@tool
extends Node3D

@export var atomic_number: int = 1:
	set(value):
		atomic_number = value
		_sync_text()
@export var symbol: String = "H":
	set(value):
		symbol = value
		_sync_text()
@export var element_name: String = "Hydrogen":
	set(value):
		element_name = value
		_sync_text()
@export_multiline var details: String = "MASS  1.008 u\nDENSITY  0.08988 g/cm3\nMELTS  -259.16 C\nBOILS  -252.88 C":
	set(value):
		details = value
		_sync_text()
@export var category_color: Color = Color(0.40, 0.82, 0.63):
	set(value):
		category_color = value
		_sync_materials()


func _ready() -> void:
	_sync_text()
	_sync_materials()


func _sync_text() -> void:
	var number_label := get_node_or_null("Visuals/AtomicNumber") as Label3D
	if number_label != null:
		number_label.text = str(atomic_number)
	var symbol_label := get_node_or_null("Visuals/Symbol") as Label3D
	if symbol_label != null:
		symbol_label.text = symbol
	var name_label := get_node_or_null("Visuals/ElementName") as Label3D
	if name_label != null:
		name_label.text = element_name
	var details_label := get_node_or_null("Visuals/Details") as Label3D
	if details_label != null:
		details_label.text = details


func _sync_materials() -> void:
	_set_mesh_color("Visuals/Face", category_color)
	_set_mesh_color("Visuals/Frame", category_color.darkened(0.55))


func _set_mesh_color(node_path: NodePath, color: Color) -> void:
	var mesh_instance := get_node_or_null(node_path) as MeshInstance3D
	if mesh_instance == null:
		return
	var material := mesh_instance.material_override as StandardMaterial3D
	if material == null:
		return
	if not material.resource_local_to_scene:
		material = material.duplicate() as StandardMaterial3D
		material.resource_local_to_scene = true
		mesh_instance.material_override = material
	material.albedo_color = color
