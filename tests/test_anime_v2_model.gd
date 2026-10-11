extends GutTest

const CANVAS_ITEM_SCRIPT = preload("res://addons/animegodot/runtime/anime_canvas_item.gd")
const CONTROL_SCRIPT = preload("res://addons/animegodot/runtime/anime_control.gd")
const EASE_SCRIPT = preload("res://addons/animegodot/runtime/anime_ease.gd")
const LABEL_SCRIPT = preload("res://addons/animegodot/runtime/anime_label.gd")
const NODE_2D_SCRIPT = preload("res://addons/animegodot/runtime/anime_node_2d.gd")
const NODE_3D_SCRIPT = preload("res://addons/animegodot/runtime/anime_node_3d.gd")
const OPTIONS_SCRIPT = preload("res://addons/animegodot/runtime/anime_options.gd")
const POSITION_SCRIPT = preload("res://addons/animegodot/runtime/anime_position.gd")
const PROPERTY_ACCESSOR_SCRIPT = preload("res://addons/animegodot/runtime/anime_property_accessor.gd")
const PROPERTY_KEY_SCRIPT = preload("res://addons/animegodot/runtime/anime_property_key.gd")
const STAGGER_OPTIONS_SCRIPT = preload("res://addons/animegodot/runtime/anime_stagger_options.gd")
const TRACK_SCRIPT = preload("res://addons/animegodot/runtime/anime_track.gd")
const TRACK_OPTIONS_SCRIPT = preload("res://addons/animegodot/runtime/anime_track_options.gd")
const TWEEN_SPEC_SCRIPT = preload("res://addons/animegodot/runtime/anime_tween_spec.gd")


func test_typed_options_and_enums_validate() -> void:
	var options = OPTIONS_SCRIPT.new()
	options.duration = 0.8
	options.ease = EASE_SCRIPT.OUT_BACK
	_expect(options.is_valid(), "Valid typed tween options should pass validation")
	options.ease = EASE_SCRIPT.INHERIT
	_expect(not options.is_valid(), "Tween options should reject the track-only inherited ease")

	var track_options = TRACK_OPTIONS_SCRIPT.new()
	_expect(track_options.is_valid(), "Track options should accept inherited defaults")
	track_options.duration = 0.3
	track_options.delay = 0.2
	track_options.ease = EASE_SCRIPT.OUT_QUAD
	_expect(track_options.is_valid(), "Track options should accept typed overrides")
	track_options.duration = -2.0
	_expect(not track_options.is_valid(), "Track options should reject invalid durations")


func test_accessor_identity_validation_and_multiple_tracks() -> void:
	var target := Control.new()
	target.position = Vector2(5.0, 10.0)
	target.modulate = Color(1.0, 1.0, 1.0, 0.25)
	var tween_spec = TWEEN_SPEC_SCRIPT.new(target)
	tween_spec.options.duration = 0.8
	var position_track = CONTROL_SCRIPT.position_to(Vector2(400.0, 200.0))
	var duplicate_position_track = CONTROL_SCRIPT.position_to(Vector2(10.0, 20.0))
	var alpha_track = CANVAS_ITEM_SCRIPT.alpha_to(1.0)
	alpha_track.options.duration = 0.3
	alpha_track.options.delay = 0.2

	_expect(
		tween_spec.track(position_track) == tween_spec and tween_spec.tracks.size() == 1,
		"The fluent track method should attach a compatible track and return its tween spec"
	)
	_expect(tween_spec.add_track(alpha_track), "A second property track should attach")
	_expect(not tween_spec.add_track(duplicate_position_track), "A tween spec should reject duplicate property identities")
	_expect(position_track.get_start_value() == Vector2(5.0, 10.0), "An accessor should read its typed start value")
	_expect(alpha_track.apply(0.75), "An alpha accessor should apply a float value")
	_expect(is_equal_approx(target.modulate.a, 0.75), "The alpha accessor should preserve and update modulate alpha")
	_expect(
		position_track.accessor.get_native_path(target) == NodePath("position"),
		"A built-in accessor should provide its native AnimationPlayer path internally"
	)
	_expect(
		alpha_track.accessor.has_same_identity(CANVAS_ITEM_SCRIPT.alpha_to(0.5).accessor),
		"Repeated built-in accessor factories should share stable property identity"
	)
	target.free()


func test_accessor_rejects_incompatible_target_and_value() -> void:
	var node_2d := Node2D.new()
	var control_spec = TWEEN_SPEC_SCRIPT.new(node_2d)
	_expect(
		not control_spec.add_track(CONTROL_SCRIPT.position_to(Vector2.ONE)),
		"A Control accessor should reject a Node2D target"
	)

	var key = PROPERTY_KEY_SCRIPT.custom()
	var accessor = PROPERTY_ACCESSOR_SCRIPT.new(
		key,
		func(target: Object) -> bool: return target is Node2D,
		func(value: Variant) -> bool: return value is Vector2,
		func(target: Object) -> Variant: return (target as Node2D).position,
		func(target: Object, value: Variant) -> void:
			var node := target as Node2D
			node.position = value
	)
	var invalid_value_spec = TWEEN_SPEC_SCRIPT.new(node_2d)
	var invalid_value_track = TRACK_SCRIPT.new(accessor, Vector3.ONE)
	_expect(
		not invalid_value_spec.add_track(invalid_value_track),
		"A tween spec should reject a track whose value fails its accessor type guard"
	)
	_expect(
		not accessor.accepts(node_2d, Vector3.ONE),
		"A custom accessor should reject values outside its declared type guard"
	)

	var same_key_accessor = PROPERTY_ACCESSOR_SCRIPT.new(
		key,
		func(target: Object) -> bool: return target is Node2D,
		func(value: Variant) -> bool: return value is Vector2,
		func(target: Object) -> Variant: return (target as Node2D).position,
		func(target: Object, value: Variant) -> void:
			var node := target as Node2D
			node.position = value
	)
	var different_key_accessor = PROPERTY_ACCESSOR_SCRIPT.new(
		PROPERTY_KEY_SCRIPT.custom(),
		func(target: Object) -> bool: return target is Node2D,
		func(value: Variant) -> bool: return value is Vector2,
		func(target: Object) -> Variant: return (target as Node2D).position,
		func(target: Object, value: Variant) -> void:
			var node := target as Node2D
			node.position = value
	)
	_expect(accessor.has_same_identity(same_key_accessor), "A shared custom key should preserve identity")
	_expect(not accessor.has_same_identity(different_key_accessor), "Distinct custom keys should remain distinct")
	node_2d.free()


func test_track_ranges_and_keyframes_are_type_checked() -> void:
	var target := Control.new()
	var track = CONTROL_SCRIPT.position_to(Vector2(100.0, 40.0))
	_expect(track.set_start_value(Vector2.ZERO), "A typed start override should be accepted")
	_expect(track.set_keyframes([Vector2(20.0, 10.0), Vector2(60.0, 25.0)]), "Typed keyframes should be accepted")
	_expect(track.attach_to(target), "A valid ranged track should attach to its target")
	_expect(track.get_start_value() == Vector2.ZERO, "A track should expose its explicit starting value")
	_expect(not track.set_start_value(Vector3.ZERO), "A track should reject an incompatible start value")
	_expect(not track.set_keyframes([Vector2.ONE, Vector3.ONE]), "A track should reject keyframes with mixed value types")
	target.free()


func test_common_control_accessors_have_stable_property_identity() -> void:
	var target := Control.new()
	var tween_spec = TWEEN_SPEC_SCRIPT.new(target)
	var size_track = CONTROL_SCRIPT.custom_minimum_size_to(Vector2(120.0, 30.0))
	var visual_size_track = CONTROL_SCRIPT.size_to(Vector2(120.0, 30.0))
	var scale_track = CONTROL_SCRIPT.scale_to(Vector2(1.1, 1.1))
	var modulate_track = CANVAS_ITEM_SCRIPT.modulate_to(Color.WHITE)
	var alpha_track = CANVAS_ITEM_SCRIPT.alpha_to(0.5)
	_expect(tween_spec.add_track(size_track), "A custom minimum-size accessor should attach")
	_expect(tween_spec.add_track(visual_size_track), "A visual-size accessor should attach independently")
	_expect(tween_spec.add_track(scale_track), "A scale accessor should attach independently")
	_expect(tween_spec.add_track(modulate_track), "A full-modulate accessor should attach")
	_expect(
		modulate_track.accessor.has_same_identity(alpha_track.accessor),
		"Alpha and full-modulate accessors should share conflict identity"
	)
	_expect(not tween_spec.add_track(alpha_track), "A tween spec should reject alpha overlapping a full-modulate track")
	_expect(size_track.apply(Vector2(120.0, 30.0)), "The custom minimum-size accessor should write its typed value")
	_expect(target.custom_minimum_size == Vector2(120.0, 30.0), "The custom minimum size should be updated")
	_expect(visual_size_track.apply(Vector2(120.0, 30.0)), "The visual-size accessor should write its typed value")
	_expect(target.size == Vector2(120.0, 30.0), "The Control size should be updated")
	target.free()


func test_node2d_accessors_are_typed_and_share_rotation_identity() -> void:
	var target := Node2D.new()
	var position_track = NODE_2D_SCRIPT.position_to(Vector2(10.0, 20.0))
	var global_position_track = NODE_2D_SCRIPT.global_position_to(Vector2(30.0, 40.0))
	var rotation_track = NODE_2D_SCRIPT.rotation_to(PI)
	var rotation_degrees_track = NODE_2D_SCRIPT.rotation_degrees_to(90.0)
	var scale_track = NODE_2D_SCRIPT.scale_to(Vector2(2.0, 2.0))
	_expect(position_track.attach_to(target), "Node2D position should accept a Node2D and Vector2")
	_expect(global_position_track.attach_to(target), "Node2D global position should accept a Node2D and Vector2")
	_expect(rotation_track.attach_to(target), "Node2D rotation should accept a Node2D and float")
	_expect(scale_track.attach_to(target), "Node2D scale should accept a Node2D and Vector2")
	_expect(
		rotation_track.accessor.has_same_identity(rotation_degrees_track.accessor),
		"Radians and degrees rotation accessors should share conflict identity"
	)
	_expect(
		position_track.accessor.get_native_path(target) == NodePath("position"),
		"Node2D position should provide its native path internally"
	)
	var incompatible_control := Control.new()
	_expect(
		not NODE_2D_SCRIPT.position_to(Vector2.ONE).attach_to(incompatible_control),
		"Node2D accessors should reject Controls"
	)
	incompatible_control.free()
	target.free()


func test_node3d_accessors_are_typed_and_share_property_identity() -> void:
	var target := Node3D.new()
	var position_track = NODE_3D_SCRIPT.position_to(Vector3(2.0, 3.0, 4.0))
	var global_position_track = NODE_3D_SCRIPT.global_position_to(Vector3(5.0, 6.0, 7.0))
	var rotation_track = NODE_3D_SCRIPT.rotation_to(Vector3(0.1, 0.2, 0.3))
	var scale_track = NODE_3D_SCRIPT.scale_to(Vector3.ONE * 1.2)
	_expect(position_track.attach_to(target), "Node3D position should accept a Node3D and Vector3")
	_expect(global_position_track.attach_to(target), "Node3D global position should accept a Node3D and Vector3")
	_expect(rotation_track.attach_to(target), "Node3D rotation should accept a Node3D and Vector3")
	_expect(scale_track.attach_to(target), "Node3D scale should accept a Node3D and Vector3")
	_expect(position_track.apply(Vector3(2.0, 3.0, 4.0)), "Node3D position should apply typed values")
	_expect(rotation_track.apply(Vector3(0.1, 0.2, 0.3)), "Node3D rotation should apply typed values")
	_expect(scale_track.apply(Vector3.ONE * 1.2), "Node3D scale should apply typed values")
	_expect(target.position == Vector3(2.0, 3.0, 4.0), "Node3D position should receive its value")
	_expect(target.rotation == Vector3(0.1, 0.2, 0.3), "Node3D rotation should receive its value")
	_expect(target.scale == Vector3.ONE * 1.2, "Node3D scale should receive its value")
	_expect(
		position_track.accessor.get_native_path(target) == NodePath("position"),
		"Node3D position should provide its native path internally"
	)
	_expect(
		position_track.accessor.has_same_identity(NODE_3D_SCRIPT.position_to(Vector3.ZERO).accessor),
		"Node3D position accessors should share identity"
	)
	_expect(
		rotation_track.accessor.has_same_identity(NODE_3D_SCRIPT.rotation_to(Vector3.ZERO).accessor),
		"Node3D rotation accessors should share identity"
	)
	var incompatible_control := Control.new()
	_expect(
		not NODE_3D_SCRIPT.position_to(Vector3.ONE).attach_to(incompatible_control),
		"Node3D accessors should reject Controls"
	)
	incompatible_control.free()
	target.free()


func test_typed_timeline_positions_and_labels() -> void:
	var timeline_identity := Node.new()
	var label = LABEL_SCRIPT.new(timeline_identity, 1.25)
	var after_label = POSITION_SCRIPT.after(label, 0.2)
	var absolute_position = POSITION_SCRIPT.at(0.7)
	var previous_start = POSITION_SCRIPT.with_previous_start(0.1)
	var previous_end = POSITION_SCRIPT.after_previous(-0.1)

	_expect(after_label.is_valid_for(timeline_identity), "A label position should belong to its creating timeline")
	var different_timeline_identity := Node.new()
	_expect(after_label.is_valid_for(different_timeline_identity) == false, "A label position should reject a different timeline")
	different_timeline_identity.free()
	_expect(absolute_position.is_valid_for(timeline_identity), "An absolute typed position should be valid")
	_expect(previous_start.is_valid_for(timeline_identity), "A relative previous-start position should be valid")
	_expect(previous_end.is_valid_for(timeline_identity), "A relative previous-end offset may overlap its predecessor")
	_expect(not POSITION_SCRIPT.at(-0.1).is_valid_for(timeline_identity), "Negative absolute positions should be rejected")
	timeline_identity.free()


func test_stagger_origins_and_amount_are_typed() -> void:
	var stagger = STAGGER_OPTIONS_SCRIPT.new()
	stagger.each = 0.1
	var start_delays: Array[float] = []
	for index in 4:
		start_delays.append(stagger.delay_for(index, 4))
	_expect(
		is_zero_approx(start_delays[0])
			and is_equal_approx(start_delays[1], 0.1)
			and is_equal_approx(start_delays[2], 0.2)
			and is_equal_approx(start_delays[3], 0.3),
		"The first origin should distribute by typed each interval"
	)

	stagger.origin = STAGGER_OPTIONS_SCRIPT.Origin.CENTER
	_expect(is_equal_approx(stagger.delay_for(0, 4), 0.15), "The center origin should start both outer targets last")
	_expect(is_equal_approx(stagger.delay_for(1, 4), 0.05), "The center origin should start inner targets first")

	stagger.origin = STAGGER_OPTIONS_SCRIPT.Origin.EDGES
	_expect(is_zero_approx(stagger.delay_for(0, 4)), "The edges origin should start the outer targets first")
	_expect(is_equal_approx(stagger.delay_for(1, 4), 0.1), "The edges origin should delay inner targets")
	stagger.amount = 0.6
	_expect(is_equal_approx(stagger.delay_for(1, 4), 0.6), "A typed amount should set the total stagger spread")


func test_stagger_grid_axis_rankings() -> void:
	var stagger = STAGGER_OPTIONS_SCRIPT.new()
	stagger.each = 0.1
	stagger.grid_size = Vector2i(3, 2)
	stagger.origin = STAGGER_OPTIONS_SCRIPT.Origin.CENTER
	stagger.axis = STAGGER_OPTIONS_SCRIPT.Axis.HORIZONTAL
	_expect(is_equal_approx(stagger.delay_for(0, 6), 0.1), "Horizontal grid staggering should delay outer columns")
	_expect(is_zero_approx(stagger.delay_for(1, 6)), "Horizontal grid staggering should start center columns first")

	stagger.grid_size = Vector2i(2, 3)
	stagger.axis = STAGGER_OPTIONS_SCRIPT.Axis.VERTICAL
	_expect(is_equal_approx(stagger.delay_for(0, 6), 0.1), "Vertical grid staggering should delay outer rows")
	_expect(is_zero_approx(stagger.delay_for(2, 6)), "Vertical grid staggering should start the center row first")
	_expect(stagger.is_valid(), "A positive typed grid and axis should be valid")
	stagger.grid_size = Vector2i(2, 0)
	_expect(not stagger.is_valid(), "A partially specified grid should be rejected")


func _expect(condition: bool, message: String) -> void:
	assert_true(condition, message)