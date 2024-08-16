@tool
@icon("res://addons/sk_racing_cameras/icons/racing_cam.svg")
class_name RacingCamera
extends Camera3D # must actually be a camera, so that they can be previewed in the editor


## Do not use. This is the base class for all racing cameras, and does nothing on its own.
##
## The [RacingCamera] subclasses should work automatically by simply dropping
## them in the scene-tree, with little to no setup, and the [RacingCameraManager]
## singleton should manage them automatically. All camera except the
## [RacingTrackCamera], should be placed as children of the car node.
##[br][br]
##
## All cameras require a car node to be assigned to them, but cameras that
## reside in the car's own scene-tree should auto-detect the car node, as long
## as the car node is the scene root or the immediate parent of the camera node.
## If needed, the car node can be manually assigned through the inspector
## or through code (see [member follow_car] and [method set_car])
##
##[br][br]
## The car node can be of any [Node3D] type. Presumably all cars will be of
## a [PhysicsBody3D] type, but not all car scenes will have the physics body
## as the root node. In those cases, the root node should define a method
## [code]get_car_physicsbody[/code] that returns the respective physics body
## node.
##
##[br][br]
## For example:
## [codeblock]
## func get_car_physicsbody() -> PhysicsBody3D:
##     return $my_car_rigid_body_node
## [/codeblock]
##
## The documentation of each camera should mention any further requirements
## they may have.


const _shared := preload("res://addons/sk_racing_cameras/src/shared.gd")

const _CONF_WARNING_FOLLOW_CAR_INVALID = "The provided car node is not a valid car. It must either be a PhysicsBody3D or define the method: \n    get_car_physicsbody() -> PhysicsBody3D"
const _CONF_WARNING_CAR_NOT_FOUND = "Couldn't find a valid vehicle node in parent nodes.\nThe vehicle node must be either the scene root or the immediate parent of this node,\nand also either be a PhysicsBody3D subclass or define the method:\n    get_car_physicsbody() -> PhysicsBody3D"


@warning_ignore("unused_private_class_variable")
var _type:StringName = "RacingCamera"  # workaround for 'get_class' not accounting for custom classes
var _active: bool = true

@warning_ignore("unused_private_class_variable")
var _cam:Camera3D

var _car_base: Node3D
var _car_body: PhysicsBody3D  # The actual physics body that drives around, which may not be the '_car_base'



## The name of this camera, which will appear on screen when switching cameras.
var camera_name:String #= "Unnamed Camera"

## The car that this camera should follow.
## [br][br]
## This is not required if the car node is the immediate parent of this camera,
## or the root node of the same scene.
## [br][br]
## [color=white]Note:[/color] This is to be used in the editor's inspector only. For setting the car through
## code use [member set_car].
@export var follow_car:Node3D:
	set(v):
		follow_car = v
		if Engine.is_editor_hint():
			update_configuration_warnings()



func _enter_tree() -> void:
	if Engine.is_editor_hint(): return
	current = false

	if $"/root".has_node(_shared.SINGLETON_NAME):
		$"/root".get_node(_shared.SINGLETON_NAME).add_camera(self)

	_on_enter_tree()


func _exit_tree() -> void:
	if Engine.is_editor_hint(): return
	if $"/root".has_node(_shared.SINGLETON_NAME):
		$"/root".get_node(_shared.SINGLETON_NAME).remove_camera(self)



func _ready() -> void:
	if Engine.is_editor_hint(): return
	set_process_unhandled_input(false)
	_on_ready()
	set_active(false)



func _unhandled_input(event: InputEvent) -> void:
	if _car_base == null: return
	_on_unhandled_input(event)


func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	if _car_base == null: return
	_on_process(delta)


# this prevents mistakes, like forgetting to call 'super()' when overriding '_enter_tree'
# and also to keep the documentation simpler
func _on_enter_tree() -> void:                       assert(false, "to override")
func _on_ready() -> void:                            assert(false, "to override")
func _on_unhandled_input(_event: InputEvent) -> void: assert(false, "to override")
func _on_process(_delta: float) -> void:              assert(false, "to override")
func _on_set_active() -> void:                       assert(false, "to override")
func _on_set_car() -> void:                          pass


func _get_configuration_warnings() -> PackedStringArray:
	if follow_car and not _is_node_valid_car(follow_car):
		return [_CONF_WARNING_FOLLOW_CAR_INVALID]
	if not _find_valid_car_node():
		return [_CONF_WARNING_CAR_NOT_FOUND]
	return []


func _find_valid_car_node() -> Node3D:
	if owner and _is_node_valid_car(owner): return owner
	var parent:Node = get_parent()
	if not parent is RacingCamera and _is_node_valid_car(parent): return parent
	return null


func _is_node_valid_car(node:Node) -> bool:
	return node is PhysicsBody3D or node.has_method("get_car_physicsbody")


func _get_car_physicsbody(car:Node3D) -> PhysicsBody3D:
	if car is PhysicsBody3D:
		return car
	return car.get_car_physicsbody()


# cameras that are child of the car node can call this function during startup
func _init_car_from_owner() -> void:
	# TODO: should I really throw errors? Some cameras still work without
	# access to the car

	if follow_car == null:
		_car_base = _find_valid_car_node()
		if not _car_base:
			push_error("No valid car found in parent nodes. You may need to set the Follow Car field with a valid car node.")
			return
	else:
		if not _is_node_valid_car(follow_car):
			push_error("The provided car node '%s' is not a valid car. It must be any PhysicsBody3D, or a Node3D that defines the method 'get_car_physicsbody'" % follow_car.name)
			return
		_car_base = follow_car

	_car_body = _get_car_physicsbody(_car_base)


## Activate or deactivate this camera, according to [param enable].
func set_active(enable:bool) -> void:
	_active = enable
	_on_set_active()


## Check if this camera is currently active.
func is_active() -> bool:
	return _active



## Set the car that this camera should follow.
func set_car(car:Node3D) -> void:
	_car_base = car
	_car_body = _get_car_physicsbody(_car_base)
	_on_set_car()
