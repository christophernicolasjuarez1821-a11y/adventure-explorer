extends KinematicBody

export var speed = 5.0
export var gravity = 20.0
export var jump_force = 8.0
export var mouse_sensitivity = 0.002
export var reach = 5.0

const SAVE_PATH = "user://save.json"

var velocity = Vector3()

var inventory = {"grass": 0, "dirt": 0, "stone": 0, "wood": 5}
var hotbar_types = ["grass", "dirt", "stone", "wood"]
var selected_slot = 0

onready var camera = $Camera
onready var highlight = $BlockHighlight
onready var message_label = $HUD/MessageLabel
onready var slot_labels = [
	$HUD/Hotbar/Slot0,
	$HUD/Hotbar/Slot1,
	$HUD/Hotbar/Slot2,
	$HUD/Hotbar/Slot3
]

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	message_label.visible = false

	var terrain = get_parent().get_node("Terrain")

	if not load_game():
		terrain.generate()
		show_message("Mundo nuevo generado")
	else:
		show_message("Mundo cargado")

	update_hotbar()

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg2rad(-89), deg2rad(89))

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == BUTTON_WHEEL_UP:
			selected_slot = (selected_slot + 1) % hotbar_types.size()
			update_hotbar()
			return

		if event.button_index == BUTTON_WHEEL_DOWN:
			selected_slot = (selected_slot - 1 + hotbar_types.size()) % hotbar_types.size()
			update_hotbar()
			return

		var result = get_target()

		if result.empty():
			return

		if event.button_index == BUTTON_LEFT:
			mine_block(result)
		elif event.button_index == BUTTON_RIGHT:
			place_block(result)

	if event is InputEventKey and event.pressed:
		if event.scancode >= KEY_1 and event.scancode <= KEY_4:
			selected_slot = event.scancode - KEY_1
			update_hotbar()

		if event.scancode == KEY_F9:
			save_game()

	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	var input_dir = Vector3()

	if Input.is_action_pressed("ui_up"):
		input_dir.z -= 1
	if Input.is_action_pressed("ui_down"):
		input_dir.z += 1
	if Input.is_action_pressed("ui_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("ui_right"):
		input_dir.x += 1

	input_dir = input_dir.normalized()

	var forward = -global_transform.basis.z
	var right = global_transform.basis.x
	var move_dir = forward * -input_dir.z + right * input_dir.x

	velocity.x = move_dir.x * speed
	velocity.z = move_dir.z * speed

	if is_on_floor() and Input.is_key_pressed(KEY_SPACE):
		velocity.y = jump_force

	velocity.y -= gravity * delta

	velocity = move_and_slide(velocity, Vector3.UP)

	update_highlight()

func get_target():
	var from = camera.global_transform.origin
	var to = from + (-camera.global_transform.basis.z) * reach
	return get_world().direct_space_state.intersect_ray(from, to, [self])

func mine_block(result):
	var body = result.collider

	if body.is_in_group("blocks"):
		var t = body.block_type

		if inventory.has(t):
			inventory[t] += 1

		update_hotbar()
		body.queue_free()

func place_block(result):
	var t = hotbar_types[selected_slot]

	if inventory[t] <= 0:
		return

	var pos = (result.position + result.normal * 0.5).round()

	get_parent().get_node("Terrain").add_block(pos, t)

	inventory[t] -= 1
	update_hotbar()

func save_game():
	var terrain = get_parent().get_node("Terrain")

	var data = {
		"player_pos": [
			global_transform.origin.x,
			global_transform.origin.y,
			global_transform.origin.z
		],
		"inventory": inventory,
		"selected_slot": selected_slot,
		"blocks": terrain.get_save_data()
	}

	var file = File.new()
	file.open(SAVE_PATH, File.WRITE)
	file.store_string(JSON.print(data))
	file.close()

	show_message("Juego guardado")

func load_game():
	var file = File.new()

	if not file.file_exists(SAVE_PATH):
		return false

	file.open(SAVE_PATH, File.READ)
	var text = file.get_as_text()
	file.close()

	var parse = JSON.parse(text)

	if parse.error != OK:
		return false

	var data = parse.result

	if data.has("inventory"):
		inventory = data["inventory"]
		for k in inventory:
			inventory[k] = int(inventory[k])

	if data.has("selected_slot"):
		selected_slot = int(data["selected_slot"])

	if data.has("blocks"):
		get_parent().get_node("Terrain").load_blocks(data["blocks"])

	if data.has("player_pos"):
		var p = data["player_pos"]
		global_transform.origin = Vector3(p[0], p[1], p[2])

	return true

func show_message(text):
	message_label.text = text
	message_label.visible = true
	yield(get_tree().create_timer(1.5), "timeout")
	message_label.visible = false

func update_hotbar():
	for i in range(slot_labels.size()):
		var t = hotbar_types[i]
		var label = slot_labels[i]

		label.text = "%d:%d" % [i + 1, inventory[t]]

		if i == selected_slot:
			label.add_color_override("font_color", Color(1, 1, 0))
		else:
			label.add_color_override("font_color", Color(1, 1, 1))

func update_highlight():
	var result = get_target()

	if result.empty():
		highlight.visible = false
		return

	var body = result.collider

	if body.is_in_group("blocks"):
		highlight.visible = true
		highlight.global_transform.origin = body.global_transform.origin
	else:
		highlight.visible = false
