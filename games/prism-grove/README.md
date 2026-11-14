# Prism Grove

An original, offline-first 8×8 tile-placement puzzle for Android, made with Godot 4.7.2.

## Gameplay
- Select one of three shapes, then tap an empty board cell to place it.
- Complete rows and columns to clear them; simultaneous clears add bonus points and combos.
- Classic endless mode and a date-seeded Daily Bloom goal (12 lines).
- Four player-selected palettes, original synthesized placement/clear/error sound effects, pause/restart/home, best-score saving and one undo per round.
- No network permission and no third-party game art or audio.

## Reference and originality
The requested reference is Block Blast! (com.block.juggle). Prism Grove uses only broad genre conventions: grid-based shape placement, row/column clears, combos and offline solo play. Its name, logo, visual language, UI, code and shape definitions are original. No reference-game assets, code or branding are included.

## Build
Open with Godot 4.7.2 Stable. Run python3 scripts/generate_audio.py once, then open the project and run res://scenes/main.tscn. Automated smoke test: godot --headless --path . --script res://tests/smoke_test.gd.

The GitHub Actions workflow generates original WAV sound effects, runs the Godot smoke tests, and builds an Android arm64 debug APK with Target SDK 36. A successful CI run will publish the APK as a downloadable workflow artifact. It is not a Play Store release-signed AAB. Install and test on a physical Android device before release.

## License
Original project code and icon: MIT. Godot Engine and its templates retain their own licenses.
