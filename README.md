# Mood Tracker App

A Flutter application for tracking your mood and journaling with gamification elements.

## Features

- User authentication (Firebase Auth)
- Mood tracking (happy, sad, neutral)
- Journal entries (add, edit, delete)
- Gamification (badges and points system)
- Secure API integration
- Offline capability

## Architecture

- **State Management**: GetX
- **Design Pattern**: Observer Pattern for authentication state
- **Database**: Firebase Firestore
- **Authentication**: Firebase Auth

## Setup Instructions

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Set up Firebase project and add configuration files
4. Run `flutter run` to start the app

## API Integration

The app integrates with a sample REST API with token-based authentication. Error handling and retry mechanisms are implemented.

## CI/CD

GitHub Actions is configured for continuous integration. The workflow includes:
- Running tests
- Code analysis
- Building APK and IPA files
- Uploading artifacts

## Deployment

### Android (Google Play Internal Testing)
1. Build release APK: `flutter build apk --release`
2. Upload to Google Play Console
3. Distribute to internal testers

### iOS (TestFlight)
1. Build IPA: `flutter build ipa --release`
2. Upload to App Store Connect using Transporter
3. Submit to TestFlight for testing