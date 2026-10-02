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
