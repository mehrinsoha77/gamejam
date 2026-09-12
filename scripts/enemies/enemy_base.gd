class_name EnemyBase
extends CharacterBody3D
## Every alien archetype extends this. Each one's FreedomComponent describes
## which DOFs it actually uses to fight — that's what the Vector Weapon,
## Anchor Weapon and Freedom Manipulator all read and act on, so combat is
## "which freedom do I remove" rather than a flat damage race.

signal died(enemy: EnemyBase)
signal dof_stripped(dof: int)

@export var display_name: String = "ALIEN"
@export var max_health: float = 40.0
@export var move_speed: float = 2.5
@export var attack_damage: float = 8.0
@export var attack_range: float = 1.6
@export var attack_cooldown: float = 1.2
@export var detect_range: float = 14.0
@export var freedom_point_reward: int = 10
## Which DOF the Vector Weapon should strip first for this archetype — the
## one axis that most cripples its ability to reach/hit the player.
@export var preferred_dof_to_strip: int = FreedomComponent.DOF.TRANS_X
## Placeholder body color until a real model is dropped in — see
## ASSETS_NEEDED.md for the swap-in convention (assets/models/enemies/*.glb).
@export var body_color: Color = EnvironmentGenerator.COLOR_ALIEN

enum State { IDLE, CHASE, ATTACK, STAGGERED, DEAD }

var state: int = State.IDLE
var health: float
var freedom_component: FreedomComponent
var _attack_timer: float = 0.0
var _target: Node3D = null

func _ready() -> void:
	add_to_group("enemy")
	health = max_health
	set_collision_layer_value(1, false)
	set_collision_layer_value(4, true)
	set_collision_mask_value(1, true)
	set_collision_mask_value(2, true)

	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.6
	shape.shape = capsule
	shape.position.y = 0.8
	add_child(shape)

	var mesh_instance := MeshInstance3D.new()
	var capsule_mesh := CapsuleMesh.new()
	capsule_mesh.radius = 0.4
	capsule_mesh.height = 1.6
	mesh_instance.mesh = capsule_mesh
	mesh_instance.position.y = 0.8
	mesh_instance.material_override = EnvironmentGenerator.make_material(body_color, body_color, 0.4)
	add_child(mesh_instance)

	freedom_component = FreedomComponent.new()
	freedom_component.name = "FreedomComponent"
	freedom_component.display_name = display_name
	add_child(freedom_component)
	_configure_freedom()

func _configure_freedom() -> void:
	# Default archetype: ground mover, no vertical or roll freedom.
	freedom_component.relevant_dof = [FreedomComponent.DOF.TRANS_X, FreedomComponent.DOF.TRANS_Z, FreedomComponent.DOF.ROT_YAW]
	for dof in freedom_component.relevant_dof:
		freedom_component.unlock(dof)

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	if not zero_gravity_capable() and not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta

	_acquire_target()
	_attack_timer = maxf(0.0, _attack_timer - delta)

	match state:
		State.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, move_speed * delta * 4.0)
			velocity.z = move_toward(velocity.z, 0.0, move_speed * delta * 4.0)
		State.CHASE:
			_do_chase(delta)
		State.ATTACK:
			_do_attack(delta)

	move_and_slide()

func zero_gravity_capable() -> bool:
	return false

func _acquire_target() -> void:
	if _target == null:
		var p := get_tree().get_first_node_in_group("player")
		if p and global_position.distance_to(p.global_position) <= detect_range:
			_target = p
			state = State.CHASE
			return
	if _target:
		var dist := global_position.distance_to(_target.global_position)
		if dist <= attack_range:
			state = State.ATTACK
		elif dist <= detect_range * 1.5:
			state = State.CHASE
		else:
			_target = null
			state = State.IDLE

func _do_chase(delta: float) -> void:
	if _target == null:
		return
	var dir := (_target.global_position - global_position)
	dir.y = 0.0
	if dir.length() > 0.01:
		dir = dir.normalized()
	var can_x := freedom_component.is_free(FreedomComponent.DOF.TRANS_X)
	var can_z := freedom_component.is_free(FreedomComponent.DOF.TRANS_Z)
	var wish := Vector3.ZERO
	if can_x:
		wish.x = dir.x
	if can_z:
		wish.z = dir.z
	if wish.length() > 0.01:
		wish = wish.normalized()
		look_at(global_position + Vector3(dir.x, 0.0, dir.z), Vector3.UP)
	velocity.x = move_toward(velocity.x, wish.x * move_speed, move_speed * 6.0 * delta)
	velocity.z = move_toward(velocity.z, wish.z * move_speed, move_speed * 6.0 * delta)

func _do_attack(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, move_speed * 6.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, move_speed * 6.0 * delta)
	if _target == null:
		return
	if _attack_timer <= 0.0:
		_attack_timer = attack_cooldown
		_perform_attack()

## Override for archetype-specific attacks (melee swing, projectile, DOF steal...).
func _perform_attack() -> void:
	if _target and _target.has_method("take_damage"):
		_target.take_damage(attack_damage, self)
		AudioManager.play_sfx("alien_crawler_hit")

func take_damage(amount: float, _source: Node = null) -> void:
	if state == State.DEAD:
		return
	health -= amount
	if health <= 0.0:
		_die()

func _die() -> void:
	state = State.DEAD
	set_physics_process(false)
	set_collision_layer_value(4, false)
	AudioManager.play_sfx("alien_death")
	GameManager.add_freedom_points(freedom_point_reward)
	GameManager.score_combat += freedom_point_reward
	died.emit(self)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(0.05, 0.05, 0.05), 0.4)
	tween.tween_callback(queue_free)

## Called by VectorWeapon when a DOF is stripped, for archetype-specific reactions.
func on_dof_stripped(dof: int) -> void:
	dof_stripped.emit(dof)
