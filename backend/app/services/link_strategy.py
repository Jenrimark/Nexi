import numpy as np

from app.core.config import effective_similarity_threshold
from app.models.link_settings import LinkMode, LinkSettings, LlmLinkItem
from app.services.embedding import cosine_similarity
from app.services.llm_service import infer_links_with_llm, resolve_llm_config


class CandidateNote:
    def __init__(self, note_id: int, content: str, similarity: float):
        self.id = note_id
        self.content = content
        self.similarity = similarity


async def find_top_k_candidates(
    new_vec: np.ndarray,
    new_id: int,
    rows: list,
    top_k: int,
) -> list[CandidateNote]:
    scored: list[CandidateNote] = []
    for row in rows:
        if row["id"] == new_id:
            continue
        existing_vec = np.frombuffer(row["vector"], dtype=np.float32)
        sim = cosine_similarity(new_vec, existing_vec)
        scored.append(CandidateNote(row["id"], row["content"], sim))
    scored.sort(key=lambda item: item.similarity, reverse=True)
    return scored[:top_k]


def vector_only_links(candidates: list[CandidateNote], threshold: float) -> list[LlmLinkItem]:
    links: list[LlmLinkItem] = []
    for item in candidates:
        if item.similarity < threshold:
            continue
        pct = int(item.similarity * 100)
        links.append(
            LlmLinkItem(
                target_id=item.id,
                similarity=round(item.similarity, 4),
                relation="语义相似",
                reason=f"向量相似度 {pct}%，主题内容相近",
            )
        )
    return links


def candidates_to_dict(candidates: list[CandidateNote]) -> list[dict]:
    return [
        {"id": c.id, "content": c.content, "similarity": round(c.similarity, 4)}
        for c in candidates
    ]


async def resolve_links(
    new_content: str,
    new_vec: np.ndarray,
    new_id: int,
    note_rows: list,
    settings: LinkSettings,
) -> tuple[list[LlmLinkItem], str]:
    """Returns (links, strategy_used)."""
    threshold = effective_similarity_threshold()
    candidates = await find_top_k_candidates(new_vec, new_id, note_rows, settings.top_k)
    candidate_dicts = candidates_to_dict(candidates)

    if settings.mode == LinkMode.VECTOR_ONLY:
        return vector_only_links(candidates, threshold), "vector_only"

    llm = resolve_llm_config(settings)
    if llm is not None:
        llm_result = await infer_links_with_llm(new_content, candidate_dicts, llm)
        if llm_result is not None:
            return llm_result.links, "llm"

    # Fallback when LLM unavailable or failed
    links = vector_only_links(candidates, threshold)
    return links, "vector_fallback"
