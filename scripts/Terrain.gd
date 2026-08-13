extends Spatial

export var world_seed = 12345
export var size = 16
export var noise_scale = 0.15
export var height_scale = 3.0

var block_scene = preload("res://scenes/Block.tscn")
var noise = OpenSimplexNoise.new()

var grass_mat = SpatialMaterial.new()
var dirt_mat = SpatialMaterial.new()

func _ready():
	noise.seed = world_seed
	grass_mat.albedo_color = Color(0.25, 0.7, 0.25)
	dirt_mat.albedo_color = Color(0.45, 0.32, 0.2)
	generate()

func generate():
	var half = size / 2

	for x in range(-half, half):
		for z in range(-half, half):
			var n = noise.get_noise_2d(x * noise_scale, z * noise_scale)
			var h = int(round((n + 1.0) * 0.5 * height_scale)) + 1

			for y in range(1, h + 1):
				var block = block_scene.instance()
				block.transform.origin = Vector3(x, y, z)

				var mesh_instance = block.get_node("MeshInstance")

				if y == h:
					mesh_instance.material_override = grass_mat
				else:
					mesh_instance.material_override = dirt_mat

				add_child(block)
