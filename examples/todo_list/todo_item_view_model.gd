extends "res://addons/gdvm/core/component_model/observable_object.gd"

const RELAY_COMMAND = preload("res://addons/gdvm/core/input/relay_command.gd")

var id: int
var _title: String
var _completed := false
var toggle_command

var title: String:
	get:
		return _title
	set(value):
		if set_property(&"title", _title, value):
			_title = value

var completed: bool:
	get:
		return _completed
	set(value):
		if set_property(&"completed", _completed, value):
			_completed = value

var status_text: String:
	get:
		return "Completed" if completed else "Open"


func _init(item_id: int, item_title: String) -> void:
	id = item_id
	_title = item_title
	toggle_command = RELAY_COMMAND.new(_toggle)


func _toggle() -> void:
	completed = not completed
	notify_property_changed(&"status_text")
