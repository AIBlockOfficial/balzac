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

import java.util.Optional;

import xyz.balzaclang.lib.PrivateKeysStore;
import xyz.balzaclang.lib.model.transaction.ITransactionBuilder;

public interface Signature extends INetworkObject {
    byte[] getSignature();

    Optional<PublicKey> getPubkey();

    public static Signature computeSignature( //TODO: this is obsolete!!!
        PrivateKey key,
        ITransactionBuilder txBuilder,
        PrivateKeysStore keyStore,
        int inputIndex,
        SignatureModifier modifier) {
    	return key.getNetworkType().sign(key, txBuilder, keyStore, inputIndex, modifier);
    }
}
