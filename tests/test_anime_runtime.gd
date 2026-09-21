extends GutTest

const ANIME_SCRIPT = preload("res://addons/animegodot/runtime/anime.gd")

func test_to_callbacks() -> void:
	var target := Node2D.new()
	add_child_autoqfree(target)
	var callback_state := {"started": false, "completed": false, "update_count": 0}
	var tween = ANIME_SCRIPT.to(target, {
		"position": Vector2(120.0, 80.0),
		"duration": 0.03,
		"ease": ANIME_SCRIPT.EASE_OUT_QUAD,
		"on_start": func() -> void: callback_state["started"] = true,
		"on_update": func(_progress: float) -> void: callback_state["update_count"] += 1,
		"on_complete": func() -> void: callback_state["completed"] = true,
	})
	await _wait_for_tween(tween)
	_expect(tween != null and tween.has_signal("completed"), "Anime.to should return an animation handle")
	_expect(callback_state["started"], "on_start should run")
	_expect(callback_state["completed"], "on_complete should run")
	_expect(callback_state["update_count"] > 0, "on_update should run")
	_expect(target.position == Vector2(120.0, 80.0), "Anime.to should reach the final value")
	target.queue_free()


func test_from_and_set() -> void:
	var target := Node2D.new()
	add_child_autoqfree(target)
	target.position = Vector2(40.0, 30.0)
	var from_tween = ANIME_SCRIPT.from(target, {
		"position": Vector2.ZERO,
		"duration": 0.03,
	})
	_expect(target.position == Vector2.ZERO, "Anime.from should apply its starting value immediately")
	await _wait_for_tween(from_tween)
	_expect(target.position == Vector2(40.0, 30.0), "Anime.from should restore the captured value")

	var set_tween = ANIME_SCRIPT.set_value(target, {
		"position": Vector2(10.0, 15.0),
		"duration": 1.0,
	})
	_expect(target.position == Vector2(10.0, 15.0), "Anime.set should apply immediately")
	_expect(set_tween.is_finished(), "Anime.set should return a finished tween")
	target.queue_free()


func test_from_to() -> void:
	var target := Node2D.new()
	add_child_autoqfree(target)
	target.position = Vector2(20.0, 10.0)
	var tween = ANIME_SCRIPT.from_to(
		target,
		{"position": Vector2(-30.0, -15.0)},
		{"position": Vector2(80.0, 45.0), "duration": 0.03}
	)
	_expect(target.position == Vector2(-30.0, -15.0), "Anime.from_to should apply its start value immediately")
	await _wait_for_tween(tween)
	_expect(target.position == Vector2(80.0, 45.0), "Anime.from_to should reach its end value")
	target.queue_free()


func test_keyframes_and_per_property_options() -> void:
	var target := Node2D.new()
	add_child_autoqfree(target)
	target.modulate.a = 0.0
	var tween = ANIME_SCRIPT.to(target, {
		"position": {
			"keyframes": [Vector2(20.0, 0.0), Vector2(80.0, 40.0)],
			"duration": 0.04,
			"ease": ANIME_SCRIPT.EASE_LINEAR,
		},
		"modulate:a": {
			"value": 1.0,
			"duration": 0.02,
			"delay": 0.01,
			"ease": ANIME_SCRIPT.EASE_LINEAR,
		},
	})
	await _wait_for_tween(tween)
	_expect(target.position == Vector2(80.0, 40.0), "Keyframes should reach the final keyframe")
	_expect(is_equal_approx(target.modulate.a, 1.0), "Per-property timing should reach the property value")
	target.queue_free()


func test_dynamic_interpolation_and_custom_interpolator() -> void:
	var midpoint_rect: Rect2 = ANIME_SCRIPT.interpolate(
		Rect2(Vector2.ZERO, Vector2(10.0, 20.0)),
		Rect2(Vector2(20.0, 40.0), Vector2(30.0, 50.0)),
		0.5
	)
	_expect(midpoint_rect.position == Vector2(10.0, 20.0), "Rect2 positions should interpolate dynamically")
	_expect(midpoint_rect.size == Vector2(20.0, 35.0), "Rect2 sizes should interpolate dynamically")

	var midpoint_vector: Vector2i = ANIME_SCRIPT.interpolate(Vector2i.ZERO, Vector2i(5, 9), 0.5)
	_expect(midpoint_vector == Vector2i(3, 5), "Integer vectors should interpolate with integer rounding")
	var midpoint_transform: Transform2D = ANIME_SCRIPT.interpolate(
		Transform2D(0.0, Vector2.ZERO),
		Transform2D(0.0, Vector2(20.0, 40.0)),
		0.5
	)
	_expect(midpoint_transform.origin == Vector2(10.0, 20.0), "Transforms should interpolate dynamically")

	var midpoint_array: Array = ANIME_SCRIPT.interpolate(
		[0.0, Vector2.ZERO],
		[10.0, Vector2(10.0, 20.0)],
		0.5
	)
	_expect(is_equal_approx(float(midpoint_array[0]), 5.0), "Arrays should interpolate numeric elements")
	_expect(midpoint_array[1] == Vector2(5.0, 10.0), "Arrays should interpolate nested elements")
	var midpoint_dictionary: Dictionary = ANIME_SCRIPT.interpolate(
		{"value": 0.0},
		{"value": 10.0},
		0.5
	)
	_expect(is_equal_approx(float(midpoint_dictionary["value"]), 5.0), "Dictionaries should interpolate values")

	var target := Node2D.new()
	add_child_autoqfree(target)
	var state := {"calls": 0}
	var custom_interpolator := func(from_value: Variant, to_value: Variant, weight: float) -> Variant:
		state["calls"] += 1
		return Vector2(
			lerpf(from_value.x, to_value.x, weight * weight),
			lerpf(from_value.y, to_value.y, weight * weight)
		)
	var tween = ANIME_SCRIPT.to(target, {
		"position": {
			"value": Vector2(20.0, 10.0),
			"duration": 0.03,
			"interpolate": custom_interpolator,
		},
	})
	await _wait_for_tween(tween)
	_expect(state["calls"] > 0, "Custom interpolators should be called for tween tracks")
	_expect(target.position == Vector2(20.0, 10.0), "Custom interpolators should reach the final value")
	target.queue_free()


func test_tween_controls() -> void:
	var target := Node2D.new()
	add_child_autoqfree(target)
	var tween = ANIME_SCRIPT.to(target, {
		"position:x": 100.0,
		"duration": 0.12,
		"ease": ANIME_SCRIPT.EASE_LINEAR,
	})
	await wait_process_frames(2)
	tween.pause()
	var paused_position: float = tween.get_position()
	await wait_process_frames(2)
	_expect(is_equal_approx(tween.get_position(), paused_position), "A tween should keep its position while paused")
	tween.seek(0.06)
	_expect(target.position.x > 0.0 and target.position.x < 100.0, "A tween should seek to an intermediate value")
	tween.resume()
	await _wait_for_tween(tween)
	_expect(target.position.x == 100.0, "A resumed tween should reach its end")
	tween.reverse()
	await _wait_for_tween(tween)
	_expect(is_zero_approx(target.position.x), "A reversed tween should return to its start")
	tween.restart()
	await _wait_for_tween(tween)
	_expect(target.position.x == 100.0, "A restarted tween should replay from its start")
	target.queue_free()


func test_repeat_and_yoyo() -> void:
	var target := Node2D.new()
	add_child_autoqfree(target)
	var tween = ANIME_SCRIPT.to(target, {
		"position:x": 100.0,
		"duration": 0.02,
		"repeat": 1,
		"yoyo": true,
	})
	await _wait_for_tween(tween)
	_expect(is_zero_approx(target.position.x), "A yoyo repeat should finish at its starting value")
	target.queue_free()


func test_repeat_delay_and_direction() -> void:
	var target := Node2D.new()
	add_child_autoqfree(target)
	var tween = ANIME_SCRIPT.to(target, {
		"position:x": 100.0,
		"duration": 0.02,
		"repeat": 1,
		"repeat_delay": 0.02,
		"direction": "alternate",
	})
	await _wait_for_tween(tween)
	_expect(is_zero_approx(target.position.x), "Alternate repeat direction should finish at the start")
	target.queue_free()


func test_target_arrays_and_stagger() -> void:
	var first := Node2D.new()
	var second := Node2D.new()
	add_child_autoqfree(first)
	add_child_autoqfree(second)
	var tweens = ANIME_SCRIPT.to([first, second], {
		"position:x": 50.0,
		"duration": 0.02,
		"stagger": 0.02,
	})
	_expect(tweens is Array and tweens.size() == 2, "An array of targets should return two tweens")
	await _wait_for_tween(tweens[0])
	await _wait_for_tween(tweens[1])
	_expect(first.position.x == 50.0 and second.position.x == 50.0, "Target arrays should animate every target")
	first.queue_free()
	second.queue_free()


func test_rich_stagger_options() -> void:
	var first := Node2D.new()
	var second := Node2D.new()
	var third := Node2D.new()
	add_child_autoqfree(first)
	add_child_autoqfree(second)
	add_child_autoqfree(third)
	var tweens = ANIME_SCRIPT.to([first, second, third], {
		"position:x": 50.0,
		"duration": 0.02,
		"stagger": {
			"each": 0.01,
			"from": "center",
			"ease": ANIME_SCRIPT.EASE_OUT_QUAD,
		},
	})
	_expect(tweens is Array and tweens.size() == 3, "Rich stagger options should create one tween per target")
	for tween in tweens:
		await _wait_for_tween(tween)
	_expect(first.position.x == 50.0 and second.position.x == 50.0 and third.position.x == 50.0, "Rich stagger targets should complete")
	first.queue_free()
	second.queue_free()
	third.queue_free()


func test_context_cleanup() -> void:
	var test_owner := Node.new()
	add_child_autoqfree(test_owner)
	var context = ANIME_SCRIPT.context(test_owner)
	var tween = context.to(test_owner, {
		"process_mode": Node.PROCESS_MODE_DISABLED,
		"duration": 1.0,
	})
	test_owner.queue_free()
	await wait_process_frames(1)
	_expect(tween.is_finished(), "A context should clean up when its owner exits the tree")


func test_timeline_structure() -> void:
	var test_owner := Node2D.new()
	var first := Node2D.new()
	var second := Node2D.new()
	var parallel_target := Node2D.new()
	test_owner.add_child(first)
	test_owner.add_child(second)
	test_owner.add_child(parallel_target)
	add_child_autoqfree(test_owner)
	var callback_state := {"called": false}
	var timeline = ANIME_SCRIPT.timeline(test_owner)
	timeline.to(first, {"position:x": 100.0, "duration": 0.02})
	timeline.label(&"middle")
	timeline.to(second, {"position:x": 100.0, "duration": 0.02}, "middle")
	timeline.parallel(parallel_target, {"position:x": 100.0, "duration": 0.02})
	timeline.invoke(func() -> void: callback_state["called"] = true, ">")
	_expect(is_equal_approx(timeline.duration, 0.04), "Timeline labels and parallel entries should calculate duration")
	timeline.play()
	await _wait_for_timeline(timeline)
	_expect(first.position.x == 100.0, "Sequential timeline entry should complete")
	_expect(second.position.x == 100.0, "Label-positioned timeline entry should complete")
	_expect(parallel_target.position.x == 100.0, "Parallel timeline entry should complete")
	_expect(callback_state["called"], "Timeline call entry should execute")
	test_owner.queue_free()


func test_nested_timeline() -> void:
	var test_owner := Node2D.new()
	var target := Node2D.new()
	test_owner.add_child(target)
	add_child_autoqfree(test_owner)
	var child = ANIME_SCRIPT.timeline(test_owner)
	child.to(target, {"position:y": 80.0, "duration": 0.02})
	var parent = ANIME_SCRIPT.timeline(test_owner)
	parent.label(&"intro", 0.0)
	parent.add(child, "intro")
	parent.play()
	await _wait_for_timeline(parent)
	await wait_process_frames(1)
	_expect(target.position.y == 80.0, "Nested timeline should complete through its parent")
	test_owner.queue_free()


func test_nested_timeline_replay() -> void:
	var test_owner := Node2D.new()
	var target := Node2D.new()
	test_owner.add_child(target)
	add_child_autoqfree(test_owner)
	var child = ANIME_SCRIPT.timeline(test_owner)
	child.to(target, {"position:x": 80.0, "duration": 0.02})
	var parent = ANIME_SCRIPT.timeline(test_owner)
	parent.add(child)
	parent.play()
	await _wait_for_timeline(parent)
	_expect(parent.is_finished(), "Nested parent should finish its first playback")

	parent.restart()
	await _wait_for_timeline(parent)
	_expect(parent.is_finished() and is_equal_approx(target.position.x, 80.0), "Nested parent should restart its child")

	parent.reverse()
	await _wait_for_timeline(parent)
	_expect(parent.is_finished() and is_zero_approx(target.position.x), "Nested parent should reverse its child")

	parent.reverse()
	await _wait_for_timeline(parent)
	_expect(parent.is_finished() and is_equal_approx(target.position.x, 80.0), "Nested parent should reverse back through its child")
	test_owner.queue_free()


func test_timeline_controls() -> void:
	var test_owner := Node2D.new()
	var target := Node2D.new()
	test_owner.add_child(target)
	add_child_autoqfree(test_owner)
	var timeline = ANIME_SCRIPT.timeline(test_owner)
	timeline.to(target, {"position:x": 100.0, "duration": 0.12})
	timeline.play()
	await wait_process_frames(1)
	timeline.pause()
	var paused_position := target.position.x
	await wait_process_frames(1)
	await wait_process_frames(1)
	_expect(is_equal_approx(target.position.x, paused_position), "Paused timeline should stop its child tweens")
	timeline.resume()
	await _wait_for_timeline(timeline)
	_expect(target.position.x == 100.0, "Resumed timeline should complete")

	timeline.reverse()
	await _wait_for_timeline(timeline)
	_expect(is_zero_approx(target.position.x), "Reverse should return the target to its initial state")

	timeline.restart()
	await _wait_for_timeline(timeline)
	_expect(target.position.x == 100.0, "Restart should replay from the initial state")

	timeline.seek(0.06)
	_expect(target.position.x > 0.0 and target.position.x < 100.0, "Seek should sample an intermediate timeline value")
	var seeked_timeline_position: float = timeline.get_position()
	timeline.resume()
	var seek_frames := 12
	while timeline.get_position() <= seeked_timeline_position and not timeline.is_finished() and seek_frames > 0:
		await wait_process_frames(1)
		seek_frames -= 1
	_expect(
		timeline.get_position() > seeked_timeline_position,
		"A timeline should resume from its sought position"
	)
	await _wait_for_timeline(timeline)
	timeline.time_scale = 2.0
	timeline.restart()
	await _wait_for_timeline(timeline)
	_expect(target.position.x == 100.0, "Time-scaled timeline should complete")
	test_owner.queue_free()


func test_timeline_options() -> void:
	var test_owner := Node2D.new()
	var target := Node2D.new()
	test_owner.add_child(target)
	add_child_autoqfree(test_owner)
	var state := {"started": 0, "completed": 0}
	var timeline = ANIME_SCRIPT.timeline(test_owner, {
		"defaults": {"duration": 0.02, "ease": ANIME_SCRIPT.EASE_LINEAR},
		"repeat": 1,
		"repeat_delay": 0.01,
		"yoyo": true,
		"on_start": func() -> void: state["started"] += 1,
		"on_complete": func() -> void: state["completed"] += 1,
	})
	timeline.to(target, {"position:x": 100.0})
	_expect(is_equal_approx(timeline.duration, 0.02), "Timeline defaults should configure child tween duration")
	timeline.play()
	await _wait_for_timeline(timeline)
	_expect(is_zero_approx(target.position.x), "A yoyo timeline repeat should finish at its start")
	_expect(state["started"] == 1 and state["completed"] == 1, "Timeline callbacks should fire once per playback")
	test_owner.queue_free()


func test_timeline_uses_dynamic_track_data() -> void:
	var test_owner := Node2D.new()
	var target := Node2D.new()
	test_owner.add_child(target)
	add_child_autoqfree(test_owner)
	var timeline = ANIME_SCRIPT.timeline(test_owner)
	timeline.to(target, {
		"position": {
			"keyframes": [Vector2(40.0, 10.0), Vector2(80.0, 20.0)],
			"duration": 0.04,
			"ease": ANIME_SCRIPT.EASE_LINEAR,
		},
	})
	timeline.play()
	await _wait_for_timeline(timeline)
	_expect(target.position == Vector2(80.0, 20.0), "Timelines should finish dynamic keyframe tracks")
	timeline.seek(0.02)
	_expect(target.position == Vector2(40.0, 10.0), "Timeline seek should sample dynamic keyframe tracks")
	test_owner.queue_free()


func test_native_tween_process_options() -> void:
	var target := Node2D.new()
	add_child_autoqfree(target)
	var previous_time_scale := Engine.time_scale
	Engine.time_scale = 0.0
	var _ignored_tween = ANIME_SCRIPT.to(target, {
		"position:x": 40.0,
		"duration": 0.03,
		"ignore_time_scale": true,
	})
	await wait_process_frames(4)
	_expect(target.position.x == 40.0, "Ignore-time-scale tweens should run while Engine.time_scale is zero")
	Engine.time_scale = previous_time_scale

	var physics_tween = ANIME_SCRIPT.to(target, {
		"position:y": 25.0,
		"duration": 0.03,
		"process_mode": ANIME_SCRIPT.TWEEN_PROCESS_PHYSICS,
	})
	await _wait_for_tween(physics_tween)
	_expect(target.position.y == 25.0, "Physics-process tweens should complete on physics frames")
	target.queue_free()


func test_motion_path_controls() -> void:
	var target := Node2D.new()
	add_child_autoqfree(target)
	var curve := Curve2D.new()
	curve.add_point(Vector2.ZERO)
	curve.add_point(Vector2(100.0, 0.0))
	var path_tween = ANIME_SCRIPT.motion_path(target, curve, {"duration": 0.12})
	await wait_process_frames(2)
	path_tween.pause()
	var paused_position: float = path_tween.get_position()
	await wait_process_frames(2)
	_expect(is_equal_approx(path_tween.get_position(), paused_position), "A motion-path tween should pause its position")
	path_tween.seek(0.06)
	_expect(target.position.x > 0.0 and target.position.x < 100.0, "A motion-path tween should seek to an intermediate position")
	path_tween.resume()
	await _wait_for_tween(path_tween)
	_expect(is_equal_approx(target.position.x, 100.0), "A resumed motion-path tween should reach its endpoint")
	path_tween.reverse()
	await _wait_for_tween(path_tween)
	_expect(is_zero_approx(target.position.x), "A reversed motion-path tween should return to its start")
	path_tween.restart()
	await _wait_for_tween(path_tween)
	_expect(is_equal_approx(target.position.x, 100.0), "A restarted motion-path tween should replay")
	target.queue_free()


func test_timeline_autoplay() -> void:
	var test_owner := Node2D.new()
	var target := Node2D.new()
	test_owner.add_child(target)
	add_child_autoqfree(test_owner)
	var timeline = ANIME_SCRIPT.timeline(test_owner, {
		"defaults": {"duration": 0.02, "ease": ANIME_SCRIPT.EASE_LINEAR},
		"autoplay": true,
	})
	timeline.to(target, {"position:x": 25.0})
	await wait_process_frames(4)
	_expect(target.position.x == 25.0, "An autoplay timeline should begin after entries are added")
	test_owner.queue_free()


func test_overwrite_modes() -> void:
	var target := Node2D.new()
	add_child_autoqfree(target)
	target.modulate = Color.WHITE
	var first = ANIME_SCRIPT.to(target, {
		"position": Vector2(100.0, 0.0),
		"rotation": TAU,
		"modulate:a": 0.0,
		"duration": 0.12,
		"overwrite": ANIME_SCRIPT.OVERWRITE_NONE,
	})
	await wait_process_frames(1)
	var replacement = ANIME_SCRIPT.to(target, {
		"position": Vector2(25.0, 0.0),
		"duration": 0.02,
		"overwrite": ANIME_SCRIPT.OVERWRITE_AUTO,
	})
	await _wait_for_tween(replacement)
	_expect(first.active, "Auto overwrite should preserve non-conflicting property tracks")
	await _wait_for_tween(first)
	_expect(target.position == Vector2(25.0, 0.0), "Auto overwrite should leave the replacement position")
	_expect(is_equal_approx(target.rotation, TAU), "Auto overwrite should preserve the old rotation track")
	_expect(is_zero_approx(target.modulate.a), "Auto overwrite should preserve the old alpha track")

	var none_a = ANIME_SCRIPT.to(target, {
		"rotation": TAU * 2.0,
		"duration": 0.04,
		"overwrite": ANIME_SCRIPT.OVERWRITE_NONE,
	})
	var none_b = ANIME_SCRIPT.to(target, {
		"rotation": TAU * 3.0,
		"duration": 0.04,
		"overwrite": ANIME_SCRIPT.OVERWRITE_NONE,
	})
	_expect(none_a.active and none_b.active, "None overwrite should allow overlapping tracks")
	await _wait_for_tween(none_a)
	await _wait_for_tween(none_b)

	var all_old = ANIME_SCRIPT.to(target, {
		"rotation": TAU * 4.0,
		"modulate:a": 1.0,
		"duration": 0.12,
		"overwrite": ANIME_SCRIPT.OVERWRITE_NONE,
	})
	await wait_process_frames(1)
	var all_new = ANIME_SCRIPT.to(target, {
		"position": Vector2.ZERO,
		"duration": 0.02,
		"overwrite": ANIME_SCRIPT.OVERWRITE_ALL,
	})
	_expect(all_old.is_finished(), "All overwrite should kill every existing target track")
	await _wait_for_tween(all_new)
	target.queue_free()


func test_cleanup_callbacks() -> void:
	var target := Node2D.new()
	add_child_autoqfree(target)
	var state := {"kill_count": 0}
	var target_tween = ANIME_SCRIPT.to(target, {
		"position": Vector2(100.0, 0.0),
		"duration": 1.0,
		"on_kill": func() -> void: state["kill_count"] += 1,
	})
	target.queue_free()
	await wait_process_frames(1)
	_expect(target_tween.is_finished(), "Freed targets should finish their active tween")
	_expect(state["kill_count"] == 0, "Target cleanup should not invoke user kill callbacks")

	var test_owner := Node.new()
	add_child_autoqfree(test_owner)
	var context = ANIME_SCRIPT.context(test_owner)
	var context_tween = context.to(test_owner, {
		"process_mode": Node.PROCESS_MODE_DISABLED,
		"duration": 1.0,
		"on_kill": func() -> void: state["kill_count"] += 1,
	})
	context.dispose()
	_expect(context_tween.is_finished(), "Disposed contexts should finish their active tween")
	_expect(state["kill_count"] == 0, "Context cleanup should not invoke user kill callbacks")
	test_owner.queue_free()


func test_phase5_features() -> void:
	var test_owner := Node2D.new()
	var target := Node2D.new()
	target.name = "Target"
	var animation_player := AnimationPlayer.new()
	test_owner.add_child(target)
	test_owner.add_child(animation_player)
	add_child_autoqfree(test_owner)

	var curve := Curve2D.new()
	curve.add_point(Vector2.ZERO)
	curve.add_point(Vector2(100.0, 0.0))
	var path_tween = ANIME_SCRIPT.motion_path(target, curve, {
		"duration": 0.03,
		"align_to_path": true,
	})
	await _wait_for_tween(path_tween)
	_expect(is_equal_approx(target.position.x, 100.0), "Motion path should reach the curve endpoint")
	_expect(is_zero_approx(target.position.y), "Motion path should preserve the curve endpoint axis")
	_expect(is_zero_approx(target.rotation), "Path alignment should follow the curve tangent")
	var invalid_path := Node2D.new()
	var invalid_path_tween = ANIME_SCRIPT.motion_path(target, invalid_path, {"duration": 0.02})
	_expect(invalid_path_tween.is_finished(), "Invalid motion paths should finish as killed handles")
	invalid_path.queue_free()

	var shader := Shader.new()
	shader.code = "shader_type canvas_item; uniform float glow; void fragment() { COLOR = vec4(glow); }"
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter(&"glow", 0.0)
	target.material = material
	var shader_tween = ANIME_SCRIPT.to(target, {
		"material:shader_parameter/glow": 1.0,
		"duration": 0.02,
	})
	await _wait_for_tween(shader_tween)
	_expect(is_equal_approx(float(material.get_shader_parameter(&"glow")), 1.0), "Shader parameters should be tweenable")

	_expect(is_equal_approx(float(ANIME_SCRIPT.interpolate(0.0, 10.0, 0.5)), 5.0), "Numeric interpolation should be linear")
	_expect(ANIME_SCRIPT.interpolate(Color.BLACK, Color.WHITE, 0.5).is_equal_approx(Color(0.5, 0.5, 0.5, 1.0)), "Color interpolation should blend channels")
	_expect(is_equal_approx(float(ANIME_SCRIPT.bezier(0.0, 10.0, 10.0, 20.0, 0.5)), 10.0), "Bezier interpolation should calculate a cubic midpoint")
	_expect(float(ANIME_SCRIPT.spring(0.0, 10.0, 1.0)) > 9.0, "Spring interpolation should settle toward its target")

	var animation := ANIME_SCRIPT.animation_from_properties(
		animation_player,
		target,
		{"position": Vector2(50.0, 20.0)},
		0.5
	)
	_expect(animation.get_track_count() == 1, "Animation conversion should create one value track")
	_expect(String(animation.track_get_path(0)) == "Target:position", "Animation conversion should target the requested property from the AnimationPlayer root")
	var invalid_animation := ANIME_SCRIPT.animation_from_properties(
		animation_player,
		target,
		{"missing_property": 1.0},
		0.5
	)
	_expect(invalid_animation.get_track_count() == 0, "Invalid AnimationPlayer properties should be skipped safely")
	var installed := ANIME_SCRIPT.add_animation(
		animation_player,
		&"move",
		target,
		{"position": Vector2(50.0, 20.0)},
		0.5
	)
	_expect(installed.get_track_count() == 1, "AnimationPlayer conversion should return the installed animation")
	_expect(animation_player.has_animation_library(&""), "AnimationPlayer conversion should create a default library")
	_expect(animation_player.get_animation_library(&"").has_animation(&"move"), "AnimationPlayer conversion should register the animation")
	test_owner.queue_free()


func _wait_for_timeline(timeline: Variant) -> void:
	if timeline != null and not timeline.is_finished():
		var timeout_frames := 60
		while not timeline.is_finished() and timeout_frames > 0:
			await wait_process_frames(1)
			timeout_frames -= 1


func _wait_for_tween(tween: Variant) -> void:
	if tween != null and not tween.is_finished():
		await tween.completed


func _expect(condition: bool, message: String) -> void:
	assert_true(condition, message)