class_name AnimeControl
extends RefCounted

const ACCESSOR_SCRIPT = preload("res://addons/animegodot/runtime/anime_property_accessor.gd")
const KEY_SCRIPT = preload("res://addons/animegodot/runtime/anime_property_key.gd")
const TRACK_SCRIPT = preload("res://addons/animegodot/runtime/anime_track.gd")


static func position_to(value: Vector2) -> AnimeTrack:
	var accessor := ACCESSOR_SCRIPT.new(
		KEY_SCRIPT.builtin(KEY_SCRIPT.Builtin.POSITION),
		func(target: Object) -> bool: return target is Control,
		func(candidate: Variant) -> bool: return candidate is Vector2,
		func(target: Object) -> Variant: return (target as Control).position,
		func(target: Object, candidate: Variant) -> void:
			var control := target as Control
			control.position = candidate,
		func(_target: Object) -> NodePath: return NodePath("position")
	)
	return TRACK_SCRIPT.new(accessor, value)


static func global_position_to(value: Vector2) -> AnimeTrack:
	var accessor := ACCESSOR_SCRIPT.new(
		KEY_SCRIPT.builtin(KEY_SCRIPT.Builtin.GLOBAL_POSITION),
		func(target: Object) -> bool: return target is Control,
		func(candidate: Variant) -> bool: return candidate is Vector2,
		func(target: Object) -> Variant: return (target as Control).global_position,
		func(target: Object, candidate: Variant) -> void:
			var control := target as Control
			control.global_position = candidate,
		func(_target: Object) -> NodePath: return NodePath("global_position")
	)
	return TRACK_SCRIPT.new(accessor, value)


static func size_to(value: Vector2) -> AnimeTrack:
	var accessor := ACCESSOR_SCRIPT.new(
		KEY_SCRIPT.builtin(KEY_SCRIPT.Builtin.SIZE),
		func(target: Object) -> bool: return target is Control,
		func(candidate: Variant) -> bool: return candidate is Vector2,
		func(target: Object) -> Variant: return (target as Control).size,
		func(target: Object, candidate: Variant) -> void:
			var control := target as Control
			control.size = candidate,
		func(_target: Object) -> NodePath: return NodePath("size")
	)
	return TRACK_SCRIPT.new(accessor, value)


static func custom_minimum_size_to(value: Vector2) -> AnimeTrack:
	var accessor := ACCESSOR_SCRIPT.new(
		KEY_SCRIPT.builtin(KEY_SCRIPT.Builtin.CUSTOM_MINIMUM_SIZE),
		func(target: Object) -> bool: return target is Control,
		func(candidate: Variant) -> bool: return candidate is Vector2,
		func(target: Object) -> Variant: return (target as Control).custom_minimum_size,
		func(target: Object, candidate: Variant) -> void:
			var control := target as Control
			control.custom_minimum_size = candidate,
		func(_target: Object) -> NodePath: return NodePath("custom_minimum_size")
	)
	return TRACK_SCRIPT.new(accessor, value)


static func scale_to(value: Vector2) -> AnimeTrack:
	var accessor := ACCESSOR_SCRIPT.new(
		KEY_SCRIPT.builtin(KEY_SCRIPT.Builtin.SCALE),
		func(target: Object) -> bool: return target is Control,
		func(candidate: Variant) -> bool: return candidate is Vector2,
		func(target: Object) -> Variant: return (target as Control).scale,
		func(target: Object, candidate: Variant) -> void:
			var control := target as Control
			control.scale = candidate,
		func(_target: Object) -> NodePath: return NodePath("scale")
	)
	return TRACK_SCRIPT.new(accessor, value)