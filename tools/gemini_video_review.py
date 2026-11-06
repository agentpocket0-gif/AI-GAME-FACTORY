#!/usr/bin/env python3
"""Review an authorised gameplay video with Gemini Flash-Lite.

The helper uses GEMINI_API_KEY_1. A second key is not used to multiply quota.
HTTP 429 / quota errors stop immediately.
"""
from __future__ import annotations

import argparse
import json
import os
import sys
import time
from datetime import datetime, timedelta, timezone
from pathlib import Path

from google import genai
from google.genai import types

ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / "config" / "model-routing.json"
STATE = ROOT / ".cache" / "gemini-video-quota.json"

PROMPT = """Review this gameplay recording of our original carrom-style Android game.

Return a structured report with:
1. Timeline of the player-visible flow, using timestamps.
2. UI/UX defects: clipping, unreadable text, touch target problems, layout shifts.
3. Gameplay defects: aiming, striker movement, collision, pocketing, score/turn handling.
4. Animation/audio feedback that is missing or confusing.
5. Performance clues: stutter, freezes, long loading or frame drops visible in the video.
6. A prioritised issue list with severity, timestamp, expected result and suggested fix.
7. Separate confirmed observations from guesses. Do not invent hidden backend, payment or ad behaviour that is not visible.

Do not propose copying another commercial game's protected artwork, logo, text, assets or source code.
"""

def load_config() -> dict:
    return json.loads(CONFIG.read_text(encoding="utf-8"))

def load_state() -> dict:
    STATE.parent.mkdir(parents=True, exist_ok=True)
    if not STATE.exists():
        return {"requests": []}
    try:
        return json.loads(STATE.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return {"requests": []}

def save_state(state: dict) -> None:
    STATE.parent.mkdir(parents=True, exist_ok=True)
    STATE.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")

def enforce_quota(model: str, limits: dict) -> None:
    now = datetime.now(timezone.utc)
    state = load_state()
    rows = []
    for item in state.get("requests", []):
        try:
            stamp = datetime.fromisoformat(item["time"])
            if now - stamp < timedelta(hours=24):
                rows.append(item)
        except (ValueError, KeyError, TypeError):
            continue

    last_minute = [
        item for item in rows
        if now - datetime.fromisoformat(item["time"]) < timedelta(seconds=60)
    ]
    model_rows = [item for item in rows if item.get("model") == model]

    rpm_cap = int(limits.get("rpm", 10))
    model_daily_cap = int(limits.get("primary_rpd", 500) if model == "gemini-3.5-flash-lite" else limits.get("fallback_rpd", 500))
    global_daily_cap = int(limits.get("total_rolling_24h", 1000))

    if len(last_minute) >= rpm_cap:
        raise RuntimeError(f"Local Gemini guard: {rpm_cap} requests/minute reached. Wait before trying again.")
    if len(model_rows) >= model_daily_cap:
        raise RuntimeError(f"Local Gemini guard: daily cap for {model} reached.")
    if len(rows) >= global_daily_cap:
        raise RuntimeError(f"Local Gemini guard: total rolling-24h Gemini cap reached.")

    rows.append({"time": now.isoformat(), "model": model})
    save_state({"requests": rows})

def make_client():
    key = os.getenv("GEMINI_API_KEY_1", "").strip()
    if not key:
        raise RuntimeError("Set GEMINI_API_KEY_1 in the private runtime environment.")
    try:
        return genai.Client(api_key=key)
    except Exception as exc:
        raise RuntimeError(f"Could not initialise Gemini client: {exc}") from exc

def upload_and_wait(client, video_path: Path, timeout_seconds: int = 900):
    uploaded = client.files.upload(file=str(video_path))
    started = time.monotonic()
    while True:
        state_name = getattr(getattr(uploaded, "state", None), "name", "")
        if state_name == "ACTIVE":
            return uploaded
        if state_name == "FAILED":
            raise RuntimeError("Gemini Files API reported that video processing failed.")
        if time.monotonic() - started > timeout_seconds:
            raise TimeoutError("Timed out waiting for Gemini video processing.")
        time.sleep(4)
        uploaded = client.files.get(name=uploaded.name)

def main() -> int:
    parser = argparse.ArgumentParser(description="Review a gameplay video with Gemini Flash-Lite.")
    parser.add_argument("video", type=Path)
    parser.add_argument("--prompt", type=str, default=PROMPT)
    parser.add_argument("--output", type=Path, default=Path("reports/video-review/latest-review.md"))
    args = parser.parse_args()

    if not args.video.is_file():
        print("Video file not found.", file=sys.stderr)
        return 2

    config = load_config()
    video_cfg = config["providers"]["google"]["video_review"]
    models = [video_cfg["primary"], video_cfg["fallback"]]
    limits = video_cfg["app_limits"]
    try:
        client = make_client()
    except RuntimeError as exc:
        print(str(exc), file=sys.stderr)
        return 3
    uploaded = upload_and_wait(client, args.video)

    report = None
    for model in models:
        enforce_quota(model, limits)
        try:
            response = client.models.generate_content(
                model=model,
                contents=[uploaded, args.prompt],
                config=types.GenerateContentConfig(
                    temperature=1.0,
                    top_p=0.95,
                    max_output_tokens=8192,
                    thinking_config=types.ThinkingConfig(
                        thinking_level=types.ThinkingLevel.HIGH
                    ),
                ),
            )
            report = response.text or ""
            if not report.strip():
                raise RuntimeError("Gemini returned an empty video review.")
            break
        except Exception as exc:
            error = str(exc).lower()
            if "429" in error or "resource_exhausted" in error or "quota" in error:
                raise RuntimeError("Gemini quota/rate limit reached. Stopped without rotating API keys.") from exc
            if model == models[-1]:
                raise
            print(f"{model} failed for a non-quota reason; trying documented fallback model.", file=sys.stderr)

    if report is None:
        raise RuntimeError("No Gemini model returned a report.")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(report.rstrip() + "\n", encoding="utf-8")
    print(f"Review saved to {args.output}")
    return 0

if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"Video review failed: {exc}", file=sys.stderr)
        raise SystemExit(1)
