package xyz.balzaclang.lib.model.bitcoin;

import java.util.Objects;

import org.bitcoinj.core.DumpedPrivateKey;
import org.bitcoinj.core.ECKey;
import org.bitcoinj.core.LegacyAddress;
import org.bitcoinj.core.NetworkParameters;
import org.bitcoinj.core.SignatureDecodeException;
import org.bitcoinj.core.Transaction;
import org.bitcoinj.core.Transaction.SigHash;
import org.bitcoinj.core.VerificationException;
import org.bitcoinj.crypto.TransactionSignature;

import xyz.balzaclang.lib.PrivateKeysStore;
import xyz.balzaclang.lib.model.Address;
import xyz.balzaclang.lib.model.AddressImpl;
import xyz.balzaclang.lib.model.NetworkType;
import xyz.balzaclang.lib.model.PrivateKey;
import xyz.balzaclang.lib.model.PrivateKeyImpl;
import xyz.balzaclang.lib.model.PublicKey;
import xyz.balzaclang.lib.model.PublicKeyImpl;
import xyz.balzaclang.lib.model.Signature;
import xyz.balzaclang.lib.model.SignatureImpl;
import xyz.balzaclang.lib.model.SignatureModifier;
import xyz.balzaclang.lib.model.transaction.ITransaction;
import xyz.balzaclang.lib.model.transaction.ITransactionBuilder;
import xyz.balzaclang.lib.model.transaction.Input;
import xyz.balzaclang.lib.model.transaction.Output;
import xyz.balzaclang.lib.model.transaction.SerialTransactionBuilder;
import xyz.balzaclang.lib.model.transaction.bitcoin.BitcoinTransactionBuilder;

public enum BitcoinNetworkType implements NetworkType {
	MAINNET,
	TESTNET,
	;

    @Override
	public boolean isTestnet() {
		return this == TESTNET;
	}

	@Override
	public boolean isMainnet() {
		return this == MAINNET;
	}

	@Override
	public NetworkType getTestnet() {
		return TESTNET;
	}

	@Override
	public NetworkType getMainnet() {
		return MAINNET;
	}

	public NetworkParameters toNetworkParameters() {
        return this == TESTNET ? NetworkParameters.fromID(NetworkParameters.ID_TESTNET)
            : NetworkParameters.fromID(NetworkParameters.ID_MAINNET);
    }

	@Override
	public BitcoinTransactionBuilder createTransaction() {
		return new BitcoinTransactionBuilder(this);
	}

	@Override
	public ITransactionBuilder deserializeTransaction(byte[] bytes) {
		return new SerialTransactionBuilder(this, bytes);
	}
	
    @Override
	public PublicKey pubkeyFromBytes(byte[] bytes) {
		return new PublicKeyImpl(this, bytes);
	}

	@Override
	public PublicKey freshPubkey() {
    	return this.pubkeyFromBytes(new ECKey().getPubKey());
	}
    
    static PrivateKey privkey(byte[] privkey, boolean compressPubkey, BitcoinNetworkType params) {
    	return new PrivateKeyImpl(privkey, compressPubkey, params) {
    	    @Override
			protected PublicKey toPublicKey(byte[] privkey, boolean compressPubkey) {
				return params.pubkeyFromBytes(ECKey.fromPrivate(privkey, compressPubkey).getPubKey());
			}

			@Override
    	    public String getWif() {
    	        return ECKey.fromPrivate(this.privkey, this.compressPublicKey()).getPrivateKeyAsWiF(params.toNetworkParameters());
    	    }
    	};
    }
    
    @Override
	public PrivateKey privKeyFromWIF(String wif) {
        DumpedPrivateKey key = DumpedPrivateKey.fromBase58(null, wif);
        return privkey(key.getKey().getPrivKeyBytes(), key.isPubKeyCompressed(), from(key.getParameters()));
	}

	@Override
	public PrivateKey privKeyFromBytes(byte[] bytes, boolean compressPubkey) {
		return privkey(bytes, compressPubkey, this);
	}

	@Override
	public PrivateKey freshPrivkey() {
        ECKey key = new ECKey();
        return privkey(key.getPrivKeyBytes(), key.isCompressed(), this);
	}

	static Address address(byte[] address, BitcoinNetworkType params) {
    	return new AddressImpl(address, params) {
    	    @Override
    	    public String getWif() {
    	        return LegacyAddress.fromPubKeyHash(((BitcoinNetworkType) params).toNetworkParameters(), address).toBase58();
    	    }
    	};
    }

	@Override
	public Address addressFromWIF(String wif) {
        LegacyAddress addr = LegacyAddress.fromBase58(null, wif);
        return address(addr.getHash(), from(addr.getParameters()));
	}
	
	@Override
    public Address addressFromPubkey(PublicKey pubkey) {
        LegacyAddress addr = LegacyAddress.fromKey(this.toNetworkParameters(), ECKey.fromPublicOnly(pubkey.getBytes()));
        return address(addr.getHash(), this);
	}

	@Override
	public Address freshAddress() {
        return address(LegacyAddress.fromKey(this.toNetworkParameters(), new ECKey()).getHash(), this);
	}
	
	@Override
	public void checkSignatureValidAndCanonical(byte[] signatureBytes) {
		try {
	        TransactionSignature.decodeFromBitcoin(signatureBytes, true, true);
		} catch (VerificationException | SignatureDecodeException e) {
			throw new IllegalArgumentException(e);
		}
	}

	static Signature signature(byte[] signature, PublicKey pubkey, BitcoinNetworkType params) {
		return new SignatureImpl(params, signature, pubkey);
	}
	
	private static SigHash toHashType(SignatureModifier modifier) {
        switch (modifier) {
	        case ALL_INPUT_ALL_OUTPUT:
	        case SINGLE_INPUT_ALL_OUTPUT:
	            return SigHash.ALL;
	        case ALL_INPUT_SINGLE_OUTPUT:
	        case SINGLE_INPUT_SINGLE_OUTPUT:
	            return SigHash.SINGLE;
	        case ALL_INPUT_NO_OUTPUT:
	        case SINGLE_INPUT_NO_OUTPUT:
	            return SigHash.NONE;
	        default:
	            throw new IllegalArgumentException(Objects.toString(modifier));
        }
    }
	
	private static boolean toAnyoneCanPay(SignatureModifier modifier) {
        switch (modifier) {
	        case SINGLE_INPUT_ALL_OUTPUT:
	        case SINGLE_INPUT_SINGLE_OUTPUT:
	        case SINGLE_INPUT_NO_OUTPUT:
	            return true;
	        case ALL_INPUT_ALL_OUTPUT:
	        case ALL_INPUT_SINGLE_OUTPUT:
	        case ALL_INPUT_NO_OUTPUT:
	            return false;
	        default:
	            throw new IllegalArgumentException(Objects.toString(modifier));
        }
    }
	
	@Override
	public Signature sign(PrivateKey key, ITransactionBuilder txBuilder, PrivateKeysStore keyStore, int inputIndex, SignatureModifier modifier) {
		this.checkCompatible(key, "private key");

        Transaction tx = (Transaction) txBuilder.toTransaction(keyStore).getInternalTransaction();

        Input input = txBuilder.getInputs().get(inputIndex);
        int outputIndex = input.getOutIndex();
        Output output = input.getParentTx().getOutputs().get(outputIndex);
        byte[] outputScript = output.getScript().build().getProgram();

        TransactionSignature sig = tx.calculateSignature(inputIndex, ECKey.fromPrivate(key.getBytes()), outputScript, toHashType(modifier), toAnyoneCanPay(modifier));

        return signature(sig.encodeToBitcoin(), key.toPublicKey(), this);
	}

	@Override
	public Signature signatureFromBytes(byte[] bytes, PublicKey pubkey) {
		return signature(bytes, pubkey, this);
	}

	/**
	 * Gets an {@link ITransaction} which wraps the given bitcoinj transaction.
	 *
	 * @param transaction the transaction to wrap
	 * @return the wrapped transaction
	 */
	public ITransaction wrapTransaction(Transaction transaction) {
		return new BitcoinTransaction(this, transaction);
	}

	public static BitcoinNetworkType from(NetworkParameters parameters) {
        return parameters.getId().equals(NetworkParameters.ID_TESTNET) ? TESTNET : MAINNET;
    }
}
