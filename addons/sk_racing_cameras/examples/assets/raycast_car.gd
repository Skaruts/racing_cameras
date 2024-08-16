class_name ExampleRaycastCar
extends RigidBody3D


#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
#	for the camera plugin
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
func is_active() -> bool:
	return _active

func get_steering_input() -> float:
	return sign(steering_input)

#func _get_car_physicsbody() -> RigidBody3D:
	#return self
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=


@export var _active:bool = true

@export_category("Engine")
@export var engine_power:float = 7000

@export_category("Suspensions")
@export var suspension_rest_dist:float = 0.5
@export var spring_strength:float = 15000
@export var spring_damper:float = 1000
@export var wheel_radius:float = 0.33

@export_category("Steering")
@export var wheel_grip_curve:Curve
@export var steering_angle:float = 40
@export var steer_speed:float = 0.1
@export var unsteer_speed:float = 0.3


var accel_input:float
var steering_input:float

var steering_wheels:Array[ExampleRaycastWheel]
var traction_wheels:Array[ExampleRaycastWheel]
var steering_rotation:float
var wheels:Array[ExampleRaycastWheel]

var friction_factor:float = 0.1



func _ready() -> void:
	_init_input_actions()

	for wheel:ExampleRaycastWheel in $wheels.get_children():
		wheels.append(wheel)
		if wheel.is_steering: steering_wheels.append(wheel)
		if wheel.is_traction: traction_wheels.append(wheel)

	set_active(_active)


# just to facilitate the examples
func _init_input_actions() -> void:
	var _actions := {
		"accelerate" = [KEY_UP,    KEY_W, KEY_I],
		"brake"      = [KEY_DOWN,  KEY_S, KEY_K],
		"turn_left"  = [KEY_LEFT,  KEY_A, KEY_J],
		"turn_right" = [KEY_RIGHT, KEY_D, KEY_L],
		"recover"    = [KEY_ENTER],
	}

	for action:String in _actions:
		if not InputMap.has_action(action):
			InputMap.add_action(action)

		for key:Key in _actions[action]:
			var e := InputEventKey.new()
			e.keycode = key
			InputMap.action_add_event(action, e)


func _process(delta: float) -> void:
	accel_input = 0
	steering_input = 0

	if _active:
		accel_input = Input.get_axis("brake", "accelerate")
		steering_input = Input.get_axis("turn_right", "turn_left")

	steering_rotation = steering_input * steering_angle

	for wheel:ExampleRaycastWheel in steering_wheels:
		if steering_rotation != 0:
			var angle:float = clamp(wheel.rotation.y + steering_rotation, -steering_angle, steering_angle)
			var new_rotation:float = angle*delta
			wheel.rotation.y = lerpf(wheel.rotation.y, new_rotation, steer_speed)
		else:
			wheel.rotation.y = lerpf(wheel.rotation.y, 0, unsteer_speed)



func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("recover"):
		recover()


func set_active(enable: bool) -> void:
	_active = enable
	set_process_unhandled_key_input(enable)

	for wheel:ExampleRaycastWheel in wheels:
		set_physics_process(enable)


func recover() -> void:
	# need to wait a bit or it won't work sometimes
	await get_tree().physics_frame

	angular_velocity = Vector3.ZERO
	linear_velocity = Vector3.ZERO

	global_rotation = Vector3(0, global_rotation.y, 0)

	# add to the Y position, so it's relative to current ground elevation,
	# and to Z to help with when car is stuck on ledges
	global_position += global_basis.y + global_basis.z*2



