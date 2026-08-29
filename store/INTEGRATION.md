# Wiring the real services

Everything below plugs into a **seam that already exists** in the codebase.
The game runs fully without any of it (stubs); each item is an isolated swap.

| Service | File to change | Keep the shape |
|---|---|---|
| Rewarded + interstitial ads | `game/ads.gd` | signals `rewarded_started` / `rewarded_finished(bool)` / `interstitial_shown`; methods `watch_rewarded(Callable)`, `maybe_show_interstitial()`, `remove_ads` flag |
| In-app purchases | `game/iap.gd` | `PRODUCTS` array, `product(id)`, `purchase(id)` -> emits `purchased(id)`, `restore()` -> emits `restored`, `owns(id)` |
| Analytics | `game/analytics.gd` | `log_event(name, props)` — that's the only call site the rest of the game uses |
| Local notifications | `game/platform.gd` | `schedule_daily_reminder(h)`, `schedule_streak_warning(h)`, `cancel_reminders()` |
| OS review prompt | `game/platform.gd` | `request_review()` (already rate-limited to once) |

## Ads (AdMob)

1. Add a Godot AdMob plugin (e.g. `admob-plus-godot` / `poing-studios/godot-admob`)
   as an Android/iOS plugin in `android/plugins` and the iOS export.
2. In `ads.gd`:
   - init the SDK in `_ready()` with your app IDs.
   - `watch_rewarded()` — load a rewarded ad, on `rewarded` callback grant, on
     close/`failed` still call `rewarded_finished(false)` and **don't** grant.
   - `maybe_show_interstitial()` — keep the `remove_ads` and cooldown guards
     already there; only the "show it" line changes to `interstitial.show()`.
3. Consent: run Google UMP (or an IAB TCF CMP) **before** the first ad request.
   Gate `_ready()`'s SDK init on consent resolved.
4. Register test device IDs while developing.
5. Ad unit IDs live in a config, not the source.

## IAP

1. Add a billing plugin: Google Play Billing (`godot-google-play-billing` /
   the built-in `GodotGooglePlayBilling` on 4.x Android) and StoreKit for iOS.
2. `PRODUCTS[*].id` must match the product IDs you create in Play Console /
   App Store Connect. Types: `remove_ads` = non-consumable; `starter_pack`,
   `struggle_pack`, `battle_pass` = non-consumable per season / one-time;
   `gems_*`, `coins_*`, `booster_bundle`, `piggy_crack` = consumable.
3. `purchase(id)`:
   - call the plugin's `purchase(id)`.
   - on the **purchase-acknowledged** callback, emit `purchased(id)` (main.gd
     already grants from there) and **acknowledge/consume** with the store.
   - on pending/cancelled/failed, do nothing.
4. `restore()` — query owned non-consumables, re-apply entitlements
   (`remove_ads`, `starter_bought`, `bp.owned`), then emit `restored`.
5. **Server-side receipt validation** before granting anything valuable in a
   live build. The stub grants immediately; a real build should verify.

## Analytics

1. Add GameAnalytics / Firebase Analytics / a lightweight HTTP sink.
2. In `analytics.gd`, replace `flush()` with the SDK's event call, or POST the
   buffered JSON lines. Keep `log_event()` and `_exit_tree()`.
3. Events already emitted (name -> props):
   `session_start {new_player}` ·
   `level_start {stage, budget}` ·
   `level_complete {stage, moves, stars, first}` ·
   `level_fail {stage, moves, n, offer}` ·
   `ad_reward` · `booster {id,cost}` · `booster_used {id}` ·
   `iap {id}` · `week_chest {amount}` · `week_chest`... ·
   `bp_claim {coins,gems}` · `jackpot_start` · `jackpot_win` ·
   `decor_buy {id}` · `decor_set {set,bonus}`.
   Add `interstitial_shown` and an `ad_reward` `placement` prop when you wire
   real ads (the analyzer script notes these gaps).

## Notifications

- **Android:** a local-notification plugin (`godot-android-notification-scheduler`
  or a small custom `NotificationChannel` + `AlarmManager` plugin). Schedule
  from `schedule_daily_reminder(24)` / `schedule_streak_warning(20)`; cancel the
  pending ones in `cancel_reminders()` and reschedule on app pause.
- **iOS:** `UNUserNotificationCenter` via a plugin; request authorization on
  first call, then `add(UNNotificationRequest ...)` with a time-interval trigger.
- Copy is already decided: "Your daily reward is waiting", "Don't lose your
  N-day streak".

## OS review prompt

- **Android:** Play In-App Review API (`ReviewManager`).
- **iOS:** `SKStoreReviewController.requestReview()` (or `AppStore.requestReview`
  on iOS 16+).
- `request_review()` is already called after the 5th cleared level and guarded
  to fire once.

## Build / signing

- Web: `tools/export_web.ps1` (works today; needs the Web export templates).
- Android: install the Android build template, set a keystore, add the ad/IAP
  plugins under `android/plugins`, target the current API level.
- iOS: export from a Mac, set the bundle ID + provisioning, add the iOS plugin
  frameworks, submit via Xcode / Transporter.
