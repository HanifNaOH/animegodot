extends PanelContainer

const BINDER_SCRIPT = preload("res://addons/gdvm/core/binding/gdvm_binder.gd")

signal remove_requested(item_id: int)

var _view_model
var _binder

@onready var _check: CheckButton = %Check
@onready var _title: Label = %Title
@onready var _status: Label = %Status
@onready var _remove: Button = %Remove


func _ready() -> void:
	_remove.pressed.connect(_on_remove_pressed)
	pivot_offset_ratio = Vector2(0.5, 0.5)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func set_item_view_model(view_model) -> bool:
	if _binder != null:
		_binder.dispose()
	_view_model = view_model
	_binder = BINDER_SCRIPT.new(self)
	if not _binder.set_view_model(_view_model):
		return false
	_binder.bind(_title, &"title", "text")
	_binder.bind(_status, &"status_text", "text")
	_binder.bind(_check, &"completed", "button_pressed", {
		"mode": BINDER_SCRIPT.Mode.TWO_WAY,
		"signal": &"toggled",
	})
	return true


func _on_remove_pressed() -> void:
	if _view_model != null:
		remove_requested.emit(_view_model.id)


func get_item_id() -> int:
	return _view_model.id if _view_model != null else -1


func _on_mouse_entered() -> void:
	Anime.to(self, {
		"scale": Vector2(1.02, 1.02),
		"duration": 0.12,
		"ease": Anime.EASE_OUT_QUAD,
		"overwrite": Anime.OVERWRITE_AUTO,
	})


func _on_mouse_exited() -> void:
	Anime.to(self, {
		"scale": Vector2.ONE,
		"duration": 0.14,
		"ease": Anime.EASE_OUT_QUAD,
		"overwrite": Anime.OVERWRITE_AUTO,
	})


func _exit_tree() -> void:
	if _binder != null:
		_binder.dispose()
