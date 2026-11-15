extends Node


var stage2 = false

var pool: Array[int] = [1,2,3]
var order: Array[int]
var timer = 0.0
var nextTrigTime = 12.0
var readidx = 0

@onready var conversation : Node2D =  $feedback/overlayContainer/conversation/Node2D
@onready var guests : Node2D =  $feedback/workspace/main/Guests
var rng = RandomNumberGenerator.new()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	for i in range(3):
		#012
		var next_id = rng.randi_range(0,pool.size()-1)
		order.append(pool[next_id])
		pool.erase(pool[next_id])
	for i in range(3):
		print(order[i])
	pass # Replace with function body.

func guestspawn(id: int):
	conversation.set_meta("convoid",id)
	guests.toggle_sprite(id, true)
	pass
func guestexit():
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	timer += delta
	if(timer > nextTrigTime):
		timer = 0
		nextTrigTime =  rng.randf_range(12.6, 12 - 2 * readidx)
		guestspawn(order[readidx])
		readidx += 1
		
	pass
