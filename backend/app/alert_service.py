"""
Alert service — sends SMS via Twilio and builds alert messages.
Falls back gracefully when Twilio credentials are not configured.
"""
from __future__ import annotations

import logging
import os
import re
from typing import Optional

logger = logging.getLogger(__name__)


def build_alert_message(
    latitude: Optional[float],
    longitude: Optional[float],
    user_id: Optional[str] = None,
) -> str:
    """Build the standard emergency alert message."""
    name_prefix = f"User {user_id} " if user_id else "Someone "
    if latitude is not None and longitude is not None:
        location_line = (
            f"Track their location:\n"
            f"https://www.google.com/maps?q={latitude},{longitude}"
        )
    else:
        location_line = "Location unavailable."

    return (
        "🚨 EMERGENCY ALERT 🚨\n"
        f"{name_prefix}may be in danger.\n"
        f"{location_line}"
    )


def _normalise_e164(number: str) -> str:
    """Strip spaces, dashes, parentheses — keep only + and digits."""
    cleaned = re.sub(r"[^\d+]", "", number)
    if not cleaned.startswith("+"):
        cleaned = "+" + cleaned
    return cleaned


def send_sms_alerts(
    contacts: list[str],
    message: str,
) -> tuple[list[str], list[str]]:
    """
    Send *message* to every number in *contacts* via Twilio SMS.

    Returns (sent_list, failed_list).
    If Twilio is not configured the function logs a warning and returns
    all numbers as 'failed' so the app can still proceed.
    """
    account_sid = os.getenv("TWILIO_ACCOUNT_SID", "").strip()
    auth_token  = os.getenv("TWILIO_AUTH_TOKEN",  "").strip()
    from_number = _normalise_e164(os.getenv("TWILIO_FROM_NUMBER", "").strip())

    if not all([account_sid, auth_token, from_number.strip("+")]):
        logger.warning(
            "Twilio not configured — SMS alerts skipped. "
            "Set TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_FROM_NUMBER in .env"
        )
        return [], contacts

    try:
        from twilio.rest import Client  # type: ignore
        client = Client(account_sid, auth_token)
    except ImportError:
        logger.error("twilio package not installed — run: pip install twilio")
        return [], contacts

    sent:   list[str] = []
    failed: list[str] = []

    for raw_number in contacts:
        number = _normalise_e164(raw_number)
        try:
            client.messages.create(
                body=message,
                from_=from_number,
                to=number,
            )
            sent.append(number)
            logger.info("SMS sent to %s", number)
        except Exception as exc:
            failed.append(number)
            logger.error("SMS failed to %s: %s", number, exc)

    return sent, failed
