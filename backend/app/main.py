"""
Emergency Safety System — FastAPI backend entry point.

Run with:
    uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

Interactive docs available at:
    http://localhost:8000/docs
"""
from __future__ import annotations

import os
from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routers import analyze, alert, incidents, health, contacts

# Load .env (no-op if file doesn't exist)
load_dotenv()

# ── App factory ────────────────────────────────────────────────────────────────

app = FastAPI(
    title="Emergency Safety API",
    description=(
        "Backend for the AI Emergency Safety System mobile app.\n\n"
        "Provides emergency detection, SMS alerting, and incident logging."
    ),
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# ── CORS ───────────────────────────────────────────────────────────────────────

_raw_origins = os.getenv("ALLOWED_ORIGINS", "*")
allowed_origins = (
    ["*"] if _raw_origins.strip() == "*"
    else [o.strip() for o in _raw_origins.split(",") if o.strip()]
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Routers ────────────────────────────────────────────────────────────────────

app.include_router(health.router)
app.include_router(analyze.router)
app.include_router(alert.router)
app.include_router(incidents.router)
app.include_router(contacts.router)
