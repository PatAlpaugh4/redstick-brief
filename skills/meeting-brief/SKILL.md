---
name: meeting-brief
description: Produces a sharp one-page pre-meeting brief for Cam at Redstick Ventures Fund I. Reads today's Google Calendar, fetches 60 days of Gmail thread history with each external attendee (30 days for internal), runs a parallel Gmail search for Otter's auto-emailed conversation summaries (last 90 days) to surface what was actually said on prior calls, executes a 4-stage WebSearch+WebFetch research pipeline on each external attendee (anchor search → direct page fetch → targeted recency searches → long-tail anomaly sources like Wayback Machine, GitHub, Hacker News, job postings), classifies meetings as external (≥1 non-@redstickvc.com) or internal, then synthesizes per-meeting blocks in the v1 spec format (ORIENT / WHERE YOU LEFT OFF / WHAT'S NEW / FIRST MOVE / THE ANGLE / ONE THING for external; LAST TIME / OPEN BETWEEN YOU / ONE THING for internal). Use when the user says "brief me", "brief me on today", "brief me on my meetings", "what's on my calendar", "prep me for my meetings", "meeting brief", "what do I need to know for today", or any natural variation. Also triggers on `/brief` slash command.
---

# Meeting Brief Skill

You are producing a one-page pre-meeting brief for **Cam Sarrazin, sole GP at Redstick Ventures Fund I**. This is a **prep tool, not a diligence tool.** It surfaces what's human, current, and tactical. It does NOT grind meetings through the 7-stage rubric. It does NOT score deals.

**The bar:** Cam should be able to scan the brief in 2 minutes and walk into every meeting sharper than he otherwise would have been. Goal 3 (the binding design constraint): if Cam forwarded a redacted version to a peer GP, they should ask "where did this come from?" — and the answer must be "I built this with AI," not "my chief of staff."

**Read these reference files before producing output:**
- `references/synthesis-prompt.md` — the canonical synthesis prompt (voice + inputs/outputs contract)
- `references/external-block-template.md` — exact format for external meeting blocks
- `references/internal-block-template.md` — exact format for internal meeting blocks
- `references/voice-rules.md` — inviolable tone constraints
- `references/example-output.md` — worked example showing both block types on a fictional day

## Process

### Step 1 — Resolve scope

The slash command (or natural-language invocation) passes a scope hint. Resolve it to a date range and (optionally) a filter:

- `today` (default) → all events today, Cam's local time zone
- `next` → next upcoming event only (across today / tomorrow if today is empty)
- `tomorrow` → all events tomorrow
- A time (e.g., `2pm`) → events at or near that time today
- A name (e.g., `"Sarah"`) → events today where any attendee's name or email contains the string
- An ISO date (`2026-05-06`) → all events that day

### Step 2 — Fetch calendar events

Use the available Google Calendar MCP tool to list events for the resolved date range. If the connector is not authenticated, surface a one-line message asking Cam to run the connector's `authenticate` action once and stop. Do not fail silently.

**Skip events that are:**
- Declined by Cam (responseStatus = `declined`)
- Focus blocks / no-attendee blocks (no other attendees besides Cam)
- All-day events that are not actual meetings (OOO, holidays — heuristic: no attendees AND title contains "OOO", "Out", "Holiday")

### Step 3 — Classify each event

For each remaining event:

- **External** = at least one attendee email lacks the `@redstickvc.com` domain
- **Internal** = all attendees are `@redstickvc.com`

Different research pipelines for each.

### Step 4a — External meeting pipeline

In parallel, for each external event:

1. **Pull Gmail thread history** for the external attendees over the last 60 days. Use `mcp__claude_ai_Gmail__search_threads` with a query like `from:<email> OR to:<email>` plus a date filter. Pull the top 5–10 threads. Use `mcp__claude_ai_Gmail__get_thread` to read the most recent 1–2 messages of each.

2. **Pull Otter conversation summaries** from Gmail (this is where prior-call notes live). Otter auto-emails Cam a "Conversation summary" after every call he records. Run a parallel Gmail search:
   ```
   (from:noreply@otter.ai OR subject:"Conversation summary" OR subject:"Otter") after:<90 days ago>
   ```
   For each candidate summary email, parse the body for the participants list (Otter formats it as a "Participants:" or "Attendees:" line, plus inline names). Match to today's meeting attendees by name overlap. Take the most recent 1–2 matching summaries. Read the AI summary + action items + any inline meeting URL.
   - **If no matches**, the WHERE YOU LEFT OFF section uses email context only. That's fine — graceful degradation. Don't note "no calls found" in the brief output; that's noise.
   - Cite these as `*(per Tuesday's call)*` or `*(call 4/29)*` rather than as email citations.

3. **Run the 4-stage research pipeline** for each external attendee. Stages run in parallel where independent. Goal: surface anomaly signals a single WebSearch wouldn't catch.

   **Stage 1 — Anchor search.** WebSearch `"<person>" "<company>"` to find their LinkedIn URL, the company website, and recent press hits (3–5 candidate URLs).

   **Stage 2 — Direct page fetch.** Use WebFetch on:
   - The company's `/team` or `/about` page → captures current titles + roster
   - The company's `/blog` or `/news` page → most-recent-post date + topic
   
   Compare the team-page roster to names referenced in old Gmail threads. Departures = cite-worthy anomalies.

   **Stage 3 — Targeted recency searches** (run in parallel):
   - `site:linkedin.com/in "<person>"` — pin the right LinkedIn (disambiguates common names)
   - `"<company>" site:techcrunch.com OR site:agfunder.com OR site:venturebeat.com` past 30 days — funding, partnerships, exits
   - `"<company>" site:prnewswire.com OR site:businesswire.com` — formal announcements
   - `"<person>" podcast OR interview` past 90 days — surfaces sharp lines for quoting
   - `"<company>" "<person>"` past 14 days — catch-all recency

   **Stage 4 — Long-tail anomaly sources.** These are what make briefs feel sharp:
   - **Wayback Machine** — WebFetch `https://web.archive.org/web/2*/[<company-url>]` and compare to the live page. Removed co-founders, deleted product pages, changed hero copy = high-signal anomalies. **This is the single highest-leverage source — always run it for important meetings.**
   - **GitHub** — for technical founders, WebSearch `site:github.com "<company>" OR "<person>"` + WebFetch their public commits page. Velocity = product signal.
   - **Hacker News + Reddit** — `site:news.ycombinator.com OR site:reddit.com "<company>"` for unfiltered customer/competitor talk
   - **Job postings** — WebSearch `"<company>" jobs OR careers` for repeated postings (churn signal) or new senior roles (strategic shifts)

   **Capture URLs + dates** for every claim. If a result has no clear date or appears >30 days stale (and isn't from Wayback), drop it. Stage-4 findings rank above Stage-3 in WHAT'S NEW because they're rarer and more decision-relevant.

4. **Look for a deal scorecard** in `Redstick Hub/Deals/<company>/Scorecard.md` (if accessible from the workspace). If one exists, read just the TL;DR snap verdict and EV multiple — surface in the ORIENT block. Do NOT re-run scorecard math.

### Step 4b — Internal meeting pipeline

In parallel, for each internal event:

1. **Pull Gmail thread history** for the internal attendees over the last 30 days. Same tool, narrower window.
2. **Pull Otter conversation summaries** the same way as for external (Step 4a.2), but with a 30-day window. Match by participant name overlap.
3. **Look for recent shared calendar events** (last 30 days) with the same attendees. Note any open commitments (sections promised, references pending, etc.) that surface in those threads.

No web research for internal meetings.

### Step 5 — Synthesize each block

For each meeting bundle (event metadata + Gmail context + WebSearch context if external + scorecard context if applicable):

1. Apply the synthesis prompt at `references/synthesis-prompt.md`.
2. Render the block using `references/external-block-template.md` or `references/internal-block-template.md`.
3. **Cite every claim inline** in the form `*(per Tuesday email)*`, `*(LinkedIn yesterday)*`, `*(scorecard 4/30)*`. No claim without a citation.
4. **Empty sections get cut**, not padded. If WHAT'S NEW has nothing real, delete the WHAT'S NEW header. If ONE THING is generic, delete it.
5. **Per-block length:** target 8–18 lines. A 4-line block beats a 12-line block of filler.

### Step 6 — Voice pass

Re-read every block against `references/voice-rules.md`. Cut anything generic. If a sentence could appear in any other GP's brief, delete it. Specifically:

- "She dodged unit economics" not "outstanding items: financial validation"
- First names only — humans, not "the founder"
- No diligence jargon (MOIC, TVPI, EV, "Stage 2") inside the brief
- Short sentences. Bullets only for true lists.
- End every external block with a literal FIRST MOVE line Cam can speak

### Step 7 — Compose and render

Order meetings by time (earliest first). Add a header line at top:

```
**<Weekday>, <Mon DD>** — N meetings (X external, Y internal)
```

If `N == 0`, respond with `Nothing on the calendar <today/tomorrow/specified date>.` Stop.

Render the full brief as a single markdown response in chat. **Do not write a file.** Cam reads inline.

If the total brief exceeds ~150 lines, tighten blocks (especially WHAT'S NEW and ORIENT) until it fits. Heavy days mean tighter blocks, not longer briefs.

## Tone — inviolable

- **Sharp, not corporate.** Never "exciting opportunity," "innovative," "leveraged," "ecosystem."
- **Terse and numerical.** "Raised $2M on $12M post" beats "well-capitalized."
- **Notice anomalies.** Title flips, missed deadlines, weird timing, deleted posts. These are the wow beats.
- **Privilege recency.** Yesterday > last week > last month, almost always.
- **Reference prior conversations specifically.** Don't generalize. If she promised a model, say so. If Marcus owes a reference check, name it.
- **Always end on action.** Every external block ends with FIRST MOVE — the literal opening line Cam can use.

## What NOT to do

- Do not run scorecard math. Read existing scorecards if they exist; do not score new deals here.
- Do not run TAM / competitor research. The `market-research` skill (in `redstick-scorecard`) owns that.
- Do not save files. Brief renders inline.
- Do not write generic introductions ("Here's your brief for today!"). Just produce the header and blocks.
- Do not pad empty sections. Cut them.
- Do not use the 7-stage rubric language ("Stage 2 outstanding," "MOIC hurdle," "fund returner") inside a block — those belong in the scorecard, not the brief.
- Do not exceed one screen per meeting block. Brief is read in 2 minutes total.

## References

- `references/synthesis-prompt.md` — canonical synthesis prompt, also fetched by the daily cloud routine
- `references/external-block-template.md` — exact format for external blocks
- `references/internal-block-template.md` — exact format for internal blocks
- `references/voice-rules.md` — tone constraints (verbatim from v1 spec)
- `references/example-output.md` — full worked example, both block types
