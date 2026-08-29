# Cottage Sort — Competitive Gap Audit

Prepared 2026-08-29 against the M0–M7 build. Sources listed at the bottom.
A designed version of this is also published as a Claude artifact.

Targets: fun, habit-forming, healthy ad + IAP revenue.

## Headline finding

**The game has no fail state, so it is missing the single strongest revenue
lever in the genre.** Unlimited moves + unlimited free undo means there is no
"out of moves → watch an ad / buy a booster / take this bundle" moment. Top sort
puzzles deliberately *sell no way out of difficulty* [2][7]. The category does
~$200M net/year across three titles [2], split roughly **59% IAP / 41% ads**
[7]. Everything under "Tier 2" depends on adding a gentle, cozy-appropriate fail
state first.

## What the build already gets right

- Solvable-by-construction generator — every level is provably completable.
- Rewarded ads woven into progression, not bolted on. (More placements ≠ more
  revenue [8].)
- A rising login ladder (25→300, resets on a miss), not a flat daily bonus [3].
- A 3-day "watched a rewarded ad" streak → chest — a 2026-trend mechanic [3].
- Honest remove-ads (interstitials only; rewarded stays) + interstitial cooldown.
- A real BFS hint solver (many competitors give useless hints).
- A cozy restoration meta.
- Clean provider interfaces — real ad/IAP SDKs are a one-file swap.
- A working web build (Playables / itch reachable).

## Tier 1 — Foundation, before any soft launch

*77% of installs churn within 3 days [6]. None of the monetization matters if the
first two minutes don't hook. These are cheap and load-bearing.*

| Gap | Top games | We have | Add |
|---|---|---|---|
| **Onboarding / FTUE** | Sorting within 10–15s; one mechanic at a time via real gameplay [6] | No tutorial; first launch opens the Daily panel over an unexplained board | Hand-scripted first ~5 levels (pour → win → undo → add-jar); suppress Daily until session 2 |
| **Authored difficulty curve** | First difficulty peak timing predicts RPD; Pixel Flow runs 35 fail-free levels [2] | 24 stages by colour count only; no fail-free window, no tuned spike | Hand-author first ~25–30 levels: flow to ~L10, first challenge ~L12–15, spike after ~L20; keep generator for endless mode |
| **Haptics** | Sort/screw hits lean on tactile, ASMR-grade feedback [10][12] | SFX only | `Input.vibrate_handheld()` on pour/settle/invalid/win + toggle |
| **Settings screen** | Separate SFX/music/haptics, reduce-effects, restore, privacy, credits [10] | Mute toggle only | A proper settings panel (also an App Store expectation) |
| **Background music** | Cozy games live on ambient music | Silence | One ambient loop now, licensed later |
| **Local push notifications** | "reward ready", "streak breaking", "event ending" beat the 3-day cliff [6] | Nothing | Local notifications: daily-reward ~24h, streak ~20h, opt-in prompt |
| **Analytics** | Curve, funnel, pricing are all data-tuned [6][8] | Zero telemetry | Log level start/complete/fail, ad shown/completed, IAP, session length |
| **Rating prompt** | Ask right after a high moment | No prompt | Native review request after 5th clear / first 3-star, fires once |

## Tier 2 — Monetization depth

*The cozy audience is the least tolerant of friction [2]; every mechanic here has
to feel like a helping hand, not a wall.*

| Gap | Top games | We have | Add |
|---|---|---|---|
| **Fail state & fail offers** | Move limits turn a loss into a continue/booster/discount purchase [2][7] | Unlimited moves, unlimited free undo | Generous move budget on post-tutorial levels; out of moves → +moves via ad/coins or restart. No hard lives |
| **Premium currency** | Soft + hard (gems) + consumable boosters [4] | One currency (coins), no gem sink | Gems: earned slowly, bought in packs, spent on boosters/continues/exclusive decor |
| **Booster set (6+) + shop** | 69% of top puzzle games offer 6+ boosters [4] | 3, all effectively free | extra-moves, undo pack, empty-a-jar, auto-finish-a-colour, +2 jars, pre-level free spare; buy with coins or gems + bundles; meter free undo |
| **Piggy bank** | ~45% of top puzzle games [4] | Nothing | Bank fills from wins + booster use; one IAP cracks it |
| **Endless meta + collection album** | Seasonal collections became infinitely repeatable [3] | Finite cottage (~13 buys then "Restored", coins have no sink) | More rooms, then rotating decor sets + a collection album (sets, dupes, set bonuses) |
| **Starter pack & LTOs** | Value-heavy starter pack; offers timed to moments [7][8] | Four flat SKUs, no context | 24h starter pack; "struggling? bundle" after 2 fails on a level |

## Tier 3 — Retention & live-ops

*Install-weighted competitors hold ~52% / 27% / 14% at D1/D7/D30 [1]. Needs a
content cadence; a couple need a small backend. Plan post-soft-launch.*

| Gap | Top games | We have | Add |
|---|---|---|---|
| **Rotating weekly event** | Constant event calendar; competition + achievement hybrids where everyone earns [2][3] | None | Start with "clear N levels this week → chest" + a progress bar |
| **Daily jackpot** | Win one quick special board today for a big prize [3] | Login ladder + spin (both passive) | A once-daily bonus board that pays only on a win |
| **Battle pass** | Most dependable recurring-revenue layer; ~$120/yr per premium buyer [4][9]; add after month 2–3 [9] | None | Free + premium track tied to the weekly event and album; pair with piggy bank |
| **Leaderboards** | Weekly / country / global [3] | Single-player, offline | Weekly "stars earned" board; ghost/bot board until a backend exists |
| **Themed realms / world map** | ~$8–15K art each, +12–18% D30 retention [1] | Flat numbered list, one skin | Chapters that reskin the board (pantry → garden → attic → bakery), mapped to cottage rooms |
| **Play-streak & session-end hook** | "played N days" reward; win screen dangles the next goal [3] | Login + ad streak, no play streak; win panel just offers Next | Play-streak counter; show progress to next chest/room/set on win |
| **Cottage offline trickle** | Small "while you were away" payout as a return reason | Inert between sessions | Tiny capped coin trickle from restored rooms |

## Tier 4 — Store readiness

*Needed for public launch, not soft launch. Folds into the M7 art pass.*

| Gap | Add |
|---|---|
| Real art / font / music / icon set [11] | Commissioned jar/bead/cottage art, cozy display font, licensed music, full icon set |
| ASO, screenshots, privacy labels | Keyworded listing, 6–8 benefit-led screenshots, preview video, data-safety disclosures |
| Localization | Strings → translation table; top 5–8 markets first |
| QA / crash / device pass | Crash-reporting SDK + low-end Android / older-iPhone pass |

## If you do only three things

1. **Onboarding + an authored curve** — hand-build the first ~25 levels with a
   fail-free window and a deliberate first peak; don't open Daily on session one.
   Biggest D1–D7 lever, pure design time.
2. **A gentle fail state + fail offers** — a move budget and the
   continue/booster/discount offers it unlocks. All of Tier 2's revenue depends
   on this and nothing else.
3. **One weekly event + local notifications** — "clear N this week" with a
   progress bar, plus scheduled nudges. Cheapest D7–D30 lift available.

**One thing not to do:** don't answer "more monetization" with more ad buttons —
added rewarded placements don't raise RPD [8]. The wins are *depth* (currency
ladder, boosters, piggy bank, pass) and *timing* (fail offers, starter pack,
events), not volume. This audience walks at the first wall [2].

## Sources

1. Gamigion — Retention benchmark for sort puzzle games in 2026
2. PocketGamer.biz — How Magic Sort, Knit Out & Pixel Flow are redefining sort puzzle monetisation
3. Naavik — Live-ops trends powering mobile puzzle
4. GameRefinery — Boost your monetization with IAP mechanics
5. GameRefinery — 12 ways to take battle passes to the next level
6. Udonis — First-time user experience in mobile games
7. AppMagic — Hybridcasual puzzles: turning failure into revenue
8. Game Growth Advisor — Hybrid-casual game design & monetization 2026
9. StudioKrew — Mobile game monetization models that still work in 2026
10. designthegame.com / Blood Moon Interactive — game juice & haptics
11. BRSoftech — Best water sort puzzle games in 2026
12. Screw-sort store listings & reviews — ASMR / haptics / progressive difficulty

## Build status against this audit

Done:

- [x] **Headline fix** — gentle fail state (per-stage move budget) + fail offers
  (+moves via ad/coins, restart, skip-after-2-fails); undo now metered  *(M8)*
- [x] **Onboarding** — 4 hand-authored teaching levels + coach tips; brand-new
  players skip the daily pop-up on session one  *(M9)*
- [x] **Haptics** on pour/place/win + toggle  *(M10)*
- [x] **Settings screen** — SFX / music / haptics / restore / privacy line  *(M10)*
- [x] **Ambient music** — generated placeholder loop  *(M10)*
- [x] **Weekly event** — "clear 15 this week → 200 coins", in the Daily panel  *(M11)*
- [x] **Session-end hook** — win screen shows the next goal  *(M11)*
- [x] **Analytics** — local JSON event log (session/level/ad/iap); swap for an SDK  *(M11)*
- [x] **Review prompt** trigger after 5 cleared levels *(stub — needs a plugin)*  *(M11)*

Open:

- [ ] Authored difficulty curve beyond the first 4 levels (deliberate first peak, spike after ~L20)
- [ ] Local push notifications *(seam in `platform.gd`; needs a native plugin)*
- [ ] Endless cottage meta / rotating decor sets / collection album  *(dead coin sink today)*
- [ ] Gems (premium currency) + a 6+ booster set + shop bundles
- [ ] Piggy bank
- [ ] Starter pack + struggle-triggered offers
- [ ] Battle pass, leaderboards, daily jackpot, themed realms  *(need content cadence / a small backend)*
- [ ] Real art / font / music, ASO, localization, crash reporting  *(Tier 4, pre-launch)*
- [ ] Real ad SDK + real IAP bindings + real analytics SDK  *(one-file swaps at the seams)*
