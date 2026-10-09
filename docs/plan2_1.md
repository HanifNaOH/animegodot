# AnimeGodot Version 2.1 Plan

**Status:** Implemented and verified in the current worktree; package release is pending.

## Goal

Add focused playback, lifecycle, and keyframe capabilities to the typed v2 API. Use the [GSAP Tween methods](https://gsap.com/docs/v3/GSAP/Tween#methods) as a comparison checklist, not as a requirement for feature parity. Prefer explicit Godot-friendly methods, properties, signals, and typed model objects.

The v2.1 release should remain additive for existing v2 callers. The typed property/accessor model and the v2 hard-migration policy remain unchanged.

## Current Baseline

AnimeGodot already provides:

- Playback controls: `play`, `pause`, `resume`, `restart`, `reverse`, `seek`, and `kill`.
- Basic state and position queries: `is_finished`, `is_paused`, `get_position`, and `get_progress`.
- Typed options for duration, delay, easing, repeat count/delay, yoyo, direction, speed scale, overwrite, and process mode.
- Start, update, completion, and kill callbacks, with corresponding lifecycle signals.
- Typed property-level cancellation through `kill_properties(Array[AnimePropertyKey])`.
- Value-only typed keyframes, custom interpolation callables, and independently controllable batch tweens.

Several GSAP method families therefore have existing equivalents. The 2.1 implementation avoids aliases that merely duplicate mutable `AnimeOptions` fields or existing signals.

## Compatibility Rules

- Preserve existing v2 calls and their observable behavior; additions must not require migration from 2.0.
- Do not reintroduce dictionary-based tween configuration, caller-authored property paths, or string-encoded timeline positions.
- Keep callbacks as `Callable`s and property selection as typed accessors/keys.
- Define timing, event ordering, repeat indexing, and capture semantics before freezing method names.
- Keep browser-specific facilities such as CSS selectors, ScrollTrigger, and GSAP plugins out of the core Godot runtime.

## Proposed Scope

### 1. Time And Progress Semantics

Tween `duration` and `get_total_duration()` include the longest track's delay, repeats, and repeat delays; `get_progress()` retains its prior normalized whole-tween meaning. `seek_progress()` maps 0-1 onto that duration. Because tracks may have independent timing overrides, iteration and local progress are queried with `get_track_iteration(track)` and `get_track_progress(track)`. Track iteration is one-based; progress is within the active iteration and reflects yoyo/direction.

Timeline `duration`, `get_position()`, and `get_progress()` remain cycle-local. `get_total_duration()` includes timeline delay and repeats; total position/progress span the full timeline run. `get_iteration()` is one-based. Zero-duration timelines report zero total duration and report total progress 1 only after completion. Normalized seeking samples the corresponding repeat/yoyo cycle and emits update, but suppresses lifecycle and timeline-entry events.

### 2. Lifecycle Events And Capture Controls

Tween repeat notifications are per track: `on_track_repeat(track, iteration)` and `track_repeated(tween, track, iteration)` fire when playback crosses into a one-based track iteration, in either direction. Timeline `on_repeat(iteration)` and `repeated(timeline, iteration)` fire when a new timeline iteration begins. Normalized or seconds-based seeking synchronizes repeat state without emitting repeat events. Reverse completion has a dedicated callback/signal before the generic completion callback/signal.

Add explicit capture lifecycle operations:

- `invalidate()` stops playback and clears sampled values so the next play captures the target's then-current values without discarding tracks or options. The original first-capture snapshot remains available to `revert()`.
- `revert()` stops playback, restores the original first-capture values for remaining tracks, and emits `reverted` and `killed` signals without invoking kill or completion callbacks. Timeline operations apply recursively to children.

Capture original values before any `FROM`, `FROM_TO`, or `SET` write. Specify how `revert()` interacts with completed, killed, timeline-owned, and partially overwritten tweens, including which callbacks/signals fire. A restore operation must remain safe if the target has been freed.

### 3. Typed Keyframe Segments

The current `AnimeTrack.set_keyframes(Array)` accepts type-checked values distributed evenly over a track's duration. `AnimeTrack.set_keyframe_points(Array[AnimeKeyframe])` adds optional typed points at explicit normalized progress values with per-segment easing/interpolation while retaining the uniform-value form.

Requirements:

- Validate each keyframe value with its track accessor.
- Make normalized point positions and easing deterministic for seeking, reversing, repeats, and yoyo.
- Preserve per-track options and custom interpolation behavior where compatible.
- Reject invalid or mixed segment definitions clearly rather than silently falling back.

Linear typed points preserve their times in AnimationPlayer export. Non-linear point easing and custom keyframe interpolators remain runtime-only. Function-based values, random-value syntax, and automatic repeat refresh are not included; revisit them only with a typed value-provider design and a concrete use case.

### 4. Documentation And Examples

Update the [v2 API reference](api_v2.md) with finalized timing and lifecycle semantics. Add concise examples for seeking by progress, repeat callbacks, invalidating captured values, reverting a tween, and constructing non-uniform typed keyframe segments.

## Implementation Phases

1. **Contract and prototype:** Complete. Time units, one-based iterations, event ordering, normalized keyframe positions, and snapshot rules are documented.
2. **Time and state API:** Complete. Added total-time queries, normalized seeking, track iteration/progress queries, and active/reversed state queries with focused tests.
3. **Lifecycle and capture:** Complete. Added repeat/reverse-completion events, `invalidate`, and `revert`; tests cover invalidation, `FROM_TO`, timeline children, and repeat callbacks.
4. **Typed segments:** Complete. Added `AnimeKeyframe` normalized points, runtime sampling, and linear AnimationPlayer export with focused tests.
5. **Release verification:** Complete. The full headless GUT suite passes 40/40, and headless editor/plugin startup reaches the ready state on Godot 4.7.1.

## Non-Goals

- GSAP API-name parity or a general `eventCallback` string dispatcher.
- Promise/thenable wrappers when Godot signals can be awaited directly.
- Selector-based targeting, DOM/CSS helpers, or browser-only plugins.
- Replacing Godot's AnimationPlayer or Tween systems.
- Breaking changes to the v2 typed accessor, options, or timeline-position contracts.

## Definition Of Done

- Existing v2 tests and examples continue to pass without source changes.
- New time queries and setters have documented, tested behavior across repeats, repeat delays, timelines, and per-track overrides.
- Lifecycle events fire exactly once per documented boundary and behave consistently under seek, reverse, restart, kill, and revert.
- `invalidate()` and `revert()` have defined behavior for every tween mode and freed targets.
- Typed keyframe points validate through their accessor and sample consistently in forward, reverse, repeat, and yoyo playback.
- The public API remains typed and Godot-oriented; no GSAP-specific string configuration is introduced.
- Full headless tests and editor/plugin load pass on the supported Godot version.