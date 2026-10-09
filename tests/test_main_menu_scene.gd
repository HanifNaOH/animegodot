extends GutTest

const APP_SCENE = preload("res://examples/main_menu/main_menu.tscn")


func test_main_menu_targets_buttons_and_binds_selection() -> void:
	var app = APP_SCENE.instantiate()
	add_child_autoqfree(app)
	await wait_process_frames(2)

	var continue_button: Button = app.get_node("Page/Column/MainArea/MenuColumn/MenuButtons/ContinueButton")
	var settings_button: Button = app.get_node("Page/Column/MainArea/MenuColumn/MenuButtons/SettingsButton")
	var hand: Control = app.get_node("HandIndicator")
	var selection_label: Label = app.get_node("Page/Column/MainArea/MenuColumn/SelectionReadout/SelectedOption")
	var selection_detail: Label = app.get_node("Page/Column/MainArea/MenuColumn/SelectionReadout/SelectionDetail")

	continue_button.grab_focus()
	await wait_process_frames(1)
	_assert(app.get("_target_button") == continue_button, "Initial keyboard focus should target the hand")

	settings_button.grab_focus()
	await wait_process_frames(1)
	_assert(app.get("_target_button") == settings_button, "Keyboard focus should move the hand target")

	continue_button.mouse_entered.emit()
	_assert(app.get("_target_button") == continue_button, "Pointer hover should move the hand target")
	await wait_seconds(0.35)
	_assert(hand.position.distance_to(app.get_hand_target_position(continue_button)) < 1.0, "The hand should animate to the hovered button")

	settings_button.pressed.emit()
	await wait_process_frames(1)
	_assert(app.view_model.selected_option == &"settings", "The RelayCommand should update the selected option")
	_assert(selection_label.text == "SELECTED / SETTINGS", "The binder should update the selected-option label")
	_assert(selection_detail.text == "Adjust the way your world feels and sounds.", "The binder should update the selected-option detail")

	app.queue_free()
	await wait_process_frames(3)


func _assert(condition: bool, message: String) -> void:
	assert_true(condition, message)