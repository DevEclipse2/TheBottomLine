extends Sprite2D

var img: Image
var img_texture: ImageTexture

func _ready() -> void:
	# 1. Create a blank 64x64 RGBA8 image in CPU memory
	img = Image.create_empty(512, 512, false, Image.FORMAT_RGBA8)
	
	# 2. Loop through and set each pixel
	for x in range(img.get_width()):
		for y in range(img.get_height()):
			#img.set_pixel(x, y, Color(0.83, 0.808, 0.606, 0.0))
			img.set_pixel(x, y, Color(0.83, 0, 1.0, 1.0))
	
	# 3. Create an ImageTexture from the Image and assign it to the Sprite2D
	img_texture = ImageTexture.create_from_image(img)
	texture = img_texture
	
	# Optional: Keep pixel art crisp by disabling linear filtering
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
func _process(delta: float) -> void:
	#img.set_pixel(x,y,col)
	img_texture.update(img)
	pass
