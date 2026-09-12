class_name AnimeTween
extends RefCounted

const EASING_SCRIPT = preload("res://addons/animegodot/runtime/anime_easing.gd")
const PROPERTY_SCRIPT = preload("res://addons/animegodot/runtime/anime_property.gd")
const REGISTRY_SCRIPT = preload("res://addons/animegodot/runtime/anime_registry.gd")

signal started(tween)
signal updated(tween, progress: float)
signal completed(tween)
signal killed(tween)

const DEFAULT_OVERWRITE := &"auto"
const RESERVED_OPTIONS := [
	&"duration",
	&"delay",
	&"ease",
	&"repeat",
	&"yoyo",
	&"stagger",
	&"overwrite",
	&"speed_scale",
	&"on_start",
	&"on_update",
	&"on_complete",
	&"on_kill",
]

var duration: float = 0.0
var active: bool = false

var _native_tweens: Dictionary = {}
var _update_tween: Tween
var _track_count := 0
var _target_ref: WeakRef
var _mode: StringName = &"to"
var _options: Dictionary = {}
var _start_values: Dictionary = {}
var _end_values: Dictionary = {}
var _on_start: Variant
var _on_update: Variant
var _on_complete: Variant
var _on_kill: Variant
var _started := false
var _completed := false
var _killed := false


static func create(target: Object, properties: Dictionary, mode: StringName = &"to"):
	var instance := AnimeTween.new()
	instance._configure(target, properties, mode)
	return instance


func _configure(target: Object, properties: Dictionary, mode: StringName) -> void:
	_target_ref = weakref(target)
	_mode = mode
	for property_key in properties:
		_options[StringName(property_key)] = properties[property_key]
	duration = maxf(float(_options.get(&"duration", 0.0)), 0.0)
	_on_start = _options.get(&"on_start")
	_on_update = _options.get(&"on_update")
	_on_complete = _options.get(&"on_complete")
	_on_kill = _options.get(&"on_kill")

	for property_key in properties:
		var property_path := StringName(property_key)
		if property_path in RESERVED_OPTIONS:
			continue
		if not PROPERTY_SCRIPT.exists(target, property_path):
			push_warning("AnimeGodot cannot animate missing property '%s'." % property_path)
			continue

		var current_value := PROPERTY_SCRIPT.read(target, property_path)
		if mode == &"from":
			_start_values[property_path] = properties[property_key]
			_end_values[property_path] = current_value
		else:
			_start_values[property_path] = current_value
			_end_values[property_path] = properties[property_key]


func play():
	if active or _completed or _killed:
		return self

	var target := _get_target()
	if target == null:
		kill(false)
		return self

	if _mode == &"from":
		_apply_values(_start_values)

	active = true
	_connect_target_lifecycle(target)
	_register_with_registry(target)

	if _mode == &"set" or duration <= 0.0 or _end_values.is_empty():
		_emit_started()
		_apply_values(_end_values)
		_emit_update(1.0)
		_finish()
		return self

	var delay := maxf(float(_options.get(&"delay", 0.0)), 0.0)
	var repeat_count := maxi(int(_options.get(&"repeat", 0)), 0)
	var should_yoyo := bool(_options.get(&"yoyo", false))
	var first_track := true
	for property_path in _end_values:
		var native_tween := _create_native_tween(target)
		if native_tween == null:
			kill(false)
			return self
		_native_tweens[property_path] = native_tween
		_track_count += 1
		if delay > 0.0:
			native_tween.tween_interval(delay)
		if first_track:
			native_tween.tween_callback(Callable(self, "_emit_started"))
		first_track = false
		for cycle_index in range(repeat_count + 1):
			if cycle_index > 0 and not should_yoyo:
				native_tween.tween_callback(Callable(self, "_reset_property").bind(property_path))
			native_tween.set_parallel(true)
			var reversed_cycle := should_yoyo and cycle_index % 2 == 1
			var cycle_value: Variant = _start_values[property_path] if reversed_cycle else _end_values[property_path]
			var property_tweener = native_tween.tween_property(
				target,
				NodePath(property_path),
				cycle_value,
				duration
			)
			_configure_tweener(property_tweener)
			native_tween.set_parallel(false)
		native_tween.finished.connect(_on_property_finished.bind(property_path))

	if _on_update is Callable and _on_update.is_valid():
		_update_tween = _create_native_tween(target)
		if delay > 0.0:
			_update_tween.tween_interval(delay)
		for cycle_index in range(repeat_count + 1):
			var update_tweener = _update_tween.tween_method(
				Callable(self, "_emit_update"),
				0.0,
				1.0,
				duration
			)
			_configure_tweener(update_tweener)
		_track_count += 1
		_update_tween.finished.connect(_on_update_finished)

	_apply_speed_scale()
	return self


func pause():
	if not active:
		return self
	for native_tween in _native_tweens.values():
		native_tween.pause()
	if is_instance_valid(_update_tween):
		_update_tween.pause()
	return self


func resume():
	if not active:
		return self
	for native_tween in _native_tweens.values():
		native_tween.play()
	if is_instance_valid(_update_tween):
		_update_tween.play()
	return self


func set_speed_scale(scale: float):
	for native_tween in _native_tweens.values():
		native_tween.set_speed_scale(scale)
	if is_instance_valid(_update_tween):
		_update_tween.set_speed_scale(scale)
	return self


func kill(emit_callback: bool = true) -> void:
	if _killed or _completed:
		return
	_killed = true
	active = false
	for native_tween in _native_tweens.values():
		native_tween.kill()
	_native_tweens.clear()
	if is_instance_valid(_update_tween):
		_update_tween.kill()
	_update_tween = null
	_track_count = 0
	if emit_callback:
		_invoke(_on_kill)
	killed.emit(self)


func kill_properties(property_paths: Array) -> void:
	if _killed or _completed:
		return
	for property_path in property_paths:
		var normalized_path := StringName(property_path)
		if not _native_tweens.has(normalized_path):
			continue
		_native_tweens[normalized_path].kill()
		_native_tweens.erase(normalized_path)
		_track_count -= 1

	if _native_tweens.is_empty() and is_instance_valid(_update_tween):
		_update_tween.kill()
		_update_tween = null
		_track_count -= 1
	if _track_count <= 0:
		_killed = true
		active = false
		killed.emit(self)


func is_finished() -> bool:
	return _completed or _killed


func get_target() -> Object:
	return _get_target()


func get_property_paths() -> Array:
	return _end_values.keys()


func get_active_property_paths() -> Array:
	return _native_tweens.keys()


func _create_native_tween(target: Object) -> Tween:
	if target is Node and target.is_inside_tree():
		return target.create_tween()
	var main_loop := Engine.get_main_loop()
	if main_loop is SceneTree:
		return main_loop.create_tween()
	return null


func _connect_target_lifecycle(target: Object) -> void:
	if target is Node and not target.tree_exiting.is_connected(_on_target_tree_exiting):
		target.tree_exiting.connect(_on_target_tree_exiting, CONNECT_ONE_SHOT)


func _register_with_registry(target: Object) -> void:
	var registry = REGISTRY_SCRIPT.get_instance()
	if registry == null:
		return
	registry.register(
		self,
		target,
		get_property_paths(),
		_options.get(&"overwrite", DEFAULT_OVERWRITE)
	)


func _get_target() -> Object:
	if _target_ref == null:
		return null
	var target = _target_ref.get_ref()
	if target == null or not is_instance_valid(target):
		return null
	return target


func _configure_tweener(tweener: Variant) -> void:
	var easing := EASING_SCRIPT.resolve(_options.get(&"ease", &"out_quad"))
	tweener.set_trans(easing["transition"])
	tweener.set_ease(easing["ease"])


func _apply_speed_scale() -> void:
	var speed_scale := float(_options.get(&"speed_scale", 1.0))
	set_speed_scale(speed_scale)


func _reset_property(property_path: StringName) -> void:
	var target := _get_target()
	if target != null:
		PROPERTY_SCRIPT.write(target, property_path, _start_values[property_path])


func _apply_values(values: Dictionary) -> void:
	var target := _get_target()
	if target == null:
		return
	for property_path in values:
		PROPERTY_SCRIPT.write(target, property_path, values[property_path])


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


func _on_property_finished(property_path: StringName) -> void:
	if not _native_tweens.has(property_path):
		return
	_native_tweens.erase(property_path)
	_track_finished()


func _on_update_finished() -> void:
	if not is_instance_valid(_update_tween):
		return
	_update_tween = null
	_track_finished()


func _track_finished() -> void:
	_track_count -= 1
	if _track_count <= 0:
		_finish()


func _finish() -> void:
	if _completed or _killed:
		return
	active = false
	_completed = true
	_invoke(_on_complete)
	completed.emit(self)


func _on_target_tree_exiting() -> void:
	if not _completed:
		kill(false)


func _invoke(callback: Variant, arguments: Array = []) -> void:
	if callback is Callable and callback.is_valid():
		callback.callv(arguments)
