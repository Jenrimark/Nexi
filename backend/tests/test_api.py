import os
from pathlib import Path

import pytest
from httpx import ASGITransport, AsyncClient

# Use isolated test database
os.environ["USE_MOCK_EMBEDDING"] = "1"

TEST_DB = Path(__file__).resolve().parent / "test_nexi.db"
if TEST_DB.exists():
    TEST_DB.unlink()

from app.core import config  # noqa: E402
from app.core.database import close_db, get_db  # noqa: E402

config.DB_PATH = TEST_DB

from app.main import app  # noqa: E402


@pytest.fixture(autouse=True)
async def reset_db():
    db = await get_db()
    await db.execute("DELETE FROM links")
    await db.execute("DELETE FROM notes")
    await db.execute("DELETE FROM app_settings")
    await db.commit()
    yield
    await close_db()
    if TEST_DB.exists():
        TEST_DB.unlink()


@pytest.fixture
async def client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


@pytest.mark.asyncio
async def test_health(client):
    resp = await client.get("/api/health")
    assert resp.status_code == 200
    assert resp.json() == {"status": "ok"}


@pytest.mark.asyncio
async def test_upload_and_graph(client):
    r1 = await client.post("/api/upload_note", json={"content": "鸿蒙开发笔记第一条"})
    assert r1.status_code == 200
    data1 = r1.json()
    assert "id" in data1
    assert data1["links"] == []

    r2 = await client.post("/api/upload_note", json={"content": "鸿蒙开发笔记第二条"})
    assert r2.status_code == 200

    graph = await client.get("/api/get_graph")
    assert graph.status_code == 200
    body = graph.json()
    assert len(body["nodes"]) == 2
    assert isinstance(body["edges"], list)


@pytest.mark.asyncio
async def test_link_settings(client):
    resp = await client.get("/api/settings/link")
    assert resp.status_code == 200
    body = resp.json()
    assert body["mode"] in ("hybrid", "vector_only", "custom_llm")
    assert "top_k" in body
    assert "llm_available" in body


@pytest.mark.asyncio
async def test_upload_returns_relation_fields(client):
    await client.post("/api/upload_note", json={"content": "人工智能与知识图谱"})
    r2 = await client.post("/api/upload_note", json={"content": "人工智能知识图谱应用"})
    assert r2.status_code == 200
    data = r2.json()
    assert "strategy" in data
    if data["links"]:
        link = data["links"][0]
        assert "relation" in link
        assert "reason" in link


@pytest.mark.asyncio
async def test_similar_notes_create_link(client):
    await client.post("/api/upload_note", json={"content": "人工智能与知识图谱"})
    r2 = await client.post("/api/upload_note", json={"content": "人工智能知识图谱应用"})
    links = r2.json()["links"]
    assert len(links) >= 1

    graph = await client.get("/api/get_graph")
    assert len(graph.json()["edges"]) >= 1
