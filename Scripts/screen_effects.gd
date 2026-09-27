extends Node

var overlay: ColorRect
var canvas_layer: CanvasLayer

func _ready() -> void:
	canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	overlay = ColorRect.new()
	overlay.color = Color(1, 0, 0, 0.0)  # red, fully transparent by default
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas_layer.add_child(overlay)
	get_tree().root.add_child.call_deferred(canvas_layer)

# Red flasb - taking damage in case naa pod tay health bar
func flash_red(peak_alpha: float = 0.5, fade_time: float = 0.6) -> void:
	overlay.color.a = peak_alpha
	var tween = create_tween()
	tween.tween_property(overlay, "color:a", 0.0, fade_time)

# Persistent pulsing red vignette - low health state
func start_pulse(min_alpha: float = 0.0, max_alpha: float = 0.3, pulse_time: float = 1.5) -> void:
	var tween = create_tween().set_loops()
	tween.tween_property(overlay, "color:a", max_alpha, pulse_time).set_trans(Tween.TRANS_SINE)
	tween.tween_property(overlay, "color:a", min_alpha, pulse_time).set_trans(Tween.TRANS_SINE)

func stop_pulse() -> void:
	var tween = create_tween()
	tween.tween_property(overlay, "color:a", 0.0, 0.5)
