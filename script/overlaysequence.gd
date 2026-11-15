extends Node
@onready var feedback : Node2D = $/root/GameScene/feedback

@onready var graph : Node2D = $graphs
@onready var list : Node2D = $conversation


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	match feedback.get_meta("overlay"):
		6: 
			list.visible = true
			graph.visible = false
			
		7:
			list.visible = true
			graph.visible = true
	
	
	pass
