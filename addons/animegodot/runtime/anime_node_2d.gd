class_name AnimeNode2D
extends RefCounted

const ACCESSOR_SCRIPT = preload("res://addons/animegodot/runtime/anime_property_accessor.gd")
const KEY_SCRIPT = preload("res://addons/animegodot/runtime/anime_property_key.gd")
const TRACK_SCRIPT = preload("res://addons/animegodot/runtime/anime_track.gd")


static func position_to(value: Vector2) -> AnimeTrack:
	var accessor := ACCESSOR_SCRIPT.new(
		KEY_SCRIPT.builtin(KEY_SCRIPT.Builtin.POSITION),
		func(target: Object) -> bool: return target is Node2D,
		func(candidate: Variant) -> bool: return candidate is Vector2,
		func(target: Object) -> Variant: return (target as Node2D).position,
		func(target: Object, candidate: Variant) -> void:
			var node := target as Node2D
			node.position = candidate,
		func(_target: Object) -> NodePath: return NodePath("position")
	)
	return TRACK_SCRIPT.new(accessor, value)


static func global_position_to(value: Vector2) -> AnimeTrack:
	var accessor := ACCESSOR_SCRIPT.new(
		KEY_SCRIPT.builtin(KEY_SCRIPT.Builtin.GLOBAL_POSITION),
		func(target: Object) -> bool: return target is Node2D,
		func(candidate: Variant) -> bool: return candidate is Vector2,
		func(target: Object) -> Variant: return (target as Node2D).global_position,
		func(target: Object, candidate: Variant) -> void:
			var node := target as Node2D
			node.global_position = candidate,
		func(_target: Object) -> NodePath: return NodePath("global_position")
	)
	return TRACK_SCRIPT.new(accessor, value)


static func rotation_to(value: float) -> AnimeTrack:
	var accessor := ACCESSOR_SCRIPT.new(
		KEY_SCRIPT.builtin(KEY_SCRIPT.Builtin.ROTATION),
		func(target: Object) -> bool: return target is Node2D,
		func(candidate: Variant) -> bool: return candidate is float or candidate is int,
		func(target: Object) -> Variant: return (target as Node2D).rotation,
		func(target: Object, candidate: Variant) -> void:
			var node := target as Node2D
			node.rotation = float(candidate),
		func(_target: Object) -> NodePath: return NodePath("rotation")
	)
	return TRACK_SCRIPT.new(accessor, value)


static func rotation_degrees_to(value: float) -> AnimeTrack:
	var accessor := ACCESSOR_SCRIPT.new(
		KEY_SCRIPT.builtin(KEY_SCRIPT.Builtin.ROTATION),
		func(target: Object) -> bool: return target is Node2D,
		func(candidate: Variant) -> bool: return candidate is float or candidate is int,
		func(target: Object) -> Variant: return (target as Node2D).rotation_degrees,
		func(target: Object, candidate: Variant) -> void:
			var node := target as Node2D
			node.rotation_degrees = float(candidate),
		func(_target: Object) -> NodePath: return NodePath("rotation_degrees")
	)
	return TRACK_SCRIPT.new(accessor, value)


static func scale_to(value: Vector2) -> AnimeTrack:
	var accessor := ACCESSOR_SCRIPT.new(
		KEY_SCRIPT.builtin(KEY_SCRIPT.Builtin.SCALE),
		func(target: Object) -> bool: return target is Node2D,
		func(candidate: Variant) -> bool: return candidate is Vector2,
		func(target: Object) -> Variant: return (target as Node2D).scale,
		func(target: Object, candidate: Variant) -> void:
			var node := target as Node2D
			node.scale = candidate,
		func(_target: Object) -> NodePath: return NodePath("scale")
	)
	return TRACK_SCRIPT.new(accessor, value)