#!/usr/bin/env python3
"""Review an authorised gameplay video with Gemini Flash-Lite using two project pools."""
from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path

from google import genai
from google.genai import types

from google_quota import reserve_request

ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / "config" / "model-routing.json"

PROMPT = """Review this gameplay recording of our original carrom-style Android game.

Return a structured report with:
1. Timeline of the player-visible flow, using timestamps.
2. UI/UX defects: clipping, unreadable text, touch target problems, layout shifts.
3. Gameplay defects: aiming, striker movement, collision, pocketing, score/turn handling.
4. Animation/audio feedback that is missing or confusing.
5. Visible performance clues: stutter, freezes, long loading or frame drops.
6. A prioritised issue list with severity, timestamp, expected result and suggested fix.
7. Separate confirmed observations from guesses. Do not invent hidden backend, payment or ad behaviour.

Do not recommend copying another commercial game's protected assets, brand, text or source code.
"""


def load_config() -> dict:
    return json.loads(CONFIG.read_text(encoding="utf-8"))


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
    parser = argparse.ArgumentParser(description="Review gameplay video with Gemini Flash-Lite.")
    parser.add_argument("video", type=Path)
    parser.add_argument("--prompt", type=str, default=PROMPT)
    parser.add_argument("--output", type=Path, default=Path("reports/video-review/latest-review.md"))
    args = parser.parse_args()

    if not args.video.is_file():
        print("Video file not found.", file=sys.stderr)
        return 2

    video_cfg = load_config()["providers"]["google"]["video_review"]
    limits = video_cfg["per_project_app_limits"]
    models = [video_cfg["primary"], video_cfg["fallback"]]

    selected_model = models[0]
    pool_id, api_key = reserve_request(
        "video",
        selected_model,
        rpm_cap=int(limits["rpm"]),
        model_daily_cap=int(limits["per_model_rpd"]),
        group_daily_cap=int(limits["total_rpd"]),
    )
    print(f"Using configured Gemini project pool {pool_id}.", file=sys.stderr)
    client = genai.Client(api_key=api_key)
    uploaded = upload_and_wait(client, args.video)

    try:
        response = client.models.generate_content(
            model=selected_model,
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
    except Exception as exc:
        error = str(exc).lower()
        if "429" in error or "resource_exhausted" in error or "quota" in error:
            raise RuntimeError(
                "Gemini quota/rate limit reached for the selected project. "
                "This run was stopped; no alternate key was tried."
            ) from exc
        # Same project only: use the fallback model for non-quota model errors.
        fallback = models[1]
        reserve_request(
            "video",
            fallback,
            rpm_cap=int(limits["rpm"]),
            model_daily_cap=int(limits["per_model_rpd"]),
            group_daily_cap=int(limits["total_rpd"]),
            preferred_pool_id=pool_id,
        )
        response = client.models.generate_content(
            model=fallback,
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
