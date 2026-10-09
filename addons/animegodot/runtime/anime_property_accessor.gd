class_name AnimePropertyAccessor
extends RefCounted

var identity: AnimePropertyKey
var _target_validator: Callable
var _value_validator: Callable
var _getter: Callable
var _setter: Callable
var _native_path_provider: Callable


func _init(
	property_identity: AnimePropertyKey,
	target_validator: Callable,
	value_validator: Callable,
	getter: Callable,
	setter: Callable,
	native_path_provider: Callable = Callable()
) -> void:
	identity = property_identity
	_target_validator = target_validator
	_value_validator = value_validator
	_getter = getter
	_setter = setter
	_native_path_provider = native_path_provider


func is_valid() -> bool:
	return (
		identity != null
		and identity.is_valid()
		and _target_validator.is_valid()
		and _value_validator.is_valid()
		and _getter.is_valid()
		and _setter.is_valid()
	)


func accepts_target(target: Object) -> bool:
	return (
		is_valid()
		and is_instance_valid(target)
		and bool(_target_validator.call(target))
	)


func accepts_value(value: Variant) -> bool:
	return is_valid() and bool(_value_validator.call(value))


func accepts(target: Object, value: Variant) -> bool:
	return accepts_target(target) and accepts_value(value)


func read(target: Object) -> Variant:
	if not accepts_target(target):
		return null
	var value = _getter.call(target)
	if not accepts_value(value):
		return null
	return value


func write(target: Object, value: Variant) -> bool:
	if not accepts(target, value):
		return false
	_setter.call(target, value)
	return true


func get_native_path(target: Object) -> NodePath:
	if not accepts_target(target) or not _native_path_provider.is_valid():
		return NodePath()
	var path = _native_path_provider.call(target)
	return path if path is NodePath else NodePath()


func has_same_identity(other: AnimePropertyAccessor) -> bool:
	return other != null and identity.same_as(other.identity)