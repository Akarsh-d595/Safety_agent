# 🛡️ AI Emergency Safety System

Full-stack emergency detection app — **React** frontend + **FastAPI** backend.

---

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│                  React Frontend (Vite)                    │
│                                                          │
│  Layout (sidebar nav)                                    │
│    ├── HomePage      — mic + text input, AI detection    │
│    ├── ContactsPage  — add/edit/delete emergency contacts│
│    │                   choose who gets live location     │
│    ├── HistoryPage   — incident log from backend         │
│    ├── SettingsPage  — user ID, backend URL, Twilio info │
│    └── EmergencyPage — full-screen red alert UI          │
│                                                          │
│  SafetyContext (global state)                            │
│    └── api.js  (axios → FastAPI)                         │
└────────────────────┬─────────────────────────────────────┘
                     │ HTTP/JSON  (proxied via Vite in dev)
                     ▼
┌──────────────────────────────────────────────────────────┐
│                  FastAPI Backend                          │
│                                                          │
│  GET  /health                — liveness probe            │
│  POST /analyze               — AI danger detection       │
│  POST /alert                 — SMS via Twilio            │
│  POST /incidents             — log incident              │
│  GET  /incidents?user_id=x   — fetch history             │
│  GET  /contacts?user_id=x    — list contacts             │
│  POST /contacts              — add contact               │
│  PUT  /contacts/{id}         — update contact            │
│  DELETE /contacts/{id}       — delete contact            │
└──────────────────────────────────────────────────────────┘
```

---

## Quick Start

### 1 — Backend

```bash
cd backend

# Create virtual environment
python -m venv venv
venv\Scripts\activate          # Windows
# source venv/bin/activate     # macOS/Linux

# Install dependencies
pip install -r requirements.txt

# Configure environment
copy .env.example .env
# Edit .env — add Twilio credentials for SMS

# Start server
python run.py
# → http://localhost:8000
# → http://localhost:8000/docs  (Swagger UI)
```

### 2 — Frontend

```bash
cd frontend

npm install
npm run dev
# → http://localhost:3000
```

The Vite dev server proxies `/api/*` → `http://localhost:8000` automatically.

---

## Emergency Contacts — Live Location Sharing

In the **Contacts** page you can:
- Add contacts with name + E.164 phone number
- Toggle **"Alert on High danger"** — contact receives SMS with live Google Maps link
- Toggle **"Alert on Medium danger"** — contact alerted after user confirms

When a high-danger phrase is detected:
1. Browser Geolocation API fetches live coordinates
2. A Google Maps link is embedded in the alert message
3. SMS is sent to all contacts with `notify_on_high = true` via Twilio

---

## Danger Level Reference

| Level  | Example phrases | Action |
|--------|----------------|--------|
| high   | "save me", "help me", "I'm in danger" | Auto-trigger, SMS all high-alert contacts, call 112 |
| medium | "help", "someone is following me" | Show confirmation dialog |
| low    | "something feels wrong" | Show safe message |
| none   | Normal conversation | No action |

---

## SMS Alerts (Twilio)

Add to `backend/.env`:
```
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your_auth_token
TWILIO_FROM_NUMBER=+1234567890
```

Without Twilio the backend still works — SMS steps are skipped and logged as warnings.

---

## API Reference

### `POST /analyze`
```json
{ "text": "help me someone is following me", "user_id": "alice" }
```
```json
{ "danger": true, "level": "medium", "reason": "...", "trigger": false }
```

### `POST /contacts`
```json
{ "user_id": "alice", "name": "Mom", "phone": "+1234567890", "notify_on_high": true, "notify_on_medium": false }
```

### `POST /alert`
```json
{ "message": "🚨 ...", "level": "high", "latitude": 40.71, "longitude": -74.00, "contacts": ["+1234567890"] }
```

### `GET /incidents?user_id=alice`
Returns array of incident records, newest first.
