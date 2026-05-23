from fastapi import APIRouter
from pydantic import BaseModel

from app.core.database import get_db
from app.models.link_settings import LinkSettingsUpdate
from app.services.graph import get_graph, upload_note
from app.services.settings_service import get_link_settings, to_response, update_link_settings

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


@router.get("/settings/link")
async def get_link_settings_api():
    db = await get_db()
    settings = await get_link_settings(db)
    return to_response(settings)


@router.put("/settings/link")
async def put_link_settings_api(update: LinkSettingsUpdate):
    db = await get_db()
    settings = await update_link_settings(db, update)
    return to_response(settings)
