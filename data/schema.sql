-- youtube-short-viral state store (SQLite)

CREATE TABLE IF NOT EXISTS niches (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    slug        TEXT UNIQUE NOT NULL,
    name        TEXT NOT NULL,
    rpm_estimate REAL,
    competitor_channels TEXT,        -- JSON array
    formula_json TEXT,                -- decoded narrative structure
    status      TEXT DEFAULT 'active', -- active | paused | dead
    created_at  TEXT DEFAULT (datetime('now')),
    updated_at  TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS ideas (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    niche_id    INTEGER NOT NULL REFERENCES niches(id),
    title       TEXT NOT NULL,
    hook        TEXT,
    angle       TEXT,
    score       REAL,                 -- 0-100
    status      TEXT DEFAULT 'queued', -- queued | scripting | producing | rendered | uploaded | discarded
    created_at  TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS runs (
    id          TEXT PRIMARY KEY,     -- slug-YYYYMMDD-HHMMSS
    idea_id     INTEGER REFERENCES ideas(id),
    niche_slug  TEXT,
    state       TEXT DEFAULT 'pending', -- pending | running | done | failed
    current_stage TEXT,              -- niche_radar | viral_decoder | idea_forge | script_smith | asset_summoner | render_engine | thumb_craft | uploader | sentry
    cost_eur    REAL DEFAULT 0,
    output_path TEXT,                 -- runs/<id>/
    error       TEXT,
    started_at  TEXT DEFAULT (datetime('now')),
    finished_at TEXT
);

CREATE TABLE IF NOT EXISTS stage_events (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    run_id      TEXT NOT NULL REFERENCES runs(id),
    stage       TEXT NOT NULL,
    event       TEXT NOT NULL,        -- started | finished | error | metric
    payload     TEXT,                 -- JSON
    ts          TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS uploads (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    run_id      TEXT NOT NULL REFERENCES runs(id),
    youtube_video_id TEXT,
    channel_name TEXT,
    title       TEXT,
    description TEXT,
    tags        TEXT,                 -- JSON array
    thumbnail_path TEXT,
    uploaded_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS metrics (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    upload_id   INTEGER NOT NULL REFERENCES uploads(id),
    views       INTEGER,
    likes       INTEGER,
    comments    INTEGER,
    avg_view_pct REAL,
    captured_at TEXT DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_runs_state ON runs(state);
CREATE INDEX IF NOT EXISTS idx_ideas_status ON ideas(status);
CREATE INDEX IF NOT EXISTS idx_stage_events_run ON stage_events(run_id);
