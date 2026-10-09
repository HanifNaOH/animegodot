class_name AnimePosition
extends RefCounted

enum Kind {
	CURSOR,
	ABSOLUTE,
	PREVIOUS_START,
	PREVIOUS_END,
	LABEL,
}

var kind: int = Kind.CURSOR
var time: float = 0.0
var offset: float = 0.0
var label: AnimeLabel


static func cursor() -> AnimePosition:
	return AnimePosition.new(Kind.CURSOR)


static func at(seconds: float) -> AnimePosition:
	var position := AnimePosition.new(Kind.ABSOLUTE)
	position.time = seconds
	return position


static func after(label_token: AnimeLabel, time_offset: float = 0.0) -> AnimePosition:
	var position := AnimePosition.new(Kind.LABEL)
	position.label = label_token
	position.offset = time_offset
	return position


static func with_previous_start(time_offset: float = 0.0) -> AnimePosition:
	var position := AnimePosition.new(Kind.PREVIOUS_START)
	position.offset = time_offset
	return position


static func after_previous(time_offset: float = 0.0) -> AnimePosition:
	var position := AnimePosition.new(Kind.PREVIOUS_END)
	position.offset = time_offset
	return position


func _init(position_kind: int = Kind.CURSOR) -> void:
	kind = position_kind


func is_valid_for(timeline_identity: Object) -> bool:
	if not is_finite(time) or not is_finite(offset):
		return false
	if kind < Kind.CURSOR or kind > Kind.LABEL:
		return false
	if kind == Kind.ABSOLUTE and time < 0.0:
		return false
	if kind == Kind.LABEL:
		return label != null and label.belongs_to(timeline_identity)
	return true