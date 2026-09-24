"""
app.py
------
Flask REST Backend & API Server for the Smart Mosquito Breeding Detection System.
Provides endpoints for ESP32 IoT ingestion, mobile client telemetry, alert resolution,
pump control, and data visualization.
"""

import csv
import io
from datetime import datetime
from flask import Flask, Response, jsonify, render_template, request, session, redirect, url_for

import config
import data_store

app = Flask(__name__)
app.config["SECRET_KEY"] = config.SECRET_KEY

# Cache for faster responses
_latest_cache = {"data": None, "time": 0}
_cache_ttl = 5  # seconds


def _get_cached_latest():
    """Get cached latest data or fetch fresh."""
    import time
    current_time = time.time()
    
    # Return cache if fresh
    if _latest_cache["data"] and (current_time - _latest_cache["time"]) < _cache_ttl:
        return _latest_cache["data"]
    
    # Fetch fresh data
    try:
        record = data_store.get_latest_record()
        device = data_store.get_device_status()
        
        result = {
            "record": record or {},
            "device": device or {},
            "backend": "firebase" if data_store.USING_FIREBASE else "local-storage"
        }
        
        # Update cache
        _latest_cache["data"] = result
        _latest_cache["time"] = current_time
        
        return result
    except Exception:
        # Return cached data if fetch fails
        return _latest_cache["data"] or {"record": {}, "device": {}, "backend": "local-storage"}


# Health check - lightweight endpoint for connection verification
@app.route("/api/health", methods=["GET"])
def api_health():
    """Lightweight health check - responds immediately on startup."""
    return jsonify({
        "status": "ok",
        "service": "mosquito-guard",
        "timestamp": datetime.now().isoformat()
    }), 200


def _start_keep_alive():
    """Background thread to keep Render instance awake and prevent spin-down loading screens."""
    import threading
    import time
    import urllib.request

    def ping_worker():
        # Wait 30 seconds after boot before first ping
        time.sleep(30)
        while True:
            try:
                # Ping local and public endpoints to prevent spin-down
                urllib.request.urlopen("https://smart-mosquito-dashboard-1.onrender.com/api/health", timeout=10)
            except Exception:
                pass
            # Sleep 10 minutes (Render spins down after 15 minutes of inactivity)
            time.sleep(600)

    t = threading.Thread(target=ping_worker, daemon=True)
    t.start()

# Start the keepalive daemon
_start_keep_alive()


# -----------------------------------------------------------------------------
# Web Page Routes (Authentication & Dashboard)
# -----------------------------------------------------------------------------

# Hardcoded dummy credentials for basic security
ADMIN_USERNAME = "admin"
ADMIN_PASSWORD = "password123"

@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        username = request.form.get("username")
        password = request.form.get("password")
        
        if username == ADMIN_USERNAME and password == ADMIN_PASSWORD:
            session["logged_in"] = True
            return redirect(url_for("dashboard"))
        else:
            return render_template("login.html", error="Invalid username or password")
            
    # If already logged in, go to dashboard
    if session.get("logged_in"):
        return redirect(url_for("dashboard"))
        
    return render_template("login.html")


@app.route("/logout")
def logout():
    session.pop("logged_in", None)
    return redirect(url_for("login"))


@app.route("/")
def dashboard():
    # Protect dashboard route
    if not session.get("logged_in"):
        return redirect(url_for("login"))
        
    return render_template(
        "index.html",
        using_firebase=data_store.USING_FIREBASE,
        firebase_url=config.FIREBASE_DB_URL,
        device_id=config.DEFAULT_DEVICE_ID
    )


# -----------------------------------------------------------------------------
# Sensor Telemetry & Ingestion Endpoints
# -----------------------------------------------------------------------------
@app.route("/api/latest", methods=["GET"])
def api_latest():
    """Returns the latest sensor reading, active risk status, and device metadata."""
    return jsonify(_get_cached_latest())


@app.route("/api/records", methods=["GET"])
def api_records():
    """Returns historical records with optional filtering by risk and time range."""
    risk = request.args.get("risk", "all")
    time_range = request.args.get("time_range", "all")
    limit = int(request.args.get("limit", 100))
    records = data_store.get_filtered_records(risk=risk, time_range=time_range, limit=limit)
    return jsonify(records)


@app.route("/api/ingest", methods=["POST"])
def api_ingest():
    """
    Accepts new sensor telemetry from physical ESP32 or simulation script.
    Payload: {"water_level": 78.0, "temperature": 29.0, "humidity": 76.0, "image_risk_score": 88.0}
    """
    payload = request.get_json(force=True, silent=True) or {}
    try:
        water_level = float(payload.get("water_level", payload.get("WaterLevel", 0)))
        temperature = float(payload.get("temperature", payload.get("Temperature", 0)))
        humidity = float(payload.get("humidity", payload.get("Humidity", 0)))
    except (KeyError, TypeError, ValueError):
        return jsonify({"error": "water_level, temperature and humidity must be valid numbers"}), 400

    image_risk_score = payload.get("image_risk_score", payload.get("ImageRiskScore"))
    if image_risk_score is not None:
        image_risk_score = float(image_risk_score)

    latitude = payload.get("latitude")
    longitude = payload.get("longitude")
    device_id = payload.get("device_id", config.DEFAULT_DEVICE_ID)

    record = data_store.add_record(
        water_level=water_level,
        temperature=temperature,
        humidity=humidity,
        image_risk_score=image_risk_score,
        latitude=latitude,
        longitude=longitude,
        device_id=device_id
    )
    return jsonify(record), 201


@app.route("/api/simulate", methods=["POST"])
def api_simulate():
    """
    Convenience endpoint for UI demo buttons to immediately inject
    High Risk (danger), Caution, or Safe sensor conditions.
    """
    payload = request.get_json(force=True, silent=True) or {}
    scenario = payload.get("scenario", "danger")

    if scenario == "danger":
        rec = data_store.add_record(
            water_level=78.0,
            temperature=29.0,
            humidity=76.0,
            image_risk_score=88.0,
            device_id="ESP32-01"
        )
    elif scenario == "caution":
        rec = data_store.add_record(
            water_level=58.0,
            temperature=27.5,
            humidity=68.0,
            image_risk_score=42.0,
            device_id="ESP32-01"
        )
    elif scenario == "safe":
        rec = data_store.add_record(
            water_level=18.0,
            temperature=24.0,
            humidity=45.0,
            image_risk_score=5.0,
            device_id="ESP32-01"
        )
    elif scenario == "reset":
        data_store.seed_initial_data(force=True)
        rec = data_store.get_latest_record()
    else:
        rec = data_store.get_latest_record()

    return jsonify({"success": True, "scenario": scenario, "record": rec})


# -----------------------------------------------------------------------------
# Alerts Management Endpoints
# -----------------------------------------------------------------------------
@app.route("/api/alerts", methods=["GET"])
def api_alerts():
    """Returns alerts list filtered by status ('all', 'active', 'resolved')."""
    status_filter = request.args.get("status", "all")
    alerts = data_store.get_alerts(status_filter=status_filter)
    return jsonify(alerts)


@app.route("/api/alerts/<alert_id>", methods=["GET"])
def api_alert_details(alert_id):
    """Returns full information for a specific alert."""
    alert = data_store.get_alert_by_id(alert_id)
    if not alert:
        return jsonify({"error": "Alert not found"}), 404
    return jsonify(alert)


@app.route("/api/alerts/<alert_id>/resolve", methods=["POST"])
def api_resolve_alert(alert_id):
    """Marks an alert as resolved with user details and notes."""
    payload = request.get_json(force=True, silent=True) or {}
    resolved_by = payload.get("resolved_by", "Field Officer")
    action_note = payload.get("note", "Inspected and resolved via Mobile App.")
    
    success = data_store.resolve_alert(alert_id, resolved_by=resolved_by, resolution_note=action_note)
    if not success:
        return jsonify({"error": "Alert not found"}), 404

    active_dangers = [a for a in data_store.get_alerts("active") if a.get("risk_level") == "danger"]
    if not active_dangers:
        data_store.update_device_status({"buzzer_state": "OFF", "led_state": "GREEN"})

    return jsonify({"success": True, "alert_id": alert_id, "status": "resolved"})


@app.route("/api/alerts/<alert_id>/action", methods=["POST"])
def api_alert_action(alert_id):
    """Logs field action taken (e.g. Larvicide, Cleaning, Inspection)."""
    payload = request.get_json(force=True, silent=True) or {}
    actor = payload.get("actor", "Field Officer")
    action_note = payload.get("note", "Action logged.")
    mark_cleaned = payload.get("mark_cleaned", False)
    mark_resolved = payload.get("mark_resolved", False)

    updated_alert = data_store.log_alert_action(
        alert_id=alert_id,
        actor=actor,
        action_note=action_note,
        mark_cleaned=mark_cleaned,
        mark_resolved=mark_resolved
    )
    if not updated_alert:
        return jsonify({"error": "Alert not found"}), 404

    return jsonify({"success": True, "alert": updated_alert})


# -----------------------------------------------------------------------------
# Device & Hardware Diagnostics
# -----------------------------------------------------------------------------
@app.route("/api/device", methods=["GET"])
def api_device():
    """Returns current ESP32 device status, connection, and diagnostics."""
    device = data_store.get_device_status()
    return jsonify(device)


@app.route("/api/device/control", methods=["POST"])
def api_device_control():
    """
    Endpoint for dashboard to send control commands to the hardware (ESP32).
    Accepts JSON like: {"pump_state": "ON", "pump_mode": "manual", "led_state": "YELLOW"}
    The ESP32 should poll GET /api/device to see these changes and execute them.
    """
    payload = request.get_json(force=True, silent=True) or {}
    
    # Filter valid keys to prevent garbage data
    valid_keys = ["pump_state", "pump_mode", "buzzer_state", "led_state"]
    updates = {k: v for k, v in payload.items() if k in valid_keys}
    
    if not updates:
        return jsonify({"error": "No valid control commands provided"}), 400
        
    updated_device = data_store.update_device_status(updates)
    return jsonify({"success": True, "device": updated_device})


# -----------------------------------------------------------------------------
# Statistics & Report Export
# -----------------------------------------------------------------------------
@app.route("/api/stats", methods=["GET"])
def api_stats():
    """Returns high-level statistics for dashboard cards and charts."""
    return jsonify(data_store.get_system_stats())


@app.route("/api/report/export", methods=["GET"])
def api_export_report():
    """Exports historical sensor and alert records as a downloadable CSV."""
    records = data_store.get_all_records()
    output = io.StringIO()
    writer = csv.writer(output)
    
    # Write CSV Header
    writer.writerow([
        "RecordID", "Timestamp", "DeviceID", "WaterLevel(%)", 
        "Temperature(C)", "Humidity(%)", "ImageRiskScore(%)", 
        "RiskLabel", "RiskScore", "PumpStatus", "Latitude", "Longitude"
    ])
    
    for r in records:
        writer.writerow([
            r.get("RecordID", ""),
            r.get("Timestamp", ""),
            r.get("DeviceID", ""),
            r.get("WaterLevel", ""),
            r.get("Temperature", ""),
            r.get("Humidity", ""),
            r.get("ImageRiskScore", ""),
            r.get("RiskLabel", ""),
            r.get("RiskScore", ""),
            "ON" if r.get("PumpStatus") else "OFF",
            r.get("Latitude", ""),
            r.get("Longitude", "")
        ])

    return Response(
        output.getvalue(),
        mimetype="text/csv",
        headers={"Content-Disposition": f"attachment;filename=mosquito_detection_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"}
    )


# -----------------------------------------------------------------------------
# Threshold Configuration
# -----------------------------------------------------------------------------
@app.route("/api/config", methods=["GET", "POST"])
def api_config():
    if request.method == "POST":
        payload = request.get_json(force=True, silent=True) or {}
        if "water_threshold" in payload:
            config.WATER_THRESHOLD = float(payload["water_threshold"])
        if "temp_min" in payload:
            config.TEMP_MIN = float(payload["temp_min"])
        if "temp_max" in payload:
            config.TEMP_MAX = float(payload["temp_max"])
        if "humidity_min" in payload:
            config.HUMIDITY_MIN = float(payload["humidity_min"])
        if "image_risk_threshold" in payload:
            config.IMAGE_RISK_THRESHOLD = float(payload["image_risk_threshold"])

    return jsonify({
        "water_threshold": config.WATER_THRESHOLD,
        "temp_min": config.TEMP_MIN,
        "temp_max": config.TEMP_MAX,
        "humidity_min": config.HUMIDITY_MIN,
        "image_risk_threshold": config.IMAGE_RISK_THRESHOLD,
        "danger_level": config.DANGER_LEVEL,
        "caution_level": config.CAUTION_LEVEL,
    })


if __name__ == "__main__":
    app.run(debug=config.DEBUG, use_reloader=False, host="0.0.0.0", port=config.PORT)
