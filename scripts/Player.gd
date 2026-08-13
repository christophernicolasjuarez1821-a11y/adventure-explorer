extends KinematicBody

export var speed = 5.0
export var gravity = 20.0
export var jump_force = 8.0
export var mouse_sensitivity = 0.002
export var reach = 5.0

var velocity = Vector3()
var block_scene = preload("res://scenes/Block.tscn")

onready var camera = $Camera
onready var highlight = $BlockHighlight

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg2rad(-89), deg2rad(89))

	if event is InputEventMouseButton and event.pressed:
		var result = get_target()

		if result.empty():
			return

		if event.button_index == BUTTON_LEFT:
			mine_block(result)
		elif event.button_index == BUTTON_RIGHT:
			place_block(result)

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
		body.queue_free()

func place_block(result):
	var pos = (result.position + result.normal * 0.5).round()
	var block = block_scene.instance()
	block.transform.origin = pos
	get_parent().add_child(block)

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
