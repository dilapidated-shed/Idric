# Control flow, predication, selection, and speculation

This note records a compiler-design distinction we should preserve when we
start changing the Idric / edric compiler itself.

The immediate example came from the shader backend and GPU Gems 2 Chapter 34,
but the issue is not specific to GPUs.

Related shader-backend note:
https://github.com/isomorphisms/idris-shader-backend/blob/main/books%20about%20GPU%20programming/GPU%20Gems%202/chapter-34-flow-control-and-rselect.md

Source motivating the terminology:

- Mark Harris and Ian Buck, “GPU Flow-Control Idioms,” *GPU Gems 2* (2005):
  https://developer.nvidia.com/gpugems/gpugems2/part-iv-general-purpose-computation-gpus-primer/chapter-34-gpu-flow-control-idioms
- LLVM Language Reference, `select`:
  https://llvm.org/docs/LangRef.html#select-instruction

## Keep four ideas separate

### 1. Branching

A branch says which region of computation executes.

```
if condition
    run f
else
    run g
```

At the source-semantics level, the untaken arm does not execute.

### 2. Predication

Predication replaces some control flow with guarded instruction execution.

Schematic form:

```
p = condition

execute f-instructions under p
execute g-instructions under not p
```

On SIMD/SIMT machines the predicate is often a lane mask. Inactive lanes may
still travel through issued instructions, but their writes/effects are
suppressed.

GPU Gems 2 Chapter 34 describes an older fragment implementation where both
sides were evaluated and condition codes determined which results were written.
That historical implementation is a useful example of predication; it is not
the definition of source-level branching.

### 3. Selection

A selection operation chooses between values that exist as IR operands.

```
result = select condition true_value false_value
```

LLVM explicitly describes `select` as choosing a value without IR-level
branching.

This is fundamentally different from representing two alternative regions of
computation.

### 4. Speculation

Speculation means doing work before it is known to be required.

Turning

```
if condition
    f()
else
    g()
```

into straight-line computation of both `f()` and `g()`, followed by a
selection, speculates the untaken arm.

That can change more than cost. It can expose side effects, traps, invalid
loads, divergence/nontermination, poison-like intermediate values, or numerical
behavior that the source branch would never encounter.

## Compiler rule to preserve

Do not erase “which computation executes?” into “which value is selected?”
merely because a later target *might* prefer predication.

Keep source control structure visible through the IR until an explicit pass has
enough information to decide whether if-conversion is:

1. semantically legal;
2. safe to speculate;
3. profitable for the target;
4. compatible with effects and exceptional behavior;
5. compatible with lane/divergence behavior where relevant; and
6. compatible with the intended numerical semantics.

A later pass may then deliberately choose among:

- a real branch;
- predicated / masked instructions;
- a value `select`;
- duplicated specialized regions;
- moving the decision earlier;
- or another target-specific representation.

## Why this belongs in Idric

The shader `RSelect` problem is one instance of a general compiler failure
mode: lowering can destroy intent before the compiler has finished using it.

When we work on Idric's ANF, case optimization, later IRs, or new backends, we
should ask whether a transformation is preserving:

- control dependence;
- evaluation order;
- laziness / non-evaluation of untaken paths;
- effects;
- termination behavior;
- and target choices still available later.

A convenient flat IR is not automatically a neutral IR.

## Terminology for future discussions

Use these words distinctly:

- **branch** — choose which control-flow region executes;
- **predicate** — guard execution/effects with a Boolean or mask;
- **select** — choose one of two already represented values;
- **if-conversion** — deliberately transform a branch into predicated/select
  form;
- **speculation** — execute work before knowing that the source path requires
  it.

This vocabulary should make future compiler discussions much less ambiguous.
