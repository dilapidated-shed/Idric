# Idriç agent instructions

Before writing or reviewing Idriç-facing source, read:

1. [`STYLE.md`](STYLE.md)
2. [`examples/intent/railway/`](examples/intent/railway/README.md)
3. [`examples/intent/http_server/`](examples/intent/http_server/README.md)
4. [`_/AGENTS.md`](_/AGENTS.md) for repository and branch rules

Apply the shared evidence and acceptance guardrails in
`isomorphisms/ai-ci/AGENTS.md`.

`STYLE.md` is the canonical source-style guide. The two intent examples are the
canonical structural references. This file is operational guidance; do not copy
the full style guide into `AGENTS.md`.

The repository contains a large inherited Idris codebase. Its existence is not
permission to reproduce Idris/Haskell style in new Idriç work.

Inspect the relevant surrounding Idriç work before inventing a new pattern, but
do not promote arbitrary existing files into style authorities. Human
corrections and the canonical guide/examples take precedence.

Do not restore a rejected language ontology under its old name or a near-synonym
because it survives in inherited code, generated output, an old branch, or an
upstream convention. Preserve the current semantic distinction first.

For compiler/backend claims, bind evidence to the exact source head and material
compiler/backend pins. Source presence, generated output, compilation, and an
oracle or fallback do not prove execution through the named backend.

Keep language and mathematical semantics above compiler, ABI, storage, and
machine representations. A convenient representation may implement an object;
it does not define the object unless the language semantics explicitly say so.

Work on a branch, keep changes narrow, and run the checks relevant to the code
you changed before proposing it for merge.
