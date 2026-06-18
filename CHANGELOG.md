# Changelog

All notable changes to pkg-tls will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.2.0] - 2026-06-18

### Added
- ADR-0001: TLS/FFI boundary design (primitive types only)
- ADR-0002: Security design — CRLF injection prevention and port validation
- ADR-0003: Totality policy — all terminating functions carry explicit `total fn`
- `make coverage` target — run tests with behavioral branch coverage report
- `make prove` target — per-call-site refinement proof breakdown (verbose)
- `make version` target — show current package version from mvl.toml

### Changed
- Graduated `make_tls_error`, `tls_client_close`, `tls_error_msg` to `total fn` (tls.mvl)
- Graduated `contains_crlf`, `validate_no_crlf`, `validate_https_headers`, `validate_port` to `total fn` (https.mvl)
- Graduated `map_connect_error`, `map_write_error`, `map_read_error`, `close_and_fail` to `total fn` (https.mvl)
- Graduated `empty_https_headers`, `build_https_request`, `parse_https_url`, `validate_parsed_url` to `total fn` (https.mvl)
- Graduated `require_https_resp`, `parse_https_status_code`, `parse_https_headers`, `parse_https_response` to `total fn` (https.mvl)
- Added `where port > 0 && port < 65536` refinement to `tls_client_connect` parameter — creates a proof obligation at all call sites (runtime-checked in `https_request`, L1:trivial for literal-port callers)
- Fixed `MVL :=` to use PATH-based fallback (`command -v mvl`) instead of debug path

## [0.1.0] - 2026-05-31

### Added
- Initial release -- TLS 1.3 client for MVL via rustls
- `TlsStream` -- opaque handle to an active TLS connection
- `tls_client_connect` -- TCP connect + TLS handshake + certificate validation, `! Net`
- `tls_client_read` -- read all bytes (capped at 1 MiB), returns `Tainted[String]`
- `tls_client_read_response` -- read one HTTP response, returns `Tainted[String]`
- `tls_client_write` -- write data to TLS stream, `! Net`
- `tls_client_close` -- send close_notify, release TCP socket
- `TlsError` enum: `HandshakeFailed`, `CertificateInvalid`, `ConnectionClosed`, `IoError`, `Other`
- HTTPS convenience layer (`pkg.tls.https`): `https_post`, `https_request`, `HttpsResponse`
- IFC: all received bytes tagged `Tainted[String]`; callers must explicitly relabel
- Native: rustls 0.23, rustls-pemfile 2, webpki-roots 0.26 (no OpenSSL)
- Rust backend: `bridge.rs`; LLVM backend: `llvm.rs` (extern "C" ABI)
