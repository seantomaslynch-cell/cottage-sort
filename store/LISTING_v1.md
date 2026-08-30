# App Store listing — v1 (iOS, ads-only)

Paste-ready copy for the first submission. `store/METADATA.md` keeps the
fuller, IAP-inclusive copy for when purchases turn on in a later update.

Character limits in (parens). Counts checked against the text below.

---

## Name (30)
```
Cottage Sort
```

## Subtitle (30)
```
Cozy ball sort & home restore
```

## Promotional text (170)  — editable later without review
```
A calm colour-sorting puzzle with a cottage to rebuild. No timers, no lives —
pour the beads, tidy every jar, and spend what you earn making a run-down
cottage cozy again.
```

## Description (4000)
```
Pour the coloured beads from jar to jar until each one holds a single colour.
Every puzzle you clear earns coins, and every coin goes into restoring a little
cottage that has seen better days — patch the roof, plant the garden, and
decorate it room by room.

Easy to pick up. Quietly hard to put down.

• SORT AT YOUR OWN PACE — no timers, no lives, no pressure. Tap a jar, tap
  another, and watch the colours settle into place.
• RESTORE THE COTTAGE — coins from puzzles rebuild a two-room home and an
  ever-growing collection of decor, with new seasonal pieces rotating in.
• 120 HAND-MADE LEVELS plus endless play beyond them, across themed chapters
  that reskin the whole board — the Pantry, the Garden, the Bakery and more.
• A REASON TO RETURN — daily login rewards, a spin wheel, a weekly challenge,
  a once-a-day bonus puzzle, and a 28-day reward track.
• GENTLE HELP WHEN YOU'RE STUCK — a colour magnet, a head start, a few extra
  moves. Always optional; every level can be solved without them.
• PLAY OFFLINE — your progress saves on your device.

Free to play, supported by ads. No purchases in this version.
```

## Keywords (100, comma-separated, no spaces)
```
sort,ball sort,water sort,puzzle,cozy,relax,brain,jar,color,offline,decorate,cottage,zen,logic
```

## What's New (first release)
```
First release. Thanks for trying Cottage Sort — a calm little sorting puzzle
with a cottage to rebuild. Feedback and bug reports very welcome.
```

## URLs
- **Support URL:**  https://seantomaslynch-cell.github.io/cottage-sort/support.html
- **Marketing URL (optional):**  https://seantomaslynch-cell.github.io/cottage-sort/
- **Privacy Policy URL (required):**  https://seantomaslynch-cell.github.io/cottage-sort/privacy.html

  Repo is **public**, so serve straight from `docs/`: Settings → Pages →
  Source: Deploy from a branch → `master` / `/docs` → Save. Live in ~1 min at
  `https://seantomaslynch-cell.github.io/cottage-sort/`.

  **`app-ads.txt` caveat:** AdMob looks for it at the **root of the domain**
  in the store listing, not a sub-path — `…github.io/cottage-sort/app-ads.txt`
  will NOT be found. To make it work either (a) add a public repo named
  `seantomaslynch-cell.github.io` with `app-ads.txt` at its root, or (b) put a
  cheap custom domain in front of this Pages site. **Not a launch blocker** —
  it only improves ad fill/eCPM over the first few weeks. `docs/app-ads.txt`
  holds the record for whichever host you pick.

## Category & price
- Primary: **Games → Puzzle**.  Secondary: **Games → Casual**.
- Price: **Free**.

## Age rating → 4+
Every content question answered **None**. Simulated Gambling: **None** — the
spin wheel and daily bonus puzzle are free, have no wager, and no spins of
chance can be bought.

## App Privacy (nutrition label) — ads-only v1, Google AdMob only

No first-party analytics is transmitted in v1 (`analytics.gd` logs only to the
device). Declare exactly what the AdMob SDK collects:

| Data type | Collected | Linked to user | Used to track | Purpose |
|---|---|---|---|---|
| Device ID (advertising identifier) | Yes | No | **Yes** | Third-Party Advertising |
| Usage Data (ad interactions) | Yes | No | **Yes** | Third-Party Advertising |
| Coarse Location (from IP, by the ad SDK) | Yes | No | **Yes** | Third-Party Advertising |

- **Data used to track you:** advertising identifier, usage data, coarse location.
- **Not collected:** name, email, phone, contacts, photos, precise location,
  purchases, search history, user content, health, financial info.
- The **ATT prompt** is shown once before the first ad request
  (`main.gd` → `_ads.request_att()`), string = `Config.ATT_USAGE_DESCRIPTION`.
- If you later add a crash/analytics SDK, add a **Diagnostics** row
  (Not linked, not tracking, "App Functionality / Analytics").

## Export compliance
Uses only standard HTTPS / OS-provided encryption → in App Store Connect answer
**"No"** to "does your app use non-exempt encryption", or add
`ITSAppUsesNonExemptEncryption = false` to the plist.
