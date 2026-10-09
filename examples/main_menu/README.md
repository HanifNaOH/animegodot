# GDVM Main Menu Example

This standalone example pairs a button-driven main menu with one GDVM ViewModel. It demonstrates:

- `ObservableObject` selection state and a `RelayCommand` for menu activation.
- Code-first `GdvmBinder` setup and disposal in the view.
- AnimeGodot motion that points a movable hand indicator at the hovered or focused button.
- Keyboard focus navigation alongside pointer interaction.

The menu choices update the selected-option readout; they do not launch game screens or quit the project. The illustrated guide and hand are scene placeholders. Replace the figure with the supplied character art when available, keeping the hand/arm independently movable or attaching an overlay hand sprite to `HandIndicator`.

Open `main_menu.tscn` in Godot to run the example.