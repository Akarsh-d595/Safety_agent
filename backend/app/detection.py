"""
Emergency detection engine.
Analyses text and returns a structured danger assessment.
"""
from __future__ import annotations

from app.models import AnalyzeResponse, DangerLevel

# ── Signal dictionaries ────────────────────────────────────────────────────────

_HIGH_SIGNALS: list[str] = [
    "save me",
    "help me",
    "i'm being attacked",
    "i am being attacked",
    "i'm being hurt",
    "i am being hurt",
    "someone is hurting me",
    "call 911",
    "call the police",
    "i'm going to die",
    "i am going to die",
    "he has a weapon",
    "she has a weapon",
    "they have a gun",
    "they have a knife",
    "he has a knife",
    "he has a gun",
    "she has a gun",
    "she has a knife",
    "i am in danger",
    "i'm in danger",
    "please help me",
    "somebody help",
    "someone help",
]

_MEDIUM_SIGNALS: list[str] = [
    "help",
    "emergency",
    "i need help",
    "someone is following me",
    "i'm being followed",
    "i am being followed",
    "i think someone is following me",
    "i feel unsafe",
    "i'm scared",
    "i am scared",
    "i'm not safe",
    "i am not safe",
    "this person won't leave me alone",
    "i'm being stalked",
    "i am being stalked",
]

_LOW_SIGNALS: list[str] = [
    "i'm a little worried",
    "i am a little worried",
    "something feels wrong",
    "this seems suspicious",
    "i'm not sure if i'm safe",
    "i am not sure if i am safe",
    "i feel uncomfortable",
    "something is off",
]


# ── Public API ─────────────────────────────────────────────────────────────────

def analyze_text(text: str) -> AnalyzeResponse:
    """
    Analyse *text* and return an :class:`AnalyzeResponse`.

    Matching is case-insensitive and substring-based so partial phrases
    (e.g. "please help me now") still trigger the correct tier.
    """
    normalised = text.lower().strip()

    for signal in _HIGH_SIGNALS:
        if signal in normalised:
            return AnalyzeResponse(
                danger=True,
                level=DangerLevel.high,
                reason=f'High-danger phrase detected: "{signal}"',
                trigger=True,
            )

    for signal in _MEDIUM_SIGNALS:
        if signal in normalised:
            return AnalyzeResponse(
                danger=True,
                level=DangerLevel.medium,
                reason=f'Danger phrase detected: "{signal}"',
                trigger=False,
            )

    for signal in _LOW_SIGNALS:
        if signal in normalised:
            return AnalyzeResponse(
                danger=True,
                level=DangerLevel.low,
                reason=f'Potential concern detected: "{signal}"',
                trigger=False,
            )

    return AnalyzeResponse(
        danger=False,
        level=DangerLevel.none,
        reason="No danger signals detected.",
        trigger=False,
    )
