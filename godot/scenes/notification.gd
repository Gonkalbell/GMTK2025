class_name Notification extends Label3D

const scene: PackedScene = preload("res://scenes/notification.tscn")

static func spawn(in_tree: SceneTree, in_pos: Vector3, in_text: String, in_size: float, in_color: Color, in_duration: float):
	var notification = scene.instantiate()
	in_tree.root.add_child(notification)
	notification.initialize(in_pos, in_text, in_size, in_color, in_duration)

static func spawn_score(in_tree: SceneTree, in_pos: Vector3, in_score: int):
	Notification.spawn(in_tree, in_pos, "+%d" % in_score, 32, Color.GREEN, 3)

static func spawn_invalid(in_tree: SceneTree, in_pos: Vector3):
	Notification.spawn(in_tree, in_pos, "X", 32, Color.RED, 3)

func initialize(in_pos: Vector3, in_text: String, in_size: float, in_color: Color, in_duration: float):
	global_position = in_pos
	text = in_text
	font_size = in_size
	modulate = in_color
	%Timer.start(in_duration)

func _on_timer_timeout() -> void:
	queue_free()
