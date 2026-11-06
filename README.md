# AI Game Factory — Board Masters Arena

This public repository now contains the first playable Godot 4.7.2 Carrom-style game slice, public reference research, model routing policy and a restricted CI repair agent.

## Open the game

Open the game/ folder in Godot 4.7.2 stable. The main scene is game/scenes/main.tscn.

The current playable slice includes:
- Touch and mouse drag-back aiming.
- Moving discs, friction, cushion bounces and circle collisions.
- Four pockets, basic scoring, a striker pocket foul and simplified queen-cover logic.
- A simple local AI opponent.
- 50 selectable board colour/palette themes.
- Portrait-friendly layout.

This is a playable starting point, not the finished commercial game. It does not yet include complete official tournament rules, 1v1/2v2 online multiplayer, accounts, cloud saves, shop, Google Play Billing, ads, a full collection/inventory, finished 3D art/audio, final Android export or device QA.

## Current development task

Create an original carrom-inspired mobile game using Miniclip Carrom Pool only as a reference for public features and player flows. Do not reuse its source code, name/logo, text, art, sound, private APIs, player data or extracted assets.

## Important project files

- game/README.md — current playable scope and known gaps.
- research/carrom-pool/RESEARCH.md — public-source reference research.
- research/carrom-pool/FEATURE_MATRIX.csv — evidence-based feature checklist.
- research/carrom-pool/SCREEN_CAPTURE_CHECKLIST.csv — A-to-Z walkthrough capture checklist.
- research/carrom-pool/BOARD_PLAN_50.md — 50 original board theme concepts.
- agents/CARROM_GAME_BRIEF.md — product and technical brief.
- agents/GAME_AGENT_ROLES.md — specialist agent responsibilities.
- agents/AUTO_REPAIR_AGENT.md — repair agent behaviour and limits.
- docs/MODEL_ROUTING.md — verified NVIDIA/Gemini/Gemma IDs and rate-limit policy.
- config/model-routing.json — machine-readable model configuration.

## CI and automatic repair

- Godot CI downloads Godot 4.7.2 and runs project import/parse plus a scene smoke test.
- When a Godot CI run fails, Auto Repair Agent can use NVIDIA Nemotron to propose a restricted patch and open a pull request.
- The repair agent can only edit selected files inside game/. It cannot edit workflows or secrets and cannot merge its own PR.
- Add NVIDIA_API_KEY in GitHub Actions Secrets to enable the repair call. Without it, no code repair is attempted.

## Model keys

Add these GitHub Actions secret names only after reviewing the workflow:
- NVIDIA_API_KEY
- GEMINI_API_KEY_1
- GEMINI_API_KEY_2

Never put live keys in repository files. Gemini quotas are project-scoped, so two keys belonging to the same project do not double RPM/RPD.

## Public repository safety

Never commit live API keys, Android signing keys, private account exports, player data, or the commercial game's APK. Keep any authorised APK used for static analysis outside the public repository. Do not upload decompiled proprietary code or extracted app assets.

## Monetisation principles

Use optional rewarded ads and clear, fixed-content cosmetics only. Purchases require server-side validation and an appropriate adult/guardian-approved setup. Do not add paid random-reward boxes or paid roulette. Never interrupt an active shot or match with an ad.
