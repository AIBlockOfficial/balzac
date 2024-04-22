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

import xyz.balzaclang.lib.PrivateKeysStore;
import xyz.balzaclang.lib.model.transaction.ITransactionBuilder;
import xyz.balzaclang.lib.model.transaction.TransactionBuilder;

import static com.google.common.base.Preconditions.*;

public interface NetworkType {
	default void checkCompatible(INetworkObject object) {
		this.checkCompatible(object, "object");
	}

	default void checkCompatible(INetworkObject object, String desc) {
		NetworkType objectNetwork = object.getNetworkType();
		checkArgument(objectNetwork == this, "%s is from network %s (expected: %s)", desc, objectNetwork, this);
	}
	
    boolean isTestnet();
    boolean isMainnet();
    
    NetworkType getTestnet();
    NetworkType getMainnet();
    
    TransactionBuilder createTransaction();
    ITransactionBuilder deserializeTransaction(byte[] bytes);

    PublicKey pubkeyFromBytes(byte[] bytes);
    PublicKey freshPubkey();

    PrivateKey privKeyFromWIF(String wif);
    PrivateKey privKeyFromBytes(byte[] bytes, boolean compressPubkey);
    PrivateKey freshPrivkey();

    Address addressFromWIF(String wif);
    Address addressFromPubkey(PublicKey pubkey);
    Address freshAddress();

    void checkSignatureValidAndCanonical(byte[] signatureBytes);
    Signature sign(PrivateKey key, ITransactionBuilder txBuilder, PrivateKeysStore keyStore, int inputIndex, SignatureModifier modifier);
    Signature signatureFromBytes(byte[] bytes, PublicKey pubkey);
}
