class_name LevelBase
extends Node3D
## Shared plumbing for every level scene: player spawning, HUD binding,
## pause menu, and a couple of small helpers. Level scripts (Prologue,
## Level1, ...) extend this and build their own geometry in _ready()
## after calling super._ready().

var hud: HUD
var player: Player

func _ready() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func spawn_player(spawn_position: Vector3, spawn_basis_y_rotation: float = 0.0) -> Player:
	player = Player.new()
	player.name = "Player"
	add_child(player)
	player.global_position = spawn_position
	player.rotation.y = spawn_basis_y_rotation
	hud = HUD.new()
	add_child(hud)
	hud.bind_player(player)
	return player

func set_objective(text: String) -> void:
	GameManager.set_objective(text)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not DialogueManager.is_active() and not get_tree().paused:
		add_child(PauseMenu.new())
		get_viewport().set_input_as_handled()
