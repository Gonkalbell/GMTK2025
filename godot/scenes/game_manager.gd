extends Node3D

var score = 0

@export var obstacle_scene: PackedScene = preload("res://scenes/obstacle.tscn")
@export var pickup_scene: PackedScene= preload("res://scenes/pickup.tscn")

var max_time_limit: float

func _ready() -> void:
	max_time_limit = %TimeLimit.wait_time
	for i in 5:
		spawn_scene.call_deferred(pickup_scene)
	for i in 5:
		spawn_scene.call_deferred(obstacle_scene)

func _process(delta: float) -> void:
	%HUD.text = "Time: %ds\nScore: %s" % [%TimeLimit.time_left, score]

func _on_spawn_timer_timeout() -> void:
	spawn_scene(obstacle_scene)

func spawn_scene(packed_scene: PackedScene):
	var origin: Vector3 = %Planet.global_position
	var radius: float = %Planet.scale.x
	var random_point: Vector3 = origin + radius * Util.random_on_unit_sphere()

	var instance: Node3D = packed_scene.instantiate()
	get_tree().root.add_child(instance)
	instance.global_position = random_point


func _on_player_completed_loop(points: PackedVector3Array) -> void:
	var origin: Vector3 = %Planet.global_position

	var average_point = Vector3.ZERO
	for point in points:
		average_point += point
	average_point /= points.size()

	var plane_normal = (average_point - origin).normalized()
	var aribitrary_axis = Vector3.RIGHT if !plane_normal.is_equal_approx(Vector3.RIGHT) else Vector3.UP
	var plane_tangent = plane_normal.cross(aribitrary_axis).normalized()
	var plane_bitangent = plane_normal.cross(plane_tangent).normalized()

	var flattened_points = PackedVector2Array()
	flattened_points.resize(points.size())
	for i in points.size():
		var flattened_point = Vector2(points[i].dot(plane_bitangent), points[i].dot(plane_tangent))
		flattened_points[i] = flattened_point

	var all_obstacles = get_tree().get_nodes_in_group("Obstacle") as Array[Node3D]
	var looped_any_obstacles = false
	for obstacle in all_obstacles:
		var pos = obstacle.global_position
		var is_above_plane = pos.dot(plane_normal) >= 0
		var flattened_pos = Vector2(pos.dot(plane_bitangent), pos.dot(plane_tangent))
		if is_above_plane and Geometry2D.is_point_in_polygon(flattened_pos, flattened_points):
			DebugDraw3D.draw_text(1.1 * pos, "X", 128, Color.RED, 3)
			looped_any_obstacles = true
	
	var all_pickups = get_tree().get_nodes_in_group("Pickup") as Array[Node3D]
	var new_points = 0
	for pickup in all_pickups:
		var pos = pickup.global_position
		var is_above_plane = pos.dot(plane_normal) >= 0
		var flattened_pos = Vector2(pos.dot(plane_bitangent), pos.dot(plane_tangent))
		if is_above_plane and Geometry2D.is_point_in_polygon(flattened_pos, flattened_points):
			if looped_any_obstacles:
				DebugDraw3D.draw_text(1.1 * pos, "X", 128, Color.RED, 3)
			else:
				new_points += 1
				score += new_points
				DebugDraw3D.draw_text(1.1 * pos, "+%d" % new_points, 128, Color.GREEN, 3)
