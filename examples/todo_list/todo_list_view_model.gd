extends "res://addons/gdvm/core/component_model/observable_object.gd"

const TODO_ITEM_SCRIPT = preload("res://examples/todo_list/todo_item_view_model.gd")
const RELAY_COMMAND = preload("res://addons/gdvm/core/input/relay_command.gd")

var _next_id := 1
var _items: Array = []
var _draft_text := ""
var _filter := "all"
var _item_notification_pending := false
var add_command
var clear_completed_command

var items: Array:
	get:
		return _items

var visible_items: Array:
	get:
		match _filter:
			"open":
				return _items.filter(func(item): return not item.completed)
			"completed":
				return _items.filter(func(item): return item.completed)
			_:
				return _items

var draft_text: String:
	get:
		return _draft_text
	set(value):
		if set_property(&"draft_text", _draft_text, value):
			_draft_text = value
			if add_command != null:
				add_command.notify_can_execute_changed()

var filter: String:
	get:
		return _filter
	set(value):
		var normalized := value.to_lower()
		if normalized not in ["all", "open", "completed"]:
			normalized = "all"
		if set_property(&"filter", _filter, normalized):
			_filter = normalized
			_notify_items()

var remaining_count: int:
	get:
		return _items.filter(func(item): return not item.completed).size()

var completed_count: int:
	get:
		return _items.filter(func(item): return item.completed).size()

var total_count: int:
	get:
		return _items.size()

var summary_text: String:
	get:
		return "%d open  |  %d completed" % [remaining_count, completed_count]

var empty_message: String:
	get:
		if total_count == 0:
			return "Nothing here yet. Add a task above."
		return "No tasks match this filter."


func _init() -> void:
	add_command = RELAY_COMMAND.new(_add_draft, _can_add)
	clear_completed_command = RELAY_COMMAND.new(clear_completed, func(): return completed_count > 0)
	_add_item("Review the GDVM dashboard pattern")
	_add_item("Build a first bound view")
	var finished = _add_item("Ship the AnimeGodot phase plan")
	finished.completed = true


func _add_draft() -> void:
	_add_item(_draft_text.strip_edges())
	draft_text = ""
	_notify_items()
	add_command.notify_can_execute_changed()


func _can_add() -> bool:
	return not _draft_text.strip_edges().is_empty()


func _add_item(text: String):
	var item = TODO_ITEM_SCRIPT.new(_next_id, text)
	_next_id += 1
	_items.append(item)
	item.changed.connect(_on_item_changed)
	return item


func remove_item(item_id: int) -> void:
	for index in _items.size():
		if _items[index].id == item_id:
			_items.remove_at(index)
			_notify_items()
			clear_completed_command.notify_can_execute_changed()
			return


func clear_completed() -> void:
	_items = _items.filter(func(item): return not item.completed)
	_notify_items()
	clear_completed_command.notify_can_execute_changed()


func dispose() -> void:
	_item_notification_pending = false
	for item in _items:
		if item.changed.is_connected(_on_item_changed):
			item.changed.disconnect(_on_item_changed)
	_items.clear()
	add_command = null
	clear_completed_command = null


func _notify_items() -> void:
	changed.emit(&"", null, {
		"items": items,
		"visible_items": visible_items,
		"remaining_count": remaining_count,
		"completed_count": completed_count,
		"total_count": total_count,
		"summary_text": summary_text,
		"empty_message": empty_message,
	})


func _on_item_changed(_property_name: StringName, _old_value, _new_value) -> void:
	if _item_notification_pending:
		return
	_item_notification_pending = true
	var main_loop := Engine.get_main_loop()
	if main_loop is SceneTree:
		main_loop.process_frame.connect(_flush_item_notification, CONNECT_ONE_SHOT)
	else:
		_flush_item_notification()


func _flush_item_notification() -> void:
	_item_notification_pending = false
	if clear_completed_command == null:
		return
	_notify_items()
	clear_completed_command.notify_can_execute_changed()
