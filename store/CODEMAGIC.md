# Building & publishing with Codemagic

Codemagic runs the macOS build machines, code signing, and store upload — so
**no local Mac is needed**. `codemagic.yaml` (repo root) defines three
workflows: `ios-release`, `android-release`, `web-release`.

## One-time setup in the Codemagic UI

1. **Add the app** — connect this GitHub repo (`seantomaslynch-cell/cottage-sort`).
2. **Environment variable groups** (App settings → Environment variables). Create
   these group names and add the vars; mark secrets as "Secure":

   | Group | Variables |
   |---|---|
   | `godot` | `GODOT_VERSION` = `4.7.2-stable` |
   | `appstore` | `APP_STORE_APP_ID` (the numeric App Store Connect app id), `BUNDLE_ID` = `com.example.cottagesort` |
   | `googleplay` | `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS` (paste the Play service-account JSON), `PACKAGE_NAME` = `com.example.cottagesort` |
   | `android_keys` | `CM_KEYSTORE` (upload keystore file — Codemagic base64-encodes it), `CM_KEYSTORE_PASSWORD`, `CM_KEY_ALIAS`, `CM_KEY_PASSWORD` |

3. **iOS code signing** — Teams → Integrations → **App Store Connect API key**.
   Create/upload an API key (Issuer ID + Key ID + `.p8`). Name the integration
   `CodemagicAppStoreKey` (matches `integrations.app_store_connect` in the yaml).
   Set signing to **Automatic** for bundle id `com.example.cottagesort`.
4. **Android signing** — generate a release keystore once
   (`keytool -genkey -v -keystore release.keystore -alias cottagesort -keyalg RSA -keysize 2048 -validity 10000`),
   upload it under the `android_keys` group.
5. **Google Play** — create a service account in Google Cloud with the Play
   Developer API enabled, grant it release access in Play Console, download the
   JSON, paste into `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS`.

## Before the first publish (store-side, still manual, one-time)

- **App Store Connect:** create the app record, register the bundle id, create
  every IAP in `Config.IAP_PRODUCT_IDS` with matching product ids, fill the
  metadata from `store/METADATA.md`, host `store/PRIVACY.md` and set the URL.
  See `store/APP_STORE_SUBMISSION.md` for the full list.
- **Play Console:** create the app, set up the store listing, create the IAPs,
  complete the data-safety form (`store/METADATA.md`), upload a first build to
  an internal track manually if Play requires it before API uploads work.
- Replace the placeholder art / SFX / music (`store/ASO.md`).
- Wire the real ad / IAP / analytics SDK plugins (`store/INTEGRATION.md`) and
  commit them under `android/plugins` + the iOS plugin config.

## Running it

- **Automatic:** add a build trigger (App settings → Build triggers) on push to
  `master` for the workflow you want.
- **Manual:** Start new build → pick `ios-release` / `android-release` /
  `web-release`.

### What each workflow does

- Downloads Godot `$GODOT_VERSION` + its export templates.
- `godot --headless --path . --import` (populates `.godot/`, the class cache).
- `godot --headless --export-release "<Preset>" <out>` using the presets in
  `export_presets.cfg`.
- iOS: Codemagic's automatic signing produces a signed `.ipa`; `publishing.app_store_connect`
  uploads to **TestFlight** (flip `submit_to_app_store: true` for a review submission).
- Android: builds a signed `.aab`; `publishing.google_play` uploads to the
  **internal** track as a draft (promote in Play Console).
- Web: exports and zips `build/web/` as an artifact.

## Notes / gotchas

- The `fetch_godot` script pulls from `godotengine/godot-builds` releases. If
  4.7.2 assets are named differently there, adjust the `BIN_ZIP` names.
- The iOS `.ipa` export from Godot on a Codemagic mac runner needs Xcode +
  valid signing in the keychain — both are provided by `environment.ios_signing`
  + the API key integration. If Godot emits an Xcode project instead of an
  `.ipa`, add an `xcode-project build-ipa` step after the export.
- `--install-android-build-template` needs the Android export templates (pulled
  by `fetch_godot`) and the Android SDK (installed in the android workflow).
- Bump `application/version` (build number) per build — the iOS workflow derives
  it from the latest TestFlight build number; for Android, Play rejects a
  duplicate `versionCode`, so wire `package/version_code` to `$PROJECT_BUILD_NUMBER`
  in the preset or a pre-export script.
