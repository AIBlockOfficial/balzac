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

package xyz.balzaclang.lib.model.transaction;

import static com.google.common.base.Preconditions.checkArgument;
import static com.google.common.base.Preconditions.checkNotNull;
import static com.google.common.base.Preconditions.checkState;

import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import java.util.function.Consumer;
import java.util.stream.Collectors;

import org.apache.commons.lang3.StringUtils;

import com.google.common.collect.ImmutableSet;
import com.google.common.collect.Sets;

import xyz.balzaclang.lib.PrivateKeysStore;
import xyz.balzaclang.lib.model.NetworkType;
import xyz.balzaclang.lib.model.script.InputScript;
import xyz.balzaclang.lib.model.script.OutputScript;
import xyz.balzaclang.lib.model.script.primitives.Primitive;
import xyz.balzaclang.lib.utils.Env;
import xyz.balzaclang.lib.utils.EnvI;
import xyz.balzaclang.lib.utils.TablePrinter;

public abstract class TransactionBuilder implements ITransactionBuilder, EnvI<Primitive, TransactionBuilder> {

    private static final long serialVersionUID = 1L;

    protected static final long UNSET_LOCKTIME = -1;

    protected transient NetworkType params;

    private final List<Input> inputs = new ArrayList<>();
    private final List<Output> outputs = new ArrayList<>();
    protected long locktime = UNSET_LOCKTIME;
    private final Env<Primitive> env = new Env<>();

    private final Map<Set<String>, Consumer<Map<String, Primitive>>> variablesHook = new HashMap<>();

    public TransactionBuilder(NetworkType params) {
        this.params = params;
    }

    @Override
    public boolean hasVariable(String name) {
        return env.hasVariable(name);
    }

    @Override
    public boolean isFree(String name) {
        return env.isFree(name);
    }

    @Override
    public boolean isBound(String name) {
        return env.isBound(name);
    }

    @Override
    public Class<? extends Primitive> getType(String name) {
        return env.getType(name);
    }

    @Override
    public Primitive getValue(String name) {
        return env.getValue(name);
    }

    @Override
    public Primitive getValueOrDefault(String name, Primitive defaultValue) {
        return env.getValueOrDefault(name, defaultValue);
    }

    @Override
    public <E extends Primitive> E getValue(String name, Class<E> clazz) {
        return env.getValue(name, clazz);
    }

    @Override
    public TransactionBuilder addVariable(String name, Class<? extends Primitive> type) {
        env.addVariable(name, type);
        return this;
    }

    @Override
    public TransactionBuilder removeVariable(String name) {
        for (Input in : inputs) {
            checkState(!in.getScript().hasVariable(name),
                "input script " + in.getScript() + " use variable '" + name + "'");
        }
        for (Output out : outputs) {
            checkState(!out.getScript().hasVariable(name),
                "output script " + out.getScript() + " use variable '" + name + "'");
        }
        env.removeVariable(name);
        variablesHook.remove(ImmutableSet.of(name));
        return this;
    }

    @Override
    public TransactionBuilder bindVariable(String name, Primitive value) {
        env.bindVariable(name, value);
        Iterator<Set<String>> it = variablesHook.keySet().iterator();
        while (it.hasNext()) {
            Set<String> variables = it.next();
            boolean allBound = variables.stream().allMatch(this::isBound);
            if (allBound) {
                Map<String, Primitive> values = variables.stream().collect(Collectors.toMap(v -> v, v -> getValue(v)));
                Consumer<Map<String, Primitive>> hook = variablesHook.get(variables);
                hook.accept(values); // execute the hook
                it.remove(); // remove the hook
            }
        }
        return this;
    }

    /**
     * Add an hook that will be executed when all the variable {@code names} will
     * have been bound. The hook is a {@link Consumer} that will take the value of
     * the variable.
     *
     * @param names a set of variables names
     * @param hook  the consumer
     * @return this builder
     */
    public TransactionBuilder addHookToVariableBinding(Set<String> names, Consumer<Map<String, Primitive>> hook) {
        checkNotNull(names, "'names' cannot be null");
        checkNotNull(hook, "'hook' cannot be null");
        checkArgument(!names.isEmpty(), "cannot add an hook for an empty set of variables");
        for (String name : names) {
            checkArgument(hasVariable(name), "'" + name + "' is not a variable");
            checkArgument(isFree(name), "'" + name + "' is not a free");
        }
        checkArgument(!variablesHook.containsKey(ImmutableSet.copyOf(names)),
            "an hook for variables " + names + " is already defined");
        variablesHook.put(ImmutableSet.copyOf(names), hook);
        return this;
    }

    public boolean hasHook(String name, String... names) {
        checkNotNull(name, "'name' cannot be null");
        checkNotNull(names, "'names' cannot be null");
        return variablesHook.containsKey(Sets.union(Sets.newHashSet(name), Sets.newHashSet(names)));
    }

    @Override
    public Collection<String> getVariables() {
        return env.getVariables();
    }

    @Override
    public Collection<String> getFreeVariables() {
        return env.getFreeVariables();
    }

    @Override
    public void clear() {
        env.clear();
    }

    @Override
    public Collection<String> getBoundVariables() {
        return env.getBoundVariables();
    }

    @Override
    public List<Input> getInputs() {
        return inputs;
    }

    @Override
    public List<Output> getOutputs() {
        return outputs;
    }

    /**
     * Remove the unused variables of this builder. A transaction variable is unused
     * if it is unused by all the input/output scripts.
     *
     * @return this builder
     */
    public TransactionBuilder removeUnusedVariables() {
        for (String name : getVariables()) {

            boolean used = false;

            for (Input in : inputs) {
                used = used || in.getScript().hasVariable(name);
            }

            for (Output out : outputs) {
                used = used || out.getScript().hasVariable(name);
            }

            if (!used)
                removeVariable(name);
        }

        return this;
    }

    /**
     * Add a new transaction input.
     *
     * @param inputScript the input script that redeem {@code tx} at
     *                    {@code outIndex}.
     * @return this builder.
     * @throws IllegalArgumentException if the parent transaction binding does not
     *                                  match its free variables, or the input
     *                                  script free variables are not contained
     *                                  within this tx free variables.
     */
    public TransactionBuilder addCoinbaseInput(InputScript inputScript) {
        checkState(this.inputs.isEmpty(), "addInput(ScriptBuilder2) can be invoked only once");
        return addInput(Input.of(inputScript));
    }

    /**
     * Add a new transaction input.
     *
     * @param tx          the parent transaction to redeem.
     * @param outIndex    the index of the output script to redeem.
     * @param inputScript the input script that redeem {@code tx} at
     *                    {@code outIndex}.
     * @return this builder.
     * @throws IllegalArgumentException if the parent transaction binding does not
     *                                  match its free variables, or the input
     *                                  script free variables are not contained
     *                                  within this tx free variables.
     */
    public TransactionBuilder addInput(ITransactionBuilder tx, int outIndex, InputScript inputScript) {
        return addInput(Input.of(tx, outIndex, inputScript));
    }

    /**
     * Add a new transaction input.
     *
     * @param tx          the parent transaction to redeem.
     * @param outIndex    the index of the output script to redeem.
     * @param inputScript the input script that redeem {@code tx} at
     *                    {@code outIndex}.
     * @param locktime    relative locktime.
     * @return this builder.
     * @throws IllegalArgumentException if the parent transaction binding does not
     *                                  match its free variables, or the input
     *                                  script free variables are not contained
     *                                  within this tx free variables.
     */
    public TransactionBuilder addInput(ITransactionBuilder tx, int outIndex, InputScript inputScript, long locktime) {
        return addInput(Input.of(tx, outIndex, inputScript, locktime));
    }

    public TransactionBuilder addInput(Input input) {
        checkNotNull(input, "'input' cannot be null");
        checkArgument(getFreeVariables().containsAll(input.getScript().getFreeVariables()),
            "the input script contains free-variables "
                + input.getScript().getFreeVariables()
                + ", but the transactions only contains "
                + getFreeVariables());
        for (String fv : input.getScript().getFreeVariables()) {
            checkArgument(input.getScript().getType(fv).equals(getType(fv)),
                "input script variable '"
                    + fv
                    + "' is of type "
                    + input.getScript().getType(fv)
                    + " while the tx variable is of type "
                    + getType(fv));
        }
        inputs.add(input);
        return this;
    }

    /**
     * Add a new transaction output.
     *
     * @param outputScript the output script.
     * @param satoshis     the amount of satoshis of the output.
     * @return this builder.
     * @throws IllegalArgumentException if the output script free variables are not
     *                                  contained within this tx free variables.
     */
    public TransactionBuilder addOutput(OutputScript outputScript, long satoshis) {
        checkArgument(getFreeVariables().containsAll(outputScript.getFreeVariables()),
            "the output script contains free-variables "
                + outputScript.getFreeVariables()
                + ", but the transactions only contains "
                + getFreeVariables());
        for (String fv : outputScript.getFreeVariables()) {
            checkArgument(outputScript.getType(fv).equals(getType(fv)),
                "input script variable '"
                    + fv
                    + "' is of type "
                    + outputScript.getType(fv)
                    + " while the tx variable is of type "
                    + getType(fv));
        }
        outputs.add(Output.of(outputScript, satoshis));
        return this;
    }

    /**
     * Set the transaction locktime (absolute locktime which could represent a block
     * number or a timestamp).
     *
     * @param locktime the value to set.
     * @return this builder.
     */
    public TransactionBuilder setLocktime(long locktime) {
        this.locktime = locktime;
        return this;
    }

    /**
     * Recursively check that this transaction and all the ancestors don't have free
     * variables.
     *
     * @return true if this transaction and all the ancestors don't have free
     *         variables, false otherwise.
     */
    @Override
    public boolean isReady() {
        return env.isReady() && inputs.size() > 0 && outputs.size() > 0 && inputs.stream().filter(Input::hasParentTx)
            .map(Input::getParentTx).allMatch(ITransactionBuilder::isReady);
    }

    @Override
    public abstract ITransaction toTransaction(PrivateKeysStore keystore);

    @Override
    public boolean isCoinbase() {
        return inputs.size() == 1 && !inputs.get(0).hasParentTx();
    }

    @Override
    public String toString() {
        StringBuilder sb = new StringBuilder("\n");

        addInfo(sb, this);
        addVariables(sb, this);
        addInputs(sb, this.inputs);
        addOutputs(sb, this.outputs);

        return sb.toString();
    }

    private static void addInfo(StringBuilder sb, TransactionBuilder tb) {
        TablePrinter tp = new TablePrinter("General info", 2);
        tp.addRow("hashcode", tb.hashCode());
        tp.addRow("coinbase", tb.isCoinbase());
        tp.addRow("ready", tb.isReady());
        tp.addRow("locktime", tb.locktime != UNSET_LOCKTIME ? String.valueOf(tb.locktime) : "none");
        sb.append(tp.toString());
        sb.append("\n");
    }

    private static void addVariables(StringBuilder sb, EnvI<Primitive, ?> env) {
        TablePrinter tp = new TablePrinter("Variables", new String[] { "Name", "Type", "Binding" }, "No variables");
        for (String name : new TreeSet<>(env.getVariables())) {
            tp.addRow(name, env.getType(name).getSimpleName(), env.getValueOrDefault(name, Primitive.of("")).toString());
        }
        sb.append(tp.toString());
        sb.append("\n");
    }

    private static void addInputs(StringBuilder sb, List<Input> inputs) {
        TablePrinter tp = new TablePrinter("Inputs",
            new String[] { "Index", "Outpoint", "Locktime", "Type", "Ready", "Variables", "Script" }, "No inputs");
        int i = 0;
        for (Input input : inputs) {
            String index = String.valueOf(i++);
            String outpoint = input.hasParentTx() ? input.getOutIndex() + ":" + input.getParentTx().hashCode() : "none";
            String locktime = input.hasLocktime() ? String.valueOf(input.getLocktime()) : "none";
            String type = String.valueOf(input.getScript().getType());
            String ready = String.valueOf(input.getScript().isReady());
            List<String> vars = getCompactVariables(input.getScript());
            String script = input.getScript().toString();

            tp.addRow(index, outpoint, locktime, type, ready, vars.isEmpty() ? "" : vars.get(0), script);

            for (int j = 1; j < vars.size(); j++) {
                tp.addRow(new String[] { "", "", "", "", vars.isEmpty() ? "" : vars.get(j), "" });
            }
        }
        sb.append(tp.toString());
        sb.append("\n");
    }

    private static void addOutputs(StringBuilder sb, List<Output> inputs) {
        TablePrinter tp = new TablePrinter("Outputs",
            new String[] { "Index", "Value", "Type", "Ready", "Variables", "Script" }, "No outputs");
        int i = 0;
        for (Output output : inputs) {
            String index = String.valueOf(i++);
            String value = String.valueOf(output.getValue());
            String type = String.valueOf(output.getScript().getType());
            String ready = output.getScript().isReady() + "";
            List<String> vars = getCompactVariables(output.getScript());
            String script = output.getScript().toString();

            tp.addRow(index, value, type, ready, vars.isEmpty() ? "" : vars.get(0), script);

            for (int j = 1; j < vars.size(); j++) {
                tp.addRow("", "", "", "", vars.isEmpty() ? "" : vars.get(j), "");
            }
        }
        sb.append(tp.toString());
        sb.append("\n");
    }

    private static List<String> getCompactVariables(EnvI<Primitive, ?> env) {
        List<String> res = new ArrayList<>();
        Collection<String> variables = new TreeSet<>(env.getVariables());

        int size = variables.stream().map(v -> ("(" + env.getType(v).getSimpleName() + ") " + v).length()).reduce(0,
            Integer::max);

        for (String v : variables) {
            res.add(StringUtils.rightPad("(" + env.getType(v).getSimpleName() + ") " + v, size)
                + (env.isBound(v) ? " -> " + env.getValue(v) : ""));
        }
        return res;
    }

    @Override
    public int hashCode() {
        final int prime = 31;
        int result = 1;
        result = prime * result + ((env == null) ? 0 : env.hashCode());
        result = prime * result + ((inputs == null) ? 0 : inputs.hashCode());
        result = prime * result + (int) (locktime ^ (locktime >>> 32));
        result = prime * result + ((outputs == null) ? 0 : outputs.hashCode());
        result = prime * result + ((variablesHook == null) ? 0 : variablesHook.hashCode());
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
        TransactionBuilder other = (TransactionBuilder) obj;
        if (env == null) {
            if (other.env != null)
                return false;
        }
        else if (!env.equals(other.env))
            return false;
        if (inputs == null) {
            if (other.inputs != null)
                return false;
        }
        else if (!inputs.equals(other.inputs))
            return false;
        if (locktime != other.locktime)
            return false;
        if (outputs == null) {
            if (other.outputs != null)
                return false;
        }
        else if (!outputs.equals(other.outputs))
            return false;
        if (variablesHook == null) {
            if (other.variablesHook != null)
                return false;
        }
        else if (!variablesHook.equals(other.variablesHook))
            return false;
        return true;
    }
}
