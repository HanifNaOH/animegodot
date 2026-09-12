extends SceneTree

const ANIME_SCRIPT = preload("res://addons/animegodot/runtime/anime.gd")

var _failures: Array[String] = []


func _init() -> void:
	print("AnimeGodot runtime tests starting.")
	call_deferred("_run")


func _run() -> void:
	await _test_to_callbacks()
	await _test_from_and_set()
	await _test_repeat_and_yoyo()
	await _test_target_arrays_and_stagger()
	await _test_context_cleanup()
	await _test_timeline_structure()
	await _test_nested_timeline()
	await _test_timeline_controls()
	await _test_overwrite_modes()
	await _test_cleanup_callbacks()
	await _test_phase5_features()

	if _failures.is_empty():
		print("AnimeGodot runtime tests passed.")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)


func _test_to_callbacks() -> void:
	var target := Node2D.new()
	root.add_child(target)
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


func _test_from_and_set() -> void:
	var target := Node2D.new()
	root.add_child(target)
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


func _test_repeat_and_yoyo() -> void:
	var target := Node2D.new()
	root.add_child(target)
	var tween = ANIME_SCRIPT.to(target, {
		"position:x": 100.0,
		"duration": 0.02,
		"repeat": 1,
		"yoyo": true,
	})
	await _wait_for_tween(tween)
	_expect(is_zero_approx(target.position.x), "A yoyo repeat should finish at its starting value")
	target.queue_free()


func _test_target_arrays_and_stagger() -> void:
	var first := Node2D.new()
	var second := Node2D.new()
	root.add_child(first)
	root.add_child(second)
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


func _test_context_cleanup() -> void:
	var owner := Node.new()
	root.add_child(owner)
	var context = ANIME_SCRIPT.context(owner)
	var tween = context.to(owner, {
		"process_mode": Node.PROCESS_MODE_DISABLED,
		"duration": 1.0,
	})
	owner.queue_free()
	await process_frame
	_expect(tween.is_finished(), "A context should clean up when its owner exits the tree")


func _test_timeline_structure() -> void:
	var owner := Node2D.new()
	var first := Node2D.new()
	var second := Node2D.new()
	var parallel_target := Node2D.new()
	owner.add_child(first)
	owner.add_child(second)
	owner.add_child(parallel_target)
	root.add_child(owner)
	var callback_state := {"called": false}
	var timeline = ANIME_SCRIPT.timeline(owner)
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
	owner.queue_free()


func _test_nested_timeline() -> void:
	var owner := Node2D.new()
	var target := Node2D.new()
	owner.add_child(target)
	root.add_child(owner)
	var child = ANIME_SCRIPT.timeline(owner)
	child.to(target, {"position:y": 80.0, "duration": 0.02})
	var parent = ANIME_SCRIPT.timeline(owner)
	parent.label(&"intro", 0.0)
	parent.add(child, "intro")
	parent.play()
	await _wait_for_timeline(parent)
	await process_frame
	_expect(target.position.y == 80.0, "Nested timeline should complete through its parent")
	owner.queue_free()


func _test_timeline_controls() -> void:
	var owner := Node2D.new()
	var target := Node2D.new()
	owner.add_child(target)
	root.add_child(owner)
	var timeline = ANIME_SCRIPT.timeline(owner)
	timeline.to(target, {"position:x": 100.0, "duration": 0.12})
	timeline.play()
	await process_frame
	timeline.pause()
	var paused_position := target.position.x
	await process_frame
	await process_frame
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
	timeline.time_scale = 2.0
	timeline.restart()
	await _wait_for_timeline(timeline)
	_expect(target.position.x == 100.0, "Time-scaled timeline should complete")
	owner.queue_free()


func _test_overwrite_modes() -> void:
	var target := Node2D.new()
	root.add_child(target)
	target.modulate = Color.WHITE
	var first = ANIME_SCRIPT.to(target, {
		"position": Vector2(100.0, 0.0),
		"rotation": TAU,
		"modulate:a": 0.0,
		"duration": 0.12,
		"overwrite": ANIME_SCRIPT.OVERWRITE_NONE,
	})
	await process_frame
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
	await process_frame
	var all_new = ANIME_SCRIPT.to(target, {
		"position": Vector2.ZERO,
		"duration": 0.02,
		"overwrite": ANIME_SCRIPT.OVERWRITE_ALL,
	})
	_expect(all_old.is_finished(), "All overwrite should kill every existing target track")
	await _wait_for_tween(all_new)
	target.queue_free()


func _test_cleanup_callbacks() -> void:
	var target := Node2D.new()
	root.add_child(target)
	var state := {"kill_count": 0}
	var target_tween = ANIME_SCRIPT.to(target, {
		"position": Vector2(100.0, 0.0),
		"duration": 1.0,
		"on_kill": func() -> void: state["kill_count"] += 1,
	})
	target.queue_free()
	await process_frame
	_expect(target_tween.is_finished(), "Freed targets should finish their active tween")
	_expect(state["kill_count"] == 0, "Target cleanup should not invoke user kill callbacks")

	var owner := Node.new()
	root.add_child(owner)
	var context = ANIME_SCRIPT.context(owner)
	var context_tween = context.to(owner, {
		"process_mode": Node.PROCESS_MODE_DISABLED,
		"duration": 1.0,
		"on_kill": func() -> void: state["kill_count"] += 1,
	})
	context.dispose()
	_expect(context_tween.is_finished(), "Disposed contexts should finish their active tween")
	_expect(state["kill_count"] == 0, "Context cleanup should not invoke user kill callbacks")
	owner.queue_free()


func _test_phase5_features() -> void:
	var owner := Node2D.new()
	var target := Node2D.new()
	var animation_player := AnimationPlayer.new()
	owner.add_child(target)
	owner.add_child(animation_player)
	root.add_child(owner)

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
	_expect(String(animation.track_get_path(0)).ends_with(":position"), "Animation conversion should target the requested property")
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
	owner.queue_free()


func _wait_for_timeline(timeline: Variant) -> void:
	if timeline != null and not timeline.is_finished():
		await timeline.completed


func _wait_for_tween(tween: Variant) -> void:
	if tween != null and not tween.is_finished():
		await tween.completed


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)