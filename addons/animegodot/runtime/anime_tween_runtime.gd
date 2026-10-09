class_name AnimeTweenRuntime
extends AnimeTweenSpec

const INTERPOLATION_SCRIPT = preload("res://addons/animegodot/runtime/anime_interpolation.gd")
const REGISTRY_SCRIPT = preload("res://addons/animegodot/runtime/anime_registry_runtime.gd")

signal started(tween: AnimeTweenRuntime)
signal updated(tween: AnimeTweenRuntime, progress: float)
signal completed(tween: AnimeTweenRuntime)
signal killed(tween: AnimeTweenRuntime)

enum Mode {
	TO,
	FROM,
	FROM_TO,
	SET,
}

var mode: int = Mode.TO
var duration: float = 0.0
var active: bool = false
var _driver: Tween
var _captured_values: Array[Array] = []
var _position: float = 0.0
var _play_direction: int = 1
var _started := false
var _completed := false
var _killed := false
var _paused := false
var _registered := false


func _init(tween_target: Object = null, tween_mode: int = Mode.TO) -> void:
	super(tween_target)
	mode = tween_mode
	if tween_target is Node:
		tween_target.tree_exiting.connect(_on_target_tree_exiting, CONNECT_ONE_SHOT)


func add_track(new_track: AnimeTrack) -> bool:
	var added := super.add_track(new_track)
	if added:
		_recalculate_duration()
	return added


func refresh_duration() -> float:
	_recalculate_duration()
	return duration


func play() -> AnimeTweenRuntime:
	if active or _completed or _killed:
		return self
	if not is_instance_valid(target) or not options.is_valid() or tracks.is_empty():
		kill(false)
		return self
	_recalculate_duration()
	if _captured_values.is_empty() and not _capture_values():
		kill(false)
		return self
	_register_with_registry()
	active = true
	_paused = false
	if not _started:
		_started = true
		_invoke(options.on_start)
		started.emit(self)
	_apply_at(_position)
	if mode == Mode.SET or is_zero_approx(duration):
		_apply_at(duration if _play_direction > 0 else 0.0)
		_emit_update(1.0 if _play_direction > 0 else 0.0)
		_finish()
		return self
	_start_driver()
	return self


func pause() -> AnimeTweenRuntime:
	if not active:
		return self
	_paused = true
	if is_instance_valid(_driver):
		_driver.pause()
	return self


func resume() -> AnimeTweenRuntime:
	if not active and _paused:
		_paused = false
		return play()
	if active and is_instance_valid(_driver):
		_paused = false
		_driver.play()
	return self


func restart() -> AnimeTweenRuntime:
	_stop_driver()
	_position = 0.0
	_play_direction = 1
	_started = false
	_completed = false
	_killed = false
	_paused = false
	return play()


func reverse() -> AnimeTweenRuntime:
	if _killed:
		return self
	_stop_driver()
	_play_direction *= -1
	_completed = false
	_paused = false
	return play()


func seek(position: float) -> AnimeTweenRuntime:
	if _captured_values.is_empty() and not _capture_values():
		return self
	_stop_driver()
	_completed = false
	_killed = false
	_paused = true
	_position = clampf(position, 0.0, duration)
	_apply_at(_position)
	_emit_update(get_progress())
	return self


func reset() -> AnimeTweenRuntime:
	_stop_driver()
	_position = 0.0
	_play_direction = 1
	_started = false
	_completed = false
	_killed = false
	_paused = true
	return self


func kill(emit_callback: bool = true) -> void:
	if _killed or _completed:
		return
	_stop_driver()
	_killed = true
	_paused = false
	_registered = false
	if emit_callback:
		_invoke(options.on_kill)
	killed.emit(self)


func is_finished() -> bool:
	return _completed or _killed


func is_paused() -> bool:
	return _paused and active


func get_position() -> float:
	return _position


func get_progress() -> float:
	return 0.0 if is_zero_approx(duration) else _position / duration


func get_property_keys() -> Array[AnimePropertyKey]:
	var result: Array[AnimePropertyKey] = []
	for track in tracks:
		if track.is_valid():
			result.append(track.accessor.identity)
	return result


func get_active_property_keys() -> Array[AnimePropertyKey]:
	return get_property_keys() if active else []


func kill_properties(property_keys: Array[AnimePropertyKey]) -> void:
	for track_index in range(tracks.size() - 1, -1, -1):
		var should_remove := false
		for property_key in property_keys:
			if tracks[track_index].accessor.identity.same_as(property_key):
				should_remove = true
				break
		if should_remove:
			tracks.remove_at(track_index)
			if track_index < _captured_values.size():
				_captured_values.remove_at(track_index)
	if tracks.is_empty():
		kill(false)
	else:
		_recalculate_duration()


func sample_at(position: float, apply_values: bool = true, emit_update: bool = false) -> void:
	if _captured_values.is_empty() and not _capture_values():
		return
	_position = clampf(position, 0.0, duration)
	if apply_values:
		_apply_at(_position)
	if emit_update:
		_emit_update(get_progress())


func prepare_for_timeline() -> bool:
	_stop_driver()
	_completed = false
	_killed = false
	_paused = false
	_recalculate_duration()
	return not _captured_values.is_empty() or _capture_values()


func begin_from_timeline(start_position: float) -> void:
	_position = clampf(start_position, 0.0, duration)
	if _started:
		return
	_started = true
	_invoke(options.on_start)
	started.emit(self)


func finish_from_timeline(end_position: float) -> void:
	sample_at(end_position)
	_finish()


func reset_for_timeline() -> void:
	_stop_driver()
	_position = 0.0
	_started = false
	_completed = false
	_killed = false
	_paused = false


func _capture_values() -> bool:
	_captured_values.clear()
	for track in tracks:
		if not track.is_valid():
			return false
		var current_value = track.get_start_value()
		var values: Array = []
		match mode:
			Mode.FROM:
				values.append(track.end_value)
				values.append_array(track.keyframes)
				values.append(current_value)
			Mode.FROM_TO:
				values.append(track.start_value if track.has_start_value else current_value)
				values.append_array(track.keyframes)
				values.append(track.end_value)
			Mode.SET:
				values.append(track.end_value)
			_:
				values.append(current_value)
				values.append_array(track.keyframes)
				values.append(track.end_value)
		_captured_values.append(values)
	return true


func _recalculate_duration() -> void:
	duration = 0.0
	for track in tracks:
		var track_duration := track.options.duration if track.options.duration >= 0.0 else options.duration
		var delay := track.options.delay if track.options.delay >= 0.0 else options.delay
		var repeat_count := track.options.repeat_count if track.options.repeat_count >= 0 else options.repeat_count
		var repeat_delay := track.options.repeat_delay if track.options.repeat_delay >= 0.0 else options.repeat_delay
		duration = maxf(duration, delay + track_duration * (repeat_count + 1) + repeat_delay * repeat_count)


func _register_with_registry() -> void:
	if _registered:
		return
	var registry = REGISTRY_SCRIPT.get_instance()
	if registry == null:
		return
	registry.register(self, target, options.overwrite)
	_registered = true


func _start_driver() -> void:
	var end_position := duration if _play_direction > 0 else 0.0
	var remaining := absf(end_position - _position)
	if is_zero_approx(remaining):
		_finish()
		return
	var tree := Engine.get_main_loop() as SceneTree
	if target is Node and target.is_inside_tree():
		_driver = target.create_tween()
	elif tree != null:
		_driver = tree.create_tween()
	if _driver == null:
		kill(false)
		return
	_driver.set_ignore_time_scale(options.ignore_time_scale)
	_driver.set_process_mode(options.process_mode)
	_driver.set_speed_scale(options.speed_scale)
	_driver.tween_method(Callable(self, "_on_driver_position"), _position, end_position, remaining)
	_driver.finished.connect(_on_driver_finished)


func _apply_at(position: float) -> void:
	for index in tracks.size():
		var value := _sample_track(tracks[index], _captured_values[index], position)
		tracks[index].apply(value)


func _sample_track(track: AnimeTrack, values: Array, position: float) -> Variant:
	if mode == Mode.SET or values.size() == 1:
		return values.back()
	var track_duration := track.options.duration if track.options.duration >= 0.0 else options.duration
	var delay := track.options.delay if track.options.delay >= 0.0 else options.delay
	var repeat_count := track.options.repeat_count if track.options.repeat_count >= 0 else options.repeat_count
	var repeat_delay := track.options.repeat_delay if track.options.repeat_delay >= 0.0 else options.repeat_delay
	var local_position := maxf(position - delay, 0.0)
	if position < delay:
		return values.front()
	if is_zero_approx(track_duration):
		return values.back()
	if position <= delay:
		return values.front()
	var total_duration := track_duration * (repeat_count + 1) + repeat_delay * repeat_count
	if local_position >= total_duration:
		var final_reverse := _is_reversed(track, repeat_count)
		return values.front() if final_reverse else values.back()
	var cycle_period := track_duration + repeat_delay
	var cycle_index := mini(int(floor(local_position / cycle_period)), repeat_count)
	var cycle_position := minf(fmod(local_position, cycle_period), track_duration)
	if _is_reversed(track, cycle_index):
		cycle_position = track_duration - cycle_position
	var segment_length := track_duration / float(values.size() - 1)
	var segment_index := mini(int(floor(cycle_position / segment_length)), values.size() - 2)
	var segment_position := clampf(cycle_position - segment_index * segment_length, 0.0, segment_length)
	var easing := _ease_parts(track.options.ease if track.options.ease != AnimeEase.INHERIT else options.ease)
	var weight := float(Tween.interpolate_value(0.0, 1.0, segment_position, segment_length, easing.x, easing.y))
	var interpolator: Variant = track.options.interpolator if track.options.interpolator.is_valid() else null
	return INTERPOLATION_SCRIPT.value(values[segment_index], values[segment_index + 1], weight, interpolator)


func _is_reversed(track: AnimeTrack, cycle_index: int) -> bool:
	var direction := track.options.direction if track.options.direction != AnimeOptions.Direction.INHERIT else options.direction
	if direction == AnimeOptions.Direction.REVERSE:
		return true
	var yoyo := track.options.yoyo == AnimeTrackOptions.Toggle.ENABLED if track.options.yoyo != AnimeTrackOptions.Toggle.INHERIT else options.yoyo
	return cycle_index % 2 == 1 if direction == AnimeOptions.Direction.ALTERNATE or yoyo else false


func _ease_parts(ease: int) -> Vector2i:
	if ease == AnimeEase.LINEAR:
		return Vector2i(Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	var family := int((ease - 1) / 3)
	var phase := (ease - 1) % 3
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
	return Vector2i(transition, ease_mode)


func _on_driver_position(position: float) -> void:
	if _killed:
		return
	_position = position
	_apply_at(position)
	_emit_update(get_progress())


func _on_driver_finished() -> void:
	if _killed or _completed:
		return
	_position = duration if _play_direction > 0 else 0.0
	_apply_at(_position)
	_finish()


func _on_target_tree_exiting() -> void:
	if not _completed:
		kill(false)


func _stop_driver() -> void:
	if is_instance_valid(_driver):
		_driver.kill()
	_driver = null
	active = false


func _emit_update(progress: float) -> void:
	_invoke(options.on_update, [progress])
	updated.emit(self, progress)


func _finish() -> void:
	if _completed or _killed:
		return
	_stop_driver()
	_completed = true
	_paused = false
	_registered = false
	_invoke(options.on_complete)
	completed.emit(self)


func _invoke(callback: Callable, arguments: Array = []) -> void:
	if callback.is_valid():
		callback.callv(arguments)