class_name FreedomCoreFragment
extends Interactable
## The recurring plot device: a shard of alien technology that hums with
## harvested freedom. Picking one up advances the story, awards points, and
## optionally plays a revelation-teaser line — the game never dumps the full
## truth in one box, so keep `reveal_lines` short (1-3 sentences).

signal collected

@export var reveal_lines: Array[String] = []
@export var freedom_points_reward: int = 25
@export var one_shot: bool = true

var _collected: bool = false

func _ready() -> void:
	super._ready()
	prompt_text = "TAKE FRAGMENT"
	var shape := CollisionShape3D.new()
	var sphere_shape := SphereShape3D.new()
	sphere_shape.radius = 0.6
	shape.shape = sphere_shape
	add_child(shape)
	var mesh_instance := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.25
	sphere.height = 0.5
	mesh_instance.mesh = sphere
	mesh_instance.material_override = EnvironmentGenerator.make_material(EnvironmentGenerator.COLOR_FREEDOM, EnvironmentGenerator.COLOR_FREEDOM, 2.5, 0.2)
	add_child(mesh_instance)
	var light := OmniLight3D.new()
	light.light_color = EnvironmentGenerator.COLOR_FREEDOM
	light.omni_range = 3.0
	light.light_energy = 1.0
	add_child(light)
	var tween := create_tween().set_loops()
	tween.tween_property(mesh_instance, "rotation:y", TAU, 4.0).from(0.0)

func can_interact(_player: Node) -> bool:
	return enabled and not (_collected and one_shot)

func interact(_player: Node) -> void:
	if not can_interact(_player):
		return
	_collected = true
	GameManager.add_freedom_points(freedom_points_reward)
	GameManager.score_exploration += freedom_points_reward
	AudioManager.play_sfx("scan_activate")
	if not reveal_lines.is_empty():
		var packaged: Array = []
		for line in reveal_lines:
			packaged.append({"speaker": "FRAGMENT RESONANCE", "text": line})
		DialogueManager.queue_lines(packaged, true)
	collected.emit()
	visible = false
	set_deferred("monitoring", false)
