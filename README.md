# Smart IV Drip Monitor - Mobile Application (Flutter)

A production-quality, medical-grade Flutter mobile application designed for hospital nurses to monitor live fluid infusion telemetry and configure ESP32 Smart IV Drip Monitor hardware over Bluetooth Low Energy (BLE).

---

## Key Features & UX Highlights

* **Nurse-First Interface**: Designed with large touch targets (minimum 56px button heights), high-contrast typography, and hospital-clean white card layouts with Electric Orange and Light Green accents.
* **Context-Aware Infusion Session Alarm**: Monitoring sessions activate automatically after observing continuous `FLOWING` telemetry for 60 seconds. Once active, receiving a `FLOW_STOPPED` status triggers phone vibration, local notifications, and a prominent red warning card on the Dashboard.
* **Single Source of Truth BLE Integration**: Communicates using the exact GATT service and characteristic UUIDs specified in the firmware documentation via `flutter_blue_plus`.
* **Dynamic Connection Banners**: Provides friendly progress messages during discovery (`Searching for Smart IV Monitor...`, `Connecting...`, `Synchronizing...`) and auto-reconnects if disconnected.
* **Network Provisioning**: Allows nurses to update WiFi SSID and WPA2 passwords into ESP32 NVS via BLE and receive live connection results (`Connected Successfully` / `Connection Failed`).
* **Subtle Branding**: Features an understated `"Powered by Imaxeuno"` footer on the Settings page.

---

## Directory Layout

```text
smart_iv_monitor_app/
├── android/                   # Android build files with BLE & Location permissions
├── ios/                       # iOS build files with Bluetooth privacy keys
├── lib/
│   ├── main.dart              # App entry point & MultiProvider initialization
│   ├── core/
│   │   ├── constants/         # BLE UUIDs & Brand colors
│   │   └── theme/             # Material 3 Light Theme setup
│   ├── data/
│   │   ├── models/            # Telemetry & Device metadata models
│   │   └── ble/               # flutter_blue_plus GATT service wrapper
│   ├── providers/             # BleProvider, TelemetryProvider, WifiSetupProvider
│   └── presentation/
│       ├── screens/           # Dashboard, Device, WiFi, and Settings screens
│       └── widgets/           # CustomCard, StatusPill, SignalIndicator, AlarmBanner
└── pubspec.yaml               # Dependencies
```

---

## How to Build and Run

### Prerequisites
1. Installed [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.0.0 or higher).
2. Android Studio or VS Code with Flutter extensions.
3. Physical Android device or iOS device (BLE operations require physical hardware; emulators do not support Bluetooth scanning).

### Execution Steps
1. Navigate to the project directory:
   ```bash
   cd smart_iv_monitor_app
   ```
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application on a connected mobile device:
   ```bash
   flutter run
   ```
4. Build release APK for Android:
   ```bash
   flutter build apk --release
   ```
