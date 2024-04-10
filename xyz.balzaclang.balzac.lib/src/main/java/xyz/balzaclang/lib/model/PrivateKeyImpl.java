/*
 * Copyright 2019 Nicola Atzei
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package xyz.balzaclang.lib.model;

import java.util.Arrays;

public abstract class PrivateKeyImpl implements PrivateKey {

    private final NetworkType params;
    protected final byte[] privkey;
    private final boolean compressPubkey;
    private final PublicKey pubkey;
    private final Address address;

    public PrivateKeyImpl(byte[] privkey, boolean compressPubkey, NetworkType params) {
        this.params = params;
        this.privkey = privkey.clone();
        this.compressPubkey = compressPubkey;
        this.pubkey = this.toPublicKey(privkey, compressPubkey);
        this.address = Address.from(pubkey, params);
    }

    @Override
    public byte[] getBytes() {
        return privkey.clone();
    }

    @Override
    public boolean compressPublicKey() {
        return compressPubkey;
    }

    @Override
    public PublicKey toPublicKey() {
        return pubkey;
    }
    
    protected abstract PublicKey toPublicKey(byte[] privkey, boolean compressPubkey);

    @Override
    public Address toAddress() {
        return address;
    }

    @Override
    public NetworkType getNetworkType() {
        return params;
    }

    @Override
    public PrivateKey withNetwork(NetworkType networkType) {
    	return networkType == this.params ? this : networkType.privKeyFromBytes(privkey.clone(), compressPubkey);
    }

    @Override
    public int hashCode() {
        final int prime = 31;
        int result = 1;
        result = prime * result + Arrays.hashCode(privkey);
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
        PrivateKeyImpl other = (PrivateKeyImpl) obj;
        if (!Arrays.equals(privkey, other.privkey))
            return false;
        return true;
    }

    @Override
    public String toString() {
        return getWif();
    }
}
