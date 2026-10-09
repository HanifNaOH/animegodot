class_name AnimePropertyKey
extends RefCounted

enum Builtin {
	CUSTOM,
	POSITION,
	MODULATE,
	CUSTOM_MINIMUM_SIZE,
	SCALE,
	GLOBAL_POSITION,
	ROTATION,
	GLOBAL_ROTATION,
}

var builtin_id: int = Builtin.CUSTOM


func _init(identity: int = Builtin.CUSTOM) -> void:
	builtin_id = identity


static func custom() -> AnimePropertyKey:
	return AnimePropertyKey.new(Builtin.CUSTOM)


static func builtin(identity: int) -> AnimePropertyKey:
	return AnimePropertyKey.new(identity)


func is_valid() -> bool:
	return builtin_id >= Builtin.CUSTOM and builtin_id <= Builtin.GLOBAL_ROTATION


func same_as(other: AnimePropertyKey) -> bool:
	if other == null or not is_valid() or not other.is_valid():
		return false
	if builtin_id == Builtin.CUSTOM or other.builtin_id == Builtin.CUSTOM:
		return self == other
	return builtin_id == other.builtin_id


func display_name() -> StringName:
	match builtin_id:
		Builtin.POSITION: return &"position"
		Builtin.MODULATE: return &"modulate"
		Builtin.CUSTOM_MINIMUM_SIZE: return &"custom_minimum_size"
		Builtin.SCALE: return &"scale"
		Builtin.GLOBAL_POSITION: return &"global_position"
		Builtin.ROTATION: return &"rotation"
		Builtin.GLOBAL_ROTATION: return &"global_rotation"
		_: return &"custom"