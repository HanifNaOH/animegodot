extends GutTest

const VIEW_MODEL_SCRIPT = preload("res://examples/todo_list/todo_list_view_model.gd")


func test_todo_view_model() -> void:
	var view_model = VIEW_MODEL_SCRIPT.new()
	var observed_state := {"remaining": -1}
	view_model.changed.connect(func(_property_name: StringName, _old_value, new_value):
		if new_value is Dictionary and new_value.has("remaining_count"):
			observed_state["remaining"] = new_value["remaining_count"]
	)
	_assert(view_model.total_count == 3, "The demo should seed three tasks")
	_assert(view_model.remaining_count == 2, "The demo should seed two open tasks")
	_assert(view_model.completed_count == 1, "The demo should seed one completed task")

	view_model.draft_text = "Write the first test"
	_assert(view_model.add_command.can_execute(), "The add command should enable for non-empty draft text")
	view_model.add_command.execute()
	_assert(view_model.total_count == 4, "Adding a task should append one item")
	_assert(view_model.remaining_count == 3, "Adding an open task should update the remaining count")
	_assert(view_model.draft_text.is_empty(), "Adding a task should clear the draft")

	view_model.filter = "open"
	_assert(view_model.visible_items.size() == 3, "The open filter should exclude completed tasks")
	view_model.visible_items[0].completed = true
	await wait_process_frames(2)
	_assert(view_model.remaining_count == 2, "Changing a child item should update aggregate counts")
	_assert(observed_state["remaining"] == 2, "Aggregate change notifications should use the committed child value; observed=%d" % observed_state["remaining"])
	_assert(view_model.visible_items.size() == 2, "The open filter should react to child completion")

	view_model.filter = "completed"
	_assert(view_model.visible_items.size() == 2, "The completed filter should show completed tasks")
	view_model.clear_completed_command.execute()
	_assert(view_model.total_count == 2, "Clearing completed tasks should remove completed items")
	_assert(view_model.completed_count == 0, "Clearing completed tasks should reset completed count")

	view_model.remove_item(view_model.items[0].id)
	_assert(view_model.total_count == 1, "Removing a task should remove its item")
	view_model.dispose()


func _assert(condition: bool, message: String) -> void:
	assert_true(condition, message)
