# Product rules and quality gates

## Clean-room rule

Rebuild public player-facing functionality, not target-owned assets or source. Do not copy the app name, logo, character design, exact UI illustrations, audio, copy, level layouts or private endpoints. The title, mascot and world must be independently designed.

## Gameplay engine

- Keep deterministic logical board state separate from rendering and animation.
- Choose and document a grid arrangement after additional public gameplay observation.
- Resolve launch, first collision, wall reflection, attachment, matches, detached clusters and objectives in the logical engine.
- Make the aiming preview represent the same collision and placement result as the actual shot.
- A refused shot must not consume a move.
- Make every level reproducible from a saved seed.
- Test: no legal slot, ceiling hit, corner hit, wall bounces, no match, 2-bubble match, 3+ match, detached group, empty colour pool, objective completion, no shots left and retry.

## Progression and content

- Design Easy, Medium and Hard independently, not only by recolouring.
- Use a data-driven campaign catalog.
- Record objective, initial board, available colours, move budget, star thresholds, seed and content revision per level.
- Validate legal positions, no overlaps, objectives, solve budgets and duplicate structures.
- A 600-level launch set requires generated/authored content and automated verification. Do not claim it complete until the catalog is built and checked.

## Presentation

- Portrait-first Android.
- Original glossy bubble materials with readable colour and symbol cues.
- Original mascot and world art.
- Aim preview and clear hit, pop, drop, rescue and result transitions.
- Reduced-motion, readable contrast and accessible controls.
- Original or properly licensed sound and music.

## Quality gates

1. Godot 4.7.2 imports and parses the project.
2. Unit tests cover physics, match groups, falling clusters and objectives.
3. Every shipped level passes validation and a reproducible solve or explicit difficulty rule.
4. Input works at varying refresh rates and portrait aspect ratios.
5. Background/resume and offline saves survive process recreation.
6. Android debug APK exports successfully.
7. A real-device install and play test is recorded.
8. Performance, thermal, storage and accessibility checks are documented.
9. Release AAB uses the user's own release signing key, which must never be committed to GitHub.
