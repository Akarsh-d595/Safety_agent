"""
Contact store — persists emergency contacts per user to a JSON file.
Each contact has: id, user_id, name, phone (E.164), notify_on_high,
notify_on_medium, created_at.
"""
from __future__ import annotations

import json
import os
import uuid
from datetime import datetime, timezone
from typing import Any

_STORE_FILE = os.getenv("CONTACT_STORE_FILE", "contacts.json")

_contacts: list[dict[str, Any]] = []
_loaded = False


def _load() -> None:
    global _contacts, _loaded
    if _loaded:
        return
    if os.path.exists(_STORE_FILE):
        try:
            with open(_STORE_FILE, "r", encoding="utf-8") as f:
                _contacts = json.load(f)
        except (json.JSONDecodeError, OSError):
            _contacts = []
    _loaded = True


def _save() -> None:
    try:
        with open(_STORE_FILE, "w", encoding="utf-8") as f:
            json.dump(_contacts, f, indent=2, default=str)
    except OSError as exc:
        import logging
        logging.getLogger(__name__).error("Could not save contacts: %s", exc)


def add_contact(
    *,
    user_id: str,
    name: str,
    phone: str,
    notify_on_high: bool = True,
    notify_on_medium: bool = False,
) -> dict[str, Any]:
    _load()
    record: dict[str, Any] = {
        "id":               str(uuid.uuid4()),
        "user_id":          user_id,
        "name":             name,
        "phone":            phone,
        "notify_on_high":   notify_on_high,
        "notify_on_medium": notify_on_medium,
        "created_at":       datetime.now(timezone.utc).isoformat(),
    }
    _contacts.append(record)
    _save()
    return record


def get_contacts(user_id: str) -> list[dict[str, Any]]:
    _load()
    return [c for c in _contacts if c.get("user_id") == user_id]


def update_contact(
    contact_id: str,
    user_id: str,
    *,
    name: str | None = None,
    phone: str | None = None,
    notify_on_high: bool | None = None,
    notify_on_medium: bool | None = None,
) -> dict[str, Any] | None:
    _load()
    for c in _contacts:
        if c["id"] == contact_id and c["user_id"] == user_id:
            if name             is not None: c["name"]             = name
            if phone            is not None: c["phone"]            = phone
            if notify_on_high   is not None: c["notify_on_high"]   = notify_on_high
            if notify_on_medium is not None: c["notify_on_medium"] = notify_on_medium
            _save()
            return c
    return None


def delete_contact(contact_id: str, user_id: str) -> bool:
    global _contacts
    _load()
    before = len(_contacts)
    _contacts = [
        c for c in _contacts
        if not (c["id"] == contact_id and c["user_id"] == user_id)
    ]
    if len(_contacts) < before:
        _save()
        return True
    return False
