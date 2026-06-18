# ADR-0001: TLS/FFI Boundary Design — Primitive Types Only

**Status:** Accepted
**Date:** 2026-06-18
**Context:** pkg-tls wraps rustls via an `extern "rust"` block. The design question is: what types should cross the FFI boundary?

## Decision

**Only primitive types cross the FFI boundary.** The `extern "rust"` block in `src/internal/ffi.mvl` uses only `Int` and `String`. The MVL-level types (`TlsStream`, `TlsError`) are composed entirely in `tls.mvl` from these primitives.

Specifically:
- TLS connection handles are `Int` (positive = valid, -1 = failure from tls_connect)
- Error codes are `Int` with a documented enum mapping: 0=no error, 1=HandshakeFailed, 2=CertificateInvalid, 3=ConnectionClosed, 4=IoError, 5=Other
- Data is `String` — both outbound request bytes and inbound response bytes
- `tls_errmsg(handle)` provides the human-readable last error for a handle

## Rationale

MVL's IFC and effect system cannot enforce properties inside `extern "rust"` code. By keeping the boundary primitive, the trust surface is minimal:
- The MVL layer (`tls.mvl`) can be fully verified by `mvl check`
- Only the Rust bridge (`bridge.rs`) deals with rustls directly
- The LLVM backend (`llvm.rs`) exposes the same primitive ABI
- No MVL struct or enum leaks into unsafe Rust; no Rust type leaks into MVL

The TLS layer manages its own TCP+TLS connections internally, which avoids cross-runtime handle sharing between pkg.tls and std.net (see #1017). This means `tls_connect` opens the TCP socket and performs the handshake in one call; callers never touch raw sockets.

## Handle lifetime

```
tls_connect(host, port) -> Int   -- positive handle or -1
tls_read(handle) -> String       -- "" on error; check tls_errno
tls_write(handle, data) -> Int   -- bytes written or -1 on error
tls_close(handle) -> Unit        -- always safe, even after error
tls_errmsg(handle) -> String     -- last error for this handle
tls_errmsg(-1) -> String         -- error from last failed tls_connect
```

The MVL layer wraps this into `TlsStream` (opaque) and `TlsError` (discriminated union) in `tls.mvl`. No handle integer is ever exposed in the public API.

## Consequences

- All complex type construction is verifiable by `mvl check`
- The Rust bridge is small and auditable (< 150 lines)
- LLVM backend uses the same extern ABI, enabling future non-Rust targets
- Future: if MVL gains a native `Bytes` type, `String` can be replaced at the FFI edge

## Connected to

- MVL ADR-0006: FFI extern "rust" bridge (trust boundary model)
- `src/internal/ffi.mvl` — the extern block
- `bridge.rs` / `llvm.rs` — Rust implementation
- #1017, #811
