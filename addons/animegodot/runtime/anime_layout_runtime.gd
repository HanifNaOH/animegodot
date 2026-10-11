class_name AnimeLayoutRuntime
extends RefCounted

const TWEEN_RUNTIME_SCRIPT = preload("res://addons/animegodot/runtime/anime_tween_runtime.gd")
const CONTROL_SCRIPT = preload("res://addons/animegodot/runtime/anime_control.gd")
const ELEVATED_Z_INDEX := 4096

signal started(layout: AnimeLayoutRuntime)
signal completed(layout: AnimeLayoutRuntime)
signal killed(layout: AnimeLayoutRuntime)
signal _update_finished

class Snapshot:
	var item: AnimeLayoutItem
	var first_rect: Rect2
	var original_order := 0
	var original_z_index := 0
	var original_z_as_relative := true
	var original_scale := Vector2.ONE
	var final_global_position := Vector2.ZERO
	var final_size := Vector2.ZERO
	var final_scale := Vector2.ONE
	var has_final := false

var options: AnimeLayoutOptions = AnimeLayoutOptions.new()
var active := false
var _root: Control
var _discovers_children := false
var _snapshots: Array[Snapshot] = []
var _active_tweens: Array[AnimeTweenRuntime] = []
var _started := false
var _completed := false
var _killed := false
var _update_in_progress := false
var _update_generation := 0


func _init(source: Variant, layout_options: AnimeLayoutOptions = null) -> void:
	if layout_options != null:
		options = layout_options.copy()
	if source is Control:
		_root = source as Control
		_discovers_children = true
		return
	if not source is Array:
		push_warning("AnimeGodot layout requires a root Control or an array of AnimeLayoutItem values.")
		return
	_snapshots = _capture_items(source)


func record() -> AnimeLayoutRuntime:
	if not _discovers_children or not is_instance_valid(_root):
		push_warning("AnimeGodot record() requires a layout created with Anime.create_layout().")
		return self
	if _update_in_progress or active or not _active_tweens.is_empty():
		push_warning("AnimeGodot cannot record a layout while its previous transition is active.")
		return self
	_record()
	return self


func _record() -> void:
	_reset_run_state()
	_snapshots = _capture_items(_discover_items())


func animate() -> AnimeLayoutRuntime:
	return play()


func update(change: Callable) -> AnimeLayoutRuntime:
	if not _discovers_children or not is_instance_valid(_root) or not _root.is_inside_tree():
		push_warning("AnimeGodot update() requires an in-tree root created with Anime.create_layout().")
		return self
	if not change.is_valid():
		push_warning("AnimeGodot update() requires a valid layout-change Callable.")
		return self
	if _update_in_progress or active or not _active_tweens.is_empty():
		push_warning("AnimeGodot cannot update a layout while its previous transition is active.")
		return self
	_update_in_progress = true
	_update_generation += 1
	var update_generation := _update_generation
	_record()
	change.call(_root)
	if update_generation != _update_generation:
		return self
	await _wait_for_layout_settle()
	if update_generation != _update_generation:
		return self
	animate()
	if not is_finished():
		await _update_finished
	if update_generation == _update_generation:
		_update_in_progress = false
	return self


func _capture_items(items: Array) -> Array[Snapshot]:
	var snapshots: Array[Snapshot] = []
	var seen_controls: Dictionary = {}
	for item in items:
		if item == null or not is_instance_valid(item) or not item.is_valid():
			push_warning("AnimeGodot FLIP requires an in-tree layout Control and its direct-child visual wrapper with a zero pivot.")
			continue
		var layout_id: int = item.layout_control.get_instance_id()
		if seen_controls.has(layout_id):
			push_warning("AnimeGodot FLIP received the same layout Control more than once.")
			continue
		seen_controls[layout_id] = true
		var snapshot := Snapshot.new()
		snapshot.item = item
		snapshot.first_rect = item.visual_control.get_global_rect()
		snapshot.original_order = item.layout_control.get_index()
		snapshot.original_z_index = item.visual_control.z_index
		snapshot.original_z_as_relative = item.visual_control.z_as_relative
		snapshot.original_scale = item.visual_control.scale
		snapshots.append(snapshot)
	return snapshots


func _discover_items() -> Array[AnimeLayoutItem]:
	var items: Array[AnimeLayoutItem] = []
	var candidates: Array[Node] = []
	if options.children_group.is_empty():
		candidates.assign(_root.get_children())
	else:
		for node in _root.find_children("*", "Control", true, false):
			if node.is_in_group(options.children_group):
				candidates.append(node)
	for candidate in candidates:
		var layout_control := candidate as Control
		if layout_control == null:
			continue
		var visual_control := layout_control.get_node_or_null(options.visual_path) as Control
		if visual_control == null:
			continue
		items.append(AnimeLayoutItem.new(layout_control, visual_control))
	return items


func _wait_for_layout_settle() -> void:
	var tree := _root.get_tree()
	var previous_rects := _current_layout_rects()
	var stable_frames := 0
	for _frame in 12:
		await tree.process_frame
		var current_rects := _current_layout_rects()
		if current_rects == previous_rects:
			stable_frames += 1
		else:
			stable_frames = 0
		previous_rects = current_rects
		hold_first_state()
		if stable_frames >= 2:
			return


func _current_layout_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for snapshot in _snapshots:
		if is_instance_valid(snapshot.item) and snapshot.item.is_valid():
			rects.append(snapshot.item.layout_control.get_global_rect())
	return rects


func _reset_run_state() -> void:
	_started = false
	_completed = false
	_killed = false
	active = false
	_active_tweens.clear()


func play() -> AnimeLayoutRuntime:
	if _started or _completed or _killed:
		return self
	_started = true
	if not options.is_valid():
		push_warning("AnimeGodot FLIP rejected invalid layout options.")
		_killed = true
		killed.emit(self)
		return self
	active = true
	started.emit(self)
	for snapshot in _snapshots:
		if not _prepare_snapshot(snapshot):
			continue
		var item := snapshot.item
		var visual := item.visual_control
		var item_tween: AnimeTweenRuntime = TWEEN_RUNTIME_SCRIPT.new(visual)
		item_tween.options.duration = options.duration
		item_tween.options.ease = options.ease
		item_tween.options.speed_scale = options.speed_scale
		item_tween.options.ignore_time_scale = options.ignore_time_scale
		item_tween.options.process_mode = options.process_mode
		item_tween.options.overwrite = options.overwrite
		var position_track := CONTROL_SCRIPT.global_position_to(snapshot.final_global_position)
		var size_track := CONTROL_SCRIPT.size_to(snapshot.final_size)
		size_track.options.ease = options.size_ease
		if (
			not item_tween.add_track(position_track)
			or not item_tween.add_track(size_track)
		):
			_restore_final(snapshot)
			continue
		item_tween.completed.connect(_on_item_completed)
		item_tween.killed.connect(_on_item_killed)
		_active_tweens.append(item_tween)
	if _active_tweens.is_empty():
		_finish()
		return self
	for item_tween in _active_tweens.duplicate():
		if is_instance_valid(item_tween):
			item_tween.play()
	return self


func kill() -> void:
	if _completed or _killed:
		return
	_killed = true
	if _update_in_progress:
		_update_generation += 1
		_update_in_progress = false
	active = false
	for item_tween in _active_tweens.duplicate():
		if is_instance_valid(item_tween):
			item_tween.kill(false)
	for snapshot in _snapshots:
		_restore_final(snapshot)
	_active_tweens.clear()
	killed.emit(self)
	_update_finished.emit()


func is_finished() -> bool:
	return _completed or _killed


func hold_first_state() -> void:
	if _started or _completed or _killed:
		return
	for snapshot in _snapshots:
		if not is_instance_valid(snapshot.item) or not snapshot.item.is_valid():
			continue
		var visual := snapshot.item.visual_control
		visual.global_position = snapshot.first_rect.position
		visual.size = snapshot.first_rect.size
		visual.scale = snapshot.original_scale


func _prepare_snapshot(snapshot: Snapshot) -> bool:
	if snapshot.item == null or not is_instance_valid(snapshot.item) or not snapshot.item.is_valid():
		return false
	var item := snapshot.item
	var visual := item.visual_control
	var last_rect := item.layout_control.get_global_rect()
	if (
		snapshot.first_rect.size.x <= 0.0
		or snapshot.first_rect.size.y <= 0.0
		or last_rect.size.x <= 0.0
		or last_rect.size.y <= 0.0
	):
		return false
	snapshot.final_global_position = last_rect.position
	snapshot.final_size = last_rect.size
	snapshot.final_scale = snapshot.original_scale
	snapshot.has_final = true
	visual.global_position = snapshot.first_rect.position
	visual.size = snapshot.first_rect.size
	visual.scale = snapshot.original_scale
	_raise_visual(snapshot)
	return true


func _on_item_completed(item_tween: AnimeTweenRuntime) -> void:
	_remove_item_tween(item_tween)
	if not _killed and _active_tweens.is_empty():
		_finish()


func _on_item_killed(item_tween: AnimeTweenRuntime) -> void:
	var snapshot := _snapshot_for(item_tween)
	_remove_item_tween(item_tween)
	_restore_final(snapshot)
	if not _killed and _active_tweens.is_empty():
		_finish()


func _snapshot_for(item_tween: AnimeTweenRuntime) -> Snapshot:
	for snapshot in _snapshots:
		if is_instance_valid(snapshot.item) and snapshot.item.visual_control == item_tween.target:
			return snapshot
	return null


func _remove_item_tween(item_tween: AnimeTweenRuntime) -> void:
	_active_tweens.erase(item_tween)


func _raise_visual(snapshot: Snapshot) -> void:
	var visual := snapshot.item.visual_control
	visual.z_as_relative = false
	var snapshot_index := _snapshots.find(snapshot)
	var rank := 0
	for candidate_index in _snapshots.size():
		var candidate: Snapshot = _snapshots[candidate_index]
		if candidate.original_order < snapshot.original_order or (
			candidate.original_order == snapshot.original_order and candidate_index < snapshot_index
		):
			rank += 1
	visual.z_index = ELEVATED_Z_INDEX - _snapshots.size() + rank + 1


func _restore_final(snapshot: Snapshot) -> void:
	if snapshot == null or not is_instance_valid(snapshot.item) or not snapshot.item.is_valid():
		return
	if not snapshot.has_final:
		var layout_rect := snapshot.item.layout_control.get_global_rect()
		snapshot.final_global_position = layout_rect.position
		snapshot.final_size = layout_rect.size
		snapshot.final_scale = snapshot.original_scale
		snapshot.has_final = true
	if not is_instance_valid(snapshot.item.visual_control):
		return
	var visual := snapshot.item.visual_control
	visual.global_position = snapshot.final_global_position
	visual.size = snapshot.final_size
	visual.scale = snapshot.final_scale
	visual.z_as_relative = snapshot.original_z_as_relative
	visual.z_index = snapshot.original_z_index


func _finish() -> void:
	if _completed or _killed:
		return
	for snapshot in _snapshots:
		_restore_final(snapshot)
	active = false
	_completed = true
	_update_in_progress = false
	completed.emit(self)
	_update_finished.emit()