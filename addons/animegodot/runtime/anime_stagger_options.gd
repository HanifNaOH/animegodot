class_name AnimeStaggerOptions
extends RefCounted

enum Origin {
	FIRST,
	CENTER,
	LAST,
	EDGES,
	INDEX,
}

enum Axis {
	BOTH,
	HORIZONTAL,
	VERTICAL,
}

var each: float = 0.0
var amount: float = -1.0
var start_delay: float = 0.0
var origin: int = Origin.FIRST
var origin_index: int = 0
var grid_size: Vector2i = Vector2i.ZERO
var axis: int = Axis.BOTH
var reversed: bool = false
var ease: int = AnimeEase.LINEAR


func is_valid() -> bool:
	return (
		is_finite(each)
		and each >= 0.0
		and is_finite(amount)
		and amount >= -1.0
		and is_finite(start_delay)
		and start_delay >= 0.0
		and origin >= Origin.FIRST
		and origin <= Origin.INDEX
		and (grid_size == Vector2i.ZERO or (grid_size.x > 0 and grid_size.y > 0))
		and axis >= Axis.BOTH
		and axis <= Axis.VERTICAL
		and AnimeEase.is_valid(ease)
	)


func delay_for(index: int, count: int) -> float:
	if not is_valid() or count <= 1 or index < 0 or index >= count:
		return start_delay
	var maximum_rank := 0.0
	for target_index in count:
		maximum_rank = maxf(maximum_rank, _rank_for(target_index, count))
	if is_zero_approx(maximum_rank):
		return start_delay
	var rank := _rank_for(index, count)
	var normalized := rank / maximum_rank
	if reversed:
		normalized = 1.0 - normalized
	var spread := amount if amount >= 0.0 else each * maximum_rank
	return start_delay + spread * AnimeEase.weight(ease, normalized)


func _rank_for(index: int, count: int) -> float:
	if grid_size != Vector2i.ZERO:
		var columns := grid_size.x
		var rows := grid_size.y
		var source_row := 0.0
		var source_column := 0.0
		match origin:
			Origin.CENTER:
				source_row = (rows - 1) * 0.5
				source_column = (columns - 1) * 0.5
			Origin.LAST:
				source_row = rows - 1
				source_column = columns - 1
			Origin.INDEX:
				var source_index := clampi(origin_index, 0, count - 1)
				source_row = source_index / columns
				source_column = source_index % columns
		var row := index / columns
		var column := index % columns
		if origin == Origin.EDGES:
			return minf(minf(row, rows - 1 - row), minf(column, columns - 1 - column))
		match axis:
			Axis.HORIZONTAL:
				return absf(column - source_column)
			Axis.VERTICAL:
				return absf(row - source_row)
			_:
				return absf(row - source_row) + absf(column - source_column)
	var source := 0.0
	match origin:
		Origin.CENTER:
			source = (count - 1) * 0.5
		Origin.LAST:
			source = count - 1
		Origin.INDEX:
			source = clampf(float(origin_index), 0.0, count - 1)
	return minf(index, count - 1 - index) if origin == Origin.EDGES else absf(index - source)