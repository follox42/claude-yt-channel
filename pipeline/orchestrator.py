#!/usr/bin/env python3
"""claude-yt-channel pipeline orchestrator.

Runs the 9-stage pipeline (niche-radar -> sentry) by invoking Claude Code agents
sequentially. Stage events are persisted in SQLite for the dashboard at :3737.

Usage:
    python orchestrator.py --niche bodycam --mode mvp
    python orchestrator.py --niche bodycam --mode mvp --skip niche_radar viral_decoder
    python orchestrator.py --resume <run_id>
    python orchestrator.py --status
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import sqlite3
import subprocess
import sys
import time
import uuid
from pathlib import Path
from typing import Any

PROJECT_ROOT = Path(__file__).resolve().parents[1]
DB_PATH = PROJECT_ROOT / "data" / "runs.db"
RUNS_DIR = PROJECT_ROOT / "runs"
SCHEMA_PATH = PROJECT_ROOT / "data" / "schema.sql"

STAGES = [
    "niche_radar",
    "viral_decoder",
    "idea_forge",
    "script_smith",
    "asset_summoner",
    "render_engine",
    "thumb_craft",
    "uploader",
    "sentry",
]

MVP_STAGES = STAGES[:7]  # stop before uploader for MVP (manual upload)


def db_conn() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


def init_db() -> None:
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    schema = SCHEMA_PATH.read_text()
    with db_conn() as conn:
        conn.executescript(schema)
    print(f"[init] DB initialized at {DB_PATH}")


def create_run(niche_slug: str, idea_id: int | None = None) -> str:
    run_id = f"{niche_slug}-{dt.datetime.now().strftime('%Y%m%d-%H%M%S')}-{uuid.uuid4().hex[:6]}"
    run_dir = RUNS_DIR / run_id
    run_dir.mkdir(parents=True, exist_ok=True)
    with db_conn() as conn:
        conn.execute(
            """INSERT INTO runs (id, idea_id, niche_slug, state, current_stage, output_path)
               VALUES (?, ?, ?, 'pending', ?, ?)""",
            (run_id, idea_id, niche_slug, STAGES[0], str(run_dir)),
        )
    print(f"[run] created {run_id} at {run_dir}")
    return run_id


def log_event(run_id: str, stage: str, event: str, payload: dict[str, Any] | None = None) -> None:
    with db_conn() as conn:
        conn.execute(
            "INSERT INTO stage_events (run_id, stage, event, payload) VALUES (?, ?, ?, ?)",
            (run_id, stage, event, json.dumps(payload) if payload else None),
        )


def set_run_state(run_id: str, **fields: Any) -> None:
    keys = ", ".join(f"{k}=?" for k in fields)
    with db_conn() as conn:
        conn.execute(f"UPDATE runs SET {keys} WHERE id=?", (*fields.values(), run_id))


def invoke_agent(stage: str, run_id: str, args: dict[str, Any]) -> dict[str, Any]:
    """Invoke a Claude Code agent for the given stage.

    For MVP, this is a placeholder that just writes a stub artifact. Real
    invocation will spawn a Claude Code Agent via the SDK or shell out to
    `claude -p "use the {stage} skill with args ..."`.
    """
    run_dir = RUNS_DIR / run_id
    stage_artifact = run_dir / f"{stage}.json"

    log_event(run_id, stage, "started", args)
    print(f"[{stage}] starting (run={run_id})")

    # TODO: real Claude Code agent invocation. For now, write a stub.
    stub_payload = {
        "stage": stage,
        "run_id": run_id,
        "args": args,
        "stub": True,
        "ts": dt.datetime.now().isoformat(),
    }
    stage_artifact.write_text(json.dumps(stub_payload, indent=2))

    log_event(run_id, stage, "finished", {"artifact": str(stage_artifact)})
    print(f"[{stage}] done -> {stage_artifact}")
    return stub_payload


def run_pipeline(
    niche_slug: str,
    mode: str = "mvp",
    skip: list[str] | None = None,
    resume_id: str | None = None,
) -> str:
    stages = MVP_STAGES if mode == "mvp" else STAGES
    skip = set(skip or [])

    if resume_id:
        run_id = resume_id
        # Determine next stage from current_stage
        with db_conn() as conn:
            row = conn.execute("SELECT current_stage FROM runs WHERE id=?", (run_id,)).fetchone()
        if not row:
            sys.exit(f"resume failed: run {run_id} not found")
        try:
            start_idx = stages.index(row["current_stage"])
        except ValueError:
            start_idx = 0
        active_stages = stages[start_idx:]
    else:
        run_id = create_run(niche_slug)
        active_stages = stages

    set_run_state(run_id, state="running")

    for stage in active_stages:
        if stage in skip:
            print(f"[{stage}] SKIPPED")
            continue
        set_run_state(run_id, current_stage=stage)
        try:
            invoke_agent(stage, run_id, {"niche_slug": niche_slug})
        except Exception as e:
            set_run_state(run_id, state="failed", error=str(e), finished_at=dt.datetime.now().isoformat())
            log_event(run_id, stage, "error", {"error": str(e)})
            print(f"[{stage}] FAILED: {e}", file=sys.stderr)
            return run_id

    set_run_state(run_id, state="done", finished_at=dt.datetime.now().isoformat())
    print(f"[pipeline] done: {run_id}")
    return run_id


def show_status() -> None:
    with db_conn() as conn:
        rows = conn.execute(
            "SELECT id, niche_slug, state, current_stage, cost_eur, started_at, finished_at FROM runs ORDER BY started_at DESC LIMIT 20"
        ).fetchall()
    if not rows:
        print("no runs yet")
        return
    print(f"{'RUN_ID':<40} {'NICHE':<20} {'STATE':<10} {'STAGE':<20} {'COST':<8} {'STARTED'}")
    for r in rows:
        print(f"{r['id']:<40} {r['niche_slug'] or '-':<20} {r['state']:<10} {r['current_stage'] or '-':<20} {r['cost_eur'] or 0:<8.2f} {r['started_at']}")


def main() -> None:
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=False)

    ap.add_argument("--niche", help="niche slug to run (required for new runs)")
    ap.add_argument("--mode", default="mvp", choices=["mvp", "full"], help="mvp=stop before uploader, full=all 9 stages")
    ap.add_argument("--skip", nargs="*", default=[], help="stages to skip")
    ap.add_argument("--resume", help="run_id to resume")
    ap.add_argument("--status", action="store_true", help="show recent runs")
    ap.add_argument("--init-db", action="store_true", help="initialize DB schema")

    args = ap.parse_args()

    if args.init_db:
        init_db()
        return

    if args.status:
        show_status()
        return

    if not args.niche and not args.resume:
        ap.error("--niche or --resume required")

    if not DB_PATH.exists():
        init_db()

    run_id = run_pipeline(
        niche_slug=args.niche or "resumed",
        mode=args.mode,
        skip=args.skip,
        resume_id=args.resume,
    )
    print(f"\nrun_id={run_id}")


if __name__ == "__main__":
    main()
