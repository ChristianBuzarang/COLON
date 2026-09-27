extends Node

@export var fade_duration: float = 1.0
var fade_layer: CanvasLayer
var fade_rect: ColorRect
var is_transitioning: bool = false

func _ready() -> void:
	fade_layer = CanvasLayer.new()
	fade_layer.layer = 128
	fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.anchor_right = 1.0
	fade_rect.anchor_bottom = 1.0
	fade_rect.modulate.a = 0.0
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(fade_rect)
	get_tree().root.add_child.call_deferred(fade_layer)

func go_to_scene(scene_path: String) -> void:
	if is_transitioning:
		return
	is_transitioning = true

	var tween_out = create_tween()
	tween_out.tween_property(fade_rect, "modulate:a", 1.0, fade_duration)
	await tween_out.finished

	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame

	var tween_in = create_tween()
	tween_in.tween_property(fade_rect, "modulate:a", 0.0, fade_duration)
	await tween_in.finished

	is_transitioning = false
