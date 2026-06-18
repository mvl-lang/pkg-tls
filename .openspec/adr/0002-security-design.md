# ADR-0002: Security Design — CRLF Injection Prevention and Port Validation

**Status:** Accepted
**Date:** 2026-06-18
**Context:** pkg-tls.https constructs raw HTTP/1.1 requests from caller-supplied strings (method, URL, headers, body). Without validation, an attacker who controls any of these strings could inject CRLF sequences to split the HTTP request and smuggle additional headers or a second request — a classic HTTP header injection attack.

## Decision

### CRLF injection prevention

All caller-supplied strings that end up in HTTP request headers are validated before the connection is opened:

1. **Method** — `validate_no_crlf(method, "method")` in `https_request`
2. **URL host and path** — `validate_parsed_url` calls `validate_no_crlf` on both `parsed.host` and `parsed.path`
3. **Header names and values** — `validate_https_headers` iterates every key/value pair in the caller-supplied `Map[String, String]`

The check (`contains_crlf`) rejects any string that contains `\r` (CR, U+000D) or `\n` (LF, U+000A), either alone or combined. This covers CRLF (`\r\n`), bare CR, and bare LF — all of which can terminate an HTTP header line depending on the parser.

Validation errors return `Err(HttpsError::InvalidUrl(...))` before any network call is made, so no malformed request can ever be sent.

### Port range validation

`validate_port` enforces the valid TCP port range (1–65535). Port 0 is rejected — it is a reserved wildcard in most TCP stacks and is never a valid server port. Port numbers above 65535 exceed the 16-bit TCP field.

The proof obligation is placed on `tls_client_connect`, the function that actually uses the port:

```mvl
pub partial fn tls_client_connect(host: String, port: Int where port > 0 && port < 65536) -> ...
```

This means every caller of `tls_client_connect` must discharge `port > 0 && port < 65536`. The only caller is `https_request`, which passes a port from `validate_port` (enforced by an `if` guard). The prover emits a runtime check here (not a static L1 proof) because the port arrives via a function return, not a literal. The obligation appears in `make prove` output and is not failed — it is enforced at runtime as a guard.

## Why validate before connect?

Failing before the network call avoids:
- Sending a partially-constructed malformed request (no partial writes)
- Needing to close and clean up a TLS stream on validation failure
- Any ambiguity about whether a rejected request reached the server

The `https_request` validation pipeline is:

```
validate_no_crlf(method) -> validate_https_headers(headers) ->
parse_https_url(url) -> validate_parsed_url(parsed) ->
[only then] tls_client_connect
```

## IFC consequence

Response headers are `plain String`, not `Tainted[String]`. This is intentional: the response parser must inspect header names and values to structure `HttpsResponse`. Only the body carries the `Tainted` label because:
- Header inspection is needed for routing decisions (Content-Type, Content-Length, etc.)
- The body content is fully attacker-controlled and must not be trusted without explicit relabeling

Callers are warned in the module doc comment not to use header values for security decisions without independent validation.

## Consequences

- HTTP header injection is structurally impossible for `https_request` callers
- Port 0 and ports > 65535 are rejected before any DNS lookup
- The refinement on `validate_port` makes port safety machine-checkable at call sites
- Response body is always `Tainted[String]` — callers must explicitly `relabel trust(...)` to use it as plain `String`

## Connected to

- ADR-0003: Totality policy — all validation functions are `total fn`
- `src/https.mvl` — `contains_crlf`, `validate_no_crlf`, `validate_https_headers`, `validate_port`
- `src/https_test.mvl` — CRLF injection tests, port range tests
