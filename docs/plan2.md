# AnimeGodot Version 2 Plan

## Goal

Redesign AnimeGodot's public animation API around typed property accessors and typed options. V2 removes string-keyed property names and string-encoded control values from user-facing calls. It is a hard migration: the v1 API is unsupported in v2.

The purpose is not to reproduce GSAP feature-for-feature. Keep the fluent authoring, timeline, and control ideas that fit Godot, while using Godot Nodes, Resources, Callables, and native animation systems where appropriate.

## Migration Policy

- V2 is a breaking major version.
- V1 calls such as `Anime.to(target, {"position": value})` are not supported by v2.
- Do not ship compatibility wrappers, dictionary fallbacks, or dual v1/v2 entry points in the v2 runtime.
- Update all bundled examples, tests, and documentation to v2 before release.
- Publish a migration guide for users moving from v1; it documents replacements but does not imply runtime compatibility.
- Users who need v1 behavior must remain on the v1 release line.

## Public API Contract

- A property is selected with a typed accessor, never a property-name string or `NodePath` supplied by the caller.
- Values supplied to built-in accessors have concrete GDScript types, such as `Vector2` for `Node2D.position` and `Color` for `CanvasItem.modulate`.
- Options are declared through typed fields, methods, or enums, not a `Dictionary` of string keys.
- Ease, overwrite, process mode, direction, and other closed option sets use enums or named constants with typed values.
- Callbacks use `Callable`.
- Timeline placement uses numeric positions or typed position/label objects, not expressions such as `"<+=0.2"`.
- Strings remain valid animation values where the animated property itself is textual. The restriction is on strings used as API identifiers and configuration keys.

The implementation may use `Variant` internally where required by GDScript, but the public accessors must constrain the target class and value type as tightly as GDScript allows. Target compatibility is validated when a track is attached if the language cannot express that relationship statically.

## V1 Inventory And V2 Disposition

Inventory is based on the runtime entry points, README examples, and `tests/test_anime_runtime.gd`.

| V1 surface | Observed behavior | V2 disposition |
| --- | --- | --- |
| `to`, `from`, `from_to`, immediate set | Creates and starts a handle immediately; `from` captures/restores the current value, `from_to` supplies both endpoints, set applies immediately. | Retain behavior, redesign around typed tracks and an explicit handle/play boundary. |
| Property selection | Dictionary keys become `StringName`/`NodePath`; nested indexed paths and shader paths are supported. Existence checking validates the root property, not every nested segment. | Remove caller-authored property paths. Replace with built-in typed accessors and custom getter/setter accessors with stable identity. |
| Track values and keyframes | Raw endpoints, arrays, and per-property dictionaries support keyframes, duration, delay, easing, repeat, direction, yoyo, and custom interpolation. | Redesign as typed track objects with typed per-track options and explicit keyframe values; do not accept track dictionaries. |
| Tween options | Duration, delay, easing, repeat (plus `loop` alias), repeat delay, yoyo, direction, stagger, overwrite, speed scale, time-scale behavior, process mode, autoplay, and lifecycle callbacks. | Retain relevant behavior through typed fields/enums and `Callable`s. Use a canonical repeat count; remove the string/dictionary option surface and `loop` alias. |
| Easing | Linear, sine, quad, cubic, quart, quint, expo, circ, back, bounce, elastic, and spring; each has in/out/in-out variants. Unknown names warn and fall back to out-quad. | Retain built-in curves as typed ease values. Invalid values should be rejected/diagnosed, not silently selected by string parsing. |
| Target arrays and stagger | Arrays of targets; stagger supports interval/amount, start delay, origin (including index/edges), reverse, easing, and grid/axis ranking. | Retain through `to_many`/`from_many`/`from_to_many`/`set_many`, typed target/track arrays, and enum-based `AnimeStaggerOptions`. |
| Tween controls and lifecycle | Handles expose signals and play, pause, resume, restart, reverse, seek, reset, kill, position, progress, speed scale, and finished state. | Retain where meaningful. Use typed methods/properties; keep progress reporting for tweens. |
| Timeline structure | Sequential entries, parallel-to-most-recent-start, nested timelines, callbacks, and labels. | Retain with typed entries and label tokens. |
| Timeline placement | Defaults to the cursor; accepts numeric positions, labels, and string expressions for previous start/end and offsets. | Remove the string parser. Use `AnimePosition` constructors and typed labels; preserve absolute, relative, and overlap placement. |
| Timeline controls/options | Pause, resume, restart, reverse, seek, kill, time scale; defaults, delay, repeat/loop, repeat delay, yoyo, direction, scheduling options, autoplay, callbacks. | Retain relevant behavior with typed options. The current timeline has position/seek but no public progress getter; do not claim v1 progress parity. |
| Interpolation | Built-in numeric, vector, rectangle, color, quaternion, plane, bounds, transform, array, and dictionary interpolation; discrete values switch at segment end. Custom interpolation accepts a `Callable`. | Retain the interpolation utility. Typed accessors constrain supported values; custom interpolators remain runtime-only. |
| Motion paths | `Curve2D`/`Path2D`, progress range, path alignment/rotation, repeats, callbacks, and playback controls. | V1 entry points are unsupported; typed motion-path support is explicitly deferred beyond phase 4. |
| Shader parameters | Addressed through a string path such as `material:shader_parameter/glow`. | V1 string paths are unsupported; typed shader-uniform access is explicitly deferred beyond phase 4. |
| AnimationPlayer conversion | V1 produced simple value tracks and did not preserve runtime easing, repeats, or custom interpolation. | Typed exporter supports native-path accessors with linear, non-repeating tracks; callable-only accessors stay runtime-only. |
| Editor dock | Previews/scrubs native AnimationPlayer clips, inspects runtime activity, and saves native animation resources. | Retain the dock; typed runtime-only tracks cannot be exported as native clips unless they provide a valid native track representation. |
| GSAP-only additions in the comparison | Selector strings, repeat refresh, yoyo ease, repeat/reverse callbacks, promises, plugins, ScrollTrigger, quick setters, and ticker utilities are not present in v1. | Out of v2 scope unless separately justified; do not imply parity with GSAP. |

The former v1 runtime suite has been replaced by `test_anime_v2_model.gd`, `test_anime_v2_public_api.gd`, and `test_anime_v2_runtime.gd`. Current coverage includes typed accessors/options, batch stagger, playback modes, overwrite, interpolation, typed timelines, and AnimationPlayer export boundaries. Motion-path and shader-uniform tests await their deferred typed APIs.

## Phase 1 API Prototype

This is the v2 design baseline for phase 2, with type/helper names still provisional. Built-in accessor factories take typed values and produce tracks with stable property identity. A tween has shared typed options; a track can override them.

```gdscript
var tween := Anime.tween(panel)
tween.options.duration = 0.8
tween.options.ease = AnimeEase.OUT_BACK

tween.track(AnimeControl.position_to(Vector2(400, 200)))

var alpha_track := AnimeCanvasItem.alpha_to(1.0)
alpha_track.options.duration = 0.3
alpha_track.options.delay = 0.2
tween.track(alpha_track)
tween.play()
```

Timeline placement uses tokens and constructors rather than string expressions:

```gdscript
var timeline := Anime.timeline(self)
timeline.add(tween)
var after_intro: AnimeLabel = timeline.add_label()
timeline.add(fade_tween, AnimePosition.after(after_intro, 0.2))
timeline.play()
```

Prototype requirements: `position_to` accepts a `Vector2`; `alpha_to` accepts a `float`; accessors declare compatible target classes and stable identities; attaching an accessor to an incompatible target reports an error. `AnimePosition.after` accepts a label token and numeric offset. The v2 builder is dormant until `play()`; timeline-added children are scheduled by the timeline. Phase 2 must verify this shape with multi-track, per-track options, overwrite, and timeline tests before names are frozen.

Phase 2 introduced the model types behind this sketch, including `AnimeTweenSpec`. Phase 3 now exposes typed tween factories, playback, multi-target helpers, and typed timeline scheduling; names shown here are implemented public names except where explicitly marked provisional in later design notes.

## Scope

### Core animation operations

- Typed `to`, `from`, `from_to`, and immediate-set operations.
- One or multiple tracks per tween, with shared options and per-track options where supported.
- Typed duration, delay, easing, repeat, repeat delay, yoyo, speed scale, overwrite, and process mode settings.
- Lifecycle callbacks and tween controls: play, pause, resume, reverse, restart, seek, kill, and completion state.
- Multiple targets and stagger, using typed collections and options.
- Existing conflict handling and safe cleanup when targets or owners leave the tree.

### Timelines

- Sequential and parallel entries, nested timelines, callbacks, and labels.
- Typed absolute and relative positions. Labels are typed tokens returned by the timeline, not string identifiers.
- Pause, resume, reverse, restart, seek, position reporting, and time-scale controls. Timeline progress APIs are a possible addition, not v1 parity.
- Typed timeline defaults and lifecycle callbacks.

### Godot-specific features

- Retain useful v1 features where they fit the typed model: motion paths, interpolation helpers, shader parameters, and AnimationPlayer conversion.
- Provide built-in typed accessors for a deliberately limited set of common Godot properties first. Expand from real usage rather than attempting exhaustive coverage.
- Provide an explicit typed custom-accessor API using getter/setter `Callable`s for user-defined properties. Accessors need stable identity for overwrite tracking.

## Native AnimationPlayer Boundary

`Animation` value tracks use Godot property paths. V2 callers must not provide property-name strings to AnimeGodot, but built-in typed accessors may translate their identity into a native path when exporting to an `Animation`.

- Support export for built-in accessors that can produce a valid native track path.
- A custom getter/setter accessor without a native path is runtime-only; conversion must report this clearly rather than silently creating a broken track.
- Shader parameter accessors need a dedicated typed representation and must not require a caller-authored string path.
- Test path resolution relative to the AnimationPlayer root and target node.

## Non-Goals

- Preserving source or binary compatibility with v1.
- Shipping a general string-path escape hatch in the v2 public runtime.
- Implementing every GSAP plugin or browser-specific feature such as CSS selectors and ScrollTrigger.
- Generating a typed accessor for every property on every Godot class before the first v2 release.
- Hiding Godot limitations: where GDScript cannot provide compile-time guarantees, validate explicitly and document the boundary.

## Implementation Phases

### 1. Inventory and contract

- **Complete.** Inventory v1 public methods, options, timeline syntax, property resolution, examples, and test coverage in “V1 Inventory And V2 Disposition”.
- **Complete.** Classify retained/redesigned behavior, runtime-only custom interpolation/motion paths, native-path export constraints, and removed string-based identifiers.
- **Complete.** Establish and validate the typed prototype for shared options, multiple tracks, per-track overrides, explicit playback, and typed timeline placement.

### 2. Typed model

- **Complete.** Added typed property accessors/tracks, tween and per-track options, easing and overwrite enums, and typed timeline positions/labels.
- **Complete.** Built-in position/modulate accessors use stable identities; custom accessors share identity through reusable property-key tokens.
- **Complete.** Accessors validate targets and values before reading/writing; tween specs reject incompatible or duplicate tracks.
- **Complete.** Added focused tests for option validation, accessor typing/identity, multiple tracks, and cross-timeline label rejection. Playback and registry integration were completed in phase 3.

### 3. Runtime and timeline migration

- **Complete.** Tween modes, options, tracks, callbacks, playback controls, and timelines now run from typed model objects; timeline placement uses typed positions/labels.
- **Complete.** Added `to_many`/`from_many`/`from_to_many`/`set_many` with independent handles, copied tracks/options, and typed stagger origins, amount/interval, grid, axis, reverse, and easing.
- **Complete.** Overwrite registration compares stable accessor identities; targeted tests cover partial conflicts and cleanup/control behavior.
- **Complete.** Removed the v1 dictionary runtime test suite and migrated the README and maintained tween examples to v2. Legacy v1 global class names are marked `V1Unsupported`.

### 4. Typed accessors and native integrations

- **Complete.** Added typed `Node2D` position/global-position/rotation/scale accessors alongside the initial `Control` and `CanvasItem` set.
- **Complete.** Custom getter/setter accessors remain runtime-capable; export skips them unless they provide a native path.
- **Complete.** Added typed AnimationPlayer conversion/installation for native-path tracks. It supports linear, non-repeating tracks and skips unsupported timing/custom interpolation with a warning.
- **Complete.** Interpolation helpers and typed runtime custom interpolators remain supported.
- **Deferred.** Motion-path and shader-uniform accessors remain unavailable through the v2 facade; their typed designs are deferred beyond this phase.
- **Complete.** Added tests for Node2D accessor validation and AnimationPlayer native-path export/runtime-only custom accessors.

### 5. Hard migration and release

- **Complete.** Removed the v1 dictionary parsers/runtime files and updated the editor dock to inspect the typed registry.
- **Complete.** Maintained examples and tests use the typed API; no v1 dictionary tween calls or legacy runtime references remain in them.
- **Complete.** Published [the v2 API reference](api_v2.md) and [the v1 migration guide](migration_v1_to_v2.md); marked `docs/plan.md` as the historical v1 plan.
- **Complete.** Bumped `VERSION` and `plugin.cfg` to 2.0.0 and documented the breaking release in `CHANGELOG.md`. V1 is unsupported by v2.
- **Complete.** Full headless GUT command and headless editor/plugin load exit successfully.

## Definition Of Done

- No public v2 animation call uses a string or dictionary to identify a property or configure a closed-set option.
- Built-in accessors enforce concrete value types at their public entry points and validate target compatibility.
- Custom accessors can animate user-defined values without property-name strings and participate correctly in overwrite tracking.
- Timelines use typed labels and positions; no string position parser remains in the v2 public path.
- Supported v1 behaviors have v2 tests; removed or constrained behaviors are listed in migration documentation.
- All maintained examples and tests use v2 exclusively.
- No v1 compatibility layer is shipped or advertised as supported.
- Headless tests pass and the editor plugin loads without errors on the project's supported Godot version.

Phase 5 release hard cut is complete for v2. Motion-path and shader-uniform animation remain intentionally deferred; they have no v1 dictionary entry point or compatibility path in this release.