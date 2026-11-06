#!/usr/bin/env python3
"""Shared quota pool for two Gemini API keys tied to two independent projects.

This is an app-side guard. It does not query Google for quota availability.
Do not set GEMINI_PROJECTS_ARE_SEPARATE=true unless AI Studio confirms the
two keys belong to different Google Cloud projects.
"""
from __future__ import annotations

import fcntl
import json
import os
from contextlib import contextmanager
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
STATE = ROOT / ".cache" / "google-api-quota.json"
LOCK = ROOT / ".cache" / "google-api-quota.lock"


@contextmanager
def _locked_state():
    STATE.parent.mkdir(parents=True, exist_ok=True)
    with LOCK.open("a+", encoding="utf-8") as lock_file:
        fcntl.flock(lock_file.fileno(), fcntl.LOCK_EX)
        try:
            if STATE.exists():
                try:
                    data = json.loads(STATE.read_text(encoding="utf-8"))
                except (json.JSONDecodeError, OSError):
                    data = {}
            else:
                data = {}
            if not isinstance(data, dict):
                data = {}
            data.setdefault("next_pool", 0)
            data.setdefault("requests", [])
            yield data
            STATE.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
        finally:
            fcntl.flock(lock_file.fileno(), fcntl.LOCK_UN)


def available_pools() -> list[tuple[str, str]]:
    keys = [
        ("project_1", os.getenv("GEMINI_API_KEY_1", "").strip()),
        ("project_2", os.getenv("GEMINI_API_KEY_2", "").strip()),
    ]
    keys = [(name, key) for name, key in keys if key]
    if not keys:
        raise RuntimeError("No Gemini API keys are configured in the runtime.")
    if len(keys) == 2 and os.getenv("GEMINI_PROJECTS_ARE_SEPARATE", "").lower() != "true":
        raise RuntimeError(
            "Two keys are present, but separate project quotas are not enabled. "
            "Confirm in Google AI Studio that the keys belong to different Google Cloud projects, "
            "then set GEMINI_PROJECTS_ARE_SEPARATE=true."
        )
    return keys


def _prune(rows: list[dict[str, Any]], now: datetime) -> list[dict[str, Any]]:
    kept = []
    for row in rows:
        try:
            timestamp = datetime.fromisoformat(str(row["time"]))
            if now - timestamp < timedelta(hours=24):
                kept.append(row)
        except (KeyError, ValueError, TypeError):
            continue
    return kept


def reserve_request(
    group: str,
    model: str,
    *,
    rpm_cap: int,
    model_daily_cap: int | None = None,
    group_daily_cap: int,
    preferred_pool_id: str | None = None,
) -> tuple[str, str]:
    """Reserve one request in a project pool and return (pool_id, API key).

    Pool choice is round-robin and independent of model unless a same-project
    fallback explicitly supplies preferred_pool_id. A provider 429 must stop
    the current run; this function does not rotate keys after a quota error.
    """
    all_pools = available_pools()
    now = datetime.now(timezone.utc)
    if preferred_pool_id is not None:
        preferred_index = next(
            (i for i, item in enumerate(all_pools) if item[0] == preferred_pool_id),
            None,
        )
        if preferred_index is None:
            raise RuntimeError("The selected Gemini project pool is not configured in this runtime.")
        candidate_indices = [preferred_index]
    else:
        with _locked_state() as state:
            start_index = int(state.get("next_pool", 0)) % len(all_pools)
        candidate_indices = [
            (start_index + offset) % len(all_pools)
            for offset in range(len(all_pools))
        ]

    with _locked_state() as state:
        rows = _prune(list(state.get("requests", [])), now)
        for index in candidate_indices:
            pool_id, api_key = all_pools[index]
            pool_rows = [r for r in rows if r.get("pool") == pool_id and r.get("group") == group]
            last_minute = []
            for row in pool_rows:
                try:
                    stamp = datetime.fromisoformat(str(row["time"]))
                    if now - stamp < timedelta(seconds=60):
                        last_minute.append(row)
                except (KeyError, ValueError, TypeError):
                    continue

            model_rows = [r for r in pool_rows if r.get("model") == model]
            if len(last_minute) >= rpm_cap:
                continue
            if model_daily_cap is not None and len(model_rows) >= model_daily_cap:
                continue
            if len(pool_rows) >= group_daily_cap:
                continue

            rows.append({
                "time": now.isoformat(),
                "pool": pool_id,
                "group": group,
                "model": model,
            })
            state["requests"] = rows
            state["next_pool"] = (index + 1) % len(all_pools)
            return pool_id, api_key

        raise RuntimeError(
            "All configured Gemini project pools have reached the local app-side quota guard. "
            "Wait for the limits to reset or check the projects' actual AI Studio quotas."
        )
