extends Node3D

@export var speed: float = 0.25
@export var turns_per_sec:float = 0.5

func _process(delta: float) -> void:
	var yaw = Input.get_axis("move_right", "move_left")
	rotate_y(TAU * yaw * delta * turns_per_sec)
	translate_object_local(Vector3.FORWARD * speed)
