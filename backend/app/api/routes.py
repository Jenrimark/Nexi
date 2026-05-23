from fastapi import APIRouter
from pydantic import BaseModel

from app.services.graph import get_graph, upload_note

router = APIRouter()


class UploadRequest(BaseModel):
    content: str


@router.post("/upload_note")
async def upload(req: UploadRequest):
    result = await upload_note(req.content)
    return result


@router.get("/get_graph")
async def graph():
    result = await get_graph()
    return result


@router.get("/health")
async def health():
    return {"status": "ok"}
