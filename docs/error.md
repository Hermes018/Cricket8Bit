# Error Log

Format: `[date] symptom -> root cause -> fix applied -> how it was verified fixed`

---

- 2026-09-18: symptom: GitHub PAT exposed via CLI/embedded in remote URL -> root cause: insecure credential handling (putting plaintext token in `git remote add` and curl commands) -> fix: token revoked, rotated by user, remote fixed locally (`git remote set-url origin`), security standard tightened in master prompt to explicitly rule out this pattern.

See `docs/master_context.md`
