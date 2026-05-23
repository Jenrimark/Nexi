import aiosqlite
from app.core import config

_db: aiosqlite.Connection | None = None


async def get_db() -> aiosqlite.Connection:
    global _db
    if _db is None:
        _db = await aiosqlite.connect(str(config.DB_PATH))
        _db.row_factory = aiosqlite.Row
        await _init_tables(_db)
    return _db


async def close_db():
    global _db
    if _db is not None:
        await _db.close()
        _db = None


async def _init_tables(db: aiosqlite.Connection):
    await db.executescript("""
        CREATE TABLE IF NOT EXISTS notes (
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            content    TEXT    NOT NULL,
            vector     BLOB,
            created_at TEXT    NOT NULL DEFAULT (datetime('now'))
        );

        CREATE TABLE IF NOT EXISTS links (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            source_id   INTEGER NOT NULL REFERENCES notes(id) ON DELETE CASCADE,
            target_id   INTEGER NOT NULL REFERENCES notes(id) ON DELETE CASCADE,
            relation    TEXT,
            similarity  REAL    NOT NULL
        );

        CREATE INDEX IF NOT EXISTS idx_links_source ON links(source_id);
        CREATE INDEX IF NOT EXISTS idx_links_target ON links(target_id);
    """)
    await db.commit()
