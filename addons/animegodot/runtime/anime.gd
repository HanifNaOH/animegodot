class_name Anime
extends RefCounted

const CONTEXT_SCRIPT = preload("res://addons/animegodot/runtime/anime_context.gd")
const TWEEN_RUNTIME_SCRIPT = preload("res://addons/animegodot/runtime/anime_tween_runtime.gd")
const TIMELINE_RUNTIME_SCRIPT = preload("res://addons/animegodot/runtime/anime_timeline_runtime.gd")
const INTERPOLATION_SCRIPT = preload("res://addons/animegodot/runtime/anime_interpolation.gd")
const ANIMATION_EXPORTER_SCRIPT = preload("res://addons/animegodot/runtime/anime_animation_exporter.gd")
const STAGGER_OPTIONS_SCRIPT = preload("res://addons/animegodot/runtime/anime_stagger_options.gd")

const OVERWRITE_NONE := AnimeOverwrite.NONE
const OVERWRITE_AUTO := AnimeOverwrite.AUTO
const OVERWRITE_ALL := AnimeOverwrite.ALL
const TWEEN_PROCESS_IDLE := Tween.TWEEN_PROCESS_IDLE
const TWEEN_PROCESS_PHYSICS := Tween.TWEEN_PROCESS_PHYSICS

const EASE_LINEAR := AnimeEase.LINEAR
const EASE_IN_SINE := AnimeEase.IN_SINE
const EASE_OUT_SINE := AnimeEase.OUT_SINE
const EASE_IN_OUT_SINE := AnimeEase.IN_OUT_SINE
const EASE_IN_QUAD := AnimeEase.IN_QUAD
const EASE_OUT_QUAD := AnimeEase.OUT_QUAD
const EASE_IN_OUT_QUAD := AnimeEase.IN_OUT_QUAD
const EASE_IN_CUBIC := AnimeEase.IN_CUBIC
const EASE_OUT_CUBIC := AnimeEase.OUT_CUBIC
const EASE_IN_OUT_CUBIC := AnimeEase.IN_OUT_CUBIC
const EASE_IN_QUART := AnimeEase.IN_QUART
const EASE_OUT_QUART := AnimeEase.OUT_QUART
const EASE_IN_OUT_QUART := AnimeEase.IN_OUT_QUART
const EASE_IN_QUINT := AnimeEase.IN_QUINT
const EASE_OUT_QUINT := AnimeEase.OUT_QUINT
const EASE_IN_OUT_QUINT := AnimeEase.IN_OUT_QUINT
const EASE_IN_EXPO := AnimeEase.IN_EXPO
const EASE_OUT_EXPO := AnimeEase.OUT_EXPO
const EASE_IN_OUT_EXPO := AnimeEase.IN_OUT_EXPO
const EASE_IN_CIRC := AnimeEase.IN_CIRC
const EASE_OUT_CIRC := AnimeEase.OUT_CIRC
const EASE_IN_OUT_CIRC := AnimeEase.IN_OUT_CIRC
const EASE_IN_BACK := AnimeEase.IN_BACK
const EASE_OUT_BACK := AnimeEase.OUT_BACK
const EASE_IN_OUT_BACK := AnimeEase.IN_OUT_BACK
const EASE_IN_BOUNCE := AnimeEase.IN_BOUNCE
const EASE_OUT_BOUNCE := AnimeEase.OUT_BOUNCE
const EASE_IN_OUT_BOUNCE := AnimeEase.IN_OUT_BOUNCE
const EASE_IN_ELASTIC := AnimeEase.IN_ELASTIC
const EASE_OUT_ELASTIC := AnimeEase.OUT_ELASTIC
const EASE_IN_OUT_ELASTIC := AnimeEase.IN_OUT_ELASTIC
const EASE_IN_SPRING := AnimeEase.IN_SPRING
const EASE_OUT_SPRING := AnimeEase.OUT_SPRING
const EASE_IN_OUT_SPRING := AnimeEase.IN_OUT_SPRING


static func context(owner: Node = null):
	return CONTEXT_SCRIPT.new(owner)


static func tween(target: Object) -> AnimeTweenRuntime:
	return _context_for(target).tween(target)


static func to(target: Object) -> AnimeTweenRuntime:
	return tween(target)


static func from(target: Object) -> AnimeTweenRuntime:
	return _context_for(target).create_tween(target, AnimeTweenRuntime.Mode.FROM)


static func from_to(target: Object) -> AnimeTweenRuntime:
	return _context_for(target).create_tween(target, AnimeTweenRuntime.Mode.FROM_TO)


static func set_value(target: Object) -> AnimeTweenRuntime:
	return _context_for(target).create_tween(target, AnimeTweenRuntime.Mode.SET)


static func to_many(
	targets: Array[Node],
	tracks: Array[AnimeTrack],
	options: AnimeOptions = null,
	stagger: RefCounted = null
) -> Array[AnimeTweenRuntime]:
	return _create_many(targets, tracks, options, stagger, AnimeTweenRuntime.Mode.TO)


static func from_many(
	targets: Array[Node],
	tracks: Array[AnimeTrack],
	options: AnimeOptions = null,
	stagger: RefCounted = null
) -> Array[AnimeTweenRuntime]:
	return _create_many(targets, tracks, options, stagger, AnimeTweenRuntime.Mode.FROM)


static func from_to_many(
	targets: Array[Node],
	tracks: Array[AnimeTrack],
	options: AnimeOptions = null,
	stagger: RefCounted = null
) -> Array[AnimeTweenRuntime]:
	return _create_many(targets, tracks, options, stagger, AnimeTweenRuntime.Mode.FROM_TO)


static func set_many(
	targets: Array[Node],
	tracks: Array[AnimeTrack],
	options: AnimeOptions = null,
	stagger: RefCounted = null
) -> Array[AnimeTweenRuntime]:
	return _create_many(targets, tracks, options, stagger, AnimeTweenRuntime.Mode.SET)


static func interpolate(from_value: Variant, to_value: Variant, weight: float, interpolator: Variant = null) -> Variant:
	return INTERPOLATION_SCRIPT.value(from_value, to_value, weight, interpolator)


static func bezier(from_value: Variant, control_one: Variant, control_two: Variant, to_value: Variant, weight: float) -> Variant:
	return INTERPOLATION_SCRIPT.bezier(from_value, control_one, control_two, to_value, weight)


static func spring(from_value: Variant, to_value: Variant, time: float, stiffness: float = 170.0, damping: float = 26.0, mass: float = 1.0) -> Variant:
	return INTERPOLATION_SCRIPT.spring(from_value, to_value, time, stiffness, damping, mass)


static func animation_from_tween(player: AnimationPlayer, tween: AnimeTweenRuntime) -> Animation:
	return ANIMATION_EXPORTER_SCRIPT.from_tween(player, tween)


static func add_tween_animation(player: AnimationPlayer, name: StringName, tween: AnimeTweenRuntime) -> Animation:
	return ANIMATION_EXPORTER_SCRIPT.add_to_player(player, name, tween)


static func timeline(owner: Node = null, options: AnimeOptions = null) -> AnimeTimelineRuntime:
	return TIMELINE_RUNTIME_SCRIPT.new(owner, options)


static func _context_for(target: Object) -> AnimeContext:
	return CONTEXT_SCRIPT.new(target if target is Node else null)


static func _create_many(
	targets: Array[Node],
	tracks: Array[AnimeTrack],
	options: AnimeOptions,
	stagger: RefCounted,
	mode: int
) -> Array[AnimeTweenRuntime]:
	var created: Array[AnimeTweenRuntime] = []
	if targets.is_empty() or tracks.is_empty():
		return created
	var base_options := options.copy() if options != null else AnimeOptions.new()
	var stagger_options: RefCounted = stagger if stagger != null else STAGGER_OPTIONS_SCRIPT.new()
	if (
		not base_options.is_valid()
		or not stagger_options.has_method("is_valid")
		or not stagger_options.has_method("delay_for")
		or not bool(stagger_options.call("is_valid"))
	):
		push_warning("AnimeGodot rejected invalid typed batch options.")
		return created

	var copied_tracks: Array[Array] = []
	for target in targets:
		if not is_instance_valid(target):
			push_warning("AnimeGodot batch targets must all be valid Nodes.")
			return []
		var target_tracks: Array[AnimeTrack] = []
		for track in tracks:
			if track == null or not track.options.is_valid():
				push_warning("AnimeGodot batch tracks must be valid typed tracks.")
				return []
			var copied_track := track.copy_for(target)
			if copied_track == null:
				push_warning("AnimeGodot batch accessor rejected a target or track value.")
				return []
			target_tracks.append(copied_track)
		copied_tracks.append(target_tracks)

	for index in targets.size():
		var target := targets[index]
		var tween := _context_for(target).create_tween(target, mode)
		tween.options = base_options.copy()
		var stagger_delay := float(stagger_options.call("delay_for", index, targets.size()))
		tween.options.delay += stagger_delay
		for track in copied_tracks[index]:
			if track.options.delay >= 0.0:
				track.options.delay += stagger_delay
			if not tween.add_track(track):
				tween.kill(false)
				return []
		created.append(tween)
	return created
