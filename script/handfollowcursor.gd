extends Node2D

@onready var pointhand : Sprite2D = $hand/point
@onready var griphand : Sprite2D = $hand/grip
@onready var beckonhand : Sprite2D = $hand/beckon
@onready var idlehand : Sprite2D = $hand/idle

@onready var finger_root: Node2D = $hand/point/fingerroot
@onready var finger_tip: Node2D = $hand/point/fingertip
@onready var hand : Node2D = $hand

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	originalpos = global_position
	handyoriginal = hand.position.y
	pass # Replace with function body.
var originalpos = Vector2(0,0)
var state = 0
var handyoriginal = 0
# 0 : idle
# 1 : beckon
# 2 : grip 
# 3 : point
var oldstate = 0
var maxoffset = 50

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
	state = get_meta("State")
	if state != oldstate:
		HandSetVisible()
		oldstate = state
	
	#extract world position
	var target_pos: Vector2 = get_global_mouse_position()
	var target_angle: float = (target_pos - global_position).angle()
	var finger_angle: float = (finger_tip.global_position - finger_root.global_position).angle()
	global_rotation += angle_difference(finger_angle, target_angle)/2
	hand.global_rotation += angle_difference(finger_angle, target_angle)/2
	var newpos: Vector2 = Vector2(originalpos.x - (target_pos.x)/1152 * maxoffset, originalpos.y - (target_pos.y - 432 )/864 * maxoffset * 0.1)
	global_position = newpos
	hand.position = Vector2(hand.position.x, handyoriginal + (target_pos.y - 432 )/864 * maxoffset)
	pass
