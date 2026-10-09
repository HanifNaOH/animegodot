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
	var callback_state := {"reverse_completed": false}
	var tween = TWEEN_RUNTIME_SCRIPT.new(target)
	tween.options.duration = 0.12
	tween.options.ease = AnimeEase.LINEAR
	tween.options.on_reverse_complete = func() -> void: callback_state["reverse_completed"] = true
	tween.track(CONTROL_SCRIPT.position_to(Vector2(100.0, 0.0)))
	tween.play()
	_expect(tween.is_active(), "An unpaused playing tween should report active")
	await wait_process_frames(1)
	tween.pause()
	_expect(not tween.is_active(), "A paused tween should not report active")
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
	_expect(callback_state["reverse_completed"], "Reverse completion should invoke its dedicated callback")
	tween.restart()
	await tween.completed
	_expect(is_equal_approx(target.position.x, 100.0), "A restarted typed tween should replay")


func test_tween_progress_queries_respect_per_track_repeats() -> void:
	var target := Control.new()
	add_child_autoqfree(target)
	var tween = TWEEN_RUNTIME_SCRIPT.new(target)
	tween.options.duration = 1.0
	var track = CONTROL_SCRIPT.position_to(Vector2(100.0, 0.0))
	track.options.duration = 0.5
	track.options.delay = 0.1
	track.options.repeat_count = 1
	track.options.repeat_delay = 0.2
	track.options.yoyo = AnimeTrackOptions.Toggle.ENABLED
	tween.track(track)

	_expect(is_equal_approx(tween.get_total_duration(), 1.3), "Tween total duration should include track delay and repeats")
	tween.seek_progress(0.75)
	_expect(tween.get_track_iteration(track) == 2, "Track iteration should be one-based and respect its repeat override")
	_expect(is_equal_approx(tween.get_track_progress(track), 0.65), "Track progress should account for the active yoyo iteration")
	_expect(is_equal_approx(tween.get_progress(), 0.75), "Normalized seeking should preserve total tween progress")


func test_total_duration_refreshes_after_options_change() -> void:
	var target := Control.new()
	add_child_autoqfree(target)
	var tween = TWEEN_RUNTIME_SCRIPT.new(target)
	tween.track(CONTROL_SCRIPT.position_to(Vector2(50.0, 0.0)))
	tween.options.duration = 0.4
	tween.options.delay = 0.1
	_expect(is_equal_approx(tween.get_total_duration(), 0.5), "Total duration should reflect options changed after track attachment")


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


func test_timeline_total_progress_seeks_repeat_and_yoyo_cycles() -> void:
	var scene_owner := Node2D.new()
	var target := Control.new()
	scene_owner.add_child(target)
	add_child_autoqfree(scene_owner)
	var tween = TWEEN_RUNTIME_SCRIPT.new(target)
	tween.options.duration = 0.2
	tween.options.ease = AnimeEase.LINEAR
	tween.track(CONTROL_SCRIPT.position_to(Vector2(100.0, 0.0)))
	var timeline = TIMELINE_RUNTIME_SCRIPT.new(scene_owner)
	timeline.options.delay = 0.1
	timeline.options.repeat_count = 2
	timeline.options.repeat_delay = 0.1
	timeline.options.yoyo = true
	timeline.add(tween)

	_expect(is_equal_approx(timeline.get_total_duration(), 0.9), "Timeline total duration should include delay and repeat gaps")
	timeline.seek_progress(0.5)
	_expect(timeline.get_iteration() == 2, "Timeline iteration should be one-based")
	_expect(is_equal_approx(timeline.get_total_position(), 0.45), "Timeline total position should follow normalized seeking")
	_expect(is_equal_approx(timeline.get_total_progress(), 0.5), "Timeline total progress should include repeat cycles")
	_expect(is_equal_approx(target.position.x, 75.0), "Seeking should sample the active yoyo cycle")


func test_repeat_callbacks_report_track_and_timeline_iterations() -> void:
	var target := Control.new()
	add_child_autoqfree(target)
	var track_repeats: Array[int] = []
	var tween = TWEEN_RUNTIME_SCRIPT.new(target)
	tween.options.duration = 0.02
	tween.options.ease = AnimeEase.LINEAR
	tween.options.repeat_count = 1
	tween.options.on_track_repeat = func(_track: AnimeTrack, iteration: int) -> void: track_repeats.append(iteration)
	tween.track(CONTROL_SCRIPT.position_to(Vector2(20.0, 0.0)))
	tween.play()
	await tween.completed
	_expect(track_repeats == [2], "Track repeat callbacks should report one-based iteration numbers")

	var timeline_repeats: Array[int] = []
	var child = TWEEN_RUNTIME_SCRIPT.new(target)
	child.options.duration = 0.02
	child.track(CONTROL_SCRIPT.position_to(Vector2(30.0, 0.0)))
	var timeline = TIMELINE_RUNTIME_SCRIPT.new()
	timeline.options.repeat_count = 1
	timeline.options.on_repeat = func(iteration: int) -> void: timeline_repeats.append(iteration)
	timeline.add(child)
	timeline.play()
	await timeline.completed
	_expect(timeline_repeats == [2], "Timeline repeat callbacks should report one-based iteration numbers")


func test_invalidate_recaptures_start_and_revert_restores_original_value() -> void:
	var target := Control.new()
	add_child_autoqfree(target)
	var tween = TWEEN_RUNTIME_SCRIPT.new(target)
	tween.options.duration = 0.04
	tween.options.ease = AnimeEase.LINEAR
	tween.track(CONTROL_SCRIPT.position_to(Vector2(100.0, 0.0)))
	tween.play()
	await tween.completed

	target.position = Vector2(200.0, 0.0)
	tween.invalidate()
	tween.play()
	tween.seek_progress(0.5)
	_expect(is_equal_approx(target.position.x, 150.0), "Invalidation should capture the target's current start value on replay")
	tween.revert()
	_expect(target.position == Vector2.ZERO, "Revert should restore the value captured before the first play")
	_expect(tween.is_finished(), "A reverted tween should report finished")


func test_from_to_revert_uses_target_value_not_explicit_start() -> void:
	var target := Control.new()
	add_child_autoqfree(target)
	target.position = Vector2(15.0, 25.0)
	var tween = TWEEN_RUNTIME_SCRIPT.new(target, TWEEN_RUNTIME_SCRIPT.Mode.FROM_TO)
	tween.options.duration = 0.02
	var track = CONTROL_SCRIPT.position_to(Vector2(80.0, 90.0))
	track.set_start_value(Vector2.ZERO)
	tween.track(track)
	tween.play()
	await tween.completed
	tween.revert()
	_expect(target.position == Vector2(15.0, 25.0), "Revert should restore the pre-animation target value")


func test_from_and_set_revert_restore_original_target_value() -> void:
	var target := Control.new()
	add_child_autoqfree(target)
	target.position = Vector2(15.0, 25.0)
	var from_tween = TWEEN_RUNTIME_SCRIPT.new(target, TWEEN_RUNTIME_SCRIPT.Mode.FROM)
	from_tween.options.duration = 0.02
	from_tween.track(CONTROL_SCRIPT.position_to(Vector2.ZERO))
	from_tween.play()
	await from_tween.completed
	from_tween.revert()
	_expect(target.position == Vector2(15.0, 25.0), "FROM revert should restore the original target value")

	var set_tween = TWEEN_RUNTIME_SCRIPT.new(target, TWEEN_RUNTIME_SCRIPT.Mode.SET)
	set_tween.track(CONTROL_SCRIPT.position_to(Vector2(80.0, 90.0)))
	set_tween.play()
	_expect(target.position == Vector2(80.0, 90.0), "SET should apply before it can be reverted")
	set_tween.revert()
	_expect(target.position == Vector2(15.0, 25.0), "SET revert should restore the original target value")


func test_revert_safely_skips_freed_targets() -> void:
	var target := Control.new()
	add_child_autoqfree(target)
	var tween = TWEEN_RUNTIME_SCRIPT.new(target)
	tween.options.duration = 1.0
	tween.track(CONTROL_SCRIPT.position_to(Vector2(100.0, 0.0)))
	tween.play()
	target.free()
	tween.revert()
	_expect(tween.is_finished(), "Revert should finish safely when the target has been freed")


func test_timeline_revert_restores_child_tweens() -> void:
	var scene_owner := Node2D.new()
	var target := Control.new()
	target.position = Vector2(5.0, 10.0)
	scene_owner.add_child(target)
	add_child_autoqfree(scene_owner)
	var tween = TWEEN_RUNTIME_SCRIPT.new(target)
	tween.options.duration = 0.02
	tween.options.ease = AnimeEase.LINEAR
	tween.track(CONTROL_SCRIPT.position_to(Vector2(100.0, 200.0)))
	var timeline = TIMELINE_RUNTIME_SCRIPT.new(scene_owner)
	timeline.add(tween)
	timeline.play()
	await timeline.completed
	target.position = Vector2(300.0, 400.0)
	timeline.invalidate()
	timeline.seek(0.01)
	_expect(
		target.position == Vector2(200.0, 300.0),
		"Timeline invalidation should recapture child starting values"
	)
	timeline.revert()
	_expect(target.position == Vector2(5.0, 10.0), "Timeline revert should restore the original child target value")


func test_typed_keyframe_points_sample_nonuniform_segments() -> void:
	var target := Control.new()
	add_child_autoqfree(target)
	var tween = TWEEN_RUNTIME_SCRIPT.new(target)
	tween.options.duration = 0.4
	tween.options.ease = AnimeEase.LINEAR
	var track = CONTROL_SCRIPT.position_to(Vector2(100.0, 0.0))
	var points: Array[AnimeKeyframe] = [
		AnimeKeyframe.new(0.25, Vector2(20.0, 0.0), AnimeEase.LINEAR),
		AnimeKeyframe.new(0.75, Vector2(80.0, 0.0), AnimeEase.LINEAR),
	]
	_expect(track.set_keyframe_points(points), "Typed keyframe points should accept ordered normalized positions")
	tween.track(track)
	tween.seek(0.2)
	_expect(is_equal_approx(target.position.x, 50.0), "Keyframe points should interpolate across nonuniform segments")
	tween.seek(0.35)
	_expect(is_equal_approx(target.position.x, 90.0), "The final keyframe segment should reach the track endpoint")


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