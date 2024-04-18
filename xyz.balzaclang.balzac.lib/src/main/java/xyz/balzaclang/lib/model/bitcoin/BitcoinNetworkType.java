package xyz.balzaclang.lib.model.bitcoin;

import org.bitcoinj.core.DumpedPrivateKey;
import org.bitcoinj.core.ECKey;
import org.bitcoinj.core.LegacyAddress;
import org.bitcoinj.core.NetworkParameters;
import org.bitcoinj.core.Transaction;

import xyz.balzaclang.lib.model.Address;
import xyz.balzaclang.lib.model.AddressImpl;
import xyz.balzaclang.lib.model.NetworkType;
import xyz.balzaclang.lib.model.PrivateKey;
import xyz.balzaclang.lib.model.PrivateKeyImpl;
import xyz.balzaclang.lib.model.PublicKey;
import xyz.balzaclang.lib.model.transaction.ITransaction;
import xyz.balzaclang.lib.model.transaction.ITransactionBuilder;
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
	public byte[] freshPubkey() {
    	return new ECKey().getPubKey();
	}
    
    static PrivateKey privkey(byte[] privkey, boolean compressPubkey, BitcoinNetworkType params) {
    	return new PrivateKeyImpl(privkey, compressPubkey, params) {
    	    @Override
			protected PublicKey toPublicKey(byte[] privkey, boolean compressPubkey) {
				return PublicKey.fromBytes(ECKey.fromPrivate(privkey, compressPubkey).getPubKey());
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
	
	/**
	 * Gets an {@link ITransaction} which wraps the given bitcoinj transaction.
	 *
	 * @param transaction the transaction to wrap
	 * @return the wrapped transaction
	 */
	public ITransaction wrapTransaction(Transaction transaction) {
		return new ITransaction() {
			@Override
			public Object getInternalTransaction() {
				return transaction;
			}

			@Override
			public byte[] serialize() {
				return transaction.bitcoinSerialize();
			}

			@Override
			public byte[] getTxIdBytes() {
				return transaction.getTxId().getBytes();
			}

			@Override
			public NetworkType getNetworkType() {
				return BitcoinNetworkType.this;
			}
		};
	}

	public static BitcoinNetworkType from(NetworkParameters parameters) {
        return parameters.getId().equals(NetworkParameters.ID_TESTNET) ? TESTNET : MAINNET;
    }
}
