extends Area3D

@export var one_shot: bool = true
var _triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	if one_shot and _triggered:
		return
	_triggered = true

	DialogueManager.start([
		{ "text": "Socializing in real life is so tiring… Having friends is so tiring…", "narration": true },
		{ "text": "It feels so fake! I hate talking about myself! I hate socializing! I hate going out!", "speaker": "Soph" },
		{ "text": "I just wanna stay home in peace, reading my books without anyone bothering me or pressuring about what they think is best for me!", "speaker": "Soph" },
	])
