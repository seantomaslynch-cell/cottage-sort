# Cottage Sort — Design Doc

**Status:** first playable (core sort loop). Web-first. Built in Godot 4.7, GL Compatibility renderer.

## Concept

A cozy **sort-and-restore** hybrid-casual puzzle. The player sorts clutter into
matching jars/baskets to earn coins, and spends those coins rebuilding and
decorating a run-down cottage, room by room.

- **Core loop (the 10-second hook):** ball-sort puzzle — pour stacked coloured
  items between jars until each jar holds one colour. Fast, tactile, endless.
- **Meta loop (the reason to come back):** coins from puzzles restore an
  isometric cottage — fix the roof, furnish the kitchen, plant the garden.
  This is the collectible, screenshot-able, LiveOps-able layer.

## Why this shape (2026 research)

- Puzzle is ~44% of casual IAP spend. **Match-3 and block puzzle are saturated;
  sort puzzles grew +229% YoY** and are cheap to build and ad-friendly.
- Winning casual games are **hybrid-casual**: snackable core + meta progression +
  events, content refreshed every 4–6 weeks.
- Retention bar for the genre: D1 ~27%+, D7 ~18%.
- Cozy art (warm tones, soft light) + isometric worlds are on-trend and
  performance-light — a good fit for web/Playables.

## Rewarded ads (woven into progression, never bolted on)

Every offer is tied to a want the player has *right now*. Rewards are
"meaningful but not sufficient".

| Placement | Offer |
|---|---|
| Stuck / undo | Watch to undo last 3 moves, or add one temporary jar |
| Level complete | 2x coins |
| Shop | Free coin pouch (cooldown) |
| Daily | Spin the wheel (coins / decor token / booster) |
| Restore screen | Mystery decor box |
| Streak | Watch a rewarded ad 3 days running -> bonus chest / discounted bundle |

Targets: rewarded completion >90%, opt-in >30%.

## Monetization

Ads are the on-ramp; keep IAP simple: remove-ads, starter pack, coin packs,
seasonal decor bundle. No pay-to-win.

## Retention systems (later milestones)

- Exponential daily-login curve (not flat).
- Weekly challenge + rotating free decor.
- Seasonal decor drop every 4–6 weeks (the real retention engine).

## Roadmap

- [x] **M0 — Core sort loop:** tap-to-pour jars, win detection, placeholder art.
- [x] **M1 — Feel:** pour animation, sfx (procedural WAVs), win juice, undo,
  add-jar (1st free then rewarded-ad stub), level select, save/load, mute.
  Solvable-by-construction level generator (`level_gen.gd`) + headless tests
  (`tools/test_logic.gd`). 12-stage colour ramp (3 -> 8), 2 spare jars each.
- [ ] **M2 — Content:** wider difficulty curve, more stages, "challenge" 1-spare
  mode, per-stage star ratings by move count, hint system.
- [ ] **M3 — Meta:** cottage restore screen, coins economy, first room with ~5 upgrade slots.
- [ ] **M4 — Retention:** daily rewards (exponential curve), daily spin, streak loop.
- [ ] **M5 — Ads + IAP:** real rewarded-ad SDK behind the stub, remove-ads, coin packs.
- [ ] **M6 — Web build:** itch.io / YouTube Playables export, size budget, load screen.
- [ ] **M7 — Art pass:** cozy jar/item art, cottage isometric art, UI theme, icon, real sfx/music.

## Files added in M1

- `game/level_gen.gd` — deterministic solvable-by-construction generator (+ session cache).
- `game/audio.gd` — sound manager; `game/audio/*.wav` from `tools/gen_sfx.py`.
- `game/ads.gd` — rewarded-ad stub (`watch_rewarded(Callable)`), simulates a view.
- `game/save.gd` — `user://save.json`: per-stage best moves + mute.
- `game/level_select.gd` — stage grid overlay with cleared markers.
- `tools/test_logic.gd` — headless checks: colour counts, not-pre-solved,
  independent solvability, move-logic asserts. Run:
  `godot --headless --path . --script res://tools/test_logic.gd`

## Tech notes

- Portrait 720x1280, `stretch/mode = canvas_items`, `aspect = expand`.
- `emulate_touch_from_mouse` on; input handles both touch and mouse.
- HUD built from code for now; a Godot `Theme` resource comes in the art pass.
- Level format: `game/levels.gd` — array of jars, each an array of colour indices
  bottom -> top; every colour must appear exactly `CAP` (4) times.
