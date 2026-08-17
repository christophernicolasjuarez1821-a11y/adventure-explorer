extends Node

var types = {
	"grass": Color(0.25, 0.7, 0.25),
	"dirt": Color(0.45, 0.32, 0.2),
	"stone": Color(0.55, 0.55, 0.55),
	"wood": Color(0.55, 0.4, 0.2),
}

var materials = {}

func _ready():
	for t in types:
		var m = SpatialMaterial.new()
		m.albedo_color = types[t]
		materials[t] = m

func get_material(t):
	if materials.has(t):
		return materials[t]
	return null

func get_color(t):
	if types.has(t):
		return types[t]
	return Color(1, 0, 1)

