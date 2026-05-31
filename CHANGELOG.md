# Changelog

All notable changes to pkg-tls will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

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
