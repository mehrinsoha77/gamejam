class_name Level1
extends LevelBase
## LEVEL 1 — THE STRAIGHT LINE. Theme: constraint. A single corridor spine
## (fittingly literal for a level about having almost no freedom) running
## START -> WEAPON -> TERMINAL/PUZZLE -> ALIEN ENCOUNTER -> RESEARCH ROOM ->
## FREEDOM CORE -> EXIT. See LEVEL_DESIGN.md for the full room-by-room spec
## this implements.
##
## Z layout (rooms and corridors abut exactly — no gaps in the floor):
## StartRoom [0,8] CorridorA [8,14] WeaponRoom [14,20] CorridorB [20,26]
## PuzzleRoom [26,40] CorridorC [40,46] ArenaRoom [46,60] CorridorD [60,66]
## ResearchRoom [66,80] CorridorE [80,86]. Forward is +Z (player spawns
## facing PI, see LevelBase.spawn_player).

## The Level 1 "challenge": a plain question/answer terminal (see
## scripts/ui/quiz_ui.gd + scripts/systems/quiz_terminal.gd). Add more
## questions here any time — each is {"question": ..., "answers": [one or
## more accepted strings, case/whitespace-insensitive]}.
const LEVEL1_QUIZ_QUESTIONS := [
	{
		"question": "What is the full form of BRS?",
		"answers": ["BUET Robotics Society"],
	},
]

var _puzzle_door: Door
var _arena_enemies_alive: int = 0
var _crawler_spawns := [Vector3(-3, 0.1, 51), Vector3(3, 0.1, 57)]

func _ready() -> void:
	super._ready()
	EnvironmentGenerator.setup_world_environment(
		self,
		Color(0.04, 0.05, 0.08), Color(0.12, 0.1, 0.14),
		Color(0.07, 0.08, 0.11), true
	)
	_build_start_zone()
	_build_weapon_zone()
	_build_puzzle_zone()
	_build_arena_zone()
	_build_research_zone()
	_build_exit_zone()
	_spawn_player()
	set_objective("FIND A WAY FORWARD.")

# ---------------------------------------------------------------- START ----
# StartRoom center z=4 (span 0-8), open north into CorridorA at z=8.
func _build_start_zone() -> void:
	var wall_mat := EnvironmentGenerator.make_material(EnvironmentGenerator.COLOR_NEUTRAL_DARK)
	var floor_mat := EnvironmentGenerator.make_material(EnvironmentGenerator.COLOR_NEUTRAL)
	EnvironmentGenerator.create_room(self, Vector3(0, 0, 4), Vector3(6, 3, 8), wall_mat, floor_mat, wall_mat, ["north"])
	EnvironmentGenerator.create_light(self, Vector3(0, 2.2, 4), Color(0.6, 0.65, 0.75), 0.9, 6.0)
	EnvironmentGenerator.create_dust_particles(self, Vector3(0, 1.6, 4))

	var checkpoint := Checkpoint.new()
	checkpoint.spawn_id = "level1_start"
	checkpoint.level_path = "res://levels/level_1.tscn"
	checkpoint.position = Vector3(0, 1.0, 2)
	add_child(checkpoint)

	# CorridorA center z=11 (span 8-14).
	EnvironmentGenerator.create_corridor(self, Vector3(0, 0, 11), 2.6, 2.6, 6.0, wall_mat)
	EnvironmentGenerator.create_light(self, Vector3(0, 2.0, 11), Color(0.7, 0.35, 0.2), 0.5, 4.0)

# --------------------------------------------------------------- WEAPON ----
# WeaponRoom center z=17 (span 14-20), open both ends.
func _build_weapon_zone() -> void:
	var wall_mat := EnvironmentGenerator.make_material(EnvironmentGenerator.COLOR_NEUTRAL_DARK)
	var floor_mat := EnvironmentGenerator.make_material(EnvironmentGenerator.COLOR_NEUTRAL)
	EnvironmentGenerator.create_room(self, Vector3(0, 0, 17), Vector3(6, 3, 6), wall_mat, floor_mat, wall_mat, ["north", "south"])
	EnvironmentGenerator.create_light(self, Vector3(0, 2.2, 17), Color(0.3, 0.7, 1.0), 1.0, 6.0)
	EnvironmentGenerator.create_pipe(self, Vector3(-2.9, 2.6, 14.5), Vector3(-2.9, 2.6, 19.5), 0.08)

	var rack := WeaponPickup.new()
	rack.weapon_script = load("res://scripts/weapons/energy_weapon.gd")
	rack.pickup_label = "ENERGY WEAPON"
	rack.position = Vector3(-2.4, 1.2, 17)
	add_child(rack)
	rack.collected.connect(func(): set_objective("PROCEED. SOMETHING IS ALIVE DOWN HERE."))

	# CorridorB center z=23 (span 20-26).
	EnvironmentGenerator.create_corridor(self, Vector3(0, 0, 23), 2.6, 2.6, 6.0, wall_mat)
	EnvironmentGenerator.create_dust_particles(self, Vector3(0, 1.6, 23))

# --------------------------------------------------------------- PUZZLE ----
# PuzzleRoom center z=33 (span 26-40), open both ends; north exit gated by
# _puzzle_door until the access quiz is answered correctly.
func _build_puzzle_zone() -> void:
	var wall_mat := EnvironmentGenerator.make_material(EnvironmentGenerator.COLOR_NEUTRAL_DARK)
	var floor_mat := EnvironmentGenerator.make_material(EnvironmentGenerator.COLOR_NEUTRAL)
	EnvironmentGenerator.create_room(self, Vector3(0, 0, 33), Vector3(7, 3, 14), wall_mat, floor_mat, wall_mat, ["north", "south"])
	EnvironmentGenerator.create_light(self, Vector3(0, 2.2, 28), Color(0.6, 0.65, 0.75), 0.9, 6.0)
	EnvironmentGenerator.create_light(self, Vector3(0, 2.2, 38), Color(0.6, 0.65, 0.75), 0.9, 6.0)
	EnvironmentGenerator.create_alien_growth(self, Vector3(3.2, 0.2, 29))

	var quiz := QuizTerminal.new()
	quiz.name = "AccessQuiz"
	quiz.questions = LEVEL1_QUIZ_QUESTIONS
	quiz.position = Vector3(0, 1.3, 30)
	add_child(quiz)
	quiz.solved.connect(_on_puzzle_solved)

	_puzzle_door = Door.new()
	_puzzle_door.name = "PuzzleDoor"
	_puzzle_door.locked = true
	_puzzle_door.position = Vector3(0, 1.3, 40)
	add_child(_puzzle_door)

	var post_puzzle_checkpoint := Checkpoint.new()
	post_puzzle_checkpoint.spawn_id = "post_puzzle"
	post_puzzle_checkpoint.level_path = "res://levels/level_1.tscn"
	post_puzzle_checkpoint.position = Vector3(0, 1.0, 41)
	add_child(post_puzzle_checkpoint)

	# CorridorC center z=43 (span 40-46).
	EnvironmentGenerator.create_corridor(self, Vector3(0, 0, 43), 2.6, 2.6, 6.0, wall_mat)

	if GameManager.level1_puzzle_solved:
		quiz._solved = true
		_puzzle_door.locked = false
		_puzzle_door.open()

func _on_puzzle_solved() -> void:
	GameManager.level1_puzzle_solved = true
	GameManager.reverse_movement_unlocked = true
	player.forward_only = false
	player.unlock_dof_with_presentation(
		[FreedomComponent.DOF.TRANS_X, FreedomComponent.DOF.TRANS_Z],
		hud, "GROUND-PLANE TRANSLATION"
	)
	DialogueManager.say("Access verified. Full lateral translation granted.", "AI SYSTEM")
	_puzzle_door.force_unlock_and_open()
	set_objective("KEEP MOVING. THE PATH IS OPEN NOW.")

# ---------------------------------------------------------------- ARENA ----
# ArenaRoom center z=53 (span 46-60), open both ends.
func _build_arena_zone() -> void:
	var wall_mat := EnvironmentGenerator.make_material(EnvironmentGenerator.COLOR_NEUTRAL_DARK)
	var floor_mat := EnvironmentGenerator.make_material(EnvironmentGenerator.COLOR_NEUTRAL)
	EnvironmentGenerator.create_room(self, Vector3(0, 0, 53), Vector3(12, 3.4, 14), wall_mat, floor_mat, wall_mat, ["north", "south"])
	EnvironmentGenerator.create_light(self, Vector3(-3, 2.6, 49), EnvironmentGenerator.COLOR_DANGER, 1.1, 6.0)
	EnvironmentGenerator.create_light(self, Vector3(3, 2.6, 57), EnvironmentGenerator.COLOR_DANGER, 1.1, 6.0)
	EnvironmentGenerator.create_debris(self, Vector3(-3, 0, 53), 5, Vector3(1.5, 0, 1.5))
	EnvironmentGenerator.create_debris(self, Vector3(3, 0, 51), 5, Vector3(1.5, 0, 1.5))

	var arena_trigger := Area3D.new()
	arena_trigger.set_collision_layer_value(1, false)
	arena_trigger.set_collision_mask_value(2, true)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3, 3, 1.0)
	shape.shape = box
	arena_trigger.add_child(shape)
	arena_trigger.position = Vector3(0, 1.0, 47.5)
	if not GameManager.level1_arena_cleared:
		arena_trigger.body_entered.connect(_on_arena_entered, CONNECT_ONE_SHOT)
	add_child(arena_trigger)

	var post_arena_checkpoint := Checkpoint.new()
	post_arena_checkpoint.spawn_id = "post_arena"
	post_arena_checkpoint.level_path = "res://levels/level_1.tscn"
	post_arena_checkpoint.position = Vector3(0, 1.0, 59)
	add_child(post_arena_checkpoint)

	# CorridorD center z=63 (span 60-66).
	EnvironmentGenerator.create_corridor(self, Vector3(0, 0, 63), 2.6, 2.6, 6.0, wall_mat)

func _on_arena_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	set_objective("SURVIVE.")
	AudioManager.set_music_state(AudioManager.MusicState.COMBAT)
	_arena_enemies_alive = _crawler_spawns.size()
	for pos in _crawler_spawns:
		var crawler := Crawler.new()
		crawler.position = pos
		add_child(crawler)
		crawler.died.connect(_on_arena_enemy_died)

func _on_arena_enemy_died(_enemy: EnemyBase) -> void:
	_arena_enemies_alive -= 1
	if _arena_enemies_alive <= 0:
		GameManager.level1_arena_cleared = true
		set_objective("THE RESEARCH WING IS AHEAD.")
		AudioManager.set_music_state(AudioManager.MusicState.EXPLORATION)

# ------------------------------------------------------------- RESEARCH ----
# ResearchRoom center z=73 (span 66-80), open both ends.
func _build_research_zone() -> void:
	var wall_mat := EnvironmentGenerator.make_material(EnvironmentGenerator.COLOR_NEUTRAL_DARK)
	var floor_mat := EnvironmentGenerator.make_material(EnvironmentGenerator.COLOR_NEUTRAL)
	# Note: no "window" opening — a gap wide enough to see a distant planet
	# through is also wide enough to walk into the void beyond (no floor out
	# there). A proper glass-paned window is a follow-up art pass; see
	# ASSETS_NEEDED.md. Room stays fully enclosed for now.
	EnvironmentGenerator.create_room(self, Vector3(0, 0, 73), Vector3(9, 3.2, 14), wall_mat, floor_mat, wall_mat, ["north", "south"])
	EnvironmentGenerator.create_light(self, Vector3(0, 2.4, 73), EnvironmentGenerator.COLOR_FREEDOM, 1.0, 8.0)

	var log_prop := ResearchLog.new()
	log_prop.log_title = "FACILITY LOG 04"
	log_prop.log_lines = [
		"Subjects are not chosen. They are found already here.",
		"The Core does not create freedom. It only moves it.",
	]
	log_prop.position = Vector3(-3.2, 1.1, 69)
	add_child(log_prop)

	var manipulator_pickup := WeaponPickup.new()
	manipulator_pickup.weapon_script = load("res://scripts/weapons/freedom_manipulator.gd")
	manipulator_pickup.pickup_label = "THE VECTOR"
	manipulator_pickup.position = Vector3(3.2, 1.1, 69)
	add_child(manipulator_pickup)
	manipulator_pickup.collected.connect(func():
		DialogueManager.say("Unregistered device bonded. Scan mode available.", "AI SYSTEM")
	)

	var platform_body := StaticBody3D.new()
	platform_body.set_collision_layer_value(1, true)
	platform_body.position = Vector3(3.2, 0.1, 76)
	add_child(platform_body)
	var platform_shape := CollisionShape3D.new()
	var platform_box := BoxShape3D.new()
	platform_box.size = Vector3(2.0, 0.2, 2.0)
	platform_shape.shape = platform_box
	platform_body.add_child(platform_shape)
	var platform_mesh := MeshInstance3D.new()
	var pm_box := BoxMesh.new()
	pm_box.size = Vector3(2.0, 0.2, 2.0)
	platform_mesh.mesh = pm_box
	platform_mesh.material_override = EnvironmentGenerator.make_material(EnvironmentGenerator.COLOR_INTERACTIVE)
	platform_body.add_child(platform_mesh)

	var elevator_panel := ElevatorPlatform.new()
	elevator_panel.top_y = 4.5
	elevator_panel.position = Vector3(2.2, 1.0, 76)
	add_child(elevator_panel)
	elevator_panel.set_platform_mesh(platform_body)

	var fragment := FreedomCoreFragment.new()
	fragment.position = Vector3(0, 1.4, 78)
	fragment.reveal_lines = [
		"...the facility was not built to study movement.",
		"It was built to study freedom itself.",
	]
	add_child(fragment)
	fragment.collected.connect(func():
		set_objective("FIND THE EXIT.")
	)

	# CorridorE center z=83 (span 80-86).
	EnvironmentGenerator.create_corridor(self, Vector3(0, 0, 83), 2.6, 2.6, 6.0, wall_mat)

# ------------------------------------------------------------------ EXIT ----
func _build_exit_zone() -> void:
	var trigger := Area3D.new()
	trigger.position = Vector3(0, 1.0, 85)
	trigger.set_collision_layer_value(1, false)
	trigger.set_collision_mask_value(2, true)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.2, 2.4, 1.0)
	shape.shape = box
	trigger.add_child(shape)
	trigger.body_entered.connect(func(body):
		if body.is_in_group("player"):
			GameManager.show_ending(
				"END OF VERTICAL SLICE",
				"You've played the Prologue and Level 1 — THE STRAIGHT LINE. Levels 2-5, the Final Act and all four endings are designed in LEVEL_DESIGN.md, ready for the next development pass."
			)
	)
	add_child(trigger)

# ---------------------------------------------------------------- SPAWN ----
func _spawn_player() -> void:
	var spawn_pos := Vector3(0, 0.1, 1.0)
	var cp: Dictionary = GameManager.checkpoint_data
	if cp.get("level_path", "") == "res://levels/level_1.tscn" and cp.has("extra") and cp["extra"].has("spawn_position"):
		var arr: Array = cp["extra"]["spawn_position"]
		spawn_pos = Vector3(arr[0], arr[1], arr[2])
	spawn_player(spawn_pos, PI)
	player.freedom_component.unlock(FreedomComponent.DOF.TRANS_Z)
	player.forward_only = not GameManager.reverse_movement_unlocked
	if not player.forward_only:
		player.freedom_component.unlock(FreedomComponent.DOF.TRANS_X)
	if spawn_pos == Vector3(0, 0.1, 1.0):
		GameManager.save_checkpoint("res://levels/level_1.tscn", "level1_start")
