extends Node2D

var notes = {1:"""~A hotel with many wonders. Some might say infinitely many~
Guests will arrive soon. If you can’t hear that bell you’d better get your ears checked
Be on the lookout for large groups
I have no idea what sort of bedevilled attraction they have around town but theres been more people than ever, and honestly i have not had to clean up so many ashtrays since 
Anyhow i think upper management has at least some idea of what you are, so i think they will find out how to make life easier for you when sorting out large influxes
R.T.F.M 
Ryan Tebrook-Franz Messik (night shift)"""}

func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	$NightNotes.text = notes[1]
