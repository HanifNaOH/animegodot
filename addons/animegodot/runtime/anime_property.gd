class_name AnimeProperty
extends RefCounted


static func exists(target: Object, property_path: StringName) -> bool:
	if not is_instance_valid(target):
		return false
	if _is_shader_parameter_path(target, property_path):
		return true

	var node_path := NodePath(property_path)
	if node_path.get_name_count() == 0:
		return false

	var root_property := node_path.get_name(0)
	for property_info in target.get_property_list():
		if property_info.get("name") == root_property:
			return true
	return false


static func read(target: Object, property_path: StringName) -> Variant:
	var shader_path := _shader_parameter_parts(target, property_path)
	if not shader_path.is_empty():
		return shader_path["material"].get_shader_parameter(shader_path["parameter"])
	return target.get_indexed(NodePath(property_path))


static func write(target: Object, property_path: StringName, value: Variant) -> void:
	var shader_path := _shader_parameter_parts(target, property_path)
	if not shader_path.is_empty():
		shader_path["material"].set_shader_parameter(shader_path["parameter"], value)
		return
	target.set_indexed(NodePath(property_path), value)


static func _is_shader_parameter_path(target: Object, property_path: StringName) -> bool:
	return not _shader_parameter_parts(target, property_path).is_empty()


static func _shader_parameter_parts(target: Object, property_path: StringName) -> Dictionary:
	var path_text := String(property_path)
	var separator := path_text.find(":shader_parameter/")
	if separator < 0:
		return {}
	var material_path := path_text.substr(0, separator)
	var parameter_name := path_text.substr(separator + 18)
	if material_path.is_empty() or parameter_name.is_empty():
		return {}
	var material = target.get_indexed(NodePath(material_path))
	if material is ShaderMaterial:
		return {"material": material, "parameter": StringName(parameter_name)}
	return {}