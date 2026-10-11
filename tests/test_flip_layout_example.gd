extends GutTest

const DEMO_SCENE = preload("res://examples/flip_layout/flip_layout_demo.tscn")
const EXPAND_QUEUE_SCENE = preload("res://examples/flip_expand_queue/flip_expand_queue.tscn")


func test_create_layout_discovers_children_and_updates_repeatedly() -> void:
	var demo = DEMO_SCENE.instantiate()
	add_child_autoqfree(demo)
	await wait_process_frames(2)

	var grid := demo.get("_grid") as GridContainer
	var slots: Array = demo.get("_slots")
	var visuals: Array = demo.get("_visuals")
	var layout := Anime.create_layout(grid) as AnimeLayoutRuntime
	_assert(layout != null, "create_layout should return a reusable layout controller")

	layout.update(func(root: Control) -> void:
		(root as GridContainer).columns = 1
	)
	await layout.started
	await layout.completed
	for index in slots.size():
		var visual := visuals[index] as Control
		var slot := slots[index] as Control
		_assert(
			visual.global_position.is_equal_approx(slot.get_global_rect().position),
			"The automatic layout update should settle each discovered visual at its slot"
		)

	layout.update(func(root: Control) -> void:
		(root as GridContainer).columns = 3
	)
	await layout.started
	await layout.completed
	for index in slots.size():
		var visual := visuals[index] as Control
		var slot := slots[index] as Control
		_assert(
			visual.global_position.is_equal_approx(slot.get_global_rect().position),
			"The same layout object should support another update after completion"
		)


func test_layout_update_uses_per_transition_timing_and_stagger_options() -> void:
	var demo = DEMO_SCENE.instantiate()
	add_child_autoqfree(demo)
	await wait_process_frames(2)

	var grid := demo.get("_grid") as GridContainer
	var defaults := AnimeLayoutOptions.new()
	defaults.duration = 0.05
	var layout := Anime.create_layout(grid, defaults) as AnimeLayoutRuntime
	var transition_options := AnimeLayoutOptions.new()
	transition_options.duration = 0.3
	transition_options.delay = 0.02
	transition_options.stagger.each = 0.04

	layout.update(func(root: Control) -> void:
		(root as GridContainer).columns = 1
	, transition_options)
	await layout.started
	await wait_process_frames(1)

	var active_tweens: Array = layout.get("_active_tweens")
	_assert(active_tweens.size() == grid.get_child_count(), "Each discovered slot should have a tween")
	_assert(
		is_equal_approx((active_tweens[0] as AnimeTweenRuntime).options.duration, 0.3),
		"An update should use its supplied duration"
	)
	_assert(
		is_equal_approx((active_tweens[0] as AnimeTweenRuntime).options.delay, 0.02),
		"The first item should use the transition's base delay"
	)
	_assert(
		is_equal_approx((active_tweens[1] as AnimeTweenRuntime).options.delay, 0.06),
		"Subsequent items should include their stagger delay"
	)
	_assert(
		is_equal_approx(layout.options.duration, 0.05),
		"Per-transition options should not mutate the controller defaults"
	)
	await layout.completed

	layout.update(func(root: Control) -> void:
		(root as GridContainer).columns = 3
	)
	await layout.started
	await wait_process_frames(1)
	active_tweens = layout.get("_active_tweens")
	_assert(
		is_equal_approx((active_tweens[0] as AnimeTweenRuntime).options.duration, 0.05),
		"An update without overrides should use the controller's default duration"
	)
	_assert(
		is_zero_approx((active_tweens[0] as AnimeTweenRuntime).options.delay),
		"An update without overrides should use the controller's default delay"
	)
	await layout.completed


func test_layout_update_holds_first_state_before_the_next_frame() -> void:
	var root := Control.new()
	root.size = Vector2(320.0, 120.0)
	var slot := Control.new()
	slot.position = Vector2(8.0, 8.0)
	slot.size = Vector2(80.0, 40.0)
	var visual := Control.new()
	visual.name = "Visual"
	visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	slot.add_child(visual)
	root.add_child(slot)
	add_child_autoqfree(root)
	await wait_process_frames(1)

	var first_position := visual.global_position
	var layout := Anime.create_layout(root) as AnimeLayoutRuntime
	layout.update(func(_layout_root: Control) -> void:
		slot.position = Vector2(200.0, 8.0)
	)
	_assert(
		visual.global_position.is_equal_approx(first_position),
		"The visual should stay at its captured position immediately after the layout mutation"
	)
	await layout.started
	await layout.completed
	_assert(
		visual.global_position.is_equal_approx(slot.get_global_rect().position),
		"The visual should settle at its target after the transition"
	)


func test_overlapping_layout_updates_are_ignored_until_the_first_finishes() -> void:
	var demo = DEMO_SCENE.instantiate()
	add_child_autoqfree(demo)
	await wait_process_frames(2)

	var grid := demo.get("_grid") as GridContainer
	var layout := Anime.create_layout(grid) as AnimeLayoutRuntime
	var update_counts := {"first": 0, "second": 0}
	layout.update(func(root: Control) -> void:
		update_counts["first"] += 1
		(root as GridContainer).columns = 1
	)
	layout.update(func(root: Control) -> void:
		update_counts["second"] += 1
		(root as GridContainer).columns = 2
	)
	_assert(update_counts["first"] == 1, "The first update should run")
	_assert(update_counts["second"] == 0, "An overlapping update should be rejected")
	_assert(grid.columns == 1, "A rejected update should not overwrite the accepted mutation")

	await layout.completed


func test_spammed_reorder_keeps_one_transition_consistent() -> void:
	var demo = DEMO_SCENE.instantiate()
	add_child_autoqfree(demo)
	await wait_process_frames(2)

	var grid := demo.get("_grid") as GridContainer
	var reorder_button := demo.get("_reorder_button") as Button
	var original_mouse_filter := reorder_button.mouse_filter
	var original_last_slot: Control = grid.get_child(grid.get_child_count() - 1)
	demo.call("_on_reorder_pressed")
	var flip := demo.get("_active_flip") as AnimeLayoutRuntime
	_assert(demo.get("_transitioning"), "The first reorder should hold the transition lock")
	_assert(not reorder_button.disabled, "Layout controls should retain their enabled appearance during FLIP")
	_assert(
		reorder_button.mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"Layout controls should ignore mouse input during FLIP"
	)

	demo.call("_on_reorder_pressed")
	await flip.completed
	await wait_process_frames(1)
	_assert(grid.get_child(0) == original_last_slot, "A spammed reorder should not cancel or duplicate the accepted move")
	_assert(not demo.get("_transitioning"), "The transition lock should release after completion")
	_assert(not reorder_button.disabled, "Layout controls should remain enabled after FLIP")
	_assert(reorder_button.mouse_filter == original_mouse_filter, "Layout mouse input should be restored after FLIP")


func test_reorder_visually_interpolates_between_slot_positions() -> void:
	var demo = DEMO_SCENE.instantiate()
	add_child_autoqfree(demo)
	await wait_process_frames(2)

	var slots: Array = demo.get("_slots")
	var visuals: Array = demo.get("_visuals")
	var moving_visual := visuals.back() as Control
	var original_z_index := moving_visual.z_index
	var original_z_as_relative := moving_visual.z_as_relative
	var start_positions: Array[Vector2] = []
	for visual in visuals:
		start_positions.append((visual as Control).global_position)

	demo.call("_on_reorder_pressed")
	var flip := demo.get("_active_flip") as AnimeLayoutRuntime
	await flip.started
	await get_tree().create_timer(0.12).timeout
	_assert(
		moving_visual.z_index == AnimeLayoutRuntime.ELEVATED_Z_INDEX,
		"The moving card should draw above overlapping siblings"
	)
	_assert(not moving_visual.z_as_relative, "The moving card should use absolute draw order during FLIP")

	var observed_intermediate_position := false
	var observed_motion_progress := 0.0
	for index in slots.size():
		var start := start_positions[index]
		var destination := (slots[index] as Control).get_global_rect().position
		var current := (visuals[index] as Control).global_position
		if start.distance_to(destination) > 1.0:
			if current.distance_to(start) > 1.0 and current.distance_to(destination) > 1.0:
				observed_intermediate_position = true
				observed_motion_progress = start.distance_to(current) / start.distance_to(destination)
				break
	_assert(observed_intermediate_position, "A reordered card should be observed moving between its old and new slot")
	_assert(observed_motion_progress < 0.6, "The reordered card should not cover most of its path in the first 120 ms")

	await flip.completed
	_assert(moving_visual.z_index == original_z_index, "FLIP should restore the card's original z-index")
	_assert(
		moving_visual.z_as_relative == original_z_as_relative,
		"FLIP should restore the card's original relative z-index setting"
	)


func test_container_reflow_does_not_flash_layout_targets_before_flip() -> void:
	var demo = DEMO_SCENE.instantiate()
	add_child_autoqfree(demo)
	await wait_process_frames(2)

	var slots: Array = demo.get("_slots")
	var visuals: Array = demo.get("_visuals")
	var first_rects: Array[Rect2] = []
	for visual in visuals:
		first_rects.append((visual as Control).get_global_rect())

	demo.call("_on_list_pressed")
	var flip := demo.get("_active_flip") as AnimeLayoutRuntime
	await wait_process_frames(2)

	for index in visuals.size():
		var visual := visuals[index] as Control
		var current_rect := visual.get_global_rect()
		var target_rect := (slots[index] as Control).get_global_rect()
		var source_distance := (
			current_rect.position.distance_to(first_rects[index].position)
			+ current_rect.size.distance_to(first_rects[index].size)
		)
		var target_distance := (
			current_rect.position.distance_to(target_rect.position)
			+ current_rect.size.distance_to(target_rect.size)
		)
		_assert(
			source_distance < target_distance * 0.25,
			"Visual wrappers should remain near their first rects while Container reflow settles"
		)
	await flip.completed


func test_flip_captures_the_visible_wrapper_as_its_source_rect() -> void:
	var demo = DEMO_SCENE.instantiate()
	add_child_autoqfree(demo)
	await wait_process_frames(2)

	var slot := (demo.get("_slots") as Array).back() as Control
	var visual := (demo.get("_visuals") as Array).back() as Control
	visual.global_position += Vector2(0.0, 24.0)
	visual.size -= Vector2(40.0, 8.0)
	var source_rect := visual.get_global_rect()
	var options := AnimeLayoutOptions.new()
	options.ease = AnimeEase.LINEAR
	var flip := AnimeLayoutRuntime.new([AnimeLayoutItem.new(slot, visual)], options)

	flip.play()
	_assert(
		visual.z_index <= AnimeLayoutRuntime.ELEVATED_Z_INDEX,
		"Filtered FLIP items should remain within Godot's maximum z-index"
	)
	_assert(
		visual.global_position.is_equal_approx(source_rect.position),
		"FLIP should begin at the visible wrapper position instead of snapping to its layout slot"
	)
	_assert(
		visual.size.is_equal_approx(source_rect.size),
		"FLIP should begin at the visible wrapper size instead of snapping to its layout slot"
	)

	await flip.completed
	_assert(
		visual.global_position.is_equal_approx(slot.get_global_rect().position),
		"FLIP should finish at the layout slot position"
	)


func test_killing_before_play_restores_the_final_layout_rect() -> void:
	var demo = DEMO_SCENE.instantiate()
	add_child_autoqfree(demo)
	await wait_process_frames(2)

	var grid := demo.get("_grid") as GridContainer
	var slot := (demo.get("_slots") as Array).back() as Control
	var visual := (demo.get("_visuals") as Array).back() as Control
	var flip := AnimeLayoutRuntime.new([AnimeLayoutItem.new(slot, visual)])
	grid.columns = 1
	grid.queue_sort()
	await wait_process_frames(2)
	var final_rect := slot.get_global_rect()

	flip.hold_first_state()
	flip.kill()

	_assert(
		visual.global_position.is_equal_approx(final_rect.position)
			and visual.size.is_equal_approx(final_rect.size),
		"Cancellation before play should snap the wrapper to its final layout rectangle"
	)


func test_expandable_queue_animates_row_size_and_following_positions() -> void:
	var demo = EXPAND_QUEUE_SCENE.instantiate()
	add_child_autoqfree(demo)
	await wait_process_frames(2)

	var slots: Array = demo.get("_slots")
	var visuals: Array = demo.get("_visuals")
	var details: Array = demo.get("_details")
	var detail := details[0] as Label
	var first_size := (slots[0] as Control).size
	var second_position := (slots[1] as Control).get_global_rect().position
	demo.call("_toggle_details", 0)
	var flip := demo.get("_active_flip") as AnimeLayoutRuntime
	_assert(detail.visible, "The expanded detail should enter the layout immediately")
	_assert(is_zero_approx(detail.modulate.a), "New detail content should start transparent")
	await flip.started
	await get_tree().create_timer(0.12).timeout

	_assert(
		detail.modulate.a > 0.0 and detail.modulate.a < 1.0,
		"Expanded detail content should fade in during the FLIP transition"
	)
	var animated_size := (visuals[0] as Control).get_global_rect().size
	var target_size := (slots[0] as Control).get_global_rect().size
	_assert(animated_size.y > first_size.y, "The expanded card should grow during FLIP")
	_assert(animated_size.y < target_size.y, "The expanded card should interpolate instead of snapping to full height")
	_assert(
		(slots[1] as Control).get_global_rect().position.y > second_position.y,
		"Expanding a queue item should push following slots down"
	)

	await flip.completed
	_assert(is_equal_approx(detail.modulate.a, 1.0), "Expanded detail content should finish fully visible")
	_assert(
		(visuals[0] as Control).get_global_rect().size.is_equal_approx(target_size),
		"The expanded visual should settle at its resized slot"
	)


func test_list_layout_interpolates_position_and_size_without_scaling_content() -> void:
	var demo = DEMO_SCENE.instantiate()
	add_child_autoqfree(demo)
	await wait_process_frames(2)

	var slots: Array = demo.get("_slots")
	var visuals: Array = demo.get("_visuals")
	var first_rects: Array[Rect2] = []
	var original_scales: Array[Vector2] = []
	for slot in slots:
		first_rects.append((slot as Control).get_global_rect())
	for visual in visuals:
		original_scales.append((visual as Control).scale)

	demo.call("_on_list_pressed")
	var flip := demo.get("_active_flip") as AnimeLayoutRuntime
	await flip.started
	await wait_process_frames(1)
	var initial_size := first_rects[0].size
	var final_size := (slots[0] as Control).get_global_rect().size
	var first_sample_size := (visuals[0] as Control).get_global_rect().size
	_assert(
		first_sample_size.distance_to(initial_size) < initial_size.distance_to(final_size) * 0.1,
		"List wrappers should widen gently at the start instead of visibly stretching"
	)
	await get_tree().create_timer(0.18).timeout

	var observed_position_interpolation := false
	var observed_size_interpolation := false
	for index in slots.size():
		var first_rect := first_rects[index]
		var final_rect := (slots[index] as Control).get_global_rect()
		var visual := visuals[index] as Control
		if first_rect.position.distance_to(final_rect.position) > 1.0:
			if (
				visual.global_position.distance_to(first_rect.position) > 1.0
				and visual.global_position.distance_to(final_rect.position) > 1.0
			):
				observed_position_interpolation = true
		var current_size := visual.get_global_rect().size
		if first_rect.size.distance_to(final_rect.size) > 1.0:
			if current_size.distance_to(first_rect.size) > 1.0 and current_size.distance_to(final_rect.size) > 1.0:
				observed_size_interpolation = true
		_assert(
			visual.scale.is_equal_approx(original_scales[index]),
			"FLIP should not scale card text or other child content"
		)
	_assert(observed_position_interpolation, "List layout should animate cards between their old and new slots")
	_assert(observed_size_interpolation, "List layout should animate wrapper size without scaling its contents")

	await flip.completed


func test_repeated_mode_changes_interpolate_and_settle_at_slots_without_scaling_text() -> void:
	var demo = DEMO_SCENE.instantiate()
	add_child_autoqfree(demo)
	await wait_process_frames(2)

	var slots: Array = demo.get("_slots")
	var visuals: Array = demo.get("_visuals")
	var original_scales: Array[Vector2] = []
	for visual in visuals:
		original_scales.append((visual as Control).scale)
	for grid_mode in [false, true, false, true]:
		var first_rects: Array[Rect2] = []
		var first_visual_rects: Array[Rect2] = []
		for slot in slots:
			first_rects.append((slot as Control).get_global_rect())
		for visual in visuals:
			first_visual_rects.append((visual as Control).get_global_rect())

		demo.call("_change_layout", grid_mode)
		var flip := demo.get("_active_flip") as AnimeLayoutRuntime
		await wait_process_frames(1)
		for index in visuals.size():
			var visual_rect := (visuals[index] as Control).get_global_rect()
			var final_rect := (slots[index] as Control).get_global_rect()
			var position_travel := first_visual_rects[index].position.distance_to(final_rect.position)
			var size_travel := first_visual_rects[index].size.distance_to(final_rect.size)
			if position_travel > 1.0:
				_assert(
					visual_rect.position.distance_to(first_visual_rects[index].position) < position_travel * 0.5,
					"A wrapper should not snap to its target during reflow"
				)
			if size_travel > 1.0:
				_assert(
					visual_rect.size.distance_to(first_visual_rects[index].size) < size_travel * 0.5,
					"A wrapper size should not snap to its target during reflow"
				)
		if not flip.active:
			await flip.started
		await get_tree().create_timer(0.18).timeout

		var observed_position_interpolation := false
		var observed_size_interpolation := false
		for index in slots.size():
			var first_rect := first_rects[index]
			var final_rect := (slots[index] as Control).get_global_rect()
			var visual := visuals[index] as Control
			if first_rect.position.distance_to(final_rect.position) > 1.0:
				if (
					visual.global_position.distance_to(first_rect.position) > 1.0
					and visual.global_position.distance_to(final_rect.position) > 1.0
				):
					observed_position_interpolation = true
			var current_size := visual.get_global_rect().size
			if first_rect.size.distance_to(final_rect.size) > 1.0:
				if current_size.distance_to(first_rect.size) > 1.0 and current_size.distance_to(final_rect.size) > 1.0:
					observed_size_interpolation = true
		_assert(observed_position_interpolation, "Repeated mode changes should interpolate card positions")
		_assert(observed_size_interpolation, "Repeated mode changes should interpolate card sizes")

		await flip.completed
		await wait_process_frames(2)
		for index in slots.size():
			var visual := visuals[index] as Control
			var slot := slots[index] as Control
			var visual_position := visual.global_position
			var slot_position := slot.get_global_rect().position
			_assert(
				visual_position.is_equal_approx(slot_position),
				"Completed visual must align to slot: mode=%s index=%d visual=%s slot=%s delta=%s"
				% [str(grid_mode), index, str(visual_position), str(slot_position), str(visual_position - slot_position)]
			)
			_assert(
				visual.scale.is_equal_approx(original_scales[index]),
				"Each completed transition should preserve the original scale"
			)


func test_switching_to_grid_from_bottom_of_list_keeps_cards_visible() -> void:
	var demo = DEMO_SCENE.instantiate()
	demo.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	demo.size = Vector2(900.0, 600.0)
	add_child_autoqfree(demo)
	await wait_process_frames(2)

	demo.call("_on_list_pressed")
	var list_flip := demo.get("_active_flip") as AnimeLayoutRuntime
	await list_flip.completed
	await wait_process_frames(2)

	var scroll := demo.get_node("OuterMargin/Page/Scroll") as ScrollContainer
	var vertical_bar := scroll.get_v_scroll_bar()
	scroll.scroll_vertical = int(vertical_bar.max_value)
	await wait_process_frames(2)
	_assert(
		scroll.scroll_vertical > 0,
		"List should scroll in this test viewport: max=%f page=%f grid_size=%s scroll_size=%s"
		% [vertical_bar.max_value, vertical_bar.page, str(_grid_size(demo)), str(scroll.size)]
	)

	demo.call("_on_grid_pressed")
	var grid_flip := demo.get("_active_flip") as AnimeLayoutRuntime
	await wait_process_frames(1)
	var scroll_rect := scroll.get_global_rect()
	var visuals: Array = demo.get("_visuals")
	var held_visible_card_count := 0
	for visual in visuals:
		if scroll_rect.intersects((visual as Control).get_global_rect()):
			held_visible_card_count += 1
	_assert(held_visible_card_count > 0, "The scroll viewport should not go empty during the first Grid reflow frame")
	await grid_flip.completed
	await wait_process_frames(2)

	var visible_card_count := 0
	for visual in visuals:
		if scroll_rect.intersects((visual as Control).get_global_rect()):
			visible_card_count += 1
	_assert(
		visible_card_count == visuals.size(),
		"The first Grid transition from a scrolled List should show every card"
	)
	_assert(scroll.scroll_vertical == 0, "The Grid layout should reset the obsolete List scroll offset")


func test_list_remains_populated_after_scrolling_down_and_back_to_top() -> void:
	var demo = DEMO_SCENE.instantiate()
	demo.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	demo.size = Vector2(900.0, 600.0)
	add_child_autoqfree(demo)
	await wait_process_frames(2)

	demo.call("_on_list_pressed")
	var flip := demo.get("_active_flip") as AnimeLayoutRuntime
	await flip.completed
	await wait_process_frames(2)

	var scroll := demo.get_node("OuterMargin/Page/Scroll") as ScrollContainer
	var vertical_bar := scroll.get_v_scroll_bar()
	var visuals: Array = demo.get("_visuals")
	var slots: Array = demo.get("_slots")
	scroll.scroll_vertical = int(vertical_bar.max_value - vertical_bar.page)
	await wait_process_frames(2)
	_assert(scroll.scroll_vertical > 0, "The List should scroll below its top in the compact viewport")

	scroll.scroll_vertical = 0
	await wait_process_frames(2)
	var first_visual := visuals[0] as Control
	var first_slot := slots[0] as Control
	_assert(
		scroll.get_global_rect().intersects(first_visual.get_global_rect()),
		"The first card should be visible after scrolling back to the top"
	)
	_assert(
		first_visual.global_position.is_equal_approx(first_slot.get_global_rect().position),
		"The first card should remain aligned with its List slot after scrolling"
	)


func test_scroll_input_is_disabled_only_during_layout_transition() -> void:
	var demo = DEMO_SCENE.instantiate()
	demo.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	demo.size = Vector2(900.0, 600.0)
	add_child_autoqfree(demo)
	await wait_process_frames(2)

	var scroll := demo.get_node("OuterMargin/Page/Scroll") as ScrollContainer
	var original_mouse_filter := scroll.mouse_filter
	var original_vertical_filter := scroll.get_v_scroll_bar().mouse_filter
	var original_horizontal_filter := scroll.get_h_scroll_bar().mouse_filter
	demo.call("_on_list_pressed")
	var flip := demo.get("_active_flip") as AnimeLayoutRuntime
	_assert(scroll.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Scroll input should lock during FLIP")
	_assert(
		scroll.get_v_scroll_bar().mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"Vertical scrollbar input should lock during FLIP"
	)
	var wheel_event := InputEventMouseButton.new()
	wheel_event.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel_event.pressed = true
	wheel_event.position = scroll.get_global_rect().get_center()
	get_viewport().push_input(wheel_event)
	await wait_process_frames(1)
	_assert(scroll.scroll_vertical == 0, "Wheel input should not move the viewport during FLIP")

	await flip.completed
	await wait_process_frames(1)
	_assert(scroll.mouse_filter == original_mouse_filter, "Scroll input should be restored after FLIP")
	_assert(
		scroll.get_v_scroll_bar().mouse_filter == original_vertical_filter,
		"Vertical scrollbar input should be restored after FLIP"
	)
	_assert(
		scroll.get_h_scroll_bar().mouse_filter == original_horizontal_filter,
		"Horizontal scrollbar input should be restored after FLIP"
	)


func _grid_size(demo: Control) -> Vector2:
	return (demo.get("_grid") as Control).size


func _assert(condition: bool, message: String) -> void:
	assert_true(condition, message)