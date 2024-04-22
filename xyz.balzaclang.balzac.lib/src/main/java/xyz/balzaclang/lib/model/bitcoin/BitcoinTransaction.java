package xyz.balzaclang.lib.model.bitcoin;

import org.bitcoinj.core.Transaction;

import xyz.balzaclang.lib.model.NetworkType;
import xyz.balzaclang.lib.model.transaction.ITransaction;

class BitcoinTransaction implements ITransaction {
	final BitcoinNetworkType params;
	final Transaction internalTransaction;
	
	BitcoinTransaction(BitcoinNetworkType params, Transaction internalTransaction) {
		this.params = params;
		this.internalTransaction = internalTransaction;
	}

	@Override
	public Transaction getInternalTransaction() {
		return this.internalTransaction;
	}

	@Override
	public byte[] serialize() {
		return this.internalTransaction.bitcoinSerialize();
	}

	@Override
	public byte[] getTxIdBytes() {
		return this.internalTransaction.getTxId().getBytes();
	}

	@Override
	public NetworkType getNetworkType() {
		return this.params;
	}
}
