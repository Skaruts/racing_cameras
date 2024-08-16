@tool
class_name RacingOrbitCamera
extends RacingCamera

## An orbiting camera, controlled with the mouse. Only works while mouse
## is captured.
##[br][br]
## Must be child of the car node.
##
## A camera that orbits around the car, controlled with the mouse. The mouse wheel
## can also be used to move the camera closer or away from the car. Holding
## [code]Ctrl[/code] or [code]Shift[/code] will slow down or speed up the
## camera movement, respectively.
##
##[br][br]
## [color=white][b]Note:[/b][/color] the mouse controls will only work if the
## mouse is captured. The mouse can be captured by left-clicking, or uncaptured
## by pressing [code]escape[/code].
##[br][br]
## [color=white][b]Note:[/b][/color] This camera must be a child of the car node.
## If the car node is the scene root or the immediate parent, then the camera
## will automatically detect it. Otherwise the car node must be set manually,
## either by setting [member RacingCamera.follow_car] in the inspector, or using
## [method RacingCamera.set_car] through code.


var _pivot1:Node3D
var _pivot2:Node3D
var _cam_pos:Vector3

@export var stabilized         : bool  = true   ## If [code]true[/code], the camera will not be affected by the rotation of the car.
@export var default_distance   : float = 5      ## The default camera distance from the car.
@export var cam_speed          : float = 0.4    ## How fast the camera moves toward or away from the car, when turning the mouse wheel.
@export var min_distance       : float = 0.5    ## The minimum distance to the car.
@export var max_distance       : float = 20     ## The maximum distance to the car.
@export var invert_x_axis      : bool           ## Invert horizontal mouse movement.
@export var invert_y_axis      : bool           ## Invert vertical mouse movement.
@export var invert_mouse_wheel : bool           ## Invert mouse wheel movement.


func _on_enter_tree() -> void:
	_type = "RacingOrbitCamera"
	camera_name = "Orbit Camera"

	_init_car_from_owner()

	_pivot1 = Node3D.new()
	_pivot2 = Node3D.new()
	_cam = Camera3D.new()

	add_child(_pivot1)
	_pivot1.add_child(_pivot2)
	_pivot2.add_child(_cam)

	top_level = stabilized


func _on_ready() -> void:
	_cam_pos = Vector3(0, 0, default_distance)
	_cam.position = _cam_pos
	_pivot2.rotation.x = deg_to_rad(-25)


func _on_process(_delta: float) -> void:
	if stabilized or _car_base != _car_body:
		global_position = _car_body.global_position

	if not stabilized:
		global_rotation = _car_body.global_rotation

	if _cam.position != _cam_pos:
		_cam.position = _cam.position.lerp(_cam_pos, 0.1)


func _on_unhandled_input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return

	if event is InputEventMouseMotion:
		const DEG90 = PI/2

		var x_dir := -1 if invert_x_axis else 1
		var y_dir := -1 if invert_y_axis else 1
		_pivot1.rotate_y(-event.relative.x * x_dir * _shared.mouse_sensitivity)
		_pivot2.rotate_x(-event.relative.y * y_dir * _shared.mouse_sensitivity)
		_pivot2.rotation.x = clamp(_pivot2.rotation.x, -DEG90, DEG90)

	else:
		_check_mouse_wheel(event)


func _check_mouse_wheel(event:InputEvent) -> void:
	if event is InputEventMouseButton:
		var step := cam_speed
		if Input.is_key_pressed(KEY_SHIFT): step *= 2
		if Input.is_key_pressed(KEY_CTRL):  step /= 2

		if not invert_mouse_wheel:
			if   event.button_index == MOUSE_BUTTON_WHEEL_UP:   _cam_pos.z -= step
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN: _cam_pos.z += step
		else:
			if   event.button_index == MOUSE_BUTTON_WHEEL_UP:   _cam_pos.z += step
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN: _cam_pos.z -= step

		_cam_pos.z = clamp(_cam_pos.z, min_distance, max_distance)


func _on_set_active() -> void:
	_cam.current = _active
	set_process_unhandled_input(_active)

