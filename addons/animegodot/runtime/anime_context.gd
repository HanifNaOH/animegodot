class_name AnimeContext
extends RefCounted

const TWEEN_RUNTIME_SCRIPT = preload("res://addons/animegodot/runtime/anime_tween_runtime.gd")
const TIMELINE_RUNTIME_SCRIPT = preload("res://addons/animegodot/runtime/anime_timeline_runtime.gd")

signal disposed(context: AnimeContext)

var owner: Node

var _tweens: Array[AnimeTweenRuntime] = []
var _timelines: Array[AnimeTimelineRuntime] = []
var _disposed := false


func _init(context_owner: Node = null) -> void:
	owner = context_owner
	if is_instance_valid(owner):
		owner.tree_exiting.connect(_on_owner_tree_exiting, CONNECT_ONE_SHOT)


func tween(target: Object) -> AnimeTweenRuntime:
	return create_tween(target)


func to(target: Object) -> AnimeTweenRuntime:
	return create_tween(target)


func from(target: Object) -> AnimeTweenRuntime:
	return create_tween(target, AnimeTweenRuntime.Mode.FROM)


func from_to(target: Object) -> AnimeTweenRuntime:
	return create_tween(target, AnimeTweenRuntime.Mode.FROM_TO)


func set_value(target: Object) -> AnimeTweenRuntime:
	return create_tween(target, AnimeTweenRuntime.Mode.SET)


func create_tween(target: Object, mode: int = AnimeTweenRuntime.Mode.TO) -> AnimeTweenRuntime:
	if _disposed or not is_instance_valid(target):
		return null
	var created: AnimeTweenRuntime = TWEEN_RUNTIME_SCRIPT.new(target, mode)
	_tweens.append(created)
	created.completed.connect(_on_tween_finished)
	created.killed.connect(_on_tween_finished)
	return created


func timeline(options: AnimeOptions = null) -> AnimeTimelineRuntime:
	if _disposed:
		return null
	var created: AnimeTimelineRuntime = TIMELINE_RUNTIME_SCRIPT.new(owner, options)
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
	for timeline in _timelines.duplicate():
		if is_instance_valid(timeline):
			timeline.kill(false)
	_tweens.clear()
	_timelines.clear()
	disposed.emit(self)


func is_disposed() -> bool:
	return _disposed


func _on_tween_finished(tween: Variant) -> void:
	_tweens.erase(tween)


func _on_timeline_finished(timeline: Variant) -> void:
	_timelines.erase(timeline)


func _on_owner_tree_exiting() -> void:
	dispose()