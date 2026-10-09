class_name AnimeTrack
extends RefCounted

var accessor: AnimePropertyAccessor
var end_value: Variant
var start_value: Variant
var has_start_value := false
var keyframes: Array[Variant] = []
var keyframe_points: Array[AnimeKeyframe] = []
var options: AnimeTrackOptions = AnimeTrackOptions.new()
var target: Object


func _init(property_accessor: AnimePropertyAccessor, value: Variant) -> void:
	accessor = property_accessor
	end_value = value


func attach_to(track_target: Object) -> bool:
	if not is_instance_valid(track_target) or not _accepts_values(track_target):
		return false
	if is_instance_valid(target):
		return target == track_target
	target = track_target
	return true


func is_valid() -> bool:
	return (
		accessor != null
		and _accepts_values(target)
		and options != null
		and options.is_valid()
	)


func set_start_value(value: Variant) -> bool:
	if accessor == null or not accessor.accepts_value(value):
		return false
	start_value = value
	has_start_value = true
	return true


func set_keyframes(values: Array) -> bool:
	if accessor == null:
		return false
	for value in values:
		if not accessor.accepts_value(value):
			return false
	keyframes.assign(values)
	keyframe_points.clear()
	return true


func set_keyframe_points(points: Array[AnimeKeyframe]) -> bool:
	if accessor == null:
		return false
	var previous_progress := 0.0
	for point in points:
		if point == null or not point.is_valid() or point.progress <= previous_progress or not accessor.accepts_value(point.value):
			return false
		previous_progress = point.progress
	keyframe_points.clear()
	for point in points:
		keyframe_points.append(point.copy())
	keyframes.clear()
	return true


func copy_for(track_target: Object) -> AnimeTrack:
	if accessor == null or not accessor.accepts(track_target, end_value):
		return null
	var copied := AnimeTrack.new(accessor, end_value)
	copied.options = options.copy()
	if has_start_value and not copied.set_start_value(start_value):
		return null
	if not copied.set_keyframes(keyframes) or not copied.set_keyframe_points(keyframe_points) or not copied.attach_to(track_target):
		return null
	return copied


func get_start_value() -> Variant:
	if not is_valid():
		return null
	if has_start_value:
		return start_value
	return accessor.read(target)


func apply(value: Variant) -> bool:
	if not is_instance_valid(target) or accessor == null:
		return false
	return accessor.write(target, value)


func _accepts_values(candidate: Object) -> bool:
	if accessor == null or not accessor.accepts(candidate, end_value):
		return false
	if has_start_value and not accessor.accepts_value(start_value):
		return false
	for keyframe in keyframes:
		if not accessor.accepts_value(keyframe):
			return false
	var previous_progress := 0.0
	for keyframe_point in keyframe_points:
		if (
			keyframe_point == null
			or not keyframe_point.is_valid()
			or keyframe_point.progress <= previous_progress
			or not accessor.accepts_value(keyframe_point.value)
		):
			return false
		previous_progress = keyframe_point.progress
	return true