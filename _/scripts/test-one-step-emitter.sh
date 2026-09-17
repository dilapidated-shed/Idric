#!/bin/sh
set -eu

support_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
source="$support_root/examples/compiler-one-step/PrintX.idric"
temporary=$(mktemp -d)
trap 'rm -rf "$temporary"' EXIT HUP INT TERM

first="$temporary/print-x.first.one-step"
second="$temporary/print-x.second.one-step"
"$support_root/edric" --emit-one-step "$source" -o "$first"
"$support_root/edric" --emit-one-step "$source" -o "$second"

cmp "$first" "$second"
source_sha=$(sha256sum "$source" | cut -d' ' -f1)
compiler_head=$(git -C "$support_root" rev-parse HEAD)
test "$(head -n 1 "$first")" = "$(printf 'EDRIC_ONE_STEP\t1')"
grep -Fx "$(printf 'source_sha256\t%s' "$source_sha")" "$first"
grep -Fx "$(printf 'compiler_head\tisomorphisms/Idric\t%s' "$compiler_head")" "$first"
grep -Fx "$(printf 'core_typecheck\tPASS')" "$first"
grep -Fx "$(printf 'representation\tidris2-anf-show-0.8.0')" "$first"
grep -F "PrintX.main = [0]: %let v1 = ('X') in (Prelude.IO.prim__putChar(v1, v0))" "$first"
test "$(tail -n 1 "$first")" = end

body="$temporary/body"
{
  printf 'EDRIC_ONE_STEP_BODY\t1\n'
  sed -n '/^definitions_begin$/,/^definitions_end$/p' "$first" | sed '1d;$d'
} > "$body"
body_sha=$(sha256sum "$body" | cut -d' ' -f1)
grep -Fx "$(printf 'body_sha256\t%s' "$body_sha")" "$first"

printf '%s\n' 'Idriç compiler one-step emitter: PASS'
