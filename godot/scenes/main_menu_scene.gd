extends Node3D

@export var game_scene:PackedScene
@export var settings_scene:PackedScene

@onready var overlay := %FadeOverlay
@onready var new_game_button := %NewGameButton
@onready var settings_button := %SettingsButton
@onready var exit_button := %ExitButton

var next_scene = game_scene

func _ready() -> void:
	new_game_button.disabled = game_scene == null
	settings_button.disabled = settings_scene == null
	overlay.visible = true
	
	# connect signals
	new_game_button.pressed.connect(_on_play_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)
	overlay.on_complete_fade_out.connect(_on_fade_overlay_on_complete_fade_out)
	
	new_game_button.grab_focus()

func _on_settings_button_pressed() -> void:
	next_scene = settings_scene
	overlay.fade_out()
	
func _on_play_button_pressed() -> void:
	next_scene = game_scene
	overlay.fade_out()

func _on_exit_button_pressed() -> void:
	get_tree().quit()

func _on_fade_overlay_on_complete_fade_out() -> void:
	get_tree().change_scene_to_packed(next_scene)
