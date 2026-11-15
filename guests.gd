extends Node2D

var sprites = {1: "Sprites1", 2: "Sprites2", 3: "Sprites3",
4: "Sprites4", 5: "Sprites5", 6: "Sprites6", 7: "Sprites7"}

func toggle_sprite(number : int, on_screen : bool):
	var target = get_node(sprites[number])
	if on_screen:
		target.visible = true
	else:
		target.visible = false

func _process(_delta):
	
