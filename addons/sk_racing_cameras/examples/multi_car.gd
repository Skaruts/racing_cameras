extends Node3D

# Quick and dirty car managing code

# In this case, the 'set_car' function tells the camera manager which car
# is being used


var cars:Array[Node3D]
var curr_idx := 0


func _ready() -> void:
	for car in $cars.get_children():
		cars.append(car)
		car.set_active(false) # make sure all cars are inactive to start with

	set_car(0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_focus_next"):
		set_car( wrapi(curr_idx+1, 0, cars.size()) )


func set_car(idx:int) -> void:
	var old_car := cars[curr_idx]
	curr_idx = idx
	var curr_car := cars[idx]

	curr_car.set_active(true)
	if old_car != curr_car:
		old_car.set_active(false)

	# just so it won't throw errors if the plugin is off
	if $"/root".has_node("cameraman"):
		$"/root".get_node("cameraman").set_car(curr_car)
