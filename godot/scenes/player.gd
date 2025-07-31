extends Node3D

@export var speed: float = 0.25
@export var turns_per_sec:float = 0.5
@onready var path: Path3D = %Path3D

func _process(delta: float) -> void:
	var yaw = Input.get_axis("move_right", "move_left")
	rotate_y(TAU * yaw * delta * turns_per_sec)
	translate_object_local(Vector3.FORWARD * speed)
	var curve = path.curve
	if curve.point_count > 0:
		curve.set_point_position(curve.point_count - 1, global_position)

func _on_timer_timeout() -> void:
	var curve = path.curve
	path.curve.add_point(global_position)
	
