# Games in AI Game Factory

Each game is kept in its own isolated folder or source bundle. Existing projects such as Board Masters Arena and Screw Puzzle are not modified.

## Prism Grove
- Source bundle: `prism-grove-source.zip`
- CI unpacks it to `games/prism-grove/`, runs Godot smoke tests, and exports an Android arm64 debug APK.
- Open the extracted `games/prism-grove/` folder in Godot 4.7.2 Stable. Generate local SFX first with `python3 scripts/generate_audio.py`.
- The debug APK is for device testing only, not a Play Store release.
