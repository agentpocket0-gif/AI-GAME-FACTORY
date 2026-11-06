#!/usr/bin/env python3
"""High-thinking text reasoning helper using hosted Gemma 4 models."""
from __future__ import annotations

import argparse
import json
import os
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

from google import genai
from google.genai import types

ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / "config" / "model-routing.json"
STATE = ROOT / ".cache" / "gemma-quota.json"


def load_config() -> dict:
    return json.loads(CONFIG.read_text(encoding="utf-8"))


def reserve_request(model: str, rpm_cap: int, daily_cap: int) -> None:
    now = datetime.now(timezone.utc)
    STATE.parent.mkdir(parents=True, exist_ok=True)
    if STATE.exists():
        try:
            data = json.loads(STATE.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            data = {"requests": []}
    else:
        data = {"requests": []}

    recent = []
    for row in data.get("requests", []):
        try:
            stamp = datetime.fromisoformat(row["time"])
            if now - stamp < timedelta(hours=24):
                recent.append(row)
        except (ValueError, KeyError, TypeError):
            continue

    last_minute = [
        row for row in recent
        if now - datetime.fromisoformat(row["time"]) < timedelta(seconds=60)
    ]
    per_model = [row for row in recent if row.get("model") == model]

    if len(last_minute) >= rpm_cap:
        raise RuntimeError(f"Local guard reached {rpm_cap} requests/minute. Wait before retrying.")
    if len(per_model) >= daily_cap:
        raise RuntimeError(f"Local guard reached {daily_cap} requests/24h for {model}.")

    recent.append({"time": now.isoformat(), "model": model})
    STATE.write_text(json.dumps({"requests": recent}, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Use Gemma 4 with HIGH thinking for text reasoning.")
    parser.add_argument("prompt", help="The reasoning task to send")
    parser.add_argument("--model", choices=["gemma-4-26b-a4b-it", "gemma-4-31b-it"], default="gemma-4-26b-a4b-it")
    parser.add_argument("--output", type=Path, default=Path("reports/gemma/latest.md"))
    args = parser.parse_args()

    key = os.getenv("GEMINI_API_KEY_1", "").strip()
    if not key:
        print("Set GEMINI_API_KEY_1 in the runtime environment or GitHub Actions Secrets.", file=sys.stderr)
        return 2

    cfg = load_config()["providers"]["google"]["gemma4"]
    limits = cfg["requested_app_limits_per_model"]
    reserve_request(args.model, int(limits["rpm"]), int(limits["rolling_24h"]))

    client = genai.Client(api_key=key)
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

    result = response.text or ""
    if not result.strip():
        raise RuntimeError("Gemma returned an empty response.")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(result.rstrip() + "\n", encoding="utf-8")
    print(f"Saved reasoning result to {args.output}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        message = str(exc).lower()
        if "429" in message or "resource_exhausted" in message or "quota" in message:
            print("Gemma quota reached. Stopped without rotating API keys.", file=sys.stderr)
        else:
            print(f"Gemma reasoning failed: {exc}", file=sys.stderr)
        raise SystemExit(1)
