<div align='center'>
  <img src='https://github.com/user-attachments/assets/c5e80af1-30d6-4532-be16-8ca90cb85fa5' width='500px' />
</div>


---

# PescApp

A Flutter application for fishing enthusiasts that provides weather information, maps integration, and fishing-related features.

## Table of Contents
- [Features](#features)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Environment Setup](#environment-setup)
- [Installation](#installation)
- [Running the App](#running-the-app)
- [API Keys](#api-keys)
- [Contributing](#contributing)
- [Security Notes](#security-notes)
- [License](#license)

## Features
- User authentication (Sign in/Sign up)
- Interactive maps with fishing locations
- Real-time weather information
- Fishing spots tracking
- Profile management
- Multi-platform support (iOS, Android, Web)

## Project Structure
```plaintext
pescapp/
├── android/             # Android-specific files
├── ios/                 # iOS-specific files
├── lib/                 # Dart source code
│   ├── screens/         # UI screens
│   ├── services/        # Business logic and API services
│   ├── widgets/         # Reusable UI components
│   ├── firebase_options.dart
│   └── main.dart        # Application entry point
├── web/                 # Web-specific files
├── scripts/             # Build and deployment scripts
└── test/                # Test files
```

## Prerequisites
- Flutter SDK (^3.6.1)
- Dart SDK (^3.0.0)
- Android Studio / Xcode
- Firebase account
- Google Maps API key
- OpenWeather API key

## Environment Setup

1. Create a `.env` file in the project root:
   ```plaintext
   GOOGLE_MAPS_API_KEY=your_google_maps_api_key
   WEATHER_API_KEY=your_openweather_api_key
   ```

2. Create `web/environment.js`:
   ```javascript
   window.env = {
       "GOOGLE_MAPS_API_KEY": "%GOOGLE_MAPS_API_KEY%"
   };
   ```

3. Update your Firebase configuration:
   - Replace the Firebase configuration in `lib/firebase_options.dart`
   - Update `google-services.json` for Android
   - Update `GoogleService-Info.plist` for iOS

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/pescapp.git
   cd pescapp
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the environment setup script:
   ```bash
   chmod +x scripts/run-local.sh
   ./scripts/run-local.sh
   ```

## Running the App

### Development
```bash
flutter run
```

### Web
```bash
flutter run -d chrome
```

### Production Build
```bash
flutter build apk  # Android
flutter build ios  # iOS
flutter build web  # Web
```

## API Keys

### Required API Keys:
1. **Google Maps API Key**
   - Create a project in Google Cloud Console
   - Enable Maps SDK for Android, iOS, and JavaScript
   - Place the key in:
     - `.env` file
     - Android Manifest
     - iOS configuration

2. **OpenWeather API Key**
   - Sign up at OpenWeather
   - Place the key in `.env` file

3. **Firebase Configuration**
   - Create a Firebase project
   - Add applications (Android, iOS, Web)
   - Download and replace configuration files

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Security Notes
- Never commit API keys or sensitive information
- Use environment variables for sensitive data
- Keep Firebase configuration secure
- Update dependencies regularly

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
