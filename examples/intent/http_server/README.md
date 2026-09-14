# HTTP server intent example

This example is a structural reference for Idriç: the main path should describe
what the server does before exposing sockets, buffers, parser state, syscalls, or
foreign-library machinery.

The notation here is intent-oriented. It is not a claim that every phrase is
already accepted by the current parser.

## Top level: serve one request

```idric
connection ← accept connection from listener
request ← read request from connection
response ← answer request
write response to connection
close connection
```

The nouns and prepositions expose semantic roles directly. `connection` is the
source of the request and the destination of the response; that information is
not hidden in argument position.

## One level down: reading an HTTP request

```idric
read request from connection ≝
    bytes ← read bytes from connection
    text ← decode utf8 from bytes
    request ← parse http_request from text
    return request
```

If byte framing, streaming, or incremental parsing later matters, those details
can replace this implementation without changing the higher-level phrase used
by the server.

## Boundary code stays below the domain action

A concrete implementation may eventually descend through typed network wrappers
to a syscall, TLS library, or another foreign boundary. Keep that machinery
behind names that still say what the program is doing. Raw descriptors, buffer
layouts, status integers, and FFI declarations should not take over the
server's top-level vocabulary.

## Missing meaning is a compiler problem, not a filesystem problem

If the program can see no definition that gives meaning to:

```idric
read request from connection
```

the useful failure is semantic:

```text
undefined operation:
read request from connection

understood roles:
action = read
thing = request
source = connection

no visible definition matches that phrase
```

Do not require the programmer to decide first whether such an implementation
must live under `read/`, `request/`, or `connection/`. Semantic resolution and
filesystem organization are separate concerns.

## What this example establishes

- purpose-ordered top-level actions;
- explicit semantic roles instead of positional argument piles;
- intent above transport and parsing mechanism;
- typed boundaries between bytes, text, HTTP requests, and connections;
- unresolved, ambiguous, or contradictory meaning belongs in compiler errors;
- suspicious but still meaningful naming/metadata belongs in warnings or style
  checks rather than hard grammar.
