extends TextureButton

func _ready() -> void:
	# Connect the pressed signal directly since the script is on the TextureButton itself
	pressed.connect(_on_texture_button_pressed)

func _on_texture_button_pressed() -> void:
	# Load your target scene using its resource path
	get_tree().change_scene_to_file("res://scenes/game_scene.tscn")
