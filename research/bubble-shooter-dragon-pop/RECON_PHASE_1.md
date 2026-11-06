# Bubble Shooter Reference Recon — Phase 1 (Public Evidence)

Date: 2026-11-06
Target: Google Play package `game.bubble.shooter.dragon.pop`
Store title: Bubble Shooter
Publisher shown by Google Play: UUTEAM Technology Limited-Dragon Inc.
Status: Public-source reconnaissance only. This is not an APK-level or full runtime audit.

## 1. Source register

| Source | What it establishes | Limits |
|---|---|---|
| [Google Play listing](https://play.google.com/store/apps/details?id=game.bubble.shooter.dragon.pop) | Current public description, store metadata, screenshots, ratings, declared ads/offline status, public reviews | Does not reveal all screens, internal rules, exact level count, ad frequency, purchase inventory or implementation |
| [AppBrain app profile](https://www.appbrain.com/app/bubble-shooter/game.bubble.shooter.dragon.pop) | Third-party metadata snapshot: version 167.0, approx. 121 MB, Android 6+, 200M install estimate, ads | Third-party snapshot; install and size figures may differ by region/version |
| [Chrome-Stats profile](https://chrome-stats.com/d/game.bubble.shooter.dragon.pop) | Third-party version, screenshot index and review-theme summary | Not developer documentation; not authoritative for implementation |
| [Replica Skill](https://github.com/Jakeschincariol/replica-skill) | Clean-room workflow and required recon/build artifacts | Its own rules prohibit decompiling the target binary or copying its code/assets |
| [REA](https://github.com/morluto/rea) | Android APK static-analysis workflow and evidence requirements | Requires a connected REA MCP server, APK file path, JADX MCP JAR and Java 17+ |

## 2. Verified public facts

- Google Play currently identifies the package as `game.bubble.shooter.dragon.pop`.
- The listing reports 100M+ downloads, a 4.5-star rating and about 1.14M reviews at the time checked.
- The listing says the game contains ads and supports offline play.
- The store description says the core loop is to aim, match 3 or more bubbles, remove bubbles to reveal/rescue small dragons, use props/boosters, and earn stars based on performance.
- The listing describes a single-player, stylized/cartoon, dinosaur-themed bubble shooter.
- The listing's visible update date is 2025-10-31.
- The public screenshots show a portrait-oriented playfield, dense glossy bubble formations, a lower-center launcher, a bright aiming/shot beam, and varied themed backdrops. The visible boards include colored bubbles, dark/metal-looking blockers or special pieces, and special glowing projectiles. These are visual observations from the listing screenshots, not proof of every in-game rule.
- Public reviews include complaints about intrusive or frequent ads, slow bubble movement, sound continuing after mute, helper behavior that feels unpredictable, and occasional level/aim/boost bugs. These are individual user reports and should be treated as issues to investigate, not universal facts.

## 3. Screen inventory: confirmed vs unknown

| ID | Screen/area | Evidence status | Notes |
|---|---|---|---|
| S01 | Main menu / start | Unknown | No reliable public screenshot of the full menu inspected yet |
| S02 | Level selection / map | Unknown | Need user walkthrough or lawful runtime observation |
| S03 | Core gameplay | Partially confirmed | Store screenshots show portrait board, launcher, bubbles and themed backgrounds |
| S04 | Pause/settings | Unknown | Need direct walkthrough |
| S05 | Booster/prop selection | Partially confirmed | Store text confirms props exist; exact set and UI unknown |
| S06 | Level completion / stars | Partially confirmed | Store text confirms star rewards; exact result screen unknown |
| S07 | Failure / continue | Unknown | Need runtime observation |
| S08 | Shop / currency / IAP | Unknown | Store listing alone does not establish whether IAP exists |
| S09 | Ads / rewarded ads | Partially confirmed | Listing declares ads; placements, frequency and reward rules unknown |
| S10 | Dragon rescue / collection | Partially confirmed | Store description says removing bubbles reveals cute dragons; full collection flow unknown |
| S11 | Settings / sound | Unknown | Public review mentions mute issue, but settings layout is not confirmed |
| S12 | Offline behavior / save | Partially confirmed | Listing labels game offline; save format and offline feature coverage unknown |

## 4. Core loop inferred from public evidence

1. Load a level.
2. Present a bubble formation and a launcher with a current/next bubble state (the latter is visible in store screenshots).
3. Aim and shoot toward a matching color group.
4. Match at least three same-color bubbles.
5. Remove connected bubbles; some shots reveal dragon characters.
6. Use available props/boosters when needed.
7. Finish the level and award a star rating based on performance.

Unknown mechanics that must not be guessed into the final design: shot limits, ceiling/row descent, exact wall-bounce physics, swap rules, bubble queue behavior, color spawning, objective variants, special-piece rules, dragon rescue conditions, scoring formula, star thresholds, lives/energy, map progression, and retry/continue rules.

## 5. Clean-room product direction

Build a new Android bubble-shooter game with its own name, brand, characters, art, sounds, level layouts, UI copy and code. Recreate only broad, non-proprietary interaction patterns after they are independently understood.

Quality targets for our implementation:
- Accurate, predictable aiming and collision behavior.
- Smooth, responsive projectile travel and clear hit feedback.
- Readable board composition on small Android screens.
- Distinct original world themes and original creature designs.
- A transparent, player-friendly ad policy; no ads interrupting an active shot or covering controls.
- Sound and music mute controls that actually mute all relevant channels.
- Deterministic, validated levels with no impossible boards.
- Reliable local saves and offline play.
- Clear, understandable booster behavior with no random helper actions that confuse the player.
- Automated tests for level solvability, shot resolution, color connectivity, falling clusters, scoring and save recovery.

## 6. Skill findings and execution status

### Replica Skill
The `replica-recon` instructions were read from the public repository. They require a source register, stable screen IDs, user flows, component inventory, evidence-backed data model, feature matrix, exclusions and honest project sizing. The skill is clean-room and explicitly says not to decompile the target binary, scrape private pages, copy source, assets, logos or copy. Its build stages are recon → architecture → design → build → test → diff → improve → rebrand → launch.

### REA
The `reverse-engineer-anything` skill and Android artifact reference were read from the public repository. REA's documented Android flow starts with `inspect_android_package`, then class/method inspection and reference tracing. Its documentation says the APK is inspected statically and is not launched; JADX MCP JAR 0.7.1 and Java 17+ are required.

**Important execution limitation:** no REA MCP tools are registered in the current connected tool session. Reading the REA skill does not install or register its MCP server. No target APK was found among the available conversation/library files. Therefore no APK manifest, DEX, class, method, native library, SDK, permission or binary-level finding is claimed here.

## 7. Required evidence to complete A-to-Z

- The target APK file supplied by the user, or a lawful copy they control, for REA static package analysis.
- A user-recorded walkthrough covering first launch, main menu, map, first level, several later levels, pause/settings, each booster, win/fail, shop and ad/reward screens.
- Screenshots/video at the actual Android phone resolution, including loading and transitions.
- If the target app requires network access, only observations from the user's own app session and permitted public behavior; do not capture credentials or private player data.

## 8. Next stages

1. Complete evidence-backed recon and feature matrix.
2. Write architecture and deterministic game-engine specification.
3. Create original art direction and UI design tokens.
4. Build the gameplay vertical slice in Godot 4.7.2.
5. Add level authoring/validation, progression, boosters, save, audio and settings.
6. Run automated gameplay and Android export tests.
7. Compare our screens and flows against the documented functional requirements, not copied assets.

No APK or playable build is claimed by this research phase.
