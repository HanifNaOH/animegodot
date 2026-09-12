extends Control

const BINDER_SCRIPT = preload("res://addons/gdvm/core/binding/gdvm_binder.gd")
const VIEW_MODEL_SCRIPT = preload("res://examples/todo_list/todo_list_view_model.gd")
const ROW_SCENE = preload("res://examples/todo_list/todo_row.tscn")

var view_model
var binder

@onready var _draft: LineEdit = %Draft
@onready var _add_button: Button = %Add
@onready var _filter: OptionButton = %Filter
@onready var _clear_button: Button = %ClearCompleted
@onready var _todo_list: VBoxContainer = %TodoList
@onready var _empty_message: Label = %EmptyMessage


func _ready() -> void:
	layout_direction = Control.LAYOUT_DIRECTION_LTR
	_draft.layout_direction = Control.LAYOUT_DIRECTION_LTR
	_draft.text_direction = Control.TEXT_DIRECTION_LTR
	_draft.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	view_model = VIEW_MODEL_SCRIPT.new()
	binder = BINDER_SCRIPT.new(self)
	binder.set_view_model(view_model)
	binder.bind(%Summary, &"summary_text", "text")
	binder.bind(%Remaining, &"remaining_count", "text", {"converter": &"str"})
	binder.bind(%EmptyMessage, &"empty_message", "text")
	binder.bind_list(_todo_list, &"visible_items", ROW_SCENE, {
		"item_key": &"id",
		"item_view_model_factory": func(item): return item,
		"on_added": _on_row_added,
		"on_removed": _on_row_removed,
	})
	_add_button.pressed.connect(_on_add_pressed)
	_clear_button.pressed.connect(view_model.clear_completed_command.execute)
	_draft.text_changed.connect(_on_draft_changed)
	_draft.text_submitted.connect(_on_text_submitted)
	_filter.item_selected.connect(_on_filter_selected)
	view_model.changed.connect(_on_view_model_changed)
	view_model.add_command.can_execute_changed.connect(_refresh_commands)
	view_model.clear_completed_command.can_execute_changed.connect(_refresh_commands)
	_refresh_commands()
	_refresh_empty_state()


func _on_text_submitted(_text: String) -> void:
	_on_add_pressed()


func _on_draft_changed(text: String) -> void:
	view_model.draft_text = text


func _on_add_pressed() -> void:
	view_model.add_command.execute()
	_draft.text = view_model.draft_text


func _on_filter_selected(index: int) -> void:
	var filters := [&"all", &"open", &"completed"]
	if index < filters.size():
		view_model.filter = filters[index]
	_refresh_empty_state()


func _on_row_added(row: Node) -> void:
	if row.has_signal(&"remove_requested"):
		row.remove_requested.connect(_on_row_remove_requested)
	if row is Control:
		var control := row as Control
		var target_height := maxf(control.custom_minimum_size.y, control.size.y)
		Anime.set_value(control, {
			"custom_minimum_size:y": 0.0,
			"modulate:a": 0.0,
		})
		Anime.to(control, {
			"custom_minimum_size:y": target_height,
			"modulate:a": 1.0,
			"duration": 0.24,
			"ease": Anime.EASE_OUT_BACK,
		})


func _on_row_removed(row: Node) -> void:
	row.queue_free()


func _on_row_remove_requested(item_id: int) -> void:
	for row in _todo_list.get_children():
		if not row.has_method(&"get_item_id") or row.get_item_id() != item_id:
			continue
		if row is not Control:
			view_model.remove_item(item_id)
			return
		var control := row as Control
		control.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var exit_x := control.position.x - maxf(control.size.x, 320.0)
		Anime.to(control, {
			"custom_minimum_size:y": 0.0,
			"position:x": exit_x,
			"modulate:a": 0.0,
			"duration": 0.18,
			"ease": Anime.EASE_IN_SINE,
			"on_complete": func(): view_model.remove_item(item_id),
		})
		return


func _on_view_model_changed(_property_name: StringName, _old_value, _new_value) -> void:
	_refresh_commands()
	_refresh_empty_state()


func _refresh_commands() -> void:
	if view_model == null:
		return
	_add_button.disabled = not view_model.add_command.can_execute()
	_clear_button.disabled = not view_model.clear_completed_command.can_execute()


func _refresh_empty_state() -> void:
	if view_model == null:
		return
	_empty_message.visible = view_model.visible_items.is_empty()


func _exit_tree() -> void:
	if binder != null:
		binder.dispose()
	if view_model != null:
		view_model.dispose()
