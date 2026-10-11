@tool
extends Control

@export var step_number: int = 1:
	set(value):
		step_number = value
		_sync_text()
@export var step_title: String = "Build release candidate":
	set(value):
		step_title = value
		_sync_text()
@export var summary_text: String = "Artifact #2481 / signed 2 min ago":
	set(value):
		summary_text = value
		_sync_text()
@export_multiline var detail_text: String = "The desktop and mobile packages are staged. Check the release checksum before publishing.":
	set(value):
		detail_text = value
		_sync_text()
@export var status_text: String = "READY":
	set(value):
		status_text = value
		_sync_text()
@export var card_color: Color = Color(0.82, 0.91, 0.84):
	set(value):
		card_color = value
		_sync_style()


func _ready() -> void:
	_sync_text()
	_sync_style()


func _sync_text() -> void:
	var title_label := get_node_or_null("Visual/Margin/Content/TitleRow/StepTitle") as Label
	if title_label != null:
		title_label.text = "%02d  %s" % [step_number, step_title]
	var summary_label := get_node_or_null("Visual/Margin/Content/SummaryRow/Summary") as Label
	if summary_label != null:
		summary_label.text = summary_text
	var detail_label := get_node_or_null("Visual/Margin/Content/Detail") as Label
	if detail_label != null:
		detail_label.text = detail_text
	var status_label := get_node_or_null("Visual/Margin/Content/TitleRow/Status") as Label
	if status_label != null:
		status_label.text = status_text


func _sync_style() -> void:
	var visual := get_node_or_null("Visual") as PanelContainer
	if visual == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = card_color
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.shadow_color = Color(0.08, 0.16, 0.13, 0.12)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	visual.add_theme_stylebox_override("panel", style)