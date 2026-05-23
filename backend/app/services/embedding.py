import hashlib
import logging

import httpx
import numpy as np

from app.core.config import OLLAMA_BASE_URL, OLLAMA_MODEL, USE_MOCK_EMBEDDING

logger = logging.getLogger(__name__)

DIMENSION = 1024


def mock_embedding(text: str) -> np.ndarray:
    """Deterministic n-gram bag embedding for dev when Ollama is unavailable."""
    vec = np.zeros(DIMENSION, dtype=np.float32)
    normalized = text.strip().lower()
    if not normalized:
        vec[0] = 1.0
        return vec

    for i in range(len(normalized) - 2):
        idx = int(hashlib.md5(normalized[i : i + 3].encode()).hexdigest(), 16) % DIMENSION
        vec[idx] += 1.0

    norm = np.linalg.norm(vec)
    if norm == 0:
        vec[0] = 1.0
        return vec
    return vec / norm


async def get_embedding(text: str) -> np.ndarray:
    if USE_MOCK_EMBEDDING:
        return mock_embedding(text)

    try:
        async with httpx.AsyncClient(timeout=30) as client:
            resp = await client.post(
                f"{OLLAMA_BASE_URL}/api/embed",
                json={"model": OLLAMA_MODEL, "input": text},
            )
            resp.raise_for_status()
            vec = resp.json()["embeddings"][0]
            return np.array(vec, dtype=np.float32)
    except (httpx.ConnectError, httpx.TimeoutException, httpx.HTTPStatusError) as exc:
        logger.warning("Ollama unavailable (%s), falling back to mock embedding", exc)
        return mock_embedding(text)


def cosine_similarity(a: np.ndarray, b: np.ndarray) -> float:
    dot = np.dot(a, b)
    norm = np.linalg.norm(a) * np.linalg.norm(b)
    if norm == 0:
        return 0.0
    return float(dot / norm)
