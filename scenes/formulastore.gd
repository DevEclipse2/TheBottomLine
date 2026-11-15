extends Node2D

@onready var constructor: Node2D = $"formula constructor"
@onready var graph: Sprite2D = $"GraphPaper/graph"

## Stores all finalized/submitted RPN formulas
var main_formulas: Array[PackedStringArray] = []


func _ready() -> void:
	# Initialize metadata on constructor so keys always exist
	if not constructor.has_meta("currentform"):
		constructor.set_meta("currentform", PackedStringArray())
	if not constructor.has_meta("complete"):
		constructor.set_meta("complete", false)


func _process(_delta: float) -> void:
	# 1. Read the formula currently under construction (PackedStringArray)
	var current_form: PackedStringArray = constructor.get_meta("currentform", PackedStringArray())
	
	# 2. Check if operand 11 set "complete" to true
	if constructor.get_meta("complete", true):
		print("completed!")
		# Reset the "complete" flag immediately after reading
		constructor.set_meta("complete", false)
		
		# Push into the main formula array if non-empty
		if not current_form.is_empty():
			main_formulas.append(current_form)
			
		# Clear constructor so the user can start typing the next formula
		if constructor.has_method("clear"):
			constructor.clear()
		current_form = PackedStringArray()
		
	# 3. Combine main_formulas + current_form and send to graph
	var all_to_render: Array[PackedStringArray] = main_formulas.duplicate()
	if not current_form.is_empty():
		all_to_render.append(current_form)
		
	graph.set_meta("functions", all_to_render)
