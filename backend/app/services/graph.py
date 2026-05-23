import numpy as np

from app.core.config import effective_similarity_threshold
from app.core.database import get_db
from app.services.embedding import cosine_similarity, get_embedding


async def upload_note(content: str) -> dict:
    vec = await get_embedding(content)
    db = await get_db()
    threshold = effective_similarity_threshold()

    cursor = await db.execute(
        "INSERT INTO notes (content, vector) VALUES (?, ?)",
        (content, vec.tobytes()),
    )
    new_id = cursor.lastrowid
    await db.commit()

    rows = await db.execute_fetchall("SELECT id, vector FROM notes WHERE id != ?", (new_id,))
    links = []
    for row in rows:
        existing_vec = np.frombuffer(row["vector"], dtype=np.float32)
        sim = cosine_similarity(vec, existing_vec)
        if sim >= threshold:
            links.append({"target_id": row["id"], "similarity": round(sim, 4)})

    for link in links:
        await db.execute(
            "INSERT INTO links (source_id, target_id, relation, similarity) VALUES (?, ?, ?, ?)",
            (new_id, link["target_id"], "", link["similarity"]),
        )
    await db.commit()

    return {"id": new_id, "links": links}


async def get_graph() -> dict:
    db = await get_db()

    note_rows = await db.execute_fetchall("SELECT id, content, created_at FROM notes")
    nodes = [
        {"id": r["id"], "content": r["content"], "created_at": r["created_at"]}
        for r in note_rows
    ]

    link_rows = await db.execute_fetchall(
        "SELECT source_id, target_id, relation, similarity FROM links"
    )
    edges = [
        {
            "source": r["source_id"],
            "target": r["target_id"],
            "relation": r["relation"] or "",
            "similarity": r["similarity"],
        }
        for r in link_rows
    ]

    return {"nodes": nodes, "edges": edges}
