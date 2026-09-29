# ARM/Thumb compiler comparison reference

The ICK repository's `inspiration` branch now contains a comparative study of
GCC, Clang/LLVM, TinyCC, chibicc, cproc/QBE, lacc, 8cc, cparser/libFirm,
CompCert, PCC, slimcc, and c4.

Reference:
https://github.com/dilapidated-shed/ick/tree/inspiration/inspiration

The most relevant notes for this ARM/Thumb line are:

- `gcc-contrast-notes.md` — what public compiler discussions say GCC's
  complexity buys and what smaller/differently structured compilers trade away;
- `kernel-construct-corpus.md` — real Linux-kernel constructs matched to
  constructs already used in ICK/Wegert/Pauli;
- `first-six-traces.md` — corrected paired-source traces for wrapper structs,
  `static inline`, union representation views, layout contracts, mask/shift
  extraction, and memcpy/copy lowering.

## ARM/Thumb questions to revisit

When ARM/Thumb lowering work resumes, use those comparisons to re-check:

- how local the target-description seam can be;
- whether a small direct backend or a richer intermediate representation gives
  the better trade for T32;
- ABI treatment of one-field wrapper types and small aggregates;
- constant mask/shift extraction for FP8/FP6 and finite-circle encodings;
- immediate versus register shift selection;
- call-site inlining versus merely implementing C-style inline semantics;
- explicit block-copy representation versus early lowering to loops or libcalls;
- how much optimizer machinery measurably helps the actual Idriç/ICK corpus;
- which target facts belong in the backend and which belong in higher-level
  architecture selection.

## Update rule

This note is a pointer, not a backend decision. Refresh it when the ICK
comparison gains executable cross-compiler results or when ARM/Thumb work
introduces a new IR, instruction-selection strategy, ABI boundary, or
optimization policy worth comparing against the reference compilers.
