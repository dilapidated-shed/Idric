# Idriç repository rules

Read [../STYLE.md](../STYLE.md) before writing or reviewing Idriç-facing source.
`STYLE.md` is the source-style authority; this file is operational repository
guidance.

Read [EDRIC.md](EDRIC.md) and [BRANCHES.md](BRANCHES.md) before changing this
repository.

## Identify the compiler line first

- `Idriç` is the default branch and the canonical modern compiler line. It is
  based on current Idris 2.
- There is no current `main` branch. When the user says "the main branch of
  Idriç", use `Idriç` unless they explicitly name another line.
- `Odriç` is the deliberately unsettled compiler/shell co-design line. Do not
  use it for ordinary Idriç parser or compiler work unless the user names it.
- `master`, `idric/unicode-arrows`, and
  `archive/idri_dash_exact_commit` preserve old bootstrap history. They are
  reference material, never implementation bases.
- ARM/Thumb, RISC-V, and shader backend work belongs in their separate
  repositories. A backend integration branch here must state the exact core
  compiler contract it is integrating.

Before editing, run:

```sh
git fetch origin --prune
git status --short --branch
git worktree list
```

Do not switch, reset, stash, rebase, or overwrite a dirty worktree merely to
make it current. Preserve it and reconcile its base deliberately.

## Branch names

Use one descriptive purpose after one of these prefixes:

- `syntax/` for source grammar and notation;
- `compiler/` for compiler passes and internal representations;
- `prelude/` for public language vocabulary;
- `platform/` for build and device support;
- `integration/` for an explicit boundary with another repository;
- `notes/` or `examples/` for non-implementation research;
- `archive/` only for intentionally retained history.

Prefer long semantic names. Do not introduce `ANF` as a branch, module, or type
name without also stating the exact representation guarantee. Avoid agent
names, `fix`, `noop`, `pr`, or bare issue numbers as the only explanation of a
branch.

Do not create a second branch pointing at the same commit as a convenience
alias. After a pull request is merged or closed, remove its head branch unless
it is an intentional archive.
