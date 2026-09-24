"""Host harness tests. These are not a substitute for compiler acceptance."""
import copy
import importlib.util
import json
from pathlib import Path
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[3]
spec = importlib.util.spec_from_file_location("acceptance", ROOT / "xbrl_acceptance.py")
a = importlib.util.module_from_spec(spec)
spec.loader.exec_module(a)


class AcceptanceTests(unittest.TestCase):
    def setUp(self):
        self.data = a.FIXTURE.read_bytes()
        self.oracle = json.loads(a.ORACLE.read_text())

    def test_frozen_integrity(self):
        a.integrity(self.data, self.oracle)

    def test_byte_mutations_cannot_pass_integrity(self):
        for mutation in (self.data[:-1], self.data + b"\n", self.data.replace(b"\n", b"\r\n"),
                         b"\xef\xbb\xbf" + self.data, self.data.replace(b"18000", b"18001")):
            with self.subTest(mutation=mutation[-30:]), self.assertRaises(ValueError):
                a.integrity(mutation, self.oracle)

    def test_attribute_span_tamper(self):
        self.oracle["tokenizer"]["tokens"][0]["attributes"][0]["value_span"][0] += 1
        with self.assertRaisesRegex(ValueError, "slice mismatch"):
            a.integrity(self.data, self.oracle)

    def test_gap_tamper(self):
        self.oracle["tokenizer"]["tokens"][1]["span"][0] += 1
        with self.assertRaisesRegex(ValueError, "gap/overlap"):
            a.integrity(self.data, self.oracle)

    def test_metadata_not_sent_as_observations(self):
        self.assertEqual(set(a.projection(self.oracle)), {"search", "tokenizer", "traversal", "extraction"})

    def test_every_observation_section_is_required(self):
        expected = a.projection(self.oracle)
        for name in expected:
            observed = copy.deepcopy(expected)
            del observed[name]
            self.assertFalse(a.equivalent(observed, expected))

    def test_first_numeric_fact_is_not_target(self):
        expected = a.projection(self.oracle)
        observed = copy.deepcopy(expected)
        observed["extraction"]["integer_value"] = 125000
        self.assertFalse(a.equivalent(observed, expected))

    def test_wrong_bounded_path_cannot_pass(self):
        expected = a.projection(self.oracle)
        observed = copy.deepcopy(expected)
        observed["traversal"]["bounded_find"][1]["result"] = [0]
        self.assertFalse(a.equivalent(observed, expected))

    def test_document_whitespace_is_not_a_root_child(self):
        expected = a.projection(self.oracle)
        observed = copy.deepcopy(expected)
        observed["traversal"]["node_preorder"].append(
            {"kind": "text", "value": "\n", "span": [281, 282], "path": [2]})
        self.assertFalse(a.equivalent(observed, expected))

    def test_json_numbers_are_type_sensitive(self):
        self.assertFalse(a.equivalent(18000, 18000.0))
        self.assertFalse(a.equivalent(1, True))

    def test_duplicate_keys_rejected(self):
        with self.assertRaises(ValueError):
            a.strict_json('{"search":{},"search":{}}')

    def test_nonfinite_json_rejected(self):
        with self.assertRaises(ValueError):
            a.strict_json('{"integer_value":NaN}')

    def test_no_required_skip_can_be_green(self):
        receipt = {"stages": dict.fromkeys(a.STAGES, "PASS")}
        self.assertEqual(a.overall(receipt), "PASS")
        for stage in a.STAGES:
            for status in ("SKIP", "NOT_VERIFIED", "FAIL"):
                altered = copy.deepcopy(receipt)
                altered["stages"][stage] = status
                self.assertEqual(a.overall(altered), "FAIL")

    def test_controls_cover_value_offsets_and_paths(self):
        observed_cases = {}
        def fake_command(label, argv, timeout, failure_expected):
            # Capture generated inputs; do not pretend to execute a compiler.
            observed_cases[label] = Path(argv[1]).read_bytes()
            return "{}"
        import tempfile
        with tempfile.TemporaryDirectory() as folder, patch.object(a, "OUT", Path(folder)), \
             patch.object(a, "command", fake_command), patch.object(a, "equivalent", return_value=True):
            cases = a.controls(self.data, a.projection(self.oracle), Path("unused"))
        self.assertEqual(len(cases), 11)
        self.assertEqual(observed_cases["shifted-offsets"], b"\n" + self.data)
        self.assertIn(b">18001<", observed_cases["changed-income"])
        self.assertLess(observed_cases["swapped-siblings"].index(b"NetIncomeLoss"),
                        observed_cases["swapped-siblings"].index(b"Revenue"))
        self.assertEqual(self.oracle["traversal"]["bounded_find"][1]["result"], [1])

    def test_ir_accepts_lowered_nullary_enum_dispatch(self):
        body = (
            "XbrlCanary.state_class_step = [0, 1]: %case v0 of { "
            "%constalt(0) => %case v1 of { %constalt(0) => 1| %constalt(1) => 1 Just 0 }| "
            "%constalt(1) => %case v1 of { %constalt(3) => 0| %constalt(4) => 1 Just 2 }| "
            "%constalt(2) => %case v1 of { %constalt(2) => 1| %constalt(0) => 2| "
            "%constalt(1) => 2 Just 0 } Nothing }\n"
            "XbrlCanary.scan_loop = [0, 1]: %case v1 of { %constalt(0) => "
            "XbrlCanary.scan_loop(XbrlCanary.state_class_step(v0, "
            "XbrlCanary.classify_byte(v1))) Nothing }\n"
        )
        text = ("EDRIC_ONE_STEP\t1\nsource_sha256\tsource\n"
                "compiler_head\tisomorphisms/Idric\thead\ncore_typecheck\tPASS\n"
                "representation\tidris2-anf-show-0.8.0\nbody_sha256\t" +
                a.digest(("EDRIC_ONE_STEP_BODY\t1\n" + body).encode()) +
                "\ndefinitions_begin\n" + body + "definitions_end\nend\n")
        a.inspect_ir(text, "source", "head")

    def test_ir_with_matching_hash_but_no_scanner_is_rejected(self):
        body = "XbrlCanary.main = []: 18000\n"
        text = ("EDRIC_ONE_STEP\t1\nsource_sha256\tsource\n"
                "compiler_head\tisomorphisms/Idric\thead\ncore_typecheck\tPASS\n"
                "representation\tidris2-anf-show-0.8.0\nbody_sha256\t" +
                a.digest(("EDRIC_ONE_STEP_BODY\t1\n" + body).encode()) +
                "\ndefinitions_begin\n" + body + "definitions_end\nend\n")
        with self.assertRaisesRegex(ValueError, "dispatch absent"):
            a.inspect_ir(text, "source", "head")
        with self.assertRaisesRegex(ValueError, "stale one-step"):
            a.inspect_ir(text, "source", "different-head")


if __name__ == "__main__":
    unittest.main()
