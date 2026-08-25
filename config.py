"""
config.py
---------
Configuration for the Smart Mosquito Breeding Spot Detection System.
Includes municipal office routing settings, environmental thresholds,
database paths, and email configuration.
"""

import os
from dotenv import load_dotenv

load_dotenv()

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(BASE_DIR, "data")
os.makedirs(DATA_DIR, exist_ok=True)

# Data storage paths
LOCAL_DATA_FILE = os.path.join(DATA_DIR, "records.json")
LOCAL_ALERTS_FILE = os.path.join(DATA_DIR, "alerts.json")
LOCAL_SPOTS_FILE = os.path.join(DATA_DIR, "breeding_spots.json")
LOCAL_COMPLAINTS_FILE = os.path.join(DATA_DIR, "complaints.json")
LOCAL_MUNICIPAL_FILE = os.path.join(DATA_DIR, "municipal_offices.json")
LOCAL_USERS_FILE = os.path.join(DATA_DIR, "users.json")
LOCAL_DEVICE_FILE = os.path.join(DATA_DIR, "device.json")

# Firebase (Optional live cloud sync)
FIREBASE_DB_URL = os.getenv("FIREBASE_DB_URL", "").rstrip("/")
FIREBASE_AUTH = os.getenv("FIREBASE_AUTH", "")

# Risk Thresholds
WATER_THRESHOLD = float(os.getenv("WATER_THRESHOLD", "70.0"))       # %
TEMP_MIN = float(os.getenv("TEMP_MIN", "20.0"))                     # °C
TEMP_MAX = float(os.getenv("TEMP_MAX", "32.0"))                     # °C
HUMIDITY_MIN = float(os.getenv("HUMIDITY_MIN", "60.0"))             # %
IMAGE_RISK_THRESHOLD = float(os.getenv("IMAGE_RISK_THRESHOLD", "65.0"))

DANGER_LEVEL = int(os.getenv("DANGER_LEVEL", "2"))
CAUTION_LEVEL = int(os.getenv("CAUTION_LEVEL", "1"))

# Default Hardware Node
DEFAULT_DEVICE_ID = "ESP32-CAM-01"
DEFAULT_DEVICE_NAME = "ESP32 Mosquito Guard Node #1"
DEFAULT_LATITUDE = 19.1663
DEFAULT_LONGITUDE = 72.8526
DEFAULT_AREA = "Green Valley, Sector 4"
DEFAULT_LOCATION = DEFAULT_AREA
DEFAULT_PINCODE = "400064"
MAX_LOCAL_RECORDS = int(os.getenv("MAX_LOCAL_RECORDS", "500"))

# Flask Server
SECRET_KEY = os.getenv("FLASK_SECRET_KEY", "smart-mosquito-breeding-detection-2026")
PORT = int(os.getenv("PORT", "5000"))
DEBUG = os.getenv("DEBUG", "True").lower() in ("true", "1", "yes")
