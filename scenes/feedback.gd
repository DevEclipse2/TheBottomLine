extends Node2D

@onready var bottleitem : Sprite2D = $workspace/main/widgets/bottle
@onready var bottlebtn : Button = $workspace/main/widgets/bottle/Btn
@onready var keyitem : Sprite2D = $workspace/main/widgets/keys
@onready var keybtn : Button = $workspace/main/widgets/keys/Btn
@onready var listitem : Sprite2D = $workspace/main/widgets/transcoder
@onready var listbtn : Button = $workspace/main/widgets/transcoder/Btn
@onready var clockitem : Sprite2D = $workspace/main/widgets/clock
@onready var clockbtn : Button = $workspace/main/widgets/clock/Btn
@onready var noteitem : Sprite2D = $workspace/main/widgets/notebook
@onready var notebtn : Button = $workspace/main/widgets/notebook/Btn
@onready var ashitem : Sprite2D = $workspace/main/widgets/ashtray
@onready var ashbtn : Button = $workspace/main/widgets/ashtray/Btn

#for drawer, use beckon state visually but keep as 3 internally
@onready var drawer : Sprite2D = $workspace/main/drawer
@onready var drawerbtn : Button = $workspace/main/drawer/Btn

@onready var hand : Node2D = $handspace

@onready var objectNameDisp : Label = $"object name"
@onready var handFull : Label = $"hand full alert"

var pointfade = 0
var state = 0
# 0 : idle
# 1 : beckon
# 2 : grip 
# 3 : point

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	objectNameDisp.text = "point at any object!"
	handFull.text = ""
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#use match to hide and spawn shadow
	match get_meta("callid"):
		0: 
			ashitem.visibile = true
			bottleitem.visible = true
			keyitem.visible = true
			
		1: ashitem.visibile = false
	
	pointfade -= delta
	#if anything is hovered AND not gripping anything
	if bottlebtn.is_hovered():
		objectNameDisp.text = "tea to your boss, but secretly alochol"
	elif keybtn.is_hovered():
		objectNameDisp.text = "keys to the toilet. down left,\nwalk past room infinity"
	elif listbtn.is_hovered():
		objectNameDisp.text = "who's booked for today.\n upper mgmt."
	elif clockbtn.is_hovered():
		objectNameDisp.text = "clock. this one is vintage!"
	elif drawerbtn.is_hovered():
		objectNameDisp.text = "extra storage space.\n snug spot for contraband"
	elif ashbtn.is_hovered():
		objectNameDisp.text = "ashtray.\n it seems to be full"
	elif notebtn.is_hovered():
		objectNameDisp.text = "read the mucking fanual"
	else:
		objectNameDisp.text = "point at any object!"
	if get_meta("callid") != 0:
		state = 2
		hand.set_meta("state",2)
		hand.set_meta("object", get_meta("callid"))
	if bottlebtn.is_hovered() || keybtn.is_hovered() || listbtn.is_hovered() || clockbtn.is_hovered() || drawerbtn.is_hovered() || notebtn.is_hovered() || ashbtn.is_hovered():
		
		if state == 0:
			#stuff
			hand.set_meta("state",3)
			state = 3
		if state == 3:
			pointfade = 0.35
		if drawerbtn.is_hovered():
			hand.set_meta("state",1)
	elif pointfade <= 0:
		if state == 3 || state == 1:
			state = 0
			hand.set_meta("state",0)
	pass
	if pointfade <= 0.32:
		if state == 1:
			hand.set_meta("state",0)
	elif pointfade <= 0.11:
		if state == 1:
			hand.set_meta("state",1)
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		#search through all instances 
		#hide the sprite, change the state, put the item into their hand
		#spawn shadow to hint the dropoff location
		handFull.text = ""
		#beckon
		state = 1
		hand.set_meta("state",1)
		pointfade = 0.64
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("use"):
		
		get_viewport().set_input_as_handled()
	pass
