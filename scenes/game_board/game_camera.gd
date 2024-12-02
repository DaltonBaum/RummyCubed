extends Camera2D

@export var fling_action: bool = true
@export var min_fling_velocity: float = 100.0
@export var deceleration: float = 2500.0
@export var min_zoom: float = 0.5
@export var max_zoom: float = 2
@export var zoom_sensitivity: int = 5
@export var zoom_increment: Vector2 = Vector2(0.02, 0.02)

var last_pinch_distance: float = 0
var events = {}

# Viewport size
var vp_size := Vector2.ZERO

# Initial velocity of the fling
var velocity_x: float = 0.0
var velocity_y: float = 0.0

# The Start and end positive of the fling
var start_position := Vector2.ZERO
var end_position := Vector2.ZERO

# Fling related variables
var fling_time: float = 0.0001
var ignore_fling : bool = false
var is_flying: bool = false
var is_moving: bool = false

var duration: float = 0.0001
var dx: float = 0.0
var dy: float = 0.0
var zoomed_to_min = false
var zoomed_to_max = false

var disabled = false

# Connects the viewport signal
func _ready() -> void:
	_on_viewport_size_changed()
	get_viewport().size_changed.connect(_on_viewport_size_changed)

func _process(delta) -> void:
	# If the camera is moving, update the duration
	if is_moving:
		duration += delta

	# If the camera is flying, set the next camera's position considering the velocity
	if is_flying:
		fling(velocity_x, velocity_y, delta)
	
	# Constrain camera position
	var x = vp_size.x / 2 / zoom.x
	var y = vp_size.y / 2 / zoom.y
	position.x = clamp(position.x, limit_left+x, limit_right-x)
	position.y = clamp(position.y, limit_top+y, limit_bottom-y)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var i = event.index

		if event.is_pressed():
			events[i] = event
			# If there is more than one finger at the screen, ignores the fling action
			ignore_fling = events.size() > 1 or !DragManager.is_currently_dragging()

			# Sets the camera as moving if the fling action is activated
			is_moving = fling_action
			if events.size() == 1 and !DragManager.is_currently_dragging():
				# Stores the event start position to calculate the velocity later
				start_position = event.position
				end_position = start_position
				last_pinch_distance = 0

			# In case the camera was flying, stops it
			finish_flying()

		# If it's not pressed
		else:
			if duration > 0 and is_moving and not ignore_fling:
				is_moving = false

				# If the fling action is activated and it's not to ignore the fling action
				if fling_action and not ignore_fling:
					if was_flinged(start_position, end_position, fling_time):
						is_flying = true

			# Erases this event from the dictionary
			events.erase(i)

			# The fling action will be ignored until the last finger leave the screen
			if events.size() == 0:
				ignore_fling = false
				is_moving = false

	if event is InputEventScreenDrag:
		if duration > 0.02 and is_moving and not ignore_fling:
			fling_time = duration
			duration = 0.0001
			start_position = end_position
			end_position = event.position

		var last_pos: Vector2 = events[event.index].position
		if last_pos.distance_to(event.position) > zoom_sensitivity:
			events[event.index] = event

		if events.size() == 1 and !DragManager.is_currently_dragging() and !disabled:
			position -= event.relative / zoom

		if events.size() > 1:
			# Stores the touches position
			var keys = events.keys()
			var p1: Vector2 = events[keys[0]].position
			var p2: Vector2 = events[keys[1]].position

			# Calculates the distance between them
			var pinch_distance: float = p1.distance_to(p2)
			if last_pinch_distance == 0:
				last_pinch_distance = pinch_distance


			if abs(pinch_distance - last_pinch_distance) > zoom_sensitivity:
				var new_zoom: Vector2
				if (pinch_distance < last_pinch_distance):
					new_zoom = zoom - zoom_increment * zoom
				else:
					new_zoom = zoom + zoom_increment * zoom

				zoom_at(new_zoom, (p1 + p2) / 2)
				last_pinch_distance = pinch_distance


# Updates the reference vp_size properly when the viewport change size
func _on_viewport_size_changed() -> void:
	var viewport := get_viewport()
	vp_size = viewport.get_visible_rect().size

func was_flinged(start_p: Vector2, end_p: Vector2, dt: float) -> bool:
	var vi: float = start_p.distance_to(end_p) / dt
	duration = vi / deceleration

	if vi >= min_fling_velocity:
		velocity_x = (start_p.x - end_p.x) / dt
		velocity_y = (start_p.y - end_p.y) / dt
		dx = velocity_x / duration
		dy = velocity_y / duration
		return true

	else:
		return false


func fling(vx: float, vy: float, dt: float) -> void:
	if disabled:
		return

	duration -= dt
	if duration > 0.0:
		if position.x > limit_right or position.x < limit_left:
			dx = velocity_x / 0.2
		if position.y > limit_bottom or position.y < limit_top:
			dy = velocity_y / 0.2

		# Calculates the next camera's position for both axis
		var npx = position.x + vx * dt
		var npy = position.y + vy * dt

		# Moves the camera to the next position
		position = Vector2(npx, npy)

		# Calculates the next velocity for both axis considering the deceleration
		velocity_x = vx - dx * dt
		velocity_y = vy - dy * dt

	else:
		finish_flying()

func finish_flying() -> void:
	is_flying = false
	duration = 0.0
	velocity_x = 0.0
	velocity_y = 0.0

func apply_zoom(new_zoom: Vector2) -> void:
	if disabled:
		return

	zoomed_to_min = false
	zoomed_to_max = false

	if new_zoom.x <= min_zoom:
		zoomed_to_min = true
		zoom = Vector2(min_zoom, min_zoom)
		return

	if new_zoom.x >= max_zoom:
		zoomed_to_max = true
		zoom = Vector2(max_zoom, max_zoom)
		return

	new_zoom.x = clamp(new_zoom.x, min_zoom, max_zoom)
	zoom = Vector2.ONE * new_zoom.x


func zoom_at(new_zoom: Vector2, point: Vector2) -> void:
	if disabled:
		return
		
	# In case the camera was flying, stops it
	finish_flying()

	var zoom_diff: Vector2
	zoom_diff = new_zoom - zoom

	point -= vp_size/2

	apply_zoom(new_zoom)

	if !zoomed_to_min and !zoomed_to_max:
		position += (point * zoom_diff)
