extends Node
## GameManager (autoload singleton)
## Owns cross-scene state: freedom points, permanently unlocked DOFs,
## current checkpoint, scene flow, and end-of-run scoring.
## Movement itself is still gated locally by the player's own FreedomComponent;
## this just remembers progress across level loads / checkpoint respawns.

signal freedom_points_changed(total: int)
signal dof_progression_unlocked(dof: int) # FreedomComponent.DOF value
signal objective_changed(text: String)

const SAVE_PATH := "user://checkpoint.save"

var freedom_points: int = 0
var permanently_unlocked_dof: Array = [] # FreedomComponent.DOF values already earned
var reverse_movement_unlocked: bool = false # Prologue-only teaching beat, see ARCHITECTURE.md

var current_level_path: String = ""
var checkpoint_data: Dictionary = {}

# Level-specific one-shot progress flags that must survive an in-level
# respawn (scene reload) without being reset like the transient node state.
var level1_puzzle_solved: bool = false
var level1_arena_cleared: bool = false

var debug_mode: bool = false

# --- Settings (persisted separately from checkpoints) ---
const SETTINGS_PATH := "user://settings.cfg"
var mouse_sensitivity: float = 0.002
var fov: float = 80.0
var head_bob_enabled: bool = true
var screen_shake_enabled: bool = true
var subtitles_enabled: bool = true
var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0
var fullscreen: bool = false
var vsync_enabled: bool = true

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("settings", "mouse_sensitivity", mouse_sensitivity)
	cfg.set_value("settings", "fov", fov)
	cfg.set_value("settings", "head_bob_enabled", head_bob_enabled)
	cfg.set_value("settings", "screen_shake_enabled", screen_shake_enabled)
	cfg.set_value("settings", "subtitles_enabled", subtitles_enabled)
	cfg.set_value("settings", "master_volume", master_volume)
	cfg.set_value("settings", "music_volume", music_volume)
	cfg.set_value("settings", "sfx_volume", sfx_volume)
	cfg.set_value("settings", "fullscreen", fullscreen)
	cfg.set_value("settings", "vsync_enabled", vsync_enabled)
	cfg.save(SETTINGS_PATH)

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		apply_settings()
		return
	mouse_sensitivity = cfg.get_value("settings", "mouse_sensitivity", mouse_sensitivity)
	fov = cfg.get_value("settings", "fov", fov)
	head_bob_enabled = cfg.get_value("settings", "head_bob_enabled", head_bob_enabled)
	screen_shake_enabled = cfg.get_value("settings", "screen_shake_enabled", screen_shake_enabled)
	subtitles_enabled = cfg.get_value("settings", "subtitles_enabled", subtitles_enabled)
	master_volume = cfg.get_value("settings", "master_volume", master_volume)
	music_volume = cfg.get_value("settings", "music_volume", music_volume)
	sfx_volume = cfg.get_value("settings", "sfx_volume", sfx_volume)
	fullscreen = cfg.get_value("settings", "fullscreen", fullscreen)
	vsync_enabled = cfg.get_value("settings", "vsync_enabled", vsync_enabled)
	apply_settings()

func apply_settings() -> void:
	AudioManager.apply_volume_settings(master_volume, music_volume, sfx_volume)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync_enabled else DisplayServer.VSYNC_DISABLED)

# Scoring components, tallied across a run.
var score_combat: int = 0
var score_puzzle: int = 0
var score_exploration: int = 0
var score_efficiency: int = 0
var score_freedom_management: int = 0
var score_optional_discoveries: int = 0

var enemies_defeated_nonlethally: int = 0
var research_logs_found: int = 0
var creatures_freed: int = 0

func _ready() -> void:
	debug_mode = OS.is_debug_build()
	load_settings()

func add_freedom_points(amount: int) -> void:
	freedom_points += amount
	freedom_points_changed.emit(freedom_points)

func unlock_dof_permanently(dof: int) -> void:
	if permanently_unlocked_dof.has(dof):
		return
	permanently_unlocked_dof.append(dof)
	dof_progression_unlocked.emit(dof)

func has_permanent_dof(dof: int) -> bool:
	return permanently_unlocked_dof.has(dof)

func set_objective(text: String) -> void:
	objective_changed.emit(text)

func start_new_game() -> void:
	freedom_points = 0
	permanently_unlocked_dof.clear()
	reverse_movement_unlocked = false
	score_combat = 0
	score_puzzle = 0
	score_exploration = 0
	score_efficiency = 0
	score_freedom_management = 0
	score_optional_discoveries = 0
	enemies_defeated_nonlethally = 0
	research_logs_found = 0
	creatures_freed = 0
	checkpoint_data.clear()
	level1_puzzle_solved = false
	level1_arena_cleared = false
	goto_scene("res://levels/prologue.tscn")

func goto_scene(path: String) -> void:
	current_level_path = path
	get_tree().call_deferred("change_scene_to_file", path)

func save_checkpoint(level_path: String, spawn_id: String, extra: Dictionary = {}) -> void:
	checkpoint_data = {
		"level_path": level_path,
		"spawn_id": spawn_id,
		"freedom_points": freedom_points,
		"permanently_unlocked_dof": permanently_unlocked_dof.duplicate(),
		"reverse_movement_unlocked": reverse_movement_unlocked,
		"extra": extra,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_var(checkpoint_data)
		f.close()

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func load_checkpoint() -> void:
	if not has_save():
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return
	var data = f.get_var()
	f.close()
	if typeof(data) != TYPE_DICTIONARY:
		return
	checkpoint_data = data
	freedom_points = data.get("freedom_points", 0)
	permanently_unlocked_dof = data.get("permanently_unlocked_dof", [])
	reverse_movement_unlocked = data.get("reverse_movement_unlocked", false)
	goto_scene(data.get("level_path", "res://levels/prologue.tscn"))

func respawn_at_checkpoint() -> void:
	if checkpoint_data.is_empty():
		goto_scene("res://levels/prologue.tscn")
	else:
		goto_scene(checkpoint_data.get("level_path", "res://levels/prologue.tscn"))

func compute_rank() -> String:
	var total := score_combat + score_puzzle + score_exploration + score_efficiency + score_freedom_management + score_optional_discoveries
	if total >= 500:
		return "S"
	elif total >= 350:
		return "A"
	elif total >= 200:
		return "B"
	return "C"

var pending_ending_title: String = ""
var pending_ending_body: String = ""

func show_ending(title: String, body: String) -> void:
	pending_ending_title = title
	pending_ending_body = body
	goto_scene("res://scenes/ending_screen.tscn")

func total_score() -> int:
	return score_combat + score_puzzle + score_exploration + score_efficiency + score_freedom_management + score_optional_discoveries
