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

	var tree := get_tree()
	var old_scene := tree.current_scene

	# Detach the player so it survives the old scene being freed
	var player := tree.get_first_node_in_group("player") as Node3D
	if player:
		player.get_parent().remove_child(player)

	# Swap scenes
	var new_scene = (load(scene_path) as PackedScene).instantiate()
	tree.root.add_child(new_scene)
	tree.current_scene = new_scene
	old_scene.queue_free()

	# Put the same player into the new scene
	if player:
		# Free any duplicate player the new scene ships with
		for p in tree.get_nodes_in_group("player"):
			p.queue_free()
		new_scene.add_child(player)

		var spawn := tree.get_first_node_in_group("player_spawn") as Node3D
		if spawn:
			player.global_position = spawn.global_position
			player.rotation.y = spawn.global_rotation.y
		else:
			push_warning("No player_spawn found in " + scene_path)

		player.velocity = Vector3.ZERO
		var cam := player.get_node_or_null("Head/Camera3D") as Camera3D
		if cam:
			cam.make_current()
		if player.has_method("on_scene_entered"):
			player.on_scene_entered()

	var tween_in = create_tween()
	tween_in.tween_property(fade_rect, "modulate:a", 0.0, fade_duration)
	await tween_in.finished

	is_transitioning = false
