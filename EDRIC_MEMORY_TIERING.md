# Idriç memory-tiering lowering note

Status: design note. This is not a claim that every phrase below is accepted by the current parser.

Memory management is a useful forcing example for the intended Idriç boundary because the semantic policy is much easier to state than any one Linux, Android, DEX, C, assembly, or kernel implementation.

## Start with the policy

A top-level description should be able to say something close to:

```idric
when memory becomes scarce
    compress cold memory quickly

when the machine is idle
    recompress older cold memory more densely
    only when restore remains fast

when memory remains scarce
    move sufficiently cold memory to internal storage
    within write budget

when an application becomes active
    restore its likely working memory early

kill cached application only when cheaper tiers are insufficient
```

The exact grammar is open. The important point is that `zram`, `lmkd`, page tables, sysfs files, ioctls, Binder calls, DEX opcodes, and ARM instructions are implementation details below the policy.

The concrete Android experiment lives in <https://github.com/isomorphisms/zram>.

## Lower gradually, and not necessarily uniformly

Lowering does not need to be one fixed staircase for every action. Different phrases can descend through different mechanisms:

```text
Idriç policy
    |
    +-> Android framework action
    |      -> checked Android/runtime operations
    |      -> DEX
    |
    +-> Linux userspace action
    |      -> syscall / ioctl / sysfs operation
    |      -> native machine code
    |
    +-> kernel-side action
    |      -> checked kernel primitive
    |      -> target-specific native code
    |
    +-> GPU experiment
           -> typed compute operation
           -> GPU target language / machine path
```

This is intentionally jagged. `prefetch cached process` might be framework-facing and naturally lower through Android APIs or DEX. Manipulating zram or a kernel page-reclaim primitive ultimately crosses a native Linux/kernel boundary. One source policy should not be forced through one universal implementation language merely to make the compiler pipeline look uniform.

## C is optional machinery, not the meaning

C is useful because operating-system APIs, kernels, vendor headers, and toolchains expose many C-shaped boundaries. That makes C a convenient implementation or diagnostic form. It does not make C the semantic intermediate language.

Possible lower forms include:

- direct Thumb-2 / AArch32 machine code;
- AArch64, x86-64, RISC-V, or other direct machine-code backends;
- DEX for Android runtime/framework-facing work;
- WebAssembly where its execution model fits;
- GPU/shader or compute targets;
- C as disposable generated source where that remains the simplest boundary;
- another native systems language, including D, when its runtime and ABI requirements fit the target;
- a future Idriç-owned portable machine IR.

No one of these should become the ontology of the source language.

## A portable machine IR is plausible

A future cross-processor IR can sit below semantic Idriç operations and above target encodings. It should describe machine-relevant meaning without pretending all processors are identical.

Useful explicit concepts would include:

- values and exact widths;
- addresses and address spaces;
- loads, stores, alignment, and atomic ordering;
- branches and calls;
- stack/frame requirements where relevant;
- system-call or foreign-call boundaries;
- traps/errors;
- vector/SIMD operations where the semantic operation really permits them;
- target constraints and required capabilities.

Then target lowering decides registers, instruction selection, calling convention, relocations, object format, and processor-specific details.

This would be a portable *machine* representation, not a replacement for the higher semantic IR. It must remain possible to bypass it when a target such as DEX or a GPU has a substantially different execution model.

## DEX is a real target, but not a Linux-kernel instruction set

DEX is appropriate for code that belongs in Android's managed/runtime layer. Idriç can therefore lower an Android-side controller, service, policy process, or framework client directly to DEX.

DEX cannot directly execute as Linux kernel code. Kernel zram, page reclaim, storage drivers, and similar mechanisms still require code accepted by the kernel/native architecture. The source program can nevertheless span both sides by preserving the semantic action above the boundary and lowering each component to the target it actually runs on.

For example:

```text
when cached application becomes active
    -> Android process-state observation/controller -> DEX
    -> request prefetch through typed boundary
    -> native userspace or kernel mechanism -> AArch32/AArch64/etc.
```

The implementation boundary should be visible and typed rather than hidden behind a pretend single-target compiler.

## “English-major C” is a useful intermediate presentation

A human-readable low-level form can become more explicit without immediately becoming punctuation-heavy C. For example:

```idric
cold_pages ← pages idle longer than idle_threshold

for each page in cold_pages
    if denser compression saves enough memory
        and restore latency remains below interactive budget
    then
        recompress page using secondary compressor
```

One level lower might expose page numbers, byte counts, queues, file descriptors, Binder handles, or sysfs paths while still using names and role words rather than positional argument piles.

Only the final lowering needs to care whether the selected implementation is DEX bytecode, a syscall sequence, C-shaped ABI calls, or direct machine instructions.

## ComputerScience chooses; Idriç preserves intent

`walnut-burgundy/computer-science` should eventually choose among implementation variants from target facts and measurements:

- which compressors exist on this kernel;
- CPU/GPU throughput and energy;
- decompression tail latency;
- memory pressure and likely reuse time;
- internal-storage latency and write budget;
- available Android/kernel interfaces;
- actual target ABI and instruction set.

Idriç should preserve the semantic request and the constraints needed to make that choice. The compiler should not silently encode one historical operating-system convention such as “all systems work goes through C.”

## Acceptance boundary

Keep separate evidence for:

1. source phrase is parsed/checked;
2. checked semantic operation is preserved in IR;
3. selected lower form is generated;
4. target artifact verifies/loads;
5. code executes through that target on the claimed runtime/device;
6. memory-policy behavior actually improves the measured app-switch workload.

A DEX artifact does not prove the kernel mechanism. A native helper does not prove the DEX controller. An emulator does not prove the physical low-RAM phone.
