extends Button

@onready var constructor : Node2D = $"/root/GameScene/feedback/overlayContainer/graphs/formula constructor"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(_on_texture_button_pressed)

func _on_texture_button_pressed() -> void:
	# Load your target scene using its resource path
	
	constructor.set_meta("operand", get_meta("op"))
