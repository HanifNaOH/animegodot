class_name Anime
extends RefCounted

const CONTEXT_SCRIPT = preload("res://addons/animegodot/runtime/anime_context.gd")
const TIMELINE_SCRIPT = preload("res://addons/animegodot/runtime/anime_timeline.gd")
const INTERPOLATION_SCRIPT = preload("res://addons/animegodot/runtime/anime_interpolation.gd")
const ANIMATION_SCRIPT = preload("res://addons/animegodot/runtime/anime_animation.gd")

const OVERWRITE_NONE := &"none"
const OVERWRITE_AUTO := &"auto"
const OVERWRITE_ALL := &"all"

const EASE_LINEAR := &"linear"
const EASE_IN_SINE := &"in_sine"
const EASE_OUT_SINE := &"out_sine"
const EASE_IN_OUT_SINE := &"in_out_sine"
const EASE_IN_QUAD := &"in_quad"
const EASE_OUT_QUAD := &"out_quad"
const EASE_IN_OUT_QUAD := &"in_out_quad"
const EASE_IN_CUBIC := &"in_cubic"
const EASE_OUT_CUBIC := &"out_cubic"
const EASE_IN_OUT_CUBIC := &"in_out_cubic"
const EASE_IN_QUART := &"in_quart"
const EASE_OUT_QUART := &"out_quart"
const EASE_IN_OUT_QUART := &"in_out_quart"
const EASE_IN_QUINT := &"in_quint"
const EASE_OUT_QUINT := &"out_quint"
const EASE_IN_OUT_QUINT := &"in_out_quint"
const EASE_IN_EXPO := &"in_expo"
const EASE_OUT_EXPO := &"out_expo"
const EASE_IN_OUT_EXPO := &"in_out_expo"
const EASE_IN_CIRC := &"in_circ"
const EASE_OUT_CIRC := &"out_circ"
const EASE_IN_OUT_CIRC := &"in_out_circ"
const EASE_IN_BACK := &"in_back"
const EASE_OUT_BACK := &"out_back"
const EASE_IN_OUT_BACK := &"in_out_back"
const EASE_IN_BOUNCE := &"in_bounce"
const EASE_OUT_BOUNCE := &"out_bounce"
const EASE_IN_OUT_BOUNCE := &"in_out_bounce"
const EASE_IN_ELASTIC := &"in_elastic"
const EASE_OUT_ELASTIC := &"out_elastic"
const EASE_IN_OUT_ELASTIC := &"in_out_elastic"
const EASE_IN_SPRING := &"in_spring"
const EASE_OUT_SPRING := &"out_spring"
const EASE_IN_OUT_SPRING := &"in_out_spring"


static func context(owner: Node = null):
	return CONTEXT_SCRIPT.new(owner)


static func to(target: Variant, properties: Dictionary) -> Variant:
	return _context_for(target).to(target, properties)


static func from(target: Variant, properties: Dictionary) -> Variant:
	return _context_for(target).from(target, properties)


static func set_value(target: Variant, properties: Dictionary) -> Variant:
	return _context_for(target).set_value(target, properties)


static func motion_path(target: Node, path: Variant, options: Dictionary = {}):
	return _context_for(target).motion_path(target, path, options)


static func interpolate(from_value: Variant, to_value: Variant, weight: float) -> Variant:
	return INTERPOLATION_SCRIPT.value(from_value, to_value, weight)


static func bezier(from_value: Variant, control_one: Variant, control_two: Variant, to_value: Variant, weight: float) -> Variant:
	return INTERPOLATION_SCRIPT.bezier(from_value, control_one, control_two, to_value, weight)


static func spring(from_value: Variant, to_value: Variant, time: float, stiffness: float = 170.0, damping: float = 26.0, mass: float = 1.0) -> Variant:
	return INTERPOLATION_SCRIPT.spring(from_value, to_value, time, stiffness, damping, mass)


static func animation_from_properties(player: AnimationPlayer, target: Node, properties: Dictionary, duration: float) -> Animation:
	return ANIMATION_SCRIPT.from_properties(player, target, properties, duration)


static func add_animation(player: AnimationPlayer, name: StringName, target: Node, properties: Dictionary, duration: float) -> Animation:
	return ANIMATION_SCRIPT.add_to_player(player, name, target, properties, duration)


static func timeline(owner: Node = null, options: Dictionary = {}):
	return TIMELINE_SCRIPT.new(owner, options)


static func _context_for(targets_value: Variant):
	var targets: Array = targets_value if targets_value is Array else [targets_value]
	for target in targets:
		if target is Node:
			return CONTEXT_SCRIPT.new(target)
	return CONTEXT_SCRIPT.new()