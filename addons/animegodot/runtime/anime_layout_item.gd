class_name AnimeLayoutItem
extends RefCounted

var layout_control: Control
var visual_control: Control


func _init(layout: Control, visual: Control) -> void:
	layout_control = layout
	visual_control = visual


func is_valid() -> bool:
	return (
		is_instance_valid(layout_control)
		and is_instance_valid(visual_control)
		and layout_control != visual_control
		and visual_control.get_parent() == layout_control
		and layout_control.is_inside_tree()
		and visual_control.is_inside_tree()
		and visual_control.pivot_offset.is_zero_approx()
	)