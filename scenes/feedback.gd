extends Node2D

@onready var bottleitem : Sprite2D = $workspace/main/widgets/bottle
@onready var bottlebtn : Button = $workspace/main/widgets/bottle/Btn
@onready var keyitem : Sprite2D = $workspace/main/widgets/keys
@onready var keybtn : Button = $workspace/main/widgets/keys/Btn
@onready var listitem : Sprite2D = $workspace/main/widgets/transcoder
@onready var listbtn : Button = $workspace/main/widgets/transcoder/Btn

@onready var hand : Node2D = $handspace

var state = 0
var pointfade = 0
# 0 : idle
# 1 : beckon
# 2 : grip 
# 3 : point

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pointfade -= delta
	#if anything is hovered AND not gripping anything
	if bottlebtn.is_hovered() || keybtn.is_hovered() || listbtn.is_hovered():
		
		if state == 0:
			#stuff
			hand.set_meta("State",3)
			state = 3
		if state == 3:
			pointfade = 0.5
	elif pointfade <= 0:
		state = 0
		hand.set_meta("State",0)
	pass
