/*
 * Copyright 2017 Nicola Atzei
 */

/*
 * generated by Xtext 2.11.0
 */
package it.unica.tcs.validation

import com.google.inject.Inject
import it.unica.tcs.bitcoinTM.AbsoluteTime
import it.unica.tcs.bitcoinTM.AfterTimeLock
import it.unica.tcs.bitcoinTM.ArithmeticSigned
import it.unica.tcs.bitcoinTM.BitcoinTMFactory
import it.unica.tcs.bitcoinTM.BitcoinTMPackage
import it.unica.tcs.bitcoinTM.BitcoinValue
import it.unica.tcs.bitcoinTM.Div
import it.unica.tcs.bitcoinTM.Import
import it.unica.tcs.bitcoinTM.Input
import it.unica.tcs.bitcoinTM.Interpretable
import it.unica.tcs.bitcoinTM.IsMinedCheck
import it.unica.tcs.bitcoinTM.KeyLiteral
import it.unica.tcs.bitcoinTM.Literal
import it.unica.tcs.bitcoinTM.Model
import it.unica.tcs.bitcoinTM.Modifier
import it.unica.tcs.bitcoinTM.Output
import it.unica.tcs.bitcoinTM.PackageDeclaration
import it.unica.tcs.bitcoinTM.Parameter
import it.unica.tcs.bitcoinTM.Reference
import it.unica.tcs.bitcoinTM.Referrable
import it.unica.tcs.bitcoinTM.RelativeTime
import it.unica.tcs.bitcoinTM.Signature
import it.unica.tcs.bitcoinTM.Times
import it.unica.tcs.bitcoinTM.Transaction
import it.unica.tcs.bitcoinTM.TransactionHexLiteral
import it.unica.tcs.bitcoinTM.TransactionIDLiteral
import it.unica.tcs.bitcoinTM.Versig
import it.unica.tcs.lib.Hash
import it.unica.tcs.lib.ITransactionBuilder
import it.unica.tcs.lib.SerialTransactionBuilder
import it.unica.tcs.lib.TransactionBuilder
import it.unica.tcs.lib.client.BitcoinClientException
import it.unica.tcs.lib.client.TransactionNotFoundException
import it.unica.tcs.lib.utils.BitcoinUtils
import it.unica.tcs.utils.ASTUtils
import it.unica.tcs.utils.BitcoinClientFactory
import it.unica.tcs.utils.SignatureAndKey
import it.unica.tcs.xsemantics.BitcoinTMInterpreter
import it.unica.tcs.xsemantics.Rho
import java.util.HashMap
import java.util.HashSet
import java.util.Map
import java.util.Set
import org.bitcoinj.core.Address
import org.bitcoinj.core.AddressFormatException
import org.bitcoinj.core.DumpedPrivateKey
import org.bitcoinj.core.Utils
import org.bitcoinj.core.VerificationException
import org.bitcoinj.core.WrongNetworkException
import org.bitcoinj.script.Script
import org.bitcoinj.script.ScriptException
import org.eclipse.emf.ecore.util.EcoreUtil
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.naming.IQualifiedNameConverter
import org.eclipse.xtext.naming.QualifiedName
import org.eclipse.xtext.resource.IContainer
import org.eclipse.xtext.resource.IEObjectDescription
import org.eclipse.xtext.resource.IResourceDescription
import org.eclipse.xtext.resource.IResourceDescriptions
import org.eclipse.xtext.resource.impl.ResourceDescriptionsProvider
import org.eclipse.xtext.validation.Check
import org.eclipse.xtext.validation.CheckType
import org.eclipse.xtext.validation.ValidationMessageAcceptor

import static org.bitcoinj.script.Script.*

/**
 * This class contains custom validation rules.
 *
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#validation
 */
class BitcoinTMValidator extends AbstractBitcoinTMValidator {

//  private static Logger logger = Logger.getLogger(BitcoinTMValidator);

    @Inject private extension IQualifiedNameConverter
    @Inject private extension BitcoinTMInterpreter
    @Inject private extension ASTUtils
    @Inject private ResourceDescriptionsProvider resourceDescriptionsProvider;
    @Inject private IContainer.Manager containerManager;
    @Inject private BitcoinClientFactory clientFactory;

    @Check
    def void checkUnusedParameters__Script(it.unica.tcs.bitcoinTM.Script script){

        for (param : script.params) {
            var references = EcoreUtil.UsageCrossReferencer.find(param, script.exp);
            if (references.size==0)
                warning("Unused variable '"+param.name+"'.",
                    param,
                    BitcoinTMPackage.Literals.PARAMETER__NAME
                );
        }
    }

    @Check
    def void checkUnusedParameters__Transaction(Transaction tx){

        for (param : tx.params) {
            var references = EcoreUtil.UsageCrossReferencer.find(param, tx);
            if (references.size==0)
                warning("Unused variable '"+param.name+"'.",
                    param,
                    BitcoinTMPackage.Literals.PARAMETER__NAME
                );
        }
    }

    @Check
    def void checkVerSigDuplicatedKeys(Versig versig) {

        for(var i=0; i<versig.pubkeys.size-1; i++) {
            for(var j=i+1; j<versig.pubkeys.size; j++) {

                var k1 = versig.pubkeys.get(i)
                var k2 = versig.pubkeys.get(j)

                if (k1==k2) {
                    warning("Duplicated public key.", versig, BitcoinTMPackage.Literals.VERSIG__PUBKEYS, i);
                    warning("Duplicated public key.", versig,BitcoinTMPackage.Literals.VERSIG__PUBKEYS, j);
                }
            }
        }
    }

    @Check
    def void checkSignatureModifiers(Signature signature) {

        var input = EcoreUtil2.getContainerOfType(signature, Input);
        for (other: EcoreUtil2.getAllContentsOfType(input, Signature)){

            if (signature!=other && signature.modifier.restrictedBy(other.modifier)) {
                warning('''This signature modifier is nullified by another one.''',
                    signature,
                    BitcoinTMPackage.Literals.SIGNATURE__MODIFIER
                );
                warning('''This signature modifier is nullifying another one.''',
                    other,
                    BitcoinTMPackage.Literals.SIGNATURE__MODIFIER
                );
            }
        }
    }

    def private boolean restrictedBy(Modifier _this, Modifier other) {
        false;
    }

    @Check
    def void checkConstantScripts(it.unica.tcs.bitcoinTM.Script script) {

        val res = script.exp.interpretE

        if (!res.failed && (res.first instanceof Boolean)) {
            warning("Script will always evaluate to "+res.first,
                script.eContainer,
                script.eContainingFeature
            );
        }
    }


//  @Check
    def void checkInterpretExp(Interpretable exp) {

        if (context.containsKey(exp.eContainer)
            || exp instanceof Literal
            || exp instanceof ArithmeticSigned
            || exp.eContainer instanceof BitcoinValue
        ){
            // your parent can be simplified, so you are too
            context.put(exp, exp)
            return
        }

        if (exp instanceof Reference) {
            // references which refer to a declaration are interpreted as their right-part interpretation.
            // It's not useful to show that.
            return;
        }

        if (exp instanceof org.bitcoinj.core.Transaction) {
            // It's not useful to show that.
            return;
        }

        var resInterpret = exp.interpretE       // simplify if possible, then interpret

        var container = exp.eContainer
        var index =
            if (container instanceof Input) {
                container.exps.indexOf(exp)
            }
            else ValidationMessageAcceptor.INSIGNIFICANT_INDEX

        if (!resInterpret.failed /* || !resSimplify.failed*/) {

            // the expression can be simplified. Store it within the context such that sub-expression will skip this check
            context.put(exp, exp)

            val value = resInterpret.first

            var compilationResult =
                switch (value) {
                    Hash:    BitcoinTMFactory.eINSTANCE.createHashType.value+":"+BitcoinUtils.encode(value.bytes)
                    String:     '"'+value+'"'
                    default:    value.toString
                }

            info('''This expression can be simplified. It will be compiled as «compilationResult» ''',
                exp.eContainer,
                exp.eContainmentFeature,
                index
            );

        }
    }

    @Check
    def void checkPackageDuplicate(PackageDeclaration pkg) {
        var Set<QualifiedName> names = new HashSet();
        var IResourceDescriptions resourceDescriptions = resourceDescriptionsProvider.getResourceDescriptions(pkg.eResource());
        var IResourceDescription resourceDescription = resourceDescriptions.getResourceDescription(pkg.eResource().getURI());
        for (IContainer c : containerManager.getVisibleContainers(resourceDescription, resourceDescriptions)) {
            for (IEObjectDescription od : c.getExportedObjectsByType(BitcoinTMPackage.Literals.PACKAGE_DECLARATION)) {
                if (!names.add(od.getQualifiedName())) {
                    error(
                        "Duplicated package name",
                        BitcoinTMPackage.Literals.PACKAGE_DECLARATION__NAME
                    );
                }
            }
        }
    }

    @Check
    def void checkImport(Import imp) {

        var packageName = (imp.eContainer as Model).package.name.toQualifiedName
        var importedPackage = imp.importedNamespace.toQualifiedName

        if (packageName.equals(importedPackage.skipLast(1))) {
            error(
                '''The import «importedPackage» refers to this package declaration''',
                BitcoinTMPackage.Literals.IMPORT__IMPORTED_NAMESPACE
            );
            return
        }

        var Set<QualifiedName> names = new HashSet();
        var IResourceDescriptions resourceDescriptions = resourceDescriptionsProvider.getResourceDescriptions(imp.eResource());
        var IResourceDescription resourceDescription = resourceDescriptions.getResourceDescription(imp.eResource().getURI());

        for (IContainer c : containerManager.getVisibleContainers(resourceDescription, resourceDescriptions)) {
            for (IEObjectDescription od : c.getExportedObjectsByType(BitcoinTMPackage.Literals.PACKAGE_DECLARATION)) {
                names.add(od.qualifiedName.append("*"))
            }
            for (IEObjectDescription od : c.getExportedObjectsByType(BitcoinTMPackage.Literals.TRANSACTION)) {
                names.add(od.qualifiedName)
            }
        }

        if (!names.contains(importedPackage)) {
            error(
                '''The import «importedPackage» cannot be resolved''',
                BitcoinTMPackage.Literals.IMPORT__IMPORTED_NAMESPACE
            );
        }
    }

    @Check
    def void checkDeclarationNameIsUnique(Referrable r) {

        if (r instanceof Parameter)
            return

        var root = EcoreUtil2.getRootContainer(r);
        val allReferrables = EcoreUtil2.getAllContentsOfType(root, Referrable).filter[x|!(x instanceof Parameter)]

        for (other: allReferrables){

            if (r!=other && r.name.equals(other.name)) {
                error("Duplicated name "+other.name,
                    r,
                    r.literalName
                );
            }
        }
    }

    @Check
    def void checkVerSig(Versig versig) {

        if (versig.pubkeys.size>15) {
            error("Cannot verify more than 15 public keys.",
                BitcoinTMPackage.Literals.VERSIG__PUBKEYS
            );
        }

        if (versig.signatures.size > versig.pubkeys.size) {
            error("The number of signatures cannot exceed the number of public keys.",
                versig,
                BitcoinTMPackage.Literals.VERSIG__SIGNATURES
            );
        }
    }

    @Check
    def void checkSig(Signature sig) {
        var k = sig.privkey

        if (k instanceof Reference) {
            if (k.ref.isTxParameter)
                error("Cannot use parametric key.",
                    sig,
                    BitcoinTMPackage.Literals.SIGNATURE__PRIVKEY
                );
        }
    }

    @Check
    def void checkSigTransaction(Signature sig) {
        val isTxDefined = sig.tx !== null
        val isWithinInput = EcoreUtil2.getContainerOfType(sig, Input) !== null

        if (isTxDefined && sig.tx.isCoinbase) {
            error("Transaction cannot be a coinbase.",
                sig,
                BitcoinTMPackage.Literals.SIGNATURE__TX
            );
        }

        if (isTxDefined && sig.tx.isSerial) {
            error("Cannot sign a serialized transaction.",
                sig,
                BitcoinTMPackage.Literals.SIGNATURE__TX
            );
        }

        if (isTxDefined && isWithinInput) {
            error("Transaction cannot be specified within input script.",
                sig,
                BitcoinTMPackage.Literals.SIGNATURE__TX
            );
        }

        if (!isTxDefined && !isWithinInput) {
            error("Transaction must be specified.",
                sig.eContainer,
                sig.eContainingFeature
            );
        }
    }


    @Check
    def void checkKeyDeclaration(KeyLiteral k) {

        if (k.value.isPrivateKey) {
            try {
                DumpedPrivateKey.fromBase58(k.networkParams, k.value)
            }
            catch (WrongNetworkException e) {
                error("Key is not valid for the given network.",
                    k,
                    BitcoinTMPackage.Literals.KEY_LITERAL__VALUE
                )
            }
            catch (AddressFormatException e) {
                error("Invalid key. "+e.message,
                    k,
                    BitcoinTMPackage.Literals.KEY_LITERAL__VALUE
                )
            }
        }

        if (k.value.isAddress) {
            try {
                Address.fromBase58(k.networkParams, k.value)
            }
            catch (WrongNetworkException e) {
                error("Address is not valid for the given network.",
                    k,
                    BitcoinTMPackage.Literals.KEY_LITERAL__VALUE
                )
            }
            catch (AddressFormatException e) {
                error("Invalid address. "+e.message,
                    k,
                    BitcoinTMPackage.Literals.KEY_LITERAL__VALUE
                )
            }
        }
    }

    @Check
    def void checkUniqueParameterNames__Script(it.unica.tcs.bitcoinTM.Script p) {

        for (var i=0; i<p.params.size-1; i++) {
            for (var j=i+1; j<p.params.size; j++) {
                if (p.params.get(i).name == p.params.get(j).name) {
                    error(
                        "Duplicated parameter name '"+p.params.get(j).name+"'.",
                        p.params.get(j),
                        BitcoinTMPackage.Literals.PARAMETER__NAME, j
                    );
                }
            }
        }
    }

    @Check
    def void checkUniqueParameterNames__Transaction(Transaction p) {

        for (var i=0; i<p.params.size-1; i++) {
            for (var j=i+1; j<p.params.size; j++) {
                if (p.params.get(i).name == p.params.get(j).name) {
                    error(
                        "Duplicated parameter name '"+p.params.get(j).name+"'.",
                        p.params.get(j),
                        BitcoinTMPackage.Literals.PARAMETER__NAME, j
                    );
                }
            }
        }
    }

    @Check
    def void checkScriptWithoutMultply(it.unica.tcs.bitcoinTM.Script p) {

        val exp = p.exp

        val times = EcoreUtil2.getAllContentsOfType(exp, Times);
        val divs = EcoreUtil2.getAllContentsOfType(exp, Div);
        var signs = EcoreUtil2.getAllContentsOfType(exp, Signature);

        times.forEach[t|
            error(
                "Multiplications are not permitted within scripts.",
                t.eContainer,
                t.eContainingFeature
            );
        ]

        divs.forEach[d|
            error(
                "Divisions are not permitted within scripts.",
                d.eContainer,
                d.eContainingFeature
            );
        ]

        signs.forEach[s|
            error("Signatures are not allowed within output scripts.",
                s.eContainer,
                s.eContainmentFeature
            );
        ]
    }

    @Check
    def void checkSerialTransaction(TransactionHexLiteral tx) {

        try {
            val txJ = new org.bitcoinj.core.Transaction(tx.networkParams, BitcoinUtils.decode(tx.value))
            txJ.verify
        }
        catch (VerificationException e) {
            error(
                '''Transaction is invalid. Details: «e.message»''',
                tx,
                null
            );
        }
    }

    @Check
    def void checkSerialTransaction(TransactionIDLiteral tx) {

        try {
            val id = tx.value
            val client = clientFactory.getBitcoinClient(tx.networkParams)
            val hex = client.getRawTransaction(id)
            val txJ = new org.bitcoinj.core.Transaction(tx.networkParams, BitcoinUtils.decode(hex))
            txJ.verify
        }
        catch (TransactionNotFoundException e) {
            error(
                '''Transaction not found, check you are in the right network. Details: «e.message»''',
                tx,
                null
            );
        }
        catch (VerificationException e) {
            error(
                '''Transaction is invalid. Details: «e.message»''',
                tx,
                null
            );
        }
        catch (Exception e) {
            error(
                '''Unable to fetch the transaction from its ID. Check that trusted nodes are configured correctly''',
                tx,
                null
            );
            println(e.message)
        }
    }

    @Check(CheckType.NORMAL)
    def void checkUserDefinedTx(Transaction tx) {

        if (tx.isCoinbase)
            return;

        var hasError = false;

        /*
         * Verify that inputs are valid
         */
        val mapInputsTx = new HashMap<Input, ITransactionBuilder>
        for (input: tx.inputs) {
            /*
             * get the transaction input
             */
            val txInput = input.txRef

            if (txInput.txVariables.empty) {

                val res = input.txRef.interpretE

                if (res.failed) {
                    res.ruleFailedException.printStackTrace
                    error("Error evaluating the transaction input, see error log for details.",
                        input,
                        BitcoinTMPackage.Literals.INPUT__TX_REF
                    );
                    hasError = hasError || true
                }
                else {
                    val txB = res.first as ITransactionBuilder
                    mapInputsTx.put(input, txB)
                    var valid =
                        input.isPlaceholder || (
                            input.checkInputIndex(txB) &&
                            input.checkInputExpressions(txB)
                        )

                    hasError = hasError || !valid
                }
            }
        }

        if(hasError) return;  // interrupt the check

        /*
         * pairwise verify that inputs are unique
         */
        for (var i=0; i<tx.inputs.size-1; i++) {
            for (var j=i+1; j<tx.inputs.size; j++) {

                var inputA = tx.inputs.get(i)
                var inputB = tx.inputs.get(j)

                var areValid = checkInputsAreUnique(inputA, inputB, mapInputsTx)

                hasError = hasError || !areValid
            }
        }

        if(hasError) return;  // interrupt the check

        /*
         * Verify that the fees are positive
         */
        hasError = !tx.checkFee

        if(hasError) return;  // interrupt the check

        /*
         * Verify that the input correctly spends the output
         */
        hasError = tx.correctlySpendsOutput
    }


    def boolean checkInputIndex(Input input, ITransactionBuilder inputTx) {

        var numOfOutputs = inputTx.outputs.size
        var outIndex = input.outpoint

        if (outIndex>=numOfOutputs) {
            error("This input is pointing to an undefined output script.",
                input,
                BitcoinTMPackage.Literals.INPUT__TX_REF
            );
            return false
        }

        return true
    }

    def boolean checkInputExpressions(Input input, ITransactionBuilder inputTx) {

        var outputIdx = input.outpoint as int

        if (inputTx instanceof SerialTransactionBuilder) {
            if (inputTx.outputs.get(outputIdx).script.isP2SH) {
                input.failIfRedeemScriptIsMissing
            }
            else {
                input.failIfRedeemScriptIsDefined
            }
        }
        else if (inputTx instanceof TransactionBuilder) {
            input.failIfRedeemScriptIsDefined
        }

        if (inputTx.outputs.get(outputIdx).script.isP2PKH) {
            for (e : input.exps) {
                val res = e.interpretE
                if (!res.failed && res.first instanceof SignatureAndKey) {
                    val sig = res.first as SignatureAndKey
                    if (sig.pubkey === null) {
                        error(
                            "The given signature does not specify a pubkey, needed to redeem a P2PKH (e.g. fun(s) . versig(k;s)).",
                            e,
                            null
                        );
                        return false
                    }
                }
            }
        }

        return true
    }


    def boolean failIfRedeemScriptIsMissing(Input input) {
        if (input.redeemScript===null) {
            error(
                "You must specify the redeem script when referring to a P2SH output of a serialized transaction.",
                input,
                BitcoinTMPackage.Literals.INPUT__EXPS,
                input.exps.size-1
            );
            return false
        }
        else {
            // free variables are not allowed
            var ok = true
            for (v : EcoreUtil2.getAllContentsOfType(input.redeemScript, Reference)) {
                if (v.ref.eContainer instanceof org.bitcoinj.core.Transaction) {
                    error(
                        "Cannot reference transaction parameters from the redeem script.",
                        v,
                        BitcoinTMPackage.Literals.REFERENCE__REF
                    );
                    ok = false;
                }
            }
            return ok
        }
    }

    def boolean failIfRedeemScriptIsDefined(Input input) {
        if (input.redeemScript!==null) {
            error(
                "You must not specify the redeem script when referring to a user-defined transaction.",
                input.redeemScript,
                BitcoinTMPackage.Literals.INPUT__EXPS,
                input.exps.size-1
            );
            return false
        }
        return true;
    }

    def boolean checkInputsAreUnique(Input inputA, Input inputB, Map<Input, ITransactionBuilder> mapInputsTx) {

        val txA = mapInputsTx.get(inputA)
        val txB = mapInputsTx.get(inputB)

        if (txA===null || txB===null)
            return true

        if (!txA.ready || !txB.ready)
            return true

        if (txA.toTransaction==txB.toTransaction && inputA.outpoint==inputB.outpoint
        ) {
            error(
                "Double spending. You cannot redeem the output twice.",
                inputA,
                BitcoinTMPackage.Literals.INPUT__TX_REF
            );

            error(
                "Double spending. You cannot redeem the output twice.",
                inputB,
                BitcoinTMPackage.Literals.INPUT__TX_REF
            );
            return false
        }
        return true
    }

    def boolean checkFee(Transaction _tx) {

        if (_tx.isCoinbase)
            return true;

        val res = _tx.interpretE

        if (!res.failed) {
            val tx = res.first as ITransactionBuilder

            var amount = 0L

            for (in : tx.inputs) {
                amount += in.parentTx.outputs.get(in.outIndex).value
            }

            for (output : tx.outputs) {
                amount-=output.value
            }

            if (amount<0) {
                error("The transaction spends more than expected.",
                    _tx,
                    BitcoinTMPackage.Literals.TRANSACTION__OUTPUTS
                );
                return false;
            }

        }

        return true;
    }

    def boolean correctlySpendsOutput(Transaction tx) {

        /*
         * Check if tx has parameters and they are used
         */
        val someIsUsed = tx.params.exists[p|
            EcoreUtil.UsageCrossReferencer.find(p, tx).size>=0;
        ]

        if (someIsUsed) {
            return true
        }

        var res = tx.interpretE

        if (!res.failed) {
            var txBuilder = res.first as ITransactionBuilder

            if (txBuilder.isCoinbase) {
                return true
            }

            for (var i=0; i<tx.inputs.size; i++) {

                println('''correctlySpendsOutput: «tx.name».in[«i»]''');
                println(txBuilder.toString)

                var Script inScript = null
                var Script outScript = null

                try {
                    // compile the transaction to BitcoinJ representation
                    var txJ = txBuilder.toTransaction()

                    println()
                    println(txJ.toString)

                    inScript = txJ.getInput(i).scriptSig
                    outScript = txJ.getInput(i).outpoint.connectedOutput.scriptPubKey
                    val value = txJ.getInput(i).outpoint.connectedOutput.value

                    inScript.correctlySpends(
                            txJ,
                            i,
                            outScript,
                            value,
                            ALL_VERIFY_FLAGS
                        )
                } catch(ScriptException e) {

                    warning(
                        '''
                        This input does not redeem the specified output script.

                        Details: «e.message»

                        INPUT:   «inScript»
                        OUTPUT:  «outScript»
                        «IF outScript.isPayToScriptHash»
                        REDEEM SCRIPT:  «new Script(inScript.chunks.get(inScript.chunks.size-1).data)»
                        REDEEM SCRIPT HASH:  «BitcoinUtils.encode(Utils.sha256hash160(new Script(inScript.chunks.get(inScript.chunks.size-1).data).program))»
                        «ENDIF»
                        ''',
                        tx,
                        BitcoinTMPackage.Literals.TRANSACTION__INPUTS,
                        i
                    );
                } catch(Exception e) {
                    error('''Something went wrong: see error for details''',
                            tx,
                            BitcoinTMPackage.Literals.TRANSACTION__INPUTS,
                            i)
                    e.printStackTrace
                }
            }
        }
        else {
            res.ruleFailedException.printStackTrace
            error(
                '''Error evaluating the transaction «tx.name», see error log for details.''',
                tx,
                BitcoinTMPackage.Literals.TRANSACTION__INPUTS
            )

        }

        return true
    }

    @Check
    def void checkPositiveOutValue(Output output) {

        var value = output.value.exp.interpretE.first as Long
        var script = output.script

        if (script.isOpReturn(new Rho) && value>0) {
            error("OP_RETURN output scripts must have 0 value.",
                output,
                BitcoinTMPackage.Literals.OUTPUT__VALUE
            );
        }

        // https://github.com/bitcoin/bitcoin/commit/6a4c196dd64da2fd33dc7ae77a8cdd3e4cf0eff1
        if (!script.isOpReturn(new Rho) && value<546) {
            error("Output (except OP_RETURN scripts) must spend at least 546 satoshis.",
                output,
                BitcoinTMPackage.Literals.OUTPUT__VALUE
            );
        }
    }

    @Check
    def void checkJustOneOpReturn(Transaction tx) {
        /*
         * https://en.bitcoin.it/wiki/Script
         * "Currently it is usually considered non-standard (though valid) for a transaction to have more than one OP_RETURN output or an OP_RETURN output with more than one pushdata op."
         */

        var boolean[] error = newBooleanArrayOfSize(tx.outputs.size);

        for (var i=0; i<tx.outputs.size-1; i++) {
            for (var j=i+1; j<tx.outputs.size; j++) {

                var outputA = tx.outputs.get(i)
                var outputB = tx.outputs.get(j)

                // these checks need to be executed in this order
                if (outputA.script.isOpReturn(new Rho) && outputB.script.isOpReturn(new Rho)
                ) {
                    if (!error.get(i) && (error.set(i,true) && true))
                        warning(
                            "Currently it is usually considered non-standard (though valid) for a transaction to have more than one OP_RETURN output or an OP_RETURN output with more than one pushdata op.",
                            outputA.eContainer,
                            outputA.eContainingFeature,
                            i
                        );

                    if (!error.get(j) && (error.set(j,true) && true))
                        warning(
                            "Currently it is usually considered non-standard (though valid) for a transaction to have more than one OP_RETURN output or an OP_RETURN output with more than one pushdata op.",
                            outputB.eContainer,
                            outputB.eContainingFeature,
                            j
                        );
                }
            }
        }
    }

    @Check
    def void checkUniqueAbsoluteTimelock(AbsoluteTime tlock) {

        var tx = EcoreUtil2.getContainerOfType(tlock, Transaction);
        for (other: tx.timelocks){

            if (tlock!=other && tlock.class==other.class) {
                error(
                	"Duplicated absolute timelock",
                    tlock,
                    null
                );
            }
        }
    }

    @Check
    def void checkUniqueRelativeTimelock(RelativeTime tlock) {

        var tx = EcoreUtil2.getContainerOfType(tlock, Transaction);
        for (other: tx.timelocks){

            if (tlock!=other && tlock.class==other.class) {
                val tx1 = tlock.tx.interpretE.first
                val tx2 = (other as RelativeTime).tx.interpretE.first

                if (tx1==tx2)
                    error(
                    	"Duplicated relative timelock",
                        tlock,
                        null
                    );
            }
        }
    }

    @Check
    def void checkRelativeTimelockFromTx(RelativeTime tlock) {

        if (EcoreUtil2.getContainerOfType(tlock, AfterTimeLock) === null && tlock.tx === null) {
            error(
                'Missing reference to an input transaction',
                tlock,
                BitcoinTMPackage.Literals.RELATIVE_TIME__TX
            );
        }
    }

    @Check
    def void checkRelativeTimelockFromTxIsInput(RelativeTime tlock) {

        if (tlock.tx !== null) {
            val tx = tlock.tx.interpretE.first
            val containingTx = EcoreUtil2.getContainerOfType(tlock, Transaction);

            for (in : containingTx.inputs) {
                val inTx = in.txRef.interpretE.first
                if (tx==inTx) {
                    return
                }
            }

            error(
                'Relative timelocks must refer to an input transaction',
                tlock,
                BitcoinTMPackage.Literals.RELATIVE_TIME__TX
            );
        }
    }

    @Check
    def void checkAbsoluteTime(AbsoluteTime tlock) {

        val res = tlock.value.interpretE

        if (res.failed)
            return;

        val value = res.first as Long

        if (value<0) {
            error(
                "Negative timelock is not permitted.",
                tlock,
                BitcoinTMPackage.Literals.TIMELOCK__VALUE
            );
        }

        if (tlock.isBlock && value>=org.bitcoinj.core.Transaction.LOCKTIME_THRESHOLD) {
            error(
                "Block number must be lower than 500_000_000.",
                tlock,
                BitcoinTMPackage.Literals.TIMELOCK__VALUE
            );
        }

        if (!tlock.isBlock && value<org.bitcoinj.core.Transaction.LOCKTIME_THRESHOLD) {
            error(
                "Block number must be greater or equal than 500_000_000 (1985-11-05 00:53:20). Found "+tlock.value,
                tlock,
                BitcoinTMPackage.Literals.TIMELOCK__VALUE
            );
        }
    }

    @Check
    def void checkRelativeTime(RelativeTime tlock) {

        if (tlock.isBlock) {

            val res = tlock.value.interpretE

            if (res.failed)
                return;

            val value = res.first as Long

            if (value<0) {
                error(
                    "Negative timelock is not permitted.",
                    tlock,
                    BitcoinTMPackage.Literals.TIMELOCK__VALUE
                );
            }

            /*
             * tlock.value must fit in 16-bit
             */
            if (!value.fitIn16bits) {
                error(
                    '''Relative timelocks must fit within unsigned 16-bits. Block value is «value», max allowed is «0xFFFF»''',
                    tlock,
                    BitcoinTMPackage.Literals.TIMELOCK__VALUE
                );
            }
        }
        else {
            val value = tlock.delay.delayValue

            if (!value.fitIn16bits) {
                error(
                    '''Relative timelocks must fit within unsigned 16-bits. Delay is «value», max allowed is «0xFFFF»''',
                    tlock,
                    BitcoinTMPackage.Literals.TIMELOCK__VALUE
                );
            }
        }
    }

    @Check
    def void checkAfterTimelock(AfterTimeLock after) {
        val tlock = after.timelock

        if (tlock instanceof RelativeTime) {
            if (tlock.tx !== null) {
                error(
                    "Cannot specify the tx within scripts",
                    tlock,
                    BitcoinTMPackage.Literals.RELATIVE_TIME__TX
                );
            }
        }
    }

    @Check
    def boolean checkTransactionChecksOndemand(Transaction tx) {
        var hasError = false
        for (var i=0; i<tx.checks.size-1; i++) {
            for (var j=i; i<tx.checks.size; j++) {
                val one = tx.checks.get(i)
                val other = tx.checks.get(j)

                if (one.class == other.class) {
                    error(
                        "Duplicated annotation",
                        tx,
                        BitcoinTMPackage.Literals.TRANSACTION__CHECKS,
                        i
                    );
                    error(
                        "Duplicated annotation",
                        tx,
                        BitcoinTMPackage.Literals.TRANSACTION__CHECKS,
                        j
                    );
                    hasError = true;
                }
            }
        }

        return !hasError;
    }

    @Check(CheckType.NORMAL)
    def void checkTransactionOndemand(IsMinedCheck check) {

        val tx = EcoreUtil2.getContainerOfType(check, Transaction)

        if (!checkTransactionChecksOndemand(tx)) {
            return
        }

        val checkIdx = tx.checks.indexOf(check)
        val res = tx.interpretE

        if (res.failed) {
            warning(
                '''Cannot check if «tx.name» is mined. Cannot interpret the transaction.''',
                tx,
                BitcoinTMPackage.Literals.TRANSACTION__CHECKS,
                checkIdx
            );
        }
        else {
            val txBuilder = res.first as ITransactionBuilder
            val txid = txBuilder.toTransaction.hashAsString

            try {
                val client = clientFactory.getBitcoinClient(tx.networkParams)
                val mined = client.isMined(txid)

                if (check.isMined && !mined) {
                    warning(
                        "Transaction is not mined",
                        tx,
                        BitcoinTMPackage.Literals.TRANSACTION__CHECKS,
                        checkIdx
                    );
                }

                if (!check.isMined && mined) {
                    warning(
                        "Transaction is already mined",
                        tx,
                        BitcoinTMPackage.Literals.TRANSACTION__CHECKS,
                        checkIdx
                    );
                }

            }
            catch(BitcoinClientException e) {
                warning(
                    "Cannot check if the transaction is mined due to network problems: "+e.message,
                    tx,
                    BitcoinTMPackage.Literals.TRANSACTION__CHECKS,
                    checkIdx
                );
            }
        }
    }
}