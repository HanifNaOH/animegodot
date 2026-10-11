extends Control

const ENTRIES := [
	{
		"title": "Build release candidate",
		"summary": "Artifact #2481 / signed 2 min ago",
		"detail": "The desktop and mobile packages are staged. Check the release checksum before publishing.",
		"status": "READY",
		"color": Color(0.82, 0.91, 0.84),
	},
	{
		"title": "Run integration checks",
		"summary": "12 of 14 checks complete",
		"detail": "The slow device-matrix run is still active. The remaining checks cover upgrade and restore paths.",
		"status": "RUNNING",
		"color": Color(0.79, 0.88, 0.93),
	},
	{
		"title": "Publish release notes",
		"summary": "Draft saved / awaiting final review",
		"detail": "The notes include the migration summary, resolved issues, and links to the signed artifacts.",
		"status": "QUEUED",
		"color": Color(0.94, 0.84, 0.74),
	},
]

var _list: VBoxContainer
var _slots: Array[Control] = []
var _visuals: Array[Control] = []
var _details: Array[Label] = []
var _detail_buttons: Array[Button] = []
var _layout: AnimeLayoutRuntime
var _active_flip: AnimeLayoutRuntime
var _transitioning := false


func _ready() -> void:
	_build_interface()
	_layout = Anime.create_layout(_list)


func _build_interface() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.94, 0.96, 0.93)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var page := MarginContainer.new()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.add_theme_constant_override("margin_left", 42)
	page.add_theme_constant_override("margin_top", 34)
	page.add_theme_constant_override("margin_right", 42)
	page.add_theme_constant_override("margin_bottom", 34)
	add_child(page)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	page.add_child(column)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	column.add_child(header)

	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_theme_constant_override("separation", 4)
	header.add_child(heading)

	var eyebrow := Label.new()
	eyebrow.text = "RELEASE 2.8.0  /  STAGING"
	eyebrow.add_theme_color_override("font_color", Color(0.26, 0.48, 0.40))
	eyebrow.add_theme_font_size_override("font_size", 12)
	heading.add_child(eyebrow)

	var title := Label.new()
	title.text = "Release queue"
	title.add_theme_color_override("font_color", Color(0.10, 0.18, 0.16))
	title.add_theme_font_size_override("font_size", 30)
	heading.add_child(title)

	var count := Label.new()
	count.text = "03  STEPS"
	count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count.add_theme_color_override("font_color", Color(0.30, 0.44, 0.39))
	count.add_theme_font_size_override("font_size", 13)
	header.add_child(count)

	_list = VBoxContainer.new()
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 12)
	column.add_child(_list)

	for index in ENTRIES.size():
		_add_entry(index, ENTRIES[index])

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 8)
	column.add_child(footer)

	var footer_rule := ColorRect.new()
	footer_rule.custom_minimum_size = Vector2(20, 2)
	footer_rule.color = Color(0.37, 0.66, 0.52)
	footer_rule.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	footer.add_child(footer_rule)

	var footer_label := Label.new()
	footer_label.text = "DEPLOYMENT PIPELINE  /  ALL TIMES UTC"
	footer_label.add_theme_color_override("font_color", Color(0.39, 0.49, 0.44))
	footer_label.add_theme_font_size_override("font_size", 11)
	footer.add_child(footer_label)


func _add_entry(index: int, entry: Dictionary) -> void:
	var slot := Control.new()
	slot.custom_minimum_size = Vector2(0, 116)
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_child(slot)
	_slots.append(slot)

	var visual := PanelContainer.new()
	visual.name = "Visual"
	visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visual.add_theme_stylebox_override("panel", _card_style(entry["color"]))
	slot.add_child(visual)
	_visuals.append(visual)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 12)
	visual.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 5)
	margin.add_child(content)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 12)
	content.add_child(title_row)

	var entry_title := Label.new()
	entry_title.text = "%02d  %s" % [index + 1, entry["title"]]
	entry_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry_title.add_theme_color_override("font_color", Color(0.10, 0.18, 0.16))
	entry_title.add_theme_font_size_override("font_size", 17)
	title_row.add_child(entry_title)

	var status := Label.new()
	status.text = entry["status"]
	status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status.add_theme_color_override("font_color", Color(0.25, 0.39, 0.34))
	status.add_theme_font_size_override("font_size", 11)
	title_row.add_child(status)

	var summary_row := HBoxContainer.new()
	summary_row.add_theme_constant_override("separation", 12)
	content.add_child(summary_row)

	var summary := Label.new()
	summary.text = entry["summary"]
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.add_theme_color_override("font_color", Color(0.32, 0.43, 0.39))
	summary.add_theme_font_size_override("font_size", 13)
	summary_row.add_child(summary)

	var detail_button := Button.new()
	detail_button.text = "Show details"
	detail_button.custom_minimum_size = Vector2(112, 30)
	detail_button.pressed.connect(_toggle_details.bind(index))
	summary_row.add_child(detail_button)
	_detail_buttons.append(detail_button)

	var detail := Label.new()
	detail.text = entry["detail"]
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_theme_color_override("font_color", Color(0.23, 0.34, 0.30))
	detail.add_theme_font_size_override("font_size", 13)
	detail.visible = false
	content.add_child(detail)
	_details.append(detail)


func _toggle_details(index: int) -> void:
	if _transitioning or index < 0 or index >= _slots.size():
		return
	_transitioning = true
	var options := AnimeLayoutOptions.new()
	options.duration = 0.46
	options.ease = AnimeEase.OUT_CUBIC
	options.size_ease = AnimeEase.IN_OUT_CUBIC
	var flip := _layout
	_active_flip = flip
	var detail := _details[index]
	var expanded := not detail.visible
	if expanded:
		var detail_modulate := detail.modulate
		detail_modulate.a = 0.0
		detail.modulate = detail_modulate
		flip.started.connect(_fade_in_detail.bind(detail, options.duration), CONNECT_ONE_SHOT)
	await flip.update(func(_root: Control) -> void:
		detail.visible = expanded
		_slots[index].custom_minimum_size.y = 174.0 if expanded else 116.0
		_detail_buttons[index].text = "Hide details" if expanded else "Show details"
		_list.queue_sort()
	, options)
	_active_flip = null
	_transitioning = false


func _fade_in_detail(_started_layout: AnimeLayoutRuntime, detail: Label, transition_duration: float) -> void:
	var tween := Anime.tween(detail)
	tween.options.duration = minf(0.18, transition_duration)
	tween.options.ease = AnimeEase.OUT_CUBIC
	tween.track(AnimeCanvasItem.alpha_to(1.0))
	tween.play()


func _card_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.shadow_color = Color(0.08, 0.16, 0.13, 0.12)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	return style