class_name AnimeLabel
extends RefCounted

var timeline_identity: Object
var time: float = 0.0


func _init(owner_identity: Object, label_time: float) -> void:
	timeline_identity = owner_identity
	time = label_time


func is_valid() -> bool:
	return is_instance_valid(timeline_identity) and is_finite(time) and time >= 0.0


func belongs_to(owner_identity: Object) -> bool:
	return is_valid() and timeline_identity == owner_identity