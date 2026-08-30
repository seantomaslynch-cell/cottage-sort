# Cottage Sort — iOS launch checklist (ads-only v1)

One list that ties the other `store/` docs together. Check items off as you go.

**Legend:** `[x]` done · `[ ]` your action · `[~]` blocked until a build exists

## Known values (already wired into the repo)

| | |
|---|---|
| App name | Cottage Sort |
| Apple Team ID | `U34G42XFT8` |
| App Store Connect app (adamId) | `6806743872` |
| Bundle ID | `com.seanlynch.cottagesort` |
| AdMob publisher | `pub-5040304268747359` |
| AdMob iOS app ID | `ca-app-pub-5040304268747359~5303167211` |
| AdMob iOS rewarded | `ca-app-pub-5040304268747359/9888902188` |
| AdMob iOS interstitial | `ca-app-pub-5040304268747359/2101911509` |
| Support email | `temveno@gmail.com` |
| Repo | `github.com/seantomaslynch-cell/cottage-sort` (public) |

---

## Phase 0 — Accounts & identifiers

- [x] Apple Developer Program membership active
- [x] App Store Connect app record created (`6806743872`)
- [x] Team ID, AdMob iOS app + 2 ad units, publisher ID — all in `game/config.gd` + `export_presets.cfg` + `codemagic.yaml`
- [x] **Bundle ID** `com.seanlynch.cottagesort` registered (matches
      `export_presets.cfg`, `codemagic.yaml`, `game/config.gd`)
- [ ] Confirm the App Store Connect record's Bundle ID = `com.seanlynch.cottagesort`
      (Apps → Cottage Sort → App Information)

## Phase 1 — Hosting (privacy / support / app-ads.txt)

- [x] `docs/` static site written (index / privacy / support / app-ads.txt / .nojekyll)
- [x] GitHub Pages enabled — live at `https://seantomaslynch-cell.github.io/cottage-sort/`
- [ ] **Fix the Pages source:** it's currently serving from the repo **root**
      (shows the README, and `docs/` pages only work under `/docs/…`). Change
      Settings → Pages → Branch folder from `/ (root)` to **`/docs`** → Save.
      After that the clean URLs below work and `/` shows the player-facing page.
- [ ] Verify the 3 URLs load (after the source fix):
      - `https://seantomaslynch-cell.github.io/cottage-sort/`
      - `https://seantomaslynch-cell.github.io/cottage-sort/privacy.html`
      - `https://seantomaslynch-cell.github.io/cottage-sort/support.html`
      *(if you leave the source on root instead, the working URLs are the same
      with `/docs/` inserted — then update `game/config.gd` + `LISTING_v1.md` to match)*
- [ ] *(later, not blocking)* app-ads.txt at a real domain root — either add a
      public `seantomaslynch-cell.github.io` repo with `app-ads.txt` at its root,
      or put a custom domain in front of the Pages site. Only affects ad fill/eCPM.

## Phase 2 — First build → TestFlight

- [x] `codemagic.yaml` `ios-release` workflow written
- [ ] **App Store Connect API key:** App Store Connect → Users and Access →
      Integrations → App Store Connect API → generate a key with **App Manager**
      role. Download the `.p8` (one chance), note the **Key ID** and **Issuer ID**.
- [ ] **Codemagic setup** (codemagic.io):
  - [ ] Add application → connect `seantomaslynch-cell/cottage-sort`
  - [ ] Teams → Integrations → **App Store Connect API key** → upload the `.p8`
        + Key ID + Issuer ID → name it exactly **`CodemagicAppStoreKey`**
  - [ ] iOS signing → **Automatic**, bundle id `com.seanlynch.cottagesort`,
        team `U34G42XFT8`
  - [ ] Environment variable groups (App settings → Environment variables):
    - [ ] `godot` → `GODOT_VERSION` = `4.7.2-stable`
    - [ ] `appstore` → `APP_STORE_APP_ID` = `6806743872`,
          `BUNDLE_ID` = `com.seanlynch.cottagesort`
  - [ ] *(do NOT need `googleplay` / `android_keys` groups for v1)*
- [ ] Start a build of `ios-release` (Start new build → pick the workflow)
- [ ] Build passes: an `.ipa` artifact appears and uploads to TestFlight
- [ ] TestFlight processes the build (Apple's ~10-30 min), no "missing
      compliance" flag (see Phase 4 export compliance)
- [ ] Install on your iPhone via TestFlight

**If the build fails:** most likely the Godot iOS export template, a plugin
compile error, or signing. Read the Codemagic log; `store/CODEMAGIC.md` has the
setup detail.

## Phase 3 — On-device verification

Ads are **fully wired** (commit `c7bf0fc`): AdmobPlugin editor plugin enabled,
`addons/AdmobPlugin/export.cfg` drives the plist injection, `USE_ADMOB_PLUGIN`
is true, `ads.gd` uses the real plugin API, the ~26 MB Google SDK is committed
(no CI download). `Config.ADS_FORCE_TEST = true` + `export.cfg is_real=false`
→ **Google TEST ads** in every build until the real launch.

- [ ] Game launches, no crash, portrait, respects the notch / home indicator
- [ ] Touch: pours, drags, all menu screens, settings toggles
- [ ] Performance is smooth (watch the board with combos + confetti)
- [ ] Save/resume works across app kill + relaunch
- [ ] **ATT prompt** appears once before the first ad
- [ ] A **rewarded** ad shows (Google test ad), reward granted only on completion
- [ ] An **interstitial** shows between levels, 90s cooldown holds
- [ ] EEA/UK: the Google UMP consent form appears — set up the GDPR message in
      the AdMob console first (until then the SDK serves non-personalised ads)
- [ ] If ads *don't* show: check the Codemagic build log for the AdmobPlugin
      export step, and that `ios/framework/*.xcframework` linked. Reconcile
      method/signal names in `ads.gd` against `addons/AdmobPlugin/Admob.gd` if
      the installed plugin version differs.
- [ ] **Recapture the 5 screenshots** from this build (no debug button / toast)
- [ ] **Screenshots:** recapture the 5 in `store/screenshots/` from this build (no
      "+1 day (debug)" button, no stray toast) — either regenerate via
      `tools/make_store_shots.gd` against release-config raws, or screenshot
      on-device and drop them in
- [ ] Play 15-20 levels for feel; note anything that needs a balance tweak

## Phase 4 — App Store Connect listing

All copy is in **`store/LISTING_v1.md`** — paste from there.

- [ ] App Information: name, subtitle, category **Puzzle** (secondary **Casual**),
      no content rights issues
- [ ] Pricing: **Free**, all territories
- [ ] Version metadata: promotional text, description, keywords, "What's New"
- [ ] **App icon:** upload `store/icon_1024.png` (1024², RGB, no alpha)
- [ ] **Screenshots:** upload the 6.7" set (1290×2796). One set covers 6.5"/6.9" too.
- [ ] **Support URL:** `https://seantomaslynch-cell.github.io/cottage-sort/support.html`
- [ ] **Marketing URL** (optional): `https://seantomaslynch-cell.github.io/cottage-sort/`
- [ ] **Privacy Policy URL:** `https://seantomaslynch-cell.github.io/cottage-sort/privacy.html`
- [ ] **App Privacy** ("nutrition label"): 3 rows — advertising identifier,
      usage data, coarse location — all *Not linked to you*, all *Used to track
      you*, purpose *Third-Party Advertising*. Nothing else. (Table in LISTING_v1.md.)
- [ ] **Age rating:** answer every question **None** → 4+. Simulated Gambling =
      None (spin/jackpot are free, no wager, no purchasable chance).
- [x] **Export compliance:** `ITSAppUsesNonExemptEncryption` = `false` is in the
      plist (`export_presets.cfg`) — no compliance question to answer
- [ ] **In-App Purchases:** none for v1 — leave the section empty
- [ ] Assign the processed build to the version
- [ ] "Sign-in required" = No; demo account = not needed

## Phase 5 — Submit & review

- [ ] Submit for review (manual release, or auto-release on approval — your call)
- [ ] Watch for reviewer messages in App Store Connect (Resolution Center).
      Common ads-app asks: ATT implementation, privacy label accuracy, a working
      support URL — all covered above.
- [ ] On approval: release

## Phase 6 — Post-launch

- [ ] AdMob console: link the app to its App Store listing (reduces invalid
      traffic), set up the GDPR/UMP message, add your test device IDs to
      `Config.ADMOB_TEST_DEVICE_IDS` for future local testing
- [ ] Fix `app-ads.txt` at a real domain root (Phase 1 note) and wait for AdMob
      to crawl it (can take weeks)
- [ ] Watch: crash-free rate (add a crash SDK if it's bad), D1/D7 retention,
      ad eCPM, review sentiment
- [ ] Tune the difficulty curve / economy from real data
      (`game/levels.gd` knobs, `tools/analyze_events.py`)

### When you launch for real (flip off test ads)

- [ ] `game/config.gd`: `ADS_FORCE_TEST = false`
- [ ] `addons/AdmobPlugin/export.cfg`: `[General] is_real = true`
- [ ] Both must agree. Commit, rebuild — now serving live ads.

### Deferred to later updates

- [ ] **IAP:** it stays off for v1 (`GameIap.ENABLED = false`). Real StoreKit
      needs an iOS billing plugin (not in the repo — e.g. a cengiz-pz or
      godot-ios billing plugin) **and** the 11 products created in App Store
      Connect from `store/METADATA.md`. Then set `GameIap.ENABLED = true`, wire
      `iap.gd`'s `purchase()` to the plugin, add the Purchases row to the App
      Privacy label, and update the description.
- [ ] **Push notifications:** native plugin into `game/platform.gd`
- [ ] **Android:** real AdMob Android app + 2 units → `Config.ADMOB_*_ANDROID`;
      `com.seanlynch.cottagesort` as the package name in the Android preset;
      Play Console + `codemagic.yaml` `android-release`
- [ ] **Crash / analytics SDK** → add the Diagnostics row to the privacy label
- [ ] **Real bitmap art / more music** (procedural art ships as-is for v1)
- [ ] Optional content: the "No spares / Tight Squeeze" level variant

---

## `store/` doc map

| File | What |
|---|---|
| `LAUNCH_CHECKLIST.md` | this file |
| `LISTING_v1.md` | paste-ready App Store copy for v1 (ads-only) |
| `METADATA.md` | fuller copy incl. IAP, for a later update |
| `ASO.md` | keyword / screenshot / positioning notes |
| `CODEMAGIC.md` | Codemagic setup detail |
| `APP_STORE_SUBMISSION.md` | long-form submission notes |
| `INTEGRATION.md` | SDK-swap guide (ads / IAP / analytics / notifications) |
| `PRIVACY.md` | privacy template (hosted version is `docs/privacy.html`) |
| `ASSETS.md` | asset-pack + art rationale |
