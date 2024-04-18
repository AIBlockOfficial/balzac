package xyz.balzaclang.lib.utils;

import org.bouncycastle.crypto.digests.SHA3Digest;

/**
 * Helper methods for cryptographic primitives.
 *
 * @author Joey Rabil
 */
public class CryptoUtils {
	/**
	 * Computes the SHA3-256 hash of the given bytes.
	 * 
	 * @param data the bytes to hash
	 * @return the computed SHA3-256 hash
	 */
	public static byte[] sha3_256(byte[] data) {
		return sha3(256, data);
	}

	/**
	 * Computes the SHA3 hash of the given bytes.
	 * 
	 * @param size the size of the SHA3 hash to compute. Must be one of {@code 224},
	 *             {@code 256}, {@code 384}, {@code 512}
	 * @param data the bytes to hash
	 * @return the computed SHA3 hash
	 */
	public static byte[] sha3(int size, byte[] data) {
		var digest = new SHA3Digest(size);
		digest.update(data, 0, data.length);

		var hash = new byte[digest.getDigestSize()];
		digest.doFinal(hash, 0);
		return hash;
	}
}
