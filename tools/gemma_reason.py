#!/usr/bin/env python3
"""High-thinking Gemma 4 reasoning with independent Gemini project quota pools."""
from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

from google import genai
from google.genai import types

from google_quota import reserve_request

ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / "config" / "model-routing.json"


def main() -> int:
    parser = argparse.ArgumentParser(description="Use Gemma 4 with HIGH thinking for text reasoning.")
    parser.add_argument("prompt", help="The reasoning task to send")
    parser.add_argument(
        "--model",
        choices=["gemma-4-26b-a4b-it", "gemma-4-31b-it"],
        default="gemma-4-26b-a4b-it",
    )
    parser.add_argument("--output", type=Path, default=Path("reports/gemma/latest.md"))
    args = parser.parse_args()

    limits = load_config()["providers"]["google"]["gemma4"]["per_project_app_limits"]
    pool_id, api_key = reserve_request(
        "gemma4",
        args.model,
        rpm_cap=int(limits["rpm"]),
        model_daily_cap=None,
        group_daily_cap=int(limits["total_rpd"]),
    )
    print(f"Using configured Gemini project pool {pool_id}.", file=sys.stderr)

    client = genai.Client(api_key=api_key)
    try:
        response = client.models.generate_content(
            model=args.model,
            contents=args.prompt,
            config=types.GenerateContentConfig(
                temperature=1.0,
                top_p=0.95,
                max_output_tokens=8192,
                thinking_config=types.ThinkingConfig(
                    thinking_level=types.ThinkingLevel.HIGH
                ),
            ),
        )
    except Exception as exc:
        message = str(exc).lower()
        if "429" in message or "resource_exhausted" in message or "quota" in message:
            raise RuntimeError(
                "Gemma quota/rate limit reached for the selected project. "
                "This run was stopped; no alternate key was tried."
            ) from exc
        raise

    result = response.text or ""
    if not result.strip():
        raise RuntimeError("Gemma returned an empty response.")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(result.rstrip() + "\n", encoding="utf-8")
    print(f"Saved reasoning result to {args.output}")
    return 0


def load_config() -> dict:
    return json.loads(CONFIG.read_text(encoding="utf-8"))


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"Gemma reasoning failed: {exc}", file=sys.stderr)
        raise SystemExit(1)
