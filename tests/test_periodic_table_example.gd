extends GutTest

const DEMO_SCENE = preload("res://examples/periodic_table/periodic_table_demo.tscn")


func test_scene_authors_the_elements_and_interface() -> void:
	var demo: Node = DEMO_SCENE.instantiate()
	var stage := demo.get_node_or_null("ElementStage") as Node3D
	_assert(stage != null, "The 3D stage should be authored in the packed scene")
	_assert(stage.get_child_count() == 118, "All element cards should exist before runtime initialization")
	_assert(demo.get_node_or_null("%LayoutCamera") is Camera3D, "The camera should be authored in the packed scene")
	_assert(demo.get_node_or_null("%TableButton") is Button, "The layout interface should be authored in the packed scene")

	var hydrogen := stage.get_node_or_null("Element001_H") as Node3D
	var helium := stage.get_node_or_null("Element002_He") as Node3D
	_assert(hydrogen != null, "Hydrogen should be a serialized card node")
	_assert(helium != null, "Helium should be a serialized card node")
	_assert(
		hydrogen.scene_file_path == "res://examples/periodic_table/periodic_table_element_card.tscn"
			and helium.scene_file_path == hydrogen.scene_file_path,
		"Every element should instance the same reusable card scene"
	)
	_assert(String(helium.get("symbol")) == "He", "Each card instance should retain its element-specific data")
	for index in stage.get_child_count():
		var card := stage.get_child(index) as Node3D
		_assert(card.scene_file_path == hydrogen.scene_file_path, "Every card should share the reusable model scene")
		_assert(int(card.get("atomic_number")) == index + 1, "Every card should retain its atomic-number override")
	_assert(hydrogen.get_node_or_null("Face") is MeshInstance3D, "Card geometry should be editable scene nodes")
	_assert(hydrogen.get_node_or_null("Symbol") is Label3D, "Element labels should be editable scene nodes")
	_assert(hydrogen.get_node_or_null("Picker/CollisionShape") is CollisionShape3D, "Card picking should be authored in the scene")
	demo.free()


func test_periodic_table_animates_all_four_layout_targets() -> void:
	var demo = DEMO_SCENE.instantiate()
	add_child_autoqfree(demo)
	await wait_process_frames(2)

	var cards: Array = demo.get("_cards")
	_assert(cards.size() == 118, "The scene should build one card for every element")
	var layout_names: Array[StringName] = [&"table", &"sphere", &"helix", &"grid"]
	var target_positions: Array[Vector3] = []
	for layout in layout_names:
		var target: Transform3D = demo.call("_layout_transform", 0, layout)
		_assert(not target_positions.has(target.origin), "Each layout should place the first element differently")
		if layout == &"sphere" or layout == &"helix":
			_assert(not target.basis.get_euler().is_zero_approx(), "Sphere and helix cards should follow their 3D arrangement")
		else:
			_assert(target.basis.get_euler().is_zero_approx(), "Table and grid cards should stay face-on")
		target_positions.append(target.origin)
	var first_sphere: Transform3D = demo.call("_layout_transform", 0, &"sphere")
	var sphere_radius := first_sphere.origin.length()
	for index in cards.size():
		var sphere_layout_target: Transform3D = demo.call("_layout_transform", index, &"sphere")
		_assert(absf(sphere_layout_target.origin.length() - sphere_radius) < 0.001, "Every element center should lie on the same sphere")
		_assert(
			sphere_layout_target.basis.z.normalized().dot(sphere_layout_target.origin.normalized()) > 0.999,
			"Each element face should point radially outward"
		)
	var grid_first: Transform3D = demo.call("_layout_transform", 0, &"grid")
	var grid_next_layer: Transform3D = demo.call("_layout_transform", 25, &"grid")
	var grid_last_layer: Transform3D = demo.call("_layout_transform", 100, &"grid")
	_assert(
		grid_first.origin.z < grid_next_layer.origin.z and grid_next_layer.origin.z < grid_last_layer.origin.z,
		"The grid layout should distribute elements across multiple depth layers"
	)

	var stage := demo.get("_stage") as Node3D
	var pointer_motion := InputEventMouseMotion.new()
	pointer_motion.position = Vector2.ZERO
	demo.call("_input", pointer_motion)
	await wait_process_frames(12)
	_assert(not stage.rotation.is_zero_approx(), "Moving the pointer should orbit the 3D arrangement")

	var right_press := InputEventMouseButton.new()
	right_press.button_index = MOUSE_BUTTON_RIGHT
	right_press.pressed = true
	demo.call("_unhandled_input", right_press)
	var drag := InputEventMouseMotion.new()
	drag.relative = Vector2(180.0, -90.0)
	demo.call("_input", drag)
	_assert(not stage.rotation.is_zero_approx(), "Right-dragging should orbit the 3D arrangement")

	var first_card := cards[0] as Node3D
	var source_position := first_card.position
	var sphere_target: Transform3D = demo.call("_layout_transform", 0, &"sphere")
	demo.call("_change_layout", &"sphere")
	await wait_process_frames(12)
	_assert(first_card.position.distance_to(source_position) > 0.1, "The first card should begin moving during a layout transition")
	_assert(first_card.position.distance_to(sphere_target.origin) > 0.1, "The first card should be observed between layouts")

	var waited_frames := 0
	while demo.get("_transitioning") and waited_frames < 180:
		await wait_process_frames(1)
		waited_frames += 1
	_assert(not demo.get("_transitioning"), "The layout transition should finish")
	_assert(first_card.position.is_equal_approx(sphere_target.origin), "The first card should settle at the sphere target")
	_assert(
		first_card.rotation.is_equal_approx(sphere_target.basis.get_euler()),
		"Cards should settle into their sphere-facing orientation"
	)


func test_every_element_has_a_picker_and_viewport_click_selects_cards() -> void:
	var demo = DEMO_SCENE.instantiate()
	add_child_autoqfree(demo)
	await wait_process_frames(2)
	await wait_physics_frames(2)

	var cards: Array = demo.get("_cards")
	var camera := demo.get("_camera") as Camera3D
	for card in cards:
		var has_picker := false
		for child in (card as Node3D).get_children():
			if child is Area3D and (child as Area3D).input_ray_pickable:
				has_picker = true
				break
		_assert(has_picker, "Every periodic-table element should have a ray-pickable area")

	for index in [0, 25, 117]:
		var card := cards[index] as Node3D
		var screen_position := camera.unproject_position(card.global_position)
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		click.position = screen_position
		demo.call("_input", click)
		await wait_physics_frames(2)
		await wait_process_frames(1)
		_assert(
			demo.get("_selected_index") == index,
			"Viewport clicks should select the element under the pointer: index=%d" % index
		)
		await _wait_for_transition(demo)
		demo.call("_select_element", index)
		await _wait_for_transition(demo)


func test_selecting_element_expands_details_and_escape_collapses() -> void:
	var demo = DEMO_SCENE.instantiate()
	add_child_autoqfree(demo)
	await wait_process_frames(2)

	var cards: Array = demo.get("_cards")
	var detail_labels: Array = demo.get("_detail_labels")
	_assert(cards.size() == 118, "Element details should be available for all 118 cards")
	_assert(
		(demo.call("_element_details", 1) as String).contains("MASS  1.008 u"),
		"Hydrogen details should use its supplied atomic mass"
	)
	_assert(
		(demo.call("_element_details", 118) as String).contains("MASS  294 u"),
		"The physical-property data should cover the last element too"
	)
	demo.call("_select_element", 0)
	await wait_process_frames(10)
	_assert(demo.get("_selected_index") == 0, "Selecting a card should mark it as expanded")
	_assert((cards[0] as Node3D).scale.x > 1.0, "The selected card should enlarge")
	_assert((detail_labels[0] as Label3D).scale.x > 0.0, "The selected card should reveal its properties")
	await _wait_for_transition(demo)

	var escape := InputEventKey.new()
	escape.pressed = true
	escape.keycode = KEY_ESCAPE
	demo.call("_unhandled_input", escape)
	await _wait_for_transition(demo)
	_assert(demo.get("_selected_index") == -1, "Escape should collapse the selected card")
	_assert((detail_labels[0] as Label3D).scale.is_zero_approx(), "Collapsed cards should hide their property text")

	demo.call("_select_element", 0)
	await _wait_for_transition(demo)
	demo.call("_change_layout", &"sphere")
	_assert(demo.get("_selected_index") == -1, "Changing layouts should clear an expanded card")
	await _wait_for_transition(demo)


func test_selected_sphere_element_turns_its_front_toward_camera() -> void:
	var demo = DEMO_SCENE.instantiate()
	add_child_autoqfree(demo)
	await wait_process_frames(2)

	demo.call("_change_layout", &"sphere")
	await _wait_for_transition(demo)
	var cards: Array = demo.get("_cards")
	var card := cards[25] as Node3D
	var camera := demo.get("_camera") as Camera3D
	var initial_position := card.global_position
	demo.call("_select_element", 25)
	await _wait_for_transition(demo)

	var to_camera := (camera.global_position - card.global_position).normalized()
	var card_front := card.global_basis.z.normalized()
	_assert(
		card_front.dot(to_camera) > 0.995,
		"An expanded sphere element should face directly toward the camera"
	)
	_assert(
		card.global_position.distance_to(initial_position) > 0.5,
		"The selected sphere element should move forward for an unobstructed view"
	)
func _wait_for_transition(demo: Node) -> void:
	var waited_frames := 0
	while demo.get("_transitioning") and waited_frames < 180:
		await wait_process_frames(1)
		waited_frames += 1
	_assert(not demo.get("_transitioning"), "The periodic table transition should complete")


func _assert(condition: bool, message: String) -> void:
	assert_true(condition, message)