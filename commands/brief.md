---
description: Generate a sharp one-page pre-meeting brief for today's (or specified) calendar
---

Invoke the `meeting-brief` skill to produce a one-page briefing on the user's calendar meetings. Pass any argument the user provided to the skill as the scope hint.

Steps:

1. **Resolve scope from the argument** (or default):
   - No argument or "today" → all meetings today (Cam's local TZ)
   - "next" → next upcoming meeting only
   - "tomorrow" → all meetings tomorrow
   - A time like "2pm" or "14:00" → meeting at or near that time today
   - A name like `"Sarah"` or `"Sarah Chen"` → meeting(s) with that named attendee today
   - A date like `2026-05-06` → all meetings on that date

2. **Read the skill** at `skills/meeting-brief/SKILL.md` and follow its full process. Read the reference files (`synthesis-prompt.md`, `external-block-template.md`, `internal-block-template.md`, `voice-rules.md`, `example-output.md`) before producing output.

3. **Render inline** as a single markdown response in chat — do not save a file. Cam reads the brief in Cowork, scrolls if needed, then walks into his meetings.

4. **Header line**: `**<Weekday>, <Mon DD>** — N meetings (X external, Y internal)`. If no meetings: respond with `Nothing on the calendar <today/tomorrow/etc.>` — no padding.

5. **Voice pass before output**: re-check against `references/voice-rules.md`. Cut anything generic. If a sentence could appear in any other GP's brief, delete it.
