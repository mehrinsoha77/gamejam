class_name FreedomManipulator
extends WeaponBase
## THE VECTOR. The signature mechanic: SCAN continuously, then act on the
## scanned object in one of six modes cycled with [Q]:
##   TAKE      – give one of its free DOFs directly to the player
##   RETURN    – give back a DOF this device previously took (from the
##               player or from its own internal buffer)
##   STORE     – pull a free DOF into the device's small buffer, unassigned
##   TRANSFER  – push a buffered DOF into whatever is scanned next
##   LOCK      – forcibly disable one of its free DOFs (non-lethal crowd control)
##   RESTORE   – undo a LOCK/steal on whatever is scanned (the "mercy" action)

enum Mode { TAKE, STORE, TRANSFER, RETURN, LOCK, RESTORE }
const MODE_NAMES := {
	Mode.TAKE: "TAKE", Mode.STORE: "STORE", Mode.TRANSFER: "TRANSFER",
	Mode.RETURN: "RETURN", Mode.LOCK: "LOCK", Mode.RESTORE: "RESTORE",
}
const BUFFER_CAPACITY := 3

var mode: int = Mode.TAKE
var buffer: Array = [] # [{dof:int, source:FreedomComponent}]

var scan_panel: ScanPanel
var _scanned: FreedomComponent = null
var _scanned_name: String = "OBJECT"

func _init() -> void:
	weapon_name = "THE VECTOR"
	fire_cooldown = 0.3
	range_meters = 12.0

func equip(player: Node) -> void:
	super.equip(player)

func set_scan_panel(panel: ScanPanel) -> void:
	scan_panel = panel

func _process(delta: float) -> void:
	super._process(delta)
	if owner_player == null:
		return
	if owner_player.weapon_system.current_weapon() != self:
		if scan_panel:
			scan_panel.hide_scan()
		_scanned = null
		return
	_update_scan()

func _update_scan() -> void:
	var interaction := _get_interaction()
	if interaction == null:
		return
	var result := interaction.raycast_any(range_meters)
	var collider = result.get("collider") if not result.is_empty() else null
	if collider and collider.has_node("FreedomComponent"):
		_scanned = collider.get_node("FreedomComponent")
		_scanned_name = collider.get_node("FreedomComponent").display_name
		if scan_panel:
			scan_panel.show_scan(_scanned_name, _scanned, MODE_NAMES[mode])
	else:
		_scanned = null
		if scan_panel:
			scan_panel.hide_scan()

func cycle_mode() -> void:
	mode = (mode + 1) % Mode.size()
	AudioManager.play_sfx("ui_click")

func primary_fire() -> void:
	if not can_fire() or _scanned == null:
		return
	var player_fc: FreedomComponent = owner_player.get_node("FreedomComponent") if owner_player.has_node("FreedomComponent") else null
	match mode:
		Mode.TAKE:
			_do_take(player_fc)
		Mode.STORE:
			_do_store()
		Mode.TRANSFER:
			_do_transfer()
		Mode.RETURN:
			_do_return(player_fc)
		Mode.LOCK:
			_do_lock()
		Mode.RESTORE:
			_do_restore()

func secondary_fire() -> void:
	cycle_mode()

func _do_take(player_fc: FreedomComponent) -> void:
	if player_fc == null:
		return
	var dof = _scanned.first_free_dof()
	if dof == null:
		return
	if _scanned.give_to(dof, player_fc):
		_start_cooldown()
		AudioManager.play_sfx("freedom_take")
		GameManager.score_freedom_management += 10

func _do_store() -> void:
	if buffer.size() >= BUFFER_CAPACITY:
		return
	var dof = _scanned.first_free_dof()
	if dof == null:
		return
	if _scanned.hold_for_device(dof):
		buffer.append({"dof": dof, "source": _scanned})
		_start_cooldown()
		AudioManager.play_sfx("freedom_take")

func _do_transfer() -> void:
	if buffer.is_empty():
		return
	var entry: Dictionary = buffer[0]
	var dof: int = entry.dof
	if not _scanned.is_relevant(dof):
		return
	if not _scanned.is_free(dof):
		_scanned.unlock(dof)
		buffer.pop_front()
		_start_cooldown()
		AudioManager.play_sfx("freedom_transfer")
		GameManager.score_freedom_management += 10

func _do_return(player_fc: FreedomComponent) -> void:
	# Case 1: undo a buffered STORE still sitting in the device.
	for i in range(buffer.size()):
		var entry: Dictionary = buffer[i]
		if entry.source == _scanned:
			_scanned.release_from_device(entry.dof)
			buffer.remove_at(i)
			_start_cooldown()
			AudioManager.play_sfx("freedom_transfer")
			return
	# Case 2: undo a direct TAKE the player is currently holding.
	if player_fc == null:
		return
	for dof in _scanned.relevant_dof:
		if _scanned.is_held_by(dof, player_fc):
			_scanned.reclaim(dof)
			_start_cooldown()
			AudioManager.play_sfx("freedom_transfer")
			return

func _do_lock() -> void:
	var dof = _scanned.first_lockable_dof()
	if dof == null:
		return
	_scanned.force_lock(dof)
	_start_cooldown()
	AudioManager.play_sfx("weapon_vector_fire")

func _do_restore() -> void:
	var dof = _scanned.first_restorable_dof()
	if dof == null:
		return
	_scanned.force_unlock(dof)
	_start_cooldown()
	AudioManager.play_sfx("freedom_transfer")
	GameManager.creatures_freed += 1
