# AnimeGodot Version 2.2 Plan

**Status:** Proposed. This document defines work for a future additive release; no runtime changes are implied by the plan itself.

## Goal

Address the timeline playback, timeline defaults, AnimationPlayer dock/export, and stagger-grid defects found in the v2 extension audit. Preserve the typed v2 API and avoid behavior changes outside the affected cases.

Build on the current v2 runtime and the implemented 2.1 work. The package version remains unchanged until implementation, release verification, and release approval are complete.

## Compatibility Rules

- Keep existing v2 call sites working; do not restore dictionary options or string property paths.
- Preserve established single-cycle playback and export behavior unless a bug fix requires a documented correction.
- Resolve timeline state from the current playhead, direction, iteration, and repeat schedule; do not rebuild playback from an endpoint when resuming or reversing mid-cycle.
- Defaults must be explicit typed overrides. Do not infer that a user left a field unset by comparing it with a legitimate value such as `0.0`, `false`, or `OUT_QUAD`.
- Represent AnimationPlayer choices with library identity as well as animation identity; animation names alone are not unique across libraries.

## Proposed Scope

### 7. Control FLIP Layout Transitions

Add `AnimeLayoutItem`, `AnimeLayoutOptions`, `AnimeLayoutRuntime`, and the `Anime.flip()` facade for existing Control items that persist through a layout change. Capture each layout slot's global rectangle before the caller mutates state; after Container reflow, apply the inverse position/size transform to its direct-child visual wrapper and tween the wrapper to its final transform.

The initial implementation requires the visual wrapper to remain a direct child of its layout Control, fill that slot, and use a zero pivot. It does not animate entering/exiting controls, reparenting, or cross-canvas moves. Those cases require explicit lifetime and coordinate-space policies and remain deferred.

**Current implementation:** The same-layout reorder/resize subset supports both explicit `Anime.flip()` item lists and reusable `Anime.create_layout(root).update(callback)` controllers, with VBox expansion and GridContainer reorder/resize integration tests. Enter/exit transitions and the other proposed audit fixes in this plan remain unimplemented.

### 1. Timeline Reverse From Current State

Calling `reverse()` during playback or while paused must continue from the current playhead in the opposite direction. It must not jump to the beginning or end before moving. Reversing a completed timeline should still play back from its completed endpoint; reversing twice should restore the original direction.

Preserve nested-entry state and callback semantics. A child already entered in the current cycle must be sampled at its current local time and must not restart or finish twice solely because the parent changed direction.

### 2. Resume Across Repeated Timeline Cycles

Resuming a paused timeline must finish the current cycle remainder, then execute all remaining repeat cycles and repeat delays. Preserve yoyo/direction alternation and one-based repeat callbacks. Pausing inside a repeat delay must resume the remaining delay rather than restart the full delay or skip directly to the next cycle.

Define and test whether reversing during a repeat delay reverses the delay position or begins the previous cycle immediately. Keep seconds-based and normalized seeking event behavior unchanged unless explicitly covered by a test.

### 3. Explicit Timeline Default Overrides

Timeline defaults currently infer inheritance from selected values and omit several `AnimeOptions` fields. Add an additive typed override model with an explicit unset/inherit state for every supported child option. It should cover duration, delay, ease, repeat count/delay, yoyo, direction, overwrite, speed scale, time-scale behavior, process mode, and callbacks where inheritance is appropriate.

Keep the existing `timeline.defaults` surface source-compatible during the transition. Document its existing behavior and provide a clear migration path to the explicit overlay; do not silently reinterpret concrete values in existing caller code. Define precedence as track options, then tween options, then explicit timeline defaults, then library defaults.

### 4. AnimationPlayer Dock Library Awareness

Track each dropdown item as a pair of animation-library name and animation name. Display a qualified label when names collide. Use the selected library for preview position/length, scrubbing, saving the current clip, and saving a library. Keep default-library workflows unchanged.

Handle missing or removed libraries and animations without invalid resource access. Refresh selection when the selected AnimationPlayer changes or its animation libraries change.

### 5. Fresh AnimationPlayer Export Duration

Export must not depend on a cached `tween.duration` after callers change options. Refresh or derive timing from the current options and tracks before writing keys. Set `Animation.length` from the final exported key times, including supported per-track delays and explicit keyframe positions, and ensure an empty or `SET` export has a documented length.

Unsupported tracks must not create an animation length that implies keys were exported when they were skipped. Preserve the current warning behavior for runtime-only accessors and unsupported easing/repeats.

### 6. Stagger Grid Capacity Validation

Define the grid layout contract relative to the batch target count. At minimum, reject a grid whose capacity is smaller than the target count before creating tweens; never allow off-grid indices to produce negative ranks or collapse edge staggering to zero. If partial rows or unused cells are supported, document their row/column mapping and edge-origin behavior.

Add a typed count-aware validation helper and a clear warning or failure result at the batch API boundary. Keep linear staggering unchanged when no grid is configured.

## Implementation Phases

1. **Regression contracts:** Add failing tests for mid-cycle reverse, paused repeat continuation, per-field default inheritance, named animation libraries, stale export duration, and undersized grids.
2. **Timeline state machine:** Correct reverse and resume scheduling from the current cycle/time, including repeat delays, yoyo, nested entries, and event ordering.
3. **Typed defaults:** Add the explicit timeline option overlay, precedence rules, copy behavior, and API documentation without breaking existing `timeline.defaults` callers.
4. **Dock library model:** Store library/name identity per item and route preview, scrub, and save operations through the selected library.
5. **Exporter and grid validation:** Recompute export timing from current tracks/options and validate grid capacity before batch creation.
6. **Release verification:** Run focused suites for each fix, the complete GUT suite, headless editor/plugin startup, and a manual dock check with both default and named libraries.

## Non-Goals

- Redesigning tween or timeline authoring syntax.
- Adding browser-specific GSAP features or selector-based targets.
- Expanding the typed accessor set as part of these bug fixes.
- Changing v2.1 time/progress semantics or reworking AnimationPlayer export beyond correct duration and library handling.
- Bumping `VERSION` or publishing a release before all acceptance criteria pass.

## Definition Of Done

- Mid-play and paused reverse preserve the current timeline playhead and nested-child state without jumps or duplicate lifecycle events.
- Pausing and resuming during active cycles and repeat delays completes the configured repeat/yoyo schedule exactly once.
- Explicit timeline defaults apply only fields the caller set and respect track/tween precedence.
- Dock preview, scrub, and save work for default and named animation libraries, including duplicate clip names.
- Exported animation length and key times reflect current options and tracks, not stale cached duration.
- Undersized grids fail clearly; valid grids produce non-negative, deterministic ranks for all supported origins/axes.
- The initial FLIP helper preserves geometry across supported same-layout reorder/resize transitions and restores final transforms after completion/cancellation.
- Focused regressions, the complete GUT suite, and headless editor/plugin startup pass on the supported Godot version.
- Existing user work remains untouched, and package version metadata changes only as part of an approved release.