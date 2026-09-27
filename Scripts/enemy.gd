extends CharacterBody3D

enum State { STATIC, IDLE, SEARCH, CHASE }

@export var current_state = State.STATIC
@export var chase_speed = 3.0
@export var rotation_speed = 5.0
@export var vision_range = 15.0
@export var hearing_sensitivity = 1.0 # How good the hearing of enemy

@onready var nav_agent = $NavigationAgent3D
@onready var player = get_tree().get_first_node_in_group("player")
@onready var visuals = $Visuals

var last_sound_pos = Vector3.ZERO


func _physics_process(delta: float) -> void:
	if !player: return
	
	check_hearing()
	
	match current_state:
		State.STATIC:
			# Only gaze at player
			handle_gaze(delta)
			check_for_panic()
		
		State.SEARCH:
			# Move to where the sound was heard
			nav_agent.target_position = last_sound_pos
			move_to_target(chase_speed * 0.5) # Move slower while searching
			
			if nav_agent.is_navigation_finished():
				current_state = State.IDLE # Or go back to STATIC
		
		State.CHASE:
			handle_gaze(delta)
			
			# Pathfinding Logic
			nav_agent.target_position = player.global_position
			move_to_target(chase_speed)

func check_hearing():
	var dist = global_position.distance_to(player.global_position)
	
	# Hearing Formula:
	# IF Player Noise > Distance (Adjusted by sensitivity)
	if player.current_noise_level > (dist / hearing_sensitivity):
		print("Enemy heard a noise at: ", player.global_position)
	
	# IF Enemy is IDLE, THEN SEARCH
	if current_state == State.STATIC or current_state == State.IDLE:
		current_state = State.SEARCH 

func move_to_target(speed):
	var next_pos = nav_agent.get_next_path_position()
	var dir = (next_pos - global_position).normalized()
	velocity = dir * speed
	move_and_slide()

func handle_gaze(delta):
	# Smoothly rotate the visuals to face the player
	var look_target = player.global_position
	look_target.y = global_position.y
	
	var target_dir = global_position.direction_to(look_target)
	var target_basis = Basis.looking_at(target_dir)
	visuals.basis = visuals.basis.slerp(target_basis, rotation_speed * delta)

func check_for_panic():
	# If player is looking at the static enemy, increase their insanity
	var dist = global_position.distance_to(player.global_position)
	if dist < 10.0:
		player.insanity_level += 0.1

func _on_kill_zone_body_entered(body):
	if body.is_in_group("player"):
		trigger_jumpscare()

func trigger_jumpscare():
	print("BOO! Jumpscare triggered.")
	# Here play animation and loud sound
