extends Node3D

var score = 0

@export var obstacle_scene: PackedScene = preload("res://scenes/obstacle.tscn")
@export var pickup_scene: PackedScene= preload("res://scenes/pickup.tscn")

func _enter_tree() -> void:
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
