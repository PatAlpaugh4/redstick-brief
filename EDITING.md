# Editing the Redstick Brief Plugin

This is the editable source for the `redstick-brief` Cowork plugin. Edit the files here, run `./build.sh`, send Cam the new `.plugin` file.

The plugin pairs with an n8n workflow in `n8n/` that runs the same logic on a 6 AM weekday cron and emails Cam. The synthesis prompt, voice rules, and templates are shared between both — n8n fetches them from a raw URL pointing at this repo's `references/` folder.

---

## What lives where

| File | Edit when you want to... |
|---|---|
| `skills/meeting-brief/SKILL.md` | Change the per-meeting process, what data sources to pull, classification logic |
| `skills/meeting-brief/references/synthesis-prompt.md` | Change voice, what the synthesis pass prioritizes, citation rules **(also affects n8n workflow)** |
| `skills/meeting-brief/references/external-block-template.md` | Change the format of external meeting blocks |
| `skills/meeting-brief/references/internal-block-template.md` | Change the format of internal meeting blocks |
| `skills/meeting-brief/references/voice-rules.md` | Update tone constraints |
| `skills/meeting-brief/references/example-output.md` | Update the worked example |
| `commands/brief.md` | Change what `/brief` does |
| `n8n/redstick-brief-daily.json` | Update the daily-email workflow |
| `.claude-plugin/plugin.json` | Bump the version (do this every release) |

---

## Editing workflow

1. Edit the file(s) above
2. **Bump the version** in `.claude-plugin/plugin.json` (e.g., `0.1.0` → `0.2.0` for a meaningful change, `0.1.0` → `0.1.1` for a small fix)
3. Run `./build.sh` from this folder
4. Output appears at `../redstick-brief.plugin`
5. Send Cam the new `.plugin` file — he reinstalls in Cowork (one click, replaces old version)
6. **If you edited a `references/` file**, the n8n workflow also picks up the change automatically on its next 6 AM run (it fetches the raw URL each morning). Verify with a manual trigger first.

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

## Files excluded from the build

The `build.sh` script ships only `.claude-plugin/`, `commands/`, `skills/`. Excluded:
- `.DS_Store`
- `build.sh` (this build script)
- `EDITING.md` (this file)
- `README.md`
- `SHIP-EMAIL.md`
- `n8n/` (workflow lives outside the plugin install)
