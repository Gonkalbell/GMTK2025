extends Node3D

@export var move_speed: float = 8
@export var turn_speed: float = 0.5
@export var max_speed_bonus: float = 8;
## We use this angle (in turns) to find the path's maximum arc length relative to the radius of the planet.
@export var max_path_arc_angle: float = 0.98
@export var path_max_segment_length: float = 0.5

var speed_bonus: float = 0.0

signal completed_loop(points: PackedVector3Array)

func _ready() -> void:
	%Path3D.global_transform = Transform3D.IDENTITY
	var curve: Curve3D = %Path3D.curve
	curve.clear_points()
	# Add some initial points so we don't get errors
	var back_dir = %TailStart.global_position - %Player.global_position
	curve.add_point(%TailStart.global_position + 0.1 * back_dir)
	curve.add_point(%TailStart.global_position)

func _process(delta: float) -> void:
	var planet_origin: Vector3 = %Planet.global_position
	var planet_radius: float = %Planet.scale.x

	var up_dir_old: Vector3 = (%Player.global_position - planet_origin).normalized()
	var forward_dir_old: Vector3 = (-%Player.global_basis.z).slide(up_dir_old).normalized()
	var coaster_screen_pos: Vector2 = %Camera.unproject_position(%Player.global_position)
	var view_dir: Vector2 = %Camera.unproject_position(%Player.global_position + forward_dir_old) - coaster_screen_pos

	var yaw_input: float = 0

	var input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if not is_zero_approx(input.length_squared()):
		yaw_input = view_dir.angle_to(input)
	elif Input.is_action_pressed("click"):
		var mouse_pos: Vector2 = get_viewport().get_mouse_position()
		var dir_to_mouse: Vector2 = (mouse_pos - coaster_screen_pos).normalized()
		if dir_to_mouse.length_squared() > 0.001:
			yaw_input = view_dir.angle_to(dir_to_mouse)

	%Player.rotate_object_local(Vector3.UP, TAU * -yaw_input * delta * turn_speed)
	%Player.translate_object_local(Vector3.FORWARD * delta * (move_speed + speed_bonus))

	var up_dir: Vector3 = (%Player.global_position - planet_origin).normalized()
	var forward_dir: Vector3 = (-%Player.global_basis.z).slide(up_dir).normalized()
	var right_dir: Vector3 = up_dir.cross(forward_dir).normalized()

	%Player.global_position = planet_origin + up_dir * planet_radius
	%Player.global_basis = Basis(right_dir, up_dir, -forward_dir)

	%CameraOrigin.global_position = %CameraTarget.global_position
	var camera_up_dir = (%CameraOrigin.global_position - planet_origin).normalized()
	var camera_forward_dir = (-%CameraOrigin.global_basis.z).slide(camera_up_dir).normalized()
	var camera_right_dir = camera_up_dir.cross(camera_forward_dir).normalized()

	%CameraOrigin.global_basis = Basis(camera_right_dir, camera_up_dir, -camera_forward_dir)

	var curve: Curve3D = %Path3D.curve
	var tail_pos = %TailStart.global_position
	var segment_length = path_max_segment_length
	if curve.point_count >= 2:
		segment_length = curve.get_point_position(curve.point_count - 2).distance_to(tail_pos)
	if segment_length < path_max_segment_length:
		curve.set_point_position(curve.point_count - 1, tail_pos)
	else:
		_detect_loop()
		var tail_forward = -%TailStart.global_basis.z
		curve.add_point(tail_pos, -0.1 * path_max_segment_length * tail_forward, 0.1 * path_max_segment_length * tail_forward)
		while curve.get_baked_length() > max_path_arc_angle * TAU * planet_radius:
			curve.remove_point(0)


func _detect_loop():
	var curve: Curve3D = %Path3D.curve
	if curve.point_count <= 3:
		return
	var tail_pos: Vector3 = %TailStart.global_position
	var prev_pos: Vector3 = curve.get_point_position(curve.point_count - 2)

	# BUGFIX: limit the length of this segment or else the tail will sometimes detect false positives
	var limited_tail = (prev_pos - tail_pos).limit_length(1.95 * path_max_segment_length)
	prev_pos = tail_pos + limited_tail

	var points = Util.get_curve3d_point_positions(curve).slice(0, -3)
	var intersection = Util.segment_curve_intersect3d(prev_pos, tail_pos, points)
	if intersection != null:
		var intersection_index = intersection["index"]
		var loop_points = points.slice(intersection_index)
		curve.set_point_count(intersection_index)
		curve.add_point(intersection["point"])
		completed_loop.emit(loop_points)

func _on_game_manager_points_gained(points: float, _total_points: float) -> void:
	speed_bonus = lerp(speed_bonus, max_speed_bonus, clampf(points / 10, 0, 1))
	%SpeedBoostTimer.start(points)

func _on_game_manager_fucked_up() -> void:
	speed_bonus = 0

func _on_speed_boost_timer_timeout() -> void:
	speed_bonus = 0
