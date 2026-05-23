from app.core.database import get_db
from app.services.embedding import get_embedding
from app.services.link_strategy import resolve_links
from app.services.settings_service import get_link_settings


async def upload_note(content: str) -> dict:
    vec = await get_embedding(content)
    db = await get_db()
    settings = await get_link_settings(db)

    cursor = await db.execute(
        "INSERT INTO notes (content, vector) VALUES (?, ?)",
        (content, vec.tobytes()),
    )
    new_id = cursor.lastrowid
    await db.commit()

    note_rows = await db.execute_fetchall("SELECT id, content, vector FROM notes")
    links, strategy = await resolve_links(content, vec, new_id, note_rows, settings)

    for link in links:
        await db.execute(
            """
            INSERT INTO links (source_id, target_id, relation, similarity, reason)
            VALUES (?, ?, ?, ?, ?)
            """,
            (new_id, link.target_id, link.relation, link.similarity, link.reason),
        )
    await db.commit()

    return {
        "id": new_id,
        "links": [link.model_dump() for link in links],
        "strategy": strategy,
    }


async def get_graph() -> dict:
    db = await get_db()

    note_rows = await db.execute_fetchall("SELECT id, content, created_at FROM notes")
    nodes = [
        {"id": r["id"], "content": r["content"], "created_at": r["created_at"]}
        for r in note_rows
    ]

    link_rows = await db.execute_fetchall(
        "SELECT source_id, target_id, relation, similarity, reason FROM links"
    )
    edges = [
        {
            "source": r["source_id"],
            "target": r["target_id"],
            "relation": r["relation"] or "",
            "similarity": r["similarity"],
            "reason": r["reason"] or "",
        }
        for r in link_rows
    ]

    return {"nodes": nodes, "edges": edges}
