extends ColorRect

# The radar field
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	# Accept only draggable fielders
	if data is TextureRect and data.has_method("_get_drag_data"):
		return true
	return false

func _drop_data(at_position: Vector2, data: Variant):
	# Move the fielder to the new position
	# Ensure the fielder is a child of the radar (it already should be)
	data.position = at_position - (data.size * 0.5)
