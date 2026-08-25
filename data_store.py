"""
data_store.py
-------------
Handles storing, retrieving, and analyzing sensor records, alerts, and ESP32
device states for the Smart Mosquito Breeding Detection System.

Supports:
1. Firebase Realtime Database (when FIREBASE_DB_URL is set in config / .env)
2. Local JSON files (data/records.json, data/alerts.json, data/device.json) with auto-seeding.
"""

import json
import os
import time
import uuid
from datetime import datetime, timedelta

import requests
import config

USING_FIREBASE = bool(config.FIREBASE_DB_URL)

# -----------------------------------------------------------------------------
# File Helpers & Safety
# -----------------------------------------------------------------------------
def _ensure_file(file_path, default_content):
    os.makedirs(os.path.dirname(file_path), exist_ok=True)
    if not os.path.exists(file_path) or os.path.getsize(file_path) == 0:
        with open(file_path, "w", encoding="utf-8") as f:
            json.dump(default_content, f, indent=2)


def _read_json(file_path, default_content):
    _ensure_file(file_path, default_content)
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return default_content


def _write_json(file_path, data):
    _ensure_file(file_path, [])
    with open(file_path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)


# -----------------------------------------------------------------------------
# Risk Classification Engine (Matches ESP32 Algorithm)
# -----------------------------------------------------------------------------
def classify_risk(water_level, temperature, humidity, image_risk_score=0.0):
    """
    Computes breeding risk score and status.
    - Water Level >= Threshold (+2)
    - Temp in favorable range (20°C - 32°C) AND Humidity >= Threshold (+1)
    - Image / Camera AI Detection >= Threshold (+1)
    """
    score = 0
    reasons = []

    if water_level >= config.WATER_THRESHOLD:
        score += 2
        reasons.append(f"Stagnant water level ({water_level}%) exceeds safety limit ({config.WATER_THRESHOLD}%)")
    elif water_level >= 50.0:
        score += 1
        reasons.append(f"Water accumulation ({water_level}%) approaching caution limit")

    if config.TEMP_MIN <= temperature <= config.TEMP_MAX and humidity >= config.HUMIDITY_MIN:
        score += 1
        reasons.append(f"Favorable climate: Temp {temperature}°C (opt: {config.TEMP_MIN}-{config.TEMP_MAX}°C) & Humidity {humidity}% (min: {config.HUMIDITY_MIN}%)")
    elif humidity >= config.HUMIDITY_MIN:
        reasons.append(f"High atmospheric humidity ({humidity}%)")

    if image_risk_score >= config.IMAGE_RISK_THRESHOLD:
        score += 1
        reasons.append(f"AI Vision detected mosquito larvae / pupae (Confidence: {image_risk_score}%)")

    if score >= config.DANGER_LEVEL:
        label = "danger"  # 🔴 BREEDING RISK DETECTED
    elif score >= config.CAUTION_LEVEL:
        label = "caution"  # 🟡 CAUTION – CHECK WATER CONDITIONS
    else:
        label = "safe"     # 🟢 SAFE AREA

    return score, label, reasons


# -----------------------------------------------------------------------------
# Device & Hardware Diagnostics State
# -----------------------------------------------------------------------------
DEFAULT_DEVICE_STATE = {
    "device_id": config.DEFAULT_DEVICE_ID,
    "device_name": config.DEFAULT_DEVICE_NAME,
    "location": config.DEFAULT_LOCATION,
    "latitude": config.DEFAULT_LATITUDE,
    "longitude": config.DEFAULT_LONGITUDE,
    "status": "connected",
    "battery_level": 94,
    "power_source": "Solar + USB-C 5V",
    "wifi_rssi": -62,
    "buzzer_state": "ACTIVE",  # "ACTIVE" or "OFF"
    "led_state": "RED",       # "GREEN", "YELLOW", "RED"
    "last_sync": datetime.now().isoformat(),
    "firmware_version": "v2.4-ESP32-AI",
}


def get_device_status():
    if USING_FIREBASE:
        try:
            url = f"{config.FIREBASE_DB_URL}/device/{config.DEFAULT_DEVICE_ID}.json"
            params = {"auth": config.FIREBASE_AUTH} if config.FIREBASE_AUTH else {}
            resp = requests.get(url, params=params, timeout=5)
            if resp.ok and resp.json():
                return resp.json()
        except Exception:
            pass
    return _read_json(config.LOCAL_DEVICE_FILE, DEFAULT_DEVICE_STATE)


def update_device_status(updates):
    current = get_device_status()
    current.update(updates)
    current["last_sync"] = datetime.now().isoformat()

    if USING_FIREBASE:
        try:
            url = f"{config.FIREBASE_DB_URL}/device/{current.get('device_id', config.DEFAULT_DEVICE_ID)}.json"
            params = {"auth": config.FIREBASE_AUTH} if config.FIREBASE_AUTH else {}
            requests.put(url, params=params, json=current, timeout=5)
        except Exception:
            pass

    _write_json(config.LOCAL_DEVICE_FILE, current)
    return current


# -----------------------------------------------------------------------------
# Record Storage & Retrieval
# -----------------------------------------------------------------------------
def add_record(water_level, temperature, humidity, image_risk_score=None, latitude=None, longitude=None, device_id=None):
    if image_risk_score is None:
        image_risk_score = round(min(96.0, max(5.0, (water_level * 0.9) + (humidity * 0.15) - 10)), 1)

    score, label, reasons = classify_risk(water_level, temperature, humidity, image_risk_score)

    buzzer_state = "ACTIVE" if label == "danger" else "OFF"
    led_state = "RED" if label == "danger" else ("YELLOW" if label == "caution" else "GREEN")

    update_device_status({
        "buzzer_state": buzzer_state,
        "led_state": led_state,
        "last_sync": datetime.now().isoformat()
    })

    record_id = f"REC-{uuid.uuid4().hex[:8].upper()}"
    now_iso = datetime.now().isoformat()

    record = {
        "RecordID": record_id,
        "DeviceID": device_id or config.DEFAULT_DEVICE_ID,
        "WaterLevel": round(float(water_level), 1),
        "Temperature": round(float(temperature), 1),
        "Humidity": round(float(humidity), 1),
        "ImageRiskScore": round(float(image_risk_score), 1),
        "RiskScore": score,
        "RiskLabel": label,
        "AlertStatus": label in ("caution", "danger"),
        "BuzzerStatus": buzzer_state,
        "LedStatus": led_state,
        "Reasons": reasons,
        "Latitude": latitude or config.DEFAULT_LATITUDE,
        "Longitude": longitude or config.DEFAULT_LONGITUDE,
        "Timestamp": now_iso,
    }

    if label in ("danger", "caution"):
        _create_or_update_alert(record)

    if USING_FIREBASE:
        try:
            url = f"{config.FIREBASE_DB_URL}/sensor/{record_id}.json"
            params = {"auth": config.FIREBASE_AUTH} if config.FIREBASE_AUTH else {}
            requests.put(url, params=params, json=record, timeout=5)
        except Exception:
            pass

    records = _read_json(config.LOCAL_DATA_FILE, [])
    records.append(record)
    records = records[-config.MAX_LOCAL_RECORDS:]
    _write_json(config.LOCAL_DATA_FILE, records)

    return record


def get_all_records():
    records = _read_json(config.LOCAL_DATA_FILE, [])
    if not records:
        seed_initial_data()
        records = _read_json(config.LOCAL_DATA_FILE, [])
    return records


def get_latest_record():
    records = get_all_records()
    return records[-1] if records else None


def get_filtered_records(risk="all", time_range="all", limit=50):
    records = get_all_records()
    
    now = datetime.now()
    if time_range == "today":
        cutoff = now.replace(hour=0, minute=0, second=0, microsecond=0)
        records = [r for r in records if datetime.fromisoformat(r.get("Timestamp", now.isoformat())) >= cutoff]
    elif time_range == "7days":
        cutoff = now - timedelta(days=7)
        records = [r for r in records if datetime.fromisoformat(r.get("Timestamp", now.isoformat())) >= cutoff]
    elif time_range == "30days":
        cutoff = now - timedelta(days=30)
        records = [r for r in records if datetime.fromisoformat(r.get("Timestamp", now.isoformat())) >= cutoff]

    if risk and risk != "all":
        records = [r for r in records if r.get("RiskLabel") == risk]

    return list(reversed(records))[:limit]


# -----------------------------------------------------------------------------
# Alerts Engine
# -----------------------------------------------------------------------------
def _create_or_update_alert(record):
    alerts = _read_json(config.LOCAL_ALERTS_FILE, [])
    active_alerts = [a for a in alerts if a.get("status") == "active" and a.get("device_id") == record.get("DeviceID")]
    
    if active_alerts:
        alert = active_alerts[0]
        alert["water_level"] = record["WaterLevel"]
        alert["temperature"] = record["Temperature"]
        alert["humidity"] = record["Humidity"]
        alert["image_risk_score"] = record["ImageRiskScore"]
        alert["risk_level"] = record["RiskLabel"]
        alert["risk_score"] = record["RiskScore"]
        alert["last_updated"] = record["Timestamp"]
        alert["reasons"] = record["Reasons"]
    else:
        alert_id = f"ALT-{1080 + len(alerts) + 1}"
        new_alert = {
            "alert_id": alert_id,
            "title": "⚠️ Mosquito Breeding Risk Detected" if record["RiskLabel"] == "danger" else "🟡 Caution: Favourable Breeding Conditions",
            "device_id": record.get("DeviceID", config.DEFAULT_DEVICE_ID),
            "location": config.DEFAULT_LOCATION,
            "water_level": record["WaterLevel"],
            "temperature": record["Temperature"],
            "humidity": record["Humidity"],
            "image_risk_score": record["ImageRiskScore"],
            "risk_level": record["RiskLabel"],
            "risk_score": record["RiskScore"],
            "status": "active",
            "created_at": record["Timestamp"],
            "last_updated": record["Timestamp"],
            "reasons": record["Reasons"],
            "image_evidence": "/static/images/larvae_sample.svg",
            "is_cleaned": False,
            "actions_log": [
                {
                    "timestamp": record["Timestamp"],
                    "actor": "System Automation (ESP32)",
                    "action": "Alert triggered. Telemetry logged."
                }
            ],
            "resolved_at": None,
            "resolved_by": None
        }
        alerts.insert(0, new_alert)

    _write_json(config.LOCAL_ALERTS_FILE, alerts)


def get_alerts(status_filter="all"):
    alerts = _read_json(config.LOCAL_ALERTS_FILE, [])
    if not alerts:
        seed_initial_data()
        alerts = _read_json(config.LOCAL_ALERTS_FILE, [])
    if status_filter != "all":
        alerts = [a for a in alerts if a.get("status") == status_filter]
    return alerts


def get_alert_by_id(alert_id):
    alerts = get_alerts("all")
    for a in alerts:
        if a.get("alert_id") == alert_id:
            return a
    return None


def resolve_alert(alert_id, resolved_by="Field Officer", resolution_note="Area inspected and stagnant water cleared."):
    alerts = _read_json(config.LOCAL_ALERTS_FILE, [])
    found = False
    for a in alerts:
        if a.get("alert_id") == alert_id:
            a["status"] = "resolved"
            a["resolved_at"] = datetime.now().isoformat()
            a["resolved_by"] = resolved_by
            a["is_cleaned"] = True
            if "actions_log" not in a:
                a["actions_log"] = []
            a["actions_log"].append({
                "timestamp": datetime.now().isoformat(),
                "actor": resolved_by,
                "action": f"Marked as Resolved: {resolution_note}"
            })
            found = True
            break
    if found:
        _write_json(config.LOCAL_ALERTS_FILE, alerts)
    return found


def log_alert_action(alert_id, actor, action_note, mark_cleaned=False, mark_resolved=False):
    alerts = _read_json(config.LOCAL_ALERTS_FILE, [])
    updated_alert = None
    for a in alerts:
        if a.get("alert_id") == alert_id:
            if "actions_log" not in a:
                a["actions_log"] = []
            a["actions_log"].append({
                "timestamp": datetime.now().isoformat(),
                "actor": actor,
                "action": action_note
            })
            if mark_cleaned:
                a["is_cleaned"] = True
            if mark_resolved:
                a["status"] = "resolved"
                a["resolved_at"] = datetime.now().isoformat()
                a["resolved_by"] = actor
            updated_alert = a
            break
    if updated_alert:
        _write_json(config.LOCAL_ALERTS_FILE, alerts)
    return updated_alert


# -----------------------------------------------------------------------------
# Summary Statistics Engine
# -----------------------------------------------------------------------------
def get_system_stats():
    records = get_all_records()
    alerts = get_alerts("all")
    
    total_alerts = len(alerts)
    active_alerts = len([a for a in alerts if a.get("status") == "active"])
    resolved_alerts = len([a for a in alerts if a.get("status") == "resolved"])
    
    today_date = datetime.now().date()
    today_alerts = len([
        a for a in alerts 
        if datetime.fromisoformat(a.get("created_at", datetime.now().isoformat())).date() == today_date
    ])

    latest = get_latest_record()
    device = get_device_status()

    avg_water = round(sum(r["WaterLevel"] for r in records[-30:]) / max(1, len(records[-30:])), 1) if records else 0
    avg_temp = round(sum(r["Temperature"] for r in records[-30:]) / max(1, len(records[-30:])), 1) if records else 0
    avg_hum = round(sum(r["Humidity"] for r in records[-30:]) / max(1, len(records[-30:])), 1) if records else 0

    return {
        "total_alerts": total_alerts,
        "today_alerts": today_alerts,
        "active_alerts": active_alerts,
        "resolved_alerts": resolved_alerts,
        "device_connected": device.get("status") == "connected",
        "current_risk": latest.get("RiskLabel", "safe") if latest else "safe",
        "current_water": latest.get("WaterLevel", 0) if latest else 0,
        "current_temp": latest.get("Temperature", 0) if latest else 0,
        "current_humidity": latest.get("Humidity", 0) if latest else 0,
        "current_image_risk": latest.get("ImageRiskScore", 0) if latest else 0,
        "last_sync": device.get("last_sync", datetime.now().isoformat()),
        "avg_water": avg_water,
        "avg_temp": avg_temp,
        "avg_humidity": avg_hum,
    }


# -----------------------------------------------------------------------------
# Data Seeding
# -----------------------------------------------------------------------------
def seed_initial_data(force=False):
    if not force and os.path.exists(config.LOCAL_DATA_FILE) and os.path.getsize(config.LOCAL_DATA_FILE) > 10:
        return

    now = datetime.now()
    seed_records = []
    
    for i in range(48, 0, -1):
        t = now - timedelta(hours=i)
        if i > 24:
            wl = round(32.0 + (48 - i) * 1.2 + (i % 3), 1)
            temp = round(26.0 + (i % 4) * 0.8, 1)
            hum = round(62.0 + (i % 5) * 2.0, 1)
            img_risk = round(20.0 + (48 - i) * 0.8, 1)
        elif i > 6:
            wl = round(65.0 + (24 - i) * 0.8, 1)
            temp = round(28.5 + (i % 3) * 0.5, 1)
            hum = round(72.0 + (i % 4) * 1.5, 1)
            img_risk = round(60.0 + (24 - i) * 1.0, 1)
        else:
            wl = round(78.0 + (6 - i) * 0.3, 1)
            temp = round(29.0 + (i % 2) * 0.4, 1)
            hum = round(76.0 + (i % 2) * 0.6, 1)
            img_risk = round(85.0 + (6 - i) * 1.2, 1)

        score, label, reasons = classify_risk(wl, temp, hum, img_risk)
        
        seed_records.append({
            "RecordID": f"REC-{uuid.uuid4().hex[:8].upper()}",
            "DeviceID": config.DEFAULT_DEVICE_ID,
            "WaterLevel": wl,
            "Temperature": temp,
            "Humidity": hum,
            "ImageRiskScore": img_risk,
            "RiskScore": score,
            "RiskLabel": label,
            "AlertStatus": label in ("caution", "danger"),
            "BuzzerStatus": "ACTIVE" if label == "danger" else "OFF",
            "LedStatus": "RED" if label == "danger" else ("YELLOW" if label == "caution" else "GREEN"),
            "Reasons": reasons,
            "Latitude": config.DEFAULT_LATITUDE,
            "Longitude": config.DEFAULT_LONGITUDE,
            "Timestamp": t.isoformat(),
        })

    live_rec = {
        "RecordID": f"REC-LATEST-01",
        "DeviceID": "ESP32-01",
        "WaterLevel": 78.0,
        "Temperature": 29.0,
        "Humidity": 76.0,
        "ImageRiskScore": 88.0,
        "RiskScore": 3,
        "RiskLabel": "danger",
        "AlertStatus": True,
        "BuzzerStatus": "ACTIVE",
        "LedStatus": "RED",
        "Reasons": [
            "Stagnant water level (78.0%) exceeds safety limit (70.0%)",
            "Favorable climate: Temp 29.0°C (opt: 20.0-32.0°C) & Humidity 76.0% (min: 60.0%)",
            "AI Vision detected mosquito larvae / pupae (Confidence: 88.0%)"
        ],
        "Latitude": config.DEFAULT_LATITUDE,
        "Longitude": config.DEFAULT_LONGITUDE,
        "Timestamp": now.isoformat(),
    }
    seed_records.append(live_rec)
    _write_json(config.LOCAL_DATA_FILE, seed_records)

    seed_alerts = [
        {
            "alert_id": "ALT-1082",
            "title": "⚠️ Mosquito Breeding Risk Detected",
            "device_id": "ESP32-01",
            "location": "Sector 4 - Drainage Sump A, Green Valley",
            "water_level": 78.0,
            "temperature": 29.0,
            "humidity": 76.0,
            "image_risk_score": 88.0,
            "risk_level": "danger",
            "risk_score": 3,
            "status": "active",
            "created_at": (now - timedelta(minutes=24)).isoformat(),
            "last_updated": now.isoformat(),
            "reasons": [
                "Stagnant water level (78.0%) exceeds threshold (>70%)",
                "Temperature 29.0°C & Humidity 76.0% in peak breeding window",
                "AI Camera detected high mosquito larvae concentration (88%)"
            ],
            "image_evidence": "/static/images/larvae_sample.svg",
            "is_cleaned": False,
            "actions_log": [
                {
                    "timestamp": (now - timedelta(minutes=24)).isoformat(),
                    "actor": "System Automation (ESP32-01)",
                    "action": "Sensor threshold breach. High danger alert broadcasted."
                },
                {
                    "timestamp": (now - timedelta(minutes=10)).isoformat(),
                    "actor": "Municipal Control Room",
                    "action": "Dispatched Field Officer team to Sector 4."
                }
            ],
            "resolved_at": None,
            "resolved_by": None
        },
        {
            "alert_id": "ALT-1081",
            "title": "🟡 Caution: Favourable Breeding Conditions",
            "device_id": "ESP32-02",
            "location": "Sector 2 - School Playground Rain Tank",
            "water_level": 58.5,
            "temperature": 28.0,
            "humidity": 72.0,
            "image_risk_score": 45.0,
            "risk_level": "caution",
            "risk_score": 1,
            "status": "active",
            "created_at": (now - timedelta(hours=3)).isoformat(),
            "last_updated": (now - timedelta(hours=1)).isoformat(),
            "reasons": [
                "Water level rising towards threshold (58.5%)",
                "Atmospheric humidity is high (72.0%)"
            ],
            "image_evidence": "/static/images/water_tank_sample.svg",
            "is_cleaned": False,
            "actions_log": [
                {
                    "timestamp": (now - timedelta(hours=3)).isoformat(),
                    "actor": "System Automation",
                    "action": "Caution threshold triggered."
                }
            ],
            "resolved_at": None,
            "resolved_by": None
        },
        {
            "alert_id": "ALT-1080",
            "title": "⚠️ Mosquito Breeding Risk Detected (Resolved)",
            "device_id": "ESP32-01",
            "location": "Sector 4 - Commercial Plaza Cooling Tower",
            "water_level": 82.0,
            "temperature": 30.5,
            "humidity": 80.0,
            "image_risk_score": 92.0,
            "risk_level": "danger",
            "risk_score": 3,
            "status": "resolved",
            "created_at": (now - timedelta(days=1, hours=5)).isoformat(),
            "last_updated": (now - timedelta(days=1, hours=2)).isoformat(),
            "reasons": [
                "High stagnant water depth in cooling basin",
                "Severe larvae presence identified by vision sensor"
            ],
            "image_evidence": "/static/images/larvae_sample.svg",
            "is_cleaned": True,
            "actions_log": [
                {
                    "timestamp": (now - timedelta(days=1, hours=5)).isoformat(),
                    "actor": "System Automation",
                    "action": "High danger alert initiated."
                },
                {
                    "timestamp": (now - timedelta(days=1, hours=3)).isoformat(),
                    "actor": "Field Officer Alok Verma",
                    "action": "Applied Abate larvicide granules and cleaned cooling basin."
                },
                {
                    "timestamp": (now - timedelta(days=1, hours=2)).isoformat(),
                    "actor": "Field Officer Alok Verma",
                    "action": "Marked as Resolved: Area cleaned and sanitized."
                }
            ],
            "resolved_at": (now - timedelta(days=1, hours=2)).isoformat(),
            "resolved_by": "Field Officer Alok Verma"
        },
        {
            "alert_id": "ALT-1079",
            "title": "🟡 Caution: Stagnant Water Accumulation (Resolved)",
            "device_id": "ESP32-03",
            "location": "Community Park - Fountain Reservoir",
            "water_level": 62.0,
            "temperature": 27.0,
            "humidity": 68.0,
            "image_risk_score": 38.0,
            "risk_level": "caution",
            "risk_score": 1,
            "status": "resolved",
            "created_at": (now - timedelta(days=2, hours=8)).isoformat(),
            "last_updated": (now - timedelta(days=2, hours=4)).isoformat(),
            "reasons": [
                "Stagnant water accumulation following rain"
            ],
            "image_evidence": "/static/images/water_tank_sample.svg",
            "is_cleaned": True,
            "actions_log": [
                {
                    "timestamp": (now - timedelta(days=2, hours=4)).isoformat(),
                    "actor": "Municipal Health Worker",
                    "action": "Fountain basin cleaned and covered with mesh net."
                }
            ],
            "resolved_at": (now - timedelta(days=2, hours=4)).isoformat(),
            "resolved_by": "Municipal Health Worker"
        }
    ]
    _write_json(config.LOCAL_ALERTS_FILE, seed_alerts)

    _write_json(config.LOCAL_DEVICE_FILE, {
        "device_id": "ESP32-01",
        "device_name": "ESP32 Mosquito Guard Node #1",
        "location": "Sector 4 - Drainage Sump A, Green Valley",
        "latitude": config.DEFAULT_LATITUDE,
        "longitude": config.DEFAULT_LONGITUDE,
        "status": "connected",
        "battery_level": 94,
        "power_source": "Solar + USB-C 5V",
        "wifi_rssi": -62,
        "buzzer_state": "ACTIVE",
        "led_state": "RED",
        "last_sync": now.isoformat(),
        "firmware_version": "v2.4-ESP32-AI",
    })


# Initialize seed data
_ensure_file(config.LOCAL_DATA_FILE, [])
if not _read_json(config.LOCAL_DATA_FILE, []):
    seed_initial_data(force=True)
