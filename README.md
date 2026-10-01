# Idriç

Idriç is an experimental language and compiler derived from Idris 2. This is
the canonical compiler repository; its default branch is **`Idriç`**. The
ASCII repository name `Idric` and the language name refer to the same project.

The compiler implements Idriç source notation and vocabulary on the inherited
type checker and compiler. Language semantics live here; target backends own
their lowering and execution evidence. A passing host test does not establish
that a backend, Android artifact, or physical device executed that program.

Start with [the language/build checkpoint](_/EDRIC.md),
[source style](STYLE.md), and [branch roles](_/BRANCHES.md).
[Intent examples](examples/intent/railway/README.md) show the intended program
structure. Compiler implementation is exposed at the root; build machinery,
libraries, tests, and inherited documentation live under [`_/`](_/).
The root [`edric`](edric) entrypoint dispatches to that build machinery.

## Related implementations

| Project | Responsibility |
| --- | --- |
| [DEX / ARM backend repository](https://github.com/dilapidated-shed/idric-arm-thumb) | `main` is the direct DEX/ART line; [`native-arm`](https://github.com/dilapidated-shed/idric-arm-thumb/tree/native-arm) is a separate ARM/Thumb line. They are not interchangeable evidence. |
| [x86-64 backend](https://github.com/dilapidated-shed/idric-x86-aggressive-backend) | Checked compiler handoff, direct x86-64/ELF emission, and bounded native Linux fixtures. |
| [Shader backend](https://github.com/dilapidated-shed/idris-shader-backend) | GPU lowering and target-specific shader experiments. |
| [Idric-Net](https://github.com/dilapidated-shed/Idric-Net) | Networking library consumed by clients such as ICU. |
| [IB](https://github.com/dilapidated-shed/ib) | Experimental durable browser/task state; a language consumer. |
| [Grease](https://github.com/dilapidated-shed/grease) | Oils-derived shell; its `ish` branch is the separate successor co-designed with `Odriç`. |
| [Cat Food](https://github.com/isomorphisms/catfood) / [ai-ci](https://github.com/isomorphisms/ai-ci) | Workbench/runtime delivery and shared evidence verification. |

These are ownership boundaries, not claims that every planned integration is
implemented. Consult each implementation's current contract and exact receipts.
The [live pull requests](https://github.com/dilapidated-shed/Idric/pulls) are
the current work queue; merged work on an experimental branch is not necessarily
integrated into `Idriç`.
