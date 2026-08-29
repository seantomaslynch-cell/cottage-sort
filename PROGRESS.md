# Progress — Cottage Sort

Cross-machine handoff snapshot. Design & roadmap live in [DESIGN.md](DESIGN.md);
file map in [README.md](README.md).

**Updated:** 2026-08-29
**Repo:** github.com/seantomaslynch-cell/cottage-sort (private) · branch `master`
**Engine:** Godot 4.7.2 stable (standard / GDScript, GL Compatibility, portrait 720×1280)

## Status

| Milestone | State |
|---|---|
| M0 core sort loop | ✅ done |
| M1 feel (anim, SFX, undo, add-jar, level select, save) | ✅ done |
| M2 content (24 stages, stars, hint + BFS solver) | ✅ done |
| M3 cottage meta (coins, restore screen, 5 upgrade slots) | ✅ done |
| M4 retention (login cycle, spin wheel, ad-watch streak) | ✅ done |
| M5 monetization scaffolding (ad provider + interstitial, IAP stub, Shop) | ✅ done — stubs |
| M6 web export config (`export_presets.cfg`, build scripts) | ✅ done — templates not installed |
| M7 first art pass (palette, UI theme, glass jars, cottage scene, icon) | ✅ done |

Playable end to end. Three headless test suites pass (see below).

## What's next (external / asset work)

1. **Real web build** — install Godot Web export templates (editor →
   *Manage Export Templates*), then `pwsh tools/export_web.ps1`
   (or `GODOT=… tools/export_web.sh`). Output → `build/web/`. See
   [web/README.md](web/README.md).
2. **Real ads + IAP** — swap the bodies of `game/ads.gd` and `game/iap.gd` for a
   native SDK / platform store. Interfaces are stable; nothing else changes.
3. **Real art / font / music** — replace the procedural `_draw()` art and the
   generated placeholder SFX (`tools/gen_sfx.py`).
4. **Deferred:** explicit 1-spare-jar "challenge" mode (parked in M2 — too harsh
   for the cozy default and the verifier couldn't confirm solvability in budget).

## Run / test / build

```bash
# play (opens a window)
godot --path .

# compile + import (also rebuilds the global class cache)
godot --headless --path . --editor --quit

# tests
godot --headless --path . --script res://tools/test_logic.gd   # sort logic + generator + solver
godot --headless --path . --script res://tools/test_daily.gd   # login curve, spin, ad streak
godot --headless --path . --script res://tools/test_shop.gd    # IAP + interstitial gating

# screenshot a screen (no --headless; restores save.json after)
godot --path . --script res://tools/screenshot.gd -- res://shot.png board   # board|cottage|daily|shop
```

In-game keys: `R` restart · `N` next · `U` undo · `H` hint · `L` levels ·
`C` cottage · `D` daily · `S` shop · `M` mute. Debug builds also get a
"+1 day" button in the Daily panel.

## Gotchas

- After adding a new `class_name` script, a no-`--editor` headless run can fail
  with *"Identifier X not declared"* because it uses a stale
  `.godot/global_script_class_cache.cfg`. Fix: run `--editor --quit` once to
  rebuild it.
- `save.json` lives at `user://` (per-machine, not in the repo). The daily/shop
  tests back it up and restore it; the screenshot tool does too.
- `build/` and `shot*.png` are git-ignored.
