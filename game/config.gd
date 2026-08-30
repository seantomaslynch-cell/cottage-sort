extends RefCounted
class_name Config
## Placeholders for the values a live build needs. Nothing here is used by the
## stubs; the real ad/IAP/analytics/notification code (see store/INTEGRATION.md)
## reads from here so wiring the SDKs is fill-in-the-blanks.
##
## Do NOT commit real SECRETS (analytics secret, signing keys, service creds) —
## load those from an untracked file / env at build time. AdMob app + ad-unit
## IDs are the exception: they ship inside every app binary and are not
## sensitive, so the real ones live here.

# --- AdMob -------------------------------------------------------------------
# PRODUCTION ids. iOS app "Cottage Sort" is live in AdMob; Android not created
# yet. NEVER point a build you personally test on at these — tapping your own
# live ads gets the AdMob account banned. Dev/TestFlight builds must use the
# ADMOB_*_TEST ids below (or register the device via ADMOB_TEST_DEVICE_IDS).
const ADMOB_PUBLISHER_ID         := "pub-5040304268747359"   # for app-ads.txt
const ADMOB_APP_ID_IOS           := "ca-app-pub-5040304268747359~5303167211"
const ADMOB_REWARDED_IOS         := "ca-app-pub-5040304268747359/9888902188"
const ADMOB_INTERSTITIAL_IOS     := "ca-app-pub-5040304268747359/2101911509"
const ADMOB_APP_ID_ANDROID       := "ca-app-pub-0000000000000000~0000000000"
const ADMOB_REWARDED_ANDROID     := "ca-app-pub-0000000000000000/0000000000"
const ADMOB_INTERSTITIAL_ANDROID := "ca-app-pub-0000000000000000/0000000000"

# Google's public test ids — safe to click. ads.gd should use these whenever
# OS.is_debug_build() or a soft-launch flag is set.
const ADMOB_APP_ID_TEST_IOS         := "ca-app-pub-3940256099942544~1458002511"
const ADMOB_APP_ID_TEST_ANDROID     := "ca-app-pub-3940256099942544~3347511713"
const ADMOB_REWARDED_TEST_IOS       := "ca-app-pub-3940256099942544/1712485313"
const ADMOB_REWARDED_TEST_ANDROID   := "ca-app-pub-3940256099942544/5224354917"
const ADMOB_INTERSTITIAL_TEST_IOS     := "ca-app-pub-3940256099942544/4411468910"
const ADMOB_INTERSTITIAL_TEST_ANDROID := "ca-app-pub-3940256099942544/1033173712"

const ADMOB_TEST_DEVICE_IDS: Array[String] = []   # add your device IDs while developing

# App Tracking Transparency — iOS shows this line in the permission dialog.
# Must also be set verbatim as NSUserTrackingUsageDescription in the iOS export
# preset (application/additional_plist_content).
const ATT_USAGE_DESCRIPTION := "Cottage Sort uses your device identifier to show ads that are more relevant to you."

# --- Store product IDs (must match game/iap.gd PRODUCTS ids) -----------------
# These are the *store* SKUs. Keep the ids identical on both platforms.
const IAP_PRODUCT_IDS: Array[String] = [
	"remove_ads", "starter_pack", "struggle_pack", "booster_bundle",
	"battle_pass", "piggy_crack",
	"gems_small", "gems_medium", "gems_large",
	"coins_small", "coins_medium",
]
# consumable vs non-consumable — the billing plugin needs to know which to consume
const IAP_NON_CONSUMABLE: Array[String] = ["remove_ads"]
const IAP_ONE_TIME_PER_SEASON: Array[String] = ["battle_pass"]
const IAP_ONE_TIME: Array[String] = ["starter_pack"]
# everything else in IAP_PRODUCT_IDS is consumable

# --- Analytics --------------------------------------------------------------
const ANALYTICS_KEY := "REPLACE_ME"
const ANALYTICS_SECRET := "REPLACE_ME"
const ANALYTICS_ENDPOINT := ""   # for a plain HTTP sink instead of an SDK

# --- Store / legal -------------------------------------------------------------
# Served from docs/ via GitHub Pages (Settings -> Pages -> master / /docs).
const MARKETING_URL     := "https://seantomaslynch-cell.github.io/cottage-sort/"
const PRIVACY_POLICY_URL := "https://seantomaslynch-cell.github.io/cottage-sort/privacy.html"
const SUPPORT_URL        := "https://seantomaslynch-cell.github.io/cottage-sort/support.html"
const SUPPORT_EMAIL := "REPLACE-WITH-SUPPORT-EMAIL"   # also in docs/support.html
const BUNDLE_ID := "com.seanlynch.cottagesort"   # match export_presets.cfg + stores
const APP_STORE_CONNECT_APP_ID := "6806743872"   # numeric adamId of the App Store Connect record
const APPLE_TEAM_ID := "U34G42XFT8"

# --- Notifications --------------------------------------------------------------
const NOTIF_DAILY_TITLE := "Cottage Sort"
const NOTIF_DAILY_BODY := "Your daily reward is waiting."
const NOTIF_STREAK_TITLE := "Cottage Sort"
const NOTIF_STREAK_BODY := "Don't lose your login streak — pop in for today's reward."
