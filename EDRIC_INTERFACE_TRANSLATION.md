# Edriç interface translation note

Status: design note. This is not a claim that the current parser accepts the example phrases below, nor that a universal Edriç compiler pipeline already implements them.

A small terminal-output helper is a useful forcing example for the kind of interface Edriç should make easy: state the practical job first, preserve the important boundary, and translate into whatever mechanism already solves that job on the target.

The important requirement is simple:

```text
color interactive terminal output
keep receipt files plain
```

That requirement does not intrinsically mean ANSI escape sequences, POSIX shell, C, one compiler backend, or even compilation at all.

## Concrete implementation

A shell implementation can already express the job compactly:

```sh
# Terminal colors only; receipt files stay plain.
if [ -t 1 ] && [ "${TERM:-dumb}" != dumb ]; then
    stdout_reset=$(printf '\033[0m')
    stdout_bold=$(printf '\033[1m')
    stdout_green=$(printf '\033[32m')
    stdout_yellow=$(printf '\033[33m')
    stdout_blue=$(printf '\033[34m')
    stdout_magenta=$(printf '\033[35m')
    stdout_cyan=$(printf '\033[36m')
else
    stdout_reset=''
    stdout_bold=''
    stdout_green=''
    stdout_yellow=''
    stdout_blue=''
    stdout_magenta=''
    stdout_cyan=''
fi

if [ -t 2 ] && [ "${TERM:-dumb}" != dumb ]; then
    stderr_reset=$(printf '\033[0m')
    stderr_bold=$(printf '\033[1m')
    stderr_red=$(printf '\033[31m')
else
    stderr_reset=''
    stderr_bold=''
    stderr_red=''
fi

section() {
    printf '\n%s%s=== %s ===%s\n' "$stdout_bold" "$stdout_cyan" "$*" "$stdout_reset"
}

pass() {
    printf '%s%sPASS%s  %s\n' "$stdout_bold" "$stdout_green" "$stdout_reset" "$*"
}

fail() {
    printf '%s%sFAIL%s  %s\n' "$stderr_bold" "$stderr_red" "$stderr_reset" "$*" >&2
}

info() {
    printf '%s%s%s%s\n' "$stdout_blue" "$*" "$stdout_reset" ""
}

warn() {
    printf '%s%sWARN%s  %s\n' "$stdout_bold" "$stdout_yellow" "$stdout_reset" "$*"
}
```

This code is useful precisely because the mechanism is ordinary and local. The semantic boundary is clearer than the implementation:

- decorate each output stream only when that stream is an interactive terminal with a usable terminal type;
- otherwise emit no decoration on that stream;
- keep machine-readable or saved receipts independent of presentation;
- distinguish ordinary information, warnings, failures, passes, and section boundaries for a human reader;
- send failures to the error stream without letting standard-output terminal state decide whether standard error is decorated.

Those are the facts an Edriç-facing interface should preserve.

## Translate the job, not the spelling

An Edriç description should be able to express something close to:

```idric
stdout_style ← presentation for standard output
stderr_style ← presentation for standard error

when stdout_style supports color
    show sections bold cyan
    show passes bold green
    show information blue
    show warnings bold yellow

when stderr_style supports color
    show failures bold red on standard error

keep receipts plain
```

The exact grammar is open. This is intent notation, not implemented syntax.

On a POSIX shell target, the simplest implementation may be almost exactly the shell fragment above. On another target, the same interface could instead map to:

- a terminal library;
- Windows console attributes;
- an Android text or logging surface;
- a native system API;
- an existing command-line utility;
- a script generated in another language;
- direct output bytes where that boundary is appropriate;
- no styling at all when the target cannot support it safely.

The source requirement should not be distorted merely to force every target through the same machinery.

## Translation does not require a universal compiler

For this class of problem, "lowering" can mean several different things.

Edriç may compile an operation directly. It may select a small target-specific adapter. It may emit a shell fragment. It may call an existing program through a checked interface. It may translate one useful notation into another. It may leave an already-correct implementation in its native language and provide only the typed or semantic boundary around it.

The important property is that the requested meaning survives the crossing.

A useful architecture is therefore not necessarily:

```text
Edriç -> one IR -> C -> everything
```

or even:

```text
Edriç -> one compiler -> every target
```

It can instead be a set of explicit translations:

```text
semantic action
    -> shell adapter when shell is the natural boundary
    -> DEX action when Android runtime is the natural boundary
    -> syscall or native action when the operating system is the natural boundary
    -> GPU operation when the GPU is the natural boundary
    -> existing external tool when that is already the smallest correct implementation
```

Some paths may use the Idriç compiler. Some may use another compiler. Some may not need a compiler in the ordinary sense at all.

## Interfaces should preserve evidence boundaries

The terminal example also shows why presentation and receipts should remain separate.

Color is for a human-facing terminal. A receipt is evidence intended to survive redirection, comparison, parsing, storage, or later inspection. Mixing terminal escape sequences into receipts would make a presentation choice contaminate the evidence layer.

So the interface should preserve at least these distinctions:

```text
human presentation ≠ durable receipt
standard output ≠ standard error
semantic status ≠ chosen color
requested action ≠ implementation mechanism
```

`PASS` is not semantically "green". Green is one presentation of a pass on one class of terminal. Likewise, a failure remains a failure if the output device is monochrome or if all styling is disabled.

## Practicality is the design test

This is the scale at which the interface should prove itself. A person has a small practical job. One environment already has a concise working idiom. Edriç should make the intent clearer and the boundary safer without demanding that the person rewrite the world underneath it.

If translating a six-line idea requires inventing a universal runtime, routing through C, targeting a particular compiler, or pretending every environment shares one execution model, the abstraction is probably below the wrong boundary.

The useful question is:

```text
what does the person want done here?
```

Then preserve that meaning while choosing the smallest correct mechanism available on the actual target.

## Relationship to the memory-tiering note

[`EDRIC_MEMORY_TIERING.md`](EDRIC_MEMORY_TIERING.md) makes the same architectural point at a much larger scale: one policy can lower through Android, native Linux, kernel, DEX, or GPU paths without one universal implementation language.

This terminal example supplies the small everyday version of the same rule. Edriç should support both ends of that range: from "print this status clearly without polluting the receipt" to system-wide memory policy.

Neither example implies that every useful translation must become syntax in the language. They are design tests for where semantic intent ends and replaceable implementation mechanism begins.
