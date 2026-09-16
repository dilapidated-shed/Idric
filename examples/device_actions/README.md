# Device-action targets

This directory is the canonical target-neutral inventory for the small device
programs tracked in issue #85.

The phone may motivate an example, but it does not define the example's only
implementation. Each action keeps independent rows for:

- `armv7_thumb_linux` — native ARMv7/Thumb-2 on ordinary Linux;
- `x86_64_linux` — native x86-64 on ordinary Linux;
- `android_phone` — the separately identified Android implementation.

A Linux row may use a declared simulated device in a full-system guest. The
receipt must say that it is simulated. User-mode execution, a host build, an
image buffer, and actual presented display or physical-device behavior remain
different evidence levels.

`targets.tsv` is intentionally long-form: one action/profile pair per row. That
makes missing target entries mechanically detectable rather than allowing one
successful platform to hide another missing platform.

The `shell_role` column records where Ish/Grease may usefully orchestrate the
action—such as waiting for an input edge, consuming a sensor stream, or timing
a sequence. It does not require the shell to duplicate each native backend.

Implementation state and execution state must remain conservative. `not_started`,
`not_reconciled`, `oracle_present`, and `historical_reference` are not synonyms
for working Idriç backend support. Likewise, `ci_pending`, `host_only`, and
`not_run` are not physical or full-system acceptance.

Run the registry check from any directory with:

```sh
/path/to/Idric/_/check-device-action-targets.sh
```

The check verifies the schema, rejects duplicate action/profile rows, and
requires all three target profiles for every registered action.
