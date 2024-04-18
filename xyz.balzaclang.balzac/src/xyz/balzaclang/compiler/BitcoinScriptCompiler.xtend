package xyz.balzaclang.compiler

import com.google.inject.Inject
import jakarta.inject.Singleton
import xyz.balzaclang.utils.ASTUtils
import xyz.balzaclang.xsemantics.BalzacInterpreter

@Singleton
class BitcoinScriptCompiler {

    @Inject extension ASTUtils
    @Inject extension BalzacInterpreter
}