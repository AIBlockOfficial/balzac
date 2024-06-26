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

public class PublicKeyImpl implements PublicKey {

    private final NetworkType params;
    private final byte[] pubkey;

    public PublicKeyImpl(NetworkType params, byte[] pubkey) {
    	this.params = params;
        this.pubkey = pubkey.clone();
    }

    @Override
    public byte[] getBytes() {
        return pubkey.clone();
    }

    @Override
	public NetworkType getNetworkType() {
		return this.params;
	}

	@Override
    public int hashCode() {
        final int prime = 31;
        int result = 1;
        result = prime * result + Arrays.hashCode(pubkey);
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
        PublicKeyImpl other = (PublicKeyImpl) obj;
        if (!Arrays.equals(pubkey, other.pubkey))
            return false;
        return true;
    }

    @Override
    public String toString() {
        return getBytesAsString();
    }
}
