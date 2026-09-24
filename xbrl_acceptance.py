#!/usr/bin/env python3
"""Offline, exact-head Idriç acceptance for the one frozen XML canary.

Host Python checks integrity and observations; it never parses XML for the
implementation. A fresh compiler build and a network namespace are required.
Generated logs, compiler handoff, executable and receipt stay under _/build/.
"""
from __future__ import annotations

import argparse
import copy
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parent
OUT = ROOT / "_" / "build" / "xbrl-acceptance"
FIXTURE = ROOT / "fixtures" / "xbrl" / "tiny-instance.xml"
ORACLE = FIXTURE.with_name("tiny-instance.oracle.json")
SOURCE = ROOT / "XbrlCanary.idric"
FROZEN_SHA256 = "936f6516b375941feb1f44ed2cdabfce7ee7d2793f473b0a5c09543a59330b4a"
STAGES = ("fixture_integrity", "compiler_build", "network_isolation", "core_typecheck",
          "compiler_ir", "chez_codegen", "compiled_execution", "fixed_search",
          "tokenizer", "bounded_tree", "extraction", "derived_controls")
SECTIONS = (("fixed_search", "search"), ("tokenizer", "tokenizer"),
            ("bounded_tree", "traversal"), ("extraction", "extraction"))


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def strict_json(text: str) -> object:
    def pairs(items: list[tuple[str, object]]) -> dict:
        result = {}
        for key, value in items:
            require(key not in result, f"duplicate JSON key: {key}")
            result[key] = value
        return result
    return json.loads(text, object_pairs_hook=pairs,
                      parse_constant=lambda value: (_ for _ in ()).throw(ValueError(value)))


def equivalent(actual: object, expected: object) -> bool:
    # Unlike Python's ==, distinguish true/1 and 18000.0/18000.
    options = dict(sort_keys=True, ensure_ascii=True, allow_nan=False, separators=(",", ":"))
    return json.dumps(actual, **options) == json.dumps(expected, **options)


def projection(oracle: dict) -> dict:
    return {name: oracle[name] for _, name in SECTIONS}


def integrity(data: bytes, oracle: dict) -> None:
    require(oracle["version"] == 1 and oracle["synthetic"] is True, "wrong fixture version/source")
    require(oracle["source_url"] is None, "live source is forbidden")
    require(oracle["correctness_boundary"]["network"] == "forbidden", "network boundary changed")
    require(len(data) == oracle["byte_count"] == 282, "fixture byte count changed")
    require(digest(data) == oracle["sha256"] == FROZEN_SHA256, "fixture SHA-256 changed")
    require(data.isascii() and b"\r" not in data and not data.startswith(b"\xef\xbb\xbf"), "not frozen ASCII")
    require(data.endswith(b"\n") and not data.endswith(b"\n\n"), "terminal LF changed")
    # Check that the frozen semantic oracle actually describes its frozen slices.
    def span_text(span: list[int], value: str) -> None:
        lo, hi = span
        require(0 <= lo <= hi <= len(data), "oracle span out of bounds")
        require(data[lo:hi] == value.encode("ascii"), f"oracle slice mismatch at {span}")
    needle = oracle["search"]["needle"]
    matches = oracle["search"]["matches"]
    require(oracle["search"]["count"] == len(matches), "search count mismatch")
    for span in matches:
        span_text(span, needle)
    cursor = 0
    for token in oracle["tokenizer"]["tokens"]:
        require(token["span"][0] == cursor, "oracle token gap/overlap")
        cursor = token["span"][1]
        if token["kind"] == "text":
            span_text(token["span"], token["value"])
        else:
            span_text(token["name_span"], token["name"])
            for attr in token.get("attributes", []):
                span_text(attr["name_span"], attr["name"])
                span_text(attr["value_span"], attr["value"])
    require(cursor == oracle["tokenizer"]["final_offset"] == len(data), "oracle EOF mismatch")
    span_text(oracle["extraction"]["text_span"], oracle["extraction"]["raw_text"])


def git(*args: str) -> str:
    return subprocess.check_output(["git", "-C", str(ROOT), *args], text=True).strip()


def identity() -> dict:
    head = git("rev-parse", "HEAD")
    require(not git("status", "--porcelain", "--untracked-files=no"), "tracked checkout is dirty")
    require(head == os.environ.get("IDRIC_EXPECTED_HEAD", head), "not the requested exact head")
    return {"head": head, "tree": git("rev-parse", "HEAD^{tree}"),
            "source_sha256": digest(SOURCE.read_bytes()),
            "fixture_sha256": digest(FIXTURE.read_bytes()),
            "oracle_sha256": digest(ORACLE.read_bytes()),
            "runner_sha256": digest(Path(__file__).read_bytes())}


def compiler_manifest() -> dict[str, str]:
    roots = [ROOT / "_" / "build" / "exec", ROOT / "_" / "bootstrap-build"]
    roots += list((ROOT / "_" / "libs").glob("*/build/ttc"))
    require((roots[0] / "idris2").is_file(), "current compiler is missing")
    files = sorted({p for root in roots for p in root.rglob("*") if p.is_file()})
    require(files, "empty compiler manifest")
    return {str(p.relative_to(ROOT)): digest(p.read_bytes()) for p in files}


def save(receipt: dict) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    tmp = OUT / "receipt.tmp"
    tmp.write_text(json.dumps(receipt, indent=2, sort_keys=True) + "\n")
    tmp.replace(OUT / "receipt.json")


def overall(receipt: dict) -> str:
    return "PASS" if all(receipt["stages"].get(s) == "PASS" for s in STAGES) else "FAIL"


def prepare() -> None:
    # A new attempt cannot reuse an old executable, handoff, stamp or PASS.
    if OUT.exists():
        shutil.rmtree(OUT)
    OUT.mkdir(parents=True)
    receipt = {"version": 1, "status": "NOT_VERIFIED", "stages": dict.fromkeys(STAGES, "SKIP"),
               "scope": "Idriç core/ANF handoff and Linux Chez execution; no native-backend claim",
               "native_backend_execution": "NOT_VERIFIED"}
    try:
        receipt["identity"] = identity()
        integrity(FIXTURE.read_bytes(), strict_json(ORACLE.read_text()))
        receipt["stages"]["fixture_integrity"] = "PASS"
    except Exception as exc:
        receipt["stages"]["fixture_integrity"] = "FAIL"
        receipt["status"] = "FAIL"
        receipt["error"] = str(exc)
        raise
    finally:
        save(receipt)


def load_receipt() -> dict:
    require((OUT / "receipt.json").is_file(), "run prepare and a fresh bootstrap first")
    return strict_json((OUT / "receipt.json").read_text())


def stamp_build() -> None:
    receipt = load_receipt()
    try:
        require(identity() == receipt["identity"], "checkout moved during compiler build")
        manifest = compiler_manifest()
        (OUT / "compiler-manifest.json").write_text(json.dumps(manifest, sort_keys=True) + "\n")
        receipt["compiler_manifest_sha256"] = digest((OUT / "compiler-manifest.json").read_bytes())
        receipt["stages"]["compiler_build"] = "PASS"
    except Exception as exc:
        receipt["stages"]["compiler_build"] = "FAIL"
        receipt["status"] = "FAIL"
        receipt["error"] = str(exc)
        raise
    finally:
        save(receipt)


def isolated() -> bool:
    # In an unshared Linux network namespace only the down loopback exists.
    path = Path("/proc/net/dev")
    if not path.is_file():
        return False
    interfaces = {line.split(":", 1)[0].strip() for line in path.read_text().splitlines() if ":" in line}
    return interfaces == {"lo"}


def environment() -> dict[str, str]:
    env = os.environ.copy()
    support = ROOT / "_"
    env["PATH"] = str(support / ".tools" / "bin") + os.pathsep + env.get("PATH", "")
    env["CHEZ"] = str(support / ".tools" / "bin" / "scheme")
    env["IDRIS2_PREFIX"] = str(support / "bootstrap-build")
    env["IDRIS2_PATH"] = os.pathsep.join(str(support / "libs" / lib / "build" / "ttc")
                                        for lib in ("prelude", "base", "linear", "network", "contrib", "test"))
    env.pop("IDRIS2_CG", None)
    return env


def command(label: str, argv: list[str], timeout: int = 240, failure_expected: str | None = None) -> str:
    result = subprocess.run(argv, cwd=ROOT, env=environment(), text=True,
                            capture_output=True, timeout=timeout)
    (OUT / f"{label}.stdout").write_text(result.stdout)
    (OUT / f"{label}.stderr").write_text(result.stderr)
    if failure_expected is None:
        require(result.returncode == 0, f"{label} exited {result.returncode}; see {label}.stderr")
    else:
        require(result.returncode != 0 and failure_expected in result.stdout,
                f"{label} did not reject with {failure_expected!r}")
    return result.stdout


def inspect_ir(text: str, source_sha: str, head: str) -> None:
    header, definitions = text.split("definitions_begin\n", 1)
    body, tail = definitions.split("definitions_end\n", 1)
    require(tail == "end\n", "bad one-step footer")
    lines = header.splitlines()
    require(lines[0] == "EDRIC_ONE_STEP\t1", "wrong one-step version")
    fields = {}
    for line in lines[1:]:
        key, value = line.split("\t", 1)
        require(key not in fields, "duplicate one-step header")
        fields[key] = value
    require(fields["source_sha256"] == source_sha, "one-step source mismatch")
    require(fields["compiler_head"] == "isomorphisms/Idric\t" + head, "stale one-step compiler")
    require(fields["core_typecheck"] == "PASS", "core typecheck absent")
    require(fields["representation"] == "idris2-anf-show-0.8.0", "unknown one-step representation")
    require(fields["body_sha256"] == digest(("EDRIC_ONE_STEP_BODY\t1\n" + body).encode()), "IR digest mismatch")
    # Inspect actual definition bodies, never a source comment or envelope label.
    definitions_by_name = dict(line.split(" = ", 1) for line in body.splitlines() if " = " in line)
    def family(name: str) -> str:
        return "\n".join(value for key, value in definitions_by_name.items()
                         if "XbrlCanary." + name in key)
    dispatch = family("state_class_step")
    scan = family("scan_loop")
    require("%case " in dispatch, "finite state/class dispatch absent from ANF")
    # Current ANF lowers these nullary enums to integer constant alternatives,
    # so constructor names are not guaranteed to survive the representation.
    # The envelope already binds this IR to the exact source and compiler head.
    named_dispatch = all("XbrlCanary." + constructor in dispatch for constructor in
                         ("DataState", "NameState", "QuotedState", "AngleOpen", "Ampersand"))
    lowered_dispatch = dispatch.count("%case ") >= 4 and dispatch.count("%constalt(") >= 10
    require(named_dispatch or lowered_dispatch, "finite state/class alternatives absent from ANF")
    require("%case " in scan, "data-run scanner absent from ANF")
    require("XbrlCanary.classify_byte" in scan, "scanner lost byte classification")
    require("XbrlCanary.state_class_step" in scan, "scanner lost state/class dispatch")
    require("XbrlCanary.scan_loop" in scan, "scanner lost its continuing run")
    # This is a checked ANF workload witness, NOT native instruction selection
    # and NOT a claim that ANF has gained a first-class bulk-scan intrinsic.


def replace_scalar(value: object, before: str, after: str) -> object:
    if isinstance(value, dict):
        return {key: replace_scalar(item, before, after) for key, item in value.items()}
    if isinstance(value, list):
        return [replace_scalar(item, before, after) for item in value]
    return after if value == before else value


def shift_spans(value: object, delta: int) -> object:
    if isinstance(value, dict):
        return {key: ([x + delta for x in item] if key.endswith("span") else shift_spans(item, delta))
                for key, item in value.items()}
    if isinstance(value, list):
        return [shift_spans(item, delta) for item in value]
    return value


def controls(data: bytes, expected: dict, executable: Path) -> list[str]:
    passed = []
    def check(label: str, altered: bytes, wanted: dict | None = None, error: str | None = None) -> None:
        path = OUT / f"{label}.xml"
        path.write_bytes(altered)
        stdout = command(label, [str(executable), str(path)], timeout=30, failure_expected=error)
        if wanted is not None:
            require(equivalent(strict_json(stdout), wanted), f"{label} output mismatch")
        passed.append(label)
    changed = replace_scalar(copy.deepcopy(expected), "18000", "18001")
    changed["extraction"]["integer_value"] = 18001
    check("changed-income", data.replace(b">18000<", b">18001<"), changed)
    changed = replace_scalar(copy.deepcopy(expected), "125000", "999999")
    check("revenue-negative-control", data.replace(b">125000<", b">999999<"), changed)
    shifted = shift_spans(copy.deepcopy(expected), 1)
    shifted["search"]["first_match"] += 1
    shifted["search"]["matches"] = [[x + 1 for x in span] for span in expected["search"]["matches"]]
    shifted["tokenizer"]["final_offset"] += 1
    shifted["tokenizer"]["tokens"].insert(0, {"kind": "text", "span": [0, 1], "value": "\n"})
    shifted["tokenizer"]["data_scans"].insert(0, {"span": [0, 1], "bytes": "\n", "terminator": "0x3c"})
    check("shifted-offsets", b"\n" + data, shifted)
    swapped = copy.deepcopy(expected)
    ts = expected["tokenizer"]["tokens"]
    swapped["tokenizer"]["tokens"] = [ts[0]] + shift_spans(ts[4:7], -76) + shift_spans(ts[1:4], 87) + ts[7:]
    swapped["tokenizer"]["data_scans"] = [shift_spans(expected["tokenizer"]["data_scans"][1], -76),
        shift_spans(expected["tokenizer"]["data_scans"][0], 87), expected["tokenizer"]["data_scans"][2]]
    swapped["search"]["first_match"] -= 76
    swapped["search"]["matches"] = [[x - 76 for x in span] for span in expected["search"]["matches"]]
    es = expected["traversal"]["element_preorder"]
    swapped["traversal"]["element_preorder"] = [es[0], shift_spans(es[2], -76), shift_spans(es[1], 87)]
    ns = expected["traversal"]["node_preorder"]
    swapped["traversal"]["node_preorder"] = [ns[0]] + shift_spans(ns[3:5], -76) + shift_spans(ns[1:3], 87)
    for row in swapped["traversal"]["element_preorder"][1:] + swapped["traversal"]["node_preorder"][1:]:
        row["path"][0] = 1 - row["path"][0]
    swapped["traversal"]["bounded_find"][1]["result"] = [0]
    swapped["extraction"] = shift_spans(expected["extraction"], -76)
    swapped["extraction"]["element_path"] = [0]
    swapped["extraction"]["text_path"] = [0, 0]
    check("swapped-siblings", data[:105] + data[181:268] + data[105:181] + data[268:], swapped)
    check("missing-target", data.replace(b"NetIncomeLoss", b"LostIncomeNet"), error="target absent")
    check("ampersand-stop", data.replace(b">18000<", b">18&00<"), error="entities are outside")
    check("mismatched-close", data.replace(b"</us-gaap:Revenue>", b"</us-gaap:Wrong>"), error="mismatched close")
    check("truncated-root", data[:268], error="unclosed element")
    check("non-ascii", data.replace(b"quarter", b"qu\xc3\xa4rter"), error="only printable ASCII")
    check("depth-bound", b"<a>" * 9 + data.rstrip(b"\n") + b"</a>" * 9, error="tree depth bound")
    check("byte-bound", data + b" " * 4096, error="byte bound")
    return passed


def run() -> None:
    receipt = load_receipt()
    stage = "compiler_build"
    try:
        require(receipt["status"] == "NOT_VERIFIED", "prepare a new attempt; do not reuse an old receipt")
        require(receipt["identity"] == identity(), "checkout changed after build")
        require(receipt["stages"]["compiler_build"] == "PASS", "fresh successful compiler build not recorded")
        manifest_file = OUT / "compiler-manifest.json"
        require(digest(manifest_file.read_bytes()) == receipt["compiler_manifest_sha256"], "build stamp changed")
        require(compiler_manifest() == strict_json(manifest_file.read_text()), "compiler/library bytes changed")
        def passed(name: str) -> None:
            receipt["stages"][name] = "PASS"
            save(receipt)
        stage = "network_isolation"
        require(isolated(), "run acceptance in a Linux network namespace: sudo unshare --net -- python3 xbrl_acceptance.py run")
        passed(stage)
        compiler = ROOT / "_" / "build" / "exec" / "idris2"
        stage = "core_typecheck"
        command(stage, [str(compiler), "--check", "--build-dir", str(OUT / "check"), str(SOURCE)])
        passed(stage)
        stage = "compiler_ir"
        artifact = OUT / "program.one-step"
        command(stage, ["sh", str(ROOT / "_" / "scripts" / "emit-one-step.sh"), str(SOURCE), "-o", str(artifact)])
        inspect_ir(artifact.read_text(), receipt["identity"]["source_sha256"], receipt["identity"]["head"])
        receipt["one_step_sha256"] = digest(artifact.read_bytes())
        passed(stage)
        stage = "chez_codegen"
        output = OUT / "chez"
        output.mkdir()
        command(stage, [str(compiler), "--cg", "chez", "--build-dir", str(OUT / "chez-ttc"),
                        "--output-dir", str(output), "-o", "xbrl-canary", str(SOURCE)])
        executable = output / "xbrl-canary"
        require(executable.is_file(), "Chez produced no executable")
        passed(stage)
        stage = "compiled_execution"
        observed = strict_json(command(stage, [str(executable), str(FIXTURE)], timeout=30))
        oracle = strict_json(ORACLE.read_text())
        expected = projection(oracle)
        require(isinstance(observed, dict) and observed.keys() == expected.keys(), "missing/extra observation sections")
        passed(stage)
        for stage, section in SECTIONS:
            require(equivalent(observed[section], expected[section]), f"{section} differs from frozen oracle")
            passed(stage)
        stage = "derived_controls"
        receipt["controls"] = controls(FIXTURE.read_bytes(), expected, executable)
        passed(stage)
        require(identity() == receipt["identity"], "checkout moved during acceptance")
        receipt["status"] = overall(receipt)
        require(receipt["status"] == "PASS", "required acceptance stage did not pass")
    except Exception as exc:
        receipt["stages"][stage] = "FAIL"
        receipt["status"] = "FAIL"
        receipt["error"] = str(exc)
        raise
    finally:
        save(receipt)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("prepare", "stamp-build", "fail-build", "run"))
    action = parser.parse_args().action
    try:
        if action == "prepare":
            prepare()
        elif action == "stamp-build":
            stamp_build()
        elif action == "fail-build":
            receipt = load_receipt()
            receipt["status"] = "FAIL"
            receipt["stages"]["compiler_build"] = "FAIL"
            receipt["error"] = "fresh bootstrap/focused tests failed; compiler acceptance was not run"
            save(receipt)
            return 1
        else:
            run()
    except Exception as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        return 1
    print(f"{action}: recorded in {OUT / 'receipt.json'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
