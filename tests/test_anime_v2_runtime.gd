extends GutTest

const CONTROL_SCRIPT = preload("res://addons/animegodot/runtime/anime_control.gd")
const POSITION_SCRIPT = preload("res://addons/animegodot/runtime/anime_position.gd")
const TIMELINE_RUNTIME_SCRIPT = preload("res://addons/animegodot/runtime/anime_timeline_runtime.gd")
const TWEEN_RUNTIME_SCRIPT = preload("res://addons/animegodot/runtime/anime_tween_runtime.gd")
const ANIME_SCRIPT = preload("res://addons/animegodot/runtime/anime.gd")


func test_typed_tween_plays_and_emits_lifecycle() -> void:
	var target := Control.new()
	add_child_autoqfree(target)
	var callback_state := {"started": false, "completed": false}
	var tween = TWEEN_RUNTIME_SCRIPT.new(target)
	tween.options.duration = 0.03
	tween.options.ease = AnimeEase.LINEAR
	tween.options.on_start = func() -> void: callback_state["started"] = true
	tween.options.on_complete = func() -> void: callback_state["completed"] = true
	tween.track(CONTROL_SCRIPT.position_to(Vector2(120.0, 80.0)))
	tween.play()
	await tween.completed

	_expect(target.position == Vector2(120.0, 80.0), "A typed position track should reach its endpoint")
	_expect(callback_state["started"], "Typed tween on_start should fire")
	_expect(callback_state["completed"], "Typed tween on_complete should fire")
	_expect(tween.is_finished(), "A completed typed tween should report finished")


func test_from_tween_applies_start_immediately() -> void:
	var target := Control.new()
	add_child_autoqfree(target)
	target.position = Vector2(40.0, 30.0)
	var tween = TWEEN_RUNTIME_SCRIPT.new(target, TWEEN_RUNTIME_SCRIPT.Mode.FROM)
	tween.options.duration = 0.03
	tween.track(CONTROL_SCRIPT.position_to(Vector2.ZERO))
	tween.play()
	_expect(target.position == Vector2.ZERO, "A from tween should apply its start value immediately")
	await tween.completed
	_expect(target.position == Vector2(40.0, 30.0), "A from tween should end at the captured target value")


func test_typed_tween_seek_pause_reverse_and_restart() -> void:
	var target := Control.new()
	add_child_autoqfree(target)
	var tween = TWEEN_RUNTIME_SCRIPT.new(target)
	tween.options.duration = 0.12
	tween.options.ease = AnimeEase.LINEAR
	tween.track(CONTROL_SCRIPT.position_to(Vector2(100.0, 0.0)))
	tween.play()
	await wait_process_frames(1)
	tween.pause()
	var paused_position: float = target.position.x
	await wait_process_frames(2)
	_expect(is_equal_approx(target.position.x, paused_position), "A paused typed tween should stop updating")
	tween.seek(0.06)
	_expect(is_equal_approx(target.position.x, 50.0), "Typed tween seek should sample an intermediate value")
	tween.resume()
	await tween.completed
	_expect(is_equal_approx(target.position.x, 100.0), "A resumed typed tween should reach its endpoint")
	tween.reverse()
	await tween.completed
	_expect(is_zero_approx(target.position.x), "A reversed typed tween should return to its start")
	tween.restart()
	await tween.completed
	_expect(is_equal_approx(target.position.x, 100.0), "A restarted typed tween should replay")


func test_typed_timeline_sequences_by_label_and_invokes_callbacks() -> void:
	var scene_owner := Node2D.new()
	var first_target := Control.new()
	var second_target := Control.new()
	scene_owner.add_child(first_target)
	scene_owner.add_child(second_target)
	add_child_autoqfree(scene_owner)
	var first = TWEEN_RUNTIME_SCRIPT.new(first_target)
	first.options.duration = 0.02
	first.options.ease = AnimeEase.LINEAR
	first.track(CONTROL_SCRIPT.position_to(Vector2(40.0, 0.0)))
	var second = TWEEN_RUNTIME_SCRIPT.new(second_target)
	second.options.duration = 0.02
	second.options.ease = AnimeEase.LINEAR
	second.track(CONTROL_SCRIPT.position_to(Vector2(80.0, 0.0)))
	var state := {"called": false}
	var timeline = TIMELINE_RUNTIME_SCRIPT.new(scene_owner)
	timeline.add(first)
	var midpoint = timeline.add_label()
	timeline.add(second, POSITION_SCRIPT.after(midpoint, 0.01))
	timeline.invoke(func() -> void: state["called"] = true)
	_expect(is_equal_approx(timeline.duration, 0.05), "Typed timeline labels should position sequential entries")
	timeline.play()
	await timeline.completed

	_expect(first_target.position == Vector2(40.0, 0.0), "The first typed timeline tween should finish")
	_expect(second_target.position == Vector2(80.0, 0.0), "The label-positioned typed tween should finish")
	_expect(state["called"], "Typed timeline callbacks should run")


func test_typed_timeline_seek_samples_child_tween() -> void:
	var scene_owner := Node2D.new()
	var target := Control.new()
	scene_owner.add_child(target)
	add_child_autoqfree(scene_owner)
	var tween = TWEEN_RUNTIME_SCRIPT.new(target)
	tween.options.duration = 0.12
	tween.options.ease = AnimeEase.LINEAR
	tween.track(CONTROL_SCRIPT.position_to(Vector2(100.0, 0.0)))
	var timeline = TIMELINE_RUNTIME_SCRIPT.new(scene_owner)
	timeline.add(tween)
	timeline.seek(0.06)
	_expect(is_equal_approx(target.position.x, 50.0), "Typed timeline seek should sample child tracks")


func test_typed_overwrite_cancels_only_matching_property_identity() -> void:
	var target := Control.new()
	add_child_autoqfree(target)
	var original = TWEEN_RUNTIME_SCRIPT.new(target)
	original.options.duration = 0.08
	original.options.ease = AnimeEase.LINEAR
	original.track(CONTROL_SCRIPT.position_to(Vector2(100.0, 0.0)))
	original.track(AnimeCanvasItem.alpha_to(0.0))
	original.play()
	await wait_process_frames(1)

	var replacement = TWEEN_RUNTIME_SCRIPT.new(target)
	replacement.options.duration = 0.02
	replacement.options.overwrite = AnimeOverwrite.AUTO
	replacement.track(CONTROL_SCRIPT.position_to(Vector2(25.0, 0.0)))
	replacement.play()
	_expect(original.active, "Auto overwrite should preserve non-conflicting tracks")
	_expect(original.tracks.size() == 1, "Auto overwrite should remove only the matching accessor identity")
	await replacement.completed
	await original.completed
	_expect(target.position == Vector2(25.0, 0.0), "The replacement position track should win")
	_expect(is_zero_approx(target.modulate.a), "The original alpha track should continue to completion")


func test_interpolation_helpers_and_custom_interpolator() -> void:
	var midpoint: Vector2 = ANIME_SCRIPT.interpolate(Vector2.ZERO, Vector2(10.0, 20.0), 0.5)
	_expect(midpoint == Vector2(5.0, 10.0), "Built-in Vector2 interpolation should produce its midpoint")
	_expect(
		is_equal_approx(float(ANIME_SCRIPT.bezier(0.0, 10.0, 10.0, 20.0, 0.5)), 10.0),
		"The bezier helper should produce its cubic midpoint"
	)

	var target := Control.new()
	add_child_autoqfree(target)
	var state := {"calls": 0}
	var tween = TWEEN_RUNTIME_SCRIPT.new(target)
	tween.options.duration = 0.03
	var track = CONTROL_SCRIPT.position_to(Vector2(20.0, 10.0))
	track.options.interpolator = func(from_value: Variant, to_value: Variant, weight: float) -> Vector2:
		state["calls"] += 1
		return from_value.lerp(to_value, weight * weight)
	tween.track(track)
	tween.play()
	await tween.completed
	_expect(state["calls"] > 0, "A custom interpolator should be invoked for its typed track")
	_expect(target.position == Vector2(20.0, 10.0), "A custom interpolator should reach the typed endpoint")


func _expect(condition: bool, message: String) -> void:
	assert_true(condition, message)