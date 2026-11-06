# Board Masters Arena — Godot 4.7.2

This folder contains an original, offline-first carrom-style playable slice.

## Playable features

- Classic Carrom setup: 18 discs plus the queen.
- Disc Pool setup: 12 discs and no queen.
- Drag-back touch/mouse aiming and shot release.
- Place the striker horizontally along the active baseline.
- 2D disc collisions, friction, cushion bounce and four corner pockets.
- Basic scoring, striker/opponent-disc fouls and simplified queen-cover handling.
- Offline AI opponent.
- Same-device local two-player pass-and-play.
- Turn timer using the selected striker's Time stat.
- 50 original board colour/material palettes.
- 24 original striker designs with Force, Aim and Time values.
- Animated collision sparks and expanding pocket rings, with automatic effect cleanup.
- Pause overlay with frozen turn clock, resume and new-match actions; Android Back/Escape toggle.
- Initial strikers unlock through XP milestones; no paid stat advantages.
- Local profile save at `user://player_profile.json` for selected board/striker, mode, matches, wins and XP.

## Controls

1. Select Classic Carrom or Disc Pool.
2. Choose Offline AI or Local 2 Players.
3. Tap the striker button to cycle through unlocked designs.
4. Tap near your baseline to place the striker horizontally.
5. Tap the striker, drag backwards to set power and direction, then release.
6. Use the board button to cycle the 50 themes.
7. New Match restarts the current mode.

## Physics and rules limitations

The game currently uses a custom simple 2D disc solver with equal-mass collision response, friction and cushion restitution. It is not yet calibrated to official carrom tournament equipment or a full reference game's hidden rules. Queen/foul handling is a simplified first pass; corner capture, cover, striker-return and opponent-piece penalties still need an expanded rules test suite.

The local AI is a basic target-directed opponent, not a strong competitive bot. Scores and XP are local practice progression, not a cloud-backed economy.

## Not implemented yet

- Full Carrom/Disc Pool rules and edge-case test suite.
- 12 original power designs and their balanced implementation.
- Finished animated menus, 3D-look assets, haptics and sound.
- Online accounts, matchmaking, server-authoritative 1v1/2v2, friends and leaderboards.
- Cloud save and secure currency ledger.
- Google Play Billing, purchase validation and optional rewarded ad SDK.
- Release AAB, signing, privacy/compliance review and real-device QA.

Do not call this a final commercial release. The project currently has a cloud-tested playable slice. Android export is a separate manual workflow and still requires a successful artifact build plus device installation/play testing.
