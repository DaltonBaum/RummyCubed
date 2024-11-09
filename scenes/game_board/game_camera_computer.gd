# -------------------------
# Poorly written/buggy implementation for a camera with mouse/keyboard
# DO NOT COPY, ITS BAD
# -------------------------

#extends Camera2D

#@export var start_zoom: float = 1
#@export var max_zoom: float = 4
#@export var min_zoom: float = 0.5
#@export var zoom_speed: float = 0.9
#
#@export var pan_speed: float = 50.0
#
#func _ready() -> void:
	#zoom = Vector2(start_zoom, start_zoom)
#
#func _input(event: InputEvent) -> void:
	#if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		#var zoom_factor: float = zoom_speed * 1 * zoom.x
		#zoom_factor = clamp(zoom_factor, min_zoom, max_zoom)
		#zoom = Vector2(zoom_factor, zoom_factor)
	#if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		#var zoom_factor: float = 1 * zoom.x / zoom_speed
		#zoom_factor = clamp(zoom_factor, min_zoom, max_zoom)
		#zoom = Vector2(zoom_factor, zoom_factor)
	#
	#if event is InputEventKey:
		#if event.pressed:
			#match event.physical_keycode:
				#KEY_W:
					#position -= Vector2(0, pan_speed) / zoom
				#KEY_S:
					#position -= Vector2(0, -pan_speed) / zoom
				#KEY_A:
					#position -= Vector2(pan_speed, 0) / zoom
				#KEY_D:
					#position -= Vector2(-pan_speed, 0) / zoom

extends Camera2D

@export var start_zoom: float = 1.0
@export var max_zoom: float = 4.0
@export var min_zoom: float = 0.5
@export var zoom_speed: float = 0.9
@export var zoom_sensitivity: float = 10.0
@export var pan_speed: float = 50.0

var events = {}
var last_drag_distance = 0.0
var debug_touch_active = false  # Enable this for simulated multi-touch testing in debug mode
var debug_second_touch_offset = Vector2(100, 100)  # Offset for the simulated second touch point

# Initialize zoom level when the camera is ready
func _ready() -> void:
	zoom = Vector2(start_zoom, start_zoom)

# Handle panning and zooming based on touch or mouse input
func _unhandled_input(event: InputEvent) -> void:
	# Handle touch start or mouse click
	if event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		if event.pressed:
			events[event.index] = event
		else:
			events.erase(event.index)
			if events.size() < 2:
				last_drag_distance = 0.0  # Reset distance when fewer than two points

	# Handle touch drag or mouse motion for panning and zooming
	elif event is InputEventScreenDrag or event is InputEventMouseMotion:
		# Track the event position for panning and zooming
		events[event.index] = event
		if events.size() == 1:
			position += event.relative.rotated(rotation) * zoom.x

		# Simulate pinch-to-zoom if debug touch is active
		elif events.size() == 2 or (debug_touch_active and events.size() == 1):
			var touch_positions = events.values()
			var first_touch = touch_positions[0].position
			var second_touch = touch_positions[1].position if events.size() == 2 else first_touch + debug_second_touch_offset

			# Calculate distance and adjust zoom based on the change
			var current_distance = first_touch.distance_to(second_touch)
			if abs(current_distance - last_drag_distance) > zoom_sensitivity:
				var zoom_factor = (1 + zoom_speed) if current_distance < last_drag_distance else (1 - zoom_speed)
				var new_zoom = clamp(zoom.x * zoom_factor, min_zoom, max_zoom)
				zoom = Vector2(new_zoom, new_zoom)
				last_drag_distance = current_distance  # Update last distance
