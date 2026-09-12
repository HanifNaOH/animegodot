class_name AnimeRegistry
extends Node

const OVERWRITE_NONE := &"none"
const OVERWRITE_AUTO := &"auto"
const OVERWRITE_ALL := &"all"

var _records: Array = []


static func get_instance():
	var main_loop := Engine.get_main_loop()
	if not main_loop is SceneTree or main_loop.root == null:
		return null

	var root: Node = main_loop.root
	var metadata_key := &"animegodot_registry"
	if root.has_meta(metadata_key):
		var existing = root.get_meta(metadata_key)
		if existing != null and is_instance_valid(existing):
			return existing

	var created := AnimeRegistry.new()
	created.name = "AnimeGodotRegistry"
	created.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(created)
	root.set_meta(metadata_key, created)
	return created


func register(tween: Variant, target: Object, property_paths: Array, overwrite: Variant) -> void:
	if tween == null or target == null or not is_instance_valid(target):
		return

	_cleanup()
	var mode := StringName(str(overwrite))
	var requested_paths := _normalize_paths(property_paths)
	if mode == OVERWRITE_ALL:
		for record in _records.duplicate():
			if _record_targets(record, target):
				var existing_tween = record["tween"]
				existing_tween.kill_properties(existing_tween.get_active_property_paths())
	elif mode == OVERWRITE_AUTO:
		for record in _records.duplicate():
			if not _record_targets(record, target):
				continue
			var existing_tween = record["tween"]
			var overlap := _intersection(existing_tween.get_active_property_paths(), requested_paths)
			if not overlap.is_empty():
				existing_tween.kill_properties(overlap)

	_cleanup()
	_records.append({
		"tween": tween,
		"target": weakref(target),
	})
	tween.completed.connect(_on_tween_finished)
	tween.killed.connect(_on_tween_finished)


func get_active_records() -> Array:
	_cleanup()
	var active_records: Array = []
	for record in _records:
		var tween = record["tween"]
		var target = record["target"].get_ref()
		if target == null or not is_instance_valid(target):
			continue
		active_records.append({
			"target": target,
			"tween": tween,
			"properties": tween.get_active_property_paths(),
		})
	return active_records


func _normalize_paths(property_paths: Array) -> Array:
	var normalized: Array = []
	for property_path in property_paths:
		normalized.append(StringName(property_path))
	return normalized


func _intersection(left: Array, right: Array) -> Array:
	var result: Array = []
	for property_path in left:
		if property_path in right:
			result.append(property_path)
	return result


func _record_targets(record: Dictionary, target: Object) -> bool:
	var record_target = record["target"].get_ref()
	return record_target != null and is_instance_valid(record_target) and record_target == target


func _cleanup() -> void:
	for record in _records.duplicate():
		var tween = record["tween"]
		var target = record["target"].get_ref()
		if tween == null or not is_instance_valid(tween) or tween.is_finished() or target == null or not is_instance_valid(target):
			_records.erase(record)


func _on_tween_finished(tween: Variant) -> void:
	for record in _records.duplicate():
		if record["tween"] == tween:
			_records.erase(record)
