extends CharacterBody3D

@export var speed = 2.5
@export var mouse_sensitivity = 0.002
@onready var head = $Head
@onready var phone = $Head/Camera3D/Phone_Pivot
@onready var flashlight = $Head/Camera3D/SpotLight3D

var phone_lowered_pos = Vector3(0.4, -0.6, -0.5)
var phone_raised_pos = Vector3(0, -0.2, -0.4)
var is_phone_raised = false


func _process(_delta):
	# 2% chance per frame to flicker
	if randf() > 0.98: flashlight.light_energy = randf_range(0.5, 1.5)
	else: flashlight.light_energy = lerp(flashlight.light_energy, 1.0, 0.1)

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, -deg_to_rad(80), deg_to_rad(80))

func _physics_process(delta):
	# Movement Logic
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()
	
	# Phone Light Toggle Logic (Diegetic UI)
	if Input.is_action_just_pressed("toggle_light"):
		is_phone_raised = !is_phone_raised
	
	var target_pos = phone_raised_pos if is_phone_raised else phone_lowered_pos
	phone.position = phone.position.lerp(target_pos, delta * 5.0)
