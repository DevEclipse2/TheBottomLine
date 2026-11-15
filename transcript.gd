extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	match get_meta("convoid"):
		1: $Transcript.text = """Guest 1: Yo! You got any space?
You: Yeah. How many people?
Guest 1: Just me and my crew. 12 rooms!
You: Hold on. I'll check my manual."""

		2: $Transcript.text = """Guest 1: This is my… f-f-friend… and this is another friend…
Guest 2: WHAT??? I THOUGHT WE WERE MORE THAN FRIENDS!
Guest 1: Hey… let's save this for later.
Guest 1: You're getting put upstairs.
Guest 2: WHAT??
Guest 1: And I'd like to be rooming next to this handsome fella on my left.
Guest 3: Heh.
You: I'll check my manual."""
		
		3: $Transcript.text = """Guest 1: This my team, man! 
Guest 3: Yeah we a crew of 32.
Guest 2: We be balling in pairs. 
Guest 4: Shut up! You're all so dumb! Let me explain it!
Guest 4: Person 1 and 3 need to share, person 2 and 4 need to share, and so on.
You: You're asking quite a lot of me, but ok. Let me check my manual."""

		4: $Transcript.text = """Guest 1: Can we get some rooms please?
		You: Kay. How many?
		Guest 1: Like, infinity. Duh.
		You: Sorry? Uh, nevermind. Guess I'll check my manual..."""
		
		5: $Transcript.text = """Guest 1: Hey! One room. Now.
		You: Okay, should be easy enough! I'll check my manual."""
