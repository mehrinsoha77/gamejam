class_name Checkpoint
extends Interactable
## Autosave trigger. Place one at level start, after major puzzles, and
## before/after boss phases. Overlap-based (Area3D) so it fires
## automatically instead of requiring an [E] press — death should never
## cost the player more than a short walk back.

@export var spawn_id: String = "start"
@export var level_path: String = ""

@export var trigger_size: Vector3 = Vector3(2.4, 2.4, 2.0)

func _ready() -> void:
	super._ready()
	enabled = false # not an [E] interactable; triggers on body entry
	body_entered.connect(_on_body_entered)
	set_collision_mask_value(2, true) # detect the player body layer
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = trigger_size
	shape.shape = box
	add_child(shape)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	var path := level_path if level_path != "" else get_tree().current_scene.scene_file_path
	var pos := body.global_position
	GameManager.save_checkpoint(path, spawn_id, {"spawn_position": [pos.x, pos.y, pos.z]})
	AudioManager.play_sfx("checkpoint")
