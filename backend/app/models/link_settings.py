from enum import Enum
from typing import Literal

from pydantic import BaseModel, Field


class LinkMode(str, Enum):
    HYBRID = "hybrid"
    VECTOR_ONLY = "vector_only"
    CUSTOM_LLM = "custom_llm"


class LlmConfig(BaseModel):
    base_url: str = ""
    api_key: str = ""
    model: str = ""


class LinkSettings(BaseModel):
    mode: LinkMode = LinkMode.HYBRID
    top_k: int = Field(default=8, ge=3, le=20)
    use_default_llm: bool = True
    llm: LlmConfig = Field(default_factory=LlmConfig)


class LinkSettingsResponse(BaseModel):
    mode: LinkMode
    top_k: int
    use_default_llm: bool
    llm_base_url: str
    llm_model: str
    has_llm_api_key: bool
    llm_available: bool


class LinkSettingsUpdate(BaseModel):
    mode: LinkMode
    top_k: int = Field(default=8, ge=3, le=20)
    use_default_llm: bool = True
    llm_base_url: str = ""
    llm_model: str = ""
    llm_api_key: str | None = None


class LlmLinkItem(BaseModel):
    target_id: int
    similarity: float
    relation: str = ""
    reason: str = ""


class LlmLinkResult(BaseModel):
    links: list[LlmLinkItem] = Field(default_factory=list)
