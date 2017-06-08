/*
 * generated by Xtext 2.11.0
 */
package it.unica.tcs.generator

import com.google.inject.Inject
import it.unica.tcs.bitcoinTM.AfterTimeLock
import it.unica.tcs.bitcoinTM.AndExpression
import it.unica.tcs.bitcoinTM.ArithmeticSigned
import it.unica.tcs.bitcoinTM.Between
import it.unica.tcs.bitcoinTM.BooleanLiteral
import it.unica.tcs.bitcoinTM.BooleanNegation
import it.unica.tcs.bitcoinTM.Comparison
import it.unica.tcs.bitcoinTM.DummyTxBody
import it.unica.tcs.bitcoinTM.Equals
import it.unica.tcs.bitcoinTM.Expression
import it.unica.tcs.bitcoinTM.Hash
import it.unica.tcs.bitcoinTM.IfThenElse
import it.unica.tcs.bitcoinTM.Input
import it.unica.tcs.bitcoinTM.KeyDeclaration
import it.unica.tcs.bitcoinTM.Max
import it.unica.tcs.bitcoinTM.Min
import it.unica.tcs.bitcoinTM.Minus
import it.unica.tcs.bitcoinTM.Model
import it.unica.tcs.bitcoinTM.NumberLiteral
import it.unica.tcs.bitcoinTM.OrExpression
import it.unica.tcs.bitcoinTM.Output
import it.unica.tcs.bitcoinTM.PackageDeclaration
import it.unica.tcs.bitcoinTM.Parameter
import it.unica.tcs.bitcoinTM.Plus
import it.unica.tcs.bitcoinTM.SerialTxBody
import it.unica.tcs.bitcoinTM.Signature
import it.unica.tcs.bitcoinTM.SignatureType
import it.unica.tcs.bitcoinTM.Size
import it.unica.tcs.bitcoinTM.StringLiteral
import it.unica.tcs.bitcoinTM.TransactionDeclaration
import it.unica.tcs.bitcoinTM.TxBody
import it.unica.tcs.bitcoinTM.UserDefinedTxBody
import it.unica.tcs.bitcoinTM.VariableReference
import it.unica.tcs.bitcoinTM.Versig
import it.unica.tcs.xsemantics.BitcoinTMTypeSystem
import java.io.File
import java.util.HashMap
import java.util.List
import java.util.Map
import org.bitcoinj.core.Coin
import org.bitcoinj.core.DumpedPrivateKey
import org.bitcoinj.core.ECKey
import org.bitcoinj.core.Transaction
import org.bitcoinj.core.Transaction.SigHash
import org.bitcoinj.core.TransactionInput
import org.bitcoinj.core.TransactionOutPoint
import org.bitcoinj.core.TransactionOutput
import org.bitcoinj.core.Utils
import org.bitcoinj.script.Script
import org.bitcoinj.script.Script.ScriptType
import org.bitcoinj.script.ScriptBuilder
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import org.eclipse.xtext.naming.IQualifiedNameProvider

import static org.bitcoinj.script.ScriptOpCodes.*

import static extension it.unica.tcs.validation.BitcoinJUtils.*

/**
 * Generates code from your model files on save.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#code-generation
 */
class BitcoinTMGenerator extends AbstractGenerator {

	@Inject private extension IQualifiedNameProvider
    @Inject private extension BitcoinTMTypeSystem typeSystem

    /*
     * TODO: move to another file
     */
    public static class CompilationException extends RuntimeException {
        
        new() {
            this("compile error")
        }
        
        new(String message) {
            super(message)
        }
    }
    
    private static class SignaturesTracker extends HashMap<Input,List<SignatureUtil>>{
    	Input currentInput 
    }
    private static class AltStack extends HashMap<Parameter,Integer>{}
    
    private static class SignatureUtil {
        int index
        ECKey key
        SigHash hashType
        boolean anyoneCanPay
        
        override String toString() {
	        return "SignatureUtil [index=" + index + ", key=" + key + ", hashType=" + hashType + ", anyoneCanPay="+ anyoneCanPay + "]";
	    }
    }


    override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {

        var resourceName = resource.URI.lastSegment.replace(".btm", "")

        for (e : resource.allContents.toIterable.filter(Model)) {

//			var basepath = if (e.^package==null) "" else e.^package.fullyQualifiedName.toString(File.separator) ;
            var outputFilename = "" + File.separator + resourceName + ".test"

            fsa.generateFile(outputFilename, e.compile)
        }
    }

    def dispatch String compile(EObject obj) {
        throw new CompilationException
    }

    	
    def dispatch String compile(PackageDeclaration obj) {
        obj.declarations.map[x|
//        	println(x)
        	x.compile
        ].join("\n")
    }

    def dispatch String compile(KeyDeclaration obj) {
        '''key «obj.fullyQualifiedName»'''
    }

    def dispatch String compile(TransactionDeclaration obj) {
        '''transaction «obj.fullyQualifiedName» «obj.body.compile»'''
    }

    def dispatch String compile(DummyTxBody obj) {"<dummy>"}
    def dispatch String compile(SerialTxBody obj) {obj.bytes}
    
    
    def dispatch String compile(UserDefinedTxBody obj) {
        
        var tx = obj.toTransaction;
        
        '''{
	input  [
		«FOR i : tx.inputs»
		«i.scriptSig.toString»
		«ENDFOR»
	]
	output [
		«FOR i : 0 ..< tx.outputs.size»
		«var out = tx.outputs.get(i)»
		«out.value.value» : «out.scriptPubKey.toString»
		«ENDFOR»
	]
} [«Utils.HEX.encode(tx.bitcoinSerialize)»]
'''
    }


    
    
    
    
    
    
    
    /*
     * utility methods
     */
    def boolean isP2PKH(it.unica.tcs.bitcoinTM.Script script) {
        var onlyOneSignatureParam = script.params.size == 1 && (script.params.get(0).paramType instanceof SignatureType)
        var onlyOnePubkey = (script.exp.simplifySafe instanceof Versig) && (script.exp.simplifySafe as Versig).pubkeys.size == 1

        return onlyOneSignatureParam && onlyOnePubkey
    }

    def boolean isOpReturn(it.unica.tcs.bitcoinTM.Script script) {
        var noParam = script.params.size == 0
        var onlyString = script.exp instanceof StringLiteral

        return noParam && onlyString
    }

    def boolean isP2SH(it.unica.tcs.bitcoinTM.Script script) {
        return !script.isP2PKH && !script.isOpReturn
    }

	

    /*
     * 
     * compiler: AST --> BitcoinJ
     * 
     */
    
    def Transaction toTransaction(TxBody stmt) {
    	toTransaction(stmt, new HashMap())
    }
    
    /**
     * Create a bitcoinj transaction object recursively.
     * Each transaction is bound to another one by its inputs. Recursion
     * stops when either a coinbase transaction or a serialized transaction is reached.
     */
    def dispatch Transaction toTransaction(UserDefinedTxBody stmt, Map<TxBody,Transaction> cache) {
        
		if (cache.containsKey(stmt))
			return cache.get(stmt)

//        println('''--- transaction «(stmt.eContainer as TransactionDeclaration).name»---''')
        
        var netParams = stmt.networkParams        
        var Transaction tx = new Transaction(netParams)
        var inputCtx = new SignaturesTracker
        
        // the tx is not ready yet but it will be at the end of the recursive loop
        cache.put(stmt, tx)
        
        for (var i=0; i<stmt.inputs.size; i++) {
//        	println('''input «i»''')
        	var input = stmt.inputs.get(i)
            var outIndex = input.txRef.idx
            var txToRedeem = input.txRef.tx.body.toTransaction(cache)
            var outPoint = new TransactionOutPoint(netParams, outIndex, txToRedeem)
            var TransactionInput txInput = new TransactionInput(netParams, tx, input.compileInput(inputCtx).program, outPoint)
            tx.addInput(txInput)            
        }
        
        for (output : stmt.outputs) {
            var value = Coin.valueOf(output.value.exp.interpret.first as Integer)
            var txOutput = new TransactionOutput(netParams, tx, value, output.compileOutput.program)
            tx.addOutput(txOutput)
        }
        
        // set all the signatures within the input scripts (which are never part of the signature)
        for (var i=0; i<tx.inputs.size; i++) {
            var txInput = tx.getInput(i)
            var signatures = inputCtx.get(stmt.inputs.get(i))
            
            if (signatures!==null) {
            	
                var outScript = 
                    if (txInput.outpoint.connectedOutput.scriptPubKey.isPayToScriptHash)
                        txInput.scriptSig.chunks.get(txInput.scriptSig.chunks.size-1).data
                    else
                        txInput.outpoint.connectedPubKeyScript
                
                for(sign : signatures) {
                    // compute the signature
                    var txSignature = tx.calculateSignature(i, sign.key, outScript, sign.hashType, sign.anyoneCanPay)
                    
                    // replace the chunk at index sign.index with the signature
                    var sb = new ScriptBuilder
                    
                    for (var j=0; j<txInput.scriptSig.chunks.size; j++) {
                    	var chunk = txInput.scriptSig.chunks.get(j)
                    	
                    	if (j<sign.index || j>sign.index)
                    		sb.addChunk(chunk) // copy
                    	else
                    		sb.data(txSignature.encodeToBitcoin)
                    }
                    
                    txInput.scriptSig = sb.build
                }
            }
            
        }
        return tx    
    }
    
    /**
     * Deserialiaze the transaction bytes into a bitcoinj transaction.
     * We assume the byte string to be valid.
     */ 
    def dispatch Transaction toTransaction(SerialTxBody stmt, Map<TxBody,Transaction> cache) {
    	if (cache.containsKey(stmt))
			return cache.get(stmt)
    	
    	var tx = new Transaction(stmt.networkParams, Utils.HEX.decode(stmt.bytes))
    	
    	cache.put(stmt, tx)
    	return tx
    }
    
    /**
     * Create a bitcoinj coinbase transaction.
     * The amount of money that can be spend is taken from the network parameters.
     * 
     * @return a coinbase tx with a lot of money always redeemable
     */
    def dispatch Transaction toTransaction(DummyTxBody stmt, Map<TxBody,Transaction> cache) {
        if (cache.containsKey(stmt))
			return cache.get(stmt)
        
        var netParams = stmt.networkParams
        var tx = new Transaction(netParams);
        var txInput = new TransactionInput(netParams, tx, new ScriptBuilder().number(42).build().getProgram());
        var txOutput = new TransactionOutput(netParams, tx, netParams.maxMoney, new ScriptBuilder().number(1).build().getProgram());      
        
        tx.addInput(txInput);
        tx.addOutput(txOutput);
        
        cache.put(stmt, tx)
    	return tx
    }
    


    

    def Script compileInput(Input stmt, SignaturesTracker ctx) {
        var outIdx = stmt.txRef.idx

        /*
         * Set the current input within the context.
         * It will be used to set the signatures in the input script.
         */
        ctx.currentInput=stmt
		
		switch stmt.txRef.tx.body {
			
			/*
			 * User defined transaction.
			 * Return the expected inputs based on the kind of output script
			 */
			UserDefinedTxBody: {
				var inputTx = stmt.txRef.tx.body as UserDefinedTxBody       
	            var output = inputTx.outputs.get(outIdx);
	    
	            if (output.script.isP2PKH) {
	                var sig = (stmt.exps.get(0) as Expression).simplifySafe as Signature
	                var pubkey = sig.key.body.pvt.value.privateKeyToPubkeyBytes(stmt.networkParams)
	                
	                val sb = new ScriptBuilder()
	    
	                sig.compileInputExpression(sb, ctx)
	                sb.data(pubkey)
	    
	                /* <sig> <pubkey> */
	                sb.build
	            } else if (output.script.isP2SH) {
	                
	                val expSb = new ScriptBuilder()
	                
	                // build the list of expression pushes (actual parameters) 
	                stmt.exps.forEach[e|e.simplifySafe.compileInputExpression(expSb, ctx)]
	                
	                // get the redeem script to push
	                var redeemScript = output.script.getRedeemScript
	                
	                expSb.data(redeemScript.program)
	                                
	                /* <e1> ... <en> <serialized script> */
	                expSb.build
	            } else
	                throw new CompilationException
            }
            
			/*
			 * Serialized transaction.
			 * Return the expected inputs based on the kind of output script
			 */
            SerialTxBody: {
            	var output = stmt.txRef.tx.body.toTransaction.getOutput(outIdx)
            
	            if (output.scriptPubKey.isSentToAddress) {
	                var sig = (stmt.exps.get(0) as Expression).simplifySafe as Signature
	                var pubkey = sig.key.body.pvt.value.privateKeyToPubkeyBytes(stmt.networkParams)
	                
	                val sb = new ScriptBuilder()
	    
	                sig.compileInputExpression(sb, ctx)
	                sb.data(pubkey)
	    
	                /* <sig> <pubkey> */
	                sb.build
	            } else if (output.scriptPubKey.isPayToScriptHash) {
	                
	                val expSb = new ScriptBuilder()
	                
	                // build the list of expression pushes (actual parameters) 
	                stmt.exps.forEach[e|e.simplifySafe.compileInputExpression(expSb, ctx)]
	                
	                // get the redeem script to push
	                var redeemScript = stmt.redeemScript.getRedeemScript
	                expSb.data(redeemScript.program)
	                
	                /* <e1> ... <en> <serialized script> */
	                expSb.build
	            } else
	                throw new CompilationException
            }
            
            /*
             * Coinbase transaction are always redeemable.
             */
            DummyTxBody: {
	            new ScriptBuilder().number(1).build
	        }
		}
		
    }

    def Script compileOutput(Output output) {
		
        var outScript = output.script

        if (outScript.isP2PKH) {
            var versig = outScript.exp.simplifySafe as Versig
            var pk = versig.pubkeys.get(0).body.pub.value.wifToAddress(output.networkParams)

            var script = ScriptBuilder.createOutputScript(pk)

            if (script.scriptType != ScriptType.P2PKH)
                throw new CompilationException

            /* OP_DUP OP_HASH160 <pkHash> OP_EQUALVERIFY OP_CHECKSIG */
            script
        } else if (outScript.isP2SH) {
            
            // get the redeem script to serialize
            var redeemScript = output.script.getRedeemScript
            var script = ScriptBuilder.createP2SHOutputScript(redeemScript)

            if (script.scriptType != ScriptType.P2SH)
                throw new CompilationException

            /* OP_HASH160 <script hash-160> OP_EQUAL */
            script
        } else if (outScript.isOpReturn) {
            var c = outScript.exp as StringLiteral
            var script = ScriptBuilder.createOpReturnScript(c.value.bytes)

            if (script.scriptType != ScriptType.NO_TYPE)
                throw new CompilationException

            /* OP_RETURN <bytes> */
            script
        } else
            throw new UnsupportedOperationException
    }


	/**
	 * Return the redeem script (in the P2SH case) from the given output.
	 * 
	 * <p>
	 * This function is invoked to generate both the output script (hashing the result) and
	 * input script (pushing the bytes).
	 * <p>
	 * It also prepends a magic number and altstack instruction.
	 */
	def Script getRedeemScript(it.unica.tcs.bitcoinTM.Script script) {
		val sb = new ScriptBuilder
        val altstack = new AltStack
        val ctx = new SignaturesTracker
        
        // build the redeem script to serialize
        for (var i=script.params.size-1; i>=0; i--) {
            var Parameter p = script.params.get(i)
            altstack.put(p, altstack.size)    // update the context
            sb.op(0, OP_TOALTSTACK)
        }
        
        script.exp.simplifySafe.compileExpression(sb, ctx, altstack)
        sb.build
	}
	
	
	/**
	 * Compile an input expression. It must not have free variables
	 */
    def void compileInputExpression(Expression exp, ScriptBuilder sb, SignaturesTracker ctx) {
        var refs = EcoreUtil2.getAllContentsOfType(exp, VariableReference)
        
        if (refs.size>0)
        	throw new CompilationException("The given expression must not have free variables.")
        
        exp.simplifySafe.compileExpression(sb, ctx, new AltStack)	// the altstack is used only by VariableReference(s)
        sb.build
    }
    
    /*
     * EXPRESSIONS
     * 
     * N.B. the compiler tries to simplify simple expressions like
     * <ul> 
     *  <li> 1+2 ≡ 3
     *  <li> if (12==10+2) then "foo" else "bar" ≡ "foo"
     * </ul>
     */
    def private dispatch void compileExpression(Expression exp, ScriptBuilder sb, SignaturesTracker ctx, AltStack altstack) {
        throw new CompilationException
    }
    
    def private dispatch void compileExpression(KeyDeclaration stmt, ScriptBuilder sb, SignaturesTracker ctx, AltStack altstack) {
        /* push the public key */
        val pvtkey = stmt.body.pvt.value
        val key = DumpedPrivateKey.fromBase58(stmt.networkParams, pvtkey).key

        sb.data(key.pubKey)
    }

    def private dispatch void compileExpression(Hash hash, ScriptBuilder sb, SignaturesTracker ctx, AltStack altstack) {
        hash.value.compileExpression(sb, ctx, altstack)
        sb.op(OP_HASH160)
    }

    def private dispatch void compileExpression(AfterTimeLock stmt, ScriptBuilder sb, SignaturesTracker ctx, AltStack altstack) {
        stmt.time.compileExpression(sb, ctx, altstack)
        sb.op(OP_CHECKLOCKTIMEVERIFY)
        stmt.continuation.compileExpression(sb, ctx, altstack)
    }

    def private dispatch void compileExpression(AndExpression stmt, ScriptBuilder sb, SignaturesTracker ctx, AltStack altstack) {
        var res = typeSystem.interpret(stmt)
        
        if (res.failed) {
	        stmt.left.compileExpression(sb, ctx, altstack)
	        stmt.right.compileExpression(sb, ctx, altstack)
	        sb.op(OP_BOOLAND)            
        }
        else {
        	if (res.first instanceof Boolean) {
                if (res.first as Boolean) {
                    sb.number(OP_TRUE)
                }
                else sb.number(OP_FALSE)
            }
            else throw new CompilationException
        }
    }

    def private dispatch void compileExpression(OrExpression stmt, ScriptBuilder sb, SignaturesTracker ctx, AltStack altstack) {
        var res = typeSystem.interpret(stmt)
        
        if (res.failed) {
	        stmt.left.compileExpression(sb, ctx, altstack)
	        stmt.right.compileExpression(sb, ctx, altstack)
	        sb.op(OP_BOOLOR)            
        }
        else {
        	if (res.first instanceof Boolean) {
                if (res.first as Boolean) {
                    sb.number(OP_TRUE)
                }
                else sb.number(OP_FALSE)
            }
            else throw new CompilationException
        }
    }

    def private dispatch void compileExpression(Plus stmt, ScriptBuilder sb, SignaturesTracker ctx, AltStack altstack) {
        var res = typeSystem.interpret(stmt)
        
        if (res.failed) {
            stmt.left.compileExpression(sb, ctx, altstack)
            stmt.right.compileExpression(sb, ctx, altstack)
            sb.op(OP_ADD)
        }
        else {
            if (res.first instanceof String){
                sb.data((res.first as String).bytes)
            }
            else if (res.first instanceof Integer) {
                sb.number(res.first as Integer)
            }
            else throw new CompilationException            
        }
    }

    def private dispatch void compileExpression(Minus stmt, ScriptBuilder sb, SignaturesTracker ctx, AltStack altstack) {
        var res = typeSystem.interpret(stmt)
        
        if (res.failed) {
            stmt.left.compileExpression(sb, ctx, altstack)
            stmt.right.compileExpression(sb, ctx, altstack)
            sb.op(OP_SUB)
        }
        else {
            if (res.first instanceof Integer) {
                sb.number(res.first as Integer)
            }
            else throw new CompilationException 
        }
    }

    def private dispatch void compileExpression(Max stmt, ScriptBuilder sb, SignaturesTracker ctx, AltStack altstack) {
        var res = typeSystem.interpret(stmt)
        
        if (res.failed) {
            stmt.left.compileExpression(sb, ctx, altstack)
            stmt.right.compileExpression(sb, ctx, altstack)
            sb.op(OP_MAX)
        }
        else {
            if (res.first instanceof Integer) {
                sb.number(res.first as Integer)
            }
            else throw new CompilationException 
        }
    }

    def private dispatch void compileExpression(Min stmt, ScriptBuilder sb, SignaturesTracker ctx, AltStack altstack) {
        var res = typeSystem.interpret(stmt)
        
        if (res.failed) {
            stmt.left.compileExpression(sb, ctx, altstack)
            stmt.right.compileExpression(sb, ctx, altstack)
            sb.op(OP_MIN)
        }
        else {
            if (res.first instanceof Integer) {
                sb.number(res.first as Integer)
            }
            else throw new CompilationException 
        }
    }

    def private dispatch void compileExpression(Size stmt, ScriptBuilder sb, SignaturesTracker ctx, AltStack altstack) {
        stmt.value.compileExpression(sb, ctx, altstack)
        sb.op(OP_SIZE)
    }

    def private dispatch void compileExpression(BooleanNegation stmt, ScriptBuilder sb, SignaturesTracker ctx, AltStack altstack) {
        var res = typeSystem.interpret(stmt)
        
        if (res.failed) {
            stmt.exp.compileExpression(sb, ctx, altstack)
            sb.op(OP_NOT)            
        }
        else {
            if (res.first instanceof Boolean) {
                if (res.first as Boolean) {
                    sb.number(OP_TRUE)
                }
                else sb.number(OP_FALSE)
            }
            else throw new CompilationException 
        }
    }

    def private dispatch void compileExpression(ArithmeticSigned stmt, ScriptBuilder sb, SignaturesTracker ctx, AltStack altstack) {
        var res = typeSystem.interpret(stmt)
        
        if (res.failed) {
            stmt.exp.compileExpression(sb, ctx, altstack)
            sb.op(OP_NOT)
        }
        else {
            if (res.first instanceof Integer) {
                sb.number(res.first as Integer)
            }
            else throw new CompilationException 
        }
    }

    def private dispatch void compileExpression(Between stmt, ScriptBuilder sb, SignaturesTracker ctx, AltStack altstack) {
        var res = typeSystem.interpret(stmt)
        
        if (res.failed) {
            stmt.value.compileExpression(sb, ctx, altstack)
            stmt.left.compileExpression(sb, ctx, altstack)
            stmt.right.compileExpression(sb, ctx, altstack)
            sb.op(OP_WITHIN)
        }
        else {
            if (res.first instanceof Integer) {
                sb.number(res.first as Integer)
            }
            else throw new CompilationException 
        }
    }

    def private dispatch void compileExpression(Comparison stmt, ScriptBuilder sb, SignaturesTracker ctx, AltStack altstack) {
        var res = typeSystem.interpret(stmt)
        
        if (res.failed) {
            stmt.left.compileExpression(sb, ctx, altstack)
            stmt.right.compileExpression(sb, ctx, altstack)
    
            switch (stmt.op) {
                case "<": sb.op(OP_LESSTHAN)
                case ">": sb.op(OP_GREATERTHAN)
                case "<=": sb.op(OP_LESSTHANOREQUAL)
                case ">=": sb.op(OP_GREATERTHANOREQUAL)
            }
        }
        else {
            if (res.first instanceof Boolean) {
                if (res.first as Boolean) {
                    sb.number(OP_TRUE)
                }
                else sb.number(OP_FALSE)
            }
            else throw new CompilationException 
        }
    }
    
    def private dispatch void compileExpression(Equals stmt, ScriptBuilder sb, SignaturesTracker ctx, AltStack altstack) {
        var res = typeSystem.interpret(stmt)
        
        if (res.failed) {
            stmt.left.compileExpression(sb, ctx, altstack)
            stmt.right.compileExpression(sb, ctx, altstack)
            
            switch (stmt.op) {
                case "==": sb.op(OP_EQUAL)
                case "!=": sb.op(OP_EQUAL).op(OP_NOT)
            }
        }
        else {
            if (res.first instanceof Boolean) {
                if (res.first as Boolean) {
                    sb.number(OP_TRUE)
                }
                else sb.number(OP_FALSE)
            }
            else throw new CompilationException 
        }
    }

    def private dispatch void compileExpression(IfThenElse stmt, ScriptBuilder sb, SignaturesTracker ctx, AltStack altstack) {
        var res = typeSystem.interpret(stmt)
        
        if (res.failed) {
            stmt.^if.compileExpression(sb, ctx, altstack)
            sb.op(OP_IF)
            stmt.then.compileExpression(sb, ctx, altstack)
            sb.op(OP_ELSE)
            stmt.^else.compileExpression(sb, ctx, altstack)
            sb.op(OP_ENDIF)            
        }
        else {
            if (res.first instanceof String){
                sb.data((res.first as String).bytes)
            }
            else if (res.first instanceof Integer) {
                sb.number(res.first as Integer)
            }
            else if (res.first instanceof Boolean) {
                if (res.first as Boolean) {
                    sb.number(OP_TRUE)
                }
                else sb.number(OP_FALSE)
            }
            else throw new CompilationException            
        }
    }

    def private dispatch void compileExpression(Versig stmt, ScriptBuilder sb, SignaturesTracker ctx, AltStack altstack) {
        if (stmt.pubkeys.size == 1) {
            stmt.signatures.get(0).compileExpression(sb, ctx, altstack)
            stmt.pubkeys.get(0).compileExpression(sb, ctx, altstack)
            sb.op(OP_CHECKSIG)
        } else {
            sb.number(OP_0)
            stmt.signatures.forEach[s|s.compileExpression(sb, ctx, altstack)]
            sb.number(stmt.signatures.size)
            stmt.pubkeys.forEach[k|k.compileExpression(sb, ctx, altstack)]
            sb.number(stmt.pubkeys.size)
            sb.op(OP_CHECKMULTISIG)
        }
    }

    def private dispatch void compileExpression(NumberLiteral n, ScriptBuilder sb, SignaturesTracker ctx, AltStack altstack) {
        sb.number(n.value).build().toString
    }

    def private dispatch void compileExpression(BooleanLiteral n, ScriptBuilder sb, SignaturesTracker ctx, AltStack altstack) {
        sb.number(if(n.isTrue) OP_TRUE else OP_FALSE).build().toString
    }

    def private dispatch void compileExpression(StringLiteral s, ScriptBuilder sb, SignaturesTracker ctx, AltStack altstack) {
        sb.data(s.value.bytes).build().toString
    }

    def private dispatch void compileExpression(Signature stmt, ScriptBuilder sb, SignaturesTracker ctx, AltStack altstack) {
        
		var wif = stmt.key.body.pvt.value
		var signatureInfo = new SignatureUtil
		
        signatureInfo.index = sb.build.chunks.size
		signatureInfo.key = DumpedPrivateKey.fromBase58(stmt.networkParams, wif).getKey();
        signatureInfo.hashType = switch(stmt.modifier) {
                case AIAO,
                case SIAO: SigHash.ALL
                case AISO,
                case SISO: SigHash.SINGLE
                case AINO,
                case SINO: SigHash.NONE
            }
        signatureInfo.anyoneCanPay = switch(stmt.modifier) {
                case SIAO,
                case SISO,
                case SINO: true
                case AIAO,
                case AISO,
                case AINO: false
            }
            
        /*
         * store the information to compute the signature later
         */
		var currentInput = ctx.currentInput
		
        ctx.merge(currentInput, newArrayList(signatureInfo),
            [oldList, newList | oldList.addAll(newList); oldList] 
        )
        
        // store an empty value
        sb.number(OP_0)
    }

    def private dispatch void compileExpression(VariableReference varRef, ScriptBuilder sb, SignaturesTracker ctx, AltStack altstack) {
        /*
         * N: altezza dell'altstack
         * i: posizione della variabile interessata
         * 
         * OP_FROMALTSTACK( N - i )                svuota l'altstack fino a raggiungere x
         * 	                                       x ora è in cima al main stack
         * 
         * OP_DUP OP_TOALTSTACK        	           duplica x e lo rimanda sull'altstack
         * 
         * (OP_SWAP OP_TOALTSTACK)( N - i - 1 )    prende l'elemento sotto x e lo sposta sull'altstack
         * 
         */
        var param = varRef.ref
        var pos = altstack.get(param)

        if(pos === null) throw new CompilationException;

        (1 .. altstack.size - pos).forEach[x|sb.op(OP_FROMALTSTACK)]
        sb.op(OP_DUP).op(OP_TOALTSTACK)

        if (altstack.size - pos - 1 > 0)
            (1 .. altstack.size - pos - 1).forEach[x|sb.op(OP_SWAP).op(OP_TOALTSTACK)]
    }
    
}
