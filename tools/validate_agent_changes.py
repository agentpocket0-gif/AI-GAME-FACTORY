#!/usr/bin/env python3
"""Allow the DSH coding agent to edit game content, but not CI or secret plumbing."""
from __future__ import annotations

import subprocess
import sys

ALLOWED_PREFIXES = ("game/", "agents/", "docs/", "research/", "reports/")
ALLOWED_FILES = {"README.md"}
FORBIDDEN_SUFFIXES = (".apk", ".aab", ".keystore", ".jks", ".p12", ".pem")


def git_lines(*args: str) -> list[str]:
    result = subprocess.run(
        ["git", *args],
        check=True,
        text=True,
        capture_output=True,
    )
    return [line.strip() for line in result.stdout.splitlines() if line.strip()]


def main() -> int:
    changed = set(git_lines("diff", "--name-only", "HEAD"))
    changed.update(git_lines("ls-files", "--others", "--exclude-standard"))
    unexpected = []
    for path in sorted(changed):
        if path not in ALLOWED_FILES and not path.startswith(ALLOWED_PREFIXES):
            unexpected.append(path)
        if path.lower().endswith(FORBIDDEN_SUFFIXES):
            unexpected.append(path)

    if unexpected:
        print("Rejected DSH changes outside the allowed game/content scope:", file=sys.stderr)
        for path in sorted(set(unexpected)):
            print(" - " + path, file=sys.stderr)
        return 1

    if len(changed) > 60:
        print(f"Rejected DSH change set with {len(changed)} files; maximum is 60.", file=sys.stderr)
        return 1

    print(f"DSH change scope passed: {len(changed)} file(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
