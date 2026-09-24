# Idriç repository rules

Read [../STYLE.md](../STYLE.md) before writing or reviewing Idriç-facing source.
`STYLE.md` is the source-style authority; this file is operational repository
guidance.

Read [EDRIC.md](EDRIC.md) and [BRANCHES.md](BRANCHES.md) before changing this
repository.

## Human-facing scripts

Whenever giving the human a script or command block, assume `$PWD` is arbitrary.
Resolve repository and file paths from the script's own location, an explicit
project location, or a discovered repository root, and perform any required
`cd` inside the script. Never require the human to `cd` first or rely on relative
paths against their current working directory.

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

Before editing, resolve `repo_root` to the absolute path of the intended Idriç
checkout without assuming the caller's current directory. Then run:

```sh
: "${repo_root:?repo_root must be the absolute Idriç checkout path}"
git -C "$repo_root" fetch origin --prune
git -C "$repo_root" status --short --branch
git -C "$repo_root" worktree list
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
