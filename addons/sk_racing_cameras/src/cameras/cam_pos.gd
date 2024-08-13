class_name CameraPosition


var name: String
var pos: Vector3
var rot: Vector3

func _init(n:String, p:Vector3, r:=Vector3.ZERO) -> void:
	name = n
	pos = p
	rot = r
