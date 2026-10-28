# Contributing

Thanks for your interest in contributing! Please read the [Code of Conduct](CODE_OF_CONDUCT.md) first.

## Before you start

- For bugs and feature ideas, open an issue using one of the templates.
- For anything bigger than a small fix, please discuss it in an issue before writing code.
- Security problems: see [SECURITY.md](SECURITY.md), not a public issue.

## Local checks

CI runs the same commands, so you can find problems before pushing:

```sh
cargo fmt --all --check
cargo clippy --workspace --all-targets --all-features --locked -- -D warnings
cargo test --workspace --all-features --locked
RUSTDOCFLAGS="-D warnings" cargo doc --workspace --no-deps --all-features --locked
```

The lint configuration lives in the `[lints]` tables of `Cargo.toml`, so your editor shows the same warnings.

## Pull requests

- Keep a pull request focused on one change.
- Tick the matching boxes under "Type of change"; they are turned into labels automatically.
- Go through the review checklist in the template.
- Pull requests are squash-merged, so the PR title becomes the commit message. Write it in the imperative
  (e.g. "Add retry for failed uploads").
