class_name AnimeLayoutOptions
extends RefCounted

var duration: float = 0.35
var delay: float = 0.0
var ease: int = AnimeEase.OUT_QUAD
var size_ease: int = AnimeEase.INHERIT
var speed_scale: float = 1.0
var ignore_time_scale: bool = false
var process_mode: int = Tween.TWEEN_PROCESS_IDLE
var overwrite: int = AnimeOverwrite.AUTO
var stagger: AnimeStaggerOptions = AnimeStaggerOptions.new()
var children_group: StringName = &""
var visual_path: NodePath = ^"Visual"


func is_valid() -> bool:
	return (
		is_finite(duration)
		and duration >= 0.0
		and is_finite(delay)
		and delay >= 0.0
		and AnimeEase.is_valid(ease)
		and AnimeEase.is_valid(size_ease, true)
		and is_finite(speed_scale)
		and speed_scale >= 0.0
		and (process_mode == Tween.TWEEN_PROCESS_IDLE or process_mode == Tween.TWEEN_PROCESS_PHYSICS)
		and AnimeOverwrite.is_valid(overwrite)
		and stagger != null
		and stagger.is_valid()
		and not visual_path.is_empty()
	)


func copy() -> AnimeLayoutOptions:
	var copied := AnimeLayoutOptions.new()
	copied.duration = duration
	copied.delay = delay
	copied.ease = ease
	copied.size_ease = size_ease
	copied.speed_scale = speed_scale
	copied.ignore_time_scale = ignore_time_scale
	copied.process_mode = process_mode
	copied.overwrite = overwrite
	copied.stagger = stagger.copy() if stagger != null else null
	copied.children_group = children_group
	copied.visual_path = visual_path
	return copied