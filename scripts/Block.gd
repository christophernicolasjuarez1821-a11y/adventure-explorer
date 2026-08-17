extends StaticBody

export var block_type = "dirt"

func _ready():
	add_to_group("blocks")
	apply_type()

func apply_type():
	$MeshInstance.material_override = BlockData.get_material(block_type)
