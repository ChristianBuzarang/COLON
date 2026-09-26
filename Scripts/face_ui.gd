extends TextureRect

@export var state_1 = preload("res://Sprites/Colon_Expressions/expression_state_1.png")
@export var state_2 = preload("res://Sprites/Colon_Expressions/expression_state_2.png")
@export var state_3 = preload("res://Sprites/Colon_Expressions/expression_state_3.png")
@export var state_4 = preload("res://Sprites/Colon_Expressions/expression_state_4.png")
@export var state_5 = preload("res://Sprites/Colon_Expressions/expression_state_5.png")
@export var state_6 = preload("res://Sprites/Colon_Expressions/expression_state_6.png")
@export var state_7 = preload("res://Sprites/Colon_Expressions/expression_state_7.png")

@onready var flashlight = get_node("../../Head/Camera3D/SpotLight3D")

var insanity_level = 0.0 # 0 to 100


func _process(delta: float) -> void:
	if flashlight == null: return
	
	if !flashlight.visible:
		insanity_level += delta * 2.0 # Ticks up in the dark
	else:
		insanity_level = move_toward(insanity_level, 0, delta * 1.0) # Slowly recovers
	
	if insanity_level > 70:
		var pulse = 1.0 + sin(Time.get_ticks_msec() * 0.01) * 0.05
		scale = Vector2(pulse, pulse)
		modulate = Color(1, 0.5, 0.5)
	else:
		scale = Vector2(1, 1)
		modulate = Color(1, 1, 1)
	
	update_face_texture()

func update_face_texture():
	if insanity_level < 15:
		texture = state_1
	elif insanity_level < 30:
		texture = state_2
	elif insanity_level < 43:
		texture = state_3
	elif insanity_level < 58:
		texture = state_4
		position += Vector2(randf_range(-2, 2), randf_range(-2, 2))
	elif insanity_level < 72:
		texture = state_5
		position += Vector2(randf_range(-5, 5), randf_range(-5, 5))
	elif insanity_level < 86:
		texture = state_6
		position += Vector2(randf_range(-8, 8), randf_range(-8, 8))
	else:
		texture = state_7
		position += Vector2(randf_range(-10, 10), randf_range(-10, 10))
