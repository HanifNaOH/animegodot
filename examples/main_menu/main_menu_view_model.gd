extends "res://addons/gdvm/core/component_model/observable_object.gd"

const RELAY_COMMAND_SCRIPT = preload("res://addons/gdvm/core/input/relay_command.gd")

const OPTION_IDS := [&"continue", &"new_game", &"settings", &"quit"]

var _selected_option: StringName = &""
var select_option_command

var selected_option: StringName:
	get:
		return _selected_option
	set(value):
		if value not in OPTION_IDS:
			return
		if set_property(&"selected_option", _selected_option, value):
			_selected_option = value


func _init() -> void:
	select_option_command = RELAY_COMMAND_SCRIPT.new(_select_from_args, _can_select)


func dispose() -> void:
	select_option_command = null


func _select_from_args(args: Array) -> void:
	if args.size() == 1:
		selected_option = StringName(args[0])


func _can_select(args: Array) -> bool:
	return args.size() == 1 and StringName(args[0]) in OPTION_IDS