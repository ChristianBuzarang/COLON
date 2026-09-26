extends CharacterBody3D

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

#@export var speed = 2.5
@export var mouse_sensitivity = 0.002
@export var ground_mist: FogVolume

@onready var world_env = get_node("/root/Main/WorldEnvironment")
@onready var head = $Head
@onready var phone = $Head/Camera3D/Phone_Pivot
@onready var flashlight = $Head/Camera3D/SpotLight3D
@onready var interact_ray = $Head/Camera3D/RayCast3D
@onready var skeleton = $character_visual/root_character_deform/Skeleton3D
@onready var anim_player = $character_visual/AnimationPlayer

const ANIM_IDLE = "iddle_001"
const ANIM_WALK = "anim_walkwHD"
const ANIM_RUN = "runHD_001"
const ANIM_INTERACT = "attackHD_001"

var phone_lowered_pos = Vector3(0.4, -0.6, -0.5)
var phone_raised_pos = Vector3(0, -0.2, -0.4)
var is_phone_raised = false
var panic_level = 0.0
var current_anim = ""

var base_head_height : float
var bob_freq = 2.0
var bob_amp = 0.05
var t_bob = 0.0
var is_interacting = false
var sprint_speed = 5.0
var walk_speed = 2.5

var head_bone_idx


func _process(_delta):
	# 2% chance per frame to flicker
	if randf() > 0.98: flashlight.light_energy = randf_range(0.5, 1.5)
	else: flashlight.light_energy = lerp(flashlight.light_energy, 1.0, 0.1)
	
	# If the player is in the dark/fog too long, increase panic
	if panic_level > 0.5:
		var shake_amount = panic_level * 0.05
		head.position.x = randf_range(-shake_amount, shake_amount)
		head.position.y = randf_range(-shake_amount, shake_amount)
		
		# Logic to increase panic (e.g., being near the "monster" or in a dead end)
		# panic_level = move_toward(panic_level, 1.0, delta * 0.1)

func _ready():
	head_bone_idx = skeleton.find_bone("DEF-spine.006")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Eye-level height
	base_head_height = head.position.y

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-60), deg_to_rad(60))

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	var current_speed = walk_speed
	if Input.is_action_pressed("sprint") and is_on_floor():
		current_speed = sprint_speed
	
	# Movement Logic
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
	
	# Phone Light Toggle Logic (Diegetic UI)
	if Input.is_action_just_pressed("toggle_light"):
		is_phone_raised = !is_phone_raised
	
	var target_pos = phone_raised_pos if is_phone_raised else phone_lowered_pos
	phone.position = phone.position.lerp(target_pos, delta * 5.0)
	
	# Head Rotation
	if head_bone_idx != -1:
		var target_rotation = Quaternion(Vector3(1, 0, 0), head.rotation.x)
		skeleton.set_bone_pose_rotation(head_bone_idx, target_rotation)
	
	# Head Bob Login
	t_bob += delta * velocity.length() * float(is_on_floor())
	var pos = Vector3.ZERO
	pos.y = base_head_height + sin(t_bob * bob_freq) * bob_amp
	pos.x = cos(t_bob * bob_freq / 2) * bob_amp
	head.position = pos
	
	if not is_interacting:
		update_animations()

func _input(event):
	if event.is_action_pressed("toggle_light"):
		flashlight.visible = !flashlight.visible
	
	if event.is_action_pressed("interact"): 
		play_interact_animation()
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

func update_animations():
	var speed = Vector2(velocity.x, velocity.z).length()
	
	if not is_on_floor():
		anim_player.play("jumpHD_001", 0.2)
	elif speed > 0.1:
		anim_player.play(ANIM_WALK, 0.3)
		anim_player.speed_scale = speed / 3.0
	else:
		anim_player.play(ANIM_IDLE, 0.3)
		anim_player.speed_scale = 1.0

func play_interact_animation():
	is_interacting = true
	
	# The parameters are: (Animation Name, Blend Time, Speed Scale)
	# Speed Scale 0.5 = 50% speed (Half speed)
	# Speed Scale 0.2 = 20% speed (Very slow and tense)
	anim_player.play(ANIM_INTERACT, 0.2, 0.4)
	await get_tree().create_timer(0.6).timeout
	
	await anim_player.animation_finished
	is_interacting = false
