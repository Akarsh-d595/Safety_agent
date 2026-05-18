"""
Pydantic request/response models for the Emergency Safety API.
"""
from __future__ import annotations

from enum import Enum
from typing import Optional
from pydantic import BaseModel, Field


# ── Enums ──────────────────────────────────────────────────────────────────────

class DangerLevel(str, Enum):
    none   = "none"
    low    = "low"
    medium = "medium"
    high   = "high"


# ── Request models ─────────────────────────────────────────────────────────────

class AnalyzeRequest(BaseModel):
    text: str = Field(..., min_length=1, max_length=2000,
                      description="Cleaned speech or typed input from the user")
    user_id: Optional[str] = Field(None, description="Optional device/user identifier")


class AlertRequest(BaseModel):
    user_id:   Optional[str]   = Field(None)
    latitude:  Optional[float] = Field(None, ge=-90,  le=90)
    longitude: Optional[float] = Field(None, ge=-180, le=180)
    message:   str             = Field(..., min_length=1)
    level:     DangerLevel     = Field(DangerLevel.high)
    contacts:  list[str]       = Field(default_factory=list,
                                       description="E.164 phone numbers to alert")


class LogIncidentRequest(BaseModel):
    user_id:   Optional[str]   = Field(None)
    text:      str             = Field(...)
    level:     DangerLevel     = Field(...)
    latitude:  Optional[float] = Field(None)
    longitude: Optional[float] = Field(None)
    triggered: bool            = Field(False)


# ── Response models ────────────────────────────────────────────────────────────

class AnalyzeResponse(BaseModel):
    danger:  bool        = Field(...)
    level:   DangerLevel = Field(...)
    reason:  str         = Field(...)
    trigger: bool        = Field(..., description="True only when level == high")


class AlertResponse(BaseModel):
    success:       bool      = Field(...)
    sms_sent:      list[str] = Field(default_factory=list,
                                     description="Numbers that received SMS")
    sms_failed:    list[str] = Field(default_factory=list)
    message:       str       = Field(...)


class LogIncidentResponse(BaseModel):
    incident_id: str  = Field(...)
    stored:      bool = Field(...)


class HealthResponse(BaseModel):
    status:  str = "ok"
    version: str = "1.0.0"
