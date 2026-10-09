class_name AnimeCanvasItem
extends RefCounted

const ACCESSOR_SCRIPT = preload("res://addons/animegodot/runtime/anime_property_accessor.gd")
const KEY_SCRIPT = preload("res://addons/animegodot/runtime/anime_property_key.gd")
const TRACK_SCRIPT = preload("res://addons/animegodot/runtime/anime_track.gd")


static func alpha_to(value: float) -> AnimeTrack:
	var accessor := ACCESSOR_SCRIPT.new(
		KEY_SCRIPT.builtin(KEY_SCRIPT.Builtin.MODULATE),
		func(target: Object) -> bool: return target is CanvasItem,
		func(candidate: Variant) -> bool: return candidate is float or candidate is int,
		func(target: Object) -> Variant: return (target as CanvasItem).modulate.a,
		func(target: Object, candidate: Variant) -> void:
			var canvas_item := target as CanvasItem
			var modulation := canvas_item.modulate
			modulation.a = float(candidate)
			canvas_item.modulate = modulation,
		func(_target: Object) -> NodePath: return NodePath("modulate:a")
	)
	return TRACK_SCRIPT.new(accessor, value)


static func modulate_to(value: Color) -> AnimeTrack:
	var accessor := ACCESSOR_SCRIPT.new(
		KEY_SCRIPT.builtin(KEY_SCRIPT.Builtin.MODULATE),
		func(target: Object) -> bool: return target is CanvasItem,
		func(candidate: Variant) -> bool: return candidate is Color,
		func(target: Object) -> Variant: return (target as CanvasItem).modulate,
		func(target: Object, candidate: Variant) -> void:
			var canvas_item := target as CanvasItem
			canvas_item.modulate = candidate,
		func(_target: Object) -> NodePath: return NodePath("modulate")
	)
	return TRACK_SCRIPT.new(accessor, value)