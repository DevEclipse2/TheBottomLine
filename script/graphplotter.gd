class_name GraphPlotter
extends Sprite2D

const SCREEN_SIZE: int = 128

# Bottom-left corner of the 128x128 window in world coordinates.
# Clamped to >= 0 so we strictly view the +X, +Y quadrant.
var view_origin: Vector2i = Vector2i(0, 0)

var is_dragging: bool = false
var drag_start_mouse: Vector2 = Vector2.ZERO
var drag_start_origin: Vector2i = Vector2i.ZERO

var graph_image: Image
var graph_texture: ImageTexture

# Each entry: { "expr": String, "rpn": Array, "color": Color }
var functions: Array[Dictionary] = []

func _ready() -> void:
	centered = false # Top-left origin makes mouse math and layout cleaner
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	graph_image = Image.create(SCREEN_SIZE, SCREEN_SIZE, false, Image.FORMAT_RGBA8)
	graph_texture = ImageTexture.create_from_image(graph_image)
	texture = graph_texture
	
	# Default functions so you see results immediately
	set_live_function("sqrt(x+2)*4", Color.CYAN)
	add_saved_function("x/3 + 5", Color.GREEN)
	update_graph()

# Updates Function #0 in real-time as you build it in the Formula Designer
func set_live_function(expr: String, color: Color = Color.CYAN) -> void:
	var rpn: Array = parse_to_rpn(expr)
	var fn_data := { "expr": expr, "rpn": rpn, "color": color }
	if functions.is_empty():
		functions.append(fn_data)
	else:
		functions[0] = fn_data
	update_graph()

# Adds additional functions to compare & find intersections against
func add_saved_function(expr: String, color: Color) -> void:
	var rpn: Array = parse_to_rpn(expr)
	functions.append({ "expr": expr, "rpn": rpn, "color": color })
	update_graph()

func clear_extra_functions() -> void:
	if functions.size() > 1:
		functions.resize(1)
	update_graph()

# Centers the 128x128 view on a target (x, y) while staying in the +x, +y quadrant
func jump_to_world_pos(target: Vector2i) -> void:
	view_origin.x = max(0, target.x - (SCREEN_SIZE / 2))
	view_origin.y = max(0, target.y - (SCREEN_SIZE / 2))
	update_graph()

# ==========================================
# 1. RENDERING (Strictly +X, +Y & 1px Red Intersections)
# ==========================================
func update_graph() -> void:
	graph_image.fill(Color(0.08, 0.08, 0.1))
	
	# Subtle grid lines every 16 units
	var grid_col := Color(0.14, 0.14, 0.18)
	for px in range(SCREEN_SIZE):
		var wx: int = view_origin.x + px
		for py in range(SCREEN_SIZE):
			var wy: int = view_origin.y + (SCREEN_SIZE - 1 - py)
			if wx % 16 == 0 or wy % 16 == 0:
				graph_image.set_pixel(px, py, grid_col)
				
	# Highlight X=0 and Y=0 borders when at the origin edge
	var axis_col := Color(0.35, 0.35, 0.45)
	if view_origin.x == 0:
		for py in range(SCREEN_SIZE): graph_image.set_pixel(0, py, axis_col)
	if view_origin.y == 0:
		for px in range(SCREEN_SIZE): graph_image.set_pixel(px, SCREEN_SIZE - 1, axis_col)
		
	# Precompute the 128 integer X coordinates
	var x_coords := PackedFloat64Array()
	x_coords.resize(SCREEN_SIZE)
	for px in range(SCREEN_SIZE):
		x_coords[px] = float(view_origin.x + px)
		
	var hit_grid := PackedInt32Array()
	hit_grid.resize(SCREEN_SIZE * SCREEN_SIZE)
	hit_grid.fill(0)
	
	for fn_idx in range(functions.size()):
		var fn: Dictionary = functions[fn_idx]
		var y_values: PackedFloat64Array = evaluate_rpn_vectorized(fn["rpn"], x_coords)
		var col: Color = fn["color"]
		
		for px in range(SCREEN_SIZE):
			var y_val: float = y_values[px]
			if is_nan(y_val) or is_inf(y_val):
				continue
			
			var wy: int = int(round(y_val))
			if wy < 0:
				continue # Strictly +Y quadrant
				
			# Convert world Y to screen pixel Y (0 is top, 127 is bottom)
			var py: int = (SCREEN_SIZE - 1) - (wy - view_origin.y)
			if py >= 0 and py < SCREEN_SIZE:
				var idx: int = py * SCREEN_SIZE + px
				hit_grid[idx] += 1
				
				# Exact 1-pixel wide bright red collision
				if hit_grid[idx] > 1:
					graph_image.set_pixel(px, py, Color(1.0, 0.0, 0.0))
				else:
					graph_image.set_pixel(px, py, col)
					
	graph_texture.update(graph_image)

# ==========================================
# 2. RANGE INTERSECTION SCANNER
# ==========================================
# Tests integer X values in [x_min, x_max] in 128-wide vectorized batches
func find_intersections_in_range(x_min: int, x_max: int) -> Array[Vector2i]:
	var results: Array[Vector2i] = []
	if functions.size() < 2:
		return results
		
	var start_x: int = max(0, x_min)
	var end_x: int = max(start_x, x_max)
	var total_len: int = end_x - start_x + 1
	
	var x_coords := PackedFloat64Array()
	x_coords.resize(total_len)
	for i in range(total_len):
		x_coords[i] = float(start_x + i)
		
	# Evaluate each function across the entire test range
	var all_y: Array[PackedFloat64Array] = []
	for fn in functions:
		all_y.append(evaluate_rpn_vectorized(fn["rpn"], x_coords))
		
	# Check for integer pixel collisions or sign-change crossings in +X, +Y
	for i in range(total_len):
		var wx: int = start_x + i
		var seen_y: Dictionary = {}
		for f_idx in range(all_y.size()):
			var y_f: float = all_y[f_idx][i]
			if is_nan(y_f) or is_inf(y_f):
				continue
			var wy: int = int(round(y_f))
			if wy < 0:
				continue
			if seen_y.has(wy):
				var pt := Vector2i(wx, wy)
				if not results.has(pt):
					results.append(pt)
			else:
				seen_y[wy] = true
	return results

# ==========================================
# 3. VECTORIZED RPN EVALUATOR & PARSER
# ==========================================
func evaluate_rpn_vectorized(rpn: Array, x_values: PackedFloat64Array) -> PackedFloat64Array:
	var n: int = x_values.size()
	if rpn.is_empty() or n == 0:
		return PackedFloat64Array()
		
	var stack: Array[PackedFloat64Array] = []
	
	for token in rpn:
		if typeof(token) == TYPE_STRING and token == "x":
			stack.append(x_values.duplicate())
		elif typeof(token) == TYPE_FLOAT or typeof(token) == TYPE_INT:
			var arr := PackedFloat64Array()
			arr.resize(n)
			arr.fill(float(token))
			stack.append(arr)
		elif token in ["sqrt", "sin", "cos", "tan"]:
			if stack.is_empty(): return PackedFloat64Array()
			var a: PackedFloat64Array = stack.pop_back()
			var res := PackedFloat64Array()
			res.resize(n)
			match token:
				"sqrt":
					for i in range(n): res[i] = sqrt(a[i]) if a[i] >= 0.0 else NAN
				"sin":
					for i in range(n): res[i] = sin(a[i])
				"cos":
					for i in range(n): res[i] = cos(a[i])
				"tan":
					for i in range(n): res[i] = tan(a[i])
			stack.append(res)
		elif token in ["+", "-", "*", "/", "^"]:
			if stack.size() < 2: return PackedFloat64Array()
			var b: PackedFloat64Array = stack.pop_back()
			var a: PackedFloat64Array = stack.pop_back()
			var res := PackedFloat64Array()
			res.resize(n)
			match token:
				"+":
					for i in range(n): res[i] = a[i] + b[i]
				"-":
					for i in range(n): res[i] = a[i] - b[i]
				"*":
					for i in range(n): res[i] = a[i] * b[i]
				"/":
					for i in range(n): res[i] = a[i] / b[i] if b[i] != 0.0 else NAN
				"^":
					for i in range(n): res[i] = pow(a[i], b[i])
			stack.append(res)
			
	return stack.back() if stack.size() == 1 else PackedFloat64Array()

func tokenize(expr: String) -> Array[String]:
	var tokens: Array[String] = []
	var i: int = 0
	var s: String = expr.replace(" ", "")
	while i < s.length():
		var c: String = s[i]
		if c.is_valid_int() or c == ".":
			var num_str: String = ""
			while i < s.length() and (s[i].is_valid_int() or s[i] == "."):
				num_str += s[i]
				i += 1
			tokens.append(num_str)
			if i < s.length() and (s[i] == "x" or s[i] == "(" or s[i].is_valid_identifier()):
				tokens.append("*")
			continue
		if c == "x":
			tokens.append("x")
			i += 1
			if i < s.length() and (s[i] == "(" or s[i].is_valid_identifier()):
				tokens.append("*")
			continue
		if s.substr(i).begins_with("sqrt"):
			tokens.append("sqrt")
			i += 4
			continue
		var matched_fn := false
		for fn_name in ["sin", "cos", "tan"]:
			if s.substr(i).begins_with(fn_name):
				tokens.append(fn_name)
				i += 3
				matched_fn = true
				break
		if matched_fn: continue
		if c in ["+", "-", "*", "/", "^", "(", ")"]:
			if c == "-" and (tokens.is_empty() or tokens.back() in ["(", "+", "-", "*", "/", "^"]):
				tokens.append("0")
			tokens.append(c)
			i += 1
			continue
		i += 1
	return tokens

func get_precedence(op: String) -> int:
	match op:
		"+", "-": return 1
		"*", "/": return 2
		"^": return 3
		"sqrt", "sin", "cos", "tan": return 4
	return 0

func parse_to_rpn(expr: String) -> Array:
	var tokens: Array[String] = tokenize(expr)
	var output: Array = []
	var op_stack: Array[String] = []
	for token in tokens:
		if token.is_valid_float():
			output.append(token.to_float())
		elif token == "x":
			output.append("x")
		elif token in ["sqrt", "sin", "cos", "tan", "("]:
			op_stack.append(token)
		elif token == ")":
			while not op_stack.is_empty() and op_stack.back() != "(":
				output.append(op_stack.pop_back())
			if not op_stack.is_empty(): op_stack.pop_back()
			if not op_stack.is_empty() and op_stack.back() in ["sqrt", "sin", "cos", "tan"]:
				output.append(op_stack.pop_back())
		else:
			while not op_stack.is_empty() and op_stack.back() != "(" and (
				get_precedence(op_stack.back()) > get_precedence(token) or 
				(get_precedence(op_stack.back()) == get_precedence(token) and token != "^")
			):
				output.append(op_stack.pop_back())
			op_stack.append(token)
	while not op_stack.is_empty():
		var op: String = op_stack.pop_back()
		if op != "(": output.append(op)
	return output

# ==========================================
# 4. MOUSE PANNING (Clamped to +X, +Y Quadrant)
# ==========================================
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var local_pos: Vector2 = to_local(event.global_position)
		var in_bounds: bool = Rect2(Vector2.ZERO, Vector2(SCREEN_SIZE, SCREEN_SIZE)).has_point(local_pos)
		if event.pressed and in_bounds:
			is_dragging = true
			drag_start_mouse = event.global_position
			drag_start_origin = view_origin
		elif not event.pressed:
			is_dragging = false
			
	elif event is InputEventMouseMotion and is_dragging:
		var delta: Vector2 = (event.global_position - drag_start_mouse) / scale
		view_origin.x = max(0, drag_start_origin.x - int(delta.x))
		view_origin.y = max(0, drag_start_origin.y + int(delta.y))
		update_graph()
