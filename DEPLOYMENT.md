# Production deployment

## Architecture

The project is a same-origin Flask web application:

- `app.py` exposes the REST API and serves `templates/index.html`.
- `static/` contains the responsive web frontend, JavaScript API client, charts, and PWA assets.
- `data_store.py` provides local JSON storage and optional Firebase Realtime Database sync.
- `mobile_app/` is a separate Flutter client that consumes the deployed `/api` endpoints.
- `firmware/esp32_mosquito_detector.ino` sends sensor telemetry to `/api/ingest`.

## Run locally

```bash
python -m venv .venv
# Windows: .venv\\Scripts\\activate
# macOS/Linux: source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
python app.py
```

Open `http://127.0.0.1:5000`. For a production-like local process:

```bash
gunicorn --config gunicorn.conf.py app:app
```

## Deploy publicly with Render

1. Push this repository to GitHub.
2. In Render, choose **New → Blueprint** and select this repository.
3. Render reads `render.yaml`, installs dependencies, starts Gunicorn, and checks `/api/health`.
4. Set `FIREBASE_DB_URL` and `FIREBASE_AUTH` only if cloud persistence is required.
5. Copy the generated HTTPS service URL into the Flutter app's `baseUrl` and the ESP32 `SERVER_INGEST_URL`.
6. Confirm these endpoints after deployment:

```bash
curl https://YOUR-SERVICE.onrender.com/api/health
curl https://YOUR-SERVICE.onrender.com/api/latest
```

### Important persistence note

The local JSON backend is suitable for demos only. Public Render instances can lose local files during restart/redeploy. Configure Firebase before production use so telemetry and alerts survive restarts.

### Security checklist

- Keep `.env` out of Git.
- Use a generated `FLASK_SECRET_KEY`.
- Keep `DEBUG=False` in Render.
- Use HTTPS URLs in ESP32 and Flutter configuration.
- Do not expose Firebase credentials in frontend JavaScript.
- Restrict write endpoints with authentication before public multi-user use.
