# Packed quaternion, polar-complex, and CP^n literature notes

This note records the first literature/specification sweep for future low-precision
packed representations of:

- general Hamilton quaternions;
- unit rotation quaternions;
- complex values represented by magnitude and phase;
- points of complex projective space CP^n.

It is a bibliography and design-evidence index, not a representation specification.
The semantic types in this directory remain representation-independent.

The repository does **not** vendor copyrighted PDFs merely because a copy is
available on the web.  Prefer DOI/publisher/repository links and a concise
description.  A paper may be mirrored later only when its license or explicit
redistribution terms make that appropriate.

## Immediate design lessons

1. Unit rotation quaternions and general Hamilton quaternions are different
   storage problems.  The former have a unit-norm constraint and identify q
   with -q as the same rotation; the latter do not.
2. The "smallest three" / maximum-component quaternion scheme is mature
   implementation practice and is specified precisely by Khronos meshopt.
3. Polar quantization of complex data is an established signal-processing
   subject.  Magnitude and phase need not receive equal precision.
4. Quantization of CP^(n-1) is also established.  Communications literature
   treats a unit complex vector modulo global phase as a complex line and uses
   phase-invariant/chordal distortion.
5. Existing CP^n literature is mostly about codebooks and distortion/rate, not
   tiny fixed machine layouts.  A compact deterministic scalar layout remains
   a separate engineering problem.
6. Idriç's finite-circle work should be considered independently from ordinary
   low-precision scalar formats when phase itself is a circular quantity.

---

# 1. Unit-quaternion compression: specifications and implementations

The first search did not uncover one canonical academic paper that owns the
common "smallest three" encoding.  The strongest directly implementable
sources are specifications and production/open implementations.

## Khronos: KHR_meshopt_compression / EXT_meshopt_compression quaternion filter

Primary specification:

- KHR version:
  https://github.com/KhronosGroup/glTF/tree/main/extensions/2.0/Khronos/KHR_meshopt_compression
- Earlier EXT version:
  https://github.com/KhronosGroup/glTF/tree/main/extensions/2.0/Vendor/EXT_meshopt_compression

Relevant rule:

- input is a unit quaternion;
- choose the component with largest absolute value;
- use the q ~ -q double cover to make the omitted component positive;
- omit that component and store its two-bit index;
- the remaining components have magnitude at most 1/sqrt(2);
- scale the retained components by sqrt(2) before signed-normalized
  quantization;
- reconstruct the omitted component as

    sqrt(max(0, 1 - x^2 - y^2 - z^2)).

KHR/EXT stores the filtered form in an 8-byte lane arrangement and permits a
variable effective K-bit precision inside signed 16-bit components.  We should
copy the mathematical transform and its edge-case tests before deciding
whether to copy that physical layout.

Why it matters here:

- gives a normative reconstruction rule;
- gives a deterministic omitted-component representation;
- explains the 1/sqrt(2) range bound;
- gives useful conformance cases: boundary K, negative retained components,
  and clamping before sqrt.

Do not infer:

- that an 8-byte filtered glTF layout is the right Idriç machine size;
- that glTF component order defines Hamilton semantic order;
- that this applies to arbitrary non-unit quaternions.

## jpreiss/quatcompress

https://github.com/jpreiss/quatcompress

MIT-licensed compact implementation of a normalized quaternion in 32 bits.
It uses the largest-component-positive convention and stores the other three
components plus the omitted-component index.  Its README reports random-test
rotation errors and explicitly warns about harmless q/-q sign flips.

Why it matters:

- small C implementation suitable as an independent oracle;
- concrete 32-bit packing;
- useful test methodology based on angular rotation error rather than only
  scalar component error.

## Marc B. Reynolds: Quaternion quantization, part 1

https://marc-b-reynolds.github.io/quaternions/2017/05/02/QuatQuantPart1.html

Engineering analysis of several maps from unit quaternions to three stored
coordinates, including "smallest three."  It treats the geometry of the
mapped regions and compares alternatives rather than assuming one map is
universally optimal.

Why it matters:

- useful source for comparing smallest-three against alternative ball maps;
- warns us not to confuse convenient component quantization with optimal
  rotation-space quantization;
- useful for future error sweeps.

This is an engineering article, not a formal standard or peer-reviewed paper.

## Unity Netcode QuaternionCompressor

https://docs.unity.cn/Packages/com.unity.netcode.gameobjects%402.6/api/Unity.Netcode.QuaternionCompressor.html

Unity documents a "Smallest Three Quaternion Compressor Implementation" and
the norm-based reconstruction of the omitted component.

Why it matters:

- evidence that this is mainstream network/runtime practice;
- another implementation surface for compatibility tests.

## Havok / Project Anarchy rotation quantization vocabulary

Open source mirror studied during the sweep:

https://github.com/Bewolf2/projectanarchy/blob/master/Source/Animation/Animation/Animation/SplineCompressed/hkaSplineCompressedAnimation.h

The rotation-quantization enum contains:

- POLAR32;
- THREECOMP40;
- THREECOMP48;
- THREECOMP24;
- STRAIGHT16;
- UNCOMPRESSED.

Why it matters:

- production animation code explicitly treats polar and several
  smallest-three bit budgets as separate design points;
- suggests that our tests should compare a family of budgets, not bless one
  bit count prematurely.

The enum alone is not enough to reconstruct every Havok codec and should not
be treated as a complete format specification.

## Khronos Vulkan Gaussian-splat rendering guide

https://github.khronos.org/Vulkan-Site/samples/latest/samples/complex/render_octomap/Tutorials/gaussian-splats-rendering.html

The guide describes a 32-bit smallest-three packing with ten bits for each
retained component plus a two-bit omitted-component index in the context of
Gaussian splats.

Why it matters:

- current GPU-oriented example;
- directly relevant to shader decoding cost and packed alignment.

---

# 2. Polar quantization of complex data

## Stephen D. Voran and Louis L. Scharf,
## "Polar Coordinate Quantizers That Minimize Mean-Squared Error"

IEEE Transactions on Signal Processing 42(6), 1559-1563, 1994.

Open repository record and PDF:
https://mountainscholar.org/items/7cec983e-8629-4413-9c51-544679afdf3b

Bibliographic record:
https://dblp.org/rec/journals/tsp/VoranS94

Core result relevant here:

- represent z = r exp(i phi);
- quantize magnitude and phase separately;
- optimize the pair for complex-plane mean-squared error;
- phase-only representations have analyzable limits;
- the best division of available representation levels between magnitude and
  phase depends on the source distribution.

Design consequence:

Do not assume "half the bits for magnitude, half for phase."  For our compact
formats, bit allocation must be measured against the expected data and the
actual semantic error criterion.

## J. Bucklew and N. Gallagher,
## "Quantization Schemes for Bivariate Gaussian Random Variables"

IEEE Transactions on Information Theory 25(5), 537-543, 1979.

This appeared in the polar-quantization reference trail found during the
search.  It is early work on two-dimensional Gaussian quantization and is
useful background for comparing rectangular/vector and polar partitions.

Design consequence:

Cartesian/component-wise quantization is a real competing baseline; polar
storage should beat it for the workload we care about, not merely look
mathematically natural.

## S. G. Wilson,
## "Magnitude/Phase Quantization of Independent Gaussian Variates"

IEEE Transactions on Communications 28(11), 1924-1929, 1980.

Found in the reference trail of later unrestricted-polar-quantizer work.

Design consequence:

Magnitude/phase quantization predates our intended use by decades; our novel
work, if any, is in tiny explicit machine formats and integration with typed
complex/circle semantics, not the basic idea of polar quantization.

## P. F. Swaszek and T. W. Ku,
## "Asymptotic Performance of Unrestricted Polar Quantizers"

IEEE Transactions on Information Theory 32(2), 330-333, 1986.

Later sources summarize the result as an asymptotic analysis of unrestricted
polar quantizers for circularly symmetric sources, allowing the angular
resolution to depend on radial region.

Design consequence:

A format family in which phase resolution varies with magnitude is legitimate
prior art and may be worth testing against a fixed phase field.

## D. L. Neuhoff, "Polar Quantization Revisited"

IEEE International Symposium on Information Theory, p. 60, 1997.

DOI:
https://doi.org/10.1109/ISIT.1997.612975

Short conference contribution in the later polar-quantization reference
chain.

## P. W. Moo and D. L. Neuhoff,
## "Uniform Polar Quantization Revisited"

IEEE International Symposium on Information Theory, p. 100, 1998.

DOI:
https://doi.org/10.1109/ISIT.1998.708687

The uniform-polar line is useful because our first hardware-oriented formats
will probably favor cheap regular encoders/decoders over globally optimal
irregular vector codebooks.

## Z. H. Peric and M. C. Stefanovic,
## "Asymptotic Analysis of Optimal Uniform Polar Quantization"

AEU - International Journal of Electronics and Communications 56(5),
345-347, 2002.

DOI:
https://doi.org/10.1078/1434-8411-54100111

The paper derives asymptotic distortion expressions and allows a variable
number of phase partitions at different magnitude levels.

Design consequence:

When magnitude is small, spending many phase codes can be wasteful because
phase perturbation contributes little absolute complex-plane error.  This is
directly relevant to very small bit budgets.

## E. Ravelli and L. Daudet, "Embedded Polar Quantization"

IEEE Signal Processing Letters 14(10), 657-660, 2007.

DOI:
https://doi.org/10.1109/LSP.2007.896379

Found in the later polar-quantization reference trail.

Design consequence:

Progressive/refinable polar encodings are established.  If we make a packed
format with meaningful prefixes or refinement bits, we should compare it
against this line rather than calling the idea new.

---

# 3. CP^n / complex-line / Grassmannian quantization

For a nonzero complex vector, multiplication by a nonzero complex scalar does
not change the projective point.  When representatives are normalized, the
remaining ambiguity is global phase.  Communications papers routinely
encounter exactly this object when only a beamforming direction matters.

## Krishna Kiran Mukkavilli, Ashutosh Sabharwal, Elza Erkip, Behnaam Aazhang,
## "On Beamforming With Finite Rate Feedback in Multiple-Antenna Systems"

IEEE Transactions on Information Theory 49(10), 2562-2579, 2003.

DOI:
https://doi.org/10.1109/TIT.2003.817433

Uses finite beamformer codebooks and relates good codebooks to Grassmannian
packing with chordal distance.

Why it matters:

- establishes phase-invariant/subspace geometry as the correct quantization
  geometry for the application;
- provides a competing error metric to ordinary coordinate MSE.

## David J. Love, Robert W. Heath Jr., Thomas Strohmer,
## "Grassmannian Beamforming for Multiple-Input Multiple-Output Wireless Systems"

IEEE Transactions on Information Theory 49(10), 2735-2747, 2003.

DOI:
https://doi.org/10.1109/TIT.2003.817466

Author-hosted related conference PDF:
https://engineering.purdue.edu/~djlove/papers/cpaper4.pdf

For one-dimensional complex subspaces, the codebook problem is a packing of
complex lines.  The paper minimizes maximum absolute correlation between
representatives and uses a phase-invariant criterion.

Why it matters:

- CP^(m-1) is not an accidental analogy here; it is exactly the complex-line
  object underlying the beamforming quantizer;
- chordal distance and absolute inner product give us useful acceptance
  metrics for a packed CP^n codec.

## David J. Love and Robert W. Heath Jr.,
## "Limited Feedback Unitary Precoding for Orthogonal Space-Time Block Codes"

IEEE Transactions on Signal Processing 53(1), 64-73, 2005.

DOI:
https://doi.org/10.1109/TSP.2004.838928

Author-hosted PDF:
https://engineering.purdue.edu/~djlove/papers/paper4.pdf

Extends the limited-feedback/codebook picture from one-dimensional lines to
higher-dimensional subspaces and makes the Grassmann-manifold connection
explicit.

Why it matters:

Our immediate target is CP^n, but this paper helps prevent us from baking a
CP-specific layout abstraction into something that later ought to generalize
to a Grassmannian/subspace representation.

## Bishwarup Mondal, Satyaki Dutta, Robert W. Heath Jr.,
## "Quantization on the Complex Projective Space"

Data Compression Conference (DCC), 2006.

DOI:
https://doi.org/10.1109/DCC.2006.68

Publicly surfaced author copy:
https://www.researchgate.net/publication/4229998_Quantization_on_the_complex_projective_space

This is the most directly named source found in the sweep.  It formulates a
projective quantizer on CP^(n-1), assumes unit-norm representatives and
phase-invariant distortion, and analyzes high-rate expected distortion using
the chordal metric

    d(Y1,Y2) = sqrt(1 - |Y1^H Y2|^2).

Why it matters:

- direct mathematical prior art for quantizing CP^(n-1);
- gives us a natural projective error metric;
- separates Euclidean vector quantization from the quotient-space problem.

Do not infer:

The paper's codebook/rate-distortion analysis does not itself specify our
proposed fixed packed layout.

## Takao Inoue and Robert W. Heath Jr.,
## "Kerdock Codes for Limited Feedback MIMO Systems"

ICASSP, 2008.

DOI:
https://doi.org/10.1109/ICASSP.2008.4518309

Public conference copy surfaced during search:
https://dihana.cps.unizar.es/proceedings/ICASSP/2008/pdfs/0003113.pdf

Uses structured Kerdock / mutually-unbiased-basis codebooks rather than an
unstructured numerical search.

Why it matters:

- a reminder that finite-alphabet projective codebooks can have algebraic
  structure;
- useful alternative to scalar-quantizing local coordinates.

## Takao Inoue and Robert W. Heath Jr.,
## "Kerdock Codes for Limited Feedback Precoded MIMO Systems"

IEEE Transactions on Signal Processing 57(9), 3711-3716, 2009.

DOI:
https://doi.org/10.1109/TSP.2009.2020761

Expanded structured-codebook treatment.  The quaternary alphabet is
specifically attractive for compact storage and search.

Why it matters:

If a very-low-bit CP^n format performs badly as independently quantized
coordinates, a finite structured codebook is an established alternative.

## Takao Inoue and Robert W. Heath Jr.,
## "Grassmannian Predictive Frequency Domain Compression for Limited Feedback Beamforming"

Information Theory and Applications Workshop, 2010.

DOI:
https://doi.org/10.1109/ITA.2010.5454127

Exploits correlation and predictive coding on Grassmannian-valued data.

Why it matters:

A future stream format should distinguish single-value packing from temporal
or spatial predictive compression.  We should not force prediction semantics
into the scalar representation.

## Takao Inoue and Robert W. Heath Jr.,
## "Grassmannian Predictive Coding for Limited Feedback Multiuser MIMO Systems"

ICASSP, 2011.

DOI:
https://doi.org/10.1109/ICASSP.2011.5946308

Another predictive/differential treatment of Grassmannian-valued sources.

## Stefan Schwarz, Robert W. Heath Jr., Markus Rupp,
## "Adaptive Quantization on a Grassmann-Manifold for Limited Feedback Beamforming Systems"

IEEE Transactions on Signal Processing 61(18), 4450-4462, 2013.

DOI:
https://doi.org/10.1109/TSP.2013.2270466

Repository record:
https://repositum.tuwien.at/handle/20.500.12708/155293

Examines prediction and differential quantization for correlated
one-dimensional subspaces under delay constraints.

Why it matters:

- local/tangent-space or differential projective coordinates are established
  techniques;
- useful later when packed CP^n values occur in slowly varying streams.

## David J. Love, Robert W. Heath Jr., Vincent K. N. Lau, David Gesbert,
## Bhaskar D. Rao, Matthew Andrews,
## "An Overview of Limited Feedback in Wireless Communication Systems"

IEEE Journal on Selected Areas in Communications 26(8), 1341-1365, 2008.

DOI:
https://doi.org/10.1109/JSAC.2008.081002

This is a survey rather than a codec specification.  Keep it as an index into
the broader limited-feedback literature and its terminology.

---

# 4. Candidate machine-representation questions suggested by the literature

These are research questions, **not** conclusions of the cited papers.

## General Hamilton quaternion

No unit-norm assumption and no q ~ -q quotient.

Baseline formats to test:

- four E3M2-like components;
- four E5M3-like components;
- shared exponent / block-float variants;
- pair-of-complex representation if that improves a target lowering.

Errors to record:

- per-component error;
- norm error;
- Hamilton-product error;
- conjugation/inverse residual where defined.

## Unit rotation quaternion

First baseline:

- maximum-component-positive / smallest-three transform;
- 2-bit omitted-component index;
- compare several retained-coordinate budgets;
- reconstruct by the unit-norm law;
- report actual rotation-angle error.

Compare against:

- direct four-component quantization;
- polar/ball-map alternatives from Reynolds;
- existing Khronos filter as a high-precision oracle.

Tie rule for equal largest magnitudes must be explicit and deterministic.

## Polar complex

Represent semantically as:

    magnitude + circle position

rather than presuming that phase is an ordinary floating scalar.

Tests should include:

- fixed phase-bit budget;
- phase budget conditioned on magnitude bucket;
- uniform and nonuniform magnitude quantizers;
- E3M2/E5M3 magnitude candidates;
- finite-circle candidates such as Circle96 where exact rational-turn
  landmarks matter.

Zero needs a canonical stored phase because mathematical phase is undefined at
zero.

Errors to record:

- absolute complex-plane error;
- relative magnitude error where meaningful;
- circular phase error away from zero;
- multiplication error, especially multiplication by a unit phase.

## CP^n

Two distinct families deserve experiments.

### A. Local deterministic packed coordinates

Candidate construction to investigate:

1. normalize a representative;
2. choose a deterministic pivot coordinate, plausibly the largest magnitude;
3. remove global phase by making the pivot real and nonnegative;
4. omit/reconstruct the pivot using the unit-norm constraint;
5. encode the other complex coordinates with low-precision scalar or
   magnitude/phase fields;
6. store the pivot index.

This resembles smallest-three quaternion compression, but the literature above
does **not** establish it as an optimal CP^n codec.  Treat it as our proposal.

### B. Finite projective codebook

Use an integer label into a CP^n/Grassmannian codebook.

Candidates include:

- numerically optimized Grassmannian packings;
- structured finite-alphabet codebooks such as Kerdock/MUB constructions.

This may beat scalar coordinate layouts at extremely small bit counts, at the
cost of tables/search.

Errors to record:

- chordal distance;
- |<x,y>| correlation;
- Fubini-Study angle where useful;
- ordinary coordinate error only as a debugging statistic, not as the
  projective semantic metric.

---

# 5. Repository connections

Existing Idriç work that should remain upstream of any packed layout:

- PR #45: **Add linear geometry, sphere, SO(n), and quaternion type core**
- PR #81: **Establish complex-coordinate and projective semantics**
- PR #92: **Connect quaternion fixture to complex pairs**
- PR #107: **Model compact unit-pure-quaternion storage**
- PR #118: **Add finite circle semantics and Circle96 cam geometry**

Especially important distinction:

PR #107 stores an S^2 direction, equivalently a unit **pure** quaternion
0 + xi + yj + zk.  That is not an S^3 orientation-quaternion compressor.

The broader cross-repository semantic/lowering index remains:

[ROTATION-COMPLEX-PROJECTIVE-CROSS-REFERENCES.md](ROTATION-COMPLEX-PROJECTIVE-CROSS-REFERENCES.md)

---

# 6. Next literature passes

Useful next searches, deliberately separated from implementation:

- quaternion orientation quantization under geodesic/angular distortion rather
  than component MSE;
- optimal/lattice/vector quantizers for S^3 modulo antipodes;
- direct fixed-coordinate or chart quantizers for CP^n, not only codebooks;
- Fubini-Study versus chordal error bounds for low-rate quantization;
- low-bit projective codebooks with fast index/decode on ARM Thumb-2 and GPU;
- source-dependent bit allocation for magnitude/phase at 6-16 total bits;
- whether finite-circle phase codes with exact thirds/fifths have useful
  error/algebra advantages over power-of-two phase tables for our workloads.

This file should grow by adding sources and recording what they actually
establish.  Representation proposals should remain visibly marked as proposals.
