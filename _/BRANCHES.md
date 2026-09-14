# Idriç branch map

This map records the branch topology as of 2026-08-27. It exists to prevent an
old Idris bootstrap, a backend experiment, or a closed pull-request branch from
being mistaken for the current compiler.

## Canonical lines

| Branch | Meaning | Valid base for ordinary Idriç work? |
| --- | --- | --- |
| `Idriç` | Default branch; canonical modern compiler based on current Idris 2 | Yes |
| `Odriç` | Unsettled compiler line co-designed with `ish` | Only when explicitly requested |
| `gh-pages` | Generated documentation publication | No |
| `archive/idri_dash_exact_commit` | Record of refs migrated from `Idri-` | No |
| `master` | Obsolete 2020 bootstrap history | No |
| `idric/unicode-arrows` | Obsolete broad Unicode rewrite on the 2020 history | No |

The repository is named `Idric`; the project is written `Idriç`; `Edric` is a
speech/transcription spelling. Those names do not identify three compiler
branches. There is no current branch named `main`. In ordinary conversation,
"the main branch of Idriç" means the default `Idriç` branch.

## Open pull-request branches

These are reviewable changes based on `Idriç`, not alternate compiler roots.

| Pull request | Branch | Purpose |
| --- | --- | --- |
| #6 | `float32-primitive` | Add the 32-bit floating-point primitive |
| #10 | `termux-armv7-binary` | Build the compiler for 32-bit ARMv7 Termux |
| #11 | `fix-idric-natural-vocabulary` | Use `ℕ` at the Idriç source boundary |
| #13 | `depends-on-syntax` | Restrict `depends on` to dependency declarations |
| #19 | `prelude/descriptive-io-names` | Make descriptive I/O names primary |

Preserve these names while their pull requests are open. Delete each head
branch after the change is merged or deliberately abandoned.

## Research branches

These preserve a note, example, or incomplete design probe. They are not the
current compiler and should not silently become the base of implementation
work.

- `notes/compiler-adverbs`
- `notes/gpu-backends`
- `koan-by-example`
- `projective-spaces`
- `edric-min-word-aliases` and `whole-made-of-syntax` (two names for the same
  older vocabulary experiment)

## Closed-work leftovers

Do not base new work on any branch in this section. They remain visible only
because the remote refs have not yet been removed.

Merged pull-request heads:

- `idric-source-extension`
- `choice_declaration_syntax`
- `unicode_arrow_syntax`
- `fix-bootstrap-private-scheme-path`
- `fix-edric-unicode-golden`
- `koans/idric-foundations`
- `codex/list-array-vector-vocabulary`

Redundant integration/test aliases:

- `arm-thumb-integration`, which points exactly at `Idriç`
- `icu-downstream-smoke`
- `icu-downstream-smoke-pr`
- `icu-downstream-smoke-pr-2`
- `noop-check`

Inherited upstream branch debris:

- `add-constructor-to-cat`
- `autobind-application`
- `binding-application`
- `forward-data`
- `revert-2469-trans-deps`
- `update-readme-pack`
- `v0211-compat`
- `withFC-parser-refactor`

The cleanup rule is conservative: first verify that a branch is not an open
pull-request head and that its intended work is merged, archived, or unwanted;
then remove the remote ref. Moving old upstream debris into the canonical
compiler would make the history less clear, not more complete.

## Separate repositories, not branches

| Repository | Responsibility |
| --- | --- |
| `isomorphisms/idric-arm-thumb` | ARM and Thumb backend |
| `isomorphisms/idric-risc-5` | RISC-V backend |
| `isomorphisms/idris-shader-backend` | GPU shader backends |
| `isomorphisms/Idri-` | Obsolete 2020 source/reference snapshot |

The core repository owns source syntax, elaboration, compiler intermediate
representations, and target-neutral lowering contracts. A backend repository
owns target ABI and instruction selection. Cross-repository work should name
both sides of that boundary rather than creating an ambiguously named compiler
branch.

## Naming new branches

Use a long semantic name under one namespace:

```text
syntax/<source-language-change>
compiler/<pass-or-representation-change>
prelude/<public-vocabulary-change>
platform/<device-or-build-support>
integration/<other-repository-and-contract>
notes/<research-question>
examples/<runnable-example-set>
archive/<historical-source>
```

One branch should answer one question. Avoid convenience aliases and remove
closed pull-request heads.
