class_name AnimeOverwrite
extends RefCounted

enum {
	NONE,
	AUTO,
	ALL,
}


static func is_valid(value: int) -> bool:
	return value >= NONE and value <= ALL