class_name AnimeInterpolation
extends RefCounted


static func value(from_value: Variant, to_value: Variant, weight: float) -> Variant:
	var clamped_weight := clampf(weight, 0.0, 1.0)
	return _value_with_weight(from_value, to_value, clamped_weight)


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


static func _value_with_weight(from_value: Variant, to_value: Variant, weight: float) -> Variant:
	if from_value is float or from_value is int:
		return lerpf(float(from_value), float(to_value), weight)
	if from_value is Vector2:
		return from_value.lerp(to_value, weight)
	if from_value is Vector3:
		return from_value.lerp(to_value, weight)
	if from_value is Vector4:
		return from_value.lerp(to_value, weight)
	if from_value is Color:
		return from_value.lerp(to_value, weight)
	if from_value is Quaternion:
		return from_value.slerp(to_value, weight)
	return to_value if weight >= 1.0 else from_value
