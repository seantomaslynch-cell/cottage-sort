# Progress — Cottage Sort

Cross-machine handoff snapshot. Design & roadmap live in [DESIGN.md](DESIGN.md);
file map in [README.md](README.md).

**Updated:** 2026-08-29 · Codemagic CI added
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
| M13 gems currency + six-booster set + Menu-consolidated nav | ✅ done |
| M14 piggy bank + starter pack (offer cards in the Shop) | ✅ done |
| M15 authored 40-stage difficulty curve (+ endless mode past it) | ✅ done |
| M16 struggle-triggered offer ($0.99 pack on the fail screen) | ✅ done |
| M17 booster inventory + bundles | ✅ done |
| M18 seasonal battle pass (free + $4.99 premium) | ✅ done |
| M19 daily jackpot | ✅ done |
| M20 weekly leaderboard (ghost board, no backend) | ✅ done |
| M21 themed realms (6 chapters reskin the board) | ✅ done |
| M22 2nd cottage room (Kitchen) + rotating seasonal decor | ✅ done |
| M23 ship kit — SDK integration guide, ASO kit, analytics tool | ✅ done |
| M24 procedural art polish (jars + beads) | ✅ done |
| M25 functional audit + bug fixes (5 fixed — see AUDIT_FUNCTIONAL.md) | ✅ done |
| M26 config layer + App Store submission prep (store/*, iOS+Android presets) | ✅ done |
| M27 combo callouts + functional audit report | ✅ done |
| M28 Codemagic CI (iOS/Android/Web) — no local Mac needed | ✅ done |

[AUDIT.md](AUDIT.md) = competitive gap analysis · [AUDIT_FUNCTIONAL.md](AUDIT_FUNCTIONAL.md)
= code audit + fix log + a ranked fun/money upgrade list · `store/` = App Store
submission kit.
Playable end to end. Test suites: `test_logic`, `test_daily`, `test_shop`,
`test_decor`, `test_booster`, `test_bp`, `test_lb`, `test_realms` — all pass.

## What's left — all need an external piece

The seams are all in place. Config placeholders in `game/config.gd`; wiring
guide in [store/INTEGRATION.md](store/INTEGRATION.md).

1. **Apple Developer account + Codemagic setup** — the iOS/Android/Web builds
   run on Codemagic (`codemagic.yaml`), so **no local Mac is needed**. Still
   required: an Apple Developer Program membership + App Store Connect API key,
   the Codemagic env var groups / signing (see
   [store/CODEMAGIC.md](store/CODEMAGIC.md)), and the one-time store-side setup
   (app record, bundle id, IAPs, metadata, hosted privacy policy) —
   checklist in [store/APP_STORE_SUBMISSION.md](store/APP_STORE_SUBMISSION.md),
   paste-ready copy + rating/privacy answers in
   [store/METADATA.md](store/METADATA.md).
2. **Real ad / IAP / analytics SDKs** — swap the bodies of `game/ads.gd`,
   `game/iap.gd`, `game/analytics.gd`. Needs plugins + developer accounts.
3. **Local push notifications + OS review prompt** — fill in `game/platform.gd`
   with a native plugin (Android / iOS). Copy is in `config.gd`.
4. **Real bitmap art / custom font / licensed music** — needs an artist.
5. **Localization** (strings → a translation table), **crash reporting**, a
   **low-end device pass**.
6. **Content cadence** — hand-author L41–80, rotate the weekly event type.
7. **Tune the M15 curve** — run `tools/analyze_events.py` on a real `events.log`
   and adjust the `scr` / `bm` knobs in `levels.gd`.

Ranked fun/retention/money ideas: see the bottom of
[AUDIT_FUNCTIONAL.md](AUDIT_FUNCTIONAL.md).

**Needs an external piece (seam is in place):**

- **Real ads + IAP** — swap the bodies of `game/ads.gd` / `game/iap.gd`.
- **Real analytics** — swap `Analytics.flush()` for an SDK; events already logged
  to `user://events.log`.
- **Local push notifications + OS review prompt** — fill in `game/platform.gd`
  with a native plugin (Android / iOS).
- **Real art / font / music** — replace the procedural `_draw()` art and the
  generated placeholder SFX (`tools/gen_sfx.py`).
- **Web templates** on a fresh machine (editor → *Manage Export Templates*).
  On Codemagic the `&fetch_godot` step pulls them automatically.

**Deferred:** explicit 1-spare-jar "challenge" mode (too harsh for the cozy
default; verifier couldn't confirm solvability in budget).

## Run / test / build

```bash
# play (opens a window)
godot --path .

# compile + import (also rebuilds the global class cache)
godot --headless --path . --editor --quit

# tests
for t in logic daily shop decor booster bp lb realms; do
  godot --headless --path . --script res://tools/test_$t.gd
done

# screenshot a screen (no --headless; restores save.json after)
godot --path . --script res://tools/screenshot.gd -- res://shot.png board [stage]
#   modes: board | cottage | cottage_decor | daily | shop | settings | booster | season | fail

# summarise the analytics log to tune the difficulty curve
python tools/analyze_events.py
```

In-game keys: `R` restart · `N` next · `U` undo · `H` hint · `L` levels ·
`C` cottage · `D` daily · `S` shop · `M` mute (SFX). Cottage / Daily / Shop /
Levels / Settings also live behind the **Menu** button; **Boost** opens the
booster popup. Debug builds get a "+1 day" button in the Daily panel and
print `[evt]` / `[platform TODO]` lines.

## Gotchas

- After adding a new `class_name` script, a no-`--editor` headless run can fail
  with *"Identifier X not declared"* because it uses a stale
  `.godot/global_script_class_cache.cfg`. Fix: run `--editor --quit` once to
  rebuild it.
- `save.json` lives at `user://` (per-machine, not in the repo). The daily/shop
  tests back it up and restore it; the screenshot tool does too.
- `build/` and `shot*.png` are git-ignored.
