# Redstick Brief

A pre-meeting brief generator for Cam at Redstick Ventures. One slash command, one daily email — both produce the same one-page sharp briefing on every meeting on Cam's calendar.

## What you get

**`/brief`** in Cowork → reads today's Google Calendar, pulls 60 days of Gmail thread history with each external attendee (30 days for internal), runs a quick web search for "what's new" on external attendees, and writes a one-page brief inline. Optional argument: `/brief next`, `/brief tomorrow`, `/brief "Sarah"`.

**Daily email at 6:00 AM weekdays** (via a scheduled cloud routine — see [routines/cam.md](routines/cam.md)) → same logic, delivered to `cam@redstickvc.com` so Cam wakes up to the brief without asking.

## What's in a brief

One block per meeting, ordered by time. Two formats:

**External** (≥1 non-`@redstickvc.com` attendee):

```
9:00 AM · Sarah Chen · Greenhouse Robotics
Founder call · second touch since Tuesday's intro

ORIENT
[Who they are, current state]

WHERE YOU LEFT OFF
[Prior conversation specifics — what was promised, what's outstanding]

WHAT'S NEW (last 14 days)
[Recent public activity, news, team changes, anomalies — cited]

FIRST MOVE
[Literal opening line Cam can use in the meeting]

THE ANGLE
[What to prioritize: angle 1, angle 2, angle 3]

ONE THING
[Single memorable insight unique to this meeting]
```

**Internal** (all `@redstickvc.com`):

```
2:00 PM · 1:1 with Marcus

LAST TIME
[What was agreed on, what he owes you, what you owe him]

OPEN BETWEEN YOU
[Specific bullets: references sent but not read, sections owed, etc.]

ONE THING
[Single most important topic to confirm]
```

Empty days don't get an email. No-attendee focus blocks are skipped. Internal-only days run lighter blocks.

## How to use

**On-demand (skill):**
- `/brief` — all of today's meetings
- `/brief next` — next meeting only
- `/brief tomorrow` — tomorrow's calendar
- `/brief "Sarah Chen"` — single named attendee
- Natural-language phrases: "brief me on today", "prep me for my meetings", "what's on my calendar"

**Daily (cloud routine):**
- Email arrives at 6:00 AM Mon–Fri in Cam's local TZ.
- Subject: `Tuesday, May 5 — 4 meetings`.
- One-page markdown body.
- Runs as a scheduled remote agent on Cam's Anthropic account. Setup details: [routines/cam.md](routines/cam.md).

## Data sources

- **Google Calendar** — today's events, attendees, locations
- **Gmail** — last 60 days of threads with each external attendee, last 30 days for internal
- **WebSearch** — recent public activity, company news, team changes, anomalies (last 14 days)

Both Google connectors must be attached: in Cam's Cowork (for `/brief` skill) and on the routine itself at https://claude.ai/code/routines (for the daily email). Connect at https://claude.ai/customize/connectors.

## Components

```
.claude-plugin/
  plugin.json
commands/
  brief.md           ← /brief slash command
skills/
  meeting-brief/
    SKILL.md
    references/
      synthesis-prompt.md
      external-block-template.md
      internal-block-template.md
      voice-rules.md
      example-output.md
routines/             ← scheduled cloud routine prompts (NOT shipped in the .plugin)
  cam.md              ← production prompt + setup config
  README.md
```

## Trigger phrases

`/brief`, "brief me", "brief me on today", "prep me for my meetings", "what's on my calendar", "meeting brief", "what do I need to know for today"

## Author

Patrick Alpaugh — built for Cam at Redstick Ventures.

## Version

**0.1.0** — Initial release. Skill (`/brief`) + scheduled cloud routine for the daily 6 AM email. Calendar + Gmail + WebSearch for external "WHAT'S NEW."

### Roadmap

- **0.2** — Cross-reference scorecards in `Redstick Hub/Deals/<company>/` so ORIENT pulls the snap verdict for portfolio meetings
- **0.3** — Notion deal-notes ingestion for richer "WHERE YOU LEFT OFF"
- **0.4** — Fireflies/Granola transcript pipeline (so prior calls feed the brief, not just emails)
