extends Node
@onready var animation_player: AnimationPlayer = $AnimationPlayer
var state = 1
var cooldown = 0.0
func _process(delta: float) -> void:
	# get_axis("Look_down", "Look_up") returns:
	#  1.0 if Look_up is pressed
	# -1.0 if Look_down is pressed
	#  0.0 if neither (or both) are pressed
	cooldown -= delta
	var look_input: float = Input.get_axis("Look_down", "Look_up")
	
	if cooldown <= 0.0:
		if look_input > 0:
			cooldown = 0.25
			match state:
				1:
					print("top already!")
				0:
					animation_player.play("main-midhigh")
					state += 1
				-1:
					animation_player.play("main-lowmid")
					state += 1
				_: print ("tel aviv confused")
			print("up")
		elif look_input < 0:
			cooldown = 0.25
			match state:
				1:
					animation_player.play("main-highmid")
					state -= 1
				0:
					animation_player.play("main-midlow")
					state -= 1
				-1:
					print("bottom already!")
				_: print ("tel aviv confused")
			print("down")
			#nothing
