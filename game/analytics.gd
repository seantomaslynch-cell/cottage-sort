extends Node
class_name Analytics
## Lightweight local event log. Writes JSON lines to user://events.log (capped)
## so the funnel and difficulty curve can be inspected before a real analytics
## SDK is wired in. Swap flush() for an SDK call later; keep log_event().

const PATH := "user://events.log"
const MAX_LINES := 800
const FLUSH_EVERY := 20

var _buf: Array[String] = []

func log_event(name: String, props: Dictionary = {}) -> void:
	var row := {"t": int(Time.get_unix_time_from_system()), "e": name}
	for k in props:
		row[k] = props[k]
	_buf.append(JSON.stringify(row))
	if OS.is_debug_build():
		print("[evt] ", name, "  ", props)
	if _buf.size() >= FLUSH_EVERY:
		flush()

func flush() -> void:
	if _buf.is_empty():
		return
	var lines: Array = []
	if FileAccess.file_exists(PATH):
		lines = Array(FileAccess.open(PATH, FileAccess.READ).get_as_text().split("\n", false))
	lines.append_array(_buf)
	if lines.size() > MAX_LINES:
		lines = lines.slice(lines.size() - MAX_LINES)
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(PackedStringArray(lines)) + "\n")
	_buf.clear()

func _exit_tree() -> void:
	flush()
