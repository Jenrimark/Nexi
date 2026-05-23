import aiosqlite
from app.core import config

_db: aiosqlite.Connection | None = None


async def get_db() -> aiosqlite.Connection:
    global _db
    if _db is None:
        _db = await aiosqlite.connect(str(config.DB_PATH))
        _db.row_factory = aiosqlite.Row
        await _init_tables(_db)
        await _migrate(_db)
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
            similarity  REAL    NOT NULL,
            reason      TEXT    DEFAULT ''
        );

        CREATE TABLE IF NOT EXISTS app_settings (
            key   TEXT PRIMARY KEY,
            value TEXT NOT NULL
        );

        CREATE INDEX IF NOT EXISTS idx_links_source ON links(source_id);
        CREATE INDEX IF NOT EXISTS idx_links_target ON links(target_id);
    """)
    await db.commit()


async def _migrate(db: aiosqlite.Connection):
    cols = await db.execute_fetchall("PRAGMA table_info(links)")
    col_names = {row[1] for row in cols}
    if "reason" not in col_names:
        await db.execute("ALTER TABLE links ADD COLUMN reason TEXT DEFAULT ''")
        await db.commit()
