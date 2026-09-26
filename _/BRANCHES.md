# Idriç branch roles

The canonical repository is [dilapidated-shed/Idric](https://github.com/dilapidated-shed/Idric).
The project is written **Idriç**; the repository's ASCII name is not a separate
compiler. Ordinary references to its main line mean the default **`Idriç`**
branch, not a branch named `main`.

| Line | Role |
| --- | --- |
| `Idriç` | Canonical compiler; base for ordinary language/compiler work. |
| `Odriç` | Separate compiler/shell co-design line for `ish`; use only when the task names it. |
| `gh-pages` | Generated documentation publication. |
| `archive/*`, `master`, `idric/unicode-arrows` | Preserved historical or obsolete bootstrap work; not ordinary implementation bases. |

Other named language, research, and integration branches are experiments or
task-specific work. Their existence, a merged PR into them, or several names
pointing to the same commit does not promote them to the canonical compiler.

## Find current work

Use [open pull requests](https://github.com/dilapidated-shed/Idric/pulls) and
[live branches](https://github.com/dilapidated-shed/Idric/branches). Inspect the
head, base, commits, and dependency stack before changing or deleting a branch.
Do not copy those changing lists into this document. The former August 2026
inventory remains in Git history; it is not a current retirement queue.

Keep an open PR's head and any base branch used by another open PR. Once work
is integrated or deliberately superseded, preserve needed history before
removing its ref. Intentional archives stay explicit. Age alone is not evidence
that an experiment is obsolete.

## Compiler and backend ownership

The core owns source syntax, elaboration, semantic distinctions, compiler
representations, and target-neutral handoff contracts. Separate backends own
target lowering, ABI, artifact emission, and execution evidence. See the
[root project map](../README.md#related-implementations).

In particular, `idric-arm-thumb` is a historical repository name: its `main`
branch owns direct DEX/ART, while `native-arm` owns the separate ARM/Thumb
development line. Do not infer target ownership from the repository name.

## New branch names

Use one descriptive purpose under `syntax/`, `compiler/`, `prelude/`,
`platform/`, `integration/`, `notes/`, `examples/`, or `archive/`.
One branch should answer one question. Avoid convenience aliases and remove
closed PR heads after checking dependent work and preserving useful history.
