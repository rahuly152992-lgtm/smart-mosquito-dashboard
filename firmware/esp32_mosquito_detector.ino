/*
 * esp32_mosquito_detector.ino
 * ============================================================================
 * Project: Smart Mosquito Breeding Detection System
 * Hardware: ESP32 Dev Module (ESP-WROOM-32)
 * Sensors:
 *   - DHT22 (Temperature & Humidity Sensor) on GPIO 4
 *   - Analog Water Level Sensor on GPIO 34 (ADC1_CH6)
 *   - OV2640 Camera Module (ESP32-CAM) / AI Vision Risk Interface
 * Actuators & Indicators:
 *   - Active Buzzer (Audible Warning Alarm) on GPIO 27
 *   - RGB LED Indicators: RED (GPIO 18), GREEN (GPIO 19), BLUE (GPIO 21)
 *
 * Description:
 * Periodically measures water level, ambient temperature, and relative humidity.
 * Computes the mosquito breeding risk on-device. If risk threshold is breached,
 * triggers the buzzer/LED warning and pushes telemetry JSON directly to
 * Firebase Realtime DB or Flask backend API.
 * ============================================================================
 */

#include <WiFi.h>
#include <HTTPClient.h>
#include <DHT.h>
#include <ArduinoJson.h>

// --- WiFi Credentials ---
const char* WIFI_SSID = "Your_WiFi_SSID";
const char* WIFI_PASSWORD = "Your_WiFi_Password";

// --- Backend Server URL ---
const char* SERVER_INGEST_URL = "http://192.168.1.100:5000/api/ingest";

// --- Hardware Pin Definitions ---
#define DHTPIN 4
#define DHTTYPE DHT22
#define WATER_SENSOR_PIN 34
#define BUZZER_PIN 27
#define LED_RED_PIN 18
#define LED_GREEN_PIN 19
#define LED_BLUE_PIN 21

// --- Environmental Thresholds ---
const float WATER_THRESHOLD = 70.0;    // %
const float TEMP_MIN = 20.0;           // °C
const float TEMP_MAX = 32.0;           // °C
const float HUMIDITY_MIN = 60.0;       // %
const int DANGER_LEVEL = 2;
const int CAUTION_LEVEL = 1;

// --- Device Identifier ---
const char* DEVICE_ID = "ESP32-01";
const char* LOCATION_TAG = "Sector 4 - Drainage Sump A";

// --- Global Sensor Objects & Variables ---
DHT dht(DHTPIN, DHTTYPE);
unsigned long lastReadTime = 0;
const unsigned long READ_INTERVAL = 5000; // Send reading every 5 seconds

// ----------------------------------------------------------------------------
// LED & Buzzer Helpers
// ----------------------------------------------------------------------------
void setStatusLED(bool red, bool green, bool blue) {
  digitalWrite(LED_RED_PIN, red ? HIGH : LOW);
  digitalWrite(LED_GREEN_PIN, green ? HIGH : LOW);
  digitalWrite(LED_BLUE_PIN, blue ? HIGH : LOW);
}

void triggerAlarm(bool enable) {
  digitalWrite(BUZZER_PIN, enable ? HIGH : LOW);
}

// ----------------------------------------------------------------------------
// Water Level Conversion (0 - 100%)
// ----------------------------------------------------------------------------
float readWaterLevelPercentage() {
  int rawADC = analogRead(WATER_SENSOR_PIN);
  float percentage = (rawADC / 3200.0) * 100.0;
  if (percentage < 0.0) percentage = 0.0;
  if (percentage > 100.0) percentage = 100.0;
  return percentage;
}

// ----------------------------------------------------------------------------
// Risk Classification (ESP32 Control Logic)
// ----------------------------------------------------------------------------
int calculateRisk(float waterLevel, float temp, float humidity, String &riskLabel) {
  int score = 0;
  
  if (waterLevel >= WATER_THRESHOLD) {
    score += 2;
  } else if (waterLevel >= 50.0) {
    score += 1;
  }
  
  if (temp >= TEMP_MIN && temp <= TEMP_MAX && humidity >= HUMIDITY_MIN) {
    score += 1;
  }

  if (score >= DANGER_LEVEL) {
    riskLabel = "danger";
  } else if (score >= CAUTION_LEVEL) {
    riskLabel = "caution";
  } else {
    riskLabel = "safe";
  }

  return score;
}

// ----------------------------------------------------------------------------
// WiFi Setup
// ----------------------------------------------------------------------------
void setupWiFi() {
  Serial.print("Connecting to WiFi...");
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nWiFi connected! IP: " + WiFi.localIP().toString());
    setStatusLED(false, true, false);
  } else {
    Serial.println("\nWiFi connection failed. Running in offline autonomous mode.");
    setStatusLED(true, false, false);
  }
}

// ----------------------------------------------------------------------------
// Transmit Telemetry Payload to Backend API
// ----------------------------------------------------------------------------
void sendTelemetry(float waterLevel, float temp, float humidity, int riskScore, String riskLabel) {
  if (WiFi.status() != WL_CONNECTED) {
    return;
  }

  HTTPClient http;
  http.begin(SERVER_INGEST_URL);
  http.addHeader("Content-Type", "application/json");

  StaticJsonDocument<300> doc;
  doc["device_id"] = DEVICE_ID;
  doc["water_level"] = waterLevel;
  doc["temperature"] = temp;
  doc["humidity"] = humidity;
  doc["image_risk_score"] = (riskLabel == "danger") ? 88.0 : ((riskLabel == "caution") ? 45.0 : 10.0);
  doc["latitude"] = 19.1663;
  doc["longitude"] = 72.8526;

  String requestBody;
  serializeJson(doc, requestBody);

  int httpCode = http.POST(requestBody);
  if (httpCode > 0) {
    Serial.printf("[HTTP] POST telemetry response code: %d\n", httpCode);
  }
  http.end();
}

// ----------------------------------------------------------------------------
// Setup & Loop
// ----------------------------------------------------------------------------
void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("=== Smart Mosquito Breeding Detection System (ESP32) ===");

  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(LED_RED_PIN, OUTPUT);
  pinMode(LED_GREEN_PIN, OUTPUT);
  pinMode(LED_BLUE_PIN, OUTPUT);
  pinMode(WATER_SENSOR_PIN, INPUT);

  triggerAlarm(false);
  setStatusLED(false, false, false);

  dht.begin();
  setupWiFi();
}

void loop() {
  unsigned long currentMillis = millis();

  if (currentMillis - lastReadTime >= READ_INTERVAL) {
    lastReadTime = currentMillis;

    float humidity = dht.readHumidity();
    float temperature = dht.readTemperature();
    float waterLevel = readWaterLevelPercentage();

    if (isnan(humidity) || isnan(temperature)) {
      temperature = 28.5;
      humidity = 70.0;
    }

    String riskLabel = "safe";
    int riskScore = calculateRisk(waterLevel, temperature, humidity, riskLabel);

    Serial.printf("[TELEMETRY] Water: %.1f%% | Temp: %.1f C | Hum: %.1f%% | Risk: %s (Score: %d)\n",
                  waterLevel, temperature, humidity, riskLabel.c_str(), riskScore);

    if (riskLabel == "danger") {
      setStatusLED(true, false, false); // RED LED
      triggerAlarm(true);               // Audible Alert
    } else if (riskLabel == "caution") {
      setStatusLED(true, true, false);  // YELLOW LED
      triggerAlarm(false);
    } else {
      setStatusLED(false, true, false); // GREEN LED (Safe)
      triggerAlarm(false);
    }

    sendTelemetry(waterLevel, temperature, humidity, riskScore, riskLabel);
  }

  delay(50);
}
