# GlucoseGuard

AI-Powered Hypoglycemia Prediction and Carb-Counting Tool for Indian T1D Diets — a Flutter Android MVP for hackathon demonstration.

## Features

- Splash screen with branded intro
- Home dashboard with today's risk, nutrition summary, and recent meals
- Add Meal flow with searchable Indian food database (21 items)
- Real-time nutrition calculation (carbs, calories, protein, fiber)
- Demo risk prediction with circular progress indicator
- Meal history with local persistence (SharedPreferences)
- Profile screen with customizable carb goal
- Account registration and login with Flask backend

## Project Structure

```
lib/
├── main.dart
├── data/food_database.dart
├── models/
├── screens/
├── services/
├── theme/
└── widgets/
```

## Getting Started

### Prerequisites

1. [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x+)
2. [Android Studio](https://developer.android.com/studio) with Android SDK
3. An Android emulator or physical device

### Setup

```bash
cd glucose_guard
flutter pub get
flutter doctor
```

If Android SDK is installed in a custom location:

```bash
flutter config --android-sdk <path-to-android-sdk>
```

### Run the App

```bash
flutter run
```

### Build Android APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Run on a physical phone over Wi-Fi (no USB cable)

The phone and laptop must be on the **same Wi-Fi network**. The backend keeps
using `--dart-define=API_BASE_URL` (no IP is hardcoded in Dart source). The
current verified laptop Wi-Fi address is **`192.168.7.10`**.

1. Verify the laptop's active Wi-Fi IPv4 address (see the `WLAN`/`Wi-Fi`
   adapter). It must match `192.168.7.10`, otherwise update it in the steps
   below:

   ```powershell
   ipconfig
   ```

2. Start the Flask backend bound to all interfaces on port 5000. Debug mode is
   intentionally **not** enabled:

   ```powershell
   flask --app backend.app:create_app run --host 0.0.0.0 --port 5000
   ```

3. The laptop IP is already registered for cleartext HTTP in
   `glucose_guard/android/app/src/main/res/xml/network_security_config.xml`
   (cleartext stays disabled everywhere else). If the laptop IP changes, edit
   that `<domain>` line:

   ```xml
   <domain includeSubdomains="false">192.168.7.10</domain>
   ```

4. Build the release APK pointing at that IP:

   ```powershell
   cd glucose_guard
   flutter build apk --release --dart-define=API_BASE_URL=http://192.168.7.10:5000
   ```

5. Transfer and install on the phone from
   `build\app\outputs\flutter-apk\app-release.apk` using any trusted local
   method (Google Drive, email-to-self, Nearby Share, or a local HTTP server).
   No USB cable is required.

6. From the phone's Chrome, open `http://192.168.7.10:5000/auth/login` — a JSON
   validation message confirms reachability (a refusal/timeout means the phone
   cannot reach the laptop).

7. If Windows Firewall blocks the connection, create a **private-profile only**
   inbound rule for TCP 5000 (Administrator PowerShell):

   ```powershell
   New-NetFirewallRule -DisplayName "GlucoGuide backend (private)" `
     -Direction Inbound -Protocol TCP -LocalPort 5000 `
     -Action Allow -Profile Private
   ```

   Do not open the port on the Public profile.

> Note: the laptop's IP can change between sessions (DHCP), which would break
> old builds. Re-check `ipconfig` and rebuild, or reserve a static IP. If the
> phone cannot connect even with the correct IP, the Wi-Fi network may have
> **client isolation** enabled.

Authentication is handled by the Flask backend (`POST /auth/register` and `POST /auth/login`).

## Demo Flow for Judges

1. Launch app → Splash → Home dashboard (pre-populated demo meals)
2. Tap **Add Meal** in bottom navigation
3. Search/select **Roti** → quantity **2**
4. Add **Dal** → quantity **1**
5. Add **Rice** → quantity **1**
6. Tap **Calculate Risk**
7. View prediction screen → **Save Meal**
8. Check **History** tab for saved meals

## Architecture Notes

- **FoodDatabase** — local mock data, replaceable with API
- **NutritionService** — calculates totals from selected foods
- **PredictionService** — isolated deterministic mock algorithm (swap for ML model)
- **StorageService** — SharedPreferences persistence

## Disclaimer

For educational and demonstration purposes only. This tool does not replace professional medical advice. Risk estimates are labeled **Demo Risk Estimate**.
