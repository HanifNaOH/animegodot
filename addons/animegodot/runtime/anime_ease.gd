class_name AnimeEase
extends RefCounted

enum {
	INHERIT = -1,
	LINEAR,
	IN_SINE,
	OUT_SINE,
	IN_OUT_SINE,
	IN_QUAD,
	OUT_QUAD,
	IN_OUT_QUAD,
	IN_CUBIC,
	OUT_CUBIC,
	IN_OUT_CUBIC,
	IN_QUART,
	OUT_QUART,
	IN_OUT_QUART,
	IN_QUINT,
	OUT_QUINT,
	IN_OUT_QUINT,
	IN_EXPO,
	OUT_EXPO,
	IN_OUT_EXPO,
	IN_CIRC,
	OUT_CIRC,
	IN_OUT_CIRC,
	IN_BACK,
	OUT_BACK,
	IN_OUT_BACK,
	IN_BOUNCE,
	OUT_BOUNCE,
	IN_OUT_BOUNCE,
	IN_ELASTIC,
	OUT_ELASTIC,
	IN_OUT_ELASTIC,
	IN_SPRING,
	OUT_SPRING,
	IN_OUT_SPRING,
}


static func is_valid(value: int, allow_inherit: bool = false) -> bool:
	if allow_inherit and value == INHERIT:
		return true
	return value >= LINEAR and value <= IN_OUT_SPRING


static func weight(value: int, progress: float) -> float:
	if not is_valid(value):
		return progress
	if value == LINEAR:
		return progress
	var family := int((value - 1) / 3)
	var phase := (value - 1) % 3
	var transition: int
	match family:
		0: transition = Tween.TRANS_SINE
		1: transition = Tween.TRANS_QUAD
		2: transition = Tween.TRANS_CUBIC
		3: transition = Tween.TRANS_QUART
		4: transition = Tween.TRANS_QUINT
		5: transition = Tween.TRANS_EXPO
		6: transition = Tween.TRANS_CIRC
		7: transition = Tween.TRANS_BACK
		8: transition = Tween.TRANS_BOUNCE
		9: transition = Tween.TRANS_ELASTIC
		_: transition = Tween.TRANS_SPRING
	var ease_mode := Tween.EASE_IN
	match phase:
		1: ease_mode = Tween.EASE_OUT
		2: ease_mode = Tween.EASE_IN_OUT
	return float(Tween.interpolate_value(0.0, 1.0, progress, 1.0, transition, ease_mode))