extends Node3D

@export var move_speed: float = 6
@export var turn_speed: float = 0.5
## We use this angle (in turns) to find the path's maximum arc length relative to the radius of the planet.
@export var max_path_arc_angle: float = 0.95
@export var planet: Node3D

signal completed_loop(points: PackedVector3Array)

func _ready() -> void:
	%Path3D.global_transform = Transform3D.IDENTITY
	var curve: Curve3D = %Path3D.curve
	curve.clear_points()
	# Add some initial points so we don't get errors
	var back_dir = %TailStart.global_position - %Coaster.global_position
	curve.add_point(%TailStart.global_position + 0.1 * back_dir)
	curve.add_point(%TailStart.global_position)

func _process(delta: float) -> void:
	var origin: Vector3 = planet.global_position
	var radius: float = planet.scale.x
	var yaw_input: float = Input.get_axis("move_left", "move_right")

	%Coaster.rotate_object_local(Vector3.UP, TAU * -yaw_input * delta * turn_speed)
	%Coaster.translate_object_local(Vector3.FORWARD * delta * move_speed)

	var up_dir: Vector3 = (%Coaster.global_position - origin).normalized()
	var forward_dir: Vector3 = (-%Coaster.global_basis.z).slide(up_dir).normalized()
	var right_dir: Vector3 = up_dir.cross(forward_dir).normalized()
	
	%Coaster.global_position = origin + up_dir * radius
	%Coaster.global_basis = Basis(right_dir, up_dir, -forward_dir)

	%CameraOrigin.global_position = %CameraTarget.global_position
	var camera_up_dir = (%CameraOrigin.global_position - origin).normalized()
	var camera_forward_dir = (-%CameraOrigin.global_basis.z).slide(camera_up_dir).normalized()
	var camera_right_dir = camera_up_dir.cross(camera_forward_dir).normalized()

	%CameraOrigin.global_basis = Basis(camera_right_dir, camera_up_dir, -camera_forward_dir)

	var curve: Curve3D = %Path3D.curve
	if curve.point_count > 2:
		curve.set_point_position(curve.point_count - 1, %TailStart.global_position)

func _on_new_path_point_timer_timeout() -> void:
	var radius: float = planet.scale.x
	var curve: Curve3D = %Path3D.curve
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
			completed_loop.emit(loop_points)
	curve.add_point(%TailStart.global_position)
	while curve.get_baked_length() > max_path_arc_angle * TAU * radius:
		curve.remove_point(0)
