extends PanelContainer


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return true
	
func _drop_data(at_position: Vector2, data: Variant) -> void:
	if data == get_child(0):
		return
	while get_child_count() > 0:
		var item := get_child(0)
		item.reparent(data.get_parent())
	data.reparent(self)
