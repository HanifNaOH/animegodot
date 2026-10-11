# FLIP Expandable Queue

Open `flip_expand_queue.tscn` and run the current scene. Each release step can expand to show its details. A root-based `Anime.create_layout()` controller animates the card's size and the position changes of every step below it through `layout.update()`.

This example focuses on size-changing reflow in a vertical `VBoxContainer`; the [grid/list demo](../flip_layout/README.md) covers switching between container layouts and reordering.