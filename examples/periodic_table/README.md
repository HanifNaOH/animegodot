# Periodic Table Auto Layout

Open `periodic_table_demo.tscn` and run the current scene. The 118 element cards animate between table, sphere, helix, and a five-layer 3D box grid; sphere and helix cards orient along their 3D position. Move the pointer to orbit, or right-drag for direct control. Click a card to expand its physical properties; click it again, click the background, press Escape, or switch layouts to collapse it. Use the mouse wheel to zoom.

Layout targets are computed directly from each element's index and table coordinates; no dynamic-programming pass is needed.