class_name AnimeOptions
extends RefCounted

enum Direction {
	INHERIT = -1,
	NORMAL,
	REVERSE,
	ALTERNATE,
}

var duration: float = 0.0
var delay: float = 0.0
var ease: int = AnimeEase.OUT_QUAD
var repeat_count: int = 0
var repeat_delay: float = 0.0
var yoyo: bool = false
var direction: int = Direction.NORMAL
var overwrite: int = AnimeOverwrite.AUTO
var speed_scale: float = 1.0
var ignore_time_scale: bool = false
var process_mode: int = Tween.TWEEN_PROCESS_IDLE
var autoplay: bool = false
var on_start: Callable = Callable()
var on_update: Callable = Callable()
var on_repeat: Callable = Callable()
var on_track_repeat: Callable = Callable()
var on_complete: Callable = Callable()
var on_reverse_complete: Callable = Callable()
var on_kill: Callable = Callable()


func is_valid() -> bool:
	return (
		is_finite(duration)
		and duration >= 0.0
		and is_finite(delay)
		and delay >= 0.0
		and AnimeEase.is_valid(ease)
		and repeat_count >= 0
		and is_finite(repeat_delay)
		and repeat_delay >= 0.0
		and direction >= Direction.NORMAL
		and direction <= Direction.ALTERNATE
		and AnimeOverwrite.is_valid(overwrite)
		and is_finite(speed_scale)
		and speed_scale >= 0.0
		and (process_mode == Tween.TWEEN_PROCESS_IDLE or process_mode == Tween.TWEEN_PROCESS_PHYSICS)
	)


func copy() -> AnimeOptions:
	var copied := AnimeOptions.new()
	copied.duration = duration
	copied.delay = delay
	copied.ease = ease
	copied.repeat_count = repeat_count
	copied.repeat_delay = repeat_delay
	copied.yoyo = yoyo
	copied.direction = direction
	copied.overwrite = overwrite
	copied.speed_scale = speed_scale
	copied.ignore_time_scale = ignore_time_scale
	copied.process_mode = process_mode
	copied.autoplay = autoplay
	copied.on_start = on_start
	copied.on_update = on_update
	copied.on_repeat = on_repeat
	copied.on_track_repeat = on_track_repeat
	copied.on_complete = on_complete
	copied.on_reverse_complete = on_reverse_complete
	copied.on_kill = on_kill
	return copied