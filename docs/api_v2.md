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

Tracks may call `set_keyframes(Array)` and set per-track options. A track is bound to its compatible target when added. Duplicate property identities on one tween are rejected.

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
- `on_start`, `on_update`, `on_complete`, `on_kill` (`Callable`)

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

Timeline options use `AnimeOptions`; configure child defaults through `timeline.defaults`. Playback methods include `play`, `pause`, `resume`, `reverse`, `restart`, `seek`, and `kill`.

## Interpolation And AnimationPlayer

`Anime.interpolate`, `Anime.bezier`, and `Anime.spring` are value helpers. Track interpolation can use a typed `Callable` in `track.options.interpolator`.

`Anime.animation_from_tween(player, tween)` and `Anime.add_tween_animation(player, name, tween)` export/install value tracks only when the accessor provides a native path. The current exporter supports linear tracks without repeats, yoyo, or custom interpolation. Runtime-only custom accessors are skipped with a warning.

Motion-path and shader-uniform animation are not available through the v2 facade yet. They are not supported via legacy dictionary paths.
