# PS. I only added this for testing, can be removed later --vb

extends Camera3D

# For the SHake effect
var shake_decay: float = 5.0
var trauma: float = 0.0
var trauma_power: int = 2
var noise := FastNoiseLite.new()
var noise_i: float = 0.0

@export var max_offset: Vector3 = Vector3(0.2, 0.2, 0)
@export var max_rotation: Vector3 = Vector3(0, 0, 0.1)

var _base_position: Vector3
var _base_rotation: Vector3

var _base_fov: float
var fov_punch_active: bool = false

func _ready() -> void:
	_base_position = position
	_base_rotation = rotation
	_base_fov = fov
	noise.seed = randi()
	noise.frequency = 4.0

func _process(delta: float) -> void:
	_process_shake(delta)

func _process_shake(delta: float) -> void:
	if trauma > 0.0:
		trauma = max(trauma - shake_decay * delta, 0.0)
		var shake_strength = pow(trauma, trauma_power)

		noise_i += delta * 20.0
		var offset_x = max_offset.x * shake_strength * noise.get_noise_2d(noise_i, 0)
		var offset_y = max_offset.y * shake_strength * noise.get_noise_2d(noise_i, 100)
		var rot_z = max_rotation.z * shake_strength * noise.get_noise_2d(noise_i, 200)

		position = _base_position + Vector3(offset_x, offset_y, 0)
		rotation = _base_rotation + Vector3(0, 0, rot_z)
	else:
		position = _base_position
		rotation = _base_rotation

func add_trauma(amount: float) -> void:
	trauma = clamp(trauma + amount, 0.0, 1.0)

func fov_kick(target_fov: float, duration: float) -> void:
	var tween = create_tween()
	tween.tween_property(self, "fov", target_fov, duration * 0.3)
	tween.tween_property(self, "fov", _base_fov, duration * 0.7)
