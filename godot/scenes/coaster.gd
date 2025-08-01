extends Node3D

@export var move_speed: float = 6
@export var turn_speed: float = 0.3
@export var origin: Vector3 = Vector3.ZERO
@export var radius = 10

func _process(delta: float) -> void:
	var yaw_input = Input.get_axis("move_left", "move_right")

	rotate_object_local(Vector3.UP, TAU * -yaw_input * delta * turn_speed)
	translate_object_local(Vector3.FORWARD * delta * move_speed)

	var up_dir = (global_position - origin).normalized()
	var forward_dir = (-global_basis.z).slide(up_dir).normalized()
	var right_dir = up_dir.cross(forward_dir).normalized()

	global_position = origin + up_dir * radius
	global_basis = Basis(right_dir, up_dir, -forward_dir)
	
	%CameraOrigin.global_position = %CameraTarget.global_position
	var camera_up_dir = (%CameraOrigin.global_position - origin).normalized()
	var camera_forward_dir = (-%CameraOrigin.global_basis.z).slide(camera_up_dir).normalized()
	var camera_right_dir = camera_up_dir.cross(camera_forward_dir).normalized()
	
	%CameraOrigin.global_basis = Basis(camera_right_dir, camera_up_dir, -camera_forward_dir)

	#var curve = path.curve
	#if curve.point_count > 0:
		#curve.set_point_position(curve.point_count - 1, tail_start.global_position)

func _on_timer_timeout() -> void:
	return
	#var curve = path.curve
	## Detect if our path made a loop
	#if curve.point_count > 1:
		#var points = curve.tessellate_even_length(5, 2)
		#var old_points = points.slice(0, -2)
		#var intersection = Util.segment_curve_intersect3d(points[-1], points[-2], old_points)
		#if intersection != null:
			#var intersection_index = intersection["index"]
			#var loop_points = points.slice(intersection_index)
			#curve.set_point_count(intersection_index)
			#curve.add_point(intersection["point"])
			#DebugDraw3D.draw_line_path(loop_points, Color.MAGENTA, 1)
	#path.curve.add_point(tail_start.global_position)
