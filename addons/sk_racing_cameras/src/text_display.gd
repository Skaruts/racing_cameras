extends CanvasLayer

@onready var camera_name: Label = %camera_name
@onready var position_name: Label = %position_name



var text_display_time := 2.0

var name_timer: float
var position_timer: float


func show_position_name(text:String) -> void:
	position_name.show()
	position_name.text = text
	position_timer = text_display_time
	set_process(true)


func show_camera_name(text:String) -> void:
	camera_name.show()
	camera_name.text = text
	name_timer = text_display_time
	set_process(true)


func _process(delta:float) -> void:
	name_timer -= delta
	position_timer -= delta
	if name_timer     <= 0: _hide_label(camera_name)
	if position_timer <= 0: _hide_label(position_name)


func _hide_label(label:Label) -> void:
	label.hide()
	if not camera_name.visible and not position_name.visible:
		set_process(false)




