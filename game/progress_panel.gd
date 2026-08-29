extends CanvasLayer
class_name ProgressPanel
## Your record: three tabs over one scroll view.
##   Stats       — a read-only profile of lifetime numbers
##   Collection  — every decor piece, owned (name + flavour) or locked (silhouette)
##   Badges      — the achievement gallery (earned / progress)

signal closed

var _eco: Economy
var _daily: Daily
var _bp: BattlePass
var _ach: Achievements

var _title: Label
var _tabs: HBoxContainer
var _list: VBoxContainer
var _tab := "stats"

func set_refs(economy: Economy, daily: Daily, bp: BattlePass, ach: Achievements) -> void:
	_eco = economy
	_daily = daily
	_bp = bp
	_ach = ach

func _ready() -> void:
	layer = 21
	visible = false

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Palette.BG
	add_child(bg)

	_title = _label("Progress", 34, Palette.INK)
	_title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_title.offset_left = 24.0
	_title.offset_top = 22.0
	add_child(_title)

	_tabs = HBoxContainer.new()
	_tabs.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_tabs.offset_top = 72.0
	_tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	_tabs.add_theme_constant_override("separation", 10)
	add_child(_tabs)
	for spec in [["Stats", "stats"], ["Collection", "collection"], ["Badges", "badges"]]:
		var b := _button(spec[0], 22)
		b.custom_minimum_size = Vector2(180, 56)
		var which: String = spec[1]
		b.pressed.connect(func() -> void: _show(which))
		_tabs.add_child(b)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 24.0
	scroll.offset_right = -24.0
	scroll.offset_top = 140.0
	scroll.offset_bottom = -104.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_list)

	var back := _button("Back", 24)
	back.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	back.offset_left = 210.0
	back.offset_right = -210.0
	back.offset_top = -84.0
	back.offset_bottom = -28.0
	back.pressed.connect(func() -> void: closed.emit())
	add_child(back)

func open(tab := "stats") -> void:
	visible = true
	_show(tab)

func _show(which: String) -> void:
	_tab = which
	for i in _tabs.get_child_count():
		(_tabs.get_child(i) as Button).disabled = (["stats", "collection", "badges"][i] == which)
	_clear()
	match which:
		"stats": _build_stats()
		"collection": _build_collection()
		"badges": _build_badges()

# ---------------------------------------------------------------- stats -----

func _build_stats() -> void:
	var s: int = int(SaveData.data.get("stat_deepest", 0))
	_list.add_child(_head("The tidying"))
	_stat("Levels cleared", str((SaveData.data.get("completed", {}) as Dictionary).size()))
	_stat("Stars earned", "%d ★" % SaveData.total_stars())
	_stat("Levels 3-starred", str(_stars3()))
	_stat("Flawless clears", str(int(SaveData.data.get("stat_flawless", 0))))
	_stat("Best combo", "x%d" % int(SaveData.data.get("stat_best_combo", 0)))
	_stat("Furthest level", str(s + 1))

	_list.add_child(_head("The cottage"))
	_stat("Restored", "%d%%" % (roundi(_eco.restored_fraction() * 100.0) if _eco != null else 0))
	_stat("Decor collected", str(_eco.decor_count() if _eco != null else 0))
	_stat("Sets completed", str(_eco.sets_complete_count() if _eco != null else 0))

	_list.add_child(_head("Habit"))
	var ls: int = _daily.login_streak() if _daily != null else 0
	_stat("Login streak", "%d day%s" % [ls, "" if ls == 1 else "s"])
	_stat("Days played", str(int(SaveData.data.get("stat_days_played", 0))))
	_stat("Weekly chests", str(int(SaveData.data.get("stat_week_chests", 0))))
	_stat("Jackpots won", str(int(SaveData.data.get("stat_jackpot_wins", 0))))
	_stat("Battle-pass tier", str(_bp.tier_reached() if _bp != null else 0))

	_list.add_child(_head("All time"))
	_stat("Coins earned", str(int(SaveData.data.get("stat_coins_earned", 0))))
	_stat("Achievements", "%d / %d" % [_ach.unlocked_count() if _ach != null else 0, Achievements.LIST.size()])

func _stat(k: String, v: String) -> void:
	var row := HBoxContainer.new()
	var kl := _label(k, 22, Palette.INK)
	kl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(kl)
	row.add_child(_label(v, 22, Palette.ACCENT_WARM))
	var card := _card()
	card.get_child(0).add_child(row)
	_list.add_child(card)

# ------------------------------------------------------------ collection ----

func _build_collection() -> void:
	var owned_total := 0
	var grand_total := 0
	for set_name in DecorData.set_names():
		var items: Array = DecorData.SETS[set_name]
		grand_total += items.size()
		var have := 0
		for it in items:
			if _eco != null and _eco.owns_decor(it["id"]):
				have += 1
		owned_total += have
		_list.add_child(_head("%s   %d / %d" % [set_name, have, items.size()]))
		for it in items:
			_list.add_child(_decor_row(it))

	var cur: String = DecorData.current_season()["name"]
	for season in DecorData.SEASONS:
		var items2: Array = season["items"]
		var have2 := 0
		for it in items2:
			if _eco != null and _eco.owns_decor(it["id"]):
				have2 += 1
		var tag := "this season" if season["name"] == cur else "past season"
		_list.add_child(_head("%s   (%s -  %d / %d)" % [season["name"], tag, have2, items2.size()]))
		for it in items2:
			_list.add_child(_decor_row(it))

	_list.add_child(_head("Sundries   (never ends -  %d owned)" % (_eco._endless_bought() if _eco != null else 0)))
	if _eco != null:
		_list.add_child(_decor_row(_eco.next_endless()))

func _decor_row(it: Dictionary) -> Control:
	var owned := _eco != null and _eco.owns_decor(it["id"])
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	var top := HBoxContainer.new()
	var nm := _label(it["name"] if owned else "▢  ???", 23, Palette.INK if owned else Palette.INK_FAINT)
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(nm)
	top.add_child(_label("owned" if owned else "%dc" % int(it.get("cost", 0)), 19, Palette.ACCENT_WARM))
	box.add_child(top)
	box.add_child(_label(it.get("flavour", "") if owned else "not yet in the collection", 18, Palette.INK_FAINT))
	var card := _card()
	card.get_child(0).add_child(box)
	return card

# --------------------------------------------------------------- badges -----

func _build_badges() -> void:
	if _ach == null:
		return
	_list.add_child(_head("%d / %d earned" % [_ach.unlocked_count(), Achievements.LIST.size()]))
	for cat in Achievements.CATS:
		_list.add_child(_head(cat))
		for a in Achievements.LIST:
			if a["cat"] == cat:
				_list.add_child(_badge_row(a))

func _badge_row(a: Dictionary) -> Control:
	var id: String = a["id"]
	var done := _ach.unlocked(id)
	var p: Vector2i = _ach.progress(id)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	var top := HBoxContainer.new()
	var nm := _label(a["name"], 23, Palette.INK if done else Palette.INK_FAINT)
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(nm)
	var rw := "+%dc" % int(a["coins"])
	if int(a["gems"]) > 0:
		rw += " +%dg" % int(a["gems"])
	top.add_child(_label("✓ earned" if done else rw, 19, Palette.ACCENT_WARM))
	box.add_child(top)
	box.add_child(_label(a["desc"], 18, Palette.INK_FAINT))
	if not done:
		var bar := ProgressBar.new()
		bar.max_value = p.y
		bar.value = p.x
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 13)
		box.add_child(bar)
		box.add_child(_label("%d / %d" % [p.x, p.y], 16, Palette.INK_FAINT))
	var card := _card()
	card.get_child(0).add_child(box)
	return card

# --------------------------------------------------------------- helpers ----

func _stars3() -> int:
	var n := 0
	for k in SaveData.data.get("stars", {}):
		if int(SaveData.data["stars"][k]) >= 3:
			n += 1
	return n

func _card() -> PanelContainer:
	var card := PanelContainer.new()
	var mc := MarginContainer.new()
	for m in ["margin_left", "margin_right"]:
		mc.add_theme_constant_override(m, 14)
	for m in ["margin_top", "margin_bottom"]:
		mc.add_theme_constant_override(m, 9)
	card.add_child(mc)
	return card

func _head(text: String) -> Label:
	return _label(text, 22, Palette.ACCENT_WARM)

func _clear() -> void:
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()

func _label(t: String, fs: int, col: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	return l

func _button(t: String, fs: int) -> Button:
	var b := Button.new()
	b.text = t
	b.add_theme_font_size_override("font_size", fs)
	return b
