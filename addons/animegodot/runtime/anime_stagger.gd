class_name AnimeStagger
extends RefCounted

const EASING_SCRIPT = preload("res://addons/animegodot/runtime/anime_easing.gd")


static func delay_for(index: int, count: int, value: Variant) -> float:
	if value is int or value is float:
		return maxf(float(value), 0.0) * index
	if not value is Dictionary or count <= 1:
		return 0.0

	var options: Dictionary = value
	var start := maxf(float(options.get(&"start", 0.0)), 0.0)
	var ranks := _ranks(count, options)
	var maximum_rank := 0.0
	for rank in ranks:
		maximum_rank = maxf(maximum_rank, rank)
	if is_zero_approx(maximum_rank):
		return start

	var amount := options.get(&"amount", null)
	var each := float(options.get(&"each", 0.0))
	if amount != null:
		each = float(amount) / maximum_rank
	var normalized := ranks[index] / maximum_rank
	if StringName(options.get(&"direction", &"normal")) == &"reverse":
		normalized = 1.0 - normalized
	if options.has(&"ease"):
		var easing := EASING_SCRIPT.resolve(options[&"ease"])
		normalized = float(Tween.interpolate_value(
			0.0,
			1.0,
			normalized,
			1.0,
			easing["transition"],
			easing["ease"]
		))
	return start + each * maximum_rank * normalized


static func maximum_delay(count: int, value: Variant) -> float:
	var maximum := 0.0
	for index in count:
		maximum = maxf(maximum, delay_for(index, count, value))
	return maximum


static func _ranks(count: int, options: Dictionary) -> Array[float]:
	var ranks: Array[float] = []
	var grid := options.get(&"grid", null)
	var from_value = options.get(&"from", 0)
	if grid is Array and grid.size() >= 2:
		var rows := maxi(int(grid[0]), 1)
		var columns := maxi(int(grid[1]), 1)
		var source_row := 0.0
		var source_column := 0.0
		if from_value is String and StringName(from_value) == &"center":
			source_row = (rows - 1) * 0.5
			source_column = (columns - 1) * 0.5
		elif from_value is String and StringName(from_value) == &"last":
			source_row = rows - 1
			source_column = columns - 1
		elif from_value is int:
			source_row = int(from_value) / columns
			source_column = int(from_value) % columns
		var axis := StringName(options.get(&"axis", &""))
		for index in count:
			var row := index / columns
			var column := index % columns
			if axis == &"x":
				ranks.append(absf(column - source_column))
			elif axis == &"y":
				ranks.append(absf(row - source_row))
			else:
				ranks.append(absf(row - source_row) + absf(column - source_column))
		return ranks

	var source_index := 0.0
	if from_value is String:
		match StringName(from_value):
			&"last":
				source_index = count - 1
			&"center":
				source_index = (count - 1) * 0.5
			&"edges":
				for index in count:
					ranks.append(minf(index, count - 1 - index))
				return ranks
	elif from_value is int or from_value is float:
		source_index = clampf(float(from_value), 0.0, count - 1)
	for index in count:
		ranks.append(absf(index - source_index))
	return ranks
