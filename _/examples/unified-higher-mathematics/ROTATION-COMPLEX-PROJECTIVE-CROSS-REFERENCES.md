# Rotation, complex, and projective cross-references

This note is a discovery index. It does not make one backend, representation, or numerical method canonical merely because the work is linked here.

The point is to keep related mathematical semantics, compiler experiments, and target-specific implementations visible to both humans and automated code/research searches.

## Canonical semantic anchors in Idriç

### O(n) and SO(n)

- [EuclideanGeometry.idric](EuclideanGeometry.idric) contains the current typed `OrthogonalTransform` / `SpecialOrthogonal` slice.
- It includes the first-axis reflection, first-plane quarter-turn, composition, and exact quaternion rotation sample.
- Historical implementation/testing context: [Idric PR #47 — Test exact high-dimensional rotations and reflections](https://github.com/isomorphisms/Idric/pull/47).

A Givens rotation is a special-orthogonal transformation acting nontrivially on one coordinate 2-plane. A Householder reflection is orthogonal and orientation-reversing; a composition of two reflections is orientation-preserving and therefore belongs to the SO side of this semantic boundary.

The present Idriç slice does not yet provide an arbitrary-angle Givens constructor or a general matrix certificate for SO(n). Downstream Givens/Householder code should therefore be read as implementation/research evidence, not as something already represented by a complete canonical constructor here.

### Complex coordinates and CP^n

- [ComplexProjective.idric](ComplexProjective.idric) carries the structural `ComplexCoordinates complex n` and `ComplexProjectivePoint complex n` types.
- [../../../COMPLEX-PROJECTIVE.md](../../../COMPLEX-PROJECTIVE.md) records the semantic boundary: mathematical Complex is not defined as two machine floats, a SIMD pair, or a shader `vec2`.
- Historical implementation context: [Idric PR #81 — Establish complex-coordinate and projective semantics](https://github.com/isomorphisms/Idric/pull/81).

The type-theoretic work intentionally leaves machine representation open. That matters for rotations: multiplication by a unit complex number is an SO(2) rotation once the plane is given its standard complex structure, but a compiler need not immediately expand that fact into four scalar multiply/add operations.

The current tree also records standard facts about CP^n in `TopologyFacts.idric`. Projective equivalence, holomorphic evolution, orthogonal rotation, and physical storage are related topics but are not interchangeable concepts.

## Downstream executable and lowering work

### Shader backend: Givens and Householder

Repository: [isomorphisms/idris-shader-backend](https://github.com/isomorphisms/idris-shader-backend)

- [GivensFragmentMocks.idr](https://github.com/isomorphisms/idris-shader-backend/blob/main/src/Example/GivensFragmentMocks.idr) is the explicit 2D Givens / plane-rotation fixture.
- [RotateDifference8ToE1.idr](https://github.com/isomorphisms/idris-shader-backend/blob/main/src/Example/RotateDifference8ToE1.idr) uses a Householder reflection followed by a fixed reflection to obtain a proper high-dimensional rotation.
- [docs/rope.md](https://github.com/isomorphisms/idris-shader-backend/blob/main/docs/rope.md) studies RoPE as block-diagonal plane rotations.
- [PR #31 — Add a real Givens rotation conformance probe](https://github.com/isomorphisms/idris-shader-backend/pull/31) records why the Givens fixture is distinct from the Householder-based rotate-to-e1 fixture.
- [PR #36 — Add the complex/projective GPU follower](https://github.com/isomorphisms/idris-shader-backend/pull/36) follows the shared complex/projective semantics while currently lowering complex values to a shader pair.
- [PR #49 — Research DwarfStar rotation-kernel patterns](https://github.com/isomorphisms/idris-shader-backend/pull/49) is deliberately only an implementation research thread. DwarfStar may provide useful evidence about GPU scheduling, pair layout, coefficient generation, fusion boundaries, and numerical sensitivity; it does not decide the semantic representation of Idriç Complex values.

The shader work should continue to distinguish:

```text
mathematical operation
    -> typed semantic structure
    -> target lowering / representation
    -> register, lane, or shader storage
```

rather than treating an observed `vec2` or four-scalar expansion as the meaning of the operation.

### ARM / Thumb: polar complex experiment

Repository: [isomorphisms/idric-arm-thumb](https://github.com/isomorphisms/idric-arm-thumb)

- [PR #7 — Add first polar complex-number slice](https://github.com/isomorphisms/idric-arm-thumb/pull/7) lowers one logical complex value as `(magnitude, phaseTurns)` and executes multiplication as magnitude multiplication plus phase addition.
- [PR #53 — Record Thumb-2 as a provisional complex/projective follower](https://github.com/isomorphisms/idric-arm-thumb/pull/53) explicitly marks that polar representation as a provisional target choice rather than canonical Complex semantics.

This is directly relevant to unit-complex rotations and DFT/FFT twiddle multiplication: when a value remains in a polar representation, multiplication by a unit phase can reduce to phase addition. That fact should remain visible when comparing against shader/GPU implementations that expand the same semantic action into coordinate arithmetic.

### x86-64 complex/projective leader

Repository: [isomorphisms/idric-x86-aggressive-backend](https://github.com/isomorphisms/idric-x86-aggressive-backend)

- [PR #22 — Lead complex/projective arithmetic with direct x86-64 execution](https://github.com/isomorphisms/idric-x86-aggressive-backend/pull/22) is the current executable Float32 leader for the shared complex/projective corpus.
- Its two-Float32 lowering is an implementation choice for that acceptance path, not the definition of Complex.

This is useful as a numerical/executable oracle when experimenting with alternate polar, shader-pair, SIMD, or other target representations.

## Mathematical bridges worth keeping explicit

### Givens and SO(n)

A Givens rotation acts as

```text
[c  s]
[-s c]
```

on one coordinate 2-plane and as the identity on its orthogonal complement. It is therefore a concrete sparse element of SO(n).

This gives a direct bridge between the type-theoretic `SpecialOrthogonal` work and shader/compiler Givens experiments.

### Unit complex multiplication and SO(2)

For `u = exp(i theta)`, multiplication

```text
z -> u z
```

is a planar rotation. In polar coordinates it is phase addition; in Cartesian coordinates it is the familiar two-coordinate rotation.

The semantic operation should not be identified with either physical representation.

### DFT / FFT twiddles

A DFT twiddle multiply is repeated multiplication by unit complex numbers. This connects:

- complex-number semantics;
- unit-phase / SO(2) rotations;
- the ARM polar-complex experiment;
- GPU pair-rotation scheduling;
- the FFT/Givens material in the shader repository's GPU-book research.

The DFT itself also uses complex addition, so any representation strategy should be judged on the complete butterfly/dataflow rather than on multiplication alone.

### RoPE and other pair rotations

RoPE is also built from many 2D rotations, but its surrounding workload is not the same as holomorphic complex arithmetic or a DFT. DwarfStar is therefore a useful implementation specimen, not evidence that the same representation should be selected for all three workloads.

## Missing semantic connection

The current canonical type work has explicit O/SO and complex/projective structures, but no first-class `U(n)` / unitary bridge tying the standard complex structure on R^(2n) to SO(2n).

That is a real missing link, not something to fake through comments or representation aliases. If future work needs it, it should be introduced as mathematics with its own laws/tests.

## Search terms

These terms are intentionally repeated for repository and machine search:

`Givens`, `Householder`, `plane rotation`, `orthogonal`, `special orthogonal`, `O(n)`, `SO(n)`, `unit complex`, `Complex`, `ComplexCoordinates`, `CP^n`, `ComplexProjectivePoint`, `polar complex`, `DFT`, `FFT`, `twiddle`, `RoPE`, `DwarfStar`, `PowerVR`, `shader`, `rotation lowering`, `representation`.
