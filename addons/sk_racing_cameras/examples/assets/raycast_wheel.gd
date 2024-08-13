class_name ExampleRaycastWheel
extends RayCast3D

@export var is_traction := false
@export var is_steering := false

@onready var car:ExampleRaycastCar = $"../.."
@onready var mesh:Node3D = get_child(0)

var previous_spring_length:float = 0

# tire circumference = PI * diameter
@onready var tire_circumference:float = PI * car.wheel_radius*2.0
var last_pos:Vector3

var grip_factor:float = 0.6
var mass:float = 30



func _ready() -> void:
	add_exception(car)
	#tire_circumference = PI * car.wheel_radius*2.0



func _get_point_velocity(point:Vector3) -> Vector3:
	return car.linear_velocity + car.angular_velocity.cross(point - car.global_position)



func _get_point_velocity2(point:Vector3) -> Vector3:
	var state := PhysicsServer3D.body_get_direct_state(car.get_rid())
	return state.get_velocity_at_local_position(point-car.global_position)



func _physics_process(delta: float) -> void:
	if is_colliding():
		var collision_point := get_collision_point()

		_suspension(delta, collision_point)
		_acceleration(collision_point)
		_apply_z_force(collision_point)
		_apply_x_force(delta, collision_point)

		set_mesh_position(to_local(collision_point).y + car.wheel_radius)
		_spin_wheel_meshes()
	else:
		set_mesh_position(-car.suspension_rest_dist)
	#_rotate_mesh(delta)



func _rotate_mesh(delta:float) -> void:
	var dir := car.basis.z
	#var rotation_dir := sign(car.linear_velocity.dot(dir))
	var rotation_dir := 1 if car.linear_velocity.dot(dir) > 0 else -1

	mesh.rotate_x(rotation_dir * car.linear_velocity.length() * delta)




func _spin_wheel_meshes() -> void:
	var move_dir:float = 1 if car.linear_velocity.dot(car.basis.z) > 0 else -1
	# I believe the line above could also be done like by this
	#var move_dir:float = sign(car.linear_velocity.dot(car.basis.z))

	var pos_diff:float = global_position.distance_to(last_pos)
	var spin := ((pos_diff * move_dir) / tire_circumference) * 360

	mesh.rotate_x(deg_to_rad(spin))
	last_pos = global_position



func set_mesh_position(new_y:float) -> void:
	mesh.position.y = lerpf(mesh.position.y, new_y, 0.6)



# lateral force
func _apply_x_force(delta: float, collision_point: Vector3) -> void:
	var force_dir := global_basis.x
	var tire_world_vel:Vector3 = _get_point_velocity2(global_position)
	var lateral_vel := force_dir.dot(tire_world_vel)

	if is_zero_approx(tire_world_vel.length()):
		grip_factor = 1
	else:
		grip_factor = car.wheel_grip_curve.sample(
			abs(lateral_vel) / tire_world_vel.length()
		)

	var desired_vel_change := -lateral_vel * grip_factor
	var x_force := desired_vel_change / delta
	var force := force_dir * x_force * mass

	var force_point := Vector3(collision_point.x, collision_point.y + car.wheel_radius, collision_point.z)
	car.apply_force(force, force_point - car.global_position)



# drag or friction force
func _apply_z_force(collision_point:Vector3) -> void:
	var force_dir := global_basis.z
	var tire_world_vel:Vector3 = _get_point_velocity(collision_point)

	var z_force := force_dir.dot(tire_world_vel) * car.mass / 10
	var force := -force_dir * z_force

	var force_point := Vector3(collision_point.x, collision_point.y + car.wheel_radius, collision_point.z)
	car.apply_force(force, force_point - car.global_position)



func _acceleration(collision_point:Vector3) -> void:
	if not is_traction: return

	var accel_dir:Vector3 = -global_basis.z
	var torque:float = car.accel_input * car.engine_power

	var force_point := Vector3(collision_point.x, collision_point.y + car.wheel_radius, collision_point.z)

	var force := accel_dir * torque
	car.apply_force(force, force_point - car.global_position)



func _suspension(delta: float, collision_point:Vector3) -> void:
	# the direction the suspension for will be applied
	var susp_dir:Vector3 = global_basis.y

	var raycast_origin:Vector3 = global_position
	var distance:float = collision_point.distance_to(raycast_origin)

	var spring_length:float = clamp(distance - car.wheel_radius, 0, car.suspension_rest_dist)
	var spring_force:float = car.spring_strength * (car.suspension_rest_dist - spring_length)

	var spring_velocity:float = (previous_spring_length - spring_length) / delta
	var damper_force:float = (car.spring_damper * spring_velocity)

	var suspension_force:float = (spring_force + damper_force)
	#var suspension_force:Vector3 = basis.y * (spring_force + damper_force)

	previous_spring_length = spring_length

	var force_point := collision_point + Vector3(0, car.wheel_radius, 0)
	var force := susp_dir * suspension_force
	car.apply_force(force, force_point - car.global_position)
