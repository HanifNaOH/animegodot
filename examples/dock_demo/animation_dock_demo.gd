@tool
extends Control

const DEFAULT_ANIMATION := &"slide_and_fade"
const ANIMATION_NAMES := [&"slide_and_fade", &"bounce", &"pulse", &"fade_in"]

@onready var _animation_player: AnimationPlayer = %AnimationPlayer


func _ready() -> void:
	_ensure_animation()
	if not Engine.is_editor_hint():
		_animation_player.play(DEFAULT_ANIMATION)


func _ensure_animation() -> void:
	if _animation_player == null:
		return
	if not _animation_player.has_animation_library(&""):
		_animation_player.add_animation_library(&"", AnimationLibrary.new())
	var library := _animation_player.get_animation_library(&"")
	for animation_name in ANIMATION_NAMES:
		if library.has_animation(animation_name):
			continue
		var animation := _create_animation(animation_name)
		library.add_animation(animation_name, animation)


func _create_animation(animation_name: StringName) -> Animation:
	var animation := Animation.new()
	animation.resource_name = String(animation_name)
	match animation_name:
		&"bounce":
			animation.length = 1.0
			_add_keyed_track(animation, &"position", [0.0, 0.18, 0.38, 0.58, 0.78, 1.0], [Vector2(320.0, 260.0), Vector2(320.0, 120.0), Vector2(320.0, 230.0), Vector2(320.0, 145.0), Vector2(320.0, 205.0), Vector2(320.0, 170.0)])
			_add_keyed_track(animation, &"scale", [0.0, 0.18, 0.38, 0.58, 0.78, 1.0], [Vector2(0.9, 0.9), Vector2(1.05, 1.05), Vector2(0.96, 0.96), Vector2(1.02, 1.02), Vector2(0.98, 0.98), Vector2.ONE])
		&"pulse":
			animation.length = 1.2
			_add_keyed_track(animation, &"position", [0.0, animation.length], [Vector2(320.0, 210.0), Vector2(320.0, 210.0)])
			_add_keyed_track(animation, &"scale", [0.0, 0.3, 0.6, 0.9, 1.2], [Vector2.ONE, Vector2(1.16, 1.16), Vector2.ONE, Vector2(1.16, 1.16), Vector2.ONE])
			_add_keyed_track(animation, &"modulate", [0.0, 0.3, 0.6, 0.9, 1.2], [Color(0.4, 0.85, 0.73), Color(0.98, 0.58, 0.28), Color(0.4, 0.85, 0.73), Color(0.98, 0.58, 0.28), Color(0.4, 0.85, 0.73)])
		&"fade_in":
			animation.length = 0.8
			_add_keyed_track(animation, &"position", [0.0, animation.length], [Vector2(320.0, 210.0), Vector2(320.0, 210.0)])
			_add_keyed_track(animation, &"scale", [0.0, animation.length], [Vector2(0.7, 0.7), Vector2.ONE])
			_add_keyed_track(animation, &"modulate:a", [0.0, animation.length], [0.0, 1.0])
		_:
			animation.length = 1.2
			_add_value_track(animation, &"position", Vector2(140.0, 170.0), Vector2(520.0, 260.0))
			_add_value_track(animation, &"modulate:a", 0.35, 1.0)
	return animation


func _add_value_track(animation: Animation, property_path: StringName, start_value: Variant, end_value: Variant) -> void:
	_add_keyed_track(animation, property_path, [0.0, animation.length], [start_value, end_value])


func _add_keyed_track(animation: Animation, property_path: StringName, key_times: Array, values: Array) -> void:
	var track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track, NodePath("Target:" + String(property_path)))
	for index in key_times.size():
		animation.track_insert_key(track, float(key_times[index]), values[index])
