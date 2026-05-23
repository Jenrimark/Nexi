#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

if [ ! -d ".venv" ]; then
  python3 -m venv .venv
fi
source .venv/bin/activate
pip install -r requirements.txt -q

export USE_MOCK_EMBEDDING="${USE_MOCK_EMBEDDING:-1}"
export SIMILARITY_THRESHOLD="${SIMILARITY_THRESHOLD:-0.45}"
if [ -f ".env" ]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
fi
echo "Starting 灵绪 Nexi API on http://0.0.0.0:8000 (mock embedding: ${USE_MOCK_EMBEDDING})"
exec uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
