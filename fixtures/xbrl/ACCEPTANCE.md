# Executable tiny XML/compiler acceptance

`XbrlCanary.idric` at the repository root is the implementation. It reads the
input file at runtime; it does not read the JSON oracle, embed the XML, or
contain the frozen offsets or numeric answer. `xbrl_acceptance.py` compares
its observations with the unchanged `tiny-instance.oracle.json`.

The core build workflow checks out the actual PR head (not a moving name or
GitHub's synthetic merge commit), bootstraps the compiler from that checkout,
and retains an exact-head receipt and artifact bundle. No compiler cache or
old compiler download substitutes for that build. Existing focused compiler
tests still run.

## Local run

From a clean checkout on Linux, with the normal host build prerequisites:

```sh
python3 xbrl_acceptance.py prepare
python3 -m unittest discover -s _/tests/xbrl -v
./_/edric all && python3 xbrl_acceptance.py stamp-build
sudo unshare --net -- python3 xbrl_acceptance.py run
```

Only stamp a compiler immediately after that successful fresh build. The
workflow enforces that order. The stamp records the checkout identity and
hashes the compiler/runtime/library files; acceptance refuses changed bytes
or a moved/dirty tracked checkout. A stamp is build provenance from the
workflow, not a cryptographic proof that an arbitrary local compiler was
honestly built. Host dependency installation/bootstrap may need the existing
Chez source download; fixture/compiler acceptance itself has no network and
never fetches SEC/XML/taxonomy data.

Outputs stay in `_/build/xbrl-acceptance/`. Each new `prepare` removes the
previous attempt's outputs, so an old executable, IR artifact, or PASS cannot
satisfy a new run. Missing prerequisites fail; there is no upstream-Idris,
host XML parser, precomputed-output, or stale-compiler fallback.

## Required stages

1. **Fixture integrity:** unchanged 282 bytes, SHA-256, ASCII and terminal LF;
   the frozen token/name/attribute slices must agree with those bytes.
2. **Compiler build and isolation:** fresh build stamp, matching current head
   and compiler/library hashes, then an isolated Linux network namespace.
3. **Core typecheck:** compile-check the actual `.idric` source.
4. **Compiler IR:** run the existing one-step emitter, verify its source/head/
   body hashes, and inspect actual ANF definition bodies for the finite
   state/class dispatch and the continuing data-run scanner.
5. **Chez code generation and execution:** compile the same source and execute
   the resulting program against the committed fixture.
6. **Search, tokenizer, bounded tree and extraction:** exact, type-sensitive
   comparisons of all four oracle objects, including every nested span,
   attribute, text node, path, depth limit and numeric value.
7. **Derived controls:** independently execute eleven deterministic changes
   made only from the committed bytes: changed income, changed Revenue,
   shifted offsets, swapped siblings, missing target, ampersand, mismatched
   close, truncated root, non-ASCII, depth overflow and byte overflow.

The four successful controls compare complete derived observation objects,
not just their final integer. Failed-input controls require nonzero exit with
the corresponding rejection reason. They are local temporary probes, not
new promoted corpus fixtures or malformed-input recovery features.

Every required stage must be `PASS` for overall `PASS`. Missing or skipped
stages do not count as success. `receipt.json` retains the first failure and
unexecuted stages as `SKIP`; bootstrap failure is explicitly recorded. The
host harness unit tests are separate evidence and never count as execution
of the Idriç implementation.

## Exact boundary

This is an ASCII/XML subset with lexical names, double-quoted attributes,
matched open/close tags, ordinary text and document-level whitespace. Bounds
are 4096 input bytes, 64 tokens (therefore no more than 64 nodes), eight
attributes per start tag and eight element levels. The root is level one for
the construction bound; it is depth zero for bounded lookup. The fixture's
terminal LF is outside the root. Decimal extraction accepts nonempty unsigned
digits and computes an `Integer`; it does not cast arbitrary text permissively.

The existing exclusions in `README.md` remain unchanged. Namespace expansion,
XBRL context/unit/taxonomy validation, entities, self-closing tags, declarations,
comments, CDATA, recovery, and live retrieval are not implemented.

The IR stage is an **ANF workload/structure witness**, not a new first-class
bulk-scan intrinsic, a performance claim, or native instruction-selection
acceptance. Execution here uses the host Chez backend. ARM/Thumb and follower
backend execution remain `NOT_VERIFIED`; this receipt does not advance those
backend checkpoints or certify their ISA/ABI lowering.
