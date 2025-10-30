🛡️ Smart Baby Guard
Smart Baby Guard is a Flutter companion app for the SmartBabyGuard ESP32 firmware. It connects over Bluetooth Classic to stream temperature and distance data, trigger audible/visual/vibration alerts, and store historical readings locally.

Project Description
The Smart Baby Guard system keeps infants safe by combining embedded sensing and mobile monitoring.
It integrates:
• A temperature sensor (DS18B20) for heat detection
• An ultrasonic sensor (HC-SR04) for proximity alerts
• Bluetooth Classic connectivity via the SmartBabyGuard device

Whenever the ESP32 reports dangerous temperature or close distance values, the app raises alarms (sound, vibration, flashlight, and on-screen warnings) and logs data locally for review.

System Overview
Component Technology / Hardware
Framework Flutter 3.x (Dart 3.x)
Language Kotlin / Dart
Board ESP32-WROOM
Sensors DS18B20 · HC-SR04
Connectivity Bluetooth Classic
Database Local storage (Hive)
UI Theme Material 3 Dynamic (Light / Dark / System Auto)
Min SDK 23
Target SDK 35
Build Tools Gradle 8.7.2
Java Runtime JDK 21+

Features
• ESP32 Bluetooth connection with auto-reconnect
• Live dashboard showing temperature and distance
• Alert banner + sound, flash, and vibration toggles
• Local history powered by Hive
• Material 3 light/dark/system themes
• Custom Smart Baby Guard launcher icon

Installation & Setup
1️⃣ Clone the Repository:
https://github.com/jonakatin/smart_baby_guardian.git

2️⃣ Configure Flutter SDK:
flutter config --flutter-root "C:\src\flutter"
or add flutter.sdk path in android/local.properties

3️⃣ Verify Environment:
flutter doctor -v

4️⃣ Fetch Dependencies:
flutter pub get

5️⃣ Build the App:
flutter clean
flutter build apk --release

6️⃣ Run on Device (Debug):
flutter run

Team Members — Makerere University CoCIS BSSE 3 (Group 28)
Wambui Mariam 23/U/###94/PS UI Design
Johnson Makmot Kabira 23/U/###94/EVE IoT Integration
Mwesigwa Isaac 23/U/###39/PS Firmware & Testing
Bataringaya Bridget 23/U/###71/EVE Documentation & QA
Jonathan Katongole 23/U/###72/EVE App Engineer

Supervisor
Dr. Mary Nsabagwa

License
This project is distributed for academic and educational purposes under the MIT License.
