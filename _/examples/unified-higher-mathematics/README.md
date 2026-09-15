# Unified higher-mathematics semantics

This directory is the conservative reconciliation of the higher-mathematics
experiments in issues and pull requests #42, #45, #46, and #47, extended with
a compiler-checked quadratic/Hermitian-form slice. It is a small semantic
example, not a general mathematics library.

## Established model

`FiniteSpace` carries a nominal `SpaceName` and a known coordinate rank. The
name is itself indexed by its rank, so `PlaneName` cannot be reused at rank
128. The complete `FiniteSpace`, rather than its rank alone, indexes
`ExactVectorSample`, `ExactCovectorSample`, `IndexedValue`,
`EuclideanStructure`, and the orthogonal types. Consequently `plane_space`
and `image_plane_space` remain different even though both have rank two.

`ExactVectorSample space` and `ExactCovectorSample space` are separate
datatypes. They are explicitly the executable signed-number-coordinate
fragment of the named real coordinate space, not its complete carrier and not
a claim that the field of real scalars is `±Number`. Every represented sample
nevertheless denotes a genuine vector or covector. The metric-free operation
is covector evaluation:

```idris
contract : ExactCovectorSample space → ExactVectorSample space → ±Number
```

`RawExactCoordinates`, `UnsafeVectorCoordinates`, and the other
`unsafe...`/`Unsafe...` names form an explicit representation boundary kept
public for the exact #47 fixture and cross-module normalization. Destructing
and rebuilding through that boundary can deliberately erase a role or name;
it is raw interoperability, not implicit mathematical inference. The checked
API never performs such a conversion silently.

There is deliberately no checked vector-to-covector conversion in
`MathematicalSpaces`. `EuclideanStructure space` supplies that additional
identification through `lower_index` and `raise_index`; `dot`, `norm`,
`distance`, and index raising/lowering on exact samples all require the
structure explicitly. The current witness is the standard coordinate
Euclidean structure. `norm` and `distance` retain an exact symbolic square
root rather than silently choosing floating-point arithmetic. A complete
real-scalar representation remains deliberately unchosen.

`OrthogonalTransform structure orientation` is indexed by the particular
Euclidean structure and by `Preserving` or `Reversing`. Its public
constructors are restricted to the settled identity, first-axis reflection,
first-plane quarter-turn, exact integral unit-quaternion rotation, and
composition. `apply_orthogonal_exact` interprets that same closed syntax on
exact samples; composition means `left (right sample)`. This removes the old
disconnect between marker values and separate generator evaluators. The
orientation indices record the reviewed standard maps; Idriç does not derive
their determinants or a general metric-preservation theorem in this slice.
`SpecialOrthogonal structure` contains only orientation-preserving values.
Thus the first-axis reflection is orientation-reversing and two reflections
compose into `SO`, without pretending that this example can certify an
arbitrary user-supplied matrix or represent every quaternionic rotation.

The Einstein-style experiment is intentionally only a one-index kernel.
`LowerIndex` contains a covector, `UpperIndex` contains a vector, and
`contract_index` accepts opposite variance over the same complete named-space
index. Equal ranks neither erase a name mismatch nor permit same-variance
contraction. A variance change goes through `lower_indexed` or `raise_indexed`
and therefore requires a Euclidean structure.

## Quadratic and Hermitian forms

`QuadraticForms.idric` adds forms as mathematical objects above coordinate
representations:

- `BilinearForm` and `SymmetricBilinearForm`;
- a distinct primitive `QuadraticForm`, including cross terms that need not be
  presented as the diagonal of an integral symmetric bilinear form;
- `SesquilinearForm`, conjugate-linear in its first argument and linear in its
  second;
- `HermitianForm`, whose cross terms carry their conjugate partners.

A symmetric bilinear form can yield a quadratic form by diagonal evaluation,
but the reverse direction is not encoded as an unconditional equivalence.
`polar_form` is the unhalved integral polar form, and a separate
`DiagonalPresentation` certificate records when an integral quadratic form is
known to have an integral symmetric presentation. The acceptance suite also
contains an explicit characteristic-two `F2` example where `q(x,y)=xy` is
nonzero while the diagonal of its polar form vanishes.

The current exact quadratic sample carries evidence types for positive and
negative definiteness, positive and negative semidefiniteness,
nondegeneracy/degeneracy, indefiniteness, isotropy/anisotropy, integrality, and
evenness. The Hermitian sample carries positive-definite and nondegenerate
evidence. These properties are indexed certificates, not Boolean fields.

Fixing one argument of a bilinear form produces an actual
`ExactCovectorSample`; fixing the first argument of a Hermitian form produces
an actual complex covector and is conjugate-linear in that argument. No
vector-to-covector coercion is introduced.

The repository still lacks a general programmer-facing basis/matrix/scalar
ontology, so coordinate integration deliberately stops at a contained
compiler-checked plane example. `GramMatrix basis` and
`HermitianGramMatrix basis` remember the chosen basis in their types. Two
bases produce different matrices for the same underlying form, with the
ordinary law `G' = P^T G P` and Hermitian law `G' = P* G P`. The complex
fixture separately computes the ordinary-transpose result to demonstrate why
it is wrong for Hermitian change of basis.

See [QUADRATIC-FORMS.md](QUADRATIC-FORMS.md) for the architecture inventory,
refinement boundary, characteristic-two discussion, duality limit, and link to
the Conway repository's *The Sensual (Quadratic) Form* reading note.

The finite presheaf example remains in `PresheafRestriction.idric`. It shares
the strategy of making inclusions and section domains indices, but it does not
depend on Euclidean geometry. It models three opens, their stated inclusions,
restriction identity and composition, and componentwise restriction of a
formal elementary pair. It claims neither a general presheaf interface nor a
tensor-product or sheaf construction.

`TopologyFacts.idric` preserves the mathematically settled slice of #45:

- checked unit-sphere samples indexed by their ambient Euclidean structure;
- the closed additive integral-cohomology rank formula and Euler
  characteristic for ordinary spheres;
- exact quaternion multiplication and norm-one sample values;
- the real dimension, Hopf-sphere dimension, and closed additive integral
  cohomology ranks of CP^n;
- explicit theorem-boundary values for Jordan separation and the one-point
  compactification of Euclidean R^n.

Those are encoded standard facts. The compiler is not computing general
cohomology, constructing quotient spaces, or deriving separation theorems
from coordinates.

## Six knowledge boundaries

| Source of knowledge | Role in this example | What it does not do |
| --- | --- | --- |
| Ordinary type unification | Requires the same full `FiniteSpace`; indexed names prevent both equal-rank conflation and one name acquiring conflicting ranks. | It cannot turn equal coordinate counts into space equality or supply a metric. |
| Dependent-index normalization | Reduces rank-indexed constructors, literal exact arithmetic, and closed dimension/rank formulas used by `Refl`. | It does not consult named topology facts. |
| Structure information | An explicit `EuclideanStructure space` enables lowering, raising, dot products, norms, distances, and the closed O/SO operations on exact samples. | It is not ordinary unification and is not inferred merely from a rank. |
| Algebraic laws | Closed transform/form syntax, typed witnesses, and focused equalities record norm-one samples, restriction laws, orientation composition, exact generator oracles, form evaluations, and basis-change laws. | The example does not certify arbitrary matrices, prove a general norm-preservation theorem, or synthesize arbitrary algebraic structures. |
| Named fact lookup | `NamedFact` applies a selected entry to an exact typed hypothesis in `TypedContext` and returns a typed `FactAnswer` with declared attribution and a structured named origin. | It performs no search, proves no stored implication, and does not validate or authenticate metadata. |
| External/CAS evidence | Historical SymPy and NumPy/SciPy checks plus the retained dependency-free exact script independently corroborate #47; see [HIGH_DIMENSIONAL_VERIFICATION.md](HIGH_DIMENSIONAL_VERIFICATION.md). | External output is neither imported evidence nor a substitute for the current compiler receipt. |

The named-fact proof of concept contains one entry,
`topology.jordan-separation@1`. Its typed hypothesis is an embedded circle in
S^2 and its typed conclusion is the corresponding two-component separation
fact. Here the embedding value is an explicit assumption token; no map or
injectivity property is inferred or checked. A `NamedFact H C` stores
human-declared attribution plus an Idriç function `(h : H) → C h`. Lookup
explicitly applies that selected entry to `TypedContext H`; the type checker
enforces the exact hypothesis type, and the answer says that it came through
named lookup rather than unification. This is the boundary requested by #42
and the companion design note `walnut-burgundy/computer-science#56`; it is not
a registry search engine, theorem prover, authenticated provenance system, or
the downstream symbolic planner of `computer-science#54`.

## Compiler receipt and fixture isolation

The focused receipt is `_/tests/idris2/basic/edric009`. It copies the eight
`.idric` modules used by the two executable acceptance programs without
renaming their suffixes, runs the bootstrapped Idriç compiler's `--check` path,
builds both executables, and checks their output. The negative declarations
use `failing`, so the receipt also requires the compiler to reject space
conflation, dimension mismatch, same-variance contraction, vector-vector
contraction without a metric, incompatible form/vector families, basis-index
mismatch, and an unsupported integral diagonal presentation.

Using `edric009` resolves the inherited fixture collision: the #45/#47 and
#46 experiments both used an `edric008` fixture on separate branches. Their
verified behavior is brought into one fixture rather than choosing one
branch's fixture and silently discarding the other.

Run only this slice with:

```sh
./_/edric test --only idris2/basic/edric009
```

The exact R^128 oracle and the distinction between primary compiler evidence
and secondary historical checks are recorded in
[HIGH_DIMENSIONAL_VERIFICATION.md](HIGH_DIMENSIONAL_VERIFICATION.md).

## Inherited provenance

All inherited experiment branches diverged from
`9b0bf7fa8be9483440e6ec0530f3aef3999a8735`. This reconciliation is based on
the then-current `Idriç` tip
`58295f6fb49a823c5c0880568b30cff513d42d7b`; neither historical branch was
treated as a replacement compiler line.

| Work | Inherited branch | Exact inherited tip |
| --- | --- | --- |
| Issue #42 and its #46 implementation | `examples/higher-math-constraint-inference` | `c2e5945e209cbf9ab055e3c127c4b981313242fc` |
| PR #45 | `examples/linear-geometry-type-core` | `6b46694b26328ae4b71134ce8b52bdb8c00fb4e8` |
| PR #47 | `examples/high-dimensional-orthogonal-tests` | `214ceaffdb38389bef65b8fa63f73f24d66a609e` |

Within #47, commit `1ee26112670866dea3f9a679645aa45f898be3d1`
is the crucial strengthening that put a nonzero value in coordinate 128. The
unified fixture preserves that oracle rather than replacing it with a smaller
or weaker example.

## Deliberate deferrals

The smallest coherent boundary leaves the following choices open:

- a law-bearing scalar/ring/field/module abstraction, complete real-vector
  carrier, and exact representation of arbitrary real coordinates;
- named spaces whose dimension is unknown, infinite, or learned only at run
  time (`FiniteSpace` covers the present known-rank slice only);
- a general `Basis`, mathematical `Matrix`, linear-map, dual-space, and linear
  isomorphism ontology beyond the contained two-dimensional form example;
- multiple nondefinitionally-equal metrics on one named space, arbitrary
  matrix certification, and a reusable proof that every closed transform
  preserves the metric;
- general decision procedures for form nondegeneracy/definiteness, and the
  lattice/ordered-field structure required for oddness, unimodularity,
  signature, and fixed signature;
- a typed action on `UnitSpherePoint`: the exact transform evaluator is
  connected now, but lifting it to certified sphere samples awaits that
  reusable norm-preservation proof rather than wrapping an unchecked image;
- general tensor syntax, tensor products, or an Einstein elaborator beyond
  the variance- and space-aware one-index kernel;
- general presheaves, sheafification, arbitrary quotient equality, and the
  ring structure or computation of general homology/cohomology;
- theorem search, theorem proving, CAS integration, and the downstream
  symbolic planner.

These are semantic extensions, not cleanup required to reconcile the current
experiments. Adding them would require new mathematical choices and new
focused tests.
