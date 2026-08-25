# Smart Mosquito Breeding Detection System 🦟💧

An IoT-based real-time surveillance and early alert mobile web application connected to an ESP32 hardware device with Water Level Sensor, DHT22 Temperature & Humidity Sensor, AI Camera Vision detection, Local Buzzer/LED Warning, and a Relay-Controlled Drainage Pump.

---

## 📁 Project Architecture & File Locations

```
mosquito_dashboard_app/
└── mosquito_dashboard/
    ├── 📄 app.py                          # [BACKEND] Flask REST API server with real-time routing & telemetry
    ├── 📄 config.py                       # [BACKEND] Environmental thresholds, Firebase settings & paths
    ├── 📄 data_store.py                   # [DATA STORE] Storage engine (Local JSON + Firebase Realtime DB sync)
    ├── 📄 simulate_sensor.py              # [SIMULATOR] Python CLI tool simulating live ESP32 sensor telemetry
    ├── 📄 requirements.txt                # Python dependencies (Flask, requests, python-dotenv)
    ├── 📄 .env.example                    # Environment variables template (Firebase credentials)
    ├── 📂 firmware/
    │   └── 📄 esp32_mosquito_detector.ino # [HARDWARE FIRMWARE] Complete ESP32 Arduino C++ source code
    ├── 📂 data/
    │   ├── 📄 records.json                # Telemetry history database
    │   ├── 📄 alerts.json                 # Active and resolved alerts database
    │   └── 📄 device.json                 # ESP32 device state, pump mode & pinout config
    ├── 📂 static/
    │   ├── 📂 css/
    │   │   ├── 📄 style.css               # [FRONTEND] Modern UI design system, color tokens, dark mode
    │   │   └── 📄 mobile_frame.css        # [FRONTEND] Smartphone mockup frame & responsive layout switch
    │   ├── 📂 js/
    │   │   ├── 📄 app.js                  # [FRONTEND] Main SPA controller, navigation, modal & action handlers
    │   │   ├── 📄 api.js                  # [FRONTEND] REST client library connecting frontend to backend
    │   │   ├── 📄 charts.js               # [FRONTEND] Chart.js real-time telemetry stream & history charts
    │   │   └── 📄 audio.js                # [FRONTEND] Web Audio API hardware buzzer & chime synthesizer
    │   └── 📂 images/
    │       ├── 📄 logo.svg                # Mosquito shield logo with crosshairs
    │       ├── 📄 larvae_sample.svg       # AI Computer Vision larvae detection evidence
    │       └── 📄 water_tank_sample.svg   # Water tank & sensor illustration
    └── 📂 templates/
        └── 📄 index.html                  # [FRONTEND] Main Single Page Mobile App containing all 10 screens
```

---

## 🚀 How to Run the Application

### 1. Start the Flask Backend Server
Open a terminal in the `mosquito_dashboard` directory:

```bash
cd c:\Users\alok1\OneDrive\Desktop\mosquito_dashboard_app\mosquito_dashboard
python app.py
```
Server runs locally at: **`http://127.0.0.1:5000`**

### 2. Open the Mobile Web App
Open any browser (Chrome, Edge, Safari, Mobile Browser) and navigate to:
👉 **`http://127.0.0.1:5000`**

- **Phone Frame / Full Screen**: Click the toggle at the top to switch between the sleek iPhone presentation frame and full-screen desktop view.
- **One-Click Demo Roles**: On the Login screen, click **Field Officer**, **Administrator**, or **Student Demo** for instant access.

### 3. Run the Live ESP32 Sensor Simulator (Optional Demo)
To simulate live sensor streaming from another terminal:

```bash
python simulate_sensor.py
```
Options:
- `python simulate_sensor.py --scenario danger` (Simulate High Risk breeding conditions)
- `python simulate_sensor.py --scenario caution` (Simulate Caution conditions)
- `python simulate_sensor.py --scenario safe` (Simulate Safe conditions)
- `python simulate_sensor.py --interval 2` (Send reading every 2 seconds)

---

## 📱 Features & Implemented Screens

1. **Splash Screen**: App logo, app name (*Smart Mosquito Breeding Detection*), tagline (*"Detect Early. Alert Fast. Prevent Disease."*), and auto-transition.
2. **Login Screen**: Email/Password authentication, remember me, forgot password, and one-click demo role switcher.
3. **Home Dashboard**:
   - Status card (🟢 Safe Area / 🟡 Caution / 🔴 Breeding Risk Detected) with pulsing danger animations.
   - Live Sensor Cards: Water Level (78%), Temperature (29°C), Humidity (76%), Image Risk Score (88%).
   - Total Alerts Today, Active Risk Alerts, Resolved Alerts, ESP32 Connection Status.
   - Quick Actions (Pump control, Alarm buzzer test, Prevention tips).
4. **Live Monitoring Screen**:
   - Real-time gauge telemetry and live auto-updating Chart.js line graph.
   - ESP32-CAM AI Larvae Detection live stream visualization with bounding boxes.
   - Hardware GPIO pin diagnostics table (GPIO 4 DHT22, GPIO 34 Water ADC, GPIO 26 Relay, GPIO 27 Buzzer).
5. **Alerts Screen**:
   - Urgent banner: *"⚠️ Mosquito Breeding Risk Detected! Immediate action required."*
   - Filter chips (All Alerts / Active Risks / Resolved).
   - Alert list with timestamp, location, sensor values, and action buttons.
6. **Alert Details Screen (Modal)**:
   - Deep sensor telemetry analysis, risk diagnosis, camera evidence preview.
   - Buttons: **Mark as Cleaned**, **Mark as Resolved**, and **Report Action Taken** (with field log history).
7. **Device Control Screen**:
   - Connected ESP32 telemetry (Battery 94%, WiFi RSSI -62 dBm, Firmware version).
   - Submersible Drainage Pump Relay controller with **Automatic Mode** vs **Manual Mode**.
   - Safety Confirmation Warning Modal before activating pump manually.
   - Hardware buzzer and LED diagnostic test buttons.
8. **History and Reports Screen**:
   - Time filters: Today, Last 7 Days, Last 30 Days, All.
   - Historical analytics bar charts and risk distribution donut chart.
   - **Download CSV Report** and **Print/PDF Export** functions.
9. **Prevention Tips Screen**:
   - 7 Preventive guidelines (Stagnant water, Containers, Covered tanks, Drains, Tyres/plastic, Coolers, Action protocol).
   - Vector Disease guide (Dengue, Malaria, Chikungunya, Zika).
   - Interactive 5-Minute Weekly Prevention Checklist with progress bar.
10. **Profile and Settings Screen**:
    - User details with role switcher (Field Officer / Administrator / Student Researcher).
    - Dark Mode toggle, Sound effects toggle, and Push notification preferences.
    - IoT Scenario Injections (Danger, Caution, Safe, Reset) for viva demonstrations.

---

## 🔌 Hardware Setup (ESP32)

Upload `firmware/esp32_mosquito_detector.ino` using the Arduino IDE to an ESP32 Dev Board.
- **DHT22**: GPIO 4
- **Water Level Sensor (Analog ADC)**: GPIO 34
- **Relay Module (Drainage Pump)**: GPIO 26
- **Active Buzzer**: GPIO 27
- **RGB Status LEDs**: RED (GPIO 18), GREEN (GPIO 19), BLUE (GPIO 21)
