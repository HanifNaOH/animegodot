class_name AnimeAnimationExporter
extends RefCounted


static func from_tween(player: AnimationPlayer, tween: AnimeTweenRuntime) -> Animation:
	var animation := Animation.new()
	if not is_instance_valid(player) or not is_instance_valid(tween) or not is_instance_valid(tween.target):
		push_warning("AnimeGodot AnimationPlayer export requires a valid player and typed tween.")
		return animation
	if not tween.target is Node:
		push_warning("AnimeGodot AnimationPlayer export requires a Node target.")
		return animation
	if player.is_inside_tree() and tween.target.is_inside_tree() and player.get_tree() != tween.target.get_tree():
		push_warning("AnimeGodot AnimationPlayer export target must be in the same SceneTree as the player.")
		return animation

	animation.length = maxf(tween.duration, 0.0)
	var animation_root := player.get_node_or_null(player.root_node)
	if animation_root == null:
		animation_root = player.get_parent()
	if animation_root == null:
		push_warning("AnimeGodot AnimationPlayer export could not resolve the animation root.")
		return animation

	for track in tween.tracks:
		if not track.is_valid():
			push_warning("AnimeGodot AnimationPlayer export skipped an invalid typed track.")
			continue
		var native_property_path := track.accessor.get_native_path(tween.target)
		if native_property_path.is_empty():
			push_warning("AnimeGodot AnimationPlayer export skipped an accessor without a native track path.")
			continue
		if _has_unsupported_timing(tween, track):
			push_warning("AnimeGodot AnimationPlayer export currently supports only linear tracks without repeats or custom interpolation.")
			continue
		var values := _values_for(tween, track)
		if values.is_empty():
			continue
		var relative_path := animation_root.get_path_to(tween.target)
		var full_path := NodePath(String(relative_path) + ":" + String(native_property_path))
		var animation_track := animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(animation_track, full_path)
		animation.track_set_interpolation_type(animation_track, Animation.INTERPOLATION_LINEAR)
		var track_duration := _track_duration(tween, track)
		var track_delay := _track_delay(tween, track)
		if tween.mode == AnimeTweenRuntime.Mode.SET:
			animation.track_insert_key(animation_track, track_delay, values.back())
			continue
		for value_index in values.size():
			var time := track_delay
			if values.size() > 1:
				time += track_duration * float(value_index) / float(values.size() - 1)
			animation.track_insert_key(animation_track, time, values[value_index])
	return animation


static func add_to_player(player: AnimationPlayer, name: StringName, tween: AnimeTweenRuntime) -> Animation:
	if not is_instance_valid(player):
		push_warning("AnimeGodot AnimationPlayer installation requires a valid player.")
		return Animation.new()
	var animation := from_tween(player, tween)
	var library_name: StringName = &""
	var library: AnimationLibrary
	if player.has_animation_library(library_name):
		library = player.get_animation_library(library_name)
	else:
		library = AnimationLibrary.new()
		player.add_animation_library(library_name, library)
	if library.has_animation(name):
		library.remove_animation(name)
	library.add_animation(name, animation)
	return animation


static func _values_for(tween: AnimeTweenRuntime, track: AnimeTrack) -> Array:
	var current_value = track.accessor.read(tween.target)
	var values: Array = []
	match tween.mode:
		AnimeTweenRuntime.Mode.FROM:
			values.append(track.end_value)
			values.append_array(track.keyframes)
			values.append(current_value)
		AnimeTweenRuntime.Mode.FROM_TO:
			values.append(track.start_value if track.has_start_value else current_value)
			values.append_array(track.keyframes)
			values.append(track.end_value)
		AnimeTweenRuntime.Mode.SET:
			values.append(track.end_value)
		_:
			values.append(current_value)
			values.append_array(track.keyframes)
			values.append(track.end_value)
	return values


static func _has_unsupported_timing(tween: AnimeTweenRuntime, track: AnimeTrack) -> bool:
	var repeat_count := track.options.repeat_count if track.options.repeat_count >= 0 else tween.options.repeat_count
	var repeat_delay := track.options.repeat_delay if track.options.repeat_delay >= 0.0 else tween.options.repeat_delay
	var yoyo := track.options.yoyo == AnimeTrackOptions.Toggle.ENABLED if track.options.yoyo != AnimeTrackOptions.Toggle.INHERIT else tween.options.yoyo
	var direction := track.options.direction if track.options.direction != AnimeOptions.Direction.INHERIT else tween.options.direction
	var ease := track.options.ease if track.options.ease != AnimeEase.INHERIT else tween.options.ease
	var interpolator := track.options.interpolator if track.options.interpolator.is_valid() else Callable()
	return (
		repeat_count > 0
		or repeat_delay > 0.0
		or yoyo
		or direction != AnimeOptions.Direction.NORMAL
		or ease != AnimeEase.LINEAR
		or interpolator.is_valid()
	)


static func _track_duration(tween: AnimeTweenRuntime, track: AnimeTrack) -> float:
	return track.options.duration if track.options.duration >= 0.0 else tween.options.duration


static func _track_delay(tween: AnimeTweenRuntime, track: AnimeTrack) -> float:
	return track.options.delay if track.options.delay >= 0.0 else tween.options.delay