@tool
extends EditorPlugin

const PLUGIN_NAME := "AnimeGodot"
const DOCK_SCRIPT = preload("res://addons/animegodot/editor/anime_dock.gd")

var _dock: Control


func _enter_tree() -> void:
	_dock = DOCK_SCRIPT.new()
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _dock)
	_dock.initialize(get_editor_interface())


func _exit_tree() -> void:
	if _dock == null:
		return
	remove_control_from_docks(_dock)
	_dock.queue_free()
	_dock = null