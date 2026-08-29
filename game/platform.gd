extends Node
class_name Platform
## Stubs for the things Godot 4 can't do cross-platform without a native plugin:
## local push notifications and the OS in-app review prompt. The call sites are
## wired; drop a plugin in here (Android: godot-android-notification, iOS:
## UNUserNotificationCenter / SKStoreReviewController) and fill these in.

var _review_asked := false

func schedule_daily_reminder(hours := 24) -> void:
	_todo("daily-reward reminder in %dh" % hours)

func schedule_streak_warning(hours := 20) -> void:
	_todo("streak-about-to-break in %dh" % hours)

func cancel_reminders() -> void:
	_todo("cancel scheduled reminders")

func request_review() -> void:
	if _review_asked:
		return
	_review_asked = true
	_todo("OS in-app review prompt")

func _todo(what: String) -> void:
	if OS.is_debug_build():
		print("[platform TODO] ", what, "  — needs a native plugin")
