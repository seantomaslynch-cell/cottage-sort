# App store kit — Cottage Sort

Draft listing copy, keywords, screenshot plan, and data-safety answers.
Free app, IAP + ads, everyone / 3+.

## Names

- **App name:** Cottage Sort
- **iOS subtitle (30 chars):** Cozy ball sort & home restore
- **Play short description (80):** A calm colour-sorting puzzle. Fill the jars, restore your little cottage.

## Keywords (iOS, ~100 chars, comma-separated, no spaces)

```
sort,ball sort,water sort,puzzle,cozy,relax,brain,jar,color,offline,home design,decorate,zen,logic
```

## Descriptions

**Short pitch (both stores, top of the full description):**

> Pour the coloured beads between jars until each one holds a single colour.
> Every clear earns coins you spend restoring a run-down cottage — patch the
> roof, plant the garden, decorate room by room. Simple to pick up, hard to
> put down.

**Full description (Play; iOS uses the same, trimmed):**

- **Sort at your own pace.** No timers, no lives, no pressure. Tap a jar, tap
  another, watch the colours settle.
- **Restore your cottage.** Coins from puzzles rebuild a cosy home and an
  endless collection of decor — new seasonal pieces every few weeks.
- **A reason to come back.** Daily rewards, a spin wheel, a weekly challenge,
  a once-a-day jackpot board, and a seasonal pass.
- **Boosters when you're stuck** — a colour magnet, a head start, extra moves.
  Optional. The puzzles are always solvable without them.
- **Play offline.** Your progress is saved on your device.

**What's New (template):**

> - New seasonal decor set in the Cottage.
> - Fresh levels in the [Chapter] chapter.
> - Balance tweaks and fixes.

## Screenshot plan (6–8, portrait)

| # | Shot | Caption |
|---|---|---|
| 1 | Board mid-pour, a colour completing | "Sort the colours. That's the whole game." |
| 2 | Win screen with 3 stars + coins | "Every clear pays out." |
| 3 | Cottage restore screen, ~40% | "Spend coins fixing up your cottage." |
| 4 | Decorate tab with a seasonal set | "Collect decor — new pieces every season." |
| 5 | A themed realm (Garden or Bakery board) | "Chapters that change the whole room." |
| 6 | Daily panel (login ladder + wheel + jackpot) | "Come back for the daily rewards." |
| 7 | Season pass tier list | "A season pass, if you want it." |
| 8 | Booster popup | "Boosters for the tricky ones — never required." |

App preview video (15–30s): a few satisfying pours → a jar completes with the
confetti → cut to the cottage warming up as tiers are bought.

## Data safety / privacy answers

Assuming AdMob + a billing plugin + one analytics SDK:

| Data | Collected | Purpose | Linked to identity | Shared |
|---|---|---|---|---|
| Advertising ID | Yes (ads SDK) | Advertising | No | Yes, to the ad network |
| Purchase history | Yes (billing) | App functionality | No | No |
| App interactions / crash logs | Yes (analytics) | Analytics, stability | No | No |
| Approximate location | Only if the ad SDK infers it from IP | Advertising | No | Yes, to the ad network |

- No account, no email, no contacts, no precise location, no photos.
- All data in transit over HTTPS.
- Users can reset the advertising ID at the OS level; "remove ads" IAP stops
  interstitials (rewarded stays opt-in).
- A privacy policy URL is **required** by both stores before an ads build can
  ship — host a short page covering the table above.

## Store config

- Category: Games → Puzzle (secondary: Casual).
- Content rating: PAL/ESRB Everyone, PEGI 3, USK 0 — no violence/language;
  declare "in-app purchases" and "ads".
- Price: Free.
- In-app products to create (ids must match `game/iap.gd`):
  `remove_ads`, `starter_pack`, `struggle_pack`, `booster_bundle`,
  `battle_pass`, `piggy_crack`, `gems_small`, `gems_medium`, `gems_large`,
  `coins_small`, `coins_medium`.
