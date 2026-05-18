"""
POST /alert  — send SMS alerts to emergency contacts.
"""
import os
import logging
from fastapi import APIRouter
from app.models import AlertRequest, AlertResponse
from app.alert_service import build_alert_message, send_sms_alerts

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/alert", tags=["Alert"])


@router.post("", response_model=AlertResponse)
async def send_alert(body: AlertRequest) -> AlertResponse:
    """
    Dispatch SMS to the provided contacts.

    The frontend sends a fully-formed message (with live location link).
    We use it as-is. If no message is provided we build one from coordinates.
    If no contacts are supplied we fall back to EMERGENCY_CONTACTS in .env.
    """
    # Use the message the frontend built (it already has the live Maps link).
    # Only rebuild if the frontend sent an empty string.
    message = body.message.strip() if body.message.strip() else build_alert_message(
        latitude=body.latitude,
        longitude=body.longitude,
        user_id=body.user_id,
    )

    # Resolve contacts: request body takes priority, then env fallback
    contacts = list(body.contacts)
    if not contacts:
        env_contacts = os.getenv("EMERGENCY_CONTACTS", "")
        contacts = [c.strip() for c in env_contacts.split(",") if c.strip()]

    logger.info(
        "Alert request — level=%s contacts=%s lat=%s lon=%s",
        body.level, contacts, body.latitude, body.longitude,
    )

    if contacts:
        sent, failed = send_sms_alerts(contacts, message)
    else:
        logger.warning("No contacts to alert — add contacts in the app or set EMERGENCY_CONTACTS in .env")
        sent, failed = [], []

    return AlertResponse(
        success=len(sent) > 0 and len(failed) == 0,
        sms_sent=sent,
        sms_failed=failed,
        message=message,
    )
