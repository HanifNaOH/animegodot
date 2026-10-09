class_name AnimeTweenSpec
extends RefCounted

var target: Object
var options: AnimeOptions = AnimeOptions.new()
var tracks: Array[AnimeTrack] = []


func _init(tween_target: Object = null) -> void:
	target = tween_target


func track(new_track: AnimeTrack) -> AnimeTweenSpec:
	if not add_track(new_track):
		push_warning("AnimeGodot tween spec rejected an invalid, incompatible, or duplicate track.")
	return self


func add_track(new_track: AnimeTrack) -> bool:
	if not is_instance_valid(target) or new_track == null or not options.is_valid():
		return false
	if not new_track.options.is_valid() or not new_track.attach_to(target):
		return false
	for existing_track in tracks:
		if existing_track.accessor.has_same_identity(new_track.accessor):
			return false
	tracks.append(new_track)
	return true