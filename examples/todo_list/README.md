# GDVM To-Do List Example

This example follows the same architecture as GDVM's `_12_simulation_dashboard` example:

```text
TodoList view
    -> TodoListViewModel
        -> TodoItemViewModel children
```

## ViewModel Responsibilities

`todo_list_view_model.gd` owns:

- The task collection.
- The draft input.
- The current filter.
- Derived counts and empty-state text.
- Add and clear commands.
- Child item change propagation.

`todo_item_view_model.gd` owns each task's title, completion state, status text, and toggle command.

## View Responsibilities

`todo_list.gd` owns a `GdvmBinder` and declares bindings directly:

- The draft `LineEdit` sends explicit `text_changed` events to `draft_text`, preserving the caret position while typing.
- Summary labels are one-way bound to derived ViewModel properties.
- The task `VBoxContainer` uses `bind_list()` with an item ViewModel factory.
- Each row owns its own binder and binds its child ViewModel.
- The view disposes its binder and ViewModel in `_exit_tree()`.

The scene remains visual-only; binding metadata is not stored in the `.tscn` file.

## AnimeGodot Row Motion

The view uses AnimeGodot for row lifecycle motion:

- New rows expand from zero height and fade in.
- Removed rows slide left, collapse, and fade out before the ViewModel removes them.

The remove action waits for the visible AnimeGodot exit tween before changing the ViewModel. GDVM's `on_removed` callback then queues the detached row safely, avoiding a free while the button signal is still being emitted.
