extends Control

const SCREEN_SIZE: int = 128

# Pan offset in world coordinates (center of the 128x128 view)
var camera_center: Vector2i = Vector2i(0, 0)
var is_dragging: bool = false
var drag_start_mouse: Vector2 = Vector2.ZERO
var drag_start_cam: Vector2i = Vector2i.ZERO

var graph_image: Image
var graph_texture: ImageTexture
var texture_rect: TextureRect
var equation_label: RichTextLabel

# Stored functions: { "expr": String, "rpn": Array, "color": Color }
var functions: Array[Dictionary] = []

func _ready() -> void:
	# 1. Setup 128x128 Pixel Display (scaled up 4x so you can see it clearly)
	graph_image = Image.create(SCREEN_SIZE, SCREEN_SIZE, false, Image.FORMAT_RGBA8)
	graph_texture = ImageTexture.create_from_image(graph_image)
	
	texture_rect = TextureRect.new()
	texture_rect.texture = graph_texture
	texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST # Crisp pixels
	texture_rect.custom_minimum_size = Vector2(512, 512)
	texture_rect.position = Vector2(20, 20)
	add_child(texture_rect)
	
	# 2. Setup Equation Display (BBCode RichTextLabel)
	equation_label = RichTextLabel.new()
	equation_label.bbcode_enabled = true
	equation_label.position = Vector2(552, 20)
	equation_label.size = Vector2(400, 512)
	add_child(equation_label)
	
	# 3. Add sample functions (Supports implicit multiplication like 3x and full PEMDAS)
	add_function("sqrt(x+2)/(3x-1)", Color.CYAN)
	add_function("sin(x/4)*10", Color.GREEN)
	add_function("(x^2)/16 - 20", Color.YELLOW)
	
	update_graph()

# ==========================================
# 1. FUNCTION MANAGEMENT & DISPLAY
# ==========================================
func add_function(expr: String, color: Color) -> void:
	var rpn: Array = parse_to_rpn(expr)
	functions.append({
		"expr": expr,
		"rpn": rpn,
		"color": color
	})
	update_equation_display()

func update_equation_display() -> void:
	var text: String = "[b]Functions (Drag graph to pan):[/b]\n\n"
	for i in range(functions.size()):
		var fn: Dictionary = functions[i]
		var hex: String = fn["color"].to_html(false)
		var pretty: String = format_math_bbcode(fn["expr"])
		text += "[color=#%s]f%d(x) = %s[/color]\n" % [hex, i + 1, pretty]
	text += "\n[color=#ff0000][b]■ Bright Red = Intersections[/b][/color]"
	equation_label.text = text

func format_math_bbcode(expr: String) -> String:
	# Replaces sqrt and exponents with cleaner visual formatting
	var out: String = expr.replace("sqrt", "√").replace("*", "·")
	return out

# ==========================================
# 2. SHUNTING-YARD PARSER (Infix -> RPN Array)
# ==========================================
func tokenize(expr: String) -> Array[String]:
	var tokens: Array[String] = []
	var i: int = 0
	var s: String = expr.replace(" ", "")
	
	while i < s.length():
		var c: String = s[i]
		# Numbers
		if c.is_valid_int() or c == ".":
			var num_str: String = ""
			while i < s.length() and (s[i].is_valid_int() or s[i] == "."):
				num_str += s[i]
				i += 1
			tokens.append(num_str)
			# Handle implicit multiplication like "3x" or "3(" -> insert "*"
			if i < s.length() and (s[i] == "x" or s[i] == "(" or s[i].is_valid_identifier()):
				tokens.append("*")
			continue
		
		# Variable x
		if c == "x":
			tokens.append("x")
			i += 1
			if i < s.length() and (s[i] == "(" or s[i].is_valid_identifier()):
				tokens.append("*")
			continue
			
		# Multi-character functions (sqrt, sin, cos, tan)
		if s.substr(i).begins_with("sqrt"):
			tokens.append("sqrt")
			i += 4
			continue
		for fn_name in ["sin", "cos", "tan"]:
			if s.substr(i).begins_with(fn_name):
				tokens.append(fn_name)
				i += 3
				break
		if c in ["+", "-", "*", "/", "^", "(", ")"]:
			# Handle unary minus (e.g., "-x" or "(-2)") by converting to "0 - ..."
			if c == "-" and (tokens.is_empty() or tokens.back() in ["(", "+", "-", "*", "/", "^"]):
				tokens.append("0")
			tokens.append(c)
			i += 1
			continue
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
		elif token in ["sqrt", "sin", "cos", "tan"]:
			op_stack.append(token)
		elif token == "(":
			op_stack.append(token)
		elif token == ")":
			while not op_stack.is_empty() and op_stack.back() != "(":
				output.append(op_stack.pop_back())
			if not op_stack.is_empty():
				op_stack.pop_back() # Pop "("
			if not op_stack.is_empty() and op_stack.back() in ["sqrt", "sin", "cos", "tan"]:
				output.append(op_stack.pop_back())
		else: # Operator
			while not op_stack.is_empty() and op_stack.back() != "(" and (
				get_precedence(op_stack.back()) > get_precedence(token) or 
				(get_precedence(op_stack.back()) == get_precedence(token) and token != "^")
			):
				output.append(op_stack.pop_back())
			op_stack.append(token)
			
	while not op_stack.is_empty():
		output.append(op_stack.pop_back())
	return output

# ==========================================
# 3. VECTORIZED EVALUATION (1 Operator across all 128 X values)
# ==========================================
func evaluate_rpn_vectorized(rpn: Array, x_values: PackedFloat64Array) -> PackedFloat64Array:
	var stack: Array[PackedFloat64Array] = []
	
	for token in rpn:
		# 1. Push variable X array
		if typeof(token) == TYPE_STRING and token == "x":
			stack.append(x_values.duplicate())
			
		# 2. Push constant number expanded to 128 elements
		elif typeof(token) == TYPE_FLOAT or typeof(token) == TYPE_INT:
			var arr := PackedFloat64Array()
			arr.resize(SCREEN_SIZE)
			arr.fill(float(token))
			stack.append(arr)
			
		# 3. Execute Unary Operator across all 128 pixels at once
		elif token in ["sqrt", "sin", "cos", "tan"]:
			var a: PackedFloat64Array = stack.pop_back()
			var res := PackedFloat64Array()
			res.resize(SCREEN_SIZE)
			match token:
				"sqrt":
					for i in range(SCREEN_SIZE):
						res[i] = sqrt(a[i]) if a[i] >= 0.0 else NAN
				"sin":
					for i in range(SCREEN_SIZE): res[i] = sin(a[i])
				"cos":
					for i in range(SCREEN_SIZE): res[i] = cos(a[i])
				"tan":
					for i in range(SCREEN_SIZE): res[i] = tan(a[i])
			stack.append(res)
			
		# 4. Execute Binary Operator across all 128 pixels at once
		elif token in ["+", "-", "*", "/", "^"]:
			var b: PackedFloat64Array = stack.pop_back()
			var a: PackedFloat64Array = stack.pop_back()
			var res := PackedFloat64Array()
			res.resize(SCREEN_SIZE)
			match token:
				"+":
					for i in range(SCREEN_SIZE): res[i] = a[i] + b[i]
				"-":
					for i in range(SCREEN_SIZE): res[i] = a[i] - b[i]
				"*":
					for i in range(SCREEN_SIZE): res[i] = a[i] * b[i]
				"/":
					for i in range(SCREEN_SIZE):
						res[i] = a[i] / b[i] if b[i] != 0.0 else NAN
				"^":
					for i in range(SCREEN_SIZE): res[i] = pow(a[i], b[i])
			stack.append(res)
			
	return stack.back() if not stack.is_empty() else PackedFloat64Array()

# ==========================================
# 4. RENDERING & INTERSECTION DETECTION
# ==========================================
func update_graph() -> void:
	graph_image.fill(Color(0.08, 0.08, 0.1)) # Dark background
	
	# Precompute the 128 integer X coordinates for the current window
	var x_coords := PackedFloat64Array()
	x_coords.resize(SCREEN_SIZE)
	var start_x: int = camera_center.x - (SCREEN_SIZE / 2)
	for px in range(SCREEN_SIZE):
		x_coords[px] = float(start_x + px)
		
	# Draw X and Y Axes (if visible inside the 128x128 window)
	var axis_color := Color(0.25, 0.25, 0.3)
	var origin_px: int = 0 - start_x
	var origin_py: int = (SCREEN_SIZE / 2) + camera_center.y
	if origin_px >= 0 and origin_px < SCREEN_SIZE:
		for y in range(SCREEN_SIZE): graph_image.set_pixel(origin_px, y, axis_color)
	if origin_py >= 0 and origin_py < SCREEN_SIZE:
		for x in range(SCREEN_SIZE): graph_image.set_pixel(x, origin_py, axis_color)
	
	# Track how many functions hit each pixel to detect intersections
	var hit_grid := PackedInt32Array()
	hit_grid.resize(SCREEN_SIZE * SCREEN_SIZE)
	hit_grid.fill(0)
	
	# Evaluate and plot each function
	for fn_idx in range(functions.size()):
		var fn: Dictionary = functions[fn_idx]
		var y_values: PackedFloat64Array = evaluate_rpn_vectorized(fn["rpn"], x_coords)
		var col: Color = fn["color"]
		
		for px in range(SCREEN_SIZE):
			var y_val: float = y_values[px]
			if is_nan(y_val) or is_inf(y_val):
				continue
				
			# Convert world Y to screen pixel Y (inverted because screen +Y is down)
			var py: int = int(round((SCREEN_SIZE / 2) - (y_val - camera_center.y)))
			if py >= 0 and py < SCREEN_SIZE:
				var idx: int = py * SCREEN_SIZE + px
				hit_grid[idx] += 1
				
				# If 2 or more functions land on the same pixel, outline in bright red
				if hit_grid[idx] > 1:
					_draw_intersection_outline(px, py)
				else:
					graph_image.set_pixel(px, py, col)
					
	graph_texture.update(graph_image)

func _draw_intersection_outline(cx: int, cy: int) -> void:
	# Draws a bright red pixel at the intersection and outlines its 1px neighbors
	var red := Color(1.0, 0.0, 0.0)
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var nx: int = cx + dx
			var ny: int = cy + dy
			if nx >= 0 and nx < SCREEN_SIZE and ny >= 0 and ny < SCREEN_SIZE:
				graph_image.set_pixel(nx, ny, red)

# ==========================================
# 5. MOUSE DRAG PANNING (Desmos-style)
# ==========================================
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			drag_start_mouse = event.position
			drag_start_cam = camera_center
		else:
			is_dragging = false
			
	elif event is InputEventMouseMotion and is_dragging:
		# Divide by 4.0 because our 128x128 texture is displayed at 512x512
		var delta: Vector2 = (event.position - drag_start_mouse) / 4.0
		camera_center = drag_start_cam + Vector2i(int(-delta.x), int(delta.y))
		update_graph()
