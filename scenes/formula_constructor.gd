extends Node

## Stores the human-readable infix formula (e.g., "sin ( 3 * x ) + 5")
var formula_string: String = ""

## Stores the tokenized Reverse Polish Notation array (e.g., ["3", "x", "*", "sin", "5", "+"])
var rpn_queue: Array[String] = []

## Internal token list and current number buffer for multi-digit keyboard numbers
var _infix_tokens: Array[String] = []
var _current_number: String = ""

## Operator metadata: Precedence, Associativity, and Arity (number of arguments)
const OPERATORS: Dictionary = {
	"+":   {"prec": 2, "assoc": "L", "args": 2},
	"-":   {"prec": 2, "assoc": "L", "args": 2},
	"*":   {"prec": 3, "assoc": "L", "args": 2},
	"/":   {"prec": 3, "assoc": "L", "args": 2},
	"^":   {"prec": 4, "assoc": "R", "args": 2},
	"sin": {"prec": 5, "assoc": "R", "args": 1}
}

func _ready() -> void:
	# Initialize the meta to 0 so it has a clean starting state
	set_meta("operand", 0)

@onready var disp : Label = $"formula disp"

func _process(_delta: float) -> void:
	# Check if a button has set the "operand" meta to a non-zero ID
	var op_id: int = get_meta("operand", 0)
	if op_id != 0:
		# Reset metadata immediately after reading
		set_meta("operand", 0)
		_handle_meta_operand(op_id)
	disp.text = formula_string
	var packed_rpn: PackedStringArray = PackedStringArray(rpn_queue)
	set_meta("currentformula",packed_rpn)

# Inside clear():
func clear() -> void:
	_current_number = ""
	_infix_tokens.clear()
	formula_string = ""
	rpn_queue.clear()
	set_meta("currentform", PackedStringArray())


## Handles the 1-12 integer ID from the "operand" metadata
func _handle_meta_operand(op_id: int) -> void:
	match op_id:
		1: # +
			_add_operator("+")
		2: # -
			_add_operator("-")
		3: # x (variable)
			_flush_number_buffer()
			_add_variable("x")
		4: # power (^)
			_add_operator("^")
		5: # (
			_add_left_paren()
		6: # )
			_add_right_paren()
		7: # /
			_add_operator("/")
		8: # *
			_add_operator("*")
		9: # delete last input
			_handle_backspace()
		10: # sine
			_add_function("sin")
		11:
			# Reserved for other functionality; ignored here
			_flush_number_buffer()
			_update_outputs()
			set_meta("complete", true)
			pass


## Keyboard listener for numbers (0-9, .) and x
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var char_str := _normalize_key_string(OS.get_keycode_string(event.keycode).to_lower(), event.unicode)
		
		# Numbers & Decimals
		if char_str.is_valid_int() or char_str == ".":
			_add_digit_or_decimal(char_str)
			
		# Keyboard shortcut for 'x'
		elif char_str == "x":
			_flush_number_buffer()
			_add_variable("x")
			
		# Keyboard Backspace
		elif event.keycode == KEY_BACKSPACE:
			_handle_backspace()
			
		# Enter / Return (Test output)
		elif event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
			_flush_number_buffer()
			_update_outputs()
			print("--- Finalized Function ---")
			print("Formula String: f(x) = ", formula_string)
			print("RPN String:     ", get_rpn_string())
			print("Test f(2) =     ", evaluate(2.0))


## Evaluates the generated RPN function for a given value of x
func evaluate(x_value: float) -> float:
	_flush_number_buffer()
	_update_outputs()
	
	var stack: Array[float] = []
	
	for token in rpn_queue:
		if token.is_valid_float():
			stack.append(token.to_float())
		elif token == "x":
			stack.append(x_value)
		elif token in OPERATORS:
			var arg_count: int = OPERATORS[token]["args"]
			if stack.size() < arg_count:
				push_error("Invalid RPN expression: Not enough operands for '%s'" % token)
				return NAN
				
			if arg_count == 1:
				var a: float = stack.pop_back()
				if token == "sin":
					stack.append(sin(a))
			elif arg_count == 2:
				var b: float = stack.pop_back()
				var a: float = stack.pop_back()
				match token:
					"+": stack.append(a + b)
					"-": stack.append(a - b)
					"*": stack.append(a * b)
					"/": stack.append(a / b if b != 0.0 else NAN)
					"^": stack.append(pow(a, b))
					
	return stack.back() if not stack.is_empty() else 0.0

func get_rpn_string() -> String:
	return " ".join(rpn_queue)


# --- Token Insertion Helpers ---

func _add_digit_or_decimal(ch: String) -> void:
	if ch == "." and "." in _current_number:
		return
	
	# Implicit multiplication after 'x' or ')' -> e.g. "x2" becomes "x * 2"
	if _current_number.is_empty() and not _infix_tokens.is_empty():
		var last : String = _infix_tokens.back()
		if last == "x" or last == ")":
			_infix_tokens.append("*")
			
	_current_number += ch
	_update_outputs()


func _add_variable(var_name: String) -> void:
	if not _infix_tokens.is_empty():
		var last : String = _infix_tokens.back()
		# Implicit multiplication: "3x" -> "3 * x", ")x" -> ") * x", "xx" -> "x * x"
		if last.is_valid_float() or last == "x" or last == ")":
			_infix_tokens.append("*")
			
	_infix_tokens.append(var_name)
	_update_outputs()


func _add_operator(op: String) -> void:
	_flush_number_buffer()
	_infix_tokens.append(op)
	_update_outputs()


func _add_function(fn_name: String) -> void:
	_flush_number_buffer()
	if not _infix_tokens.is_empty():
		var last : String = _infix_tokens.back()
		# Implicit multiplication: "3 sin(x)" -> "3 * sin(x)"
		if last.is_valid_float() or last == "x" or last == ")":
			_infix_tokens.append("*")
			
	_infix_tokens.append(fn_name)
	_update_outputs()


func _add_left_paren() -> void:
	_flush_number_buffer()
	if not _infix_tokens.is_empty():
		var last : String = _infix_tokens.back()
		# Implicit multiplication: "3(" -> "3 * (", "x(" -> "x * ("
		if last.is_valid_float() or last == "x" or last == ")":
			_infix_tokens.append("*")
			
	_infix_tokens.append("(")
	_update_outputs()


func _add_right_paren() -> void:
	_flush_number_buffer()
	_infix_tokens.append(")")
	_update_outputs()


func _flush_number_buffer() -> void:
	if not _current_number.is_empty():
		if _current_number == ".":
			_current_number = "0.0"
		_infix_tokens.append(_current_number)
		_current_number = ""


func _handle_backspace() -> void:
	if not _current_number.is_empty():
		_current_number = _current_number.left(_current_number.length() - 1)
	elif not _infix_tokens.is_empty():
		_infix_tokens.pop_back()
	_update_outputs()


# --- Shunting-Yard & Output Updating ---

func _update_outputs() -> void:
	var all_tokens: Array[String] = _infix_tokens.duplicate()
	if not _current_number.is_empty():
		all_tokens.append(_current_number)
		
	formula_string = " ".join(all_tokens)
	rpn_queue = _shunting_yard(all_tokens)
	
	# Convert Array[String] -> PackedStringArray and store in "currentform" meta
	set_meta("currentform", PackedStringArray(rpn_queue))
	print("Formula: %-25s | RPN: %s" % [formula_string, get_rpn_string()])


func _shunting_yard(tokens: Array[String]) -> Array[String]:
	var output: Array[String] = []
	var op_stack: Array[String] = []
	
	for token in tokens:
		if token.is_valid_float() or token == "x":
			output.append(token)
		elif token == "sin":
			op_stack.append(token)
		elif token in OPERATORS:
			while not op_stack.is_empty() and op_stack.back() in OPERATORS:
				var top_op: String = op_stack.back()
				var curr_prec: int = OPERATORS[token]["prec"]
				var top_prec: int = OPERATORS[top_op]["prec"]
				var curr_assoc: String = OPERATORS[token]["assoc"]
				
				if (curr_assoc == "L" and curr_prec <= top_prec) or (curr_assoc == "R" and curr_prec < top_prec):
					output.append(op_stack.pop_back())
				else:
					break
			op_stack.append(token)
		elif token == "(":
			op_stack.append(token)
		elif token == ")":
			while not op_stack.is_empty() and op_stack.back() != "(":
				output.append(op_stack.pop_back())
			if not op_stack.is_empty() and op_stack.back() == "(":
				op_stack.pop_back() # Discard "("
			# If a function like 'sin' was right before the '(', pop it to output now
			if not op_stack.is_empty() and op_stack.back() == "sin":
				output.append(op_stack.pop_back())
				
	while not op_stack.is_empty():
		var op: String = op_stack.pop_back()
		if op != "(" and op != ")":
			output.append(op)
			
	return output


func _normalize_key_string(key_str: String, unicode: int) -> String:
	if unicode > 32 and unicode < 127:
		return char(unicode).to_lower()
	return key_str.replace("kp ", "")
