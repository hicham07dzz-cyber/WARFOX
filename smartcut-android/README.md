# SmartCut AI — Android foundation

This is a separate Android application project on branch `smartcut-android`. It does not modify the WARFOX Godot game or the existing SmartCut website.

## Current implemented functions
- Native Android application shell.
- Pick one reference video from device storage.
- Pick multiple source clips.
- Set a target duration.
- Export a JSON edit-plan draft to a location selected by the user.

## Not implemented yet
This is not the requested finished SmartCut editor. It does not yet perform AI scene/style analysis, automatic best-shot detection, trend recognition, transitions, effects, color grading, speech translation, beat synchronization, or final video rendering. The JSON plan is only a starter artifact, not an edited video.

## APK build
GitHub Actions workflow `.github/workflows/smartcut-android-apk.yml` builds a debug APK and uploads it as an Actions artifact when this branch changes. The APK is not a signed Play Store release.

Repository branch: https://github.com/hicham07dzz-cyber/WARFOX/tree/smartcut-android
