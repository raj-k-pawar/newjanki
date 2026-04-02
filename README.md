# 🌿 Janki Agro Tourism - Flutter App

A complete management app for Janki Agro Tourism built with Flutter.

## 📱 Features

### Authentication
- Multi-role login: **Manager**, **Owner**, **Admin**, **Canteen**
- Register new accounts with role selection
- Session persistence (stays logged in)
- Demo credentials included on login screen

### Manager Dashboard
- ✅ Today's Overview stats (Bookings, Guests, Revenue, Cash, Online)
- ✅ Add New Customer (full booking form)
- ✅ View All Customers (with search & filter)
- ✅ Manage Workers (attendance tracking, add workers)

### All Roles Supported
- Manager, Owner, Admin, Canteen each have their own dashboard
- Role-based navigation

---

## 🚀 Setup Instructions

### Prerequisites
- Flutter SDK 3.0.0 or higher
- Dart SDK 3.0.0 or higher
- Android Studio / VS Code
- Xcode (for iOS)

### 1. Install Flutter
```bash
# Follow https://flutter.dev/docs/get-started/install
flutter --version
```

### 2. Get Dependencies
```bash
cd janki_agro_tourism
flutter pub get
```

### 3. Run on Android
```bash
flutter run
```

### 4. Run on iOS
```bash
cd ios && pod install && cd ..
flutter run
```

### 5. Build APK (Release)
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# Split by ABI (smaller files)
flutter build apk --release --split-per-abi
```

### 6. Build AAB (for Play Store)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### 7. Build iOS IPA
```bash
flutter build ipa --release
```

---

## 🏗️ Codemagic Build

1. Push this code to GitHub/GitLab/Bitbucket
2. Login to [codemagic.io](https://codemagic.io)
3. Connect your repository
4. The `codemagic.yaml` file is already configured
5. For Android: Add keystore in Codemagic settings → Code signing
6. For iOS: Add certificates/profiles in Codemagic settings
7. Start build → get APK/IPA by email

---

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/
│   ├── user_model.dart          # User & roles
│   └── booking_model.dart       # Customer, Booking, Worker models
├── services/
│   ├── auth_service.dart        # Login/Register/Session
│   └── data_service.dart        # Customers/Workers CRUD
├── utils/
│   └── app_theme.dart           # Colors, Fonts, Theme
└── screens/
    ├── splash_screen.dart       # Animated splash
    ├── auth/
    │   ├── login_screen.dart    # Login UI
    │   └── register_screen.dart # Register UI
    ├── manager/
    │   ├── manager_dashboard.dart    # Main dashboard
    │   ├── add_customer_screen.dart  # New booking form
    │   ├── all_customers_screen.dart # Customer list
    │   └── manage_workers_screen.dart # Staff management
    ├── owner/
    │   └── owner_dashboard.dart  # Owner + Admin + Canteen dashboards
    ├── admin/
    │   └── admin_dashboard.dart
    └── canteen/
        └── canteen_dashboard.dart
```

---

## 🔑 Demo Login Credentials

| Role    | Username  | Password   |
|---------|-----------|------------|
| Manager | manager1  | manager123 |
| Owner   | owner1    | owner123   |
| Admin   | admin1    | admin123   |
| Canteen | canteen1  | canteen123 |

---

## 🎨 Design

- **Color**: Deep Forest Green (`#2D6A4F`) + Warm Amber accent
- **Font**: Playfair Display (headings) + Poppins (body)
- **Style**: Nature-inspired, clean cards, gradient headers
- **Platform**: Android & iOS

---

## 📦 Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| google_fonts | ^6.1.0 | Poppins + Playfair Display |
| shared_preferences | ^2.2.2 | Local data persistence |
| intl | ^0.19.0 | Date/currency formatting |
| provider | ^6.1.1 | State management |
| fl_chart | ^0.66.2 | Charts |
| fluttertoast | ^8.2.4 | Toast messages |

---

## 🔧 Extending the App

### Connect to a real backend:
- Replace mock data in `auth_service.dart` with actual API calls
- Replace `data_service.dart` CRUD with REST API or Firebase

### Add Firebase:
```bash
flutter pub add firebase_core firebase_auth cloud_firestore
flutterfire configure
```

---

Built with ❤️ for Janki Agro Tourism
