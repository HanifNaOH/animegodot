extends Node3D

const ELEMENTS: Array[String] = [
	"H|Hydrogen", "He|Helium", "Li|Lithium", "Be|Beryllium", "B|Boron", "C|Carbon", "N|Nitrogen", "O|Oxygen", "F|Fluorine", "Ne|Neon",
	"Na|Sodium", "Mg|Magnesium", "Al|Aluminum", "Si|Silicon", "P|Phosphorus", "S|Sulfur", "Cl|Chlorine", "Ar|Argon", "K|Potassium", "Ca|Calcium",
	"Sc|Scandium", "Ti|Titanium", "V|Vanadium", "Cr|Chromium", "Mn|Manganese", "Fe|Iron", "Co|Cobalt", "Ni|Nickel", "Cu|Copper", "Zn|Zinc",
	"Ga|Gallium", "Ge|Germanium", "As|Arsenic", "Se|Selenium", "Br|Bromine", "Kr|Krypton", "Rb|Rubidium", "Sr|Strontium", "Y|Yttrium", "Zr|Zirconium",
	"Nb|Niobium", "Mo|Molybdenum", "Tc|Technetium", "Ru|Ruthenium", "Rh|Rhodium", "Pd|Palladium", "Ag|Silver", "Cd|Cadmium", "In|Indium", "Sn|Tin",
	"Sb|Antimony", "Te|Tellurium", "I|Iodine", "Xe|Xenon", "Cs|Cesium", "Ba|Barium", "La|Lanthanum", "Ce|Cerium", "Pr|Praseodymium", "Nd|Neodymium",
	"Pm|Promethium", "Sm|Samarium", "Eu|Europium", "Gd|Gadolinium", "Tb|Terbium", "Dy|Dysprosium", "Ho|Holmium", "Er|Erbium", "Tm|Thulium", "Yb|Ytterbium",
	"Lu|Lutetium", "Hf|Hafnium", "Ta|Tantalum", "W|Tungsten", "Re|Rhenium", "Os|Osmium", "Ir|Iridium", "Pt|Platinum", "Au|Gold", "Hg|Mercury",
	"Tl|Thallium", "Pb|Lead", "Bi|Bismuth", "Po|Polonium", "At|Astatine", "Rn|Radon", "Fr|Francium", "Ra|Radium", "Ac|Actinium", "Th|Thorium",
	"Pa|Protactinium", "U|Uranium", "Np|Neptunium", "Pu|Plutonium", "Am|Americium", "Cm|Curium", "Bk|Berkelium", "Cf|Californium", "Es|Einsteinium", "Fm|Fermium",
	"Md|Mendelevium", "No|Nobelium", "Lr|Lawrencium", "Rf|Rutherfordium", "Db|Dubnium", "Sg|Seaborgium", "Bh|Bohrium", "Hs|Hassium", "Mt|Meitnerium", "Ds|Darmstadtium",
	"Rg|Roentgenium", "Cn|Copernicium", "Nh|Nihonium", "Fl|Flerovium", "Mc|Moscovium", "Lv|Livermorium", "Ts|Tennessine", "Og|Oganesson",
]
const PHYSICAL_PROPERTIES: Array[String] = [
	"1.008|0.08988|-259.16|-252.88", "4.0026022|0.1786|-272.2|-268.93", "6.94|0.534|180.5|1329.85", "9.01218315|1.85|1286.85|2468.85",
	"10.81|2.08|2075.85|3926.85", "12.011|1.821|n/a|n/a", "14.007|1.251|-210|-195.79", "15.999|1.429|-218.79|-182.96",
	"18.9984031636|1.696|-219.67|-188.12", "20.17976|0.9002|-248.59|-246.05", "22.989769282|0.968|97.79|882.94", "24.305|1.738|649.85|1089.85",
	"26.98153857|2.7|660.32|2469.85", "28.085|2.329|1413.85|3264.85", "30.9737619985|1.823|n/a|n/a", "32.06|2.07|115.21|444.65",
	"35.45|3.2|-101.55|-34.04", "39.9481|1.784|-189.34|-185.85", "39.09831|0.862|63.55|758.85", "40.0784|1.55|841.85|1483.85",
	"44.9559085|2.985|1540.85|2835.85", "47.8671|4.506|1667.85|3286.85", "50.94151|6|1909.85|3406.85", "51.99616|7.19|1906.85|2670.85",
	"54.9380443|7.21|1245.85|2060.85", "55.8452|7.874|1537.85|2860.85", "58.9331944|8.9|1494.85|2926.85", "58.69344|8.908|1454.85|2729.85",
	"63.5463|8.96|1084.62|2561.85", "65.382|7.14|419.53|906.85", "69.7231|5.91|29.76|2399.85", "72.6308|5.323|938.25|2832.85",
	"74.9215956|5.727|n/a|n/a", "78.9718|4.81|220.85|684.85", "79.904|3.1028|-7.35|58.85", "83.7982|3.749|-157.37|-153.22",
	"85.46783|1.532|39.3|687.85", "87.621|2.64|776.85|1376.85", "88.905842|4.472|1525.85|2929.85", "91.2242|6.52|1854.85|4376.85",
	"92.906372|8.57|2476.85|4743.85", "95.951|10.28|2622.85|4638.85", "98|11|2156.85|4264.85", "101.072|12.45|2333.85|4149.85",
	"102.905502|12.41|1963.85|3694.85", "106.421|12.023|1554.9|2962.85", "107.86822|10.49|961.78|2161.85", "112.4144|8.65|321.07|766.85",
	"114.8181|7.31|156.6|2071.85", "118.7107|7.365|231.93|2601.85", "121.7601|6.697|630.63|1634.85", "127.603|6.24|449.51|987.85",
	"126.904473|4.933|113.7|184.25", "131.2936|5.894|-111.75|-108.1", "132.905451966|1.93|28.55|670.85", "137.3277|3.51|726.85|1844.85",
	"138.905477|6.162|919.85|3463.85", "140.1161|6.77|794.85|3442.85", "140.907662|6.77|934.85|3129.85", "144.2423|7.01|1023.85|3073.85",
	"145|7.26|1041.85|2999.85", "150.362|7.52|1071.85|1899.85", "151.9641|5.264|825.85|1528.85", "157.253|7.9|1311.85|2999.85",
	"158.925352|8.23|1355.85|3122.85", "162.5001|8.54|1406.85|2566.85", "164.930332|8.79|1460.85|2599.85", "167.2593|9.066|1528.85|2867.85",
	"168.934222|9.32|1544.85|1949.85", "173.0451|6.9|823.85|1195.85", "174.96681|9.841|1651.85|3401.85", "178.492|13.31|2232.85|4602.85",
	"180.947882|16.69|3016.85|5457.85", "183.841|19.25|3421.85|5929.85", "186.2071|21.02|3185.85|5595.85", "190.233|22.59|3032.85|5011.85",
	"192.2173|22.56|2445.85|4129.85", "195.0849|21.45|1768.25|3824.85", "196.9665695|19.3|1064.18|2969.85", "200.5923|13.534|-38.83|356.73",
	"204.38|11.85|303.85|1472.85", "207.21|11.34|327.46|1748.85", "208.980401|9.78|271.55|1563.85", "209|9.196|253.85|961.85",
	"210|6.35|301.85|336.85", "222|9.73|-71.15|-61.65", "223|1.87|26.85|676.85", "226|5.5|959.85|1736.85",
	"227|10|1226.85|3226.85", "232.03774|11.724|1749.85|4787.85", "231.035882|15.37|1567.85|4026.85", "238.028913|19.1|1132.15|4130.85",
	"237|20.45|638.85|4173.85", "244|19.816|639.35|3231.85", "243|12|1175.85|2606.85", "247|13.51|1339.85|3109.85",
	"247|14.78|985.85|2626.85", "251|15.1|899.85|1469.85", "252|8.84|859.85|995.85", "257|n/a|1526.85|n/a",
	"258|n/a|826.85|n/a", "259|n/a|826.85|n/a", "266|n/a|1626.85|n/a", "267|23.2|2126.85|5526.85",
	"268|29.3|n/a|n/a", "269|35|n/a|n/a", "270|37.1|n/a|n/a", "269|40.7|-147.15|n/a",
	"278|37.4|n/a|n/a", "281|34.8|n/a|n/a", "282|28.7|n/a|n/a", "285|14|n/a|3296.85",
	"286|16|426.85|1156.85", "289|14|66.85|146.85", "289|13.5|396.85|1126.85", "293|12.9|435.85|811.85",
	"294|7.17|449.85|609.85", "294|4.95|n/a|76.85",
]

const LAYOUTS: Array[StringName] = [&"table", &"sphere", &"helix", &"grid"]
const CATEGORY_NAMES: Array[String] = [
	"Reactive nonmetal", "Noble gas", "Alkali metal", "Alkaline earth", "Metalloid",
	"Post-transition", "Transition metal", "Lanthanide", "Actinide", "Halogen", "Unknown",
]
const CATEGORY_COLORS: Array[Color] = [
	Color(0.40, 0.82, 0.63), Color(0.30, 0.77, 0.82), Color(0.94, 0.48, 0.38),
	Color(0.94, 0.68, 0.36), Color(0.84, 0.81, 0.40), Color(0.51, 0.72, 0.83),
	Color(0.37, 0.79, 0.64), Color(0.40, 0.60, 0.82), Color(0.76, 0.52, 0.75),
	Color(0.88, 0.48, 0.59), Color(0.56, 0.62, 0.62),
]

const CARD_WIDTH := 0.94
const CARD_HEIGHT := 1.08
const TABLE_COLUMN_GAP := 1.05
const TABLE_ROW_GAP := 1.16
const SPHERE_RADIUS := 5.1
const HELIX_RADIUS := 4.35

@onready var _stage: Node3D = %ElementStage
@onready var _camera: Camera3D = %LayoutCamera
var _cards: Array[Node3D] = []
var _number_labels: Array[Label3D] = []
var _symbol_labels: Array[Label3D] = []
var _name_labels: Array[Label3D] = []
var _detail_labels: Array[Label3D] = []
var _active_tweens: Array[AnimeTweenRuntime] = []
var _mode_buttons: Dictionary = {}
@onready var _layout_status: Label = %LayoutStatus
@onready var _selection_status: Label = %SelectionStatus
var _current_layout: StringName = &"table"
var _remaining_tweens := 0
var _transitioning := false
var _orbit_dragging := false
var _pointer_rotation := Vector2.ZERO
var _zoom := 1.0
var _selected_index := -1


func _ready() -> void:
	for card in _stage.get_children():
		_cards.append(card as Node3D)
		_number_labels.append(card.get_node("AtomicNumber") as Label3D)
		_symbol_labels.append(card.get_node("Symbol") as Label3D)
		_name_labels.append(card.get_node("ElementName") as Label3D)
		_detail_labels.append(card.get_node("Details") as Label3D)
	_mode_buttons = {
		&"table": %TableButton,
		&"sphere": %SphereButton,
		&"helix": %HelixButton,
		&"grid": %GridButton,
	}
	for layout in LAYOUTS:
		(_mode_buttons[layout] as Button).pressed.connect(_change_layout.bind(layout))
	_update_layout_status()
	_update_selection_status()
	get_viewport().size_changed.connect(_update_camera_fit)
	_update_camera_fit()


func _process(delta: float) -> void:
	if _stage == null or _orbit_dragging:
		return
	var weight := 1.0 - exp(-9.0 * delta)
	_stage.rotation.x = lerp_angle(_stage.rotation.x, _pointer_rotation.x, weight)
	_stage.rotation.y = lerp_angle(_stage.rotation.y, _pointer_rotation.y, weight)


func _element_details(atomic_number: int) -> String:
	var properties := PHYSICAL_PROPERTIES[atomic_number - 1].split("|")
	return "MASS  %s u\nDENSITY  %s g/cm3\nMELTS  %s C\nBOILS  %s C" % [
		properties[0], properties[1], properties[2], properties[3]
	]


func _category_for(atomic_number: int) -> int:
	if atomic_number >= 109:
		return 10
	if atomic_number in [3, 11, 19, 37, 55, 87]:
		return 2
	if atomic_number in [4, 12, 20, 38, 56, 88]:
		return 3
	if atomic_number >= 57 and atomic_number <= 71:
		return 7
	if atomic_number >= 89 and atomic_number <= 103:
		return 8
	if atomic_number in [9, 17, 35, 53, 85, 117]:
		return 9
	if atomic_number in [2, 10, 18, 36, 54, 86, 118]:
		return 1
	if atomic_number in [5, 14, 32, 33, 51, 52, 84]:
		return 4
	if atomic_number in [13, 31, 49, 50, 81, 82, 83, 113, 114, 115, 116]:
		return 5
	if (
		(atomic_number >= 21 and atomic_number <= 30)
		or (atomic_number >= 39 and atomic_number <= 48)
		or (atomic_number >= 72 and atomic_number <= 80)
		or (atomic_number >= 104 and atomic_number <= 108)
	):
		return 6
	return 0


func _table_cell(atomic_number: int) -> Vector2i:
	if atomic_number == 1:
		return Vector2i(0, 0)
	if atomic_number == 2:
		return Vector2i(17, 0)
	if atomic_number >= 3 and atomic_number <= 4:
		return Vector2i(atomic_number - 3, 1)
	if atomic_number >= 5 and atomic_number <= 10:
		return Vector2i(atomic_number + 7, 1)
	if atomic_number >= 11 and atomic_number <= 12:
		return Vector2i(atomic_number - 11, 2)
	if atomic_number >= 13 and atomic_number <= 18:
		return Vector2i(atomic_number - 1, 2)
	if atomic_number >= 19 and atomic_number <= 36:
		return Vector2i(atomic_number - 19, 3)
	if atomic_number >= 37 and atomic_number <= 54:
		return Vector2i(atomic_number - 37, 4)
	if atomic_number >= 55 and atomic_number <= 57:
		return Vector2i(atomic_number - 55, 5)
	if atomic_number >= 58 and atomic_number <= 71:
		return Vector2i(atomic_number - 55, 7)
	if atomic_number >= 72 and atomic_number <= 86:
		return Vector2i(atomic_number - 69, 5)
	if atomic_number >= 87 and atomic_number <= 89:
		return Vector2i(atomic_number - 87, 6)
	if atomic_number >= 90 and atomic_number <= 103:
		return Vector2i(atomic_number - 87, 8)
	return Vector2i(atomic_number - 101, 6)


func _layout_transform(index: int, layout: StringName) -> Transform3D:
	var target_position := Vector3.ZERO
	var target_rotation := Vector3.ZERO
	var target_scale := Vector3.ONE
	var count := float(ELEMENTS.size())
	match layout:
		&"table":
			var cell := _table_cell(index + 1)
			target_position = Vector3((float(cell.x) - 8.5) * TABLE_COLUMN_GAP, (4.0 - float(cell.y)) * TABLE_ROW_GAP, 0.0)
		&"sphere":
			var phi := acos(-1.0 + 2.0 * float(index) / count)
			var theta := sqrt(count * PI) * phi
			var sin_phi := sin(phi)
			target_position = Vector3(
				sin_phi * cos(theta) * SPHERE_RADIUS,
				cos(phi) * SPHERE_RADIUS,
				sin_phi * sin(theta) * SPHERE_RADIUS
			)
			var yaw := atan2(target_position.x, target_position.z)
			var pitch := -atan2(target_position.y, Vector2(target_position.x, target_position.z).length())
			target_rotation = Vector3(pitch, yaw, 0.0)
			target_scale = Vector3.ONE * 0.72
		&"helix":
			var progress := float(index) / maxf(count - 1.0, 1.0)
			var angle := progress * TAU * 3.6
			target_position = Vector3(
				cos(angle) * HELIX_RADIUS,
				(0.5 - progress) * 12.0,
				sin(angle) * HELIX_RADIUS
			)
			var yaw := atan2(target_position.x, target_position.z)
			var pitch := -atan2(target_position.y, Vector2(target_position.x, target_position.z).length() * 2.0)
			target_rotation = Vector3(pitch, yaw, 0.0)
			target_scale = Vector3.ONE * 0.76
		&"grid":
			var columns := 5
			var rows := 5
			var per_layer := columns * rows
			var layers := ceili(count / float(per_layer))
			var column := index % columns
			var row := floori(float(index) / float(columns)) % rows
			var layer := floori(float(index) / float(per_layer))
			target_position = Vector3(
				(float(column) - float(columns - 1) * 0.5) * 1.16,
				(float(rows - 1) * 0.5 - float(row)) * 1.22,
				(float(layer) - float(layers - 1) * 0.5) * 1.28
			)
			target_scale = Vector3.ONE * 0.84
	return Transform3D(Basis.from_euler(target_rotation).scaled(target_scale), target_position)


func _change_layout(layout: StringName) -> void:
	if not LAYOUTS.has(layout):
		_sync_mode_buttons()
		return
	if _transitioning:
		return
	if layout == _current_layout and _selected_index < 0:
		return
	_transition_to(layout, -1)


func _select_element(index: int) -> void:
	if _transitioning or index < 0 or index >= _cards.size():
		return
	_transition_to(_current_layout, -1 if _selected_index == index else index)


func _transition_to(layout: StringName, selected_index: int) -> void:
	var previous_selection := _selected_index
	var layout_changed := layout != _current_layout
	_transitioning = true
	_set_mode_input_locked(true)
	_current_layout = layout
	_selected_index = selected_index
	_remaining_tweens = 0
	_active_tweens.clear()
	_update_layout_status()
	_update_selection_status()
	var duration := 0.9 if layout_changed else 0.55
	var camera_position_in_stage := _stage.to_local(_camera.global_position)
	for index in _cards.size():
		var target := _layout_transform(index, layout)
		var target_rotation := target.basis.get_euler()
		if index == selected_index:
			var toward_camera := (camera_position_in_stage - target.origin).normalized()
			var selected_scale := target.basis.get_scale() * Vector3(3.0, 2.65, 1.0)
			target.origin += toward_camera * 1.1
			toward_camera = (camera_position_in_stage - target.origin).normalized()
			var focus_up := Vector3.UP
			if absf(toward_camera.dot(focus_up)) > 0.98:
				focus_up = Vector3.FORWARD
			var facing_right := focus_up.cross(toward_camera).normalized()
			var facing_up := toward_camera.cross(facing_right).normalized()
			var facing_basis := Basis(facing_right, facing_up, toward_camera)
			target_rotation = facing_basis.get_euler()
			target.basis = facing_basis.scaled(selected_scale)
		var tween := Anime.tween(_cards[index])
		tween.options.duration = duration
		tween.options.delay = float((index * 37) % _cards.size()) * (0.0028 if layout_changed else 0.001)
		tween.options.ease = AnimeEase.OUT_BACK if index == selected_index else AnimeEase.OUT_CUBIC
		tween.track(AnimeNode3D.position_to(target.origin))
		tween.track(AnimeNode3D.rotation_to(target_rotation))
		tween.track(AnimeNode3D.scale_to(target.basis.get_scale()))
		_start_transition_tween(tween)
	if layout_changed:
		var camera_tween := Anime.tween(_camera)
		camera_tween.options.duration = duration
		camera_tween.options.ease = AnimeEase.OUT_CUBIC
		camera_tween.track(AnimeNode3D.position_to(Vector3(0.0, 0.0, _camera_fit_distance(layout) * _zoom)))
		_start_transition_tween(camera_tween)
	if previous_selection >= 0:
		_animate_element_labels(previous_selection, previous_selection == selected_index, duration)
	if selected_index >= 0 and selected_index != previous_selection:
		_animate_element_labels(selected_index, true, duration)


func _animate_element_labels(index: int, expanded: bool, duration: float) -> void:
	var targets := [
		[_number_labels[index], Vector3(0.30, 0.39, 0.14) if expanded else Vector3(0.0, 0.36, 0.105), Vector3.ONE * (0.42 if expanded else 1.0)],
		[_symbol_labels[index], Vector3(-0.28, 0.30, 0.14) if expanded else Vector3(0.0, 0.02, 0.108), Vector3.ONE * (0.34 if expanded else 1.0)],
		[_name_labels[index], Vector3(-0.28, 0.02, 0.14) if expanded else Vector3(0.0, -0.39, 0.108), Vector3.ONE * (1.2 if expanded else 1.0)],
		[_detail_labels[index], Vector3(-0.28, -0.12, 0.14) if expanded else Vector3(-0.27, -0.32, 0.11), Vector3.ONE * (1.0 if expanded else 0.0)],
	]
	_number_labels[index].horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if expanded else HORIZONTAL_ALIGNMENT_CENTER
	_symbol_labels[index].horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if expanded else HORIZONTAL_ALIGNMENT_CENTER
	_name_labels[index].horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if expanded else HORIZONTAL_ALIGNMENT_CENTER
	for target in targets:
		var label := target[0] as Label3D
		var tween := Anime.tween(label)
		tween.options.duration = duration
		tween.options.ease = AnimeEase.OUT_BACK if expanded else AnimeEase.OUT_CUBIC
		tween.track(AnimeNode3D.position_to(target[1]))
		tween.track(AnimeNode3D.scale_to(target[2]))
		_start_transition_tween(tween)


func _start_transition_tween(tween: AnimeTweenRuntime) -> void:
	_remaining_tweens += 1
	_active_tweens.append(tween)
	tween.completed.connect(_on_transition_tween_completed)
	tween.play()


func _on_transition_tween_completed(_tween: AnimeTweenRuntime) -> void:
	_remaining_tweens -= 1
	if _remaining_tweens > 0:
		return
	_active_tweens.clear()
	_transitioning = false
	_set_mode_input_locked(false)
	_sync_mode_buttons()


func _set_mode_input_locked(locked: bool) -> void:
	for button in _mode_buttons.values():
		(button as Button).mouse_filter = Control.MOUSE_FILTER_IGNORE if locked else Control.MOUSE_FILTER_STOP


func _sync_mode_buttons() -> void:
	for layout in LAYOUTS:
		if _mode_buttons.has(layout):
			(_mode_buttons[layout] as Button).button_pressed = layout == _current_layout


func _update_layout_status() -> void:
	if _layout_status == null:
		return
	_layout_status.text = "%s  /  %03d ELEMENTS" % [_current_layout.to_upper(), ELEMENTS.size()]


func _update_selection_status() -> void:
	if _selection_status == null:
		return
	if _selected_index < 0:
		_selection_status.text = "118 ELEMENTS  /  11 CLASSES"
		_selection_status.add_theme_color_override("font_color", Color(0.66, 0.74, 0.71))
		return
	var fields := ELEMENTS[_selected_index].split("|")
	var category := _category_for(_selected_index + 1)
	_selection_status.text = "%03d  %s  /  %s  /  %s" % [
		_selected_index + 1, fields[0], fields[1], CATEGORY_NAMES[category]
	]
	_selection_status.add_theme_color_override("font_color", CATEGORY_COLORS[category])


func _update_camera_fit() -> void:
	if _camera == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size.y <= 0.0:
		return
	_camera.position.z = _camera_fit_distance(_current_layout) * _zoom
	_camera.look_at(Vector3(0.0, 0.85, 0.0))


func _camera_fit_distance(layout: StringName) -> float:
	var viewport_size := get_viewport().get_visible_rect().size
	var aspect := viewport_size.x / maxf(viewport_size.y, 1.0)
	var vertical_extent := 18.5
	var horizontal_extent := 19.0
	var depth_extent := 0.0
	match layout:
		&"sphere":
			vertical_extent = 11.5
			horizontal_extent = 11.5
			depth_extent = SPHERE_RADIUS * 2.0
		&"helix":
			vertical_extent = 13.5
			horizontal_extent = HELIX_RADIUS * 2.0
			depth_extent = HELIX_RADIUS * 2.0
		&"grid":
			vertical_extent = 10.0
			horizontal_extent = 7.6
			depth_extent = 5.12
	var tangent := tan(deg_to_rad(_camera.fov * 0.5))
	var vertical_fit := vertical_extent / (2.0 * tangent) + depth_extent * 0.5
	var horizontal_fit := horizontal_extent / (2.0 * tangent * maxf(aspect, 0.45)) + depth_extent * 0.5
	return maxf(vertical_fit, horizontal_fit)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if _orbit_dragging:
			_orbit(event.relative)
		else:
			var viewport_size := get_viewport().get_visible_rect().size
			if viewport_size.x > 0.0 and viewport_size.y > 0.0:
				var normalized: Vector2 = event.position / viewport_size * 2.0 - Vector2.ONE
				_pointer_rotation = Vector2(-normalized.y * 0.24, -normalized.x * 0.42)
	elif event is InputEventScreenDrag:
		_orbit(event.relative)


func _pick_element(screen_position: Vector2) -> bool:
	var ray_origin := _camera.project_ray_origin(screen_position)
	var ray_end := ray_origin + _camera.project_ray_normal(screen_position) * 100.0
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collide_with_areas = true
	query.collision_mask = 1
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return false
	var picker := hit.get("collider") as Area3D
	if picker == null:
		return false
	var card := picker.get_parent() as Node3D
	var index := _cards.find(card)
	if index < 0:
		return false
	_select_element(index)
	return true


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _pick_element(event.position):
			get_viewport().set_input_as_handled()
			return
	elif event is InputEventScreenTouch and event.pressed:
		if _pick_element(event.position):
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_orbit_dragging = event.pressed
		elif event.pressed and event.button_index == MOUSE_BUTTON_LEFT and _selected_index >= 0:
			_select_element(_selected_index)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom = maxf(0.72, _zoom - 0.08)
			_update_camera_fit()
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom = minf(1.8, _zoom + 0.08)
			_update_camera_fit()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if _selected_index >= 0:
			_select_element(_selected_index)


func _orbit(relative: Vector2) -> void:
	_stage.rotation.y = fposmod(_stage.rotation.y - relative.x * 0.004, TAU)
	_stage.rotation.x = clampf(_stage.rotation.x - relative.y * 0.003, -0.65, 0.65)
	_pointer_rotation = Vector2(_stage.rotation.x, _stage.rotation.y)
