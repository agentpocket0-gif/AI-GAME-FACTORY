# AI Game Factory — Board Masters Arena

This public repository contains a first playable Godot 4.7.2 Carrom-style game slice, public reference research, model-routing configuration, video/text review helpers and a restricted CI repair agent.

## Open the game

Open the `game/` folder in Godot 4.7.2 stable. Main scene: `game/scenes/main.tscn`.

Current playable slice:
- Touch and mouse drag-back aiming.
- Moving discs, friction, cushion bounces and circle collisions.
- Four pockets, basic scoring, a striker-pocket foul and simplified queen-cover logic.
- A simple local AI opponent.
- Local two-player pass-and-play on one device.
- 50 selectable original board colour/palette themes.
- Portrait-friendly layout.

This is a playable vertical slice, not the finished commercial game. It still needs complete carrom rules, reviewed physics tuning, 1v1/2v2 online services, accounts, cloud saves, full inventory, shop, purchase verification, rewarded ads, complete menus, final 3D art/audio, Android export and real-device QA.

## Reference and clean-room boundary

Use Miniclip Carrom Pool only as a public reference for observable gameplay patterns and feature research. Do not reuse its source code, name/logo, text, artwork, sound, private APIs, player data, APK contents or extracted assets. All shipping art and code must be original or properly licensed.

## Important files

- `game/README.md` — playable scope and known gaps.
- `research/carrom-pool/RESEARCH.md` — public reference research and unknowns.
- `research/carrom-pool/FEATURE_MATRIX.csv` — evidence-based feature matrix.
- `research/carrom-pool/SCREEN_CAPTURE_CHECKLIST.csv` — screen walkthrough checklist.
- `research/carrom-pool/BOARD_PLAN_50.md` — 50 original board theme concepts.
- `agents/CARROM_GAME_BRIEF.md` — product and technical brief.
- `agents/GAME_AGENT_ROLES.md` — specialist agent roles.
- `agents/AUTO_REPAIR_AGENT.md` — automatic CI repair design and limits.
- `docs/MODEL_ROUTING.md` — model IDs, thinking settings and quota policy.
- `config/model-routing.json` — machine-readable routing caps.
- `config/dsh-profile-overlay.example.yml` — DSH Nemotron and REA MCP overlay example.
- `docs/DSH_CONFIGURATION.md` — how to merge the DSH overlay into an existing profile.
- `tools/gemini_video_review.py` — Gemini Flash-Lite video review helper.
- `tools/gemma_reason.py` — Gemma 4 text reasoning helper.

## CI and auto-repair

- Godot CI downloads Godot 4.7.2, checks JSON/Python helper syntax, imports the project and runs gameplay smoke tests.
- A failed Godot CI run can trigger the NVIDIA Nemotron repair agent.
- The repair agent is limited to selected files under `game/`, validates its patch and opens a pull request.
- It cannot edit workflows/secrets or merge its own PR. Human review and passing CI are required.
- The repair agent only handles failures that CI can observe. It cannot automatically diagnose every device-only, online-server or design issue.

For PR creation, check the repository Actions settings and allow GitHub Actions to create pull requests. Add `NVIDIA_API_KEY` in Actions Secrets to enable repair calls.

## Model keys

Add these secret names in Settings -> Secrets and variables -> Actions:
- `NVIDIA_API_KEY`
- `GEMINI_API_KEY_1`
- `GEMINI_API_KEY_2`

NVIDIA app-side request cap: 30 RPM. Gemini video app-side cap: 10 RPM, 500 requests per rolling 24h per configured video model, 1,000 total. Gemma 4 app-side cap requested: 28 RPM and 14,000 per rolling 24h per model. These are local safeguards, not provider quota guarantees. Google's Gemini quotas are project-scoped, so two keys in the same project do not double the quota.

Never put live keys in repository files, commits, issues, workflow logs or this README.

## Android and APK safety

Never commit live API keys, Android signing keys, private account exports, player data or the commercial reference game's APK. Keep authorised APKs and private gameplay recordings outside this public repository. Do not upload decompiled proprietary code or extracted app assets.

## Monetisation principles

Use optional rewarded ads and clearly priced fixed-content cosmetics only. Any future purchase flow needs server-side receipt validation and adult/guardian approval. Do not add paid random-reward boxes or paid roulette. Never interrupt an active shot or match with an ad.
