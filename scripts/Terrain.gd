extends Spatial

export var world_seed = 12345
export var size = 16
export var noise_scale = 0.15
export var height_scale = 3.0

var block_scene = preload("res://scenes/Block.tscn")
var noise = OpenSimplexNoise.new()

func generate():
	noise.seed = world_seed
	var half = size / 2

	for x in range(-half, half):
		for z in range(-half, half):
			var n = noise.get_noise_2d(x * noise_scale, z * noise_scale)
			var h = int(round((n + 1.0) * 0.5 * height_scale)) + 1

			for y in range(1, h + 1):
				var t = "grass" if y == h else ("dirt" if y > h - 3 else "stone")
				add_block(Vector3(x, y, z), t)

func add_block(pos, type):
	var block = block_scene.instance()
	block.block_type = type
	block.transform.origin = pos
	add_child(block)

func clear_blocks():
	for c in get_children():
		c.queue_free()

func load_blocks(blocks):
	clear_blocks()

	for b in blocks:
		add_block(Vector3(b[0], b[1], b[2]), b[3])

func get_save_data():
	var data = []

	for c in get_children():
		if c.is_in_group("blocks"):
			var p = c.transform.origin
			data.append([int(p.x), int(p.y), int(p.z), c.block_type])

	return data
