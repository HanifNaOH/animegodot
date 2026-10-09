class_name AnimeTrackOptions
extends RefCounted

enum Toggle {
	INHERIT = -1,
	DISABLED,
	ENABLED,
}

var duration: float = -1.0
var delay: float = -1.0
var ease: int = AnimeEase.INHERIT
var repeat_count: int = -1
var repeat_delay: float = -1.0
var yoyo: int = Toggle.INHERIT
var direction: int = AnimeOptions.Direction.INHERIT
var interpolator: Callable = Callable()


func is_valid() -> bool:
	return (
		is_finite(duration)
		and duration >= -1.0
		and is_finite(delay)
		and delay >= -1.0
		and AnimeEase.is_valid(ease, true)
		and repeat_count >= -1
		and is_finite(repeat_delay)
		and repeat_delay >= -1.0
		and yoyo >= Toggle.INHERIT
		and yoyo <= Toggle.ENABLED
		and direction >= AnimeOptions.Direction.INHERIT
		and direction <= AnimeOptions.Direction.ALTERNATE
	)


func copy() -> AnimeTrackOptions:
	var copied := AnimeTrackOptions.new()
	copied.duration = duration
	copied.delay = delay
	copied.ease = ease
	copied.repeat_count = repeat_count
	copied.repeat_delay = repeat_delay
	copied.yoyo = yoyo
	copied.direction = direction
	copied.interpolator = interpolator
	return copied