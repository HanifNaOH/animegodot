# AnimeGodot Plan

## Goal

Build a Godot 4 animation add-on with an Anime.js-style API and selected GSAP-style capabilities, while using Godot's native animation systems wherever they are already the best fit.

## Core Decisions

- Implement the runtime in GDScript.
- Use Godot `Tween` as the first runtime backend.
- Use `AnimationPlayer` for saved, editor-authored, and complex track-based animations.
- Keep the public API concise and Godot-native: Nodes, properties, NodePaths, Variants, signals, and Resources.
- Do not embed JavaScript or copy Anime.js/GSAP source code.
- Build the editor plugin only after the runtime API is useful from scripts.

## Target API

```gdscript
var context := Anime.context(self)

context.to($Panel, {
    "position": Vector2(400, 200),
    "duration": 0.8,
    "ease": Anime.EASE_OUT_QUAD,
    "on_complete": _panel_arrived
})
```

Timeline example:

```gdscript
var timeline := context.timeline()

timeline \\
    .to($Title, {"modulate:a": 1.0, "duration": 0.4}) \\
    .to($Button, {"position:y": 240.0, "duration": 0.6}, "<+=0.1") \\
    .call(_intro_finished) \\
    .play()
```

## Milestones

### 1. Runtime foundation

Create the runtime directory and implement:

- `anime.gd`: public entry point, constants, and factory methods.
- `anime_context.gd`: owns animations created by one Node and cleans them up.
- `anime_tween.gd`: wrapper around one native Godot Tween.
- `anime_easing.gd`: friendly easing names mapped to Godot transitions/ease types.
- `anime_property.gd`: validation and support for property paths such as `position`, `rotation`, and `modulate:a`.

Initial features:

- Animate one target.
- Animate multiple properties.
- Duration and delay.
- Easing.
- Pause, resume, kill, and completion callbacks.
- Automatic cleanup when the owner exits the scene tree.

Validation:

- Add a small test scene or script.
- Run it with the configured Godot 4.7.1 executable in headless mode.
- Verify property changes and callback execution.

### 2. Anime.js-style convenience API

Add:

- `Anime.to(target, properties)`.
- `Anime.from(target, properties)`.
- `Anime.set(target, properties)`.
- Arrays of targets.
- `repeat` and `yoyo`.
- Staggered starts for target arrays.
- `on_start`, `on_update`, `on_complete`, and `on_kill` callbacks.

Keep the options dictionary separate from animated properties so reserved keys cannot be written to the target.

### 3. Timeline system

Implement `anime_timeline.gd` with:

- Sequential tweens.
- Parallel groups.
- Nested timelines.
- Labels.
- Relative positions: `"<"`, `">"`, `"label+=0.2"`.
- Pause, resume, reverse, restart, seek, and time scale.
- Timeline completion and interruption signals.

Use native Tween chains where possible. Add a small scheduler only where labels and relative positions require it.

### 4. Conflict and lifecycle handling

Add a central registry for active animations:

- `OVERWRITE_NONE`: allow animations to coexist.
- `OVERWRITE_AUTO`: replace conflicting property tracks on the same target.
- `OVERWRITE_ALL`: kill existing animations on the target.
- Kill animations safely when a target is freed.
- Ensure callbacks are not called after cleanup.

Add focused tests for overlapping position, rotation, and alpha animations.

### 5. Godot-native advanced features

Implement features that map naturally to Godot:

- `Path2D` and `Curve2D` motion paths.
- Optional rotation alignment to a path.
- Shader parameter animation.
- Color and numeric interpolation helpers.
- Spring and bezier plugins where they add clear value.
- Conversion helpers for creating or controlling `AnimationPlayer` animations.

### 6. Editor integration

Extend the existing `EditorPlugin` only after the runtime is stable:

- Add an AnimeGodot dock.
- Inspect active timelines and targets.
- Preview, pause, reverse, and scrub animations.
- Create reusable animation `Resource` files.
- Provide an optional bridge to `AnimationPlayer`.

Do not make the editor dock a dependency of runtime playback.

### 7. Documentation and release

Add:

- README with installation and first examples.
- API reference for `Anime`, `AnimeContext`, `AnimeTween`, and `AnimeTimeline`.
- Migration notes explaining when to use native Tween, AnimationPlayer, or AnimeGodot.
- Changelog and semantic versioning.
- A minimal example project or demo scene.

## Suggested Directory Layout

```text
addons/animegodot/
├── plugin.cfg
├── plugin.gd
├── runtime/
│   ├── anime.gd
│   ├── anime_context.gd
│   ├── anime_easing.gd
│   ├── anime_property.gd
│   ├── anime_timeline.gd
│   └── anime_tween.gd
├── editor/
│   ├── anime_dock.gd
│   └── anime_inspector.gd
├── tests/
└── README.md
```

## Definition Of Done For Version 0.1

- The add-on can be enabled without editor errors.
- A script can animate a Node property with one concise call.
- Multiple properties can run in parallel.
- Timelines support sequencing and at least one relative position syntax.
- Animations clean up with their owner.
- The public API has focused tests and examples.
- Headless validation passes with Godot 4.7.1.

## Implementation Order

1. Runtime `Anime.to()` backed by native Tween.
2. Easing and property-path handling.
3. Context ownership and cleanup.
4. Callbacks and repeat controls.
5. Timelines, labels, and relative positions.
6. Overwrite management.
7. Motion paths and plugin registration.
8. Editor dock and AnimationPlayer integration.
9. Documentation, demo, and release cleanup.