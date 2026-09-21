class_name AnimeAnimation
extends RefCounted

const PROPERTY_SCRIPT = preload("res://addons/animegodot/runtime/anime_property.gd")
const RESERVED_OPTIONS := [
	&"duration",
	&"delay",
	&"ease",
	&"repeat",
	&"yoyo",
	&"stagger",
	&"keyframes",
	&"interpolate",
	&"overwrite",
	&"speed_scale",
	&"on_start",
	&"on_update",
	&"on_complete",
	&"on_kill",
]


static func from_properties(player: AnimationPlayer, target: Node, properties: Dictionary, duration: float) -> Animation:
	var animation := Animation.new()
	animation.length = maxf(duration, 0.0)
	if not is_instance_valid(player) or not is_instance_valid(target):
		push_warning("AnimeGodot animation conversion requires a valid AnimationPlayer and target Node.")
		return animation
	if player.is_inside_tree() and target.is_inside_tree() and player.get_tree() != target.get_tree():
		push_warning("AnimeGodot animation conversion target must be in the same SceneTree as the AnimationPlayer.")
		return animation
	for property_key in properties:
		var property_path := StringName(property_key)
		if property_path in RESERVED_OPTIONS:
			continue
		if not PROPERTY_SCRIPT.exists(target, property_path):
			push_warning("AnimeGodot cannot convert missing property '%s' to an AnimationPlayer track." % property_path)
			continue
		var track := animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(track, _track_path(player, target, property_path))
		animation.track_insert_key(track, 0.0, PROPERTY_SCRIPT.read(target, property_path))
		animation.track_insert_key(track, animation.length, properties[property_key])
	return animation


static func add_to_player(player: AnimationPlayer, name: StringName, target: Node, properties: Dictionary, duration: float) -> Animation:
	if not is_instance_valid(player):
		push_warning("AnimeGodot animation installation requires a valid AnimationPlayer.")
		return Animation.new()
	var animation := from_properties(player, target, properties, duration)
	var library_name := &""
	var library: AnimationLibrary
	if player.has_animation_library(library_name):
		library = player.get_animation_library(library_name)
	else:
		library = AnimationLibrary.new()
		player.add_animation_library(library_name, library)
	if library.has_animation(name):
		library.remove_animation(name)
	library.add_animation(name, animation)
	return animation


static func _track_path(player: AnimationPlayer, target: Node, property_path: StringName) -> NodePath:
	var animation_root := player.get_node_or_null(player.root_node)
	if animation_root == null:
		animation_root = player.get_parent()
	var relative_path := animation_root.get_path_to(target) if animation_root != null else player.get_path_to(target)
	return NodePath(String(relative_path) + ":" + String(property_path))
