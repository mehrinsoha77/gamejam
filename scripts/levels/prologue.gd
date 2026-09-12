class_name Prologue
extends LevelBase
## AWAKENING. Teaches: movement (1 DOF, forward only), interaction,
## atmosphere, mystery. HUD stays hidden until the player has read the
## first terminal, per the design doc ("HUD is initially disabled").

const ROOM_MAT := EnvironmentGenerator.COLOR_NEUTRAL_DARK

func _ready() -> void:
	super._ready()
	EnvironmentGenerator.setup_world_environment(
		self,
		Color(0.05, 0.06, 0.09), Color(0.1, 0.09, 0.12),
		Color(0.08, 0.09, 0.12), true
	)
	_build_geometry()
	_spawn_player_restricted()
	GameManager.save_checkpoint("res://levels/prologue.tscn", "start")
	set_objective("...")
	get_tree().create_timer(1.2).timeout.connect(_intro_transmission)

func _build_geometry() -> void:
	var wall_mat := EnvironmentGenerator.make_material(ROOM_MAT)
	var floor_mat := EnvironmentGenerator.make_material(EnvironmentGenerator.COLOR_NEUTRAL)

	# Chamber (spawn room) — sealed except the corridor exit (north).
	EnvironmentGenerator.create_room(self, Vector3(0, 0, 0), Vector3(4, 3, 4), wall_mat, floor_mat, wall_mat, ["north"], 2.4)
	EnvironmentGenerator.create_light(self, Vector3(0, 2.2, 0), Color(0.5, 0.55, 0.7), 0.6, 5.0)
	EnvironmentGenerator.create_dust_particles(self, Vector3(0, 1.5, 0))
	EnvironmentGenerator.create_debris(self, Vector3(1, 0, 1), 3)

	_terminal_node = Terminal.new()
	_terminal_node.name = "FirstTerminal"
	_terminal_node.lines = [
		"CONSTRAINT SYSTEM: ACTIVE.",
		"SUBJECT MOBILITY: 1 DEGREE OF FREEDOM.",
		"Proceed forward. Reverse translation is not yet authorized.",
	]
	_terminal_node.slow_time = true
	add_child(_terminal_node)
	_terminal_node.position = Vector3(0, 1.2, 1.8)

	# Corridor stretching north, forward-only.
	EnvironmentGenerator.create_corridor(self, Vector3(0, 0, 6), 2.4, 2.6, 8.0, wall_mat)
	EnvironmentGenerator.create_light(self, Vector3(0, 2.0, 4), Color(0.8, 0.3, 0.2), 0.5, 4.0)
	EnvironmentGenerator.create_light(self, Vector3(0, 2.0, 8), Color(0.8, 0.3, 0.2), 0.5, 4.0)

	# End trigger -> Level 1.
	var trigger := Area3D.new()
	trigger.name = "ExitTrigger"
	trigger.position = Vector3(0, 1.0, 9.2)
	trigger.set_collision_layer_value(1, false)
	trigger.set_collision_mask_value(2, true)
	var trigger_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.2, 2.4, 1.0)
	trigger_shape.shape = box
	trigger.add_child(trigger_shape)
	trigger.body_entered.connect(func(body):
		if body.is_in_group("player"):
			GameManager.goto_scene("res://levels/level_1.tscn")
	)
	add_child(trigger)

var _terminal_node: Terminal

func _spawn_player_restricted() -> void:
	spawn_player(Vector3(0, 0.1, -1.5), PI)
	hud.visible = false
	# The single Degree of Freedom the Prologue is named for: forward-only Z.
	player.freedom_component.unlock(FreedomComponent.DOF.TRANS_Z)
	player.forward_only = true

func _intro_transmission() -> void:
	DialogueManager.say("Mobility restriction detected.", "AI SYSTEM")
	DialogueManager.dialogue_finished.connect(_reveal_hud, CONNECT_ONE_SHOT)

func _reveal_hud() -> void:
	hud.visible = true
