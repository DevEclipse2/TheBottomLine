extends Node
@onready var feedback : Node2D = $/root/GameScene/feedback

@onready var graph : Node2D = $graphs
@onready var note : Node2D = $notes
@onready var list : Node2D = $conversation


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	match feedback.get_meta("overlayid"):
		2:
			print("note on")
			note.visible = true
			list.visible = false
			graph.visible = false
		6: 
			print("list on")
			note.visible = false
			list.visible = true
			graph.visible = false
		7:
			print("graph on")
			note.visible = false
			list.visible = false
			graph.visible = true
	
	
	pass
