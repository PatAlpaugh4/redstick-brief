# Routines — daily 6 AM brief, scheduled cloud agent

The brief has two delivery modes that share the same skill files:

| Mode | Trigger | How |
|---|---|---|
| **On-demand** | Cam types `/brief` in Cowork | The plugin's `meeting-brief` skill runs in his Cowork session, brief renders inline |
| **Daily 6 AM email** | Cron `0 11 * * 1-5` UTC (= 6 AM CDT) | A scheduled cloud routine on Cam's account clones this repo, runs the same logic, emails him at `cam@redstickvc.com` |

This folder holds the production-ready prompt for the daily routine.

## Files

- `cam.md` — production prompt + routine config for Cam's account. Paste into a new routine at https://claude.ai/code/routines.

## Why a separate file?

The routine runs in a fresh Claude Code session with no context. The prompt has to be self-contained: tell the agent what to do, where to read the source files (this repo, cloned at the working dir), what MCP connectors to use, what to send and where. It reuses the canonical synthesis prompt and templates by reading them from the cloned repo — so editing `skills/meeting-brief/references/synthesis-prompt.md` automatically changes how tomorrow's brief is written, no routine update needed.

The only times you edit `cam.md`:
- The routine config changes (cron, model, allowed tools, recipient email)
- The set of MCP connectors changes (e.g., Notion gets added in v0.3)
- The step-by-step orchestration changes (e.g., we add a Notion read between Gmail and synthesis)

For voice/format/process changes, edit `skills/meeting-brief/references/*` instead. The routine picks up `main` on every run.

## Patrick's test routine

Patrick has a separate routine running on his own account (`Pre-meeting brief — Patrick test (6 AM CDT weekdays)`, ID `trig_01Pc5q9GcXeYRVsXhqY8ySAr`). It's a clone of `cam.md` with `patrickalpaugh@gmail.com` substituted for the recipient and the internal-domain anchor. Used to validate the pipeline before pointing the production routine at Cam's calendar.

The Patrick-test routine prompt is NOT checked in — it's stored in the routine itself at https://claude.ai/code/routines. To inspect or update, use the `/schedule` skill or the routines web UI.
