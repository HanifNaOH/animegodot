class_name AnimeContext
extends RefCounted

const TWEEN_SCRIPT = preload("res://addons/animegodot/runtime/anime_tween.gd")
const TIMELINE_SCRIPT = preload("res://addons/animegodot/runtime/anime_timeline.gd")
const MOTION_PATH_SCRIPT = preload("res://addons/animegodot/runtime/anime_motion_path_tween.gd")
const STAGGER_SCRIPT = preload("res://addons/animegodot/runtime/anime_stagger.gd")

signal disposed(context)

var owner: Node

var _tweens: Array = []
var _motion_path_tweens: Array = []
var _timelines: Array = []
var _disposed := false


func _init(context_owner: Node = null) -> void:
	owner = context_owner
	if is_instance_valid(owner):
		owner.tree_exiting.connect(_on_owner_tree_exiting, CONNECT_ONE_SHOT)


func to(target: Variant, properties: Dictionary) -> Variant:
	return _create_batch(target, properties, &"to")


func from(target: Variant, properties: Dictionary) -> Variant:
	return _create_batch(target, properties, &"from")


func from_to(target: Variant, from_properties: Dictionary, to_properties: Dictionary) -> Variant:
	if _disposed:
		return [] if target is Array else null
	var targets := _normalize_targets(target)
	var created: Array = []
	for item in targets:
		if item == null or not is_instance_valid(item):
			continue
		var tween = TWEEN_SCRIPT.create_from_to(item, from_properties, to_properties)
		_tweens.append(tween)
		tween.completed.connect(_on_tween_finished)
		tween.killed.connect(_on_tween_finished)
		tween.play()
		created.append(tween)
	if target is Array:
		return created
	return created[0] if not created.is_empty() else null


func set_value(target: Variant, properties: Dictionary) -> Variant:
	return _create_batch(target, properties, &"set")


func motion_path(target: Object, path: Variant, options: Dictionary = {}):
	if _disposed:
		return null
	var created = MOTION_PATH_SCRIPT.create(target, path, options)
	_motion_path_tweens.append(created)
	created.completed.connect(_on_motion_path_finished)
	created.killed.connect(_on_motion_path_finished)
	created.play()
	return created


func timeline(options: Dictionary = {}):
	if _disposed:
		return null
	var created = TIMELINE_SCRIPT.new(owner, options)
	_timelines.append(created)
	created.completed.connect(_on_timeline_finished)
	created.killed.connect(_on_timeline_finished)
	return created


func dispose() -> void:
	if _disposed:
		return
	_disposed = true
	for tween in _tweens.duplicate():
		if is_instance_valid(tween):
			tween.kill(false)
	for motion_path_tween in _motion_path_tweens.duplicate():
		if is_instance_valid(motion_path_tween):
			motion_path_tween.kill(false)
	for timeline in _timelines.duplicate():
		if is_instance_valid(timeline):
			timeline.kill(false)
	_tweens.clear()
	_motion_path_tweens.clear()
	_timelines.clear()
	disposed.emit(self)


func is_disposed() -> bool:
	return _disposed


func _create_batch(targets_value: Variant, properties: Dictionary, mode: StringName) -> Variant:
	if _disposed:
		return [] if targets_value is Array else null

	var targets := _normalize_targets(targets_value)
	var created: Array = []
	var base_delay := maxf(float(_option_value(properties, &"delay", 0.0)), 0.0)
	for index in targets.size():
		var target = targets[index]
		if target == null or not is_instance_valid(target):
			continue
		var target_properties := properties.duplicate(true)
		var stagger_delay := STAGGER_SCRIPT.delay_for(index, targets.size(), _option_value(properties, &"stagger", 0.0))
		if base_delay > 0.0 or stagger_delay > 0.0:
			target_properties[&"delay"] = base_delay + stagger_delay
		var tween = TWEEN_SCRIPT.create(target, target_properties, mode)
		_tweens.append(tween)
		tween.completed.connect(_on_tween_finished)
		tween.killed.connect(_on_tween_finished)
		tween.play()
		created.append(tween)

	if targets_value is Array:
		return created
	return created[0] if not created.is_empty() else null


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


func _on_tween_finished(tween: Variant) -> void:
	_tweens.erase(tween)


func _on_motion_path_finished(tween: Variant) -> void:
	_motion_path_tweens.erase(tween)


func _on_timeline_finished(timeline: Variant) -> void:
	_timelines.erase(timeline)


func _on_owner_tree_exiting() -> void:
	dispose()