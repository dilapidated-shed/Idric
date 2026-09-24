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

## State vocabulary

Implementation state is intentionally separate from execution state.

Accepted implementation states are:

- `not_started`
- `not_reconciled`
- `historical_reference`
- `oracle_present`
- `implementation_present`

Accepted execution states are:

- `not_run`
- `not_reconciled`
- `ci_pending`
- `blocked`
- `failed`
- `host_pass`
- `user_mode_pass`
- `simulated_guest_pass`
- `full_system_guest_pass`
- `physical_device_pass`

A `*_pass` state must carry an evidence reference. A pass at one level does not
imply a pass at a stronger level. In particular, a handwritten target oracle can
have `full_system_guest_pass` while compiler-generated Idriç lowering remains
unfinished; the implementation state and next-blocker fields must continue to
say so.

Accepted Ish/Grease roles are `none`, `sequence_timer`, `stream`,
`command_timer`, and `waitable_source`.

Run the registry check from any directory with:

```sh
/path/to/Idric/_/check-device-action-targets.sh
```

The check verifies the schema and state vocabulary, rejects duplicate
action/profile rows, requires evidence for pass states, and requires all three
target profiles for every registered action.
