extends RefCounted
class_name Config
## Placeholders for the values a live build needs. Nothing here is used by the
## stubs; the real ad/IAP/analytics/notification code (see store/INTEGRATION.md)
## reads from here so wiring the SDKs is fill-in-the-blanks.
##
## Do NOT commit real keys. In a real project, load these from an untracked
## `config.local.gd` / an env / a build-time generated file and keep this as the
## example.

# --- AdMob ---------------------------------------------------------------------
const ADMOB_APP_ID_ANDROID := "ca-app-pub-0000000000000000~0000000000"
const ADMOB_APP_ID_IOS     := "ca-app-pub-0000000000000000~0000000000"
const ADMOB_REWARDED_ANDROID     := "ca-app-pub-0000000000000000/0000000000"
const ADMOB_REWARDED_IOS         := "ca-app-pub-0000000000000000/0000000000"
const ADMOB_INTERSTITIAL_ANDROID := "ca-app-pub-0000000000000000/0000000000"
const ADMOB_INTERSTITIAL_IOS     := "ca-app-pub-0000000000000000/0000000000"
const ADMOB_TEST_DEVICE_IDS: Array[String] = []   # add your device IDs while developing

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
const PRIVACY_POLICY_URL := "https://example.com/cottage-sort/privacy"
const SUPPORT_EMAIL := "support@example.com"
const BUNDLE_ID := "com.example.cottagesort"   # match export_presets.cfg + stores

# --- Notifications --------------------------------------------------------------
const NOTIF_DAILY_TITLE := "Cottage Sort"
const NOTIF_DAILY_BODY := "Your daily reward is waiting."
const NOTIF_STREAK_TITLE := "Cottage Sort"
const NOTIF_STREAK_BODY := "Don't lose your login streak — pop in for today's reward."
