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
	# Detect if our path made a loop
	if curve.point_count > 1:
		var points = curve.tessellate_even_length(5, 2)
		var old_points = points.slice(0, -2)
		var intersection = Util.segment_curve_intersect3d(points[-1], points[-2], old_points)
		if intersection != null:
			var intersection_index = intersection["index"]
			var loop_points = points.slice(intersection_index)
			curve.set_point_count(intersection_index)
			curve.add_point(intersection["point"])
			DebugDraw3D.draw_line_path(loop_points, Color.MAGENTA, 1)
	path.curve.add_point(global_position)
