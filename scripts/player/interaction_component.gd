class_name InteractionComponent
extends Node
## Casts a short ray from the camera each frame to find the interactable the
## player is looking at, exposes it to the HUD for the prompt, and forwards
## the [E] press. Also exposes the same raycast result to weapons/manipulator
## so "what am I looking at" logic lives in exactly one place.

@export var interact_range: float = 3.0

var camera: Camera3D
var current_target: Interactable = null

signal target_changed(target: Interactable)

func _ready() -> void:
	set_physics_process(true)

func setup(cam: Camera3D) -> void:
	camera = cam

func _physics_process(_delta: float) -> void:
	if camera == null:
		return
	var new_target := _raycast_interactable()
	if new_target != current_target:
		current_target = new_target
		target_changed.emit(current_target)

func _raycast_interactable() -> Interactable:
	var space_state := camera.get_world_3d().direct_space_state
	var from := camera.global_position
	var to := from - camera.global_transform.basis.z * interact_range
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1 << 2 # layer 3
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var result := space_state.intersect_ray(query)
	if result.is_empty():
		return null
	var collider = result.get("collider")
	if collider is Interactable and collider.can_interact(null):
		return collider
	return null

## Generic raycast for combat weapons (hits solid bodies only, ignores areas
## so a Terminal/Door trigger volume never intercepts an Energy Weapon shot).
func raycast_body(range_override: float = -1.0) -> Dictionary:
	return _raycast(range_override, true, false)

## Raycast for the Freedom Manipulator: it needs to scan BOTH enemy bodies
## and Area3D-based interactables (doors, elevators...) since those are how
## Interactable props are implemented, so this includes areas too.
func raycast_any(range_override: float = -1.0) -> Dictionary:
	return _raycast(range_override, true, true)

func _raycast(range_override: float, with_bodies: bool, with_areas: bool) -> Dictionary:
	if camera == null:
		return {}
	var dist: float = range_override if range_override > 0.0 else interact_range * 10.0
	var space_state := camera.get_world_3d().direct_space_state
	var from := camera.global_position
	var to := from - camera.global_transform.basis.z * dist
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = with_areas
	query.collide_with_bodies = with_bodies
	return space_state.intersect_ray(query)

func try_interact(player: Node) -> void:
	if current_target and current_target.can_interact(player):
		current_target.interact(player)
