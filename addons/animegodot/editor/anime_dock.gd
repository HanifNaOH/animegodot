@tool
extends VBoxContainer

const REGISTRY_SCRIPT = preload("res://addons/animegodot/runtime/anime_registry.gd")

var editor_interface: Variant
var _animation_player: AnimationPlayer
var _selection_label: Label
var _animation_option: OptionButton
var _scrub_slider: HSlider
var _position_label: Label
var _runtime_label: Label
var _status_label: Label
var _updating_slider := false
var _built := false


func initialize(interface: Variant) -> void:
	editor_interface = interface
	_refresh_selection_connection()
	_refresh_view()


func _ready() -> void:
	_build_ui()
	if editor_interface != null:
		_refresh_selection_connection()
		_refresh_view()


func _process(_delta: float) -> void:
	if not _built:
		return
	_update_playback_state()
	_update_runtime_state()


func _build_ui() -> void:
	if _built:
		return
	_built = true
	name = "AnimeGodotDock"
	custom_minimum_size = Vector2(280.0, 0.0)
	add_theme_constant_override("separation", 6)

	var title := Label.new()
	title.text = "AnimeGodot"
	title.add_theme_font_size_override("font_size", 18)
	add_child(title)

	_selection_label = Label.new()
	_selection_label.text = "Selection: none"
	_selection_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_selection_label)

	var refresh_button := Button.new()
	refresh_button.text = "Refresh Selection"
	refresh_button.pressed.connect(_refresh_view)
	add_child(refresh_button)

	var animation_label := Label.new()
	animation_label.text = "Animation"
	add_child(animation_label)

	_animation_option = OptionButton.new()
	_animation_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_animation_option.item_selected.connect(_on_animation_selected)
	add_child(_animation_option)

	var transport := HBoxContainer.new()
	add_child(transport)
	_add_button(transport, "Preview", _on_preview)
	_add_button(transport, "Pause", _on_pause)
	_add_button(transport, "Reverse", _on_reverse)
	_add_button(transport, "Stop", _on_stop)

	_scrub_slider = HSlider.new()
	_scrub_slider.min_value = 0.0
	_scrub_slider.max_value = 0.0
	_scrub_slider.step = 0.01
	_scrub_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scrub_slider.value_changed.connect(_on_scrub_changed)
	add_child(_scrub_slider)

	_position_label = Label.new()
	_position_label.text = "0.00 / 0.00"
	add_child(_position_label)

	var save_button := Button.new()
	save_button.text = "Save Current Animation (.tres)"
	save_button.pressed.connect(_on_save_animation)
	add_child(save_button)

	_runtime_label = Label.new()
	_runtime_label.text = "Active runtime animations: 0"
	_runtime_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_runtime_label)

	_status_label = Label.new()
	_status_label.text = "Select an AnimationPlayer or a node containing one."
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_status_label)


func _add_button(parent: Container, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(callback)
	parent.add_child(button)


func _refresh_selection_connection() -> void:
	if editor_interface == null:
		return
	var selection = editor_interface.get_selection()
	if selection != null and not selection.selection_changed.is_connected(_refresh_view):
		selection.selection_changed.connect(_refresh_view)


func _refresh_view() -> void:
	if not _built:
		return
	_animation_player = _find_animation_player()
	_animation_option.clear()
	if _animation_player == null:
		_selection_label.text = "Selection: none"
		_status_label.text = "Select an AnimationPlayer or a node containing one."
		return

	_selection_label.text = "Selection: %s" % _animation_player.get_path()
	for animation_name in _animation_player.get_animation_list():
		_animation_option.add_item(String(animation_name))
	if _animation_option.item_count > 0:
		var current_name := String(_animation_player.current_animation)
		var current_index := 0
		for index in _animation_option.item_count:
			if _animation_option.get_item_text(index) == current_name:
				current_index = index
				break
		_animation_option.select(current_index)
	_status_label.text = "AnimationPlayer ready."
	_update_playback_state()


func _find_animation_player() -> AnimationPlayer:
	if editor_interface == null:
		return null
	var selection = editor_interface.get_selection()
	if selection == null:
		return null
	for selected_node in selection.get_selected_nodes():
		if selected_node is AnimationPlayer:
			return selected_node
		if selected_node is Node:
			var child_player = selected_node.find_child("AnimationPlayer", true, false)
			if child_player is AnimationPlayer:
				return child_player
	return null


func _selected_animation_name() -> StringName:
	if _animation_option == null or _animation_option.item_count == 0:
		return &""
	return StringName(_animation_option.get_item_text(_animation_option.selected))


func _on_animation_selected(_index: int) -> void:
	if _animation_player == null:
		return
	_animation_player.stop()
	_update_playback_state()


func _on_preview() -> void:
	if _animation_player == null:
		return
	var animation_name := _selected_animation_name()
	if animation_name.is_empty():
		return
	_animation_player.play(animation_name)
	_status_label.text = "Previewing %s" % animation_name


func _on_pause() -> void:
	if _animation_player == null:
		return
	_animation_player.pause()
	_status_label.text = "Preview paused."


func _on_reverse() -> void:
	if _animation_player == null:
		return
	var animation_name := _selected_animation_name()
	if animation_name.is_empty():
		return
	_animation_player.play(animation_name, -1.0, -1.0, true)
	_status_label.text = "Previewing %s in reverse." % animation_name


func _on_stop() -> void:
	if _animation_player == null:
		return
	_animation_player.stop()
	_status_label.text = "Preview stopped."
	_update_playback_state()


func _on_scrub_changed(value: float) -> void:
	if _updating_slider or _animation_player == null:
		return
	_animation_player.seek(value, true)
	_animation_player.pause()
	_status_label.text = "Preview scrubbed."


func _update_playback_state() -> void:
	if _animation_player == null or _scrub_slider == null:
		return
	var length := _animation_player.current_animation_length
	var position := _animation_player.current_animation_position
	_updating_slider = true
	_scrub_slider.max_value = maxf(length, 0.0)
	_scrub_slider.value = clampf(position, 0.0, _scrub_slider.max_value)
	_updating_slider = false
	_position_label.text = "%.2f / %.2f" % [position, length]


func _update_runtime_state() -> void:
	if _runtime_label == null:
		return
	var registry = REGISTRY_SCRIPT.get_instance()
	if registry == null:
		_runtime_label.text = "Active runtime animations: 0"
		return
	var records: Array = registry.get_active_records()
	_runtime_label.text = "Active runtime animations: %d" % records.size()


func _on_save_animation() -> void:
	if _animation_player == null:
		return
	var animation_name := _selected_animation_name()
	if animation_name.is_empty() or not _animation_player.has_animation_library(&""):
		return
	var animation = _animation_player.get_animation_library(&"").get_animation(animation_name)
	var safe_name := String(animation_name).replace("/", "_")
	var path := "res://animegodot_%s.tres" % safe_name
	var error := ResourceSaver.save(animation, path)
	if error == OK:
		_status_label.text = "Saved %s" % path
	else:
		_status_label.text = "Could not save animation: %s" % error
