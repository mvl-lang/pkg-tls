# Contributing to pkg-tls

Thank you for your interest in contributing to the MVL TLS package.

## Getting Started

1. Fork this repository
2. Create a feature branch: `git checkout -b feat/my-feature`
3. Make your changes
4. Run the type checker: `mvl check src/`
5. Run tests: `mvl test src/`
6. Commit with a conventional message: `git commit -m "feat: add ..."`
7. Push and open a pull request

## Development Setup

You need the [MVL compiler](https://github.com/LAB271/mvl_language) installed:

```bash
git clone https://github.com/LAB271/mvl_language.git
cd mvl_language
cargo build
export PATH="$PWD/target/debug:$PATH"
```

## Code Style

- Follow the MVL syntax conventions (see the [MVL cheat sheet](https://github.com/LAB271/mvl_language/blob/main/CLAUDE.md))
- All public functions must have doc comments (`///`)
- All functions must declare their effects
- IFC labels must be preserved: received bytes are always `Tainted[String]`
- Rust bridge (`bridge.rs`) and LLVM bridge (`llvm.rs`) must expose the same ABI

## Testing

```bash
mvl check src/          # type-check all source files
mvl test src/           # run inline tests
```

## License

By contributing, you agree that your contributions will be licensed under the Apache License 2.0.
