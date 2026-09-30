extends Node

signal line_started(line_data: Dictionary)
signal line_finished(line_data: Dictionary)
signal dialogue_finished

var canvas_layer: CanvasLayer
var box: Panel
var speaker_label: Label
var text_label: RichTextLabel
var portrait_rect: TextureRect

var _queue: Array = []
var _current_line: Dictionary = {}
var _typing: bool = false
var _char_index: int = 0
var _type_speed: float = 0.02  # seconds per character
var _timer: float = 0.0
var is_active: bool = false

func _ready() -> void:
	_build_ui()
	set_process(false)

func _build_ui() -> void:
	canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 80
	canvas_layer.visible = false

	box = Panel.new()
	box.anchor_left = 0.05
	box.anchor_right = 0.95
	box.anchor_top = 0.75
	box.anchor_bottom = 0.95
	canvas_layer.add_child(box)

	portrait_rect = TextureRect.new()
	portrait_rect.anchor_left = 0.0
	portrait_rect.anchor_right = 0.0
	portrait_rect.anchor_top = 0.0
	portrait_rect.anchor_bottom = 1.0
	portrait_rect.custom_minimum_size = Vector2(120, 0)
	portrait_rect.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
	portrait_rect.visible = false
	box.add_child(portrait_rect)

	speaker_label = Label.new()
	speaker_label.anchor_left = 0.03
	speaker_label.anchor_right = 0.5
	speaker_label.anchor_top = 0.02
	speaker_label.add_theme_font_size_override("font_size", 18)
	box.add_child(speaker_label)

	text_label = RichTextLabel.new()
	text_label.anchor_left = 0.03
	text_label.anchor_right = 0.97
	text_label.anchor_top = 0.22
	text_label.anchor_bottom = 0.95
	text_label.bbcode_enabled = true
	text_label.scroll_active = false
	text_label.add_theme_font_size_override("normal_font_size", 20)
	box.add_child(text_label)

	get_tree().root.add_child.call_deferred(canvas_layer)

func start(lines: Array) -> void:
	_queue = lines.duplicate()
	is_active = true
	canvas_layer.visible = true
	set_process(true)
	_advance()

func _advance() -> void:
	if _queue.is_empty():
		_end_dialogue()
		return

	_current_line = _queue.pop_front()
	line_started.emit(_current_line)

	var speaker = _current_line.get("speaker", "")
	var is_narration = _current_line.get("narration", false)
	var portrait = _current_line.get("portrait", null)

	speaker_label.text = speaker
	speaker_label.visible = speaker != ""

	if portrait != null:
		portrait_rect.texture = load(portrait)
		portrait_rect.visible = true
	else:
		portrait_rect.visible = false

	var raw_text: String = _current_line.get("text", "")
	if is_narration:
		raw_text = "[i]" + raw_text + "[/i]"

	text_label.text = ""
	_char_index = 0
	_typing = true
	_timer = 0.0
	_full_text = raw_text

func _full_text_setter(_v):
	pass

var _full_text: String = ""

func _process(delta: float) -> void:
	if not _typing:
		return
	_timer += delta
	if _timer >= _type_speed:
		_timer = 0.0
		_char_index += 1
		text_label.text = _full_text.substr(0, _char_index)
		if _char_index >= _full_text.length():
			_typing = false
			line_finished.emit(_current_line)

func advance_or_skip() -> void:
	if not is_active:
		return
	if _typing:
		# Skip typewriter, show full line instantly
		_typing = false
		_char_index = _full_text.length()
		text_label.text = _full_text
		line_finished.emit(_current_line)
	else:
		_advance()

func _end_dialogue() -> void:
	is_active = false
	canvas_layer.visible = false
	set_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	dialogue_finished.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return
	if (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE) \
	or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		advance_or_skip()
		get_viewport().set_input_as_handled()
