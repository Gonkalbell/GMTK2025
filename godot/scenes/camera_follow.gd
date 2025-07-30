extends Node3D

@export var follow_target: Node3D

func _process(delta: float) -> void:
	if follow_target != null:
		global_position = lerp(global_position, follow_target.global_position, 0.1)
