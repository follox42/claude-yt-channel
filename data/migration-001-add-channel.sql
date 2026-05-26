-- Migration 001 — add channel_slug to scope runs/ideas/uploads/metrics per channel
-- 2026-05-26: identity isolation

ALTER TABLE runs ADD COLUMN channel_slug TEXT;
ALTER TABLE ideas ADD COLUMN channel_slug TEXT;
ALTER TABLE uploads ADD COLUMN channel_slug TEXT;
ALTER TABLE metrics ADD COLUMN channel_slug TEXT;

-- Backfill existing rows with default channel
UPDATE runs SET channel_slug = 'anime-reactions' WHERE channel_slug IS NULL;
UPDATE ideas SET channel_slug = 'anime-reactions' WHERE channel_slug IS NULL;
UPDATE uploads SET channel_slug = 'anime-reactions' WHERE channel_slug IS NULL;
UPDATE metrics SET channel_slug = 'anime-reactions' WHERE channel_slug IS NULL;

CREATE INDEX IF NOT EXISTS idx_runs_channel ON runs(channel_slug);
CREATE INDEX IF NOT EXISTS idx_ideas_channel ON ideas(channel_slug);
CREATE INDEX IF NOT EXISTS idx_uploads_channel ON uploads(channel_slug);
CREATE INDEX IF NOT EXISTS idx_metrics_channel ON metrics(channel_slug);
