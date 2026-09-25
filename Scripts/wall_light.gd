extends OmniLight3D

@export var min_energy = 0.2
@export var max_energy = 2.0


func _process(_delta):
	# Flicker effect
	if randf() > 0.95:
		light_energy = randf_range(min_energy, max_energy)
	else:
		# Slowly smooth back to normal glow
		light_energy = lerp(light_energy, 1.0, 0.2)
