extends Camera2D

@export var start_zoom: float = 1
@export var max_zoom: float = 4
@export var min_zoom: float = 0.5
@export var zoom_speed: float = 0.9

@export var pan_margin: int = 0
@export var pan_speed: float = 50.0

func _ready() -> void:
	zoom = Vector2(start_zoom, start_zoom)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		var zoom_factor: float = zoom_speed * 1 * zoom.x
		zoom_factor = clamp(zoom_factor, min_zoom, max_zoom)
		zoom = Vector2(zoom_factor, zoom_factor)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		var zoom_factor: float = 1 * zoom.x / zoom_speed
		zoom_factor = clamp(zoom_factor, min_zoom, max_zoom)
		zoom = Vector2(zoom_factor, zoom_factor)
	
	if event is InputEventKey:
		if event.pressed:
			match event.physical_keycode:
				KEY_W:
					position -= Vector2(0, pan_speed) / zoom
				KEY_S:
					position -= Vector2(0, -pan_speed) / zoom
				KEY_A:
					position -= Vector2(pan_speed, 0) / zoom
				KEY_D:
					position -= Vector2(-pan_speed, 0) / zoom
