class_name AnimeTween
extends RefCounted

const EASING_SCRIPT = preload("res://addons/animegodot/runtime/anime_easing.gd")
const PROPERTY_SCRIPT = preload("res://addons/animegodot/runtime/anime_property.gd")
const REGISTRY_SCRIPT = preload("res://addons/animegodot/runtime/anime_registry.gd")
const STAGGER_SCRIPT = preload("res://addons/animegodot/runtime/anime_stagger.gd")

signal started(tween: AnimeTween)
signal updated(tween: AnimeTween, progress: float)
signal completed(tween: AnimeTween)
signal killed(tween: AnimeTween)

const DEFAULT_OVERWRITE := &"auto"
const RESERVED_OPTIONS := [
	&"duration",
	&"delay",
	&"ease",
	&"repeat",
	&"loop",
	&"repeat_delay",
	&"yoyo",
	&"direction",
	&"stagger",
	&"keyframes",
	&"interpolate",
	&"overwrite",
	&"speed_scale",
	&"ignore_time_scale",
	&"process_mode",
	&"autoplay",
	&"on_start",
	&"on_update",
	&"on_complete",
	&"on_kill",
]

var duration: float = 0.0
var active: bool = false

var _driver: Tween
var _tracks: Dictionary = {}
var _target_ref: WeakRef
var _mode: StringName = &"to"
var _options: Dictionary = {}
var _from_overrides: Dictionary = {}
var _on_start: Variant
var _on_update: Variant
var _on_complete: Variant
var _on_kill: Variant
var _position := 0.0
var _speed_scale := 1.0
var _play_direction := 1
var _paused := false
var _registered := false
var _started := false
var _completed := false
var _killed := false


static func create(target: Object, properties: Dictionary, mode: StringName = &"to"):
	var instance := AnimeTween.new()
	instance._configure(target, properties, mode)
	return instance


static func create_from_to(target: Object, from_properties: Dictionary, to_properties: Dictionary):
	var instance := AnimeTween.new()
	instance._configure_from_to(target, from_properties, to_properties)
	return instance


static func estimate_duration(properties: Dictionary, target_count: int = 1) -> float:
	var longest := 0.0
	var global_duration := maxf(float(properties.get(&"duration", properties.get("duration", 0.0))), 0.0)
	for property_key in properties:
		var property_path := StringName(property_key)
		if property_path in RESERVED_OPTIONS:
			continue
		var config: Dictionary = properties[property_key] if properties[property_key] is Dictionary and _is_track_config(properties[property_key]) else {}
		var values_count := _keyframe_count(properties, property_path, config)
		var track_duration := maxf(float(config.get(&"duration", global_duration)), 0.0)
		var delay := maxf(float(config.get(&"delay", properties.get(&"delay", 0.0))), 0.0)
		var repeat_count := _repeat_count(config, properties)
		var repeat_delay := maxf(float(config.get(&"repeat_delay", properties.get(&"repeat_delay", 0.0))), 0.0)
		var total := delay + track_duration * (repeat_count + 1) + repeat_delay * repeat_count
		longest = maxf(longest, total)
	if properties.has(&"stagger"):
		longest += STAGGER_SCRIPT.maximum_delay(target_count, properties[&"stagger"])
	return longest


static func _is_track_config(value: Dictionary) -> bool:
	for key in [&"value", &"to", &"keyframes", &"interpolate", &"duration", &"delay", &"ease", &"repeat", &"loop", &"repeat_delay", &"yoyo", &"direction"]:
		if value.has(key):
			return true
	return false


static func _keyframe_count(properties: Dictionary, property_path: StringName, config: Dictionary) -> int:
	if config.has(&"keyframes") and config[&"keyframes"] is Array:
		return maxi((config[&"keyframes"] as Array).size() + 1, 2)
	if properties.has(&"keyframes") and properties[&"keyframes"] is Dictionary:
		var frames = properties[&"keyframes"].get(property_path, properties[&"keyframes"].get(String(property_path), []))
		if frames is Array:
			return maxi(frames.size() + 1, 2)
	var raw_value = properties.get(property_path, properties.get(String(property_path)))
	if raw_value is Array:
		return maxi(raw_value.size() + 1, 2)
	return 2


static func _repeat_count(config: Dictionary, properties: Dictionary) -> int:
	var value = config.get(&"repeat", properties.get(&"repeat", null))
	if value == null and config.has(&"loop"):
		value = maxi(int(config[&"loop"]) - 1, 0)
	if value == null and properties.has(&"loop") and properties[&"loop"] is int:
		value = maxi(int(properties[&"loop"]) - 1, 0)
	return maxi(int(value if value != null else 0), 0)


static func configure_native_tween(native_tween: Tween, options: Dictionary) -> Tween:
	var ignore_time_scale = options.get(&"ignore_time_scale", options.get("ignore_time_scale", null))
	if ignore_time_scale != null:
		native_tween.set_ignore_time_scale(bool(ignore_time_scale))
	var process_mode = options.get(&"process_mode", options.get("process_mode", null))
	if process_mode is String or process_mode is StringName:
		match StringName(process_mode):
			&"physics":
				native_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
			&"idle":
				native_tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	elif process_mode is int:
		native_tween.set_process_mode(int(process_mode))
	return native_tween


func _configure(target: Object, properties: Dictionary, mode: StringName) -> void:
	_target_ref = weakref(target)
	_mode = mode
	_options = properties.duplicate(true)
	_speed_scale = maxf(float(_option_value(properties, &"speed_scale", 1.0)), 0.0)
	_on_start = _option_value(properties, &"on_start", null)
	_on_update = _option_value(properties, &"on_update", null)
	_on_complete = _option_value(properties, &"on_complete", null)
	_on_kill = _option_value(properties, &"on_kill", null)
	_build_tracks(target)


func _configure_from_to(target: Object, from_properties: Dictionary, to_properties: Dictionary) -> void:
	var combined := to_properties.duplicate(true)
	for property_key in from_properties:
		var property_path := StringName(property_key)
		if property_path in RESERVED_OPTIONS:
			continue
		if not combined.has(property_key) and not combined.has(property_path):
			combined[property_key] = from_properties[property_key]
	for option_key in from_properties:
		if StringName(option_key) in RESERVED_OPTIONS and not combined.has(option_key):
			combined[option_key] = from_properties[option_key]
	for property_key in from_properties:
		var property_path := StringName(property_key)
		if property_path not in RESERVED_OPTIONS:
			_from_overrides[property_path] = from_properties[property_key]
	_configure(target, combined, &"from_to")


func _build_tracks(target: Object) -> void:
	_tracks.clear()
	duration = 0.0
	for property_key in _options:
		var property_path := StringName(property_key)
		if property_path in RESERVED_OPTIONS:
			continue
		if not PROPERTY_SCRIPT.exists(target, property_path):
			push_warning("AnimeGodot cannot animate missing property '%s'." % property_path)
			continue
		var raw_value = _options[property_key]
		var config: Dictionary = raw_value if raw_value is Dictionary and _is_track_config(raw_value) else {}
		var endpoint = config.get(&"value", config.get(&"to", raw_value))
		var keyframe_values: Array = []
		if config.has(&"keyframes") and config[&"keyframes"] is Array:
			keyframe_values = config[&"keyframes"].duplicate(true)
		elif _options.has(&"keyframes") and _options[&"keyframes"] is Dictionary:
			var frames = _options[&"keyframes"].get(property_path, _options[&"keyframes"].get(String(property_path), []))
			if frames is Array:
				keyframe_values = frames.duplicate(true)
		elif raw_value is Array:
			keyframe_values = raw_value.duplicate(true)

		var current_value := PROPERTY_SCRIPT.read(target, property_path)
		var values: Array = []
		if _mode == &"from":
			values = keyframe_values if not keyframe_values.is_empty() else [endpoint]
			values.append(current_value)
		elif _mode == &"from_to":
			values.append(_from_overrides.get(property_path, current_value))
			values.append_array(keyframe_values if not keyframe_values.is_empty() else [endpoint])
		else:
			values.append(current_value)
			values.append_array(keyframe_values if not keyframe_values.is_empty() else [endpoint])
		if values.size() < 2:
			values.append(endpoint)

		var track_duration := maxf(float(config.get(&"duration", _options.get(&"duration", 0.0))), 0.0)
		var delay := maxf(float(config.get(&"delay", _options.get(&"delay", 0.0))), 0.0)
		var repeat_count := _repeat_count(config, _options)
		var repeat_delay := maxf(float(config.get(&"repeat_delay", _options.get(&"repeat_delay", 0.0))), 0.0)
		var track := {
			"values": values,
			"duration": track_duration,
			"delay": delay,
			"repeat": repeat_count,
			"repeat_delay": repeat_delay,
			"ease": config.get(&"ease", _options.get(&"ease", &"out_quad")),
			"interpolator": config.get(&"interpolate", _options.get(&"interpolate", null)),
			"yoyo": bool(config.get(&"yoyo", _options.get(&"yoyo", false))),
			"direction": StringName(config.get(&"direction", _options.get(&"direction", &"normal"))),
		}
		track["total_duration"] = delay + track_duration * (repeat_count + 1) + repeat_delay * repeat_count
		_tracks[property_path] = track
		duration = maxf(duration, float(track["total_duration"]))


func get_track_data() -> Dictionary:
	return _tracks.duplicate(true)


func play():
	if active or _completed or _killed:
		return self
	var target := _get_target()
	if target == null:
		kill(false)
		return self
	active = true
	_paused = false
	_connect_target_lifecycle(target)
	_register_with_registry(target)
	_apply_at(_position)
	_emit_started()
	if _mode == &"set" or duration <= 0.0 or _tracks.is_empty():
		_apply_final_state() if _play_direction > 0 else _apply_at(0.0)
		_emit_update(1.0 if _play_direction > 0 else 0.0)
		_finish()
		return self

	var end_position := duration if _play_direction > 0 else 0.0
	var remaining := absf(end_position - _position)
	if is_zero_approx(remaining):
		_finish()
		return self
	_driver = _create_native_tween(target)
	if _driver == null:
		kill(false)
		return self
	_driver.tween_method(
		Callable(self, "_on_driver_position"),
		_position,
		end_position,
		remaining
	)
	_driver.finished.connect(_on_driver_finished)
	_apply_speed_scale()
	return self


func pause():
	if not active:
		return self
	_paused = true
	if is_instance_valid(_driver):
		_driver.pause()
	return self


func resume():
	if not active and _paused:
		_paused = false
		return play()
	if active and is_instance_valid(_driver):
		_paused = false
		_driver.play()
	return self


func restart():
	_stop_driver()
	_position = 0.0
	_play_direction = 1
	_completed = false
	_killed = false
	_paused = false
	_started = false
	return play()


func reverse():
	if _killed:
		return self
	_stop_driver()
	_completed = false
	_play_direction *= -1
	_paused = false
	return play()


func seek(position: float):
	_stop_driver()
	_completed = false
	_killed = false
	active = false
	_paused = true
	_position = clampf(position, 0.0, duration)
	_apply_at(_position)
	_emit_update(0.0 if is_zero_approx(duration) else _position / duration)
	return self


func reset():
	_stop_driver()
	_completed = false
	_killed = false
	active = false
	_paused = true
	_started = false
	_position = 0.0
	_play_direction = 1
	_apply_at(0.0)
	return self


func set_speed_scale(scale: float):
	_speed_scale = maxf(scale, 0.0)
	if is_instance_valid(_driver):
		_driver.set_speed_scale(_speed_scale)
	return self


func kill(emit_callback: bool = true) -> void:
	if _killed or _completed:
		return
	_stop_driver()
	_killed = true
	active = false
	_paused = false
	_registered = false
	if emit_callback:
		_invoke(_on_kill)
	killed.emit(self)


func kill_properties(property_paths: Array) -> void:
	if _killed or _completed:
		return
	for property_path in property_paths:
		_tracks.erase(StringName(property_path))
	if _tracks.is_empty():
		kill(false)


func is_finished() -> bool:
	return _completed or _killed


func get_target() -> Object:
	return _get_target()


func get_property_paths() -> Array:
	return _tracks.keys()


func get_active_property_paths() -> Array:
	return _tracks.keys() if active else []


func get_position() -> float:
	return _position


func get_progress() -> float:
	return 0.0 if is_zero_approx(duration) else _position / duration


func _create_native_tween(target: Object) -> Tween:
	var native_tween: Tween
	if target is Node and target.is_inside_tree():
		native_tween = target.create_tween()
	else:
		var main_loop := Engine.get_main_loop()
		if main_loop is SceneTree:
			native_tween = main_loop.create_tween()
	if native_tween == null:
		return null
	return configure_native_tween(native_tween, _options)


func _connect_target_lifecycle(target: Object) -> void:
	if target is Node and not target.tree_exiting.is_connected(_on_target_tree_exiting):
		target.tree_exiting.connect(_on_target_tree_exiting, CONNECT_ONE_SHOT)


func _register_with_registry(target: Object) -> void:
	if _registered:
		return
	var registry = REGISTRY_SCRIPT.get_instance()
	if registry == null:
		return
	registry.register(self, target, get_property_paths(), _options.get(&"overwrite", DEFAULT_OVERWRITE))
	_registered = true


func _get_target() -> Object:
	if _target_ref == null:
		return null
	var target = _target_ref.get_ref()
	if target == null or not is_instance_valid(target):
		return null
	return target


func _option_value(properties: Dictionary, option_name: StringName, default_value: Variant) -> Variant:
	if properties.has(option_name):
		return properties[option_name]
	var string_name := String(option_name)
	if properties.has(string_name):
		return properties[string_name]
	return default_value


func _apply_at(position: float) -> void:
	var target := _get_target()
	if target == null:
		return
	for property_path in _tracks:
		PROPERTY_SCRIPT.write(target, property_path, sample_track(_tracks[property_path], position))


static func sample_track(track: Dictionary, position: float) -> Variant:
	var values: Array = track["values"]
	var delay: float = track["delay"]
	var cycle_duration: float = track["duration"]
	var repeat_count: int = track["repeat"]
	var repeat_delay: float = track["repeat_delay"]
	if position >= float(track["total_duration"]):
		var final_reversed := is_reversed(track, repeat_count)
		return sample_keyframes(values, 0.0 if final_reversed else cycle_duration, cycle_duration, track["ease"], track["interpolator"])
	if position <= delay or is_zero_approx(cycle_duration):
		return values[0]
	var elapsed := position - delay
	var cycle_period := cycle_duration + repeat_delay
	var cycle_index := mini(int(floor(elapsed / cycle_period)), repeat_count)
	var cycle_position := fmod(elapsed, cycle_period)
	if cycle_position >= cycle_duration:
		cycle_position = cycle_duration
	var reversed := is_reversed(track, cycle_index)
	if reversed:
		cycle_position = cycle_duration - cycle_position
	return sample_keyframes(values, cycle_position, cycle_duration, track["ease"], track["interpolator"])


static func is_reversed(track: Dictionary, cycle_index: int) -> bool:
	var direction: StringName = track["direction"]
	if direction == &"reverse":
		return true
	if direction == &"alternate_reverse":
		return cycle_index % 2 == 0
	if direction == &"alternate" or bool(track["yoyo"]):
		return cycle_index % 2 == 1
	return false


static func sample_keyframes(values: Array, position: float, total: float, ease_value: Variant, interpolator: Variant = null) -> Variant:
	if values.size() < 2 or is_zero_approx(total):
		return values.back()
	var segment_count := values.size() - 1
	var segment_length := total / segment_count
	var segment_index := mini(int(floor(position / segment_length)), segment_count - 1)
	var local_position := clampf(position - segment_index * segment_length, 0.0, segment_length)
	var easing := EASING_SCRIPT.resolve(ease_value)
	var weight := float(Tween.interpolate_value(
		0.0,
		1.0,
		local_position,
		segment_length,
		easing["transition"],
		easing["ease"]
	))
	return AnimeInterpolation.value(
		values[segment_index],
		values[segment_index + 1],
		weight,
		interpolator
	)


func _on_driver_position(position: float) -> void:
	if _killed:
		return
	_position = position
	_apply_at(position)
	_emit_update(get_progress())


func _on_driver_finished() -> void:
	if _killed or _completed:
		return
	_apply_at(_position)
	_finish()


func _stop_driver() -> void:
	if is_instance_valid(_driver):
		_driver.kill()
	_driver = null
	active = false


func _apply_speed_scale() -> void:
	set_speed_scale(_speed_scale)


func _apply_final_state() -> void:
	var target := _get_target()
	if target == null:
		return
	for property_path in _tracks:
		var track: Dictionary = _tracks[property_path]
		var final_reversed := is_reversed(track, int(track["repeat"]))
		var final_position := 0.0 if final_reversed else float(track["duration"])
		PROPERTY_SCRIPT.write(target, property_path, sample_keyframes(track["values"], final_position, track["duration"], track["ease"], track["interpolator"]))


func _emit_started() -> void:
	if _started or _killed:
		return
	_started = true
	_invoke(_on_start)
	started.emit(self)


func _emit_update(progress: float) -> void:
	if _killed:
		return
	_invoke(_on_update, [progress])
	updated.emit(self, progress)


func _finish() -> void:
	if _completed or _killed:
		return
	_stop_driver()
	active = false
	_paused = false
	_completed = true
	_registered = false
	_invoke(_on_complete)
	completed.emit(self)


func _on_target_tree_exiting() -> void:
	if not _completed:
		kill(false)


func _invoke(callback: Variant, arguments: Array = []) -> void:
	if callback is Callable and callback.is_valid():
		callback.callv(arguments)
