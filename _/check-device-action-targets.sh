#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)
registry="$repo_root/examples/device_actions/targets.tsv"

[ -f "$registry" ] || {
    printf 'FAIL: missing device-action registry: %s\n' "$registry" >&2
    exit 1
}

expected_header='action\tprofile\towner\timplementation_state\texecution_state\tevidence\tblocker_or_next\tshell_role'
actual_header=$(sed -n '1p' "$registry")

if [ "$actual_header" != "$(printf '%b' "$expected_header")" ]; then
    printf '%s\n' 'FAIL: unexpected device-action registry header' >&2
    exit 1
fi

awk -F '\t' '
BEGIN {
    required["armv7_thumb_linux"] = 1
    required["x86_64_linux"] = 1
    required["android_phone"] = 1

    implementation["not_started"] = 1
    implementation["not_reconciled"] = 1
    implementation["historical_reference"] = 1
    implementation["oracle_present"] = 1
    implementation["implementation_present"] = 1

    execution["not_run"] = 1
    execution["not_reconciled"] = 1
    execution["ci_pending"] = 1
    execution["blocked"] = 1
    execution["failed"] = 1
    execution["host_pass"] = 1
    execution["user_mode_pass"] = 1
    execution["simulated_guest_pass"] = 1
    execution["full_system_guest_pass"] = 1
    execution["physical_device_pass"] = 1

    shell_role["none"] = 1
    shell_role["sequence_timer"] = 1
    shell_role["stream"] = 1
    shell_role["command_timer"] = 1
    shell_role["waitable_source"] = 1
}
NR == 1 { next }
{
    if (NF != 8) {
        printf "FAIL: line %d has %d fields; expected 8\n", NR, NF > "/dev/stderr"
        bad = 1
        next
    }

    action = $1
    profile = $2
    implementation_state = $4
    execution_state = $5
    evidence = $6
    role = $8

    if (action == "" || profile == "" || $3 == "" || implementation_state == "" || execution_state == "" || evidence == "" || $7 == "" || role == "") {
        printf "FAIL: line %d contains an empty required field\n", NR > "/dev/stderr"
        bad = 1
    }

    if (!(profile in required)) {
        printf "FAIL: line %d has unknown profile %s\n", NR, profile > "/dev/stderr"
        bad = 1
    }

    if (!(implementation_state in implementation)) {
        printf "FAIL: line %d has unknown implementation state %s\n", NR, implementation_state > "/dev/stderr"
        bad = 1
    }

    if (!(execution_state in execution)) {
        printf "FAIL: line %d has unknown execution state %s\n", NR, execution_state > "/dev/stderr"
        bad = 1
    }

    if (!(role in shell_role)) {
        printf "FAIL: line %d has unknown shell role %s\n", NR, role > "/dev/stderr"
        bad = 1
    }

    if (execution_state ~ /_pass$/ && evidence == "-") {
        printf "FAIL: line %d claims %s without evidence\n", NR, execution_state > "/dev/stderr"
        bad = 1
    }

    key = action SUBSEP profile
    if (seen[key]++) {
        printf "FAIL: duplicate row for %s / %s\n", action, profile > "/dev/stderr"
        bad = 1
    }

    actions[action] = 1
    present[action, profile] = 1
    rows++
}
END {
    for (action in actions) {
        action_count++
        for (profile in required) {
            if (!present[action, profile]) {
                printf "FAIL: missing %s row for action %s\n", profile, action > "/dev/stderr"
                bad = 1
            }
        }
    }

    if (action_count == 0) {
        print "FAIL: no device actions registered" > "/dev/stderr"
        bad = 1
    }

    if (bad)
        exit 1

    printf "PASS: %d device actions, %d complete action/profile rows\n", action_count, rows
}
' "$registry"
