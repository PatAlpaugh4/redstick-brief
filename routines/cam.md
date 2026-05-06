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
| Allowed tools | `Read`, `Glob`, `Grep`, `WebSearch`, `WebFetch` |
| MCP connectors | Gmail + Google Calendar (both must be connected at https://claude.ai/customize/connectors) |
| Enabled | `true` once both connectors are attached |

## Prompt (paste verbatim)

```
This scheduled cloud routine fires every weekday at 6 AM Cam-local time on Cam Sarrazin's account. It produces a one-page pre-meeting brief on today's calendar and emails it to cam@redstickvc.com.

You are running in a fresh remote Claude Code session with the redstick-brief plugin source cloned at the working directory.

## Required MCP connectors

- **Gmail** (must be attached) — used for thread history, Otter conversation-summary lookups, AND sending the brief email.
- **Google Calendar** (must be attached) — required to read today's events. **If Calendar MCP is not attached to this routine, STOP immediately and report: "Calendar MCP not connected. Connect it at https://claude.ai/customize/connectors and update this routine to attach it." Do NOT send an email and do NOT attempt the brief without it.**

Optional but recommended setup (no MCP, just an Otter setting):
- **Otter "Email me conversation summaries" toggle** — when on, Otter emails Cam after every call he records. The brief picks these up via the Gmail search below as the prior-call context source. If off, brief degrades gracefully to email-only context — no error, just less call-aware.

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
   - **External:**
     - Gmail search threads with each external attendee over last 60 days; Gmail get_thread on top 5 threads per attendee.
     - Gmail search for Otter conversation summaries: `(from:noreply@otter.ai OR subject:"Conversation summary" OR subject:"Otter") after:<90 days ago>`. For each match, parse the body for participants and match by name overlap to current meeting attendees. Take the most recent 1–2. Read summary + action items. (Cite as `*(per Tuesday's call)*` or `*(call 4/29)*` rather than as email citations.)
     - **4-stage research pipeline** for each external attendee (run stages in parallel where independent):
       - **Stage 1 — Anchor**: WebSearch `"<person>" "<company>"` to find LinkedIn URL, company site, recent press
       - **Stage 2 — Direct page fetch**: WebFetch the company's `/team`, `/about`, `/blog` pages → current titles + most-recent-post date. Compare to old Gmail thread names to detect departures.
       - **Stage 3 — Targeted recency**: parallel WebSearch queries — `site:linkedin.com/in "<person>"`, `"<company>" site:techcrunch.com OR site:agfunder.com OR site:venturebeat.com` past 30 days, `"<company>" site:prnewswire.com OR site:businesswire.com`, `"<person>" podcast OR interview` past 90 days
       - **Stage 4 — Long-tail anomalies**: **Wayback Machine** (`web.archive.org/web/2*/<company-url>` then WebFetch + diff against live page — single highest-leverage anomaly source), **GitHub** for technical founders (`site:github.com "<company>"`), **Hacker News + Reddit** (`site:news.ycombinator.com OR site:reddit.com "<company>"`), **Job postings** (`"<company>" jobs OR careers` for repeated postings = churn signals)
       - Stage-4 findings rank above Stage-3 in WHAT'S NEW because they're rarer and more decision-relevant.
   - **Internal:**
     - Gmail search threads with internal attendees over last 30 days.
     - Gmail search for Otter conversation summaries the same way as external, 30-day window.
     - No web research.

7. **Synthesize each block** per `synthesis-prompt.md` and the templates. Cite every claim inline like `*(per Tuesday email)*`, `*(per Tuesday's call)*`, `*(call 4/29)*`, `*(LinkedIn 5/3)*`, `*(Wayback diff: ...)*`, `*(GitHub commits 5/2)*`. **Source priority: call beats email** — when the same fact is in both an Otter call summary and a Gmail thread, quote the call. **Stage-4 anomaly findings beat Stage-3 press hits** — lead WHAT'S NEW with the rarer, sharper item. Empty sections get cut, never padded. Each external block ends with a literal FIRST MOVE line.

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
