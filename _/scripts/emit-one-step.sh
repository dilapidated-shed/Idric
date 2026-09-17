#!/bin/sh
set -eu

support_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
compiler="$support_root/build/exec/idris2"

usage() {
  echo "usage: ./_/edric --emit-one-step SOURCE -o ARTIFACT" >&2
  exit 2
}

[ "$#" -eq 3 ] || usage
source=$1
case "$2" in
  -o|--output) ;;
  *) usage ;;
esac
output=$3

[ -f "$source" ] || { echo "Idriç one-step emitter: source not found: $source" >&2; exit 2; }
[ -x "$compiler" ] || {
  echo "Idriç one-step emitter: compiler is not bootstrapped; run ./_/edric bootstrap" >&2
  exit 2
}

caller_pwd=$(pwd)
source_dir=$(CDPATH='' cd -- "$(dirname -- "$source")" && pwd)
source_name=$(basename -- "$source")
source_path="$source_dir/$source_name"
case "$output" in
  /*) output_path=$output ;;
  *) output_path="$caller_pwd/$output" ;;
esac
output_dir=$(dirname -- "$output_path")
output_name=$(basename -- "$output_path")
mkdir -p "$output_dir"

body_name=".$output_name.body.$$"
body_path="$output_dir/$body_name"
tmp="$output_path.tmp.$$"
build_dir="$output_dir/.$output_name.build.$$"
mkdir -p "$build_dir"
trap 'rm -rf "$build_dir"; rm -f "$body_path" "$tmp"' EXIT HUP INT TERM

idric_library_path="$support_root/libs/prelude/build/ttc:$support_root/libs/base/build/ttc:$support_root/libs/linear/build/ttc:$support_root/libs/network/build/ttc:$support_root/libs/contrib/build/ttc:$support_root/libs/test/build/ttc:"
(
  cd "$source_dir"
  PATH="$support_root/.tools/bin:$PATH" \
  IDRIS2_PREFIX="$support_root/bootstrap-build" \
  IDRIS2_PATH="$idric_library_path" \
    "$compiler" --cg idric-one-step --build-dir "$build_dir" \
      --output-dir "$output_dir" -o "$body_name" "$source_name"
)

[ "$(head -n 1 "$body_path")" = "$(printf 'EDRIC_ONE_STEP_BODY\t1')" ] || {
  echo "Idriç one-step emitter: compiler returned the wrong artifact body" >&2
  exit 1
}

set -- $(sha256sum "$source_path")
source_sha256=$1
set -- $(sha256sum "$body_path")
body_sha256=$1
compiler_head=$(git -C "$support_root" rev-parse HEAD)

{
  printf 'EDRIC_ONE_STEP\t1\n'
  printf 'source_sha256\t%s\n' "$source_sha256"
  printf 'compiler_head\tisomorphisms/Idric\t%s\n' "$compiler_head"
  printf 'core_typecheck\tPASS\n'
  printf 'representation\tidris2-anf-show-0.8.0\n'
  printf 'body_sha256\t%s\n' "$body_sha256"
  printf 'definitions_begin\n'
  tail -n +2 "$body_path"
  printf 'definitions_end\n'
  printf 'end\n'
} > "$tmp"
mv "$tmp" "$output_path"
rm -rf "$build_dir"
trap - EXIT HUP INT TERM
