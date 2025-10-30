🛡️ Smart Guardian
Smart Guardian is an Android IoT companion app built with Flutter and Kotlin. It connects to an ESP32 microcontroller over Bluetooth to monitor safety conditions detecting dangerous temperature, proximity, or fire-related anomalies and alerting users instantly.

Project Description
The Smart Guardian system enhances laboratory safety by combining embedded sensing and mobile monitoring.
It integrates:
• A temperature sensor (DS18B20) for heat detection
• An ultrasonic sensor (HC-SR04) for proximity alerts
• Optional tilt or vibration sensor for movement detection

Whenever an unsafe event occurs like extreme heat, close proximity, or a possible fall the app triggers alerts (sound, vibration, flashlight, and on-screen warnings) and logs data locally for review.

System Overview
Component Technology / Hardware
Framework Flutter 3.35.6 (Dart 3.9.2)
Language Kotlin / Dart
Board ESP32-WROOM
Sensors DS18B20 · HC-SR04 · (optional Tilt sensor)
Connectivity Bluetooth Classic
Database Local storage (Hive / SharedPreferences)
UI Theme Material 3 Dynamic (Light / Dark / System Auto)
Min SDK 23
Target SDK 35
Build Tools Gradle 8.12
Java Runtime JDK 21.0.8 (Eclipse Adoptium Temurin)

Features
• ESP32 Bluetooth connection
• Live sensor dashboard with charts
• Local data logging (offline ready)
• Smart alerts (sound · flash · vibration)
• Adaptive Material 3 themes
• Auto-reconnect & persistent pairing
• Historical readings & export options

Installation & Setup
1️⃣ Clone the Repository:
git clone https://github.com/<your-username>/smart_guardian.git
cd smart_guardian

2️⃣ Configure Flutter SDK:
flutter config --flutter-root "C:\src\flutter"
or add flutter.sdk path in android/local.properties

3️⃣ Verify Environment:
flutter doctor -v

4️⃣ Fetch Dependencies:
flutter pub get

5️⃣ Install Android SDK 35 (if missing):
sdkmanager "platforms; android-35"

6️⃣ Build the App:
flutter clean
flutter build apk –release
Output: build/app/outputs/flutter-apk/app-release.apk

7️⃣ Run on Device (Debug):
flutter run

Team Members — Makerere University CoCIS BSSE 3(Group 28)
Name Registration Number Role
Wambui Mariam 23/U/###94/PS Project Coordinator / QA
Johnson Makmot Kabira 23/U/###94/EVE Embedded Systems Engineer
Mwesigwa Isaac 23/U/###39/PS Mobile App Developer
Bataringaya Bridget 23/U/###71/EVE Hardware Integration Lead
Jonathan Katongole 23/U/###72/EVE Flutter Developer

Supervisor
Dr. Mary Nsabagwa
License
This project is distributed for academic and educational purposes under the MIT License.
