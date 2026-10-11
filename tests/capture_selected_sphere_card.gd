extends SceneTree

const DEMO_SCENE = preload("res://examples/periodic_table/periodic_table_demo.tscn")


func _initialize() -> void:
	call_deferred("_capture_selected")


func _capture_selected() -> void:
	var demo := DEMO_SCENE.instantiate() as Node3D
	root.add_child(demo)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	demo.call("_change_layout", &"sphere")
	await _wait_for_transition(demo)
	demo.call("_select_element", 25)
	await _wait_for_transition(demo)
	var image := root.get_texture().get_image()
	var path := OS.get_user_data_dir().path_join("periodic_selected_camera_focus.png")
	image.save_png(path)
	print("capture=", path)
	quit()


func _wait_for_transition(demo: Node) -> void:
	var waited_frames := 0
	while demo.get("_transitioning") and waited_frames < 180:
		await process_frame
		waited_frames += 1