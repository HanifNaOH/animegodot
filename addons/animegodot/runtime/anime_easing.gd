class_name AnimeEasing
extends RefCounted


static func resolve(value: Variant) -> Dictionary:
	var easing_name := StringName("out_quad")
	if value != null:
		easing_name = StringName(str(value))

	match easing_name:
		&"linear":
			return {"transition": Tween.TRANS_LINEAR, "ease": Tween.EASE_IN_OUT}
		&"in_sine":
			return {"transition": Tween.TRANS_SINE, "ease": Tween.EASE_IN}
		&"out_sine":
			return {"transition": Tween.TRANS_SINE, "ease": Tween.EASE_OUT}
		&"in_out_sine":
			return {"transition": Tween.TRANS_SINE, "ease": Tween.EASE_IN_OUT}
		&"in_quad":
			return {"transition": Tween.TRANS_QUAD, "ease": Tween.EASE_IN}
		&"out_quad":
			return {"transition": Tween.TRANS_QUAD, "ease": Tween.EASE_OUT}
		&"in_out_quad":
			return {"transition": Tween.TRANS_QUAD, "ease": Tween.EASE_IN_OUT}
		&"in_cubic":
			return {"transition": Tween.TRANS_CUBIC, "ease": Tween.EASE_IN}
		&"out_cubic":
			return {"transition": Tween.TRANS_CUBIC, "ease": Tween.EASE_OUT}
		&"in_out_cubic":
			return {"transition": Tween.TRANS_CUBIC, "ease": Tween.EASE_IN_OUT}
		&"in_quart":
			return {"transition": Tween.TRANS_QUART, "ease": Tween.EASE_IN}
		&"out_quart":
			return {"transition": Tween.TRANS_QUART, "ease": Tween.EASE_OUT}
		&"in_out_quart":
			return {"transition": Tween.TRANS_QUART, "ease": Tween.EASE_IN_OUT}
		&"in_quint":
			return {"transition": Tween.TRANS_QUINT, "ease": Tween.EASE_IN}
		&"out_quint":
			return {"transition": Tween.TRANS_QUINT, "ease": Tween.EASE_OUT}
		&"in_out_quint":
			return {"transition": Tween.TRANS_QUINT, "ease": Tween.EASE_IN_OUT}
		&"in_expo":
			return {"transition": Tween.TRANS_EXPO, "ease": Tween.EASE_IN}
		&"out_expo":
			return {"transition": Tween.TRANS_EXPO, "ease": Tween.EASE_OUT}
		&"in_out_expo":
			return {"transition": Tween.TRANS_EXPO, "ease": Tween.EASE_IN_OUT}
		&"in_circ":
			return {"transition": Tween.TRANS_CIRC, "ease": Tween.EASE_IN}
		&"out_circ":
			return {"transition": Tween.TRANS_CIRC, "ease": Tween.EASE_OUT}
		&"in_out_circ":
			return {"transition": Tween.TRANS_CIRC, "ease": Tween.EASE_IN_OUT}
		&"in_back":
			return {"transition": Tween.TRANS_BACK, "ease": Tween.EASE_IN}
		&"out_back":
			return {"transition": Tween.TRANS_BACK, "ease": Tween.EASE_OUT}
		&"in_out_back":
			return {"transition": Tween.TRANS_BACK, "ease": Tween.EASE_IN_OUT}
		&"in_bounce":
			return {"transition": Tween.TRANS_BOUNCE, "ease": Tween.EASE_IN}
		&"out_bounce":
			return {"transition": Tween.TRANS_BOUNCE, "ease": Tween.EASE_OUT}
		&"in_out_bounce":
			return {"transition": Tween.TRANS_BOUNCE, "ease": Tween.EASE_IN_OUT}
		&"in_elastic":
			return {"transition": Tween.TRANS_ELASTIC, "ease": Tween.EASE_IN}
		&"out_elastic":
			return {"transition": Tween.TRANS_ELASTIC, "ease": Tween.EASE_OUT}
		&"in_out_elastic":
			return {"transition": Tween.TRANS_ELASTIC, "ease": Tween.EASE_IN_OUT}
		&"in_spring":
			return {"transition": Tween.TRANS_SPRING, "ease": Tween.EASE_IN}
		&"out_spring":
			return {"transition": Tween.TRANS_SPRING, "ease": Tween.EASE_OUT}
		&"in_out_spring":
			return {"transition": Tween.TRANS_SPRING, "ease": Tween.EASE_IN_OUT}
		_:
			push_warning("Unknown AnimeGodot easing '%s'; using out_quad." % easing_name)
			return {"transition": Tween.TRANS_QUAD, "ease": Tween.EASE_OUT}