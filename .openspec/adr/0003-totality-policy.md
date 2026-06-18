# ADR-0003: Totality Policy — All Terminating Functions Must Be Explicit `total fn`

**Status:** Accepted
**Date:** 2026-06-18
**Context:** MVL infers totality (`total*`) for functions with no unbounded loops and no `partial fn` callees. The question is whether pkg-tls should rely on inference or annotate explicitly.

## Decision

Same policy as pkg-http ADR-0002 and pkg-sqlite ADR-0003: **all terminating functions carry explicit `total fn`. No implicit totality (`total*`) permitted.**

## Application to pkg-tls

### tls.mvl

| Function | Before | After |
|---|---|---|
| `make_tls_error` | `fn` (implicit `total*`) | `total fn` |
| `tls_client_close` | `pub fn` (implicit `total*`) | `pub total fn` |
| `tls_error_msg` | `pub fn` (implicit `total*`) | `pub total fn` |

The three public network I/O functions (`tls_client_connect`, `tls_client_read`, `tls_client_read_response`, `tls_client_write`) remain `pub partial fn ! Net` — they perform network I/O and cannot be total.

### https.mvl

All pure helper functions graduated to `total fn`:

| Function | Notes |
|---|---|
| `contains_crlf` | Pure string predicate |
| `validate_no_crlf` | Branches on `contains_crlf` |
| `validate_https_headers` | `for` loop; `decreases headers.len()` |
| `validate_port` | Pure range check; carries refinement on return type |
| `parse_https_url` | Nested match, no loop |
| `validate_parsed_url` | Calls two `total fn` validators |
| `map_connect_error` | Pure error mapping |
| `map_write_error` | Pure error mapping |
| `map_read_error` | Pure error mapping |
| `close_and_fail` | Calls `tls_client_close` (total) + `Err(...)` |
| `empty_https_headers` | Constructs empty map |
| `build_https_request` | `for` loop; `decreases headers.len()` |
| `require_https_resp` | Pure option unwrap |
| `parse_https_status_code` | Pure parse |
| `parse_https_headers` | `for` loop; `decreases lines.len()` |
| `parse_https_response` | Two `for` loops with `decreases` |
| `https_error_msg` | Pure match |

The four public functions (`https_request`, `https_get`, `https_post`, `https_put`, `https_delete`) remain `pub partial fn ! Net` — they call `tls_client_connect`, which is partial.

### Termination of loops

Every `for` loop in a `total fn` carries a `decreases` clause:

```mvl
for k in headers.keys() decreases headers.len() { ... }
for line in lines decreases lines.len() { ... }
for line in lines.slice(1, n) decreases n - 1 { ... }
for bl in body_lines decreases body_lines.len() { ... }
```

The termination checker verifies that each `decreases` expression is non-negative and strictly decreasing across iterations.

## Port refinement proof

`tls_client_connect` carries a `where` constraint on its `port` parameter:

```mvl
pub partial fn tls_client_connect(host: String, port: Int where port > 0 && port < 65536) -> ...
```

This creates one proof obligation at the call site in `https_request`. The port arrives from `validate_port` (which already enforces the range via an `if` guard), so the prover emits a runtime check rather than an L1-static proof. The obligation is:

```
make prove:
  01:[299]  https_request → tls_client_connect(port) — `self > 0 && self < 65536`  (runtime)
  Summary: 0 proven (L1:0), 1 runtime, 0 failed
```

This is the correct result: the constraint is enforced (not failed), and it surfaces in the assurance report so that future callers of `tls_client_connect` with literal port values will get L1:trivial proofs.

## Assurance target

`make assurance` should report:
- `total fn: 18 (18 explicit, 0 implicit)` across `tls.mvl` + `https.mvl`
- `partial fn ! Net: 5` (the four HTTP convenience functions + `https_request`)
- `partial fn ! Net: 4` (the four TLS I/O functions in `tls.mvl`)

## Consequences

- `make assurance` will flag any new function without an explicit totality keyword as `total*`
- Reviewers should reject PRs that introduce implicit totality
- The `decreases` clause is the mechanism; the `total fn` keyword is the contract
- All pure logic (parsing, validation, error mapping) is machine-checked for termination

## Connected to

- MVL Req 3 (Totality) and Req 8 (Termination): verified by `mvl assurance`
- ADR-0002: Security design — all validation functions are `total fn`
- pkg-sqlite ADR-0003: same policy
- pkg-http ADR-0002: where the policy originated
