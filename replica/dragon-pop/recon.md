# Bubble Shooter (Dragon Pop) - Clean-room Recon

Research date: 2026-11-06
Target package: game.bubble.shooter.dragon.pop
Google Play title: Bubble Shooter
Developer shown by Google Play: UUTEAM Technology Limited-Dragon Inc.
Platform: Android
Our new game's name: not selected yet

## Scope and separation

This is a feature-and-flow study, not a source-code clone. We will build original code, title, branding, characters, backgrounds, sound, copy, UI details and level layouts. We will not ship the target's art, screenshots, audio, logos or text.

Bubble Night is a separate open-source project at https://github.com/SyscallBrain/bubble-night. It is not the Google Play app above. It is only a technical reference for offline game architecture, deterministic simulation, data-driven levels and save recovery. Its source and level files will not be copied into our game.

## Sources and evidence

| ID | Source | Evidence used | Confidence |
|---|---|---|---|
| SRC-01 | https://play.google.com/store/apps/details?id=game.bubble.shooter.dragon.pop | Official title, developer, ads badge, download/rating display, description and play claims | High |
| SRC-02 | https://www.appbrain.com/app/bubble-shooter/game.bubble.shooter.dragon.pop | Third-party version, size and minimum Android metadata | Medium; aggregator |
| SRC-03 | https://socialpeta.com/competitive-intelligence/bubble-shooter-dragon-pop | Secondary gameplay captures showing board HUD, target count and shot count | Medium/low; secondary capture |
| SRC-04 | https://www.gamersunite.com/bubble-shooter-dragon-pop | Secondary gameplay captures of shooter, bubbles and jungle setting | Medium/low; may be older |
| SRC-05 | https://www.youtube.com/watch?v=PTWXnSLReA8 | Public gameplay video published 2020-12-15; older visual reference only | Low for current build |
| SRC-06 | https://github.com/Jakeschincariol/replica-skill | Recon, design, build, test and clean-room method | High |
| SRC-07 | https://github.com/morluto/rea | REA evidence and Android package analysis instructions | High |
| SRC-08 | https://github.com/SyscallBrain/bubble-night | Separate MIT-licensed bubble shooter used as technical study only | High |

## Verified product facts

- Google Play calls the target Bubble Shooter and lists UUTEAM Technology Limited-Dragon Inc. as developer.
- At the time checked, Google Play displays Contains ads, a 4.5 rating and 100M+ downloads.
- The public description says to aim and match at least three bubbles of the same color.
- Removing bubbles reveals or rescues hidden baby dragons.
- The description mentions props and stars awarded according to performance.
- The store description advertises offline play without Wi-Fi.
- A third-party listing reports version 167.0, 121.36 MB and Android 6.0+. These are not official package measurements.
- The public pages reviewed do not establish a complete in-app purchase catalog, exact booster inventory, ad frequency, server APIs or the full campaign map.

## Screen inventory

Only screens supported by public evidence are described as observed. Other screens remain unknown until a controlled walkthrough.

| ID | Screen/state | Supported observation | Evidence | Confidence |
|---|---|---|---|---|
| S01 | Launch/loading | No current loading screen captured | Unknown | None |
| S02 | Home/title | No full current screen capture available | Unknown | None |
| S03 | Campaign/level select | A level-based game is implied, but map and node UI are not verified | Store description only | Low |
| S04 | Active puzzle board | Bubble field, shooter, current/next bubble, shot counter and target/score HUD appear in secondary captures | SRC-03, SRC-04 | Medium |
| S05 | Aim/trajectory | Shooter and aiming direction are visible; exact bounce and guide rules need hands-on confirmation | SRC-03, SRC-04 | Medium |
| S06 | Match/drop event | Match-3 rule is explicit; exact effect timing and detached-cluster behavior are not documented | SRC-01 | High for rule; low for animation |
| S07 | Dragon rescue/objective | Hidden baby dragons are an explicit objective in the store description | SRC-01 | High for concept; low for exact interaction |
| S08 | Booster/prop interaction | Props are confirmed; names, charges, activation and costs are unknown | SRC-01 | High for existence; low for details |
| S09 | Level result/stars | Stars depend on performance; thresholds and result UI are unknown | SRC-01 | High for reward concept |
| S10 | Pause/settings/audio | Not captured | Unknown | None |
| S11 | Ads/continue/rewarded | App contains ads; placement, trigger, frequency and reward flow are not verified | SRC-01 | High for ads; low for behavior |
| S12 | Shop/IAP | Not confirmed by reviewed sources | Unknown | None |
| S13 | Offline/resume | Offline play is advertised; exact background, save and resume behavior is unknown | SRC-01 | High for offline claim; low for edge cases |

## Core gameplay loop

1. Enter a puzzle level. The route into the level is not yet verified.
2. Aim the current bubble toward the board.
3. Match at least three bubbles of the same color.
4. Remove matches and detached groups if confirmed by direct play.
5. Reveal or rescue the hidden dragon objective.
6. Use props when needed; details are unknown pending observation.
7. Finish the level and receive stars based on performance.

The match-and-rescue concepts are strong enough to define the original game's core loop. Exact collision, wall-bounce and cluster-drop rules must be measured before claiming feature parity.

## Clean-room implementation target

- A new brand, theme and mascot unrelated to the target's protected identity.
- A polished portrait mobile bubble shooter with original glossy bubble rendering.
- A deterministic puzzle engine with aim preview and reproducible shots.
- A data-driven level catalog with three independently balanced difficulty variants.
- Original rescue objectives, props, effects, music and progression.
- Offline-first save and recovery.
- Automated gameplay, content and UI tests.
- Optional monetization only after the core game is complete and tested. Ads must never interrupt an active shot.

## Unknowns that block an A-to-Z parity claim

- Full home screen, chapter map and navigation.
- Loading sequence, first-run tutorial and permission prompts.
- Exact collision radius, grid geometry, wall bounce and attachment rules.
- Hidden dragon placement, rescue counter and win conditions.
- Complete booster list, charges, unlock conditions and effects.
- Star thresholds, scoring formula, move budget and fail conditions.
- Campaign size, chapter themes and level unlock logic.
- Ad placements, frequency caps, rewarded offers and ad-free products.
- Whether IAP exists, and if so, its products and prices.
- Audio, haptics, settings, pause, localization and accessibility.
- Save format, cloud backup, account requirements and restore behavior.
- Current device FPS, memory use, loading time and supported aspect ratios.

Do not fill these unknowns by guessing. A player-controlled walkthrough or an authorized APK package report is required.

## REA status

The REA skill instructions have been reviewed, but the REA MCP server is not connected to this conversation and no authorized target APK was supplied. No REA package, signature, manifest, class or method report has been run. This is deliberately not marked complete.

## Clean-room restrictions

Use public store pages, public videos/screenshots and the user's own installed app. Do not access another person's account, bypass access controls, copy private APIs or network traffic, or ship target code, art, audio, copy or screenshots. Keep unknowns labelled as unknown.
