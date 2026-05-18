"""
In-memory incident store with a simple JSON file persistence layer.
Replace with a real database (PostgreSQL, SQLite, etc.) for production.
"""
from __future__ import annotations

import json
import os
import uuid
from datetime import datetime, timezone
from typing import Any

_STORE_FILE = os.getenv("INCIDENT_STORE_FILE", "incidents.json")

# In-memory list — loaded from disk on first access
_incidents: list[dict[str, Any]] = []
_loaded = False


def _load() -> None:
    global _incidents, _loaded
    if _loaded:
        return
    if os.path.exists(_STORE_FILE):
        try:
            with open(_STORE_FILE, "r", encoding="utf-8") as f:
                _incidents = json.load(f)
        except (json.JSONDecodeError, OSError):
            _incidents = []
    _loaded = True


def _save() -> None:
    try:
        with open(_STORE_FILE, "w", encoding="utf-8") as f:
            json.dump(_incidents, f, indent=2, default=str)
    except OSError as exc:
        import logging
        logging.getLogger(__name__).error("Could not save incidents: %s", exc)


def log_incident(
    *,
    user_id: str | None,
    text: str,
    level: str,
    latitude: float | None,
    longitude: float | None,
    triggered: bool,
) -> str:
    """Persist an incident and return its generated ID."""
    _load()
    incident_id = str(uuid.uuid4())
    record: dict[str, Any] = {
        "id":        incident_id,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "user_id":   user_id,
        "text":      text,
        "level":     level,
        "latitude":  latitude,
        "longitude": longitude,
        "triggered": triggered,
    }
    _incidents.append(record)
    _save()
    return incident_id


def get_incidents(user_id: str | None = None) -> list[dict[str, Any]]:
    """Return all incidents, optionally filtered by user_id."""
    _load()
    if user_id:
        return [i for i in _incidents if i.get("user_id") == user_id]
    return list(_incidents)
