class_name AnimeRegistryRuntime
extends RefCounted

const METADATA_KEY: StringName = &"animegodot_v2_registry"

class Record:
	var tween_ref: WeakRef
	var target_ref: WeakRef

var _records: Array[Record] = []


static func get_instance() -> AnimeRegistryRuntime:
	var main_loop := Engine.get_main_loop()
	if not main_loop is SceneTree or main_loop.root == null:
		return null
	var root: Node = main_loop.root
	if root.has_meta(METADATA_KEY):
		var existing = root.get_meta(METADATA_KEY)
		if existing is AnimeRegistryRuntime and is_instance_valid(existing):
			return existing
	var created := AnimeRegistryRuntime.new()
	root.set_meta(METADATA_KEY, created)
	return created


func register(tween: AnimeTweenRuntime, target: Object, overwrite: int) -> void:
	if not is_instance_valid(tween) or not is_instance_valid(target) or not AnimeOverwrite.is_valid(overwrite):
		return
	_cleanup()
	for record in _records.duplicate():
		var existing_tween = record.tween_ref.get_ref()
		if existing_tween == null or not is_instance_valid(existing_tween) or _target_for(record) != target:
			continue
		if overwrite == AnimeOverwrite.ALL:
			existing_tween.kill_properties(existing_tween.get_active_property_keys())
		elif overwrite == AnimeOverwrite.AUTO:
			var overlapping := _intersection(existing_tween.get_active_property_keys(), tween.get_property_keys())
			if not overlapping.is_empty():
				existing_tween.kill_properties(overlapping)
	_cleanup()
	var record := Record.new()
	record.tween_ref = weakref(tween)
	record.target_ref = weakref(target)
	_records.append(record)
	if not tween.completed.is_connected(_on_tween_finished):
		tween.completed.connect(_on_tween_finished)
	if not tween.killed.is_connected(_on_tween_finished):
		tween.killed.connect(_on_tween_finished)


func get_active_records() -> Array:
	_cleanup()
	var active_records: Array = []
	for record in _records:
		var tween = record.tween_ref.get_ref()
		var target := _target_for(record)
		if tween == null or not is_instance_valid(tween) or target == null:
			continue
		active_records.append({"target": target, "tween": tween, "properties": tween.get_active_property_keys()})
	return active_records


func _intersection(left: Array[AnimePropertyKey], right: Array[AnimePropertyKey]) -> Array[AnimePropertyKey]:
	var result: Array[AnimePropertyKey] = []
	for left_key in left:
		for right_key in right:
			if left_key.same_as(right_key):
				result.append(left_key)
				break
	return result


func _target_for(record: Record) -> Object:
	var target = record.target_ref.get_ref()
	return target if target != null and is_instance_valid(target) else null


func _cleanup() -> void:
	for record in _records.duplicate():
		var tween = record.tween_ref.get_ref()
		if tween == null or not is_instance_valid(tween) or tween.is_finished() or _target_for(record) == null:
			_records.erase(record)


func _on_tween_finished(tween: AnimeTweenRuntime) -> void:
	for record in _records.duplicate():
		if record.tween_ref.get_ref() == tween:
			_records.erase(record)