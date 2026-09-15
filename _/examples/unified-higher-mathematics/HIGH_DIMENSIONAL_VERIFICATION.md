# Exact R^128 verification boundary

This note preserves the exact high-dimensional oracle inherited from PR #47
and states which evidence belongs to the current Idric compiler receipt.

## Provenance

The inherited source is branch
`examples/high-dimensional-orthogonal-tests` at
`214ceaffdb38389bef65b8fa63f73f24d66a609e`, based on
`9b0bf7fa8be9483440e6ec0530f3aef3999a8735`.  Commit
`1ee26112670866dea3f9a679645aa45f898be3d1` added the decisive distant
nonzero coordinate.  The reconciliation retains that strengthened fixture on
the current integration base
`58295f6fb49a823c5c0880568b30cff513d42d7b`.

## Preserved exact oracle

In one-based coordinates, with all unlisted coordinates zero,

```text
x_1 = 3,  x_2 = 4,   x_3 = 12,  x_128 = 9
y_1 = 5,  y_2 = -2,  y_3 = 7,   y_128 = 11
```

Equivalently,

```text
x = (3, 4, 12, 0, ..., 0, 9)
y = (5, -2, 7, 0, ..., 0, 11).
```

Let `H` negate the first coordinate and let `G` make the first-plane
quarter-turn `(a, b) → (-b, a)`.  The exact expected images are

```text
H x = (-3, 4, 12, 0, ..., 0, 9)
H y = (-5, -2, 7, 0, ..., 0, 11)
G x = (-4, 3, 12, 0, ..., 0, 9)
G y = (2, 5, 7, 0, ..., 0, 11).
```

The exact scalar oracles are

```text
x . x = 250
y . y = 199
x . y = 190
(H x) . (H x) = 250
(G x) . (G x) = 250
(H x) . (H y) = 190
(G x) . (G y) = 190.
```

The remaining exact iteration and far-coordinate oracles are

```text
H^2 x = x
G^4 x = x
(H x)_128 = 9
(G x)_128 = 9.
```

Mathematically, `det(H) = -1` and `det(G) = 1`.  The Idric layer does not
calculate arbitrary determinants.  It records the corresponding orientation
in closed transform constructors: `H` is `Reversing`, while `G` is
`Preserving` and is exposed through `SpecialOrthogonal`.  The same closed
syntax is interpreted by `apply_orthogonal_exact`, removing the former API
disconnect between marker terms and separately selected evaluators.  This is
not a compiler-derived determinant or general orthogonality proof; the exact
oracles and independent signed-permutation check cover these closed maps.

The nonzero 128th coordinate is essential.  A mistaken implementation that
only transforms or preserves an initial short prefix can satisfy the rank in
its type while still corrupting distant data; the two final-coordinate tests
exclude that failure.

## Primary compiler evidence

`tests/idris2/basic/edric009` is the primary current receipt.  Through the
real bootstrapped Idric path it:

1. checks `Tests.idric`, including its expected-failure declarations;
2. compiles the unified example to an executable;
3. executes that program and compares its PASS lines with `expected`.

The focused source uses `ExactVectorSample` and `ExactCovectorSample`, making
their exact `±Number` coordinate fragment explicit in the type names.  These
values denote exact samples inside the named real coordinate space; they do not define
its complete scalar carrier.  The `Refl` declarations check the stated images,
squared norms, dot products, involution, fourth-power identity, and the
preserved 128th coordinate by compiler normalization.
Orientation is represented in the closed transform type: `H` is
`Reversing`, `G` is in `SpecialOrthogonal`, and composition of two reflections
has a `SpecialOrthogonal real128_euclidean` result.

These tests preserve #47's exact high-dimensional behavior.  A Markdown
calculation, successful parsing alone, or an external numerical result does
not count as this compiler receipt.

## Secondary historical evidence only

The #47 work also recorded independent SymPy and NumPy/SciPy transcripts.  In
those historical transcripts:

- the exact symbolic checks reported `det(G) = 1`, `det(H) = -1`, and both
  matrices orthogonal;
- the reported image prefixes were `Gx = [-4, 3, 12, 0]` and
  `Hx = [-3, 4, 12, 0]`, while coordinate 128 remained `9`;
- squared norm `250` and transformed dot product `190` were preserved;
- `H^2` and `G^4` returned the original input in exact checks, and the
  numerical checks reported zero error where those errors were measured.

Those transcripts are secondary historical corroboration.  They are not a
current compiler run, they are not proof objects consumed by Idric, and no
rerunnable SymPy, NumPy, or SciPy script was committed with #47.  This
reconciliation therefore neither vendors such a script nor adds any external
mathematics dependency.  If an external check is rerun later, its command,
versions, and output should be recorded as a new independent receipt rather
than retroactively described as compiler verification.

## Current independent exact check

The dependency-free check is retained as `verify_r128.py`.  Run it with:

```sh
python3 examples/unified-higher-mathematics/verify_r128.py
```

The focused workflow runs this as a separately labelled secondary step after
the bootstrapped compiler receipt.

Under Python 3.12.13 it constructs both 128-entry fixtures, implements `H` and
`G` independently as signed permutations, computes their determinant signs,
and uses exact integer sums for the scalar checks.  It reports:

```text
rank: PASS
Hx: PASS
Gx: PASS
norm_H: PASS
norm_G: PASS
dot_H: PASS
dot_G: PASS
H2: PASS
G4: PASS
det_H: PASS
det_G: PASS
far_H: PASS
far_G: PASS
```

This remains secondary evidence.  It neither typechecks the Idric source nor
replaces the `edric009` compiler/executable receipt, and it adds no project
dependency.
