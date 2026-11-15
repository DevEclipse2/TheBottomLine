extends Node2D

@onready var bottleitem : Node2D = $workspace/main/widgets/bottle
@onready var bottlebtn : Button = $workspace/main/widgets/bottle/bottle/Btn
@onready var keyitem : Node2D = $workspace/main/widgets/keys
@onready var keybtn : Button = $workspace/main/widgets/keys/keys/Btn
@onready var listitem : Node2D = $workspace/main/widgets/list
@onready var listbtn : Button = $workspace/main/widgets/list/transcoder/Btn
@onready var clockitem : Node2D = $workspace/main/widgets/clock
@onready var clockbtn : Button = $workspace/main/widgets/clock/clock/Btn
@onready var noteitem : Node2D = $workspace/main/widgets/note
@onready var notebtn : Button = $workspace/main/widgets/note/notebook/Btn
@onready var ashitem : Node2D = $workspace/main/widgets/tray
@onready var ashbtn : Button = $workspace/main/widgets/tray/ashtray/Btn
@onready var graphitem : Node2D = $workspace/main/widgets/graph
@onready var graphbtn : Button = $workspace/main/widgets/graph/graph/Btn
@onready var overlay : Node2D = $overlayContainer


#for drawer, use beckon state visually but keep as 3 internally
@onready var drawer : Sprite2D = $workspace/main/drawer
@onready var drawerbtn : Button = $workspace/main/drawer/Btn

@onready var hand : Node2D = $handspace

@onready var shadow : Sprite2D = $"workspace/main/the object shadow"

@onready var objectNameDisp : Label = $"object name"
@onready var handFull : Label = $"hand full alert"

@onready var DLL : Node2D = $workspace/main/deskLowLeft
@onready var DTR : Node2D = $workspace/main/deskTopRight
@onready var CLL : Node2D = $workspace/main/counterLowLeft
@onready var CTR : Node2D = $workspace/main/counterTopRight


var overlay_en = false


var helditem : Node2D

var pointfade = 0
var state = 0
# 0 : idle
# 1 : beckon
# 2 : grip 
# 3 : point

var helditemid = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	objectNameDisp.text = "point at any object!"
	handFull.text = ""
	pass # Replace with function body.


var projectedLocation = Vector2(0,0)
func projectPlacePoint():
	var mousepos: Vector2 = get_global_mouse_position()
	var projX = clampf(mousepos.x,CLL.global_position.x + 40,CTR.global_position.x - 40)
	var projY = 0.0
	if mousepos.y > CLL.global_position.y: #pos is down
		#lock to bottom
		projY = clampf(mousepos.y,DTR.global_position.y,DLL.global_position.y)
	else:
		projY = clampf(mousepos.y,CTR.global_position.y,CLL.global_position.y)
	projectedLocation = Vector2(projX,projY)
	shadow.global_position = projectedLocation
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#use match to hide and spawn shadow
	objectNameDisp.visible =  !overlay
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
	elif graphbtn.is_hovered():
		objectNameDisp.text = "assign rooms with the infinite graph (TM)"
	else:
		objectNameDisp.text = "point at any object!"
	if state == 2:
		projectPlacePoint()
	if get_meta("callid") != 0:
		#item is being held in hand!
		if state != 2:
			state = 2
			hand.set_meta("state",2)
			var id = get_meta("callid")
			hand.set_meta("object", id)
			set_meta("handfull",true)
			helditemid = id
			match id:
				0: 
					ashitem.visible = true
					bottleitem.visible = true
					keyitem.visible = true
					listitem.visible = true
					clockitem.visible = true
					noteitem.visible = true
				1: 
					helditem = ashitem
					ashitem.visible = false
				2: 
					helditem = noteitem
					noteitem.visible = false
				3: 
					helditem = keyitem
					keyitem.visible = false
				4: 
					helditem = bottleitem
					bottleitem.visible = false
				5: 
					helditem = clockitem
					clockitem.visible = false
				6: 
					helditem = listitem
					listitem.visible = false
				7:
					helditem = graphitem
					graphitem.visible = false
			#below is thing that disables the buttons from being pressed
			bottlebtn.disabled = true
			keybtn.disabled = true
			listbtn.disabled = true
			clockbtn.disabled = true
			notebtn.disabled = true
			ashbtn.disabled = true
			graphbtn.disabled = true
			set_meta("callid",0)
			shadow.global_position = Vector2(1000000,0)
		
	if bottlebtn.is_hovered() || keybtn.is_hovered() || listbtn.is_hovered() || clockbtn.is_hovered() || drawerbtn.is_hovered() || notebtn.is_hovered() || ashbtn.is_hovered():
		
		if state == 0:
			#stuff
			hand.set_meta("state",3)
			state = 3
		if state == 3:
			pointfade = 0.35
		if drawerbtn.is_hovered() && state == 3:
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
		# remember to disable the button components and re-enable them later
		if state == 2 || get_meta("handfull"):
			#throws the item down if previously holding any
			if(!overlay_en):
				print("itemdown")
				bottlebtn.disabled = false
				keybtn.disabled = false
				listbtn.disabled = false
				clockbtn.disabled = false
				notebtn.disabled = false
				ashbtn.disabled = false
				graphbtn.disabled = false
				#unhides the desktop sprites
				ashitem.visible = true
				bottleitem.visible = true
				keyitem.visible = true
				listitem.visible = true
				clockitem.visible = true
				noteitem.visible = true
				graphitem.visible = true
				state = 0
				hand.set_meta("state",0)
				set_meta("handfull",false)
				set_meta("callid",0)
				helditem.global_position = projectedLocation
				helditem = null
				shadow.global_position = Vector2(1000000,0)
				helditemid = 0
		else:
			handFull.text = ""
			#beckon
			state = 1
			hand.set_meta("state",1)
			pointfade = 0.64
	elif event.is_action_pressed("use"):
		#stuff
		print("rightclick")
		if !overlay_en:
			match helditemid:
				2:
					print("note")
					set_meta("overlayid",2)
				6:
					print("list")
					set_meta("overlayid",6)
				7:
					print("graph")
					set_meta("overlayid",7)
			if helditemid == 2 || helditemid == 6 || helditemid == 7:
				overlay_en = true
				overlay.visible = true
				print("use")
				set_meta("overlay",true)
		else:
			overlay_en = false
			overlay.visible = false
			print("off overlay")
			set_meta("overlay",false)
	get_viewport().set_input_as_handled()
	pass
