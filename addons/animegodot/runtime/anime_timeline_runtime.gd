class_name AnimeTimelineRuntime
extends RefCounted

signal started(timeline: AnimeTimelineRuntime)
signal updated(timeline: AnimeTimelineRuntime, progress: float)
signal completed(timeline: AnimeTimelineRuntime)
signal killed(timeline: AnimeTimelineRuntime)

enum EntryKind {
	TWEEN,
	TIMELINE,
	CALLBACK,
}

class Entry:
	var kind: int
	var tween: Variant
	var timeline: Variant
	var callback: Callable
	var arguments: Array = []
	var start_time: float = 0.0
	var duration: float = 0.0
	var started := false
	var finished := false
	var called := false

var owner: Node
var options: AnimeOptions = AnimeOptions.new()
var defaults: AnimeOptions = AnimeOptions.new()
var duration: float = 0.0
var active := false
var time_scale: float = 1.0:
	set(value):
		time_scale = maxf(value, 0.0)
		_apply_time_scale()

var _entries: Array[Entry] = []
var _cursor := 0.0
var _last_start := 0.0
var _last_end := 0.0
var _position := 0.0
var _last_position := 0.0
var _cycle_direction := 1
var _play_direction := 1
var _driver: Tween
var _started := false
var _completed := false
var _killed := false
var _paused := false
var _autoplay_scheduled := false


func _init(timeline_owner: Node = null, timeline_options: AnimeOptions = null) -> void:
	owner = timeline_owner
	if timeline_options != null:
		options = timeline_options
	if is_instance_valid(owner):
		owner.tree_exiting.connect(_on_owner_tree_exiting, CONNECT_ONE_SHOT)


func add(item: Variant, position: AnimePosition = null) -> AnimeTimelineRuntime:
	if item is AnimeTweenRuntime:
		_add_tween(item, position)
	elif item is AnimeTimelineRuntime:
		_add_timeline(item, position)
	else:
		push_warning("AnimeGodot timeline can only add typed tween or timeline objects.")
	return self


func add_tween(tween: AnimeTweenRuntime, position: AnimePosition = null) -> AnimeTimelineRuntime:
	_add_tween(tween, position)
	return self


func add_timeline(timeline: AnimeTimelineRuntime, position: AnimePosition = null) -> AnimeTimelineRuntime:
	_add_timeline(timeline, position)
	return self


func parallel(tween: AnimeTweenRuntime) -> AnimeTimelineRuntime:
	return add(tween, AnimePosition.with_previous_start())


func invoke(callback: Callable, position: AnimePosition = null, arguments: Array = []) -> AnimeTimelineRuntime:
	if not callback.is_valid():
		push_warning("AnimeGodot timeline callback must be a valid Callable.")
		return self
	var entry := Entry.new()
	entry.kind = EntryKind.CALLBACK
	entry.callback = callback
	entry.arguments = arguments.duplicate()
	return _add_entry(entry, position)


func add_label(position: AnimePosition = null) -> AnimeLabel:
	var label_time := _resolve_position(position)
	if label_time < 0.0:
		return null
	return AnimeLabel.new(self, label_time)


func play() -> AnimeTimelineRuntime:
	if active or _completed or _killed or not options.is_valid():
		return self
	if not _prepare_entries():
		kill(false)
		return self
	active = true
	_paused = false
	if not _started:
		_started = true
		_invoke(options.on_start)
		started.emit(self)
	if is_zero_approx(duration):
		_begin_cycle(0.0, 0.0)
		_apply_at(0.0, true)
		_emit_update(1.0)
		_finish()
		return self
	_start_driver()
	return self


func pause() -> AnimeTimelineRuntime:
	if not active:
		return self
	_paused = true
	if is_instance_valid(_driver):
		_driver.pause()
	return self


func resume() -> AnimeTimelineRuntime:
	if active and is_instance_valid(_driver):
		_paused = false
		_driver.play()
	elif _paused:
		_paused = false
		_completed = false
		_start_driver(true)
	return self


func restart() -> AnimeTimelineRuntime:
	_stop_driver()
	_position = 0.0
	_play_direction = 1
	_started = false
	_completed = false
	_killed = false
	_paused = false
	_reset_entries()
	return play()


func reverse() -> AnimeTimelineRuntime:
	var was_completed := _completed
	_stop_driver()
	_play_direction *= -1
	_completed = false
	_killed = false
	_paused = false
	if was_completed:
		_reset_entries()
	if is_zero_approx(_position):
		_position = duration
		_apply_at(_position, false)
	return play()


func seek(position: float) -> AnimeTimelineRuntime:
	if not _prepare_entries():
		return self
	_stop_driver()
	_completed = false
	_killed = false
	active = false
	_paused = true
	_position = clampf(position, 0.0, duration)
	_last_position = _position
	_apply_at(_position, false)
	_emit_update(get_progress())
	return self


func kill(emit_callback: bool = true) -> void:
	if _killed or _completed:
		return
	_stop_driver()
	_killed = true
	active = false
	_paused = false
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


func sample_at(position: float, fire_events: bool = false) -> void:
	if not _prepare_entries():
		return
	_position = clampf(position, 0.0, duration)
	_apply_at(_position, fire_events)
	_emit_update(get_progress())


func _add_tween(tween: AnimeTweenRuntime, position: AnimePosition) -> void:
	if tween == null or tween.active or not is_instance_valid(tween.target):
		push_warning("AnimeGodot timeline rejected an invalid or active tween.")
		return
	tween.refresh_duration()
	_apply_defaults(tween)
	var entry := Entry.new()
	entry.kind = EntryKind.TWEEN
	entry.tween = tween
	entry.duration = tween.duration
	_add_entry(entry, position)


func _add_timeline(timeline: AnimeTimelineRuntime, position: AnimePosition) -> void:
	if timeline == null or timeline == self or timeline.active:
		push_warning("AnimeGodot timeline rejected an invalid, active, or recursive child timeline.")
		return
	var entry := Entry.new()
	entry.kind = EntryKind.TIMELINE
	entry.timeline = timeline
	entry.duration = timeline.duration
	_add_entry(entry, position)


func _add_entry(entry: Entry, position: AnimePosition) -> AnimeTimelineRuntime:
	var start_time := _resolve_position(position)
	if start_time < 0.0:
		return self
	entry.start_time = start_time
	_entries.append(entry)
	_last_start = start_time
	_last_end = start_time + entry.duration
	_cursor = maxf(_cursor, _last_end)
	duration = _cursor
	if options.autoplay and not _autoplay_scheduled and not active:
		_autoplay_scheduled = true
		call_deferred("_start_autoplay")
	return self


func _resolve_position(position: AnimePosition) -> float:
	if position == null or position.kind == AnimePosition.Kind.CURSOR:
		return _cursor
	if not position.is_valid_for(self):
		push_warning("AnimeGodot timeline rejected an invalid or foreign position token.")
		return -1.0
	match position.kind:
		AnimePosition.Kind.ABSOLUTE:
			return position.time
		AnimePosition.Kind.PREVIOUS_START:
			return maxf(_last_start + position.offset, 0.0)
		AnimePosition.Kind.PREVIOUS_END:
			return maxf(_last_end + position.offset, 0.0)
		AnimePosition.Kind.LABEL:
			return maxf(position.label.time + position.offset, 0.0)
	return _cursor


func _apply_defaults(tween: AnimeTweenRuntime) -> void:
	if tween.options.duration == 0.0 and defaults.duration > 0.0:
		tween.options.duration = defaults.duration
	if tween.options.ease == AnimeEase.OUT_QUAD and defaults.ease != AnimeEase.OUT_QUAD:
		tween.options.ease = defaults.ease
	if tween.options.repeat_count == 0 and defaults.repeat_count > 0:
		tween.options.repeat_count = defaults.repeat_count
	if not tween.options.yoyo and defaults.yoyo:
		tween.options.yoyo = true


func _prepare_entries() -> bool:
	for entry in _entries:
		if entry.kind == EntryKind.TWEEN and not entry.tween.prepare_for_timeline():
			return false
		if entry.kind == EntryKind.TIMELINE and not entry.timeline._prepare_entries():
			return false
	return true


func _start_driver(resume_from_position: bool = false) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if is_instance_valid(owner) and owner.is_inside_tree():
		_driver = owner.create_tween()
	elif tree != null:
		_driver = tree.create_tween()
	if _driver == null:
		kill(false)
		return
	_driver.set_ignore_time_scale(options.ignore_time_scale)
	_driver.set_process_mode(options.process_mode)
	_apply_time_scale()
	if options.delay > 0.0 and not resume_from_position:
		_driver.tween_interval(options.delay)
	if resume_from_position and _position > 0.0 and _position < duration:
		var endpoint := duration if _play_direction > 0 else 0.0
		_begin_cycle(_position, endpoint)
		_driver.tween_method(Callable(self, "_on_driver_position"), _position, endpoint, absf(endpoint - _position))
	else:
		for cycle_index in range(options.repeat_count + 1):
			if cycle_index > 0:
				if options.repeat_delay > 0.0:
					_driver.tween_interval(options.repeat_delay)
				_driver.tween_callback(Callable(self, "_reset_entries"))
			var reverse_cycle := options.direction == AnimeOptions.Direction.REVERSE
			if (options.direction == AnimeOptions.Direction.ALTERNATE or options.yoyo) and cycle_index % 2 == 1:
				reverse_cycle = not reverse_cycle
			if _play_direction < 0:
				reverse_cycle = not reverse_cycle
			var cycle_start := duration if reverse_cycle else 0.0
			var cycle_end := 0.0 if reverse_cycle else duration
			_driver.tween_callback(Callable(self, "_begin_cycle").bind(cycle_start, cycle_end))
			_driver.tween_method(Callable(self, "_on_driver_position"), cycle_start, cycle_end, duration)
	_driver.finished.connect(_on_driver_finished)


func _begin_cycle(start_time: float, end_time: float) -> void:
	_cycle_direction = 1 if end_time >= start_time else -1
	_position = start_time
	_last_position = start_time - float(_cycle_direction) * 0.000001
	_apply_at(start_time, true)


func _on_driver_position(position: float) -> void:
	if _killed:
		return
	_position = position
	_apply_at(position, true)
	_emit_update(get_progress())


func _apply_at(position: float, fire_events: bool) -> void:
	for entry in _entries:
		var entry_end := entry.start_time + entry.duration
		match entry.kind:
			EntryKind.TWEEN:
				var enters := _crosses(entry.start_time, entry_end, position)
				if fire_events and enters and not entry.started:
					entry.started = true
					entry.tween.begin_from_timeline(entry.duration if _cycle_direction < 0 else 0.0)
				var local_time := clampf(position - entry.start_time, 0.0, entry.duration)
				var should_sample := (_cycle_direction > 0 and position >= entry.start_time) or (_cycle_direction < 0 and position <= entry_end)
				if should_sample and not entry.finished:
					entry.tween.sample_at(local_time, true, true)
				var exits := position >= entry_end if _cycle_direction > 0 else position <= entry.start_time
				if fire_events and exits and entry.started and not entry.finished:
					entry.finished = true
					entry.tween.finish_from_timeline(entry.duration if _cycle_direction > 0 else 0.0)
			EntryKind.TIMELINE:
				var enters_child := _crosses(entry.start_time, entry_end, position)
				if fire_events and enters_child and not entry.started:
					entry.started = true
					entry.timeline._begin_from_parent(entry.duration if _cycle_direction < 0 else 0.0)
				var child_local := clampf(position - entry.start_time, 0.0, entry.duration)
				var should_sample_child := (_cycle_direction > 0 and position >= entry.start_time) or (_cycle_direction < 0 and position <= entry_end)
				if should_sample_child and not entry.finished:
					entry.timeline.sample_at(child_local, fire_events)
				var exits_child := position >= entry_end if _cycle_direction > 0 else position <= entry.start_time
				if fire_events and exits_child and entry.started and not entry.finished:
					entry.finished = true
					entry.timeline._finish_from_parent(entry.duration if _cycle_direction > 0 else 0.0)
			EntryKind.CALLBACK:
				var crossed := position >= entry.start_time if _cycle_direction > 0 else position <= entry.start_time
				var previously_before := _last_position < entry.start_time if _cycle_direction > 0 else _last_position > entry.start_time
				if fire_events and crossed and previously_before and not entry.called:
					entry.called = true
					entry.callback.callv(entry.arguments)
	_last_position = position


func _crosses(start_time: float, end_time: float, position: float) -> bool:
	if _cycle_direction > 0:
		return _last_position < start_time and position >= start_time
	return _last_position > end_time and position <= end_time


func _reset_entries() -> void:
	for entry in _entries:
		entry.started = false
		entry.finished = false
		entry.called = false
		if entry.kind == EntryKind.TWEEN:
			entry.tween.reset_for_timeline()
		elif entry.kind == EntryKind.TIMELINE:
			entry.timeline._reset_entries()


func _begin_from_parent(start_position: float) -> void:
	if not _started:
		_started = true
		_invoke(options.on_start)
		started.emit(self)
	_position = start_position


func _finish_from_parent(end_position: float) -> void:
	sample_at(end_position, false)
	_finish()


func _create_driver() -> Tween:
	if is_instance_valid(owner) and owner.is_inside_tree():
		return owner.create_tween()
	var tree := Engine.get_main_loop() as SceneTree
	return tree.create_tween() if tree != null else null


func _apply_time_scale() -> void:
	if is_instance_valid(_driver):
		_driver.set_speed_scale(options.speed_scale * time_scale)


func _on_driver_finished() -> void:
	if _killed or _completed:
		return
	_finish()


func _finish() -> void:
	if _completed or _killed:
		return
	_stop_driver()
	active = false
	_paused = false
	_completed = true
	_invoke(options.on_complete)
	completed.emit(self)


func _stop_driver() -> void:
	if is_instance_valid(_driver):
		_driver.kill()
	_driver = null
	active = false


func _emit_update(progress: float) -> void:
	_invoke(options.on_update, [progress])
	updated.emit(self, progress)


func _invoke(callback: Callable, arguments: Array = []) -> void:
	if callback.is_valid():
		callback.callv(arguments)


func _start_autoplay() -> void:
	_autoplay_scheduled = false
	play()


func _on_owner_tree_exiting() -> void:
	if not _completed:
		kill(false)