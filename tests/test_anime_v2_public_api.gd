extends GutTest

const ANIME_SCRIPT = preload("res://addons/animegodot/runtime/anime.gd")
const CONTROL_SCRIPT = preload("res://addons/animegodot/runtime/anime_control.gd")
const NODE_2D_SCRIPT = preload("res://addons/animegodot/runtime/anime_node_2d.gd")
const POSITION_SCRIPT = preload("res://addons/animegodot/runtime/anime_position.gd")
const PROPERTY_ACCESSOR_SCRIPT = preload("res://addons/animegodot/runtime/anime_property_accessor.gd")
const PROPERTY_KEY_SCRIPT = preload("res://addons/animegodot/runtime/anime_property_key.gd")
const STAGGER_OPTIONS_SCRIPT = preload("res://addons/animegodot/runtime/anime_stagger_options.gd")
const TRACK_SCRIPT = preload("res://addons/animegodot/runtime/anime_track.gd")


func test_to_plays_typed_track_and_callbacks() -> void:
	var target := Control.new()
	add_child_autoqfree(target)
	var state := {"started": false, "completed": false}
	var tween = ANIME_SCRIPT.to(target)
	tween.options.duration = 0.03
	tween.options.ease = AnimeEase.LINEAR
	tween.options.on_start = func() -> void: state["started"] = true
	tween.options.on_complete = func() -> void: state["completed"] = true
	tween.track(CONTROL_SCRIPT.position_to(Vector2(120.0, 80.0)))
	tween.play()
	await tween.completed
	_expect(target.position == Vector2(120.0, 80.0), "Typed Anime.to should reach its endpoint")
	_expect(state["started"] and state["completed"], "Typed tween lifecycle callbacks should fire")


func test_node2d_position_accessor_plays_typed_tween() -> void:
	var target := Node2D.new()
	add_child_autoqfree(target)
	var tween = ANIME_SCRIPT.to(target)
	tween.options.duration = 0.03
	tween.options.ease = AnimeEase.LINEAR
	tween.track(NODE_2D_SCRIPT.position_to(Vector2(80.0, 40.0)))
	tween.play()
	await tween.completed
	_expect(target.position == Vector2(80.0, 40.0), "A typed Node2D position track should reach its endpoint")


func test_from_from_to_and_set_use_typed_tracks() -> void:
	var target := Control.new()
	add_child_autoqfree(target)
	target.position = Vector2(40.0, 30.0)
	var from_tween = ANIME_SCRIPT.from(target)
	from_tween.options.duration = 0.02
	from_tween.track(CONTROL_SCRIPT.position_to(Vector2.ZERO))
	from_tween.play()
	_expect(target.position == Vector2.ZERO, "Anime.from should apply its starting value immediately")
	await from_tween.completed
	_expect(target.position == Vector2(40.0, 30.0), "Anime.from should return to the captured value")

	var from_to_tween = ANIME_SCRIPT.from_to(target)
	from_to_tween.options.duration = 0.02
	var from_to_track = CONTROL_SCRIPT.position_to(Vector2(80.0, 45.0))
	_expect(from_to_track.set_start_value(Vector2(-30.0, -15.0)), "from_to should accept a typed start value")
	from_to_tween.track(from_to_track)
	from_to_tween.play()
	_expect(target.position == Vector2(-30.0, -15.0), "Anime.from_to should apply the typed start immediately")
	await from_to_tween.completed
	_expect(target.position == Vector2(80.0, 45.0), "Anime.from_to should reach its typed endpoint")

	var set_tween = ANIME_SCRIPT.set_value(target)
	set_tween.track(CONTROL_SCRIPT.position_to(Vector2(10.0, 15.0)))
	set_tween.play()
	_expect(target.position == Vector2(10.0, 15.0), "Anime.set_value should apply typed tracks immediately")
	_expect(set_tween.is_finished(), "An immediate typed set should finish synchronously")


func test_context_disposal_cleans_typed_tweens() -> void:
	var context_owner := Node.new()
	add_child_autoqfree(context_owner)
	var target := Control.new()
	context_owner.add_child(target)
	var context = ANIME_SCRIPT.context(context_owner)
	var tween = context.to(target)
	tween.options.duration = 1.0
	tween.track(CONTROL_SCRIPT.position_to(Vector2(200.0, 0.0)))
	tween.play()
	context.dispose()
	_expect(tween.is_finished(), "Disposing a context should kill its typed tweens")


func test_keyframes_repeats_and_yoyo_are_typed() -> void:
	var target := Control.new()
	add_child_autoqfree(target)
	var tween = ANIME_SCRIPT.tween(target)
	tween.options.duration = 0.03
	tween.options.ease = AnimeEase.LINEAR
	tween.options.repeat_count = 1
	tween.options.yoyo = true
	var position_track = CONTROL_SCRIPT.position_to(Vector2(120.0, 80.0))
	position_track.set_keyframes([Vector2(20.0, 10.0), Vector2(80.0, 40.0)])
	tween.track(position_track)
	tween.play()
	await tween.completed
	_expect(target.position == Vector2.ZERO, "Typed yoyo repeats should return to the captured start value")


func test_timeline_uses_typed_labels_and_position_tokens() -> void:
	var scene_owner := Node2D.new()
	var first_target := Control.new()
	var second_target := Control.new()
	scene_owner.add_child(first_target)
	scene_owner.add_child(second_target)
	add_child_autoqfree(scene_owner)
	var first = ANIME_SCRIPT.to(first_target)
	first.options.duration = 0.02
	first.options.ease = AnimeEase.LINEAR
	first.track(CONTROL_SCRIPT.position_to(Vector2(40.0, 0.0)))
	var second = ANIME_SCRIPT.to(second_target)
	second.options.duration = 0.02
	second.options.ease = AnimeEase.LINEAR
	second.track(CONTROL_SCRIPT.position_to(Vector2(80.0, 0.0)))
	var timeline = ANIME_SCRIPT.timeline(scene_owner)
	timeline.add(first)
	var midpoint = timeline.add_label()
	timeline.add(second, POSITION_SCRIPT.after(midpoint, 0.01))
	timeline.play()
	await timeline.completed
	_expect(first_target.position == Vector2(40.0, 0.0), "The first timeline tween should complete")
	_expect(second_target.position == Vector2(80.0, 0.0), "A typed label should schedule the second tween")


func test_timeline_reverse_and_restart_replay_typed_children() -> void:
	var scene_owner := Node2D.new()
	var target := Control.new()
	scene_owner.add_child(target)
	add_child_autoqfree(scene_owner)
	var tween = ANIME_SCRIPT.tween(target)
	tween.options.duration = 0.03
	tween.options.ease = AnimeEase.LINEAR
	tween.track(CONTROL_SCRIPT.position_to(Vector2(100.0, 0.0)))
	var timeline = ANIME_SCRIPT.timeline(scene_owner)
	timeline.add(tween)
	timeline.play()
	await timeline.completed
	_expect(is_equal_approx(target.position.x, 100.0), "The typed timeline should complete its child")
	timeline.reverse()
	await timeline.completed
	_expect(is_zero_approx(target.position.x), "Reversing should replay the typed child toward its start")
	timeline.restart()
	await timeline.completed
	_expect(is_equal_approx(target.position.x, 100.0), "Restart should replay typed timeline children")


func test_to_many_clones_typed_tracks_and_applies_stagger() -> void:
	var first_target := Control.new()
	var second_target := Control.new()
	add_child_autoqfree(first_target)
	add_child_autoqfree(second_target)
	var targets: Array[Node] = [first_target, second_target]
	var tracks: Array[AnimeTrack] = [CONTROL_SCRIPT.position_to(Vector2(100.0, 0.0))]
	var options := AnimeOptions.new()
	options.duration = 0.12
	options.ease = AnimeEase.LINEAR
	var stagger := STAGGER_OPTIONS_SCRIPT.new()
	stagger.each = 0.08
	var tweens = ANIME_SCRIPT.to_many(targets, tracks, options, stagger)
	_expect(tweens.size() == 2, "to_many should create one independent tween per target")
	_expect(tweens[0].options != tweens[1].options, "Each batch tween should receive its own options copy")
	_expect(tweens[0].tracks[0] != tracks[0], "Each batch tween should receive a distinct track copy")
	tweens[0].play()
	tweens[1].play()
	await wait_process_frames(2)
	_expect(first_target.position.x > second_target.position.x, "Stagger should delay the second target's start")
	await tweens[0].completed
	await tweens[1].completed
	_expect(first_target.position == Vector2(100.0, 0.0), "The first batch tween should reach its endpoint")
	_expect(second_target.position == Vector2(100.0, 0.0), "The staggered batch tween should reach its endpoint")


func test_animation_player_export_uses_typed_native_accessor() -> void:
	var root := Node2D.new()
	var target := Node2D.new()
	target.name = "Target"
	var player := AnimationPlayer.new()
	root.add_child(target)
	root.add_child(player)
	add_child_autoqfree(root)

	var tween = ANIME_SCRIPT.to(target)
	tween.options.duration = 0.5
	tween.options.ease = AnimeEase.LINEAR
	tween.track(NODE_2D_SCRIPT.position_to(Vector2(50.0, 20.0)))
	var animation = ANIME_SCRIPT.animation_from_tween(player, tween)
	_expect(animation.get_track_count() == 1, "Typed native-path accessors should export one value track")
	_expect(String(animation.track_get_path(0)) == "Target:position", "Export should resolve the player-relative node path")
	_expect(is_equal_approx(animation.track_get_key_time(0, 1), 0.5), "Export should preserve the typed track duration")
	_expect(animation.track_get_key_value(0, 1) == Vector2(50.0, 20.0), "Export should preserve the typed endpoint")

	var installed = ANIME_SCRIPT.add_tween_animation(player, &"move", tween)
	_expect(installed.get_track_count() == 1, "Typed AnimationPlayer installation should return the created resource")
	_expect(player.get_animation_library(&"").has_animation(&"move"), "Typed AnimationPlayer installation should register the clip")


func test_animation_player_export_skips_callable_only_accessors() -> void:
	var root := Node2D.new()
	var target := Node2D.new()
	var player := AnimationPlayer.new()
	root.add_child(target)
	root.add_child(player)
	add_child_autoqfree(root)
	var accessor = PROPERTY_ACCESSOR_SCRIPT.new(
		PROPERTY_KEY_SCRIPT.custom(),
		func(candidate: Object) -> bool: return candidate is Node2D,
		func(value: Variant) -> bool: return value is Vector2,
		func(candidate: Object) -> Variant: return (candidate as Node2D).position,
		func(candidate: Object, value: Variant) -> void:
			var node := candidate as Node2D
			node.position = value
	)
	var tween = ANIME_SCRIPT.to(target)
	tween.options.duration = 0.5
	tween.options.ease = AnimeEase.LINEAR
	tween.track(TRACK_SCRIPT.new(accessor, Vector2(30.0, 40.0)))
	var animation = ANIME_SCRIPT.animation_from_tween(player, tween)
	_expect(animation.get_track_count() == 0, "Custom accessors without native paths should stay runtime-only")


func _expect(condition: bool, message: String) -> void:
	assert_true(condition, message)