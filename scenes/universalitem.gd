extends Button
@onready var feedback : Node2D = $/root/GameScene/feedback

func _ready() -> void:
	# Connect the pressed signal directly since the script is on the TextureButton itself
	pressed.connect(_on_texture_button_pressed)

func _on_texture_button_pressed() -> void:
	# Load your target scene using its resource path
	if !feedback.get_meta("handfull"):
		print("pressed")
		print(get_meta("id"))
		feedback.set_meta("callid", get_meta("id"))
	
	
