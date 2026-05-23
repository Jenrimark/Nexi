import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent.parent
DATA_DIR = BASE_DIR / "data"
DATA_DIR.mkdir(exist_ok=True)

DB_PATH = DATA_DIR / "nexi.db"

OLLAMA_BASE_URL = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "bge-m3")
USE_MOCK_EMBEDDING = os.getenv("USE_MOCK_EMBEDDING", "").lower() in ("1", "true", "yes")

SIMILARITY_THRESHOLD = float(os.getenv("SIMILARITY_THRESHOLD", "0.75"))
MOCK_SIMILARITY_THRESHOLD = float(os.getenv("MOCK_SIMILARITY_THRESHOLD", "0.45"))
MAX_GRAPH_NODES = 300

LLM_BASE_URL = os.getenv("LLM_BASE_URL", "https://api.deepseek.com")
LLM_API_KEY = os.getenv("LLM_API_KEY", "")
LLM_MODEL = os.getenv("LLM_MODEL", "deepseek-chat")
LLM_TIMEOUT = float(os.getenv("LLM_TIMEOUT", "30"))


def effective_similarity_threshold() -> float:
    return MOCK_SIMILARITY_THRESHOLD if USE_MOCK_EMBEDDING else SIMILARITY_THRESHOLD
