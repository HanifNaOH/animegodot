class_name AnimeKeyframe
extends RefCounted

var progress: float = 0.0
var value: Variant
var ease: int = AnimeEase.INHERIT
var interpolator: Callable = Callable()


func _init(
	key_progress: float,
	key_value: Variant,
	key_ease: int = AnimeEase.INHERIT,
	key_interpolator: Callable = Callable()
) -> void:
	progress = key_progress
	value = key_value
	ease = key_ease
	interpolator = key_interpolator


func is_valid() -> bool:
	return is_finite(progress) and progress > 0.0 and progress < 1.0 and AnimeEase.is_valid(ease, true)


func copy() -> AnimeKeyframe:
	return AnimeKeyframe.new(progress, value, ease, interpolator)