# Cam's daily-brief routine — production prompt

This is the prompt to paste into a Claude **scheduled cloud routine** (claude.ai/code/routines) on **Cam's account**. The routine fires at 6 AM weekday Cam-local time, reads his calendar, and emails him the brief.

## Routine config

| Field | Value |
|---|---|
| Name | `Pre-meeting brief — daily 6 AM` |
| Schedule | `0 11 * * 1-5` (cron, UTC) — equals 6 AM CDT. **In winter (CST), update to `0 12 * * 1-5`** to keep firing at 6 AM local. |
| Timezone | UTC (cron is always UTC; convert from America/Chicago) |
| Model | `claude-sonnet-4-6` (default; Opus 4.7 if voice quality needs more) |
| Source | `https://github.com/PatAlpaugh4/redstick-brief` |
| Allowed tools | `Read`, `Glob`, `Grep`, `WebSearch` |
| MCP connectors | Gmail + Google Calendar (both must be connected at https://claude.ai/customize/connectors) |
| Enabled | `true` once both connectors are attached |

## Prompt (paste verbatim)

```
This scheduled cloud routine fires every weekday at 6 AM Cam-local time on Cam Sarrazin's account. It produces a one-page pre-meeting brief on today's calendar and emails it to cam@redstickvc.com.

You are running in a fresh remote Claude Code session with the redstick-brief plugin source cloned at the working directory.

## Required MCP connectors

- **Gmail** (must be attached) — used for both reading thread context AND sending the brief email.
- **Google Calendar** (must be attached) — required to read today's events. **If Calendar MCP is not attached to this routine, STOP immediately and report: "Calendar MCP not connected. Connect it at https://claude.ai/customize/connectors and update this routine to attach it." Do NOT send an email and do NOT attempt the brief without it.**

## Steps

1. **Read the canonical brief instructions** from the cloned repo, in this order:
   - `skills/meeting-brief/SKILL.md` — the process
   - `skills/meeting-brief/references/synthesis-prompt.md` — voice + I/O contract; treat this as system-level guidance for the synthesis pass
   - `skills/meeting-brief/references/external-block-template.md`
   - `skills/meeting-brief/references/internal-block-template.md`
   - `skills/meeting-brief/references/voice-rules.md` — inviolable
   - `skills/meeting-brief/references/example-output.md` — study the format

2. **Fetch today's calendar events** via the Google Calendar MCP. Date range: today 00:00 → 23:59 in **America/Chicago** time zone. Cam's primary calendar.

3. **Filter events:**
   - Skip events Cam declined (responseStatus = 'declined')
   - Skip focus blocks (no attendees besides Cam)
   - Skip OOO/holiday all-day events (title contains 'OOO', 'Out', 'Holiday' AND no attendees)

4. **If 0 events remain:** print `No meetings today. Brief not sent.` and STOP. Do NOT send an empty email — per voice-rules.md, empty briefs train the user to ignore the inbox.

5. **Classify each remaining event:**
   - **external** = at least one attendee email lacks the `@redstickvc.com` domain
   - **internal** = all attendees are `@redstickvc.com`

6. **Per meeting, in parallel:**
   - **External:** Gmail search threads with each external attendee over last 60 days; Gmail get_thread on top 5 threads per attendee. WebSearch each external attendee for what's new in last 14 days (LinkedIn posts, company news, recent press, podcasts, anomalies — see synthesis-prompt.md for the query template).
   - **Internal:** Gmail search threads with internal attendees over last 30 days. No web search.

7. **Synthesize each block** per `synthesis-prompt.md` and the templates. Cite every claim inline like `*(per Tuesday email)*`, `*(LinkedIn 5/3)*`. Empty sections get cut, never padded. Each external block ends with a literal FIRST MOVE line.

8. **Compose the email:**
   - **To:** `cam@redstickvc.com`
   - **Subject:** `<Weekday>, <Mon DD> — N meeting<s> (X external, Y internal)` — e.g., `Tuesday, May 5 — 4 meetings (3 external, 1 internal)`
   - **Body:** the rendered markdown brief. Header line at top, then one block per meeting in time order. Plain markdown — Gmail will render headings and bold.

9. **Send via Gmail MCP** (compose + send email tool). Use Cam's authorized Gmail account.

10. After sending, print one confirmation line: `Sent brief to cam@redstickvc.com — N meetings, X external, Y internal.`

## Guardrails

- Do NOT save any files. Output is email-only.
- Do NOT include raw bundle JSON, tool outputs, or thinking blocks in the email body.
- Do NOT pad empty sections — delete them per voice-rules.md.
- Do NOT send an email if Calendar MCP fails, isn't attached, or returns 0 events.
- Do NOT use diligence jargon (MOIC, TVPI, EV multiple, "Stage 2") in the brief — voice-rules.md §4.
- The brief is for Cam. Voice is the GP's prep voice — sharp, terse, first names, no corporate language.
```

## Setup steps for Cam

1. Sign in at https://claude.ai/code/routines
2. Click "New routine"
3. Paste the prompt above into the message field
4. Configure: cron `0 11 * * 1-5`, model `claude-sonnet-4-6`, source repo `https://github.com/PatAlpaugh4/redstick-brief`, allowed tools as listed, attach Gmail + Calendar MCP connectors
5. Save and enable

OR — Patrick creates the routine on Cam's behalf via the `/schedule` skill in Cam's Cowork session, using this prompt verbatim.

## Updating the prompt later

Edit `synthesis-prompt.md`, `voice-rules.md`, or any template in this repo, push to `main` — the routine pulls from the repo on every run, so the next 6 AM brief picks up the change automatically.

The only reason to edit THIS file (`routines/cam.md`) is if the routine config itself changes (cron, model, recipient, tools). For voice/format/process changes, edit the references and let the routine fetch them.
