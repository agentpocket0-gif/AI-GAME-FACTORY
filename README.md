# AI Game Factory — Godot Android

This public repository is the cloud-first workspace for an original mobile board game built with Godot 4.7.2.

## Current task
Build an original carrom-inspired game using the public behaviour of Miniclip Carrom Pool as a research reference. Do not reuse Miniclip source code, logo, brand, artwork, audio, proprietary assets, private APIs or player data.

## Start here
- Public reference research: research/carrom-pool/RESEARCH.md
- Feature evidence matrix: research/carrom-pool/FEATURE_MATRIX.csv
- 50 original board themes: research/carrom-pool/BOARD_PLAN_50.md
- Game task brief: agents/CARROM_GAME_BRIEF.md
- Analysis tool setup: docs/APP_ANALYSIS_STACK.md
- Clean-room recon instructions: agents/REPLICA_RECON_METHOD.md

## Important status
The repository currently contains a starter scaffold and a public-source research baseline. It is not a finished game and no reference APK has been inspected. The exact live counts of boards, strikers, pucks, trails and powers, current India prices, full ad placements, and offline sync behaviour still need a controlled walkthrough of the installed app.

## Tool roles
- replica-skill provides an 11-stage clean-room workflow. Its recon method is adapted for the DSH agent instructions in this repository.
- REA provides CLI/MCP tools for evidence-backed app and Android APK inspection. APK analysis requires an authorised APK file, Node.js, a full JDK and the pinned JADX engine.
- DSH can connect an external REA MCP server using its MCP client.

## Public repository safety
Never commit API keys, signing keys, private account exports, player data, or the commercial game's APK. Keep credentials in GitHub Actions Secrets. Use only APK files you are authorised to inspect. Do not put extracted proprietary assets in this repository.

## Game principles
Offline practice and local play should work without internet. Online matches and purchases require server-side validation. Use optional rewarded ads only, clearly priced fixed-content cosmetics, and a parent/guardian-approved purchase flow. Avoid paid random-reward boxes and paid roulette mechanics.
