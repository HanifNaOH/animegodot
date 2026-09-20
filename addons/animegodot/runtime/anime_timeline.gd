class_name AnimeTimeline
extends RefCounted

const TWEEN_SCRIPT = preload("res://addons/animegodot/runtime/anime_tween.gd")
const PROPERTY_SCRIPT = preload("res://addons/animegodot/runtime/anime_property.gd")
const EASING_SCRIPT = preload("res://addons/animegodot/runtime/anime_easing.gd")
const STAGGER_SCRIPT = preload("res://addons/animegodot/runtime/anime_stagger.gd")

const TIMELINE_OPTIONS := [
	&"defaults",
	&"delay",
	&"repeat",
	&"loop",
	&"repeat_delay",
	&"yoyo",
	&"direction",
	&"autoplay",
	&"on_start",
	&"on_update",
	&"on_complete",
	&"on_kill",
]

signal started(timeline)
signal updated(timeline, progress: float)
signal completed(timeline)
signal killed(timeline)

const RESERVED_OPTIONS := [
	&"duration",
	&"delay",
	&"ease",
	&"repeat",
	&"yoyo",
	&"stagger",
	&"on_start",
	&"on_update",
	&"on_complete",
	&"on_kill",
]

var owner: Node
var duration: float = 0.0
var active := false
var time_scale: float = 1.0:
	set(value):
		time_scale = value
		_apply_time_scale()

var _defaults: Dictionary = {}
var _options: Dictionary = {}
var _entries: Array = []
var _labels: Dictionary = {}
var _cursor := 0.0
var _last_start := 0.0
var _last_end := 0.0
var _clock: Tween
var _progress_tween: Tween
var _active_tweens: Array = []
var _active_timelines: Array = []
var _initial_captured := false
var _direction := 1
var _position := 0.0
var _completed := false
var _killed := false
var _paused := false
var _clock_finished := false
var _repeat_count := 0
var _repeat_index := 0
var _repeat_delay := 0.0
var _started_emitted := false
var _on_start: Variant
var _on_update: Variant
var _on_complete: Variant
var _on_kill: Variant
var _autoplay_scheduled := false


func _init(context_owner: Node = null, defaults: Dictionary = {}) -> void:
	owner = context_owner
	_options = defaults.duplicate(true)
	_defaults = _options.get(&"defaults", {}).duplicate(true) if _options.get(&"defaults", {}) is Dictionary else {}
	for option_key in _options:
		if StringName(option_key) not in TIMELINE_OPTIONS:
			_defaults[option_key] = _options[option_key]
	_on_start = _options.get(&"on_start", _options.get("on_start"))
	_on_update = _options.get(&"on_update", _options.get("on_update"))
	_on_complete = _options.get(&"on_complete", _options.get("on_complete"))
	_on_kill = _options.get(&"on_kill", _options.get("on_kill"))
	_repeat_count = _timeline_repeat_count()
	_repeat_delay = maxf(float(_options.get(&"repeat_delay", _options.get("repeat_delay", 0.0))), 0.0)
	_direction = _timeline_direction(0)
	if is_instance_valid(owner):
		owner.tree_exiting.connect(_on_owner_tree_exiting, CONNECT_ONE_SHOT)


func to(target: Variant, properties: Dictionary, position: Variant = null):
	return _add_tween_entry(target, properties, &"to", position)


func from(target: Variant, properties: Dictionary, position: Variant = null):
	return _add_tween_entry(target, properties, &"from", position)


func set_value(target: Variant, properties: Dictionary, position: Variant = null):
	return _add_tween_entry(target, properties, &"set", position)


func parallel(target: Variant, properties: Dictionary):
	return to(target, properties, &"<")


func add(timeline: AnimeTimeline, position: Variant = null):
	if timeline == null:
		return self
	var entry := {
		"type": &"timeline",
		"timeline": timeline,
		"start": 0.0,
		"duration": timeline.duration,
		"started": false,
	}
	return _add_entry(entry, position)


func invoke(callback: Callable, position: Variant = null, arguments: Array = []):
	var entry := {
		"type": &"call",
		"callback": callback,
		"arguments": arguments.duplicate(true),
		"start": 0.0,
		"duration": 0.0,
		"started": false,
	}
	return _add_entry(entry, position)


func label(name: StringName, position: Variant = null):
	_labels[name] = _resolve_position(position)
	return self


func play():
	if active:
		return self
	if _completed or _killed:
		return self

	var start_position := _position if _paused else 0.0
	start_position = clampf(start_position, 0.0, duration)
	_initial_capture()
	active = true
	_paused = false
	_clock_finished = false
	if not _started_emitted:
		_emit_started()
	if duration <= 0.0:
		for entry in _entries:
			_start_entry(entry)
		_emit_progress(1.0)
		_finish()
		return self

	_start_cycle(start_position, maxf(float(_options.get(&"delay", _options.get("delay", 0.0))), 0.0) if is_zero_approx(start_position) else 0.0)
	return self


func _start_cycle(start_position: float, cycle_delay: float) -> void:
	_clock = _create_native_tween()
	_progress_tween = _create_native_tween()
	if _clock == null or _progress_tween == null:
		kill()
		return

	var scheduled := _scheduled_entries()
	scheduled.sort_custom(Callable(self, "_sort_scheduled_entries"))
	var clock_position := 0.0
	if cycle_delay > 0.0:
		_clock.tween_interval(cycle_delay)
	for scheduled_entry in scheduled:
		var start_time: float = scheduled_entry["start"]
		var entry: Dictionary = scheduled_entry["entry"]
		var entry_duration: float = entry["duration"]
		if start_position > start_time + entry_duration:
			continue
		if entry["type"] == &"call" and start_position > start_time:
			continue
		var relative_start := maxf(start_time - start_position, 0.0)
		var elapsed := maxf(start_position - start_time, 0.0)
		var gap := relative_start - clock_position
		if gap > 0.0:
			_clock.tween_interval(gap)
		_clock.tween_callback(Callable(self, "_start_scheduled_entry").bind(entry, elapsed))
		clock_position = maxf(clock_position, relative_start)
	var remaining := duration - start_position - clock_position
	if remaining > 0.0:
		_clock.tween_interval(remaining)
	_clock.finished.connect(_on_clock_finished)

	if cycle_delay > 0.0:
		_progress_tween.tween_interval(cycle_delay)
	var progress_duration := maxf(duration - start_position, 0.0)
	if progress_duration > 0.0:
		_progress_tween.tween_method(
			Callable(self, "_emit_progress"),
			start_position / duration,
			1.0,
			progress_duration
		)
	else:
		_progress_tween.tween_callback(Callable(self, "_emit_progress").bind(1.0))
	_apply_time_scale()


func pause():
	if not active:
		return self
	_paused = true
	if is_instance_valid(_clock):
		_clock.pause()
	if is_instance_valid(_progress_tween):
		_progress_tween.pause()
	for tween in _active_tweens.duplicate():
		tween.pause()
	for timeline in _active_timelines.duplicate():
		timeline.pause()
	return self


func resume():
	if not active and _paused:
		return play()
	if not active:
		return self
	_paused = false
	if is_instance_valid(_clock):
		_clock.play()
	if is_instance_valid(_progress_tween):
		_progress_tween.play()
	for tween in _active_tweens.duplicate():
		tween.resume()
	for timeline in _active_timelines.duplicate():
		timeline.resume()
	return self


func restart():
	_restart_internal(_timeline_direction(0))
	return self


func reverse():
	_direction *= -1
	_restart_internal(_direction)
	return self


func seek(position: float):
	_initial_capture()
	_stop_runtime()
	_reset_entry_runtime()
	_completed = false
	_killed = false
	active = false
	_paused = true
	_position = clampf(position, 0.0, duration)
	_apply_at(_position)
	_emit_progress(1.0 if is_zero_approx(duration) else _position / duration)
	return self


func kill(emit_callbacks: bool = true) -> void:
	if _killed:
		return
	_stop_runtime(emit_callbacks)
	active = false
	_killed = true
	if emit_callbacks:
		_invoke(_on_kill)
	killed.emit(self)


func is_finished() -> bool:
	return _completed or _killed


func is_paused() -> bool:
	return _paused and active


func get_position() -> float:
	return _position


func _add_tween_entry(target: Variant, properties: Dictionary, mode: StringName, position: Variant):
	var merged_properties := _defaults.duplicate(true)
	for property_key in properties:
		merged_properties[property_key] = properties[property_key]
	var entry := {
		"type": &"tween",
		"target": target,
		"properties": merged_properties,
		"mode": mode,
		"start": 0.0,
		"duration": 0.0,
		"started": false,
		"handles": [],
		"initial_values": [],
		"end_values": [],
	}
	entry["duration"] = _tween_entry_duration(target, merged_properties, mode)
	return _add_entry(entry, position)


func _add_entry(entry: Dictionary, position: Variant):
	var start := _resolve_position(position)
	entry["start"] = start
	_entries.append(entry)
	_last_start = start
	_last_end = start + float(entry["duration"])
	_cursor = maxf(_cursor, _last_end)
	duration = _cursor
	if bool(_options.get(&"autoplay", _options.get("autoplay", false))) and not _autoplay_scheduled and not active:
		_autoplay_scheduled = true
		call_deferred("_start_autoplay")
	return self


func _resolve_position(position: Variant) -> float:
	if position == null:
		return _cursor
	if position is int or position is float:
		return maxf(float(position), 0.0)

	var text := String(position).strip_edges()
	if text.is_empty():
		return _cursor

	var base_text := text
	var offset := 0.0
	var plus_index := text.find("+=")
	var minus_index := text.find("-=")
	var offset_index := plus_index if plus_index >= 0 else minus_index
	if plus_index >= 0 and minus_index >= 0:
		offset_index = mini(plus_index, minus_index)
	if offset_index >= 0:
		base_text = text.substr(0, offset_index)
		var offset_value := text.substr(offset_index + 2)
		offset = float(offset_value)
		if text[offset_index] == "-":
			offset = -offset

	var base_position := _cursor
	if base_text == "<":
		base_position = _last_start
	elif base_text == ">":
		base_position = _last_end
	elif _labels.has(StringName(base_text)):
		base_position = _labels[StringName(base_text)]
	elif base_text.is_valid_float():
		base_position = float(base_text)
	else:
		push_warning("AnimeGodot timeline position '%s' is unknown; using the current cursor." % text)

	return maxf(base_position + offset, 0.0)


func _tween_entry_duration(targets_value: Variant, properties: Dictionary, mode: StringName) -> float:
	if mode == &"set":
		return 0.0
	return TWEEN_SCRIPT.estimate_duration(properties, _normalize_targets(targets_value).size())


func _scheduled_entries() -> Array:
	var scheduled: Array = []
	for entry in _entries:
		var scheduled_start := float(entry["start"])
		if _direction < 0:
			scheduled_start = duration - (float(entry["start"]) + float(entry["duration"]))
		scheduled.append({"entry": entry, "start": maxf(scheduled_start, 0.0)})
	return scheduled


func _sort_scheduled_entries(left: Dictionary, right: Dictionary) -> bool:
	return float(left["start"]) < float(right["start"])


func _start_scheduled_entry(entry: Dictionary, elapsed: float = 0.0) -> void:
	_start_entry(entry, elapsed)


func _start_entry(entry: Dictionary, elapsed: float = 0.0) -> void:
	if entry["started"] and _direction > 0:
		return
	entry["started"] = true
	match entry["type"]:
		&"call":
			var callback: Callable = entry["callback"]
			if callback.is_valid():
				callback.callv(entry["arguments"])
		&"timeline":
			var child: AnimeTimeline = entry["timeline"]
			if not _active_timelines.has(child):
				_active_timelines.append(child)
			if not child.completed.is_connected(_on_child_timeline_finished):
				child.completed.connect(_on_child_timeline_finished)
			if not child.killed.is_connected(_on_child_timeline_finished):
				child.killed.connect(_on_child_timeline_finished)
			child._restart_internal(_direction)
			if elapsed > 0.0 and elapsed < child.duration:
				child.seek(elapsed)
				child.resume()
		&"tween":
			_start_tween_entry(entry, elapsed)


func _start_tween_entry(entry: Dictionary, elapsed: float = 0.0) -> void:
	var targets := _normalize_targets(entry["target"])
	var stagger = _option_value(entry["properties"], &"stagger", 0.0)
	var base_delay := maxf(float(_option_value(entry["properties"], &"delay", 0.0)), 0.0)
	entry["handles"] = []
	for index in targets.size():
		var target = targets[index]
		if target == null or not is_instance_valid(target):
			continue
		var target_delay := base_delay + STAGGER_SCRIPT.delay_for(index, targets.size(), stagger)
		var target_elapsed := elapsed - target_delay
		var total_duration := TWEEN_SCRIPT.estimate_duration(entry["properties"], 1)
		if target_elapsed >= total_duration and entry["mode"] != &"set":
			_apply_values(target, _final_values(entry, index))
			continue
		var properties: Dictionary = entry["properties"].duplicate(true)
		if target_delay > 0.0:
			properties[&"delay"] = target_delay
		var mode: StringName = entry["mode"]
		if _direction < 0:
			mode = &"to"
			var initial_values: Dictionary = entry["initial_values"][index]
			for property_path in initial_values:
				properties[property_path] = initial_values[property_path]
		if target_elapsed > 0.0 and entry["mode"] != &"set":
			mode = &"to"
			properties[&"delay"] = 0.0
			properties[&"duration"] = maxf(total_duration - target_elapsed, 0.0)
			var final_values := _final_values(entry, index)
			for property_path in final_values:
				properties[property_path] = final_values[property_path]
		elif elapsed > 0.0 and target_elapsed < 0.0:
			properties[&"delay"] = -target_elapsed
		var tween = TWEEN_SCRIPT.create(target, properties, mode)
		tween.completed.connect(_on_child_finished)
		tween.killed.connect(_on_child_finished)
		tween.set_speed_scale(time_scale)
		tween.play()
		entry["handles"].append(tween)
		_active_tweens.append(tween)


func _final_values(entry: Dictionary, index: int) -> Dictionary:
	if _direction < 0:
		return entry["initial_values"][index]
	if bool(_option_value(entry["properties"], &"yoyo", false)) and int(_option_value(entry["properties"], &"repeat", 0)) % 2 == 1:
		return entry["initial_values"][index]
	return entry["end_values"][index]


func _initial_capture() -> void:
	if _initial_captured:
		return
	for entry in _entries:
		if entry["type"] == &"timeline":
			entry["timeline"]._initial_capture()
			continue
		if entry["type"] != &"tween":
			continue
		var targets := _normalize_targets(entry["target"])
		for target in targets:
			var initial: Dictionary = {}
			var ending: Dictionary = {}
			for property_path in _animated_properties(entry["properties"]):
				if not is_instance_valid(target) or not PROPERTY_SCRIPT.exists(target, property_path):
					continue
				var current_value = PROPERTY_SCRIPT.read(target, property_path)
				if entry["mode"] == &"from":
					initial[property_path] = entry["properties"][property_path]
					ending[property_path] = current_value
				else:
					initial[property_path] = current_value
					ending[property_path] = entry["properties"][property_path]
			entry["initial_values"].append(initial)
			entry["end_values"].append(ending)
	_initial_captured = true


func _apply_at(position: float) -> void:
	for entry in _entries:
		var entry_start: float = entry["start"]
		var entry_duration: float = entry["duration"]
		if entry["type"] == &"timeline":
			var child_position := clampf(position - entry_start, 0.0, entry_duration)
			entry["timeline"].seek(child_position)
			continue
		if entry["type"] == &"call":
			continue
		var targets := _normalize_targets(entry["target"])
		var stagger := maxf(float(_option_value(entry["properties"], &"stagger", 0.0)), 0.0)
		var base_delay := maxf(float(_option_value(entry["properties"], &"delay", 0.0)), 0.0)
		var base_duration := maxf(float(_option_value(entry["properties"], &"duration", 0.0)), 0.0)
		var repeat_count := maxi(int(_option_value(entry["properties"], &"repeat", 0)), 0)
		for index in targets.size():
			var target = targets[index]
			if target == null or not is_instance_valid(target):
				continue
			var local := position - entry_start - base_delay - stagger * index
			var initial_values: Dictionary = entry["initial_values"][index]
			var end_values: Dictionary = entry["end_values"][index]
			if entry["mode"] == &"set":
				if position >= entry_start:
					_apply_values(target, end_values)
				continue
			if base_duration <= 0.0:
				if local >= 0.0:
					_apply_values(target, end_values)
				continue
			if local <= 0.0:
				_apply_values(target, initial_values)
				continue
			var total_duration := base_duration * (repeat_count + 1)
			if local >= total_duration:
				_apply_values(target, end_values)
				continue
			var cycle_index := mini(int(floor(local / base_duration)), repeat_count)
			var cycle_position := fmod(local, base_duration)
			var is_reversed := bool(_option_value(entry["properties"], &"yoyo", false)) and cycle_index % 2 == 1
			var cycle_start: Dictionary = end_values if is_reversed else initial_values
			var cycle_end: Dictionary = initial_values if is_reversed else end_values
			var easing := EASING_SCRIPT.resolve(_option_value(entry["properties"], &"ease", &"out_quad"))
			for property_path in cycle_start:
				var value = _interpolate(cycle_start[property_path], cycle_end[property_path], cycle_position, base_duration, easing)
				PROPERTY_SCRIPT.write(target, property_path, value)


func _interpolate(initial_value: Variant, end_value: Variant, elapsed: float, total: float, easing: Dictionary) -> Variant:
		if typeof(initial_value) != typeof(end_value):
			return end_value if elapsed >= total else initial_value
		if initial_value is float or initial_value is int or initial_value is Vector2 or initial_value is Vector3 or initial_value is Vector4 or initial_value is Color:
			return Tween.interpolate_value(
				initial_value,
				end_value - initial_value,
				elapsed,
				total,
				easing["transition"],
				easing["ease"]
			)
		if initial_value is Quaternion:
			var weight := float(Tween.interpolate_value(
				0.0,
				1.0,
				elapsed,
				total,
				easing["transition"],
				easing["ease"]
			))
			return initial_value.slerp(end_value, weight)
		return end_value if elapsed >= total else initial_value


func _apply_values(target: Object, values: Dictionary) -> void:
	for property_path in values:
		PROPERTY_SCRIPT.write(target, property_path, values[property_path])


func _animated_properties(properties: Dictionary) -> Array:
	var result: Array = []
	for property_key in properties:
		var property_path := StringName(property_key)
		if property_path not in RESERVED_OPTIONS:
			result.append(property_path)
	return result


func _normalize_targets(targets_value: Variant) -> Array:
	if targets_value is Array:
		return targets_value
	return [targets_value]


func _option_value(properties: Dictionary, option_name: StringName, default_value: Variant) -> Variant:
	if properties.has(option_name):
		return properties[option_name]
	var string_name := String(option_name)
	if properties.has(string_name):
		return properties[string_name]
	return default_value


func _create_native_tween() -> Tween:
	if is_instance_valid(owner):
		return owner.create_tween()
	var main_loop := Engine.get_main_loop()
	if main_loop is SceneTree:
		return main_loop.create_tween()
	return null


func _apply_time_scale() -> void:
	if is_instance_valid(_clock):
		_clock.set_speed_scale(time_scale)
	if is_instance_valid(_progress_tween):
		_progress_tween.set_speed_scale(time_scale)
	for tween in _active_tweens.duplicate():
		tween.set_speed_scale(time_scale)
	for timeline in _active_timelines.duplicate():
		timeline.time_scale = time_scale


func _emit_started() -> void:
	if _started_emitted:
		return
	_started_emitted = true
	_invoke(_on_start)
	started.emit(self)


func _emit_progress(progress: float) -> void:
	_position = progress * duration
	_invoke(_on_update, [progress])
	updated.emit(self, progress)


func _on_clock_finished() -> void:
	if _killed or _completed:
		return
	_clock_finished = true
	_finish_if_ready()


func _on_child_timeline_finished(timeline: Variant) -> void:
	_active_timelines.erase(timeline)
	_finish_if_ready()


func _finish_if_ready() -> void:
	if _clock_finished and _active_tweens.is_empty() and _active_timelines.is_empty():
		if _repeat_index < _repeat_count:
			_repeat_index += 1
			_reset_entry_runtime()
			_direction = _timeline_direction(_repeat_index)
			_position = 0.0
			_clock_finished = false
			_apply_direction_start()
			_start_cycle(0.0, _repeat_delay)
		else:
			_finish()


func _finish() -> void:
	_apply_final_state()
	active = false
	_paused = false
	_completed = true
	_clock_finished = true
	_position = duration
	_invoke(_on_complete)
	updated.emit(self, 1.0)
	completed.emit(self)


func _apply_final_state() -> void:
	for entry in _entries:
		if entry["type"] == &"timeline":
			entry["timeline"]._apply_final_state()
			continue
		if entry["type"] != &"tween":
			continue
		var targets := _normalize_targets(entry["target"])
		var values_list: Array = entry["initial_values"] if _direction < 0 else entry["end_values"]
		var repeat_count := maxi(int(_option_value(entry["properties"], &"repeat", 0)), 0)
		if _direction > 0 and bool(_option_value(entry["properties"], &"yoyo", false)) and repeat_count % 2 == 1:
			values_list = entry["initial_values"]
		for index in targets.size():
			var target = targets[index]
			if target != null and is_instance_valid(target) and index < values_list.size():
				_apply_values(target, values_list[index])


func _on_child_finished(tween: Variant) -> void:
	_active_tweens.erase(tween)
	_finish_if_ready()


func _stop_runtime(emit_callbacks: bool = false) -> void:
	if is_instance_valid(_clock):
		_clock.kill()
	if is_instance_valid(_progress_tween):
		_progress_tween.kill()
	_clock = null
	_progress_tween = null
	_clock_finished = false
	for tween in _active_tweens.duplicate():
		tween.kill(emit_callbacks)
	_active_tweens.clear()
	for timeline in _active_timelines.duplicate():
		timeline.kill(emit_callbacks)
	_active_timelines.clear()
	active = false


func _restart_internal(direction: int) -> void:
	_stop_runtime()
	_reset_entry_runtime()
	_direction = direction
	_repeat_index = 0
	_completed = false
	_killed = false
	_paused = false
	_started_emitted = false
	_position = 0.0
	_apply_direction_start()
	play()


func _reset_entry_runtime() -> void:
	for entry in _entries:
		entry["started"] = false
		entry["handles"] = []
		if entry["type"] == &"timeline":
			entry["timeline"]._reset_entry_runtime()


func _apply_direction_start() -> void:
	for entry in _entries:
		if entry["type"] == &"timeline":
			entry["timeline"]._apply_direction_start()
			continue
		if entry["type"] != &"tween":
			continue
		var targets := _normalize_targets(entry["target"])
		var values_key := "initial_values" if _direction > 0 else "end_values"
		var values_list: Array = entry[values_key]
		for index in targets.size():
			var target = targets[index]
			if target != null and is_instance_valid(target) and index < values_list.size():
				_apply_values(target, values_list[index])


func _on_owner_tree_exiting() -> void:
	kill(false)


func _start_autoplay() -> void:
	_autoplay_scheduled = false
	if not _entries.is_empty() and not active and not _completed and not _killed:
		play()


func _timeline_repeat_count() -> int:
	var value = _options.get(&"repeat", _options.get("repeat", null))
	if value == null:
		value = _options.get(&"loop", _options.get("loop", null))
		if value != null:
			value = maxi(int(value) - 1, 0)
	return maxi(int(value if value != null else 0), 0)


func _timeline_direction(cycle_index: int) -> int:
	var direction_name := StringName(_options.get(&"direction", _options.get("direction", &"normal")))
	var direction := -1 if direction_name == &"reverse" or direction_name == &"alternate_reverse" else 1
	if direction_name == &"alternate" or direction_name == &"alternate_reverse" or bool(_options.get(&"yoyo", _options.get("yoyo", false))):
		if cycle_index % 2 == 1:
			direction *= -1
	return direction


func _invoke(callback: Variant, arguments: Array = []) -> void:
	if callback is Callable and callback.is_valid():
		callback.callv(arguments)