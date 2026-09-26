# D networking source corpus

Reference D source code collected for networking/API/language-design comparison.

This directory is intentionally inside the Idriç repository even when the source is not Idriç. The point is to keep the implementations being compared in one place.

## Layers represented

- `phobos/std/socket.d` — D standard-library socket primitives.
- `phobos/std/net/curl.d` — D standard-library HTTP/network API backed by libcurl.
- `eventcore/source/eventcore/drivers/posix/sockets.d` — explicit POSIX asynchronous socket driver.
- `eventcore/examples/http-server.d` — HTTP-shaped server directly on eventcore.
- `vibe-core/source/vibe/core/net.d` — fiber-oriented TCP/UDP networking.
- `vibe-stream/tls/vibe/stream/tls.d` — TLS as a stream layer.
- `vibe-http/source/vibe/http/client.d` — HTTP client.
- `vibe-http/source/vibe/http/server.d` — HTTP server.
- `dlang-requests/source/requests/http.d` — independent native-D HTTP client.
- `dlang-requests/source/requests/streams.d` — socket/TLS stream machinery used by dlang-requests.
- `serverino/source/serverino/main.d` — compact independent HTTP server implementation.
- `serverino/source/serverino/websocket.d` — WebSocket implementation.
- `arsd/sslsocket.d` — small alternative TLS/socket design.
- `arsd/web.d` — independent web/HTTP implementation lineage.
- `hunt-net/source/hunt/net/NetServerImpl.d` — larger event-driven server design.
- `hunt-net/source/hunt/net/NetClientImpl.d` — corresponding client design.

## Provenance

These files are snapshots of public upstream open-source projects, copied for study and translation. Original copyright and license terms remain applicable. Upstream license files are copied alongside projects where the implementation file does not itself carry the complete notice.

Upstreams:

- https://github.com/dlang/phobos
- https://github.com/vibe-d/eventcore
- https://github.com/vibe-d/vibe-core
- https://github.com/vibe-d/vibe-stream
- https://github.com/vibe-d/vibe-http
- https://github.com/ikod/dlang-requests
- https://github.com/trikko/serverino
- https://github.com/dlang-libs/arsd-clone
- https://github.com/huntlabs/hunt-net

Collected 2026-09-26.
