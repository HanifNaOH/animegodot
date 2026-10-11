class_name AnimeNode3D
extends RefCounted

const ACCESSOR_SCRIPT = preload("res://addons/animegodot/runtime/anime_property_accessor.gd")
const KEY_SCRIPT = preload("res://addons/animegodot/runtime/anime_property_key.gd")
const TRACK_SCRIPT = preload("res://addons/animegodot/runtime/anime_track.gd")


static func position_to(value: Vector3) -> AnimeTrack:
	var accessor := ACCESSOR_SCRIPT.new(
		KEY_SCRIPT.builtin(KEY_SCRIPT.Builtin.POSITION),
		func(target: Object) -> bool: return target is Node3D,
		func(candidate: Variant) -> bool: return candidate is Vector3,
		func(target: Object) -> Variant: return (target as Node3D).position,
		func(target: Object, candidate: Variant) -> void:
			var node := target as Node3D
			node.position = candidate,
		func(_target: Object) -> NodePath: return NodePath("position")
	)
	return TRACK_SCRIPT.new(accessor, value)


static func global_position_to(value: Vector3) -> AnimeTrack:
	var accessor := ACCESSOR_SCRIPT.new(
		KEY_SCRIPT.builtin(KEY_SCRIPT.Builtin.GLOBAL_POSITION),
		func(target: Object) -> bool: return target is Node3D,
		func(candidate: Variant) -> bool: return candidate is Vector3,
		func(target: Object) -> Variant: return (target as Node3D).global_position,
		func(target: Object, candidate: Variant) -> void:
			var node := target as Node3D
			node.global_position = candidate,
		func(_target: Object) -> NodePath: return NodePath("global_position")
	)
	return TRACK_SCRIPT.new(accessor, value)


static func rotation_to(value: Vector3) -> AnimeTrack:
	var accessor := ACCESSOR_SCRIPT.new(
		KEY_SCRIPT.builtin(KEY_SCRIPT.Builtin.ROTATION),
		func(target: Object) -> bool: return target is Node3D,
		func(candidate: Variant) -> bool: return candidate is Vector3,
		func(target: Object) -> Variant: return (target as Node3D).rotation,
		func(target: Object, candidate: Variant) -> void:
			var node := target as Node3D
			node.rotation = candidate,
		func(_target: Object) -> NodePath: return NodePath("rotation")
	)
	return TRACK_SCRIPT.new(accessor, value)


static func scale_to(value: Vector3) -> AnimeTrack:
	var accessor := ACCESSOR_SCRIPT.new(
		KEY_SCRIPT.builtin(KEY_SCRIPT.Builtin.SCALE),
		func(target: Object) -> bool: return target is Node3D,
		func(candidate: Variant) -> bool: return candidate is Vector3,
		func(target: Object) -> Variant: return (target as Node3D).scale,
		func(target: Object, candidate: Variant) -> void:
			var node := target as Node3D
			node.scale = candidate,
		func(_target: Object) -> NodePath: return NodePath("scale")
	)
	return TRACK_SCRIPT.new(accessor, value)