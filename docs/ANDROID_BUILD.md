# Android build pipeline

Workflow: `.github/workflows/android-debug.yml`

Run it from GitHub:
1. Open Actions.
2. Select **Android Debug APK**.
3. Tap **Run workflow**.
4. When it succeeds, download the `BoardMastersArena-Android-debug` artifact.

The workflow uses Godot 4.7.2, the matching Android export templates, Java 17 and Android API 36. It builds an **arm64 debug APK** for phone testing. It is not a signed release AAB and is not ready for Play Store upload.

The export preset uses the original placeholder package ID `com.agentpocket.boardmastersarena`. Change it only before the first public release and keep it stable thereafter.

The current build has no ads, in-app purchases, network permissions or online backend. Add those only after implementing and testing their SDK/backend integrations, with an appropriate adult/guardian-approved release process.

Google Play's current new-app and update requirement from August 31, 2026 is target API 36 or higher. This preset is configured for API 36; final Play Console compliance and signing remain separate release gates.

Official references:
- https://docs.godotengine.org/en/latest/tutorials/export/exporting_for_android.html
- https://docs.godotengine.org/en/latest/tutorials/editor/command_line_tutorial.html
- https://support.google.com/googleplay/android-developer/answer/11926878
