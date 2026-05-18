"""
CRUD endpoints for emergency contacts.

GET    /contacts?user_id=x        — list contacts for a user
POST   /contacts                  — add a contact
PUT    /contacts/{contact_id}     — update a contact
DELETE /contacts/{contact_id}     — delete a contact
"""
from __future__ import annotations

from typing import Any, Optional
from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field

from app.contact_store import (
    add_contact,
    get_contacts,
    update_contact,
    delete_contact,
)

router = APIRouter(prefix="/contacts", tags=["Contacts"])


# ── Request / Response models ──────────────────────────────────────────────────

class ContactCreate(BaseModel):
    user_id:          str   = Field(..., min_length=1)
    name:             str   = Field(..., min_length=1, max_length=100)
    phone:            str   = Field(..., description="E.164 format, e.g. +1234567890")
    notify_on_high:   bool  = Field(True)
    notify_on_medium: bool  = Field(False)


class ContactUpdate(BaseModel):
    name:             Optional[str]  = None
    phone:            Optional[str]  = None
    notify_on_high:   Optional[bool] = None
    notify_on_medium: Optional[bool] = None


class DeleteResponse(BaseModel):
    deleted: bool


# ── Routes ─────────────────────────────────────────────────────────────────────

@router.get("", response_model=list[dict[str, Any]])
async def list_contacts(
    user_id: str = Query(..., description="User identifier"),
) -> list[dict[str, Any]]:
    """Return all contacts for the given user."""
    return get_contacts(user_id)


@router.post("", response_model=dict[str, Any], status_code=201)
async def create_contact(body: ContactCreate) -> dict[str, Any]:
    """Add a new emergency contact."""
    return add_contact(
        user_id=body.user_id,
        name=body.name,
        phone=body.phone,
        notify_on_high=body.notify_on_high,
        notify_on_medium=body.notify_on_medium,
    )


@router.put("/{contact_id}", response_model=dict[str, Any])
async def patch_contact(
    contact_id: str,
    body: ContactUpdate,
    user_id: str = Query(..., description="User identifier"),
) -> dict[str, Any]:
    """Update an existing contact."""
    updated = update_contact(
        contact_id,
        user_id,
        name=body.name,
        phone=body.phone,
        notify_on_high=body.notify_on_high,
        notify_on_medium=body.notify_on_medium,
    )
    if updated is None:
        raise HTTPException(status_code=404, detail="Contact not found")
    return updated


@router.delete("/{contact_id}", response_model=DeleteResponse)
async def remove_contact(
    contact_id: str,
    user_id: str = Query(..., description="User identifier"),
) -> DeleteResponse:
    """Delete a contact."""
    ok = delete_contact(contact_id, user_id)
    if not ok:
        raise HTTPException(status_code=404, detail="Contact not found")
    return DeleteResponse(deleted=True)
