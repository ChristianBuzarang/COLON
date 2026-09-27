extends Area3D

@export_file("*.tscn") var next_scene: String = "res://Scenes/colon_test_scene.tscn"
@export var one_shot: bool = true
@export var trigger_delay: float = 0.0

var _triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	if one_shot and _triggered:
		return
	_triggered = true

	if next_scene != "":
		if trigger_delay > 0.0:
			await get_tree().create_timer(trigger_delay).timeout
		SceneManager.go_to_scene(next_scene)
