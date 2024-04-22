/*
 * Copyright 2020 Nicola Atzei
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

import org.bitcoinj.core.Utils;

public interface Address extends INetworkObject {

    public byte[] getBytes();

    public String getWif();

    public default String getBytesAsString() {
    	return Utils.HEX.encode(this.getBytes());
    }

    public static Address fromBase58(String wif, NetworkType params) {
    	return params.addressFromWIF(wif);
    }

    public static Address from(Address address) {
        return fromBase58(address.getWif(), address.getNetworkType());
    	//return address; //TODO: why was this like this?
    }

    public static Address from(PublicKey pubkey, NetworkType params) {
        return from(params.addressFromPubkey(pubkey));
    }

    public static Address from(PrivateKey key) {
        return from(key.toAddress());
    }

    public static Address fresh(NetworkType params) {
    	return params.freshAddress();
    }
}
