extends Control

@onready var _grid: GridContainer = $OuterMargin/Page/Scroll/Grid
@onready var _scroll: ScrollContainer = $OuterMargin/Page/Scroll
@onready var _grid_button: Button = $OuterMargin/Page/Toolbar/GridButton
@onready var _list_button: Button = $OuterMargin/Page/Toolbar/ListButton
@onready var _reorder_button: Button = $OuterMargin/Page/Toolbar/ReorderButton
@onready var _layout_status: Label = $OuterMargin/Page/Header/LayoutStatus

var _slots: Array[Control] = []
var _visuals: Array[Control] = []
var _layout: AnimeLayoutRuntime
var _active_flip: AnimeLayoutRuntime
var _transitioning := false
var _grid_mode := true
var _grid_button_mouse_filter := Control.MOUSE_FILTER_STOP
var _list_button_mouse_filter := Control.MOUSE_FILTER_STOP
var _reorder_button_mouse_filter := Control.MOUSE_FILTER_STOP
var _scroll_mouse_filter := Control.MOUSE_FILTER_STOP
var _vertical_scrollbar_mouse_filter := Control.MOUSE_FILTER_STOP
var _horizontal_scrollbar_mouse_filter := Control.MOUSE_FILTER_STOP


func _ready() -> void:
	_grid_button_mouse_filter = _grid_button.mouse_filter
	_list_button_mouse_filter = _list_button.mouse_filter
	_reorder_button_mouse_filter = _reorder_button.mouse_filter
	_scroll_mouse_filter = _scroll.mouse_filter
	_vertical_scrollbar_mouse_filter = _scroll.get_v_scroll_bar().mouse_filter
	_horizontal_scrollbar_mouse_filter = _scroll.get_h_scroll_bar().mouse_filter
	for child in _grid.get_children():
		var slot := child as Control
		_slots.append(slot)
		_visuals.append(slot.get_node("Visual") as Control)
	_layout = Anime.create_layout(_grid)
	_grid_button.pressed.connect(_on_grid_pressed)
	_list_button.pressed.connect(_on_list_pressed)
	_reorder_button.pressed.connect(_on_reorder_pressed)
	_grid_mode = _grid.columns > 1
	_refresh_status()


func _on_grid_pressed() -> void:
	_change_layout(true)


func _on_list_pressed() -> void:
	_change_layout(false)


func _on_reorder_pressed() -> void:
	if _transitioning or _grid.get_child_count() < 2:
		return
	await _transition_layout(func() -> void:
		_grid.move_child(_grid.get_child(_grid.get_child_count() - 1), 0)
	)


func _change_layout(grid_mode: bool) -> void:
	if _transitioning:
		_sync_mode_buttons()
		return
	if _grid_mode == grid_mode:
		return
	var transitioned: bool = await _transition_layout(func() -> void: _apply_layout(grid_mode))
	if not transitioned:
		_sync_mode_buttons()
		return
	_refresh_status()


func _transition_layout(change: Callable) -> bool:
	if _transitioning:
		return false
	_transitioning = true
	_set_transition_controls_locked(true)
	var options := AnimeLayoutOptions.new()
	options.duration = 0.6
	options.ease = AnimeEase.OUT_CUBIC
	options.size_ease = AnimeEase.IN_OUT_CUBIC
	var flip := _layout
	_active_flip = flip
	await flip.update(
		func(_root: Control) -> void:
			change.call(),
		options
	)
	if _active_flip == flip:
		_active_flip = null
	_transitioning = false
	_set_transition_controls_locked(false)
	_sync_mode_buttons()
	return true


func _set_transition_controls_locked(locked: bool) -> void:
	_grid_button.mouse_filter = Control.MOUSE_FILTER_IGNORE if locked else _grid_button_mouse_filter
	_list_button.mouse_filter = Control.MOUSE_FILTER_IGNORE if locked else _list_button_mouse_filter
	_reorder_button.mouse_filter = Control.MOUSE_FILTER_IGNORE if locked else _reorder_button_mouse_filter
	_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE if locked else _scroll_mouse_filter
	_scroll.get_v_scroll_bar().mouse_filter = (
		Control.MOUSE_FILTER_IGNORE if locked else _vertical_scrollbar_mouse_filter
	)
	_scroll.get_h_scroll_bar().mouse_filter = (
		Control.MOUSE_FILTER_IGNORE if locked else _horizontal_scrollbar_mouse_filter
	)


func _sync_mode_buttons() -> void:
	_grid_button.button_pressed = _grid_mode
	_list_button.button_pressed = not _grid_mode


func _apply_layout(grid_mode: bool) -> void:
	_grid_mode = grid_mode
	_grid.columns = 3 if grid_mode else 1
	for index in _slots.size():
		var list_height := maxf(78.0, _visuals[index].get_combined_minimum_size().y)
		_slots[index].custom_minimum_size = Vector2(150.0, 122.0 if grid_mode else list_height)
	_grid.queue_sort()


func _refresh_status() -> void:
	if _layout_status == null:
		return
	_layout_status.text = "GRID  /  03 COLUMNS" if _grid_mode else "LIST  /  SINGLE COLUMN"