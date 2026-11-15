extends Sprite2D

const IMG_SIZE: int = 512
## Metadata key holding Array[PackedStringArray] (or a single PackedStringArray)
const META_KEY: String = "functions"

@export var bg_color: Color = Color(0.1, 0.1, 0.12, 1.0)
@export var axis_color: Color = Color(0.28, 0.28, 0.32, 1.0)
@export var collision_color: Color = Color.RED

var img: Image
var img_texture: ImageTexture

## Panning state: origin_offset is the pixel coordinate of math (0, 0) on the 512x512 canvas
var origin_offset: Vector2i = Vector2i(IMG_SIZE / 2, IMG_SIZE / 2)
var _is_dragging: bool = false
var _drag_accum: Vector2 = Vector2.ZERO

## Cached function colors and dirty-check state
var _func_colors: Array[Color] = []
var _last_meta_hash: int = 0
var _needs_redraw: bool = true


func _ready() -> void:
	# 1. Create a 512x512 RGBA8 image in CPU memory
	img = Image.create_empty(IMG_SIZE, IMG_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(bg_color)
	
	# 2. Create an ImageTexture from the Image and assign it to the Sprite2D
	img_texture = ImageTexture.create_from_image(img)
	texture = img_texture
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	# Initialize metadata with an empty array if not already present
	if not has_meta(META_KEY):
		set_meta(META_KEY, [])
		
	_redraw_graph()


func _input(event: InputEvent) -> void:
	# Left-click press / release
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Only start dragging if the click is inside the Sprite2D's rect
			if get_rect().has_point(to_local(event.global_position)):
				_is_dragging = true
				_drag_accum = Vector2.ZERO
		else:
			_is_dragging = false
			
	# Left-click drag to pan around the space in integer steps
	elif event is InputEventMouseMotion and _is_dragging:
		_drag_accum += event.relative / global_scale
		var step := Vector2i(int(_drag_accum.x), int(_drag_accum.y))
		if step != Vector2i.ZERO:
			origin_offset += step
			_drag_accum -= Vector2(step)
			_needs_redraw = true


func _process(_delta: float) -> void:
	# Check if the metadata functions array has been modified externally
	var current_functions: Array[PackedStringArray] = _get_rpn_functions()
	var current_hash: int = hash(current_functions)
	
	if current_hash != _last_meta_hash:
		_last_meta_hash = current_hash
		_ensure_random_colors(current_functions.size())
		_needs_redraw = true
		
	if _needs_redraw:
		_redraw_graph()
		img_texture.update(img)
		_needs_redraw = false


## Reads the metadata and normalizes it into an Array of PackedStringArrays
func _get_rpn_functions() -> Array[PackedStringArray]:
	var result: Array[PackedStringArray] = []
	if not has_meta(META_KEY):
		return result
		
	var raw_meta = get_meta(META_KEY)
	
	# Support either a single PackedStringArray or an Array of PackedStringArrays
	if raw_meta is PackedStringArray:
		if not raw_meta.is_empty():
			result.append(raw_meta)
	elif raw_meta is Array:
		for item in raw_meta:
			if item is PackedStringArray and not item.is_empty():
				result.append(item)
			elif item is Array and not item.is_empty():
				result.append(PackedStringArray(item))
				
	return result


## Assigns a distinct random color to each function (avoiding red hue ~0.0/1.0)
func _ensure_random_colors(count: int) -> void:
	while _func_colors.size() < count:
		# Pick a random hue between 0.08 and 0.92 so it never looks like collision_color (Red)
		var hue: float = randf_range(0.08, 0.92)
		var col: Color = Color.from_hsv(hue, randf_range(0.7, 0.95), randf_range(0.85, 1.0))
		_func_colors.append(col)


## Renders all functions at integer x steps and highlights collisions in red
func _redraw_graph() -> void:
	img.fill(bg_color)
	_draw_axes()
	
	var functions: Array[PackedStringArray] = _get_rpn_functions()
	if functions.is_empty():
		return
		
	# Track which pixel coordinates (x, y) are already occupied by a previous function
	# Key: int (y * IMG_SIZE + x), Value: int (function index that first drew here)
	var occupied_pixels: Dictionary = {}
	
	for f_idx in range(functions.size()):
		var rpn: PackedStringArray = functions[f_idx]
		var func_color: Color = _func_colors[f_idx]
		
		# Step across every integer pixel column on the canvas
		for px in range(IMG_SIZE):
			# Convert screen pixel X to integer math coordinate X
			var math_x: int = px - origin_offset.x
			
			# Evaluate RPN at integer math_x
			var math_y_float: float = _evaluate_rpn(rpn, float(math_x))
			if is_nan(math_y_float) or is_inf(math_y_float):
				continue
				
			# Snap output Y to integer step and convert to screen pixel Y (Y-up in math, Y-down in image)
			var math_y: int = roundi(math_y_float)
			var py: int = origin_offset.y - math_y
			
			if py >= 0 and py < IMG_SIZE:
				var pixel_key: int = py * IMG_SIZE + px
				
				# If another function already plotted this exact pixel, mark collision in RED
				if occupied_pixels.has(pixel_key) and occupied_pixels[pixel_key] != f_idx:
					img.set_pixel(px, py, collision_color)
				else:
					occupied_pixels[pixel_key] = f_idx
					img.set_pixel(px, py, func_color)


func _draw_axes() -> void:
	if origin_offset.x >= 0 and origin_offset.x < IMG_SIZE:
		for y in range(IMG_SIZE):
			img.set_pixel(origin_offset.x, y, axis_color)
	if origin_offset.y >= 0 and origin_offset.y < IMG_SIZE:
		for x in range(IMG_SIZE):
			img.set_pixel(x, origin_offset.y, axis_color)


## Evaluates a PackedStringArray in Reverse Polish Notation for a given x
func _evaluate_rpn(rpn: PackedStringArray, x_val: float) -> float:
	var stack: Array[float] = []
	
	for token in rpn:
		print(token)
		if token.is_valid_float():
			stack.append(token.to_float())
		elif token == "x":
			stack.append(x_val)
		elif token == "sin":
			if stack.is_empty(): return NAN
			stack.append(sin(stack.pop_back()))
		else:
			if stack.size() < 2: return NAN
			var b: float = stack.pop_back()
			var a: float = stack.pop_back()
			match token:
				"+": stack.append(a + b)
				"-": stack.append(a - b)
				"*": stack.append(a * b)
				"/":
					if is_zero_approx(b): return NAN
					stack.append(a / b)
				"^": stack.append(pow(a, b))
				_: return NAN
				
	return stack.back() if not stack.is_empty() else NAN
