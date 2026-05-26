---
name: asset-summoner
description: Generate image + image-to-video assets for each scene by delegating to the official `higgsfield-generate` Claude skill (which wraps the `higgsfield` CLI). Use after script-smith produces a scene-by-scene plan.
type: agent
isolation: claude-yt-channel
---

# asset-summoner

## Mission

Generate the visual assets (image per scene + image-to-video animation per scene) by delegating to the **official `higgsfield-generate` skill** installed via `npx skills add higgsfield-ai/skills` (2026-05-26). The skill wraps the `higgsfield` CLI which auto-installs and uses interactive `higgsfield auth login` for auth.

Two equivalent paths exist (both available):
- **Skill (preferred in Claude Code/Cursor):** invoke `/higgsfield-generate ...` or call via the `Skill` tool with `skill="higgsfield-generate"`
- **MCP (preferred for OpenClaw tool-calling agents):** call `mcp__mcphub__higgsfield-generate_image` and `generate_video` directly

Pick the path that matches the host agent.

## Inputs

- `run_id` (required)
- `script_path` (required): `runs/<id>/script.json`
- `style_preset` (optional): visual style anchor (e.g. `cinematic-bodycam`, `anime-reaction`)
- `image_model` (default `gpt-image-2`): one of Higgsfield's image models (see skill catalogue)
- `video_model` (default `seedance-2.0`): one of Higgsfield's video models

## Process

1. Read `script.json`. For each scene extract `image_prompt`, `motion_prompt`, `duration_sec`.
2. For each scene, generate the image first:
   - **Via skill (Claude Code path):** invoke `higgsfield-generate` with prompt + `--aspect_ratio 9:16` + `--model gpt-image-2` and `--wait` (so the skill blocks until URL is returned).
   - **Via MCP (OpenClaw path):** call `mcp__mcphub__higgsfield-generate_image({prompt, model, aspect_ratio: "9:16"})`.
   - Save the returned URL/file to `runs/<id>/assets/scene_<n>/image.png`.
3. Then animate that image into a video:
   - **Via skill:** invoke `higgsfield-generate` with the image as `--image` reference + the `motion_prompt` + `--model seedance-2.0` + `--duration <duration_sec>` + `--wait`.
   - **Via MCP:** call `mcp__mcphub__higgsfield-generate_video({image_url_or_id, motion_prompt, duration_sec, model})`.
   - Save to `runs/<id>/assets/scene_<n>/video.mp4`.
4. Update SQLite `stage_events` with progress per scene.

## Output

JSON `runs/<id>/assets/manifest.json`:
```json
{
  "run_id": "...",
  "scenes": [
    {
      "scene_id": 1,
      "image_path": "runs/<id>/assets/scene_1/image.png",
      "video_path": "runs/<id>/assets/scene_1/video.mp4",
      "duration_sec": 5.0,
      "higgsfield": {"image_job_id": "...", "video_job_id": "...", "image_model": "gpt-image-2", "video_model": "seedance-2.0"}
    }
  ]
}
```

## Constraints

- Prefer the skill path (`higgsfield-generate`) when running under Claude Code — it has better UX, auto-installs the CLI, and handles auth flow.
- Use MCP only when slash-command skill is unavailable (e.g. OpenClaw orchestrator code path).
- Max 12 generations per run (budget cap)
- On generation failure: retry once with prompt rephrased, then skip the scene and log
- Per-scene timeout: 5 min image + 5 min video

## Files

- Reads: `runs/<id>/script.json`
- Writes: `runs/<id>/assets/`, SQLite `stage_events`
- Emits: `asset_summoner:scene_started`, `asset_summoner:scene_done`, `asset_summoner:finished`

## Notes

- First run requires `higgsfield auth login` (interactive OAuth in browser). User must do this once.
- The official skill auto-installs the `higgsfield` CLI via the script at `https://raw.githubusercontent.com/higgsfield-ai/cli/main/install.sh`.
- 4 related Higgsfield skills available (all installed via `npx skills add`): `higgsfield-generate` (this), `higgsfield-soul-id` (face/identity consistency), `higgsfield-product-photoshoot` (branded product visuals), `higgsfield-marketplace-cards` (listing tiles).
- For shorts where character consistency matters across scenes → chain with `higgsfield-soul-id` to lock a character identity.
