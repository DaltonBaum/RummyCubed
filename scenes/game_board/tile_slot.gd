extends PanelContainer


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return true
	
func _drop_data(at_position: Vector2, data: Variant) -> void:
	while get_child_count() > 0:
		var item := get_child(0)
		if data == item:
			return
		item.reparent(data.get_parent())
	data.reparent(self)
