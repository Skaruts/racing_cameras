@tool
class_name RacingCockpitCamera
extends RacingCamera

## A cockpit camera, that can controlled with the mouse.
##[br][br]
## Must be child of the car node, and be adjusted to the correct cockpit position.
##
## A cockpit camera, that can controlled with the mouse.
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


var _pivot:Node3D


func _on_enter_tree() -> void:
	pass


func _on_ready() -> void:
	_type = "RacingCockpitCamera"
	camera_name = "Cockpit Camera"
	_init_car_from_owner()

	var pos := global_position
	var rot := global_rotation

	global_position = _car_body.global_position
	global_rotation = _car_body.global_rotation

	_pivot = Node3D.new()
	add_child(_pivot)
	_cam = Camera3D.new()
	_pivot.add_child(_cam)

	_pivot.global_position = pos
	_pivot.global_rotation = rot


func _on_set_active() -> void:
	_cam.current = _active
	set_process_unhandled_input(_active)


func _on_unhandled_input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return

	if event is InputEventMouseMotion:
		const DEG90 = PI/2

		_pivot.rotate_y(-event.relative.x * _shared.mouse_sensitivity)
		_cam.rotate_x(-event.relative.y * _shared.mouse_sensitivity)

		var y_limit := deg_to_rad(160)
		_pivot.rotation.y = clamp(_pivot.rotation.y, -y_limit, y_limit)
		_cam.rotation.x = clamp(_cam.rotation.x, -DEG90, DEG90)


func _on_process(_delta: float) -> void:
	# if the parent isn't the car's physics body, then this camera will need to catch up to it
	if _car_base != _car_body:
		global_position = _car_body.global_position
		global_rotation = _car_body.global_rotation

