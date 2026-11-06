# Game task: original carrom-inspired Android game

**Working title:** Board Masters Arena (placeholder)  
**Engine:** Godot 4.7.2 stable  
**Platform:** Android, mid-range devices first

## Clean-room boundary

Use Miniclip Carrom Pool only as a reference for publicly observable features and player journeys. Build independent code, brand, art, sounds, screen layouts and backend. Do not copy source code, logo, text, screenshots, assets, player data or private APIs. Reference screenshots remain in research and are never shipped.

## Product target

A polished top-down board game with responsive physics, a 3D-look finish, clear turn feedback, collision/pocket effects, satisfying sounds and quick rematches.

## Modes

1. Classic Carrom with independently written queen and foul rules.
2. Disc Pool.
3. Original Precision Challenge.
4. Two-player same-device pass-and-play.
5. Offline practice against a local bot.
6. Online 1v1 first; add 2v2 only after backend and abuse testing.

## Content targets

- 50 original board skins listed in research/carrom-pool/BOARD_PLAN_50.md.
- 24 original striker designs at launch target.
- Force, Aim and Time stats with transparent values and balance caps.
- At least 12 original power effects; publish exact effects and balance them.
- Pucks and shot trails are cosmetics only.
- These are our new-game content targets, not claims about the reference app's current inventory.

## Technical requirements

- Responsive touch aiming, guideline, power control, release, turn clock and turn resolution.
- Reliable collisions, friction, walls, corner pockets, queen/cover and foul logic.
- Automated tests for scoring, fouls, duplicate reward prevention and save/load.
- Local settings and offline progress must work without internet.
- Online match result, currency ledger and purchases must be server-validated.
- Android scaling, pause/resume, low-memory checks and thermal/performance testing.

## Monetisation

Use optional rewarded ads for fixed disclosed rewards. Sell fixed-content cosmetic boards/looks with clear prices. Do not add paid roulette or paid random-reward boxes. Never interrupt active shots with ads. For any purchase, use Google Play Billing with server-side verification and a parent/guardian-approved flow.

## Definition of done

A milestone needs Godot headless parse/import, automated gameplay tests, Android export, actual-phone install test, offline force-close/reopen test, 30-minute stability test, online reconnect tests, frame-time/memory report and screenshots/video evidence. Code existing in the repo alone is not completion.

## Build order

1. Finish evidence-based screen and feature recon.
2. Build physics prototype and automated rules tests.
3. Finish offline/local match loop and visual polish.
4. Add cosmetic inventory and local save.
5. Add online backend/matchmaking.
6. Add optional rewarded ads and fixed-price store.
7. Run device QA, security review and release export.
