extends GutTest

const APP_SCENE = preload("res://examples/todo_list/todo_list.tscn")


func test_todo_scene() -> void:
	var app = APP_SCENE.instantiate()
	add_child_autoqfree(app)
	await wait_process_frames(2)
	var draft: LineEdit = app.get_node("Page/Column/AddRow/Draft")
	_assert(draft.layout_direction == Control.LAYOUT_DIRECTION_LTR, "The draft input should use LTR layout")
	_assert(draft.text_direction == Control.TEXT_DIRECTION_LTR, "The draft input should use LTR text direction")
	_assert(draft.alignment == HORIZONTAL_ALIGNMENT_RIGHT, "The draft input should align text to the right")
	var list: VBoxContainer = app.get_node("Page/Column/ListFrame/ListColumn/TodoScroll/TodoList")
	_assert(list.get_child_count() == 3, "The bound list should create the seeded rows")
	var first_row := list.get_child(0)
	var remove_button: Button = first_row.get_node("Row/Remove")
	remove_button.pressed.emit()
	await wait_process_frames(1)
	_assert(list.get_child_count() == 3, "The row should remain visible during its exit animation")
	await wait_seconds(0.24)
	_assert(list.get_child_count() == 2, "Removing a row should reconcile the bound list after animation")
	app.queue_free()
	await wait_process_frames(3)


func _assert(condition: bool, message: String) -> void:
	assert_true(condition, message)
