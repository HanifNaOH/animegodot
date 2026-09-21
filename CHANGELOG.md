# Changelog

## 1.0.0 - 2026-09-21

### Added

- `Anime.from_to()` for explicit start and end values.
- Keyframe arrays and per-property duration, delay, and easing options.
- Direct tween seek, reverse, restart, reset, progress, repeat delay, and direction controls.
- Rich stagger settings with `each`, `amount`, `from`, `grid`, `axis`, and easing support.
- Timeline defaults, autoplay, lifecycle callbacks, repeat, repeat delay, yoyo, and direction options.
- Dynamic interpolation for common Godot value types, containers, and custom interpolator Callables.
- Timeline sampling now shares direct tween track interpolation and supports dynamic per-property configurations.
- Added `ignore_time_scale` and idle/physics `process_mode` options for native tweens, motion paths, and timelines.
- Motion-path handles now support pause, resume, seek, reverse, restart, position, and progress controls.
- Typed runtime signals and ownership collections for tween, timeline, context, and motion-path lifecycles.

## 0.1.0 - 2026-09-13

### Added

- AnimeGodot runtime facade with Tween-backed property animation.
- Easing, callbacks, delay, repeat, yoyo, stagger, and target arrays.
- Timeline sequencing, labels, relative positions, nesting, seeking, and playback controls.
- Overwrite registry with `none`, `auto`, and `all` modes.
- Curve2D and Path2D motion paths with optional path alignment.
- Shader parameter paths, interpolation helpers, bezier interpolation, and spring interpolation.
- AnimationPlayer conversion and reusable animation resource export.
- AnimeGodot editor dock for preview and runtime inspection.
- GDVM v1.0.1 integration.
- GDVM-powered to-do list example application.

### Validation

- Godot 4.7.1 runtime and editor validation passes.
- AnimeGodot runtime and timeline tests pass.
- GDVM to-do ViewModel tests pass.
