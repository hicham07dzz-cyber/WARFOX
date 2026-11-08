# WARFOX AI AGENT

Android-first assistant that accepts natural-language tasks, can request screen capture and accessibility actions with explicit Android consent, and connects to a separately configured AI backend.

## Safety model
- User must explicitly enable Accessibility and screen-capture permissions in Android settings/system prompts.
- A persistent stop control is provided while the agent service is active.
- Destructive actions and file edits require a separate in-app approval.
- No permission bypass, hidden control, credential collection, or unattended purchases.
- Screen capture is session-scoped and stops when the user ends it.

## Current status
Initial Android foundation. The UI, permission flows, service lifecycle, secure backend configuration, task planner, file approval workflow, asset import workflow, and device testing are being implemented in stages. A successful GitHub commit is not proof of an installable or tested APK.

## Build
Open this folder in Android Studio or use the included GitHub Actions workflow. Requires Android SDK 35 and JDK 17.
