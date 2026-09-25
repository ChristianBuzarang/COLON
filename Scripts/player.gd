extends CharacterBody3D

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@export var speed = 2.5
@export var mouse_sensitivity = 0.002
@export var ground_mist: FogVolume

@onready var world_env = get_node("/root/Main/WorldEnvironment")
@onready var head = $Head
@onready var phone = $Head/Camera3D/Phone_Pivot
@onready var flashlight = $Head/Camera3D/SpotLight3D
@onready var interact_ray = $Head/Camera3D/RayCast3D

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
	if not is_on_floor():
		velocity.y -= gravity * delta
	
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

func _input(event):
	if event.is_action_pressed("interact"): # Map "E" 
		if interact_ray.is_colliding():
			var object = interact_ray.get_collider()
			print("Raycast hit: ", object.name)
			
			var target = object
			while target != null:
				if target.has_method("toggle_door"):
					print("Found door script on: ", target.name)
					target.toggle_door()
					return
				target = target.get_parent()
			
			print("Hit something, but no 'toggle_door' script found!")
		else:
			print("Raycast hit nothing.")

func increase_panic(amount):
	var env = world_env.environment
	
	# Gradually make the fog thicker and closer
	env.volumetric_fog_density = lerp(env.volumetric_fog_density, 0.8, amount)
	env.volumetric_fog_albedo = Color(0.2, 0, 0) # Turn fog deep red

func make_fog_rise(delta):
	# Gradually increase the size of the fog box upward
	ground_mist.size.y += delta * 0.5
	
	var mat = ground_mist.material as FogMaterial
	mat.height_falloff = lerp(mat.height_falloff, 0.0, delta)
