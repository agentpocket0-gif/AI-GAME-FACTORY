# Boltwood Puzzle

An original, offline-first nuts-and-bolts logic puzzle built with Godot 4.7.2. This is a separate project inside the Game Factory repository and does not alter the existing Board Masters Arena game.

## Current playable slice

- Portrait Android layout with an original workshop/wood/metal visual theme.
- Tap exposed fasteners to remove them from overlapping wooden planks.
- A plank clears when all of its bolts have been removed.
- Planks above other planks hide the lower fasteners until cleared.
- Five-space tray; filling it before clearing the board fails the level.
- 30 deterministic level layouts with increasing layers and bolt-count variation.
- Local level progress, coins, and haptic preference saved with Godot ConfigFile.
- Hint, undo, one-use extra tray slot, pause, retry, and level map.
- No network permission, ads SDK, billing SDK, account system, or copied reference assets.

## Clean-room boundary

The linked store game is used only as a reference for the broad nuts-and-bolts puzzle idea and observable player flow. This project uses a new name, new code, original procedural/vector art, an independent layout generator, and its own screens. It does not include the reference game's logo, screenshots, APK assets, source code, text, level files, or private APIs.

## Open in Godot

1. Open the `screw-puzzle/` directory in Godot 4.7.2 stable.
2. Press Play. The main scene is `res://scenes/main.tscn`.
3. The first build uses vector-drawn art, so it does not need downloaded art packs.

## Controls

- Tap a visible bolt to remove it.
- Tap **HINT** to highlight an exposed bolt.
- Tap **UNDO** to reverse the last move.
- Tap **EXTRA SLOT** to spend 60 earned coins for one extra tray space in the current level.
- Use **PAUSE** to restart or return to the level map.

## Tests and Android build

The GitHub Actions workflow `.github/workflows/screw-puzzle-ci.yml` downloads Godot 4.7.2 and its Android templates, imports the project, runs a headless solver over all 30 levels, and exports an arm64 debug APK as an artifact.

The artifact is for testing only. It is not a signed Play Store release AAB and has not yet passed real-device testing. A release build still needs visual/gameplay QA on a phone, privacy and store review, app icon/screenshots, a release keystore managed securely, API-target verification, and a signed AAB pipeline.

## Known limitations

- This is the first playable vertical slice, not a finished commercial release.
- The current art is procedural 2D with a shaded/raised look, not a full 3D physics simulation.
- No sound effects, music, ads, billing, cloud save, analytics, or online features are included.
- Level layouts are deterministic variations from the original generator and need human playtesting and difficulty tuning.
- Android export and real-phone installation must be verified by GitHub Actions and device testing before calling it release-ready.

## License

Original project code and vector artwork in this folder are provided under the MIT License. Godot Engine remains under its own license.
