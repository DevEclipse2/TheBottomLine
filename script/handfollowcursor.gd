extends Node2D

@onready var pointhand : Sprite2D = $hand/point
@onready var griphand : Sprite2D = $hand/grip
@onready var beckonhand : Sprite2D = $hand/beckon
@onready var idlehand : Sprite2D = $hand/idle

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

var state = 0
# 0 : idle
# 1 : beckon
# 2 : grip 
# 3 : point
var oldstate = 0;
func HandSetVisible():
	match state:
		0:
			pointhand.visible = false
			idlehand.visible = true
			griphand.visible = false 
			beckonhand.visible = false
		1:
			pointhand.visible = false
			idlehand.visible = false
			griphand.visible = false
			beckonhand.visible = true
		2:
			pointhand.visible = false 
			idlehand.visible = false
			griphand.visible = true
			beckonhand.visible = false
		3:
			pointhand.visible = true 
			idlehand.visible = false
			griphand.visible = false
			beckonhand.visible = false
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if state != oldstate:
		HandSetVisible()
	
	#extract world position
	var world_mouse_pos: Vector2 = get_global_mouse_position()
	
	
	#compare against angle difference and align
	
	# Example: Print the world coordinates
	# print(world_mouse_pos)
	
	# Example: Move towards or check distance to the world mouse position
	# if global_position.distance_to(world_mouse_pos) > 10.0:
	#     look_at(world_mouse_pos)
	
	pass
