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
from flask import Flask, Response, jsonify, render_template, request

import config
import data_store

app = Flask(__name__)
app.config["SECRET_KEY"] = config.SECRET_KEY


# -----------------------------------------------------------------------------
# Web Page Route
# -----------------------------------------------------------------------------
@app.route("/")
def dashboard():
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
    record = data_store.get_latest_record()
    device = data_store.get_device_status()
    stats = data_store.get_system_stats()
    
    return jsonify({
        "record": record or {},
        "device": device or {},
        "stats": stats or {},
        "backend": "firebase" if data_store.USING_FIREBASE else "local-storage"
    })


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


@app.route("/api/health")
def api_health():
    return jsonify({
        "status": "healthy",
        "system": "Smart Mosquito Breeding Detection System",
        "version": "2.4.0",
        "backend": "firebase" if data_store.USING_FIREBASE else "local-json",
        "timestamp": datetime.now().isoformat()
    })


if __name__ == "__main__":
    app.run(debug=config.DEBUG, use_reloader=False, host="0.0.0.0", port=config.PORT)
