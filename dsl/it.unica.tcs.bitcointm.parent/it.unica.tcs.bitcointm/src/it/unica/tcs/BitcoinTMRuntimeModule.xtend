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
import it.unica.tcs.lib.BitcoinUtilsFactory
import it.unica.tcs.xsemantics.BitcoinTMStringRepresentation
import it.unica.tcs.xsemantics.validation.BitcoinTMTypeSystemValidator
import it.xsemantics.runtime.StringRepresentation
import org.eclipse.xtext.conversion.IValueConverterService
import org.eclipse.xtext.scoping.impl.ImportUriResolver
import org.eclipse.xtext.service.SingletonBinding

/**
 * Use this class to register components to be used at runtime / without the Equinox extension registry.
 */
class BitcoinTMRuntimeModule extends AbstractBitcoinTMRuntimeModule {
	
	
	def Class<? extends StringRepresentation> bindStringRepresentation() {
		return BitcoinTMStringRepresentation;
	}
	
//	@SingletonBinding(eager=true)
//	def BitcoinUtils bindBitcoinUtils() {
//		return BitcoinUtilsFactory.create().createBitcoinUtils();
//	}
	
	override void configure(Binder builder) {
		BitcoinUtilsFactory.create().modules.forEach[
			m|
			println("Obliooooo")
			m.configure(builder)
		]
//		builder.bind(BitcoinClientI).to(RPCBitcoinClient).asEagerSingleton;
//		builder.bind(String).annotatedWith(Names.named("bitcoind.address")).toInstance("co2.unica.it");
//		builder.bind(Integer).annotatedWith(Names.named("bitcoind.port")).toInstance(18332);
//		builder.bind(String).annotatedWith(Names.named("bitcoind.protocol")).toInstance("http");
//		builder.bind(String).annotatedWith(Names.named("bitcoind.user")).toInstance("bitcoin");
//		builder.bind(String).annotatedWith(Names.named("bitcoind.password")).toInstance("L4mbWnzC35BNrmTJ");
		super.configure(builder)
	}
	
	
//	
//	@SingletonBinding(eager=true)
//	def BitcoindApi provideBitcoindApi() {
//		val String address = "co2.unica.it";
//		val int port = 18332;
//		val String protocol = "http";
//		val String user = "bitcoin";
//		val String password = "L4mbWnzC35BNrmTJ";
//		return BitcoindApiFactory.createConnection(address, port, protocol, user, password);
//	}
	
	@SingletonBinding(eager=true)
	def Class<? extends BitcoinTMTypeSystemValidator> bindBitcoinTMTypeSystemValidator() {
		return BitcoinTMTypeSystemValidator;
	}
 
 	/*
 	 * Configure the feature name containing the imported namespace.
 	 * 'importedNamespace' is the name that allows to resolve cross-file references and cannot be changed
 	 */
	def void configureImportUriResolver(Binder binder) {
		binder.bind(String).annotatedWith(Names.named(ImportUriResolver.IMPORT_URI_FEATURE)).toInstance("importedNamespace");
	}
	
	override Class<? extends IValueConverterService> bindIValueConverterService() {
        return BitcoinTMConverterService
    }
}