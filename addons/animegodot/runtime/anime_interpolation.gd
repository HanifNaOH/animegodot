class_name AnimeInterpolation
extends RefCounted


static func value(from_value: Variant, to_value: Variant, weight: float, interpolator: Variant = null) -> Variant:
	var clamped_weight := clampf(weight, 0.0, 1.0)
	return _value_with_weight(from_value, to_value, clamped_weight, interpolator)


static func extrapolate(from_value: Variant, to_value: Variant, weight: float) -> Variant:
	return _value_with_weight(from_value, to_value, weight)


static func bezier(from_value: Variant, control_one: Variant, control_two: Variant, to_value: Variant, weight: float) -> Variant:
	var inverse := 1.0 - weight
	var first := _value_with_weight(from_value, control_one, weight)
	var second := _value_with_weight(control_one, control_two, weight)
	var third := _value_with_weight(control_two, to_value, weight)
	var first_curve := _value_with_weight(first, second, weight)
	var second_curve := _value_with_weight(second, third, weight)
	return _value_with_weight(first_curve, second_curve, weight) if inverse >= 0.0 else to_value


static func spring(from_value: Variant, to_value: Variant, time: float, stiffness: float = 170.0, damping: float = 26.0, mass: float = 1.0) -> Variant:
	var safe_mass := maxf(mass, 0.001)
	var safe_stiffness := maxf(stiffness, 0.001)
	var safe_damping := maxf(damping, 0.0)
	var natural_frequency := sqrt(safe_stiffness / safe_mass)
	var damping_ratio := safe_damping / (2.0 * sqrt(safe_stiffness * safe_mass))
	var weight := 1.0
	if damping_ratio < 1.0:
		var damped_frequency := natural_frequency * sqrt(1.0 - damping_ratio * damping_ratio)
		var decay := exp(-damping_ratio * natural_frequency * maxf(time, 0.0))
		weight = 1.0 - decay * (
			cos(damped_frequency * maxf(time, 0.0))
			+ damping_ratio / maxf(sqrt(1.0 - damping_ratio * damping_ratio), 0.001)
			* sin(damped_frequency * maxf(time, 0.0))
		)
	else:
		weight = 1.0 - exp(-natural_frequency * maxf(time, 0.0))
	return extrapolate(from_value, to_value, weight)


static func _value_with_weight(from_value: Variant, to_value: Variant, weight: float, interpolator: Variant = null) -> Variant:
	if interpolator is Callable and interpolator.is_valid():
		return interpolator.call(from_value, to_value, weight)
	if typeof(from_value) != typeof(to_value):
		return to_value if weight >= 1.0 else from_value

	match typeof(from_value):
		TYPE_INT:
			return roundi(lerpf(float(from_value), float(to_value), weight))
		TYPE_FLOAT:
			return lerpf(float(from_value), float(to_value), weight)
		TYPE_VECTOR2:
			return from_value.lerp(to_value, weight)
		TYPE_VECTOR2I:
			return Vector2i(
				roundi(lerpf(from_value.x, to_value.x, weight)),
				roundi(lerpf(from_value.y, to_value.y, weight))
			)
		TYPE_VECTOR3:
			return from_value.lerp(to_value, weight)
		TYPE_VECTOR3I:
			return Vector3i(
				roundi(lerpf(from_value.x, to_value.x, weight)),
				roundi(lerpf(from_value.y, to_value.y, weight)),
				roundi(lerpf(from_value.z, to_value.z, weight))
			)
		TYPE_VECTOR4:
			return from_value.lerp(to_value, weight)
		TYPE_VECTOR4I:
			return Vector4i(
				roundi(lerpf(from_value.x, to_value.x, weight)),
				roundi(lerpf(from_value.y, to_value.y, weight)),
				roundi(lerpf(from_value.z, to_value.z, weight)),
				roundi(lerpf(from_value.w, to_value.w, weight))
			)
		TYPE_RECT2:
			return Rect2(
				from_value.position.lerp(to_value.position, weight),
				from_value.size.lerp(to_value.size, weight)
			)
		TYPE_RECT2I:
			return Rect2i(
				Vector2i(
					roundi(lerpf(from_value.position.x, to_value.position.x, weight)),
					roundi(lerpf(from_value.position.y, to_value.position.y, weight))
				),
				Vector2i(
					roundi(lerpf(from_value.size.x, to_value.size.x, weight)),
					roundi(lerpf(from_value.size.y, to_value.size.y, weight))
				)
			)
		TYPE_COLOR:
			return from_value.lerp(to_value, weight)
		TYPE_QUATERNION:
			return from_value.slerp(to_value, weight)
		TYPE_PLANE:
			return Plane(from_value.normal.lerp(to_value.normal, weight), lerpf(from_value.d, to_value.d, weight))
		TYPE_AABB:
			return AABB(
				from_value.position.lerp(to_value.position, weight),
				from_value.size.lerp(to_value.size, weight)
			)
		TYPE_BASIS:
			return from_value.slerp(to_value, weight)
		TYPE_TRANSFORM2D:
			return from_value.interpolate_with(to_value, weight)
		TYPE_TRANSFORM3D:
			return from_value.interpolate_with(to_value, weight)
		TYPE_ARRAY:
			return _array_with_weight(from_value, to_value, weight)
		TYPE_DICTIONARY:
			return _dictionary_with_weight(from_value, to_value, weight)
		_:
			return to_value if weight >= 1.0 else from_value


static func _array_with_weight(from_value: Array, to_value: Array, weight: float) -> Variant:
	if from_value.size() != to_value.size():
		return to_value if weight >= 1.0 else from_value
	var result: Array = []
	for index in from_value.size():
		result.append(_value_with_weight(from_value[index], to_value[index], weight))
	return result


static func _dictionary_with_weight(from_value: Dictionary, to_value: Dictionary, weight: float) -> Variant:
	if from_value.keys() != to_value.keys():
		return to_value if weight >= 1.0 else from_value
	var result: Dictionary = {}
	for key in from_value:
		result[key] = _value_with_weight(from_value[key], to_value[key], weight)
	return result
