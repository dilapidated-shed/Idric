# Edric project checkpoint

This file is the durable handoff for the project called **Idriç**, **Idric**, or **Edric**. A new work thread should be able to start here without reconstructing the project from chat history.

## Canonical repository

`https://github.com/isomorphisms/Idric`

The repository's ASCII name is `Idric`. The intended project name is `Idriç`; `Edric` is also used in speech/transcription. All three names deliberately appear here so repository search can find the project.

## Foundation

Edric is an experimental Idris-derived compiler line built on the current Idris 2 compiler. The modern baseline for this checkpoint is Idris 2 commit:

`9b2116d98b5789afe3a003b234fd173c6b9aa379`

The older `isomorphisms/Idri-` / `Idris2-boot` work is historical reference only. Do **not** use that obsolete bootstrap tree as the foundation and do not replay its broad mechanical rewrite wholesale. Extract intentional language ideas from it individually and add each one to this modern tree with focused tests.

## Implementation rule

Use ordinary, current Idris 2 to implement Edric until an Edric change is itself stable enough to be deliberately dogfooded. Do not make the compiler depend on an unbuilt dialect of itself.

The first Edric-specific syntax is the storage-neutral `choice` declaration described below. The compiler remains implemented in ordinary Idris 2.

## Number and text vocabulary

Idriç source spells the unrestricted nonnegative whole-number type `Number` and
decoded character text `Text`. In a `.idric` file the frontend lowers those
names to the inherited Idris 2 bootstrap representations. Ordinary `.idr`
source remains unchanged. The inherited names are implementation and
compatibility spellings, not names for new Idriç APIs, examples, or teaching
material.

Fresh `.idric` source imports `Data.Text` when it needs the inherited text
operations. The frontend lowers that exact module boundary to `Data.String`;
ordinary `.idr` module names remain unchanged.

`Number` and `Text` describe general language values. Code should still use a
more specific semantic type—source location, byte count, path, protocol field,
and so on—when operations or invariants differ. The older `ℕ` input spelling is
accepted temporarily so existing Idriç source can migrate without a flag day;
it is not the current spelling for new source.

## Data-structure vocabulary

Edriç names a structure by what it is, not merely by whether its length is
known.

- `List A` is a list whose length is not part of its public type.
- `SizedList n A` or `ListOfLength n A` is a list whose length is part of
  its type. The length may be known in advance or computed while the program
  runs and then packaged with the list. If computing it can fail, the package
  belongs inside `Result` or `Maybe`.
- `Array n A` is indexed contiguous storage; it is not renamed merely
  because its length is known.
- `Vector` is reserved for a genuine mathematical or numeric vector,
  including shader vector values.

The inherited Idris 2 names `Vect` and `Data.Vect` remain where upstream
compatibility requires them. New Edriç APIs, examples, and explanations must
not use “vector” as a synonym for a list with a known or computed length.

## Storage-neutral choices

Files ending in `.idric` may declare a non-parameterized choice with lower
snake_case names:

```idris
choice existing_touch_target one_of
  fixed_value Number
  zero Number
  pole Number

choice touch_beginning one_of
  near_existing existing_touch_target
  empty_domain

choice placement_kind one_of
  new_zero
  new_pole
```

For Wegert, these declarations keep two decisions separate: `touch_beginning`
records what was under the finger when it went down, while `placement_kind`
records what an empty-space tap should add.

`choice` starts the declaration and `one_of` is its contextual separator.
Each indented alternative has a lower snake_case name followed by zero or more
ordinary Idris payload types. Standard documentation, visibility, and totality
modifiers are accepted; exported models should use `export` or `public export`
as usual.

The declaration means that a value is exactly one of the listed alternatives
and is lowered directly to the compiler's existing data-declaration
representation. “Storage-neutral” means the syntax makes no promise about
runtime layout, alternative marker values, alternative ordering as an ABI,
serialization, or persistent storage. It introduces neither product nor
whole-value syntax.

The dialect distinction is filename-scoped. Only `.idric` promotes `choice` to
a keyword, and `one_of` remains contextual. In ordinary `.idr` files both
`choice` and `one_of` remain available as identifiers. Lowercase choice type
and alternative names resolve correctly in signatures and exhaustive patterns,
without disabling normal Idris auto-implicit binding for unrelated lowercase
names.

## Working copy

Preferred checkout:

```sh
git clone https://github.com/isomorphisms/Idric.git /opt/Idric
cd /opt/Idric
```

If `/opt` is not writable, use `~/opt/Idric`.

## Repo-local Scheme toolchain

A system-wide Chez Scheme installation is not required. The root `edric` command installs the pinned threaded Chez Scheme toolchain under the ignored directory `.tools`:

```sh
./edric scheme
```

The stable executable path is:

```text
.tools/bin/scheme
```

The installer fetches the official Chez Scheme 10.4.1 source archive, verifies its SHA-256 digest, builds without X11 or curses, installs it under `.tools/chez-10.4.1`, and verifies that `(threaded?)` returns `#t`.

For a machine without outbound network access, provide the same verified archive explicitly:

```sh
CHEZ_ARCHIVE=/path/to/csv10.4.1.tar.gz ./edric scheme
```

The host still needs a C compiler, `make`, `tar`, and either `sha256sum` or `shasum`. `curl` or `wget` is needed only when `CHEZ_ARCHIVE` is not supplied.

## Build and test

From a clean checkout, the complete checkpoint build is:

```sh
./edric
```

That is equivalent to:

```sh
./edric scheme
./edric bootstrap
./edric test
```

The individual underlying commands remain available:

```sh
make bootstrap SCHEME="$PWD/.tools/bin/scheme"
make test only=idris2/basic/edric001
make test only=idris2/basic/edric002
make test only=idris2/basic/edric003
make test only=idris2/basic/edric004
make test only=idris2/basic/edric005
make test only=idris2/basic/edric006
make test only=idris2/basic/edric009
```

## Idriç koans

The progressive teaching suite lives in `koans`. It is part of this repository
so the exercises are checked against the exact compiler revision that defines
their syntax and semantics.

After bootstrapping the compiler, start at the first unfinished exercise:

```sh
./koans/run
```

The compiler stops at the first named hole, coverage failure, or other proof
obligation. Edit that exercise and run the command again. Reference solutions
and the suite's self-check are available separately:

```sh
./koans/run --solutions
./koans/run --validate
```

## Change discipline

For each language change:

1. Make the smallest parser, elaborator, or compiler change that expresses the idea.
2. Add a focused regression test under the existing Idris 2 test harness.
3. Keep ordinary Idris 2 behavior working unless the change explicitly replaces it.
4. Record user-visible syntax and semantic decisions here when they become part of Edric rather than leaving them only in a conversation.
5. Keep the default `Idriç` branch buildable; use a descriptive branch when an
   experiment is not yet coherent.

## New-thread handoff

A new thread working on Edric should:

1. Open this file, [BRANCHES.md](BRANCHES.md), and the root `README.md`.
2. Inspect the latest commits and current branch before changing code.
3. Use `./edric` to establish the repo-local Scheme toolchain, bootstrap the compiler, and run the focused handoff test.
4. Treat this repository as authoritative for implemented state. Conversation notes may explain intent but do not override the checked-in source and tests.
5. Update this checkpoint when a new architectural decision would otherwise be lost between threads.

## Current state

- Modern Idris 2 foundation: established.
- Durable repository handoff: established.
- Ordinary Idris 2 implementation language: established.
- Pinned repo-local threaded Chez Scheme bootstrap: established.
- Focused Edric handoff test: checked in.
- Idriç source extension: `.idric`; `.idr` remains accepted for Idris compatibility.
- Storage-neutral, lower snake_case `choice ... one_of` syntax: implemented for `.idric` only.
- Ordinary `.idr` use of `choice` and `one_of` as identifiers: preserved and regression-tested.
- Idriç source spells nonnegative whole numbers `Number` and decoded character
  text `Text`; the frontend lowers both to inherited bootstrap representations.
- Idriç source spells the inherited text-operation module `Data.Text`; the
  frontend lowers that exact module boundary to `Data.String`.
- The older `ℕ` spelling remains a migration alias, not the current spelling.
- Idriç source accepts `→`, `⇒`, `←`, and `≤` as compact aliases for `->`, `=>`, `<-`, and `<=`; the ASCII spellings remain accepted.
- The aliases are filename-scoped to `.idric`; ordinary `.idr` Unicode identifiers remain unchanged.
- Canonical Unicode pretty-printing is not yet claimed by this input-syntax slice.
- Historical broad mechanical Unicode rewrite: reference only, not the base.
- Twelve progressive Idriç koans cover holes, dependent types, quantitative
  multiplicities, storage-neutral choices, compatibility boundaries, and a
  small Wegert model; their exercises and solutions are compiler-tested.
- The focused `edric009` example reconciles nominal finite-space identity,
  rank-indexed names, distinct exact vector/covector samples, explicit
  standard-coordinate Euclidean structure, typed contraction, connected exact
  `R^128` orthogonal generators, the finite presheaf restriction model, and one
  provenance-labelled named fact.  It is a bounded semantic example, not a
  complete real-scalar model or general mathematics engine.
