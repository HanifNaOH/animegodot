# AnimeGodot

AnimeGodot is a Godot 4 animation toolkit with an Anime.js-style runtime API, native Godot Tween integration, timelines, motion paths, and an editor dock.

This repository also includes a small GDVM-powered to-do application under `examples/todo_list/`. It demonstrates a code-first ViewModel, list binding, two-way input binding, child ViewModels, and command-based actions.

## Requirements

- Godot 4.7 or newer
- GDVM 1.0.1 is included in `addons/gdvm/`

## Run The Demo

Open the project in Godot and run the project. The main scene is the GDVM to-do list:

```text
examples/todo_list/todo_list.tscn
```

The demo supports adding tasks, filtering open/completed tasks, toggling completion, removing tasks, and clearing completed tasks.

## AnimeGodot Runtime

```gdscript
var context := Anime.context(self)
var tween := context.to($Panel)
tween.options.duration = 0.8
tween.options.ease = AnimeEase.OUT_QUAD
tween.options.on_complete = _panel_arrived
tween.track(AnimeControl.position_to(Vector2(400, 200)))
tween.play()
```

`Anime.to(target)` (or `context.to(target)`) creates an unplayed, typed tween. Add one or more typed tracks, configure `AnimeOptions`, then call `play()`. No property-name strings or option dictionaries are accepted by the v2 tween API.

Available built-in accessors include `AnimeNode2D.position_to(Vector2)`, `global_position_to(Vector2)`, `rotation_to(float)`, `rotation_degrees_to(float)`, and `scale_to(Vector2)`; `AnimeControl.position_to(Vector2)`, `custom_minimum_size_to(Vector2)`, and `scale_to(Vector2)`; and `AnimeCanvasItem.alpha_to(float)` or `modulate_to(Color)`. Accessors validate target/value types and provide stable overwrite identities. Custom tracks can use `AnimePropertyAccessor` with typed getter/setter callables and a reusable `AnimePropertyKey` identity.

Tween modes use the same typed track objects:

```gdscript
var from_tween := Anime.from($Panel)
from_tween.options.duration = 0.4
from_tween.track(AnimeControl.position_to(Vector2.ZERO))
from_tween.play()

var range_tween := Anime.from_to($Panel)
var position_track := AnimeControl.position_to(Vector2(400, 80))
position_track.set_start_value(Vector2(-200, 80))
range_tween.options.duration = 0.8
range_tween.track(position_track)
range_tween.play()

var set_tween := Anime.set_value($Panel)
set_tween.track(AnimeControl.position_to(Vector2(20, 20)))
set_tween.play()
```

Tracks support typed keyframes and per-track option overrides:

```gdscript
var tween := Anime.to($Panel)
tween.options.duration = 0.8
tween.options.ease = AnimeEase.OUT_QUAD

var position_track := AnimeControl.position_to(Vector2(260, 140))
position_track.set_keyframes([Vector2(120, 80)])
tween.track(position_track)

var alpha_track := AnimeCanvasItem.alpha_to(1.0)
alpha_track.options.duration = 0.3
alpha_track.options.delay = 0.2
tween.track(alpha_track)
tween.play()
```

Multi-target factories return independently controllable tween handles. Targets and tracks are typed collections; stagger configuration uses enums instead of string origins:

```gdscript
var targets: Array[Node] = [$A, $B, $C]
var tracks: Array[AnimeTrack] = [AnimeControl.position_to(Vector2(300, 0))]
var tween_options := AnimeOptions.new()
tween_options.duration = 0.5
var stagger := AnimeStaggerOptions.new()
stagger.each = 0.1
stagger.origin = AnimeStaggerOptions.Origin.CENTER
stagger.grid_size = Vector2i(3, 1)
stagger.axis = AnimeStaggerOptions.Axis.HORIZONTAL

for item_tween in Anime.to_many(targets, tracks, tween_options, stagger):
    item_tween.play()
```

Timeline placement uses typed labels and position tokens, not string expressions:

```gdscript
var timeline := Anime.timeline(self)
var title_tween := Anime.to($Title)
title_tween.options.duration = 0.4
title_tween.track(AnimeCanvasItem.alpha_to(1.0))
timeline.add(title_tween)

var title_end := timeline.add_label()
var button_tween := Anime.to($Button)
button_tween.options.duration = 0.6
button_tween.track(AnimeControl.position_to(Vector2(0, 240)))
timeline.add(button_tween, AnimePosition.after(title_end, 0.1))
timeline.invoke(_intro_finished, AnimePosition.after_previous())
timeline.play()
```

For FLIP-style layout transitions, create a controller for the Container and wrap the mutation in `update()`. By default, each direct-child Control is paired with its direct-child `Visual` wrapper:

```gdscript
var layout := Anime.create_layout($Cards)
await layout.update(func(root: Control) -> void:
    (root as VBoxContainer).move_child(root.get_child(1), 0)
)
```

Set `AnimeLayoutOptions.children_group` to filter discovered descendant slots by Godot group, or use `options.visual_path` to select another wrapper path. For fully custom pairings, `Anime.flip(Array[AnimeLayoutItem])` remains available. Visual wrappers should fill their slots and use a zero pivot. Enter/exit and reparent transitions are not included.

Tween options include duration, delay, ease, repeat count/delay, yoyo, direction, overwrite, speed scale, time-scale behavior, process mode, and `Callable` lifecycle hooks. Tween and timeline handles provide playback controls such as pause, resume, reverse, restart, seek, and kill. Timeline entries can be tweens, nested timelines, or callbacks.

`Anime.interpolate()`, `Anime.bezier()`, and `Anime.spring()` remain available as value helpers. Tracks may set a custom interpolation `Callable` in their typed options.

Typed tracks with native accessor paths can be exported to AnimationPlayer:

```gdscript
var tween := Anime.to($Target)
tween.options.duration = 0.5
tween.options.ease = AnimeEase.LINEAR
tween.track(AnimeNode2D.position_to(Vector2(50, 20)))
var clip := Anime.animation_from_tween($AnimationPlayer, tween)
Anime.add_tween_animation($AnimationPlayer, &"move", tween)
```

Export currently supports linear tracks without repeats, yoyo, or custom interpolation. Accessors without a native path remain runtime-only. Motion-path and shader-parameter APIs are deferred while their typed v2 forms are designed; the editor dock continues to work directly with native AnimationPlayer resources.

## Godot-Native Features

Tween playback uses native Godot `Tween` instances. The editor dock provides AnimationPlayer preview, pause, reverse, stop, scrubbing, runtime inspection, and reusable `.tres` animation export.

## Editor Dock Example

Open `examples/dock_demo/animation_dock_demo.tscn` in the editor. Select the scene root or its `AnimationPlayer`, then open the AnimeGodot dock on the right. Choose `slide_and_fade`, `bounce`, `pulse`, or `fade_in` to preview, pause, reverse, stop, scrub, or save a clip as a `.tres` resource. Use **Save All Animations (.tres)** to export the complete default `AnimationLibrary` as one batch resource.

Attach that batch resource to a new `AnimationPlayer` with the same target hierarchy:

```gdscript
var player := AnimationPlayer.new()
var library := load("res://animegodot_AnimationPlayer_library.tres") as AnimationLibrary
player.add_animation_library(&"", library)
add_child(player)
player.play(&"slide_and_fade")
```

## Tests

Run the complete test folder through GUT with the configured Godot executable:

```text
godot --headless --path . --script res://addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gexit
```

The GUT editor uses `.gut_editor_config.json` to discover the same `res://tests` folder.

See the [v2 API reference](docs/api_v2.md), [v1 migration guide](docs/migration_v1_to_v2.md), and [v2 implementation roadmap](docs/plan2.md). For examples, see [examples/todo_list/README.md](examples/todo_list/README.md) and the [GDVM Main Menu](examples/main_menu/README.md), which demonstrates focus-following hand motion and command-based selection with one ViewModel.
