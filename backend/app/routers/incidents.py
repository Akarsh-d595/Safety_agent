"""
POST /incidents      — log an incident
GET  /incidents      — retrieve all incidents (optionally filtered by user_id)
"""
from fastapi import APIRouter, Query
from typing import Any
from app.models import LogIncidentRequest, LogIncidentResponse
from app.incident_store import log_incident, get_incidents

router = APIRouter(prefix="/incidents", tags=["Incidents"])


@router.post("", response_model=LogIncidentResponse)
async def create_incident(body: LogIncidentRequest) -> LogIncidentResponse:
    """Persist an incident record and return its generated ID."""
    incident_id = log_incident(
        user_id=body.user_id,
        text=body.text,
        level=body.level.value,
        latitude=body.latitude,
        longitude=body.longitude,
        triggered=body.triggered,
    )
    return LogIncidentResponse(incident_id=incident_id, stored=True)


@router.get("", response_model=list[dict[str, Any]])
async def list_incidents(
    user_id: str | None = Query(None, description="Filter by user ID"),
) -> list[dict[str, Any]]:
    """Return stored incidents, newest first."""
    incidents = get_incidents(user_id=user_id)
    return list(reversed(incidents))
