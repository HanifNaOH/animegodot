class_name AnimeMotionPathTween
extends RefCounted

const EASING_SCRIPT = preload("res://addons/animegodot/runtime/anime_easing.gd")
const PROPERTY_SCRIPT = preload("res://addons/animegodot/runtime/anime_property.gd")
const REGISTRY_SCRIPT = preload("res://addons/animegodot/runtime/anime_registry.gd")

signal started(tween)
signal updated(tween, progress: float)
signal completed(tween)
signal killed(tween)

const RESERVED_OPTIONS := [
	&"duration",
	&"delay",
	&"ease",
	&"repeat",
	&"yoyo",
	&"start_progress",
	&"end_progress",
	&"align_to_path",
	&"auto_rotate",
	&"overwrite",
	&"speed_scale",
	&"on_start",
	&"on_update",
	&"on_complete",
	&"on_kill",
]

var duration: float = 0.0
var active := false

var _native_tween: Tween
var _target_ref: WeakRef
var _curve: Curve2D
var _options: Dictionary = {}
var _property_paths: Array = [&"position"]
var _on_start: Variant
var _on_update: Variant
var _on_complete: Variant
var _on_kill: Variant
var _started := false
var _completed := false
var _killed := false


static func create(target: Object, path: Variant, options: Dictionary):
	var instance := AnimeMotionPathTween.new()
	instance._configure(target, path, options)
	return instance


func _configure(target: Object, path: Variant, options: Dictionary) -> void:
	_target_ref = weakref(target)
	_curve = _resolve_curve(path)
	for option_key in options:
		_options[StringName(option_key)] = options[option_key]
	duration = maxf(float(_options.get(&"duration", 0.0)), 0.0)
	_on_start = _options.get(&"on_start")
	_on_update = _options.get(&"on_update")
	_on_complete = _options.get(&"on_complete")
	_on_kill = _options.get(&"on_kill")
	if bool(_options.get(&"align_to_path", false)) or bool(_options.get(&"auto_rotate", false)):
		_property_paths.append(&"rotation")


func play():
	if active or _completed or _killed:
		return self
	var target := _get_target()
	if target == null or _curve == null:
		kill(false)
		return self

	active = true
	_connect_target_lifecycle(target)
	var registry = REGISTRY_SCRIPT.get_instance()
	if registry != null:
		registry.register(self, target, _property_paths, _options.get(&"overwrite", &"auto"))

	if duration <= 0.0:
		_emit_started()
		_apply_progress(1.0)
		_finish()
		return self

	_native_tween = _create_native_tween(target)
	if _native_tween == null:
		kill(false)
		return self

	var delay := maxf(float(_options.get(&"delay", 0.0)), 0.0)
	if delay > 0.0:
		_native_tween.tween_interval(delay)
	_native_tween.tween_callback(Callable(self, "_emit_started"))
	var repeat_count := maxi(int(_options.get(&"repeat", 0)), 0)
	var should_yoyo := bool(_options.get(&"yoyo", false))
	for cycle_index in range(repeat_count + 1):
		if cycle_index == 0 and delay <= 0.0:
			_native_tween.tween_callback(Callable(self, "_emit_started"))
		elif cycle_index > 0 and not should_yoyo:
			_native_tween.tween_callback(Callable(self, "_apply_progress").bind(0.0))
		var cycle_end := 0.0 if should_yoyo and cycle_index % 2 == 1 else 1.0
		var path_tweener = _native_tween.tween_method(
			Callable(self, "_apply_progress"),
			1.0 - cycle_end,
			cycle_end,
			duration
		)
		var easing := EASING_SCRIPT.resolve(_options.get(&"ease", &"out_quad"))
		path_tweener.set_trans(easing["transition"])
		path_tweener.set_ease(easing["ease"])
	_native_tween.finished.connect(_on_native_finished)
	_native_tween.set_speed_scale(float(_options.get(&"speed_scale", 1.0)))
	return self


func pause():
	if active and is_instance_valid(_native_tween):
		_native_tween.pause()
	return self


func resume():
	if active and is_instance_valid(_native_tween):
		_native_tween.play()
	return self


func set_speed_scale(scale: float):
	if is_instance_valid(_native_tween):
		_native_tween.set_speed_scale(scale)
	return self


func kill(emit_callback: bool = true) -> void:
	if _killed or _completed:
		return
	_killed = true
	active = false
	if is_instance_valid(_native_tween):
		_native_tween.kill()
	_native_tween = null
	if emit_callback:
		_invoke(_on_kill)
	killed.emit(self)


func kill_properties(property_paths: Array) -> void:
	for property_path in property_paths:
		if StringName(property_path) in _property_paths:
			kill(false)
			return


func is_finished() -> bool:
	return _completed or _killed


func get_target() -> Object:
	return _get_target()


func get_property_paths() -> Array:
	return _property_paths.duplicate()


func get_active_property_paths() -> Array:
	return [] if is_finished() else _property_paths.duplicate()


func _resolve_curve(path: Variant) -> Curve2D:
	if path is Curve2D:
		return path
	if path is Path2D:
		return path.curve
	return null


func _create_native_tween(target: Object) -> Tween:
	if target is Node:
		return target.create_tween()
	var main_loop := Engine.get_main_loop()
	if main_loop is SceneTree:
		return main_loop.create_tween()
	return null


func _get_target() -> Object:
	if _target_ref == null:
		return null
	var target = _target_ref.get_ref()
	if target == null or not is_instance_valid(target):
		return null
	return target


func _connect_target_lifecycle(target: Object) -> void:
	if target is Node and not target.tree_exiting.is_connected(_on_target_tree_exiting):
		target.tree_exiting.connect(_on_target_tree_exiting, CONNECT_ONE_SHOT)


func _apply_progress(progress: float) -> void:
	if _curve == null:
		return
	var target := _get_target()
	if target == null:
		return
	var start_progress := clampf(float(_options.get(&"start_progress", 0.0)), 0.0, 1.0)
	var end_progress := clampf(float(_options.get(&"end_progress", 1.0)), 0.0, 1.0)
	var path_progress := lerpf(start_progress, end_progress, progress)
	var length := _curve.get_baked_length()
	var distance := length * path_progress
	var position := _curve.sample_baked(distance)
	if PROPERTY_SCRIPT.exists(target, &"position"):
		PROPERTY_SCRIPT.write(target, &"position", position)
	if _property_paths.has(&"rotation") and PROPERTY_SCRIPT.exists(target, &"rotation"):
		var next_distance := minf(distance + 0.1, length)
		var next_position := _curve.sample_baked(next_distance)
		if position.distance_to(next_position) > 0.001:
			PROPERTY_SCRIPT.write(target, &"rotation", position.angle_to_point(next_position))
	_invoke(_on_update, [progress])
	updated.emit(self, progress)


func _emit_started() -> void:
	if _started or _killed:
		return
	_started = true
	_invoke(_on_start)
	started.emit(self)


func _on_native_finished() -> void:
	if _killed or _completed:
		return
	_finish()


func _finish() -> void:
	active = false
	_completed = true
	_apply_progress(1.0 if not bool(_options.get(&"yoyo", false)) or int(_options.get(&"repeat", 0)) % 2 == 0 else 0.0)
	_invoke(_on_complete)
	completed.emit(self)


func _on_target_tree_exiting() -> void:
	kill(false)


func _invoke(callback: Variant, arguments: Array = []) -> void:
	if callback is Callable and callback.is_valid():
		callback.callv(arguments)
