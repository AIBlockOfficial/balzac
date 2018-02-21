/*
 * Copyright 2017 Nicola Atzei
 */

/*
 * generated by Xtext 2.11.0
 */
package it.unica.tcs

import com.google.inject.Binder
import com.google.inject.name.Names
import it.unica.tcs.conversion.BitcoinTMConverterService
import it.unica.tcs.lib.client.BitcoinClientI
import it.unica.tcs.lib.client.impl.RPCBitcoinClient
import it.unica.tcs.scoping.BitcoinTMGlobalScopeProvider
import it.unica.tcs.xsemantics.BitcoinTMStringRepresentation
import it.unica.tcs.xsemantics.validation.BitcoinTMTypeSystemValidator
import it.xsemantics.runtime.StringRepresentation
import java.util.concurrent.TimeUnit
import org.eclipse.xtext.conversion.IValueConverterService
import org.eclipse.xtext.scoping.IGlobalScopeProvider
import org.eclipse.xtext.scoping.IScopeProvider
import org.eclipse.xtext.scoping.impl.AbstractDeclarativeScopeProvider
import org.eclipse.xtext.scoping.impl.ImportUriResolver
import org.eclipse.xtext.scoping.impl.SimpleLocalScopeProvider
import org.eclipse.xtext.service.SingletonBinding

/**
 * Use this class to register components to be used at runtime / without the Equinox extension registry.
 */
class BitcoinTMRuntimeModule extends AbstractBitcoinTMRuntimeModule {

    def Class<? extends StringRepresentation> bindStringRepresentation() {
        return BitcoinTMStringRepresentation;
    }

    @SingletonBinding(eager=true)
    def Class<? extends BitcoinTMTypeSystemValidator> bindBitcoinTMTypeSystemValidator() {
        return BitcoinTMTypeSystemValidator;
    }

    // Configure the feature name containing the imported namespace.
    // 'importedNamespace' is the name that allows to resolve cross-file references and cannot be changed
    def void configureImportUriResolver(Binder binder) {
        binder.bind(String).annotatedWith(Names.named(ImportUriResolver.IMPORT_URI_FEATURE)).toInstance("importedNamespace");
    }

    override Class<? extends IValueConverterService> bindIValueConverterService() {
        return BitcoinTMConverterService
    }

    // fully qualified names depends on the package declaration
//    override Class<? extends IQualifiedNameProvider> bindIQualifiedNameProvider() {
//      return BitcoinTMQualifiedNameProvider;
//  }

    // disable ImportedNamespaceAwareLocalScopeProvider
    override configureIScopeProviderDelegate(Binder binder) {
        binder.bind(IScopeProvider).annotatedWith(Names.named(AbstractDeclarativeScopeProvider.NAMED_DELEGATE)).to(SimpleLocalScopeProvider);
    }

    override Class<? extends IGlobalScopeProvider> bindIGlobalScopeProvider() {
        return BitcoinTMGlobalScopeProvider;
    }

    def void configureBitcoinClient(Binder binder) {
        binder.bind(BitcoinClientI).toInstance(new RPCBitcoinClient("localhost", 8332, "http", "bitcoin", "L4mbWnzC35BNrmTK", 3, TimeUnit.SECONDS));
        binder.bind(BitcoinClientI).annotatedWith(Names.named("testnet")).toInstance(new RPCBitcoinClient("co2.unica.it", 18332, "http", "bitcoin", "L4mbWnzC35BNrmTJ", 3, TimeUnit.SECONDS));
    }
}