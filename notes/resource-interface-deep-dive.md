# Resource interfaces and deep-dive levels

This is a design note, not a claim that every example phrase is accepted by the
current parser.

It extends the existing Idriç rule that purpose belongs above mechanism. The
same rule should hold for operating-system resources and devices: a program
should not have to expose whether Linux eventually implements an operation with
`read`, `write`, `ioctl`, `mmap`, a pseudo-file, or another kernel interface
until the reader deliberately descends to that implementation layer.

## Keep the program's purpose at the top

Programs may begin with titles or actions such as:

```idric
beep a sound
turn screen red
turn one pixel red
```

Those are different purposes. Their deeper implementations should be inspectable
without replacing the top-level purpose with syscall vocabulary.

For example, one level down might say:

```idric
beep a sound ≝
    audio ← open default audio output
    write tone to audio
    close audio
```

while a display action might say:

```idric
turn screen red ≝
    screen ← open display
    write red to screen
    close screen
```

and a single-pixel action might descend through a position explicitly:

```idric
turn one pixel red at location ≝
    screen ← open display
    seek screen.pixels to location
    write red to screen.pixels
    close screen
```

The examples are intentionally parallel. A reader studying audio and display
work should be able to descend through roughly comparable conceptual levels
instead of encountering unrelated API shapes merely because Linux exposes the
hardware through different historical mechanisms.

## A descriptor can be a common handle without becoming the conceptual model

On Linux, `ioctl` is not an alternative to going through the kernel. `read`,
`write`, `ioctl`, `mmap`, and related calls are all kernel interfaces, and
`ioctl` usually operates on a file descriptor.

A descriptor is therefore a plausible common lower-level handle for many
resources. That does not require the language-facing operation to be named after
the descriptor or after `ioctl`.

A deeper implementation can eventually expose something like:

```text
descriptor ← open device
configure descriptor with Linux request
write bytes to descriptor
map descriptor
close descriptor
```

and then descend again into the exact syscall ABI, request numbers, structures,
driver boundary, and hardware behavior.

Do not merely expand `ioctl` to “input/output control” as a public semantic
name. That explains the acronym without explaining the operation.

## Make device resources resemble file resources where the semantics agree

A useful direction is to treat a device as a structured resource with named
subresources or properties:

```text
audio
    samples
    sample rate
    channels
    format
    state

screen
    pixels
    width
    height
    format

camera
    frames
    width
    height
    format
    state
```

Then a small shared action vocabulary can remain familiar:

```text
open
read
write
seek
map
wait
close
```

For example:

```idric
rate ← read audio.sample rate
write 48000 to audio.sample rate
write samples to audio.samples

width ← read screen.width
seek screen.pixels to location
write red to screen.pixels
```

The implementation of `write 48000 to audio.sample rate` may eventually lower
to an `ioctl`, while writing audio samples may lower to `write`, and mapping
screen pixels may lower to `mmap`. That implementation distinction belongs
below the semantic operation.

This is filesystem-like, but it should not falsely claim that every resource is
just an untyped byte file. The common surface should preserve meaningful
differences such as readable, writable, seekable, mappable, or waitable
resources and the semantic type of the values they carry.

Possible examples include:

```text
audio.sample rate : writable Frequency
screen.width      : readable Pixel Count
screen.pixels     : seekable Pixel
accelerometer     : readable Acceleration
```

The exact type vocabulary remains a design question. The important rule is that
types describe the domain rather than exposing a raw request number, pointer,
or byte layout merely because the Linux implementation uses one.

## `ioctl` belongs at the Linux boundary

At the deepest Linux wrapper, `ioctl` still needs a careful typed model. Request
codes can imply whether the kernel reads an argument, writes one, does both, or
uses no transferred structure. That is a useful place for the type system to
prevent mismatched request codes, structures, directions, and sizes.

That safety work should not turn `ioctl` into the identity of a higher-level
audio, display, camera, terminal, or network operation.

The descent should remain conceptually similar to:

```text
beep a sound
    ↓
write tone to audio
    ↓
write sample rate to audio.sample rate
write samples to audio.samples
    ↓
Linux ioctl / write
    ↓
syscall ABI
    ↓
kernel driver
    ↓
hardware
```

and, in parallel:

```text
turn one pixel red
    ↓
seek screen.pixels to location
write red to screen.pixels
    ↓
Linux mmap / write / ioctl as required
    ↓
syscall ABI
    ↓
kernel driver
    ↓
hardware
```

The point of the layers is not to hide lower levels permanently. It is to let a
person stop at the level that answers the current question and descend further
only when the deeper mechanism matters.

## Design questions to keep open

- How visible should file descriptors be in ordinary low-level Idriç source?
- Which operations genuinely share `read`, `write`, `seek`, `map`, and `wait`
  semantics, and which need distinct domain actions?
- Should named device properties such as `audio.sample rate` behave as first-
  class resources, lenses/views onto a resource, or something else?
- How should read-only, write-only, seekable, mappable, and waitable capabilities
  appear in types without turning simple source into type-system ceremony?
- Where should Linux-specific `ioctl` request descriptions live so another
  backend can implement the same semantic operation without inheriting Linux
  vocabulary?
- How should deep-dive filesystem layout make the relation between the semantic
  action and its Linux implementation easy to follow?

The implementation mechanism is allowed to differ. The conceptual level shown
to the programmer should differ only when the meaning differs.