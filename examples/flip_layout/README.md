# FLIP Layout Demo

Open `flip_layout_demo.tscn` and run the current scene. Use **Grid** and **List** to change the Container layout, or **Move last to first** to reorder cards. The demo uses one `Anime.create_layout()` controller for the GridContainer; each change runs through `layout.update()` and animates the direct-child visual wrappers. Layout controls ignore mouse input during a transition so additional clicks cannot cancel or snap an in-flight animation.

The sample covers existing items that remain in one `GridContainer`. Enter/exit and reparent transitions are not part of the initial FLIP helper.