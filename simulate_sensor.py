"""
simulate_sensor.py
-------------------
IoT ESP32 Device Simulator for the Smart Mosquito Breeding Detection System.
Generates realistic water-level, temperature, and humidity telemetry and POSTs
them to the Flask ingest endpoint (/api/ingest) or Firebase Realtime Database.
"""

import argparse
import random
import sys
import time
from datetime import datetime

import requests

try:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

BASE_LAT = 19.1663
BASE_LON = 72.8526


def generate_reading(scenario="normal"):
    """
    Generates realistic sensor data based on requested scenario.
    """
    if scenario == "danger":
        water_level = random.uniform(75.0, 92.0)
        temperature = random.uniform(27.0, 31.5)
        humidity = random.uniform(70.0, 88.0)
        image_risk = random.uniform(80.0, 95.0)
    elif scenario == "caution":
        water_level = random.uniform(52.0, 68.0)
        temperature = random.uniform(25.0, 30.0)
        humidity = random.uniform(62.0, 78.0)
        image_risk = random.uniform(40.0, 58.0)
    elif scenario == "safe":
        water_level = random.uniform(10.0, 35.0)
        temperature = random.uniform(18.0, 24.0)
        humidity = random.uniform(35.0, 55.0)
        image_risk = random.uniform(0.0, 15.0)
    else:  # normal stochastic fluctuations
        roll = random.random()
        if roll < 0.35:
            return generate_reading("danger")
        elif roll < 0.65:
            return generate_reading("caution")
        else:
            return generate_reading("safe")

    return {
        "device_id": "ESP32-01",
        "water_level": round(water_level, 1),
        "temperature": round(temperature, 1),
        "humidity": round(humidity, 1),
        "image_risk_score": round(image_risk, 1),
        "latitude": round(BASE_LAT + random.uniform(-0.001, 0.001), 6),
        "longitude": round(BASE_LON + random.uniform(-0.001, 0.001), 6),
    }


def main():
    parser = argparse.ArgumentParser(description="ESP32 IoT Sensor Simulator for Mosquito Detection")
    parser.add_argument("--url", default="http://127.0.0.1:5000/api/ingest", help="Backend ingest API URL")
    parser.add_argument("--interval", type=float, default=4.0, help="Seconds between readings")
    parser.add_argument("--scenario", choices=["normal", "danger", "caution", "safe"], default="normal", help="Simulation mode")
    parser.add_argument("--count", type=int, default=0, help="Total readings to send (0 = infinite)")
    args = parser.parse_args()

    print("=" * 65)
    print("[SIMULATOR] Smart Mosquito Breeding Detection System - ESP32 Node")
    print("=" * 65)
    print(f" Target Endpoint: {args.url}")
    print(f" Transmit Rate  : Every {args.interval}s")
    print(f" Scenario Mode  : {args.scenario.upper()}")
    print(" Press Ctrl+C to stop simulation.")
    print("-" * 65)

    sent = 0
    try:
        while True:
            payload = generate_reading(args.scenario)
            try:
                resp = requests.post(args.url, json=payload, timeout=4)
                if resp.status_code in (200, 201):
                    res_data = resp.json()
                    risk_label = res_data.get("RiskLabel", "unknown").upper()
                    pump_status = "PUMP: ON [DRAINING]" if res_data.get("PumpStatus") else "PUMP: OFF"
                    print(f"[{datetime.now().strftime('%H:%M:%S')}] Sent -> Water: {payload['water_level']}% | Temp: {payload['temperature']}C | Hum: {payload['humidity']}% | Risk: {risk_label} | {pump_status}")
                else:
                    print(f"[{datetime.now().strftime('%H:%M:%S')}] Server returned status {resp.status_code}: {resp.text}")
            except requests.RequestException as e:
                print(f"[{datetime.now().strftime('%H:%M:%S')}] Connection Error: {e}")

            sent += 1
            if args.count and sent >= args.count:
                break
            time.sleep(args.interval)

    except KeyboardInterrupt:
        print("\nSimulator stopped.")


if __name__ == "__main__":
    main()
