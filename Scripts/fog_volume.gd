extends FogVolume


func _process(delta: float) -> void:
	# This moves the smoke texture slowly over time
	# Use 'material' to access the FogMaterial settings
	var mat = material as FogMaterial
	
	if mat and mat.density_texture:
		# We offset the texture to simulate drifting smoke
		# Adjust the Vector3 values to change direction (X, Y, Z)
		mat.edge_fade += 0 # Placeholder check
		
		var noise = mat.density_texture.noise
		noise.offset += Vector3(0.1, 0, 0.05) * delta
