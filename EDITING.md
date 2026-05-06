# Editing the Redstick Brief Plugin

This is the editable source for the `redstick-brief` Cowork plugin. Edit the files here, run `./build.sh`, send Cam the new `.plugin` file.

The plugin pairs with a **scheduled cloud routine** (config at `routines/cam.md`) that runs the same logic on a 6 AM weekday cron and emails Cam. The routine clones this repo (`https://github.com/PatAlpaugh4/redstick-brief`) on every run, so the synthesis prompt, voice rules, and templates are shared between both — push to `main`, the next 6 AM brief picks up the change.

---

## What lives where

| File | Edit when you want to... |
|---|---|
| `skills/meeting-brief/SKILL.md` | Change the per-meeting process, what data sources to pull, classification logic |
| `skills/meeting-brief/references/synthesis-prompt.md` | Change voice, what the synthesis pass prioritizes, citation rules **(also affects daily routine)** |
| `skills/meeting-brief/references/external-block-template.md` | Change the format of external meeting blocks |
| `skills/meeting-brief/references/internal-block-template.md` | Change the format of internal meeting blocks |
| `skills/meeting-brief/references/voice-rules.md` | Update tone constraints |
| `skills/meeting-brief/references/example-output.md` | Update the worked example |
| `commands/brief.md` | Change what `/brief` does |
| `commands/setup-daily-brief.md` | Change how `/setup-daily-brief` discovers/creates/updates the routine, pre-flight checks, defaults |
| `routines/cam.md` | Update the daily-email routine config (cron, model, recipient, MCP connectors) — most voice/format edits should NOT touch this file |
| `.claude-plugin/plugin.json` | Bump the version (do this every release) |

---

## Editing workflow

1. Edit the file(s) above
2. **Bump the version** in `.claude-plugin/plugin.json` (e.g., `0.1.0` → `0.2.0` for a meaningful change, `0.1.0` → `0.1.1` for a small fix) — only required for skill changes that ship to Cam's Cowork
3. Run `./build.sh` from this folder
4. Output appears at `../redstick-brief.plugin`
5. Send Cam the new `.plugin` file — he reinstalls in Cowork (one click, replaces old version)
6. **`git push origin main`** — the daily routine clones the repo on every run, so pushing `main` automatically updates the next 6 AM brief. No routine restart needed.

## Files excluded from the .plugin (build script positive include-list)

The `.plugin` file ships only `.claude-plugin/`, `commands/`, `skills/` to Cam's Cowork install. Excluded:
- `.DS_Store`, `.git/`, `.gitignore`
- `build.sh`, `EDITING.md`, `README.md`, `SHIP-EMAIL.md`
- `routines/` — the cloud routine prompts live here for source-of-truth, but they don't belong in Cowork; the routine clones the repo directly

---

## Versioning convention

Use semver loosely:
- `0.1.x` — patch fixes (typos, voice tweaks, small wording)
- `0.x.0` — meaningful behavior changes (new sections, changed logic, new commands, new data sources)
- `1.0.0` — when Cam declares it production-ready

---

## Validation

The build script checks that `plugin.json` is valid JSON. For a deeper check, if you have `claude` CLI installed:

```
claude plugin validate ./.claude-plugin/plugin.json
```

---

## Repo hygiene

- `SHIP-EMAIL.md` is gitignored (contains Cam's address + draft pre-send copy — local only)
- `*.plugin` is gitignored (the built artifact lives one folder up, not in the repo)
