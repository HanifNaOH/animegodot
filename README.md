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

context.to($Panel, {
    "position": Vector2(400, 200),
    "duration": 0.8,
    "ease": Anime.EASE_OUT_QUAD,
    "on_complete": _panel_arrived,
})
```

Timeline example:

```gdscript
var timeline := context.timeline()
timeline \\
    .to($Title, {"modulate:a": 1.0, "duration": 0.4}) \\
    .to($Button, {"position:y": 240.0, "duration": 0.6}, "<+=0.1") \\
    .invoke(_intro_finished) \\
    .play()
```

Use `Anime.set_value()` for immediate property writes. `set` and `call` are reserved by Godot's `Object` API, so AnimeGodot exposes `set_value()` and timeline `invoke()` instead.

## Godot-Native Features

```gdscript
Anime.motion_path($Rocket, $RocketPath, {
    "duration": 2.0,
    "align_to_path": true,
})

Anime.to($Sprite, {
    "material:shader_parameter/glow": 1.0,
    "duration": 0.5,
})
```

The editor dock provides AnimationPlayer preview, pause, reverse, stop, scrubbing, runtime inspection, and reusable `.tres` animation export.

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

See [docs/plan.md](docs/plan.md) for the implementation roadmap and [examples/todo_list/README.md](examples/todo_list/README.md) for the GDVM example architecture.
