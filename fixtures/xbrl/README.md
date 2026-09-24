# Tiny XBRL/XML parser canary

This directory starts the public-data parser corpus from `#73` with one deliberately small **synthetic, XBRL-like XML** document. It is a compiler/parser canary, not a schema-valid SEC filing.

## Frozen input

`tiny-instance.xml` is UTF-8 in the ASCII subset, has no BOM or CR bytes, and has exactly one terminal LF.

- byte count: `282`
- SHA-256, including the terminal LF: `936f6516b375941feb1f44ed2cdabfce7ee7d2793f473b0a5c09543a59330b4a`
- source URL: none; this fixture is synthetic

The complete bytes, with the final LF written as `\n`, are:

```text
<xbrli:xbrl xmlns:xbrli="http://www.xbrl.org/2003/instance" xmlns:us-gaap="http://fasb.org/us-gaap/2026"><us-gaap:Revenue contextRef="quarter" unitRef="USD">125000</us-gaap:Revenue><us-gaap:NetIncomeLoss contextRef="quarter" unitRef="USD">18000</us-gaap:NetIncomeLoss></xbrli:xbrl>\n
```

All spans below and in `tiny-instance.oracle.json` are zero-based half-open byte spans `[start, end)`.

## Fixed-byte search oracle

For ASCII bytes `NetIncomeLoss`:

- needle length: `13`
- first match: `190`
- all matches: `[190,203)`, `[254,267)`
- match count: `2`

This is byte search, not Unicode case folding and not XML-aware matching.

## Tokenizer oracle

The semantic token stream is:

```text
[0,105)   start_tag xbrli:xbrl
[105,157) start_tag us-gaap:Revenue
[157,163) text      125000
[163,181) end_tag   us-gaap:Revenue
[181,239) start_tag us-gaap:NetIncomeLoss
[239,244) text      18000
[244,268) end_tag   us-gaap:NetIncomeLoss
[268,281) end_tag   xbrli:xbrl
[281,282) text      LF
EOF        offset 282
```

The exact tag-name, attribute-name, attribute-value, and token spans are in the JSON oracle.

For the hot data-state bulk scan with structural byte set `{ '<', '&' }`:

```text
start 157 -> stop 163 on '<' : 125000
start 239 -> stop 244 on '<' : 18000
start 281 -> stop 282 on EOF : LF
```

The implementation may choose its own finite state and byte-class constructor names. The correctness oracle is the emitted semantic tokens, exact spans, scan stopping points, and final offset; compiler/IR inspection separately checks that finite `(state, class)` dispatch and bulk-scan meaning have not been erased.

## Tree/traversal oracle

For v1, qualified names remain lexical strings. Namespace expansion is deliberately a later XML semantic slice.

Element preorder:

```text
[]    xbrli:xbrl                 [0,281)
[0]   us-gaap:Revenue            [105,181)
[1]   us-gaap:NetIncomeLoss      [181,268)
```

Including text nodes:

```text
[]      element xbrli:xbrl
[0]     element us-gaap:Revenue
[0,0]   text    125000  [157,163)
[1]     element us-gaap:NetIncomeLoss
[1,0]   text    18000   [239,244)
```

Bounded descendant search from the root for `us-gaap:NetIncomeLoss` must therefore give:

```text
max_depth = 0 -> no result
max_depth = 1 -> [1]
```

The terminal LF is document-level whitespace and is not a child of the root element.

## Extracted-value oracle

For `us-gaap:NetIncomeLoss` at path `[1]`:

```text
contextRef = quarter
unitRef    = USD
raw text   = 18000
text span  = [239,244)
integer    = 18000
```

`Revenue = 125000` at `[0]` is a sibling/negative-control value so a traversal that merely returns the first numeric fact cannot pass.

## Correctness boundary

Compiler/backend correctness consumes only the committed `tiny-instance.xml` bytes. It must not perform DNS, HTTP, SEC/EDGAR retrieval, taxonomy fetching, or any other live lookup.

A host-side fixture-integrity step may verify byte count and SHA-256 before running parser/compiler acceptance; implementing SHA-256 is not part of this parser milestone.

Live retrieval belongs on a separate ICU refresh/differential path. A live response may be captured with provenance and promoted as a **new versioned fixture** after review, but network availability or upstream content changes must never decide whether compiler correctness passes.

## Explicitly later

This first canary does not require:

- XML declaration handling;
- namespace URI expansion/resolution;
- XBRL context/unit/taxonomy validation;
- entities or character references;
- comments, CDATA, processing instructions, or doctype;
- self-closing tags;
- malformed-input recovery;
- real SEC/network-derived bytes.

Those should be separate fixtures only when each adds a specific parser/compiler distinction.
