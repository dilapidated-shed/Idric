# GPU backend notes

These are design notes, not a commitment to a particular graphics API or compiler architecture.

## Why GLES and Vulkan matter

Android exposes two relevant low-level GPU APIs:

- **OpenGL ES (GLES)** is the mobile/embedded form of OpenGL. It is relatively small and direct enough for mathematical rendering. A program supplies geometry, buffers, textures, uniforms, and shaders and asks the GPU to draw.
- **Vulkan** is a newer and more explicit GPU API. It exposes substantially more control over memory, command submission, synchronization, pipelines, and other GPU machinery. That control may be useful eventually, but it comes with considerably more implementation surface.

For an initial Android mathematical renderer, GLES is likely the easier low-level target. Vulkan should remain available as a later target rather than being required up front.

## Compiler-backend question

Do not assume that GLES or Vulkan support must live inside the main Idriç repository.

If GPU compilation becomes substantial, each target can have its own compiler/backend repository. The main compiler can retain a small, stable boundary while target-specific machinery evolves elsewhere.

Possible arrangements include:

- Idriç -> ordinary CPU/native code, with a separate rendering layer that submits data to GLES or Vulkan.
- Idriç -> GLSL ES shader source for GLES.
- Idriç -> SPIR-V shader modules for Vulkan.
- A shared GPU-oriented intermediate representation with separate GLES and Vulkan lowering backends.

These are alternatives, not decisions yet.

## Why separate repositories are acceptable

A backend does not need to be physically inside the core compiler repository to be a real compiler backend. Separate repositories can be useful when a target brings its own toolchain, tests, generated artifacts, SDK assumptions, or platform-specific code.

This keeps the core compiler from accumulating Android/GPU-specific machinery merely because we want to experiment with a graphics target.

A possible future layout could therefore be conceptually:

- `Idric` — language, type system, core compiler, stable backend interface
- separate GLES backend repository
- separate Vulkan/SPIR-V backend repository
- renderer/application repositories that depend on whichever backend they need

The exact repository names and interfaces should wait until an actual experiment proves what data and code need to cross the boundary.

## Immediate bias

For Android rendering experiments, prefer proving the geometry with Processing or GLES before investing in Vulkan-specific machinery.

If direct GPU compilation from Idriç becomes useful, first determine whether targeting GLSL ES is sufficient. Only introduce a SPIR-V/Vulkan backend when there is a concrete reason for the extra control or portability.


## Compiler implementation comparison reference

The ICK `inspiration` branch now compares GCC with Clang/LLVM, TinyCC, chibicc, cproc/QBE, lacc, 8cc, cparser/libFirm, CompCert, PCC, slimcc, and c4, including corrected source-to-source traces rooted in real Linux-kernel and ICK/Wegert/Pauli constructs:

https://github.com/dilapidated-shed/ick/tree/inspiration/inspiration

Revisit that comparison before committing to a shared GPU IR or materially changing the Idriç-to-shader backend boundary. The most relevant questions are how long semantic operations should remain explicit, whether a small frontend/backend contract is enough, which optimizations belong before target selection, and what additional machinery a second target such as SPIR-V actually earns. Update this pointer when the comparison gains executable results or the GPU backend design changes materially.
