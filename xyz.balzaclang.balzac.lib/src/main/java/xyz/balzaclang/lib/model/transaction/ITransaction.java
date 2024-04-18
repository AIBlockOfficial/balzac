package xyz.balzaclang.lib.model.transaction;

import xyz.balzaclang.lib.model.NetworkType;

/**
 * A generic wrapper around a network-specific transaction type.
 * 
 * @author Joey Rabil
 */
public interface ITransaction {
	Object getInternalTransaction();
	
	byte[] serialize();
	
	/**
	 * @return this transaction's ID (hash)
	 */
	byte[] getTxIdBytes();
	
	NetworkType getNetworkType();
}
