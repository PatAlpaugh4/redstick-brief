---
description: One-time setup (or update) of Cam's daily 6 AM cloud routine that emails the brief every weekday morning
---

Set up the scheduled cloud routine that emails Cam the pre-meeting brief every weekday at 6 AM Cam-local time. This command is **idempotent** — first run creates the routine, subsequent runs detect and update the existing one rather than creating duplicates.

Steps:

1. **Pre-flight: confirm required MCP connectors are attached** to Cam's account. Check for tool availability of:
   - Gmail MCP (search threads + send email)
   - Google Calendar MCP (read today's events)
   - Notion MCP (read prior-call notes from the `Meeting Notes` database — Otter pushes here via Zapier)

   If any are missing: respond with the missing list + this URL `https://claude.ai/customize/connectors` and stop. Example: `"Missing connectors: Notion. Connect at https://claude.ai/customize/connectors and re-run /setup-daily-brief."`

2. **Confirm config with Cam.** Use `AskUserQuestion` to confirm (defaults shown):
   - Recipient email (default `cam@redstickvc.com`)
   - Time zone (default `America/Chicago`)
   - Note: cron `0 11 * * 1-5` UTC = 6 AM CDT during DST. In winter (CST), use `0 12 * * 1-5`. Use the current date to pick the correct one for today.

3. **Read the canonical routine prompt** from the installed plugin's `routines/cam.md`. Strip the markdown wrapper and pull just the prompt body (the section under `## Prompt (paste verbatim)`).

4. **Idempotency check.** Use the `/schedule` skill with `action: "list"` to enumerate routines on Cam's account. Look for one named `Pre-meeting brief — daily 6 AM`:
   - **Found:** call `/schedule` with `action: "update"`, `trigger_id: <found-id>`, and the new `body` containing the up-to-date `cron_expression`, `name`, `enabled: true`, `job_config` (model, repo source, allowed tools, prompt), and `mcp_connections` (Gmail, Calendar, Notion). Tell Cam: `"Updated existing routine. Next run: <next_run_at>."`
   - **Not found:** call `/schedule` with `action: "create"` and the same body shape. Tell Cam: `"Created new routine. Next run: <next_run_at>."`

5. **Repo source.** Hardcode `https://github.com/PatAlpaugh4/redstick-brief` as the routine's git source. The routine clones `main` on every run, so future prompt edits ship via `git push` — no need to re-run this command for voice/format tweaks.

6. **Allowed tools** for the routine: `Read`, `Glob`, `Grep`, `WebSearch`. No file writes, no Bash.

7. **Model**: `claude-sonnet-4-6` (default). Override only if Cam explicitly asks for Opus.

8. **Output to Cam:**
   ```
   ✓ Routine ready: <name>
   ID: <trigger_id>
   Next run: <next_run_at> (your local time)
   Manage at: https://claude.ai/code/routines/<trigger_id>

   Future prompt/voice/template edits ship via git push to PatAlpaugh4/redstick-brief — no need to re-run this command.
   ```

## What this command does NOT do

- Does NOT set up the Otter→Zapier→Notion pipeline. That's a one-time manual step Patrick walks Cam through; see `SHIP-EMAIL.md`.
- Does NOT connect MCP connectors. Cam attaches those at `https://claude.ai/customize/connectors`.
- Does NOT modify the plugin source. To change the brief's voice or format, edit `references/synthesis-prompt.md` (or other reference files) and `git push`.

## Trigger phrases

`/setup-daily-brief`, "set up the daily brief", "wire up the morning email", "schedule the brief routine", "create my morning brief routine".
