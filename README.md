# pkg-tls

TLS 1.3 client package for [MVL](https://github.com/LAB271/mvl_language).

Provides TLS client connections via [rustls](https://github.com/rustls/rustls) (pure Rust, no OpenSSL). Certificate validation uses the Mozilla root store via `webpki-roots`. Includes an HTTPS convenience layer built on top.

## Install

```bash
mvl add github.com/mvl-lang/pkg-tls v0.1.0
mvl install
```

## Usage

### Low-level TLS

```mvl
use pkg.tls.{TlsStream, TlsError, tls_client_connect, tls_client_read, tls_client_write, tls_client_close, tls_error_msg}

partial fn fetch(host: String, port: Int, request: String) -> Result[String, TlsError] ! Net {
    let stream: TlsStream = tls_client_connect(host, port)?;
    tls_client_write(stream, request)?;
    let raw = tls_client_read_response(stream)?;
    tls_client_close(stream);
    Ok(relabel trust(raw, "MY-TRUST-TAG"))
}
```

### HTTPS convenience layer

```mvl
use pkg.tls.https.{https_post, https_request, HttpsResponse, HttpsError}

partial fn post_json(url: String, body: String) -> Result[HttpsResponse, HttpsError] ! Net {
    https_post(url, {"Content-Type": "application/json"}, body)
}
```

## API

### `pkg.tls`

| Function | Signature | Effect |
|----------|-----------|--------|
| `tls_client_connect` | `(host: String, port: Int) -> Result[TlsStream, TlsError]` | `! Net` |
| `tls_client_read` | `(stream: TlsStream) -> Result[Tainted[String], TlsError]` | `! Net` |
| `tls_client_read_response` | `(stream: TlsStream) -> Result[Tainted[String], TlsError]` | `! Net` |
| `tls_client_write` | `(stream: TlsStream, data: String) -> Result[Unit, TlsError]` | `! Net` |
| `tls_client_close` | `(stream: TlsStream) -> Unit` | pure |
| `tls_error_msg` | `(e: TlsError) -> String` | pure |

### Error Types

```mvl
pub type TlsError = enum {
    HandshakeFailed(String),
    CertificateInvalid(String),
    ConnectionClosed,
    IoError(String),
    Other(String),
}
```

## Security

### IFC Model

| Data | Label | Why |
|------|-------|-----|
| Received bytes | `Tainted[String]` | Network data is untrusted until validated |
| Hostname | bare `String` | Caller-provided -- trusted endpoint |

All received data is tagged `TLS-READ` or `TLS-READ-RESPONSE`. Callers must explicitly `relabel trust(data, "MY-TAG")` to use the content.

### Native Dependencies

```toml
[native]
rustls = "0.23"
rustls-pemfile = "2"
webpki-roots = "0.26"
```

No OpenSSL, no system TLS dependency. Fully self-contained.

## License

Apache License 2.0 -- see [LICENSE](LICENSE).
