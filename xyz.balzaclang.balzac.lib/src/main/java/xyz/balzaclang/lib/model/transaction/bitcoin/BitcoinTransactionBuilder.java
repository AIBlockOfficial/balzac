package xyz.balzaclang.lib.model.transaction.bitcoin;

import static com.google.common.base.Preconditions.checkState;

import java.security.KeyStoreException;

import org.bitcoinj.core.Coin;
import org.bitcoinj.core.NetworkParameters;
import org.bitcoinj.core.Transaction;
import org.bitcoinj.core.TransactionInput;
import org.bitcoinj.core.TransactionOutPoint;
import org.bitcoinj.script.Script;
import org.bitcoinj.script.ScriptPattern;

import xyz.balzaclang.lib.PrivateKeysStore;
import xyz.balzaclang.lib.model.bitcoin.BitcoinNetworkType;
import xyz.balzaclang.lib.model.script.InputScript;
import xyz.balzaclang.lib.model.script.OutputScript;
import xyz.balzaclang.lib.model.transaction.ITransaction;
import xyz.balzaclang.lib.model.transaction.ITransactionBuilder;
import xyz.balzaclang.lib.model.transaction.Input;
import xyz.balzaclang.lib.model.transaction.Output;
import xyz.balzaclang.lib.model.transaction.TransactionBuilder;

public class BitcoinTransactionBuilder extends TransactionBuilder {
	private static final long serialVersionUID = 1L;

	public BitcoinTransactionBuilder(BitcoinNetworkType params) {
		super(params);
	}
	
	@Override
	public ITransaction toTransaction(PrivateKeysStore keystore) {
        checkState(this.isReady(), "the transaction and all its ancestors are not ready");
        NetworkParameters networkParameters = ((BitcoinNetworkType) this.params).toNetworkParameters();

        Transaction tx = new Transaction(networkParameters);

        // set version
        tx.setVersion(2);

        // inputs
        for (Input input : this.getInputs()) {

            if (!input.hasParentTx()) {
                // coinbase transaction
                byte[] script = new byte[] {}; // script will be set later
                TransactionInput txInput = new TransactionInput(networkParameters, tx, script);
                tx.addInput(txInput);
                checkState(txInput.isCoinBase(), "'txInput' is expected to be a coinbase");
            }
            else {
                ITransactionBuilder parentTransaction2 = input.getParentTx();
                Transaction parentTransaction = (Transaction) parentTransaction2.toTransaction(keystore).getInternalTransaction();
                TransactionOutPoint outPoint = new TransactionOutPoint(networkParameters,
                    input.getOutIndex(), parentTransaction);
                byte[] script = new byte[] {}; // script will be set later
                TransactionInput txInput = new TransactionInput(networkParameters, tx, script, outPoint);

                // set checksequenseverify (relative locktime)
                if (input.getLocktime() == UNSET_LOCKTIME) {
                    // see BIP-0065
                    if (this.locktime != UNSET_LOCKTIME)
                        txInput.setSequenceNumber(TransactionInput.NO_SEQUENCE - 1);
                }
                else {
                    txInput.setSequenceNumber(input.getLocktime());
                }
                tx.addInput(txInput);
            }
        }

        // outputs
        for (Output output : this.getOutputs()) {
            // bind free variables
            OutputScript sb = output.getScript();

            for (String freeVarName : getVariables()) {
                if (sb.hasVariable(freeVarName) && sb.isFree(freeVarName)) {
                    sb.bindVariable(freeVarName, this.getValue(freeVarName));
                }
            }
            checkState(sb.isReady(), "script cannot have free variables: " + sb.toString());
            checkState(sb.signatureSize() == 0);

            Script outScript = sb.getOutputScript();
            Coin value = Coin.valueOf(output.getValue());
            tx.addOutput(value, outScript);
        }

        // set checklocktime (absolute locktime)
        if (locktime != UNSET_LOCKTIME) {
            tx.setLockTime(locktime);
        }

        // set all the signatures within the input scripts (which are never part of the
        // signature)
        for (int i = 0; i < tx.getInputs().size(); i++) {
            TransactionInput txInput = tx.getInputs().get(i);
            InputScript inputScript = this.getInputs().get(i).getScript();

            // bind free variables
            for (String freeVarName : getVariables()) {
                if (inputScript.hasVariable(freeVarName) && inputScript.isFree(freeVarName)) {
                    inputScript.bindVariable(freeVarName, this.getValue(freeVarName));
                }
            }

            checkState(inputScript.isReady(), "script cannot have free variables: " + inputScript.toString());

            byte[] outScript;
            boolean isP2PKH = false;

            if (txInput.isCoinBase()) {
                outScript = new byte[] {};
            }
            else {
                // set outScript
                if (ScriptPattern.isP2SH(txInput.getOutpoint().getConnectedOutput().getScriptPubKey())) {
                    checkState(inputScript.isP2SH(), "why not?");
                    outScript = inputScript.getRedeemScript().build().getProgram();
                }
                else
                    outScript = txInput.getOutpoint().getConnectedPubKeyScript();

                // set isP2PKH
                isP2PKH = ScriptPattern.isP2PKH(txInput.getOutpoint().getConnectedOutput().getScriptPubKey());
            }

            try {
                inputScript.setAllSignatures(keystore, tx, i, outScript, isP2PKH);
            } catch (KeyStoreException e) {
                throw new RuntimeException(e);
            }
            checkState(inputScript.signatureSize() == 0, "all the signatures should have been set");

            // update scriptSig
            txInput.setScriptSig(inputScript.build());
        }

        return ((BitcoinNetworkType) this.params).wrapTransaction(tx);
	}
}
