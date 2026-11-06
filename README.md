# AI Game Factory — Board Masters Arena

This public repository contains an original Godot 4.7.2 carrom-style game, evidence-based reference research, model routing, analysis helpers, automated CI, a restricted repair agent, a manual DSH game agent and an Android debug-export workflow.

## Current game build

Open the `game/` folder in Godot 4.7.2 stable. Main scene: `game/scenes/main.tscn`.

Current playable slice:
- Classic Carrom (18 discs + queen) and Disc Pool (12 discs).
- Touch aiming, striker baseline placement, disc collision, friction, cushion bounce and four pockets.
- Simplified scoring, foul return and queen-cover rules.
- Offline AI and same-device local two-player.
- 50 original board palettes.
- 24 original strikers with Force, Aim and Time stats.
- XP unlocks, turn timer and local profile save.

This is a real playable starting point, not a complete commercial game or a confirmed APK. Full carrom rules, full power collection, polished 3D-look assets, animation/audio, online 1v1/2v2, accounts, cloud save, friends/leaderboards, shop, server-validated purchases, rewarded ads, final AAB and phone QA remain development milestones.

## Workflows

- **Godot CI:** checks YAML/configuration, Python helpers, quota-pool tests, export preset, Godot import and gameplay smoke tests.
- **Auto Repair Agent:** on a failed Godot CI run, NVIDIA Nemotron can propose a limited code patch and open a review pull request. It cannot change workflows/secrets or merge.
- **DSH Game Agent:** manual Actions workflow. Provide a scoped task; DSH headless uses NVIDIA Nemotron in a disposable runner and opens a review PR. It has not yet been successfully run end-to-end.
- **Android Debug APK:** manual Actions workflow. It aims to export an arm64 debug APK and upload it as an artifact. The pipeline itself still needs a successful manual run and real-phone install test. It is not a signed Play Store AAB.

## Current model routes

- NVIDIA Nemotron 3 Ultra: deep planning and difficult code review.
- NVIDIA Nemotron 3.5 Lightning: routine coding and repair.
- Gemini 3.5 Flash-Lite / 3.1 Flash-Lite: video review.
- Gemma 4 26B A4B / 31B: text reasoning.

NVIDIA app-side cap: 30 requests/minute. Gemini supports two independent project pools only after the two API keys are confirmed to belong to different Google Cloud projects. Set Actions variable `GEMINI_PROJECTS_ARE_SEPARATE=true` after confirming this in Google AI Studio. The current app-side caps per project are:
- Flash-Lite video review: 10 RPM, 500 requests/24h per selected model, 1,000 total.
- Gemma 4 reasoning: 28 RPM, 14,000 requests/24h across the Gemma models.

These are application safeguards based on your reported AI Studio quota, not provider guarantees. The local quota ledger round-robins new tasks between the two confirmed projects and does not retry another key after HTTP 429.

## Important files

- `game/README.md` — playable feature list and known limitations.
- `research/carrom-pool/RESEARCH.md` — public reference research and unknowns.
- `research/carrom-pool/FEATURE_MATRIX.csv` — feature/evidence matrix.
- `research/carrom-pool/SCREEN_CAPTURE_CHECKLIST.csv` — app walkthrough checklist.
- `research/carrom-pool/BOARD_PLAN_50.md` — 50 original board ideas.
- `game/data/striker_catalog.json` — 24 striker stats, themes and XP unlocks.
- `agents/CARROM_GAME_BRIEF.md` — product and technical brief.
- `agents/GAME_AGENT_ROLES.md` — specialist agent roles.
- `agents/AUTO_REPAIR_AGENT.md` — repair workflow limits.
- `docs/MODEL_ROUTING.md` — model and quota configuration.
- `docs/ANDROID_BUILD.md` — debug APK export instructions.
- `config/dsh-profile-overlay.example.yml` — DSH Nemotron and optional REA MCP configuration.
- `tools/gemini_video_review.py` — Gemini Flash-Lite video review.
- `tools/gemma_reason.py` — Gemma 4 text reasoning.
- `tools/google_quota.py` — dual-project quota ledger.

## Run the workflows

GitHub → Actions → select the workflow:
- Godot CI runs on pushes and pull requests.
- DSH Game Agent takes a task input and creates a review PR.
- Android Debug APK exports a phone-test build.

Actions is allowed to create pull requests only for DSH and repair-agent review branches. Do not put API keys, Android keystores, private videos, player data or the commercial reference APK in this public repository.
