# Muslim Kids

A Flutter app for Muslim children that covers daily prayers, Islamic quizzes, educational videos, and live classes. It's built for kids but has a teacher-facing side too — teachers can schedule live classes, send notifications, and track student progress.

## Why I Built This

I wanted something my kids could actually use to learn and stay on top of their salah without needing me to remind them constantly. Most existing Islamic apps are either built for adults or throw too much at kids at once. This one keeps it simple: track your prayers, watch some videos, do a quiz, see when the next class is.

## Features

- **Prayer times** — calculated based on device location using the Adhan library
- **Prayer tracker** — kids can log which prayers they completed each day, with a calendar view
- **Prayer alarms** — local notifications scheduled per prayer, no server needed
- **Educational quizzes** — multiple-choice quizzes on Quran, Hadith, Islamic history, etc.
- **Islamic videos** — curated YouTube videos embedded in-app for kids
- **Islamic calendar** — shows the Hijri date and upcoming Islamic events
- **Live classes** — teacher accounts can create and manage classes; enrolled students get push notifications
- **Two user roles** — `child` and `teacher`, each with a different home screen and capabilities
- **Push notifications** — Firebase Cloud Messaging for class alerts and reminders

## Tech Stack

- **Flutter** — cross-platform (Android, iOS, Web)
- **Firebase Auth** — email/password login
- **Cloud Firestore** — primary database
- **Firebase Cloud Functions** — backend logic (Node.js), class notifications
- **Firebase Cloud Messaging** — push notifications
- **Adhan** — prayer time calculation
- **Geolocator** — device location for accurate prayer times
- **flutter_local_notifications** — on-device prayer alarms
- **youtube_player_flutter** — embedded video playback
- **Lottie** — animations

## Getting Started

### Prerequisites

- Flutter SDK (≥ 3.7.0) — [install guide](https://docs.flutter.dev/get-started/install)
- Node.js + Firebase CLI (`npm install -g firebase-tools`)
- A Firebase project with Auth, Firestore, and Cloud Messaging enabled

### Setup

```bash
git clone https://github.com/fisforfaheem/muslim_kids.git
cd muslim_kids
flutter pub get
```

**Firebase config:**

```bash
# Copy the example and fill it in with your own Firebase project values
cp android/app/google-services.json.example android/app/google-services.json
# Then replace the placeholder values with the real ones from your Firebase console
```

For iOS, download `GoogleService-Info.plist` from the Firebase console and place it at `ios/Runner/GoogleService-Info.plist`.

**Cloud Functions:**

```bash
cd functions
npm install
firebase deploy --only functions
cd ..
```

**Firestore rules:**

```bash
firebase deploy --only firestore:rules
```

### Run

```bash
flutter run              # on a connected device or emulator
flutter run -d chrome    # in the browser
```

## Project Structure

```
lib/
├── Features/          # One file per main feature (prayers, quizzes, videos, etc.)
├── screens/           # Sub-screens (quiz session, video player)
├── services/          # Firebase + business logic
├── models/            # Data classes (Quiz, PrayerTime, IslamicVideo, etc.)
├── widgets/           # Reusable UI components
├── mixins/            # SafeStateMixin (prevents setState after dispose)
├── home_page.dart     # Child home screen
├── teacher_home_page.dart  # Teacher home screen
├── login_page.dart
└── main.dart

functions/
└── index.js           # Cloud Functions (class notifications, token cleanup)

assets/                # Images, Lottie JSON files, app icon
firestore.rules        # Firestore security rules
```

## Usage

Users sign up with an email and password and choose a role (child or teacher). Children get the prayer tracker, quizzes, videos, and class schedule. Teachers get a dashboard to create classes, view enrolled students, and send reminders.

Prayer alarms are scheduled locally on the device — they'll fire even without an internet connection. Push notifications require FCM and are triggered by Cloud Functions when a new class is created.

## Notes

- Prayer times use the [Adhan](https://pub.dev/packages/adhan) package, which does the calculation on-device. No external API call needed for prayer times.
- The `google-services.json` file is **not** committed to this repo (it contains API keys). See `android/app/google-services.json.example` for the expected structure.
- State management is plain `StatefulWidget` + `setState`. It works fine for this scale but could be migrated to Riverpod if the app grows.
- `cleanupExpiredTokens` is a callable Cloud Function that removes stale FCM tokens from Firestore. Run it occasionally to keep the users collection clean.

## Contributing

Branch off `main`, use descriptive branch names (`feature/add-dhikr-counter`, `fix/prayer-alarm-ios`), run `flutter format .` before committing. Submit a PR with a description of what changed and why.

## License

MIT
