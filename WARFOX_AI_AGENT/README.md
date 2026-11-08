# WARFOX AI AGENT

Android-first assistant app for the WARFOX workflow. All agent code remains isolated in this folder; the existing WARFOX game project and main branch are not modified.

## Build
- Android Studio / Gradle project.
- Package: `com.warfox.agent`
- Minimum Android: 8.0 (API 26).
- Java 17, Kotlin, Android SDK 35.
- GitHub Actions builds a debug APK artifact.

## AI provider settings
Open **إعدادات الذكاء الاصطناعي** in the app. The provider must expose the OpenAI-compatible Chat Completions endpoint `/chat/completions`.

Examples:
| Provider | Base URL | Example model |
|---|---|---|
| OpenAI | `https://api.openai.com/v1` | `gpt-4o-mini` |
| Groq | `https://api.groq.com/openai/v1` | `llama-3.3-70b-versatile` |
| OpenRouter | `https://openrouter.ai/api/v1` | Use a model ID listed by OpenRouter |

Enter the base URL, model ID, and API key, save, then use **اختبار الاتصال الحقيقي**. Only HTTPS endpoints are accepted. The API key is encrypted on-device using Android Keystore AES-GCM; it is not included in the repository, logs, or task payloads.

**Current boundary:** when an API provider is configured, the main send button calls that model for a direct AI response and saves the conversation locally. It does not yet route that model's response into the Android screen-action engine or the separate Termux worker. Without a configured provider, the existing Termux bridge path remains active.

## Google account
The Google account screen uses Android Credential Manager. Configure OAuth in Google Cloud:
1. Create an OAuth 2.0 **Web application** client ID.
2. Configure the Android OAuth client for package `com.warfox.agent` and the app's signing-certificate SHA-1 fingerprint.
3. Paste the Web Client ID into the app's Google account screen.
4. Sign in and confirm the displayed profile.

The app stores the Google profile name/email locally and does not persist the ID token. Cloud account verification and cross-device data synchronization are not implemented; those require a trusted backend/Firebase project configuration.

## Privacy and permissions
- Screen capture starts only after Android's system consent.
- Accessibility and overlay permissions are explicitly enabled by the user.
- API credentials are sent only to the selected HTTPS provider.
- Google ID tokens are not saved to local preferences.
- Do not paste API keys into GitHub issues, commits, screenshots, or chat messages.

## Current limitations
- Direct provider chat is working code but still needs a successful Android build and real-device test.
- Full AI-driven screen perception/action planning, worker cancellation in Termux, cloud account sync, and full device validation are still pending.
- Android may restrict background services and accessibility behavior; continuous unattended operation cannot be guaranteed.
- Emergency stop currently stops local Android agent services, not an independent worker process running in Termux.
