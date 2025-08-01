extends Node3D

var score = 0

@export var obstacle_scene: PackedScene = preload("res://scenes/obstacle.tscn")
@export var pickup_scene: PackedScene= preload("res://scenes/pickup.tscn")

var max_time_limit: float

var obstacle_map: Dictionary[Vector3, Node3D] = {}
var pickup_map: Dictionary[Vector3, Node3D] = {}

func _ready() -> void:
	max_time_limit = %TimeLimit.wait_time
	for i in 5:
		spawn_pickup.call_deferred()
	for i in 5:
		spawn_obstacle.call_deferred()

func _process(delta: float) -> void:
	%HUD.text = "Time: %d\nScore: %s" % [%TimeLimit.time_left, score]

func _on_spawn_timer_timeout() -> void:
	spawn_obstacle()

func random_point_on_planet() -> Vector3:
	var origin: Vector3 = %Planet.global_position
	var radius: float = %Planet.scale.x
	return origin + radius * Util.random_point_on_fibonacci_sphere()

func spawn_obstacle():
	for i in 100:
		var random_pos = random_point_on_planet()
		# This is a hacky way to make sure we don't accidentally spawn an obstacle on another obstace/pickup
		if obstacle_map.get(random_pos) != null or pickup_map.get(random_pos) != null:
			continue
		var instance: Node3D = obstacle_scene.instantiate()
		get_tree().root.add_child(instance)
		instance.global_position = random_pos
		instance.global_basis = get_arbitrary_basis(random_pos)
		obstacle_map[random_pos] = instance
		break

func spawn_pickup():
	var instance: Node3D = pickup_scene.instantiate()
	get_tree().root.add_child(instance)
	place_pickup(instance)

# TODO: handle placing pickups on top of each other
func place_pickup(pickup: Node3D):
	var random_pos = random_point_on_planet()
	var obstacle: Node3D = obstacle_map.get(random_pos);
	if obstacle != null:
		obstacle.queue_free()
		obstacle_map.erase(random_pos)
	pickup.global_position = random_pos
	pickup.global_basis = get_arbitrary_basis(random_pos)
	pickup_map[random_pos] = pickup

func get_arbitrary_basis(pos: Vector3) -> Basis:
	var origin: Vector3 = %Planet.global_position
	var up_dir = (pos - origin).normalized()
	var arbitrary_axis = Vector3.RIGHT if !up_dir.is_equal_approx(Vector3.RIGHT) else Vector3.UP
	var tangent = up_dir.cross(arbitrary_axis).normalized()
	var bitangent = tangent.cross(up_dir).normalized()
	return Basis(tangent, up_dir, bitangent)

func _on_player_completed_loop(points: PackedVector3Array) -> void:
	var origin: Vector3 = %Planet.global_position

	var average_point = Vector3.ZERO
	for point in points:
		average_point += point
	average_point /= points.size()

	var plane_normal = (average_point - origin).normalized()
	var arbitrary_axis = Vector3.RIGHT if !plane_normal.is_equal_approx(Vector3.RIGHT) else Vector3.UP
	var plane_tangent = plane_normal.cross(arbitrary_axis).normalized()
	var plane_bitangent = plane_normal.cross(plane_tangent).normalized()

	var flattened_points = PackedVector2Array()
	flattened_points.resize(points.size())
	for i in points.size():
		var flattened_point = Vector2(points[i].dot(plane_bitangent), points[i].dot(plane_tangent))
		flattened_points[i] = flattened_point

	var all_obstacles = obstacle_map.values()
	var looped_any_obstacles = false
	for obstacle in all_obstacles:
		var pos = obstacle.global_position
		var is_above_plane = pos.dot(plane_normal) >= 0
		var flattened_pos = Vector2(pos.dot(plane_bitangent), pos.dot(plane_tangent))
		if is_above_plane and Geometry2D.is_point_in_polygon(flattened_pos, flattened_points):
			Notification.spawn_invalid(get_tree(), 1.1 * pos)
			looped_any_obstacles = true

	var all_pickups = pickup_map.values()
	var new_points = 0
	for pickup in all_pickups:
		var pos = pickup.global_position
		var is_above_plane = pos.dot(plane_normal) >= 0
		var flattened_pos = Vector2(pos.dot(plane_bitangent), pos.dot(plane_tangent))
		if is_above_plane and Geometry2D.is_point_in_polygon(flattened_pos, flattened_points):
			if looped_any_obstacles:
				Notification.spawn_invalid(get_tree(), 1.1 * pos)
			else:
				new_points += 1
				score += new_points
				var new_time_limit = min(%TimeLimit.time_left + new_points, max_time_limit)
				%TimeLimit.start(new_time_limit)
				Notification.spawn_score(get_tree(), 1.1 * pos, new_points)
				place_pickup(pickup)


func _on_time_limit_timeout() -> void:
	%FadeOverlay.fade_out()
	await %FadeOverlay.on_complete_fade_out
	get_tree().change_scene_to_file("res://scenes/main_menu_scene.tscn")
