# Redstick Brief

A pre-meeting brief generator for Cam at Redstick Ventures. One slash command, one daily email — both produce the same one-page sharp briefing on every meeting on Cam's calendar.

## What you get

**`/brief`** in Cowork → reads today's Google Calendar, pulls 60 days of Gmail thread history with each attendee, searches Gmail for Otter conversation-summary emails (the prior-call source), runs a 4-stage WebSearch+WebFetch research pipeline on external attendees, writes a one-page brief inline. Optional argument: `/brief next`, `/brief tomorrow`, `/brief "Sarah"`.

**`/setup-daily-brief`** in Cowork → one-command, idempotent setup of the daily 6 AM cloud routine. Detects existing routine and updates it, or creates a new one. Use after install + connecting Gmail and Calendar MCPs.

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

**Setup the daily email (one-time):**
- `/setup-daily-brief` — creates or updates the 6 AM cloud routine on Cam's account. Idempotent.

**Daily (cloud routine):**
- Email arrives at 6:00 AM Mon–Fri in Cam's local TZ.
- Subject: `Tuesday, May 5 — 4 meetings`.
- One-page markdown body.
- Runs as a scheduled remote agent on Cam's Anthropic account. Setup details: [routines/cam.md](routines/cam.md).

## Data sources

- **Google Calendar** — today's events, attendees, locations
- **Gmail** — last 60 days of threads with each external attendee (30 days for internal), plus a parallel search for Otter `Conversation summary` emails (last 90 days) which carry the prior-call notes
- **WebSearch + WebFetch** — 4-stage research pipeline per external attendee:
  - Stage 1 anchor search (LinkedIn, company site, recent press)
  - Stage 2 direct page fetch (`/team`, `/about`, `/blog` — current titles, departures, latest post)
  - Stage 3 targeted recency searches (`site:linkedin.com/in`, TechCrunch / AgFunder / VentureBeat, PR wires, podcasts)
  - Stage 4 long-tail anomaly sources (Wayback Machine diffs, GitHub commits, Hacker News, Reddit, repeated job postings) — these get priority in WHAT'S NEW

Two MCP connectors (Gmail + Google Calendar) must be attached at https://claude.ai/customize/connectors. WebSearch and WebFetch are built into Cowork — no separate connector.

## Otter call notes (one-time toggle)

The brief reads prior-call context from Otter's auto-emailed conversation summaries:

1. In Otter: **Settings → Notifications → toggle ON "Email me conversation summaries"**.
2. Otter will email Cam after every call he records (subject: `Conversation summary: <meeting title>`).
3. The brief's existing Gmail search picks these up automatically and matches them to today's meetings by participant name overlap.

That's it. No Notion DB, no Zapier zap, no extra MCP connector. If the toggle is off, the brief works without call context — graceful degradation.

## Components

```
.claude-plugin/
  plugin.json
commands/
  brief.md                    ← /brief slash command
  setup-daily-brief.md        ← /setup-daily-brief one-time routine setup
skills/
  meeting-brief/
    SKILL.md
    references/
      synthesis-prompt.md
      external-block-template.md
      internal-block-template.md
      voice-rules.md
      example-output.md
routines/                      ← scheduled cloud routine prompts (NOT shipped in the .plugin)
  cam.md                      ← production prompt + setup config
  README.md
```

## Trigger phrases

- `/brief`, "brief me", "brief me on today", "prep me for my meetings", "what's on my calendar", "meeting brief", "what do I need to know for today"
- `/setup-daily-brief`, "set up the daily brief", "wire up the morning email", "schedule the brief routine"

## Author

Patrick Alpaugh — built for Cam at Redstick Ventures.

## Version

**0.3.0** — Simplification cut + multi-stage research. Drops the Notion/Zapier path entirely (replaces with Otter's native email summaries via Gmail search). New 4-stage WebSearch+WebFetch research pipeline (anchor → direct page fetch → targeted recency → long-tail anomaly sources including Wayback Machine, GitHub, HN/Reddit, job postings). Setup for Cam: 5 steps total.

**0.2.0** — Notion call-notes ingestion (Otter→Zapier→Notion); `/setup-daily-brief` command for idempotent one-command routine setup; "call beats email" source-priority rule. *(Superseded by v0.3 simplification — Notion path was too complicated.)*

**0.1.0** — Initial release. Skill (`/brief`) + scheduled cloud routine for the daily 6 AM email. Calendar + Gmail + WebSearch for external "WHAT'S NEW."

### Roadmap

- **0.4** — Cross-reference scorecards in `Redstick Hub/Deals/<company>/` so ORIENT pulls the snap verdict for portfolio meetings
- **0.5** — Granola/Fireflies fallback if Cam ever switches note-takers
- **0.6** — Optional Exa or Perplexity API for deeper research on high-stakes meetings (LP intros, anchor investor calls)
