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

### Extended Runtime API

Use `from_to()` when both endpoints should be explicit:

```gdscript
Anime.from_to($Panel, {
    "position": Vector2(-200, 80),
}, {
    "position": Vector2(400, 80),
    "duration": 0.8,
})
```

Property values can be keyframe arrays, or dictionaries with their own timing:

```gdscript
Anime.to($Panel, {
    "position": {
        "keyframes": [Vector2(120, 80), Vector2(260, 140)],
        "duration": 0.8,
        "ease": Anime.EASE_OUT_QUAD,
    },
    "modulate:a": {
        "value": 1.0,
        "duration": 0.3,
        "delay": 0.2,
    },
})
```

AnimeGodot interpolates numbers, integer and floating-point vectors, rectangles, colors, quaternions, planes, AABBs, transforms, arrays, and dictionaries. Discrete values such as strings, booleans, and objects switch at the end of the segment. Custom values can provide an `interpolate` Callable:

```gdscript
Anime.to($Target, {
    "position": {
        "value": Vector2(300, 120),
        "duration": 0.5,
        "interpolate": func(from_value, to_value, weight):
            var curved_weight := weight * weight
            return from_value.lerp(to_value, curved_weight),
    },
})
```

Tween handles support `pause()`, `resume()`, `seek(seconds)`, `reverse()`, `restart()`, `reset()`, `kill()`, and `get_progress()`. Repeats support `repeat_delay` and directions such as `normal`, `reverse`, and `alternate`.

Native Tween scheduling options are available for pause-menu UI and physics-synchronized motion:

```gdscript
Anime.to($PausePanel, {
    "position:y": 120.0,
    "duration": 0.25,
    "ignore_time_scale": true,
})

Anime.to($PhysicsBody, {
    "global_position": target_position,
    "duration": 0.2,
    "process_mode": Anime.TWEEN_PROCESS_PHYSICS,
})
```

Target arrays support richer stagger settings:

```gdscript
Anime.to([$A, $B, $C], {
    "position:x": 300.0,
    "duration": 0.5,
    "stagger": {
        "each": 0.1,
        "from": "center",
        "ease": Anime.EASE_OUT_QUAD,
    },
})
```

Timeline options apply to the timeline itself, while `defaults` apply to child tweens:

```gdscript
var timeline := Anime.timeline(self, {
    "defaults": {"duration": 0.4, "ease": Anime.EASE_OUT_QUAD},
    "repeat": 1,
    "repeat_delay": 0.2,
    "yoyo": true,
    "autoplay": true,
})
timeline.to($Panel, {"position:x": 400.0})
```

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

Motion-path handles support `pause()`, `resume()`, `seek(seconds)`, `reverse()`, `restart()`, `get_position()`, and `get_progress()`.

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
