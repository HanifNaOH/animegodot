# AnimeGodot v2 API

AnimeGodot v2 is a typed, hard-break release. Property selection and closed-set options use typed accessors/enums; v1 dictionary calls and compatibility adapters are not supported.

## Creating Tweens

`Anime.to(target)`, `Anime.tween(target)`, `Anime.from(target)`, `Anime.from_to(target)`, and `Anime.set_value(target)` create an unplayed `AnimeTweenRuntime`. Add tracks, configure options, then call `play()`.

```gdscript
var tween := Anime.to($Panel)
tween.options.duration = 0.4
tween.options.ease = AnimeEase.OUT_QUAD
tween.track(AnimeControl.position_to(Vector2(300, 120)))
tween.play()
```

Modes:

- `TO` interpolates from the value captured when playback starts to each track endpoint.
- `FROM` applies each track endpoint immediately, then animates to the captured value.
- `FROM_TO` uses `track.set_start_value(value)` as the explicit start and the accessor's value as the endpoint.
- `SET` applies endpoints immediately and finishes synchronously.

Tracks may call `set_keyframes(Array)` for evenly spaced values or `set_keyframe_points(Array[AnimeKeyframe])` for explicit normalized positions. A track is bound to its compatible target when added. Duplicate property identities on one tween are rejected.

`AnimeKeyframe.new(progress, value, ease)` creates a point where `progress` is strictly between 0 and 1. The start and end values remain the track's captured/explicit start and endpoint. Points must be ordered and type-compatible with the track accessor. Ease defaults to the track/tween ease; an optional interpolator overrides the track interpolator for that segment.

```gdscript
var track := AnimeControl.position_to(Vector2(300, 0))
track.set_keyframe_points([
	AnimeKeyframe.new(0.25, Vector2(40, 0), AnimeEase.OUT_QUAD),
	AnimeKeyframe.new(0.75, Vector2(240, 0), AnimeEase.IN_OUT_CUBIC),
])
```

## Time And State

Tween `duration` and `get_total_duration()` include the longest track's delay, repeats, and repeat delays. Existing `get_progress()` remains normalized over that full tween duration; `seek_progress(0.5)` seeks to its midpoint. Tracks can use different timing overrides, so query their local state with `get_track_iteration(track)` and `get_track_progress(track)`. Iteration is one-based; track progress is within the current iteration, accounts for yoyo/direction, and remains at 1 during repeat delay.

Timelines retain cycle-local `duration`, `get_position()`, and `get_progress()`. `get_total_duration()` includes timeline delay and repeats; `get_total_position()`, `get_total_progress()`, and `get_iteration()` report the overall playhead, with one-based iterations. `seek_progress(0.5)` samples the matching repeat/yoyo cycle. Seeking does not fire start, repeat, timeline-entry, completion, or reverse-completion events; it does emit the existing update callback/signal.

Both runtime handles provide `is_active()` (false while paused) and `is_reversed()`. Tween `get_total_duration()` is measured in logical seconds and is unaffected by speed scale.

## Built-In Accessors

All accessor factories validate both target and value types. Current accessors are:

- `AnimeNode2D.position_to(Vector2)`
- `AnimeNode2D.global_position_to(Vector2)`
- `AnimeNode2D.rotation_to(float)`
- `AnimeNode2D.rotation_degrees_to(float)`
- `AnimeNode2D.scale_to(Vector2)`
- `AnimeControl.position_to(Vector2)`
- `AnimeControl.custom_minimum_size_to(Vector2)`
- `AnimeControl.scale_to(Vector2)`
- `AnimeCanvasItem.alpha_to(float)`
- `AnimeCanvasItem.modulate_to(Color)`

Custom properties use `AnimePropertyAccessor` with target/value validator, getter, setter, an `AnimePropertyKey`, and an optional native path provider. Reuse the same custom key object for accessors that represent the same property. Custom accessors without a native path work at runtime but cannot export to AnimationPlayer.

## Tween Options

Set tween-wide fields on `tween.options` (`AnimeOptions`):

- `duration`, `delay`, `ease`
- `repeat_count`, `repeat_delay`, `yoyo`, `direction`
- `overwrite` (`AnimeOverwrite.NONE`, `AUTO`, or `ALL`)
- `speed_scale`, `ignore_time_scale`, `process_mode`
- `on_start`, `on_update`, `on_complete`, `on_reverse_complete`, `on_kill` (`Callable`)
- `on_track_repeat` (`Callable(track, one_based_iteration)`) for tween tracks
- `on_repeat` (`Callable(one_based_iteration)`) for timeline cycles

Tween repeat notifications are per track because tracks may override repeat timing independently. `AnimeTweenRuntime.track_repeated` emits the same track and iteration values. Timeline `repeated` fires once when a new timeline iteration begins. Reverse completion has its own callback/signal and still emits the generic completion callback/signal afterward.

`invalidate()` stops playback and clears sampled start/end values so the next play captures current target values. The original values from the first capture are retained for `revert()`. `revert()` stops the handle, restores those original values for its remaining tracks, and emits `reverted` and `killed` signals without invoking `on_kill` or `on_complete`. Timeline invalidation and revert apply recursively to child tweens/timelines. Calls safely skip targets that have already been freed.

`AnimeTrackOptions` overrides duration, delay, ease, repeat count/delay, yoyo, direction, and interpolation for one track. Negative numeric values and `INHERIT` enum values mean use the tween-wide setting.

Easing constants live on `AnimeEase`, for example `LINEAR`, `OUT_QUAD`, and `IN_OUT_SPRING`. Directions are `AnimeOptions.Direction.NORMAL`, `REVERSE`, or `ALTERNATE`.

## Multiple Targets

`Anime.to_many`, `from_many`, `from_to_many`, and `set_many` take `Array[Node]`, `Array[AnimeTrack]`, optional `AnimeOptions`, and optional `AnimeStaggerOptions`. They return independently controllable tween handles; each target gets copied tracks and options.

`AnimeStaggerOptions` provides `each`, `amount`, `start_delay`, `origin`, `origin_index`, `reversed`, `ease`, `grid_size`, and `axis`. Origins are enums (`FIRST`, `CENTER`, `LAST`, `EDGES`, `INDEX`); axes are `BOTH`, `HORIZONTAL`, and `VERTICAL`.

## Timelines

`Anime.timeline(owner)` returns an `AnimeTimelineRuntime`. Add tween/timeline objects with `add`; use `parallel` for the previous child's start, `invoke(Callable)` for callbacks, and `add_label()` for a typed label token.

`AnimePosition` supports:

- `at(seconds)` for absolute placement
- `after(label, offset)` for label-relative placement
- `with_previous_start(offset)` for overlap from the prior start
- `after_previous(offset)` for placement from the prior end
- `cursor()` or `null` for the current end

Timeline options use `AnimeOptions`; configure child defaults through `timeline.defaults`. Playback methods include `play`, `pause`, `resume`, `reverse`, `restart`, `seek`, `seek_progress`, `invalidate`, `revert`, and `kill`.

## Interpolation And AnimationPlayer

`Anime.interpolate`, `Anime.bezier`, and `Anime.spring` are value helpers. Track interpolation can use a typed `Callable` in `track.options.interpolator`.

`Anime.animation_from_tween(player, tween)` and `Anime.add_tween_animation(player, name, tween)` export/install value tracks only when the accessor provides a native path. The exporter supports linear tracks without repeats, yoyo, or custom interpolation; linear typed keyframe points preserve their explicit times. Non-linear per-point easing and custom keyframe interpolators remain runtime-only and are skipped with a warning. Runtime-only custom accessors are also skipped with a warning.

Motion-path and shader-uniform animation are not available through the v2 facade yet. They are not supported via legacy dictionary paths.
