import json
import logging

import httpx

from app.core.config import LLM_API_KEY, LLM_BASE_URL, LLM_MODEL, LLM_TIMEOUT
from app.models.link_settings import LinkMode, LinkSettings, LlmConfig, LlmLinkItem, LlmLinkResult

logger = logging.getLogger(__name__)

SYSTEM_PROMPT = (
    "你是知识图谱关联助手。根据新笔记与候选历史笔记，判断哪些候选与新笔记存在有意义的语义关联。"
    "只返回 JSON，不要 markdown 代码块。"
)


def chat_completions_url(base_url: str) -> str:
    base = base_url.rstrip("/")
    if base.endswith("/v1"):
        return f"{base}/chat/completions"
    return f"{base}/v1/chat/completions"


def _build_user_prompt(new_content: str, candidates: list[dict]) -> str:
    lines = [f'新笔记: "{new_content}"', "", "候选历史笔记:"]
    if not candidates:
        lines.append("（无候选）")
    else:
        for item in candidates:
            lines.append(f'- id={item["id"]}: "{item["content"]}" (向量相似度 {item["similarity"]:.2f})')
    lines.extend(
        [
            "",
            "请输出 JSON，格式如下:",
            '{"links":[{"target_id":1,"similarity":0.85,"relation":"关联关键词","reason":"一句话说明为何相关"}]}',
            "规则: links 最多 5 条；只包含确实相关的候选；similarity 取 0~1；无关联则 links 为空数组。",
        ]
    )
    return "\n".join(lines)


def resolve_llm_config(settings: LinkSettings) -> LlmConfig | None:
    if settings.mode == LinkMode.VECTOR_ONLY:
        return None
    if settings.mode == LinkMode.CUSTOM_LLM or not settings.use_default_llm:
        custom = settings.llm
        if not custom.api_key or not custom.base_url or not custom.model:
            return None
        return custom
    if not LLM_API_KEY:
        return None
    return LlmConfig(base_url=LLM_BASE_URL, api_key=LLM_API_KEY, model=LLM_MODEL)


def is_llm_available(settings: LinkSettings) -> bool:
    return resolve_llm_config(settings) is not None


async def infer_links_with_llm(
    new_content: str,
    candidates: list[dict],
    llm: LlmConfig,
) -> LlmLinkResult | None:
    if not candidates:
        logger.info("LLM skip: no vector candidates for note")
        return LlmLinkResult(links=[])

    url = chat_completions_url(llm.base_url)
    messages = [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": _build_user_prompt(new_content, candidates)},
    ]
    headers = {
        "Authorization": f"Bearer {llm.api_key}",
        "Content-Type": "application/json",
    }

    payloads = [
        {"model": llm.model, "messages": messages, "temperature": 0.2, "response_format": {"type": "json_object"}},
        {"model": llm.model, "messages": messages, "temperature": 0.2},
    ]

    try:
        async with httpx.AsyncClient(timeout=LLM_TIMEOUT) as client:
            last_error: Exception | None = None
            for payload in payloads:
                try:
                    resp = await client.post(url, json=payload, headers=headers)
                    resp.raise_for_status()
                    body = resp.json()
                    content = body["choices"][0]["message"]["content"]
                    parsed = _parse_llm_json(content, candidates)
                    if parsed is not None:
                        logger.info("LLM linked %d notes via %s", len(parsed.links), url)
                        return parsed
                    last_error = ValueError("LLM JSON parse failed")
                except Exception as exc:
                    last_error = exc
                    logger.warning("LLM attempt failed (%s): %s", url, exc)
            if last_error:
                raise last_error
    except Exception as exc:
        logger.warning("LLM infer failed: %s", exc)
        return None
    return None


def _parse_llm_json(content: str, candidates: list[dict]) -> LlmLinkResult | None:
    try:
        data = json.loads(content.strip())
    except json.JSONDecodeError:
        start = content.find("{")
        end = content.rfind("}")
        if start < 0 or end <= start:
            return None
        try:
            data = json.loads(content[start : end + 1])
        except json.JSONDecodeError:
            return None

    valid_ids = {c["id"] for c in candidates}
    links: list[LlmLinkItem] = []
    for raw in data.get("links", []):
        target_id = int(raw.get("target_id", 0))
        if target_id not in valid_ids:
            continue
        sim = float(raw.get("similarity", 0.5))
        sim = max(0.0, min(1.0, sim))
        links.append(
            LlmLinkItem(
                target_id=target_id,
                similarity=round(sim, 4),
                relation=str(raw.get("relation", "") or "语义关联"),
                reason=str(raw.get("reason", "") or ""),
            )
        )
    return LlmLinkResult(links=links)
