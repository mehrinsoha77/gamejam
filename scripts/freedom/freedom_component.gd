class_name FreedomComponent
extends Node
## Centralized Degree-of-Freedom state for ANY object in the game:
## the player, an elevator, a drone, a door, a boss.
## This is the single source of truth for "what can this thing do."
## Never scatter DOF booleans across gameplay scripts — read/write them here.

enum DOF { TRANS_X, TRANS_Y, TRANS_Z, ROT_PITCH, ROT_YAW, ROT_ROLL }

enum DOFState {
	LOCKED,      ## never had this freedom
	UNLOCKED,    ## permanently free to use
	TEMPORARY,   ## free for a limited time (buffs, puzzle windows)
	DISABLED,    ## administratively turned off (anchor fields, story gates)
	STOLEN,      ## taken by an enemy/hazard; recoverable
	TRANSFERRED, ## given away to another FreedomComponent via the Vector
}

const DOF_NAMES := {
	DOF.TRANS_X: "X TRANSLATION",
	DOF.TRANS_Y: "Y TRANSLATION",
	DOF.TRANS_Z: "Z TRANSLATION",
	DOF.ROT_PITCH: "PITCH",
	DOF.ROT_YAW: "YAW",
	DOF.ROT_ROLL: "ROLL",
}

## Identifies the owner in scan UIs, e.g. "SECURITY DRONE".
@export var display_name: String = "OBJECT"

## Which DOFs this object is even capable of being scanned/manipulated for.
## e.g. a wall-mounted door only ever has TRANS_Y (slides up) — everything else
## stays permanently LOCKED and hidden from the scan readout as "n/a".
@export var relevant_dof: Array[DOF] = [DOF.TRANS_X, DOF.TRANS_Y, DOF.TRANS_Z, DOF.ROT_PITCH, DOF.ROT_YAW, DOF.ROT_ROLL]

signal dof_state_changed(dof: DOF, new_state: DOFState, old_state: DOFState)
signal dof_unlocked(dof: DOF)

var _states: Dictionary = {}
## Remembers what a STOLEN/TRANSFERRED dof was before, so RETURN/RESTORE works.
var _previous_state: Dictionary = {}
## Which other FreedomComponent currently holds a TRANSFERRED dof taken from us.
var _taken_by: Dictionary = {}

func _ready() -> void:
	for dof in DOF.values():
		_states[dof] = DOFState.LOCKED

func get_state(dof: DOF) -> DOFState:
	return _states.get(dof, DOFState.LOCKED)

func is_free(dof: DOF) -> bool:
	var s := get_state(dof)
	return s == DOFState.UNLOCKED or s == DOFState.TEMPORARY

func is_relevant(dof: DOF) -> bool:
	return relevant_dof.has(dof)

func set_state(dof: DOF, new_state: DOFState) -> void:
	var old := _states.get(dof, DOFState.LOCKED)
	if old == new_state:
		return
	_states[dof] = new_state
	dof_state_changed.emit(dof, new_state, old)
	if new_state == DOFState.UNLOCKED and old == DOFState.LOCKED:
		dof_unlocked.emit(dof)

func unlock(dof: DOF) -> void:
	set_state(dof, DOFState.UNLOCKED)

func lock(dof: DOF) -> void:
	set_state(dof, DOFState.LOCKED)

## Enemy/hazard takes a DOF away temporarily. Call restore_stolen() to give it back.
func steal(dof: DOF) -> void:
	if get_state(dof) == DOFState.STOLEN:
		return
	_previous_state[dof] = get_state(dof)
	set_state(dof, DOFState.STOLEN)

func restore_stolen(dof: DOF) -> void:
	if get_state(dof) != DOFState.STOLEN:
		return
	set_state(dof, _previous_state.get(dof, DOFState.UNLOCKED))

## The Vector's TAKE operation: this component gives `dof` to `receiver`.
func give_to(dof: DOF, receiver: FreedomComponent) -> bool:
	if not is_free(dof):
		return false
	_previous_state[dof] = get_state(dof)
	set_state(dof, DOFState.TRANSFERRED)
	_taken_by[dof] = receiver
	receiver.unlock(dof)
	return true

## The Vector's RETURN operation: undoes a previous give_to().
func reclaim(dof: DOF) -> bool:
	if get_state(dof) != DOFState.TRANSFERRED:
		return false
	var receiver: FreedomComponent = _taken_by.get(dof)
	if receiver:
		receiver.lock(dof)
	set_state(dof, _previous_state.get(dof, DOFState.UNLOCKED))
	_taken_by.erase(dof)
	return true

## True if `dof` was TAKEn from us and is currently held by `fc`.
func is_held_by(dof: DOF, fc: FreedomComponent) -> bool:
	return get_state(dof) == DOFState.TRANSFERRED and _taken_by.get(dof) == fc

## Device-mediated STORE: pull a dof into the Freedom Manipulator's buffer
## (no direct receiver yet — see release_from_device()/TRANSFER).
func hold_for_device(dof: DOF) -> bool:
	if not is_free(dof):
		return false
	_previous_state[dof] = get_state(dof)
	set_state(dof, DOFState.TRANSFERRED)
	_taken_by.erase(dof)
	return true

## Undoes hold_for_device() — gives the dof back to its original owner.
func release_from_device(dof: DOF) -> void:
	if get_state(dof) != DOFState.TRANSFERRED:
		return
	set_state(dof, _previous_state.get(dof, DOFState.UNLOCKED))

## Manual LOCK/RESTORE (Freedom Manipulator's combat-agnostic version of
## steal()/restore_stolen() — same memory semantics, distinct naming so
## call sites read clearly).
func force_lock(dof: DOF) -> void:
	steal(dof)

func force_unlock(dof: DOF) -> void:
	restore_stolen(dof)

func first_free_dof() -> Variant:
	for dof in relevant_dof:
		if is_free(dof):
			return dof
	return null

func first_lockable_dof() -> Variant:
	return first_free_dof()

func first_restorable_dof() -> Variant:
	for dof in relevant_dof:
		var s := get_state(dof)
		if s == DOFState.STOLEN or s == DOFState.DISABLED:
			return dof
	return null

## Snapshot used by scan UIs: DOF -> bool (only for relevant_dof entries).
func get_scan_profile() -> Dictionary:
	var profile := {}
	for dof in relevant_dof:
		profile[dof] = is_free(dof)
	return profile

func get_free_dofs() -> Array[DOF]:
	var out: Array[DOF] = []
	for dof in relevant_dof:
		if is_free(dof):
			out.append(dof)
	return out
