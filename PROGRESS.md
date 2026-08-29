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
| M6 web export | ✅ done — builds & runs (`build/web/`, ~40 MB); templates are per-machine |
| M7 first art pass (palette, UI theme, glass jars, cottage scene, icon) | ✅ done |
| M8 fail state + fail offers (move budget, +moves ad/coins, metered undo) | ✅ done |
| M9 onboarding (4 authored teaching levels, coach tips, clean first session) | ✅ done |
| M10 haptics + settings screen + ambient music | ✅ done |
| M11 weekly event + session-end hook + local analytics + platform seams | ✅ done |
| M12 endless cottage meta (decor sets + infinite Sundries; coins always have a sink) | ✅ done |

See [AUDIT.md](AUDIT.md) for the competitive gap analysis these milestones close.
Playable end to end. Test suites: `test_logic`, `test_daily`, `test_shop`, `test_decor` — all pass.

## What's next

**In-engine, high impact (do next):**

1. **Authored difficulty curve** past the first 4 levels — a deliberate first
   peak, a spike after ~L20. Keep the generator for an endless mode after.
2. **Monetization depth** — gems (premium currency), a 6+ booster set with a
   shop + bundles, a piggy bank, a starter pack + struggle-triggered offers.
3. **Battle pass / daily jackpot / leaderboards / themed realms** — need a
   content cadence and, for leaderboards, a small backend.
4. **More cottage rooms** and seasonal decor drops on top of the M12 catalog.

**Needs an external piece (seam is in place):**

- **Real ads + IAP** — swap the bodies of `game/ads.gd` / `game/iap.gd`.
- **Real analytics** — swap `Analytics.flush()` for an SDK; events already logged
  to `user://events.log`.
- **Local push notifications + OS review prompt** — fill in `game/platform.gd`
  with a native plugin (Android / iOS).
- **Real art / font / music** — replace the procedural `_draw()` art and the
  generated placeholder SFX (`tools/gen_sfx.py`).
- **Web templates** on a fresh machine (editor → *Manage Export Templates*).

**Deferred:** explicit 1-spare-jar "challenge" mode (too harsh for the cozy
default; verifier couldn't confirm solvability in budget).

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
`C` cottage · `D` daily · `S` shop · `M` mute (SFX). Sound/music/haptics
toggles live on the Settings screen. Debug builds get a "+1 day" button in
the Daily panel and print `[evt]` / `[platform TODO]` lines.

## Gotchas

- After adding a new `class_name` script, a no-`--editor` headless run can fail
  with *"Identifier X not declared"* because it uses a stale
  `.godot/global_script_class_cache.cfg`. Fix: run `--editor --quit` once to
  rebuild it.
- `save.json` lives at `user://` (per-machine, not in the repo). The daily/shop
  tests back it up and restore it; the screenshot tool does too.
- `build/` and `shot*.png` are git-ignored.
