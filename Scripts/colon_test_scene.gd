extends Node3D

func _ready() -> void:
	DialogueManager.start([
		{ "text": "Socializing in real life is so tiring… Having friends is so tiring…", "narration": true },
		{ "text": "It feels so fake! I hate talking about myself! I hate socializing! I hate going out!", "speaker": "Soph" },
		{ "text": "I just wanna stay home in peace, reading my books without anyone bothering me or pressuring about what they think is best for me!", "speaker": "Soph" },
	])
