extends Node3D

@onready var anim = $"AnimationPlayer"

var is_open = false


func toggle_door():
	if is_open: anim.play_backwards("open")
	else: anim.play("open")
	is_open = !is_open
