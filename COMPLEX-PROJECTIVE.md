# Complex and projective semantic boundary

This slice establishes the type-level distinction needed by complex and projective arithmetic without choosing a machine representation or silently settling the separate floating-precision work.

## What the checker now distinguishes

`ComplexCoordinates complex n` is the structural type of an element of a complex coordinate space with exactly `n` coordinates. `ComplexProjectivePoint complex n` is a projective point with a nonzero homogeneous representative containing exactly `n + 1` complex coordinates.

The `complex` parameter is deliberate. The current canonical tree does not yet have a settled general real-scalar hierarchy whose precision semantics can honestly define the numerical carrier for the mathematical field C. This module therefore does **not** define C as two `Double`s, two `Float32`s, a GLSL `vec2`, or an x86 register pair merely to obtain executable code.

The concrete executable Float32 implementation currently belongs to the x86-64 leading backend and is checked against the shared corpus at `_/fixtures/complex-projective/float32.json`. The exact `ExactComplex` type in `QuadraticForms.idric` remains a Gaussian-integral test scalar used only to make structural identities reduce exactly in compiler acceptance.

## Projective semantics

For projective dimension `n`, a representative has `n + 1` homogeneous coordinates. The all-zero tuple is excluded by `NonzeroHomogeneousCoordinates`.

The runtime representation may carry a homogeneous tuple directly. The semantic point is the equivalence class under common nonzero complex rescaling:

```text
[z0:...:zn] = [lambda z0:...:lambda zn],  lambda != 0.
```

`projective_rescaling_witness` expresses one explicit witness for that quotient relation. Raw component equality is not projective equality. There is intentionally no ordinary `Eq` instance, vector addition, or multiplication for `ComplexProjectivePoint`.

Normalization is not part of construction. A backend may choose a gauge for numerical stability, chart extraction, comparison, serialization, or rendering, but common scale is otherwise retained as redundant homogeneous information.

## Affine chart

`affine_to_projective` implements

```text
(z1,...,zn) -> [1:z1:...:zn].
```

`projective_first_chart` divides by the first homogeneous coordinate only when that coordinate is nonzero. For CP^1, `[0:1]` therefore remains the point at infinity and is outside this chart.

## Holomorphic boundary

Projective structure does not make observational operations holomorphic. Conjugation, magnitude, phase, gauge choice, and coloring may be used for observation or rendering. They must not be inserted into an evolving value that is meant to remain holomorphic.

The shared render fixture uses the current whole-plane explorer model

```text
f(z) = R(z) exp(q(z))
```

where `R` carries an explicit zero/pole divisor and `q` is an entire polynomial. The fixture contains no lasso, overlapping-disc, path, Riemann-surface, or lacunary machinery.

## Precision and tolerances

The shared numerical corpus declares Float32 explicitly. Its machine implementations must preserve that declared width. A wider host calculation may be used only as an external oracle.

Exact-binary32 cases use exact comparison. Ordinary floating cases use an error bound derived from binary32 epsilon and the conditioning/operation count of the case. The current bounded complex-exponential implementation is a degree-7 Taylor polynomial and is accepted only for input magnitude at most `0.5`; its analytic truncation bound is

```text
exp(|q|) |q|^8 / 8!
```

plus a separately recorded binary32 rounding allowance. Inputs outside the declared approximation domain must be rejected rather than silently accepted with a larger arbitrary tolerance.

Projective comparison uses rescaling witnesses or invariant cross-products such as `zi*wj - zj*wi`, never raw homogeneous component equality.
