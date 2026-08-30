extends CanvasLayer
class_name BattlePassPanel
## The season track: XP bar, a scrollable tier list (free + premium rewards),
## claim-all buttons, and an "unlock premium" button. Emits intents.

signal claim_free_pressed
signal claim_premium_pressed
signal unlock_pressed
signal skip_pressed
signal closed

var bp: BattlePass = null

var _head: Label
var _bar_fill: ColorRect
var _bar_lbl: Label
var _list: VBoxContainer
var _claim_free_btn: Button
var _claim_prem_btn: Button
var _unlock_btn: Button
var _skip_btn: Button
var _toast: Label

func _ready() -> void:
	layer = 22
	visible = false

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Palette.BG
	add_child(bg)

	_head = _label("Season pass", 34)
	_head.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_head.offset_left = 24.0
	_head.offset_top = 22.0
	add_child(_head)

	# XP bar
	var bar_bg := ColorRect.new()
	bar_bg.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar_bg.offset_left = 24.0
	bar_bg.offset_right = -24.0
	bar_bg.offset_top = 74.0
	bar_bg.custom_minimum_size = Vector2(0, 22)
	bar_bg.color = Palette.CARD_BORDER
	add_child(bar_bg)
	_bar_fill = ColorRect.new()
	_bar_fill.color = Palette.ACCENT
	_bar_fill.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	_bar_fill.offset_top = 0.0
	_bar_fill.offset_bottom = 22.0
	bar_bg.add_child(_bar_fill)
	_bar_lbl = _label("", 18)
	_bar_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_bar_lbl.offset_top = 100.0
	_bar_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_bar_lbl)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_TOP_WIDE)
	scroll.offset_left = 24.0
	scroll.offset_right = -24.0
	scroll.offset_top = 134.0
	scroll.anchor_bottom = 1.0
	scroll.offset_bottom = -196.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_list)

	var claim_row := HBoxContainer.new()
	claim_row.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	claim_row.offset_left = 24.0
	claim_row.offset_right = -24.0
	claim_row.offset_top = -186.0
	claim_row.offset_bottom = -128.0
	claim_row.alignment = BoxContainer.ALIGNMENT_CENTER
	claim_row.add_theme_constant_override("separation", 14)
	add_child(claim_row)
	_claim_free_btn = _button("Claim free", 22)
	_claim_free_btn.custom_minimum_size = Vector2(210, 56)
	_claim_free_btn.pressed.connect(func() -> void: claim_free_pressed.emit())
	claim_row.add_child(_claim_free_btn)
	_claim_prem_btn = _button("Claim premium", 22)
	_claim_prem_btn.custom_minimum_size = Vector2(230, 56)
	_claim_prem_btn.pressed.connect(func() -> void: claim_premium_pressed.emit())
	claim_row.add_child(_claim_prem_btn)
	_skip_btn = _button("Skip tier", 22)
	_skip_btn.custom_minimum_size = Vector2(190, 56)
	_skip_btn.pressed.connect(func() -> void: skip_pressed.emit())
	claim_row.add_child(_skip_btn)

	var bottom := HBoxContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 24.0
	bottom.offset_right = -24.0
	bottom.offset_top = -110.0
	bottom.offset_bottom = -44.0
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 14)
	add_child(bottom)
	_unlock_btn = _button("Unlock premium  $4.99", 22)
	_unlock_btn.custom_minimum_size = Vector2(300, 64)
	_unlock_btn.pressed.connect(func() -> void: unlock_pressed.emit())
	bottom.add_child(_unlock_btn)
	var close := _button("Back to puzzles", 22)
	close.custom_minimum_size = Vector2(240, 64)
	close.pressed.connect(func() -> void: closed.emit())
	bottom.add_child(close)

	_toast = _label("", 26)
	_toast.add_theme_color_override("font_color", Palette.ACCENT_WARM)
	_toast.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_toast.offset_top = 100.0
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.modulate.a = 0.0
	add_child(_toast)

func flash(text: String) -> void:
	_toast.text = text
	_toast.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(0.9)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.5)

func set_pass(b: BattlePass) -> void:
	bp = b

func open() -> void:
	visible = true
	refresh()

func refresh() -> void:
	if bp == null:
		return
	var reached := bp.tier_reached()
	var owned := bp.pass_owned()
	_head.text = "Season pass   ·   %d days left" % bp.days_left()
	var into := bp.xp() % BattlePass.XP_PER_TIER
	_bar_fill.anchor_right = clampf(float(into) / BattlePass.XP_PER_TIER, 0.0, 1.0) if reached < BattlePass.TIERS else 1.0
	_bar_lbl.text = "Tier %d / %d    ·    %d XP" % [reached, BattlePass.TIERS, bp.xp()]

	_claim_free_btn.disabled = reached <= bp.free_claimed()
	_claim_prem_btn.disabled = not owned or reached <= bp.prem_claimed()
	# Ads-only v1: the premium track isn't purchasable yet.
	_unlock_btn.visible = not owned and GameIap.ENABLED
	if reached >= BattlePass.TIERS:
		_skip_btn.text = "Max tier"
		_skip_btn.disabled = true
	else:
		_skip_btn.text = "Skip tier  ·  %dg" % bp.skip_cost()
		_skip_btn.disabled = false

	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	for t in range(1, BattlePass.TIERS + 1):
		_list.add_child(_tier_row(t, reached, owned))

func _tier_row(t: int, reached: int, owned: bool) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var tl := _label("T%d" % t, 20)
	tl.custom_minimum_size = Vector2(46, 0)
	tl.add_theme_color_override("font_color",
		Palette.ACCENT_WARM if t <= reached else Palette.INK_FAINT)
	row.add_child(tl)

	var fr := BattlePass.reward(t, false)
	var free := _label(_reward_text(fr), 19)
	free.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if t <= bp.free_claimed():
		free.add_theme_color_override("font_color", Palette.INK_FAINT)
	row.add_child(free)

	var pr := BattlePass.reward(t, true)
	var prem := _label(_reward_text(pr) + ("" if owned else "  (locked)"), 19)
	prem.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prem.add_theme_color_override("font_color",
		Palette.INK if owned and t > bp.prem_claimed() else Palette.INK_FAINT)
	row.add_child(prem)
	return row

func _reward_text(r: Dictionary) -> String:
	var parts: Array = []
	if int(r.get("coins", 0)) > 0:
		parts.append("%dc" % int(r["coins"]))
	if int(r.get("gems", 0)) > 0:
		parts.append("%dg" % int(r["gems"]))
	if r.has("booster"):
		parts.append("+booster")
	return "  ".join(parts)

func _label(t: String, fs: int) -> Label:
	var l := Label.new()
	l.text = t
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", Palette.INK)
	return l

func _button(t: String, fs: int) -> Button:
	var b := Button.new()
	b.text = t
	b.add_theme_font_size_override("font_size", fs)
	return b
