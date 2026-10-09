extends Control

const BINDER_SCRIPT = preload("res://addons/gdvm/core/binding/gdvm_binder.gd")
const VIEW_MODEL_SCRIPT = preload("res://examples/main_menu/main_menu_view_model.gd")

const HAND_TIP_OFFSET := 86.0

var view_model
var binder
var _target_button: Button
var _has_hand_target := false

@onready var _continue_button: Button = %ContinueButton
@onready var _new_game_button: Button = %NewGameButton
@onready var _settings_button: Button = %SettingsButton
@onready var _quit_button: Button = %QuitButton
@onready var _selected_option_label: Label = %SelectedOption
@onready var _selection_detail: Label = %SelectionDetail
@onready var _hand_indicator: Control = %HandIndicator


func _ready() -> void:
	view_model = VIEW_MODEL_SCRIPT.new()
	binder = BINDER_SCRIPT.new(self)
	binder.set_view_model(view_model)
	binder.bind(_selected_option_label, &"selected_option", "text", {
		"converter": _selection_title_for,
	})
	binder.bind(_selection_detail, &"selected_option", "text", {
		"converter": _selection_detail_for,
	})
	_bind_menu_button(_continue_button, &"continue")
	_bind_menu_button(_new_game_button, &"new_game")
	_bind_menu_button(_settings_button, &"settings")
	_bind_menu_button(_quit_button, &"quit")
	_target_button = _continue_button
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_continue_button.call_deferred("grab_focus")


func get_hand_target_position(button: Button) -> Vector2:
	var canvas_to_local := get_global_transform_with_canvas().affine_inverse()
	var button_rect := button.get_global_rect()
	var button_origin := canvas_to_local * button_rect.position
	var button_center := canvas_to_local * button_rect.get_center()
	return Vector2(
		button_origin.x - HAND_TIP_OFFSET,
		button_center.y - _hand_indicator.size.y * 0.5
	)


func _bind_menu_button(button: Button, option_id: StringName) -> void:
	button.mouse_entered.connect(_on_button_targeted.bind(button))
	button.focus_entered.connect(_on_button_targeted.bind(button))
	button.pressed.connect(_on_button_pressed.bind(button, option_id))
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _on_button_targeted(button: Button) -> void:
	_move_hand_to(button, true)


func _move_hand_to(button: Button, skip_unchanged_target: bool) -> void:
	if skip_unchanged_target and _has_hand_target and _target_button == button:
		return
	var target_position := get_hand_target_position(button)
	_target_button = button
	if not _has_hand_target:
		_hand_indicator.position = target_position
		_has_hand_target = true
		return
	var tween := Anime.tween(_hand_indicator)
	tween.options.duration = 0.28
	tween.options.ease = AnimeEase.OUT_BACK
	tween.track(AnimeControl.position_to(target_position))
	tween.play()


func _on_button_pressed(button: Button, option_id: StringName) -> void:
	view_model.select_option_command.execute([option_id])
	var tween := Anime.tween(button)
	tween.options.duration = 0.26
	tween.options.ease = AnimeEase.OUT_QUAD
	var modulation_track := AnimeCanvasItem.modulate_to(Color.WHITE)
	modulation_track.set_keyframes([Color(1.0, 0.84, 0.62, 1.0)])
	tween.track(modulation_track)
	tween.play()


func _selection_title_for(option_id: StringName) -> String:
	if option_id == &"":
		return "MAKE YOUR MOVE"
	return "SELECTED / %s" % String(option_id).replace("_", " ").to_upper()


func _selection_detail_for(option_id: StringName) -> String:
	match option_id:
		&"continue":
			return "Pick up where your last story left off."
		&"new_game":
			return "Start a fresh adventure from the beginning."
		&"settings":
			return "Adjust the way your world feels and sounds."
		&"quit":
			return "Your selection is bound. No game action is wired here."
		_:
			return "Hover or focus a menu item, then select it."


func _on_viewport_size_changed() -> void:
	call_deferred("_refresh_hand_target")


func _refresh_hand_target() -> void:
	_move_hand_to(_target_button, false)


func _exit_tree() -> void:
	var viewport := get_viewport()
	viewport.size_changed.disconnect(_on_viewport_size_changed)
	binder.dispose()
	view_model.dispose()