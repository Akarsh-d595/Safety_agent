"""
POST /analyze  — run emergency detection on user text.
"""
from fastapi import APIRouter
from app.models import AnalyzeRequest, AnalyzeResponse
from app.detection import analyze_text

router = APIRouter(prefix="/analyze", tags=["Detection"])


@router.post("", response_model=AnalyzeResponse)
async def analyze(body: AnalyzeRequest) -> AnalyzeResponse:
    """
    Analyse the supplied text and return a danger assessment.

    - **danger**: whether any danger signal was found
    - **level**: none / low / medium / high
    - **reason**: human-readable explanation
    - **trigger**: true only when level == high (auto-trigger emergency)
    """
    return analyze_text(body.text)
