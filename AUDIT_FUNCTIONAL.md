# Functional audit — Cottage Sort

Reviewed 2026-08-29 against the M0–M27 build (~5k lines, 24 game scripts).
All 8 headless test suites pass; a headless run and every screen render clean.

## What was checked

- **Every panel** wires its signals in `main.gd._ready()` (27 connections, all
  one-shot — no double-connect risk), instantiates before use, and gets the
  theme pushed onto it.
- **Save**: `load_now()` merges JSON over defaults; every read uses
  `.get(key, default)`, so a partial/older save or a corrupt file degrades
  gracefully (no crash, keeps defaults).
- **Board logic**: move legality, win detection, fail detection (budget +
  wedged), undo, add-jar, boosters, combos, animation lock — via
  `test_logic.gd` + `test_booster.gd` + manual trace.
- **Economy**: coins / gems / piggy / boosters / decor / cottage tiers — via
  `test_shop.gd` + `test_booster.gd` + `test_decor.gd`.
- **Time systems**: login cycle, spin, ad streak, weekly event, jackpot,
  battle-pass season, leaderboard week, seasonal decor — via `test_daily.gd`,
  `test_bp.gd`, `test_lb.gd`.
- **No fragile node paths** — all UI is built in code; nothing uses `$Path` /
  `get_node()`.

## Bugs found and fixed (commit M25 + M27)

| Severity | Bug | Fix |
|---|---|---|
| **High** | Undo after `magnet` / `autoplay` could pop from an emptied jar → a `null` bead → crash on next draw. | `_after_booster()` clears the undo history; `undo()` guards stale entries. |
| **Medium** | Boosters were consumed from the inventory even when the effect no-op'd (board busy/locked). | Effects return `bool`; `main` applies first, decrements only on success. |
| **Medium** | Daily reset used UTC days — reward flipped at UTC midnight, not the player's local midnight. | `today()` / `_today()` shifted by the system timezone bias. |
| **Low** | Pressing `S` opened the shop without the starter-pack countdown. | Routes through `_open_shop()`. |
| **Low** | Debug "+1 day" advanced the daily clock but not the battle-pass season clock. | Syncs `_bp.debug_day_offset`. |

## Known risks / follow-ups (not blocking)

- **`SaveData.save_now()` writes on every economy change.** Claiming a
  10-tier battle pass fires ~30 synchronous file writes in a frame. Fine on
  desktop; consider a debounced/deferred save on mobile.
- **No save-format version field.** All reads are defensive so it's safe today,
  but a future incompatible change has no migration hook. Cheap to add later.
- **Jackpot forfeits silently** if the player navigates away mid-board (the
  attempt is consumed on start). Acceptable, but a "you'll lose your jackpot"
  confirm could reduce complaints.
- **`_on_hint()` overlay guard is partial** (checks `_daily_panel` / `_cottage`
  but not every panel). Harmless in practice — the Hint button is covered by
  any full-screen overlay's scrim and the key is blocked in `_unhandled_input`.
- **Analytics doesn't log `interstitial_shown`** or an `ad_reward` `placement`.
  Add when wiring the real ad SDK (`analyze_events.py` notes this).
- **Combo detection** uses a 2.2s wall-clock window; it won't fire from
  `magnet`/`autoplay` (by design — those aren't skill).

## Upgrades to make it more fun / more addicting / more money

Ranked by impact ÷ effort. Anything marked *(external)* needs a plugin/asset.

### Fun / retention

1. **Combo callouts** — done (M27): 2+ jars finishing in a burst pays a small
   bonus + "Nice!/Great!". Tune the window and words from play data.
2. **A "flawless" badge** on the win screen when a level is 3-starred with no
   undo/hint — a cheap pride hook, and a natural share moment.
3. **Cottage view should show room 2** — the Kitchen upgrades don't visibly
   change the drawing yet. Draw a second building / interior strip so buying
   Kitchen tiers has a payoff on screen.
4. **Realm-specific bead skins** — beads are the same 8 colours in every
   chapter. A subtle per-realm palette shift (jam jars in the Pantry, seed
   packets in the Garden) would make chapters feel distinct beyond the shelf.
5. **Streak-freeze token** — one free "protect my login streak" per week (or
   sold). Losing a long streak is the #1 churn moment; a safety valve keeps
   players in the loop.
6. **Push notifications** *(external)* — the single biggest D1→D7 lever still
   missing. `platform.gd` is wired.
7. **Haptic + sound polish per bead colour** — a tiny pitch shift per colour
   makes pours feel musical; near-free.

### Money

8. **Rewarded "double your combo"** — *done (M44)*: a combo of x4+ pops a
   transient HUD button ("Double x4 combo (Watch) +20") that times out after
   5s; watching a rewarded video pays the combo bonus a second time
   (`HUD.offer_combo_double` / `combo_double_pressed` → `main._on_combo_double`).
9. **A cosmetic gem sink** — *done (M44)*: `DecorData.PREMIUM` — a gem-only
   "Keepsakes" set (5 pieces, 8–28 gems) that never sells for coins. Shows in
   the Cottage Decorate tab and the Progress → Collection tab;
   `Economy.buy_decor` branches on `it.has("gem")`.
13. **Seasonal event storefront** — *done (M44)*: the Shop shows a "<Season>
    bundle" card — all 4 of the live seasonal pieces for `SEASON_BUNDLE_GEMS`
    (24), once per 28-day season (`SaveData.season_bundle_id` vs
    `DecorData.season_id()`); `main._on_season_bundle` spends the gems and
    `grant_decor`s each unowned piece.
10. **Battle-pass "tier skip"** — *done (M41)*: a "Skip tier · N gems" button
    in the season panel; cost eases toward season end (`maxi(20, 55 - days_left)`).
11. **Piggy-bank tiers** — *done (M43)*: the cap grows 250 -> 500 the first
    time the bank is cracked (`piggy_cracked_once`).
12. **Remove-ads daily gem stipend** — *done (M43)*: ad-free owners get +3
    gems on the first session each day (`stipend_day`).
14. **First-purchase doubler** — *done (M41)*: first gem pack is doubled
    (`SaveData.first_gem_buy`), flagged with a "2× first buy!" tag in the Shop.

*Also new in M41:* a **rotating daily deal** — one featured product a day
(`game/deal_data.gd`, deterministic by local date) with a +20–50% bonus on the
granted amount, once per day.

### Content cadence (needed for a live game)

15. **Authored curve** — *done to L120 (M42)*: five 16-level acts past L40
    (Orchard / Cellar / Loft / Meadow / Hearth), each opening with relief + a
    deep-run flow breather, building to a two-level peak, then winding down;
    all 120 solvability-verified and frozen in `game/level_data.gd`. Endless
    mode now starts at L121.
16. **Rotate the weekly event type** — *done (M43)*: `Daily.WEEK_EVENTS` cycles
    by `week_id` between clear-N / earn-N-stars / beat-par-N / N-no-hint-clears;
    `note_level_cleared(stars, under_par, used_hint)` scores the active one.
17. **Leaderboard needs a real backend eventually** — the ghost board is fine
    for soft launch but savvy players will notice the bots.
