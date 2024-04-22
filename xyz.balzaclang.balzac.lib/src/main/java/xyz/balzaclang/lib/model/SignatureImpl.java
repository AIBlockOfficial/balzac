package xyz.balzaclang.lib.model;

import java.util.Arrays;
import java.util.Optional;

import xyz.balzaclang.lib.utils.BitcoinUtils;

public class SignatureImpl implements Signature {
	protected final NetworkType params;
    protected final byte[] signature;
    protected final Optional<PublicKey> pubkey;
    
    public SignatureImpl(NetworkType params, byte[] signature, PublicKey pubkey) {
    	this.params = params;
    	this.signature = signature.clone();
    	this.pubkey = Optional.ofNullable(pubkey);
    	
    	if (pubkey != null) {
    		params.checkCompatible(pubkey, "public key");
    	}
    }

    @Override
	public NetworkType getNetworkType() {
		return this.params;
	}

	@Override
	public byte[] getSignature() {
		return this.signature;
	}

	@Override
	public Optional<PublicKey> getPubkey() {
		return this.pubkey;
	}

	@Override
    public String toString() {
        return "sig:"
            + BitcoinUtils.encode(signature)
            + (pubkey.isPresent() ? "[pubkey:" + pubkey.get().getBytesAsString() + "]" : "");
    }

    @Override
    public int hashCode() {
        final int prime = 31;
        int result = 1;
        result = prime * result + Arrays.hashCode(signature);
        return result;
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj)
            return true;
        if (obj == null)
            return false;
        if (getClass() != obj.getClass())
            return false;
        SignatureImpl other = (SignatureImpl) obj;
        if (!Arrays.equals(signature, other.signature))
            return false;
        return true;
    }
}
