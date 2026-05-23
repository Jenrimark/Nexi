import json

from app.core.config import LLM_API_KEY, LLM_BASE_URL, LLM_MODEL
from app.models.link_settings import LinkMode, LinkSettings, LinkSettingsResponse, LinkSettingsUpdate, LlmConfig

SETTINGS_KEY = "link_settings"


def default_settings() -> LinkSettings:
    return LinkSettings(
        mode=LinkMode.HYBRID,
        top_k=8,
        use_default_llm=True,
        llm=LlmConfig(
            base_url=LLM_BASE_URL,
            api_key="",
            model=LLM_MODEL,
        ),
    )


async def get_link_settings(db) -> LinkSettings:
    row = await db.execute_fetchall(
        "SELECT value FROM app_settings WHERE key = ?", (SETTINGS_KEY,)
    )
    if not row:
        return default_settings()
    try:
        data = json.loads(row[0]["value"])
        return LinkSettings.model_validate(data)
    except Exception:
        return default_settings()


async def save_link_settings(db, settings: LinkSettings) -> None:
    payload = settings.model_dump(mode="json")
    await db.execute(
        """
        INSERT INTO app_settings (key, value) VALUES (?, ?)
        ON CONFLICT(key) DO UPDATE SET value = excluded.value
        """,
        (SETTINGS_KEY, json.dumps(payload, ensure_ascii=False)),
    )
    await db.commit()


async def update_link_settings(db, update: LinkSettingsUpdate) -> LinkSettings:
    current = await get_link_settings(db)
    llm = current.llm.model_copy()
    if update.use_default_llm:
        llm.base_url = LLM_BASE_URL
        llm.model = update.llm_model or LLM_MODEL
        if update.llm_api_key:
            llm.api_key = update.llm_api_key
        elif not llm.api_key:
            llm.api_key = ""
    else:
        llm.base_url = update.llm_base_url
        llm.model = update.llm_model
        if update.llm_api_key is not None and update.llm_api_key != "":
            llm.api_key = update.llm_api_key

    settings = LinkSettings(
        mode=update.mode,
        top_k=update.top_k,
        use_default_llm=update.use_default_llm,
        llm=llm,
    )
    await save_link_settings(db, settings)
    return settings


def to_response(settings: LinkSettings) -> LinkSettingsResponse:
    from app.services.llm_service import is_llm_available

    has_key = bool(
        (settings.use_default_llm and LLM_API_KEY)
        or (not settings.use_default_llm and settings.llm.api_key)
    )
    return LinkSettingsResponse(
        mode=settings.mode,
        top_k=settings.top_k,
        use_default_llm=settings.use_default_llm,
        llm_base_url=LLM_BASE_URL if settings.use_default_llm else settings.llm.base_url,
        llm_model=LLM_MODEL if settings.use_default_llm else settings.llm.model,
        has_llm_api_key=has_key,
        llm_available=is_llm_available(settings),
    )
