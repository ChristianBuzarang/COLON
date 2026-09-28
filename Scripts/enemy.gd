extends CharacterBody3D

enum State { STATIC, IDLE, SEARCH, CHASE, ATTACKING }

@export var current_state = State.STATIC
@export var chase_speed = 1.5
@export var search_speed = 0.75
@export var rotation_speed = 5.0
@export var vision_range = 15.0
@export var hearing_sensitivity = 1.5 # How good the hearing of enemy

@onready var nav_agent = $NavigationAgent3D
@onready var player = get_tree().get_first_node_in_group("player")
@onready var visuals = $Visuals
@onready var ray = $RayCast3D
@onready var anim_tree = $Visuals/Red_Zombie/AnimationTree
@onready var anim_state = anim_tree.get("parameters/playback")

var target_pos = Vector3.ZERO
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var last_state = -1 # Track state changes


func _ready():
	ray.add_exception(self)
	ray.collision_mask = 1

func _physics_process(delta: float) -> void:
	if !player: return
	if not is_on_floor(): velocity.y -= gravity * delta
	
	# Logic Layers
	var can_see = can_see_player()
	var heard_something = check_hearing()
	
	if can_see and global_position.distance_to(player.global_position) < 10.0:
		check_for_panic(delta)
	
	# State Machine Logic
	match current_state:
		State.STATIC:
			handle_gaze(delta)
			update_animation(0.0)
		
		State.IDLE:
			update_animation(0.0)
			
			if can_see: current_state = State.CHASE
			elif heard_something: current_state = State.SEARCH
		
		State.SEARCH:
			update_animation(1.0)
			nav_agent.target_position = target_pos
			move_to_target(search_speed) 
			
			if can_see: current_state = State.CHASE
			elif nav_agent.is_navigation_finished():
				current_state = State.IDLE 
		
		State.CHASE:
			update_animation(2.0)
			handle_gaze(delta)
			
			if can_see:
				target_pos = player.global_position
				nav_agent.target_position = target_pos
				move_to_target(chase_speed)
			else:
				print("Lost sight. Moving to last known position.")
				current_state = State.SEARCH
		
		State.ATTACKING:
			velocity = Vector3.ZERO # Don't move while attacking

func update_animation(value):
	anim_tree.set("parameters/Move/blend_position", value)
	if current_state != last_state:
		anim_state.travel("Move")
		last_state = current_state

func can_see_player() -> bool:
	var dist = global_position.distance_to(player.global_position)
	if dist > vision_range: return false
	
	var target_vector = player.get_node("Head").global_position
	ray.look_at(target_vector)
	ray.force_raycast_update()
	
	if ray.is_colliding():
		var collider = ray.get_collider()
		print("Zombie sees: ", collider.name) 
		
		if collider.is_in_group("player"): return true
		print("Zombie view blocked by: ", collider.name)
	
	return false

func check_hearing() -> bool:
	var dist = global_position.distance_to(player.global_position)
	
	# IF Player Noise > Distance (Adjusted by sensitivity)
	if player.current_noise_level > (dist / hearing_sensitivity):
		print("Enemy heard a noise at: ", player.global_position)
		target_pos = player.global_position
		return true
	
	return false

func move_to_target(speed):
	if nav_agent.is_navigation_finished(): return
	
	var next_pos = nav_agent.get_next_path_position()
	var dir = (next_pos - global_position).normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	move_and_slide()

func handle_gaze(delta):
	# Smoothly rotate the visuals to face the player
	var look_target = player.global_position
	look_target.y = global_position.y
	
	var target_dir = global_position.direction_to(look_target)
	
	if target_dir.length() > 0.001:
		var target_basis = Basis.looking_at(target_dir)
		visuals.basis = visuals.basis.slerp(target_basis, rotation_speed * delta)

func check_for_panic(delta):
	player.insanity_level += 20.0 * delta
	print("Insanity Level: ", player.insanity_level)

func _on_kill_zone_body_entered(body):
	if body.is_in_group("player") and current_state != State.ATTACKING:
		current_state = State.ATTACKING
		anim_state.travel("attack")
		trigger_jumpscare()

func trigger_jumpscare():
	print("BOO! Jumpscare triggered.")
	
	# Disable player movement
	player.set_physics_process(false)
	self.set_physics_process(false)
	
	# Show jumpscare and loud sound
	var hud_face = player.get_node("HUD/FaceUI")
	hud_face.texture = hud_face.state_7
	await get_tree().create_timer(3).timeout
	
	# Resume player movement
	player.set_physics_process(true)
	
	#get_tree().reload_current_scene()
