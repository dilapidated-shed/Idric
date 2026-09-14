# Idriç source style

This is the canonical style guide for new Idriç-facing source. It records rules
that have actually been decided; it is not a license to fill gaps with ordinary
Idris, Haskell, or generic functional-programming habits.

This repository contains two source strata. Files ending in `.idric` show the
Idriç language being designed. Files ending in `.idr` implement the bootstrap
compiler or preserve the inherited Idris 2 compatibility surface. Do not make
the first look like renamed Idris, and do not mechanically restyle the second
as though its external and bootstrap names were Idriç names.

The canonical intent examples are:

- [`examples/intent/railway/`](examples/intent/railway/README.md)
- [`examples/intent/http_server/`](examples/intent/http_server/README.md)

Read them as examples of structure and vocabulary, not as a frozen grammar.

## Say what the program is doing first

Top-level code should read like a short, purpose-ordered recipe. Put intent above
mechanism. A reader should be able to understand the job before descending into
parsing, buffers, FFI calls, syscalls, allocation, or another implementation
choice.

Prefer meaningful domain phrases and semantic roles. For example:

```idric
connection ← accept connection from listener
request ← read request from connection
response ← answer request
write response to connection
```

Prefer grammatical phrases with words such as `from`, `to`, `on`, `with`,
`using`, and `via` when they make roles clear. Avoid piles of positional
arguments whose meaning is recoverable only from a signature.

Do not force a semantic phrase to mirror the filesystem. `read request from
connection` can have one meaning even if its implementation eventually lives
under `read/`, `request/`, `connection/`, or another sensible deep-dive path.

Compiler directives are mechanism. Maintained `.idric` source is total by
default, so it does not begin with `%default total`. Use an explicit function-
level or file directive only when the source deliberately chooses another
totality contract, and explain why. Processing an `.idric` file must not change
the inherited default for a later `.idr` compatibility file.

`public export` is for an API that downstream modules must be able to re-export;
it is not a ceremonial prefix for every definition.

## Names must carry meaning

Use ordinary or domain vocabulary instead of inherited implementation jargon.
A name should tell the reader what a value or action means in this program.

Use `snake_case`, not lowerCamelCase, for ordinary identifiers.

Avoid names such as `ExternalInvocation`, `InvokeExternal`, abbreviations that
save little space, and generic numbered/positional names when a domain name is
available.

Prefer semantic types at boundaries: port, duration, byte count, HTTP method,
destination, output pin, and similar roles are better than exposing a generic
machine representation.

## Types should describe the domain

Do not introduce `Nat` or the older migration spelling `ℕ` in new `.idric`
source. Use `Number` for the maintained whole-number surface. Do not reintroduce
a separate `Cardinality` type merely to split counts away from `Number`.

Use `Text`, not `String`, for decoded character text in new `.idric` source, and
import `Data.Text` for text operations. These Idriç spellings map to the
inherited string representation and `Data.String` implementation inside the
bootstrap compiler. Ordinary `.idr` compatibility source keeps `String` and the
exact `Data.String` module name unchanged.

Use a semantic type instead of `Number`, `Text`, a raw integer, `Bits8`, or a
flag when the value has narrower operations or invariants.

Do not introduce generic `Vect` merely because Idris provides it. Use `List`
when length is not part of the meaning. If length or shape matters, preserve
that fact with a domain-specific collection such as `SizedList` or
`ListOfLength`. Use `Array` for contiguous indexed storage. Reserve `Vector` for
a mathematical vector-space value. `Vect` survives only at an explicit Idris
compatibility boundary.

Do not leak raw representations such as `Bits8` into domain code when a named
alias or restricted semantic type would say what the bytes mean.

Strong typing should clarify real boundaries and relationships, not turn the
source into type-theory ceremony.

## Notation

Use real Unicode notation in Idriç-facing source and documentation where the
language accepts it.

- `→` for type/result direction
- `←` for effectful binding or receiving a result
- `⇒` for branch/result notation where applicable
- `=` for equality
- `≠` for inequality
- `≝` for “defined as” in intent notation and documentation
- `∘` for composition where it actually clarifies the expression
- Unicode `−` for mathematical minus rather than an ASCII hyphen when writing
  mathematical notation

Do not use ASCII `->` or `<-` as substitutes for Idriç-facing arrows.

Use `$` when it materially removes nested parentheses and makes the expression
read in its natural order. Do not add punctuation merely to imitate another
functional language.

Avoid gratuitous currying, bare-application chains, constructor-led program
descriptions, and implementation types in domain vocabulary.

## Preserve semantic boundaries

Receive and validate raw data once, retain its source identity and semantic
meaning, and lower it explicitly at the next raw boundary. Distinguish text
from bytes, paths from arbitrary text, units and widths, protocol states, and
structured results from Boolean or integer projections. Prefer a named record
when tuple positions have different meanings.

Keep target-neutral checked forms above target-specific lowering. RefC is not a
maintained Idriç backend or fallback. Do not install, invoke, or cite RefC or its
GMP dependency as acceptance for current Idriç work. A direct DEX, Wasm,
machine-code, GPU, or other maintained backend must generate its own target in
its production path and fail closed for unsupported semantics.

Preserve an explicitly chosen numeric width through checking, IR, and lowering.
Float16 is the ordinary source default; Float32 remains deliberate, and neither
is silently carried as or narrowed from an unrelated host `Double`.

## Expose mechanism by descent

Use the filesystem as a deep-dive structure. Descriptive top-level files and
directories should expose purpose; deeper files can expose concrete algorithms,
foreign calls, and machine details. One concrete implementation per file is
fine when it makes alternatives inspectable.

A directory may contain multiple implementations of the same high-level action.
Callers should import the implementation or small aggregation they actually
need rather than pulling in a broad library by default.

Hide FFI declarations, primitives, host-language glue, raw syscalls, and similar
machinery below high-level wrappers. Explain why a primitive or foreign boundary
exists and what guarantee or constraint it carries.

Keep build machinery under `_/` rather than mixing it with the domain hierarchy.
When implementation is split away from the high-level declaration, keep the
source relationship easy to follow from the top level.

The maintained compiler source is exposed at the repository root. Build
machinery, the pinned bootstrap tree, upstream libraries, inherited tests, and
generated output live under `_`. Do not style those imported strata as newly
written Idriç. New language examples use `.idric`; Idris bootstrap and external
compatibility source remains `.idr`.

Keep `.gitattributes` accurate so `.idric` is recognized and generated,
vendored, bootstrap, and foreign material does not distort repository language
statistics. Retain source/specification provenance for unusual inherited or
foreign mechanisms without copying their architecture into new code.

## Explain non-obvious constants

Special numeric values, encoding boundaries, UTF-8 cutoffs, protocol numbers,
bit masks, opcodes, representation conversions, and similar constants need
semantic names or a short explanation. The source should not require a reader
to recognize an unexplained magic number.

## Meaning errors are not style errors

Do not hard-code readability preferences into the grammar merely to enforce a
house style.

A compiler error is appropriate when meaning cannot be resolved, is ambiguous,
or is contradictory. For example, if no visible definition can give meaning to
`read request from connection`, report that unresolved semantic phrase and the
roles that were understood.

Warnings are appropriate when the program has a meaning but naming, morphology,
metadata, or an expected relationship looks suspicious.

Formatting and style checks should handle readability conventions such as
English-like phrasing, unnecessary abbreviations, positional argument piles,
and similar choices that do not make the program meaningless.

## Acceptance must match the claimed boundary

Every language change needs a focused `.idric` acceptance case and a matching
`.idr` compatibility case when tokenization or parsing could affect Idris.
Acceptance must identify the exact compiler revision, prove the intended source
or artifact structure, and run behavior at the claimed boundary.

Use `PASS`, `FAIL`, `SKIP`, and `BLOCKED` accurately. Do not turn an unsupported
backend, an emulator, a stale branch, or an unrelated fallback into evidence for
the claimed target.

## Human corrections remain authoritative

These rules and the canonical intent examples are deliberately small. They do
not make every existing Idriç-family file canonical. Inherited Idris code in
this repository is especially not a style template for new Idriç work.

When a human correction establishes or changes a convention, update this guide
or the canonical examples rather than repeatedly falling back to the old
habit. Do not silently broaden a local example into a language-wide rule.
