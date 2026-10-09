# Migrating from AnimeGodot v1 to v2

AnimeGodot v2 is a major, source-breaking release. V1 is unsupported by v2: there is no dictionary fallback, compatibility wrapper, or dual API. Projects that must keep v1 behavior should remain on the v1 release line.

## Tween Dictionaries to Typed Tracks

V1 mixed property names and options in a dictionary:

```gdscript
Anime.to($Panel, {
    "position": Vector2(300, 120),
    "duration": 0.4,
    "ease": Anime.EASE_OUT_QUAD,
})
```

In v2, create an unplayed tween, set typed options, add a typed accessor track, and play it:

```gdscript
var tween := Anime.to($Panel)
tween.options.duration = 0.4
tween.options.ease = AnimeEase.OUT_QUAD
tween.track(AnimeControl.position_to(Vector2(300, 120)))
tween.play()
```

Use `AnimeNode2D` for Node2D properties, `AnimeControl` for Control properties, and `AnimeCanvasItem` for modulation/alpha. Unsupported property names fail to compile only when represented by a typed function signature; custom accessors validate target and value types at runtime.

## Modes And Track Options

- `Anime.from(target, dict)` becomes `Anime.from(target)` plus typed tracks.
- `Anime.from_to(target, from_dict, to_dict)` becomes `Anime.from_to(target)` plus tracks configured with `set_start_value()` and endpoint accessors.
- `Anime.set_value(target, dict)` becomes `Anime.set_value(target)`, typed tracks, and `play()`.
- Per-property configuration dictionaries become `track.options` fields; keyframe arrays become `track.set_keyframes([...])`.
- `loop` is removed; use the canonical `repeat_count` field.
- String easing names become `AnimeEase` constants. String overwrite values become `AnimeOverwrite` enum values.
- Callbacks remain `Callable`s on `AnimeOptions`.

## Targets And Stagger

V1 target arrays plus a property dictionary become typed collections passed to `Anime.to_many` (or the corresponding `from_many`, `from_to_many`, or `set_many`) with `Array[Node]`, `Array[AnimeTrack]`, shared `AnimeOptions`, and `AnimeStaggerOptions`. Replace string stagger origins such as `"center"` with `AnimeStaggerOptions.Origin.CENTER`; grid dimensions use `Vector2i`, and axes use `AnimeStaggerOptions.Axis`.

## Timelines

V1 timeline `.to(target, properties, "<+=0.1")` calls become prebuilt tween handles added to a typed timeline. Replace label strings with `AnimeLabel` tokens from `add_label()`, and positions with `AnimePosition.at()`, `after()`, `with_previous_start()`, or `after_previous()`.

```gdscript
var timeline := Anime.timeline(self)
var first := Anime.to($Title)
first.options.duration = 0.4
first.track(AnimeCanvasItem.alpha_to(1.0))
timeline.add(first)
var title_end := timeline.add_label()
var next := Anime.to($Button)
next.options.duration = 0.6
next.track(AnimeControl.position_to(Vector2(0, 240)))
timeline.add(next, AnimePosition.after(title_end, 0.1))
timeline.play()
```

Timeline callbacks use `invoke(Callable, position)`; nested timelines use `add(child_timeline, position)`. Configure timeline-level options with `AnimeOptions` and child defaults through `timeline.defaults`.

## Native Integrations And Removed Features

Property-path strings such as `"modulate:a"` and `"material:shader_parameter/glow"` are not accepted by the v2 runtime. Provide a typed accessor instead. Custom `AnimePropertyAccessor`s need a reusable `AnimePropertyKey` for overwrite identity.

AnimationPlayer conversion now accepts a typed tween: `Anime.animation_from_tween(player, tween)` or `Anime.add_tween_animation(player, name, tween)`. Only native-path accessors and linear, non-repeating tracks are currently exportable; custom callable-only accessors remain runtime-only.

V1 `Anime.motion_path()` and shader-parameter dictionary paths are not available in v2. Do not call the V1 class names or old runtime scripts; they have been removed/are unsupported. Native AnimationPlayer resources and the editor dock remain available independently.

See [api_v2.md](api_v2.md) for the supported v2 API.
