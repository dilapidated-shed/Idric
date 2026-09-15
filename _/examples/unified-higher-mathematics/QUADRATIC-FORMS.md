# Quadratic and Hermitian forms

This note records the abstraction boundary exercised by `QuadraticForms.idric`
and `FormTests.idric`.

The central rule is:

> A form is a mathematical object. A matrix is a representation of that form
> relative to a chosen basis.

The implementation deliberately does not define a quadratic form as a symmetric
matrix, and it does not treat a Hermitian expression `d* G d` as an ordinary
complex quadratic form.

## Existing Idriç linear-algebra inventory

The current higher-mathematics line already has one useful programmer-facing
semantic core:

- `FiniteSpace` distinguishes named finite spaces, not merely dimensions.
- `ExactVectorSample space` and `ExactCovectorSample space` are distinct types.
- `contract` evaluates a covector on a vector and requires the same named space.
- `EuclideanStructure space` is explicit; lowering/raising indices and `dot`
  require it. There is no metric-free vector-to-covector coercion.
- `IndexedValue` tracks upper/lower variance for the first checked contraction
  experiment.

The repository also contains inherited Idris machinery that should not be
mistaken for this ontology:

- `_/libs/linear` concerns linear *usage* (`Data.Linear`, `LIO`, `LVect`), not
  mathematical linear algebra.
- `Data.IOMatrix` is an implementation data structure, not a basis-aware
  representation of a linear map or form.
- the root `Algebra.Semiring` abstraction currently records operations and
  neutral elements, but not the law-bearing ring/field/module/ordered-field or
  involution structure required for a general forms library.

There is not yet a mature programmer-facing general `Basis`, mathematical
`Matrix`, complex scalar, scalar field, module, linear map, or linear
isomorphism ontology. The earlier higher-mathematics work explicitly deferred
general multiple-basis support, arbitrary matrix certification, and scalar-field
abstraction.

That is the architectural limit for this patch. It extends the compiler-checked
semantic experiment rather than silently upgrading inherited Idris containers
into mathematical objects.

## Abstract form types

`QuadraticForms.idric` introduces separate types for:

- `BilinearForm V`: structurally bilinear combinations of covector tensors;
- `SymmetricBilinearForm V`: structurally symmetric bilinear combinations;
- `QuadraticForm V`: a primitive quadratic type, including cross terms that do
  not have to be presented as diagonals of integral symmetric bilinear forms;
- `SesquilinearForm V`: conjugate-linear in the first argument and linear in
  the second;
- `HermitianForm V`: a closed Hermitian construction whose cross terms include
  their conjugate partner.

The ordinary executable sample continues to use exact `±Number` coordinates.
This is not a claim that `±Number` is the scalar field of the named real spaces.
It is a small exact integral-lattice model consistent with the existing
higher-mathematics slice.

The complex executable sample uses exact Gaussian-integral coordinates. It adds
separate complex vectors and covectors rather than reinterpreting ordinary
integral vectors.

## Quadratic form versus bilinear form

For a symmetric bilinear form `B`, `quadratic_from_symmetric B` is always valid:

`q(v) = B(v,v)`.

The reverse direction is deliberately not an unconditional equivalence.
`polar_form q` is the integral, unhalved polar form

`q(x+y) - q(x) - q(y)`.

For `q(v)=B(v,v)`, this is `2B` in the present exact integral model. A
`DiagonalPresentation q` is separate evidence that a particular integral
quadratic form is known to have an integral symmetric diagonal presentation.
There is no generic constructor for an odd product term `alpha(v) beta(v)`,
because its symmetric presentation would require division by two.

This leaves the type boundary correct for future characteristic-two scalars.
`FormTests.idric` also contains an explicit two-dimensional F2 example:
`q(x,y)=xy` is nonzero, while the diagonal of its polar form vanishes. Thus the
acceptance suite cannot regress to a universal quadratic/symmetric-bilinear
identification.

## Hermitian versus ordinary complex quadratic structure

The convention in this module is:

- conjugate-linear in the first argument;
- linear in the second.

A Hermitian form satisfies the intended structural law

`H(x,y) = conjugate(H(y,x))`.

`hermitian_quadratic_quantity H v` exposes the real diagonal quantity `H(v,v)`
in the exact Gaussian-integral model. It does not coerce the Hermitian form into
an ordinary `QuadraticForm`.

Fixing the first argument of a Hermitian form yields a complex covector in the
second argument. As a map from the first vector to the dual, this lowering is
conjugate-linear. The patch therefore does not copy the real-vector lowering
rule mechanically.

## Refinements now represented

The current exact quadratic sample has evidence types for:

- positive definite;
- negative definite;
- positive semidefinite;
- negative semidefinite;
- nondegenerate;
- degenerate;
- indefinite;
- isotropic;
- anisotropic;
- integral;
- even.

The current Hermitian sample has evidence for positive definiteness and
nondegeneracy.

These are certificates indexed by the form value, not Boolean fields stored in
the form. Properties therefore compose without a nominal wrapper for every
combination: the same form value can carry, for example, positive-definite,
nondegenerate, anisotropic, and integral evidence. The certificate vocabulary
is intentionally small and constructive; it is not presented as a complete
decision procedure for arbitrary forms.

`positive_definite_is_nondegenerate` and related functions demonstrate that an
operation can require and transform mathematical evidence rather than testing
metadata at runtime.

## Refinements intentionally deferred

The following should not be generalized from the current exact sample until the
missing scalar/lattice architecture exists:

- odd integral forms;
- unimodularity;
- signature and fixed signature;
- general nondegeneracy/radical machinery in characteristic two;
- decision procedures for definiteness or degeneracy of arbitrary forms;
- real positivity over an ordered field rather than the exact integral sample.

Unimodularity in particular needs an explicit lattice and basis-independent
statement, not merely `det(matrix) = +/-1` attached to an arbitrary coordinate
array. Signature needs a real/ordered scalar extension with a settled scalar
ontology.

## Bases and Gram matrices

Because there is no general `Basis`/`Matrix` ontology yet, this patch adds only
a contained two-dimensional representation slice.

`GramMatrix basis` is indexed by its chosen `PlaneBasis`. The same symmetric
form therefore yields different matrices in the standard and sheared bases.
The compiler rejects assigning a Gram matrix for one basis to the other basis.
A Gram matrix plus its basis can reconstruct the represented symmetric form,
and evaluating the reconstructed form is independent of which representation
was used.

The ordinary basis-change acceptance example checks

`G_B = P^T G_A P`.

The complex slice similarly uses `HermitianGramMatrix basis` and checks

`G_B = P* G_A P`,

where `P*` is conjugate transpose. The same fixture computes the ordinary
transpose result separately and obtains a different, non-Hermitian matrix. This
keeps transpose and conjugate transpose visibly distinct in executable source.

The local `IntegralMatrix2` and `ExactComplexMatrix2` types are deliberately
representation-level helpers. They are not proposed as the repository's future
general `Matrix` abstraction.

## Vectors, covectors, and duality

For bilinear forms, `bilinear_covector_at B x` constructs the covector
`B(x,-)`. For Hermitian forms, `hermitian_covector_at H x` constructs
`H(x,-)`. Both use the existing typed covector layer; neither introduces a
vector-to-covector coercion.

A nondegenerate form should eventually yield an isomorphism between a vector
space and the appropriate dual, or the appropriate conjugate-dual structure in
the Hermitian case. The repository does not yet have general
linear-map/isomorphism objects strong enough to express that statement without
inventing a one-off wrapper, so integration stops at the mathematically valid
lowering map and indexed nondegeneracy evidence.

## Compiler versus library

No new quadratic-form compiler primitive is required. The mathematical object
types, closed constructions, refinements, and basis-indexed representations are
library-level code. Existing dependent indices and ordinary equality proofs are
enough for this slice.

The source itself follows the current Idriç surface used by the higher-math
foundation: exact signed values use `±Number`, rank/count indices use `Number`,
and Idriç-facing source uses Unicode `→`, snake_case operations, and implicit
file totality. No separate `Cardinality` type is introduced.

A future generalization should improve the mathematical library layer first:
law-bearing scalar/ring/field and involution structures, modules, bases, linear
maps, duals, and basis-aware matrices. It should not special-case quadratic
forms in the elaborator merely to compensate for those missing abstractions.

## Conway reading note

The companion Conway repository already has a chapter guide for John H.
Conway's *The Sensual (Quadratic) Form* in
[Conway PR #6](https://github.com/isomorphismes/Conway/pull/6). That note makes
the same basis-independent form / basis-dependent Gram-matrix distinction and
records the characteristic-two and Hermitian cautions. This file links to it
rather than duplicating the chapter-by-chapter material.
