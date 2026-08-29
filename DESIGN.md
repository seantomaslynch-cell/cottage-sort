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
- [x] **M2 — Content:** 24 stages (colour ramp 3-8 with periodic 3-spare
  breathers), per-stage star ratings by move count (win screen + level grid,
  saved best-of, small coin bonus), hint button (2 free per level, then a
  rewarded ad) backed by a BFS solver with heuristic fallback. Still todo:
  explicit 1-spare "challenge" mode.
- [x] **M3 — Meta:** coins earned on solve (base + first-clear bonus), Cottage
  restore screen with a first room of 5 upgrade slots (roof / walls / window /
  door / garden), each 2-3 tiers; cottage drawing warms up + gains detail as
  tiers are bought. Rewarded-ad hooks: "Double coins" on the win screen,
  "Mystery box" on the cottage screen. Economy persisted in save.
- [x] **M4 — Retention:** 7-day login cycle (rising rewards 25..300, resets on a
  missed day), once-a-day spin wheel (extra spins via rewarded ad, weighted
  prizes), 3-day "watched a rewarded ad" streak -> 150-coin chest. Daily panel
  auto-opens on the first launch of a new day. Debug "+1 day" button in debug
  builds. Headless tests in `tools/test_daily.gd`.
- [~] **M5 — Ads + IAP:** ad provider interface (rewarded + interstitial +
  cooldown + remove_ads), interstitial on "Next" between levels, IAP stub
  (remove_ads entitlement + 3 coin packs) with a Shop screen. Still todo:
  drop in a real ad SDK + real store bindings (native plugins, per-platform).
- [x] **M6 — Web build:** `export_presets.cfg` (Web, no threads, GL compat,
  cream head_include), `tools/export_web.ps1` / `.sh`, `web/README.md`.
  Verified: `web_nothreads` templates installed and `--export-release "Web"`
  produces a working `build/web/` (~40 MB, mostly `index.wasm`) that boots and
  plays in a plain static server. Optional later: custom loading shell, wasm
  size trim for Playables. (Templates are per-machine; other machines still run
  the one-time install.)
- [x] **M7 — Art pass:** shared `palette.gd` (one colour source), runtime
  `ui_theme.gd` Theme (rounded honey buttons with hover/pressed/disabled, soft
  cards) applied to the Window; glass jars (rounded belly, rim, sheen, shadow),
  glossy beads (shade + highlight), wooden shelves under each row, page
  gradient, selected-jar glow, win confetti; cottage gets a sky gradient, sun,
  clouds, drop shadows and a picket fence; new themed `icon.svg`. Still todo:
  real bitmap art + custom font + music (needs an artist / assets).

Legend: [x] done  [~] scaffolded, needs external step  [ ] not started

## Files added in M7

- `game/palette.gd` — `Palette`: every colour the game uses (page, ink, cards,
  buttons, shelf, glass, 8 bead colours).
- `game/ui_theme.gd` — `UiTheme.build()` -> a `Theme` applied to the Window in
  `main._ready()`; styles Button + Panel.
- Upgraded drawing in `board.gd` (glass jars, glossy beads, shelves, gradient,
  glow, confetti) and `cottage_view.gd` (sky, sun, clouds, fence, shadows).
- New `icon.svg`.

## Files added in M5 / M6

- `game/solver.gd` (M2) — `SortSolver`: BFS shortest-solution first move for
  hints; heuristic fallback.
- `game/iap.gd` — `GameIap` stub store (remove_ads + coin packs).
- `game/shop_panel.gd` — `ShopPanel` CanvasLayer (layer 18).
- `game/ads.gd` — now a provider: rewarded + `maybe_show_interstitial()` with a
  90s cooldown and a `remove_ads` flag.
- `export_presets.cfg` — Web preset (no threads, GL compat).
- `tools/export_web.ps1` / `tools/export_web.sh`, `web/README.md`.
- `tools/test_shop.gd` — headless IAP + interstitial-gating checks.

## Files added in M4

- `game/daily.gd` — `Daily` node: login cycle, spin, ad-streak; `today()` =
  whole UTC days + in-memory `debug_day_offset`.
- `game/spin_wheel.gd` — `SpinWheel` Node2D: draws the prize wheel, `animate_spin()`.
- `game/daily_panel.gd` — `DailyPanel` CanvasLayer (layer 25).
- `tools/test_daily.gd` — headless tests (login curve + wrap, spin gating +
  weighting, ad streak + chest); backs up / restores the real save file.

## Files added in M3

- `game/cottage_data.gd` — the room's 5 slots and their tier costs.
- `game/economy.gd` — `Economy` node: coin balance + upgrade ownership, signals,
  persistence via SaveData; `restored_fraction()` drives the art.
- `game/cottage_view.gd` — `CottageView` Control, draws the cottage from tiers.
- `game/cottage_screen.gd` — `CottageScreen` CanvasLayer: view + slot rows +
  coins + mystery box + back.
- Coin tuning in `main.gd`: `COIN_BASE = 20`, `COIN_FIRST_CLEAR = 30`.

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
