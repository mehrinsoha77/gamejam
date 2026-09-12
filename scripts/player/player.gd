class_name Player
extends CharacterBody3D
## First-person controller entirely gated by FreedomComponent. No axis of
## movement is hardcoded as "always available" except looking around
## (pitch/yaw) — see ARCHITECTURE.md for why that ambiguity in the design
## doc was resolved this way. Roll and full flight arrive with the Final Act.

signal died
signal health_changed(current: float, max: float)
signal energy_changed(current: float, max: float)

const WALK_SPEED := 4.2
const SPRINT_MULTIPLIER := 1.6
const CROUCH_MULTIPLIER := 0.5
const ACCELERATION := 10.0
const AIR_ACCELERATION := 3.0
const JUMP_VELOCITY := 4.6
const STAND_HEIGHT := 1.8
const CROUCH_HEIGHT := 1.0
const PITCH_LIMIT := deg_to_rad(85)

@export var max_health: float = 100.0
@export var max_energy: float = 100.0
@export var energy_regen_per_sec: float = 8.0

var health: float
var energy: float

## Prologue-only teaching beat: TRANS_Z is unlocked but travel is clamped to
## the forward direction until the Level 1 navigation puzzle is solved.
var forward_only: bool = false
## Set true in the Final Act: gravity off, TRANS_Y/ROT_ROLL become thrusters.
var zero_gravity: bool = false

var freedom_component: FreedomComponent
var interaction_component: InteractionComponent
var weapon_system: WeaponSystem

var _camera: Camera3D
var _camera_pivot: Node3D
var _collision: CollisionShape3D
var _capsule: CapsuleShape3D
var _footstep_player: AudioStreamPlayer3D

var _is_crouching: bool = false
var _bob_time: float = 0.0
var _camera_base_y: float = 0.0
var _mouse_captured: bool = true

func _ready() -> void:
	add_to_group("player")
	health = max_health
	energy = max_energy
	_build_rig()
	_apply_progression_from_game_manager()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	AudioManager.set_music_state(AudioManager.MusicState.EXPLORATION)

func _build_rig() -> void:
	_capsule = CapsuleShape3D.new()
	_capsule.height = STAND_HEIGHT
	_capsule.radius = 0.35
	_collision = CollisionShape3D.new()
	_collision.shape = _capsule
	_collision.position.y = STAND_HEIGHT / 2.0
	add_child(_collision)
	set_collision_layer_value(1, false)
	set_collision_layer_value(2, true) # "player" layer
	set_collision_mask_value(1, true) # world geometry
	set_collision_mask_value(4, true) # enemy bodies

	_camera_pivot = Node3D.new()
	_camera_pivot.name = "CameraPivot"
	_camera_pivot.position.y = STAND_HEIGHT - 0.2
	add_child(_camera_pivot)
	_camera_base_y = _camera_pivot.position.y

	_camera = Camera3D.new()
	_camera.name = "Camera3D"
	_camera.fov = GameManager.fov
	_camera_pivot.add_child(_camera)

	freedom_component = FreedomComponent.new()
	freedom_component.name = "FreedomComponent"
	freedom_component.display_name = "SUBJECT"
	add_child(freedom_component)
	# Looking around is always available — only movement is a taught freedom.
	freedom_component.unlock(FreedomComponent.DOF.ROT_PITCH)
	freedom_component.unlock(FreedomComponent.DOF.ROT_YAW)

	interaction_component = InteractionComponent.new()
	interaction_component.name = "InteractionComponent"
	add_child(interaction_component)
	interaction_component.setup(_camera)

	weapon_system = WeaponSystem.new()
	weapon_system.name = "WeaponSystem"
	_camera.add_child(weapon_system)

	_footstep_player = AudioStreamPlayer3D.new()
	add_child(_footstep_player)

func _apply_progression_from_game_manager() -> void:
	for dof in GameManager.permanently_unlocked_dof:
		freedom_component.unlock(dof)
	forward_only = not GameManager.reverse_movement_unlocked and not freedom_component.is_free(FreedomComponent.DOF.TRANS_Z)

func _unhandled_input(event: InputEvent) -> void:
	if DialogueManager.is_active():
		return
	if event is InputEventMouseMotion and _mouse_captured:
		_look(event.relative)
	if event.is_action_pressed("interact"):
		interaction_component.try_interact(self)
	if event.is_action_pressed("fire_primary"):
		weapon_system.fire_primary()
	if event.is_action_pressed("fire_secondary"):
		weapon_system.fire_secondary()
	if event.is_action_pressed("manipulator_mode_cycle"):
		var w := weapon_system.current_weapon()
		if w is FreedomManipulator:
			w.cycle_mode()
	if event.is_action_pressed("weapon_1"):
		weapon_system.switch_to(0)
	if event.is_action_pressed("weapon_2"):
		weapon_system.switch_to(1)
	if event.is_action_pressed("weapon_3"):
		weapon_system.switch_to(2)
	if event.is_action_pressed("weapon_4"):
		weapon_system.switch_to(3)

func _look(relative: Vector2) -> void:
	if freedom_component.is_free(FreedomComponent.DOF.ROT_YAW):
		rotate_y(-relative.x * GameManager.mouse_sensitivity)
	if freedom_component.is_free(FreedomComponent.DOF.ROT_PITCH):
		_camera_pivot.rotate_x(-relative.y * GameManager.mouse_sensitivity)
		_camera_pivot.rotation.x = clampf(_camera_pivot.rotation.x, -PITCH_LIMIT, PITCH_LIMIT)

func _physics_process(delta: float) -> void:
	if DialogueManager.is_active():
		velocity.x = move_toward(velocity.x, 0.0, ACCELERATION * delta)
		velocity.z = move_toward(velocity.z, 0.0, ACCELERATION * delta)
		move_and_slide()
		return

	if not zero_gravity and not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta

	_handle_crouch()
	_handle_movement(delta)
	_handle_jump()
	_handle_head_bob(delta)
	_regen_energy(delta)

	move_and_slide()

func _get_gated_input_vector() -> Vector2:
	var raw := Vector2.ZERO
	if Input.is_action_pressed("move_forward"):
		raw.y -= 1.0
	if Input.is_action_pressed("move_back"):
		raw.y += 1.0
	if Input.is_action_pressed("move_left"):
		raw.x -= 1.0
	if Input.is_action_pressed("move_right"):
		raw.x += 1.0

	if not freedom_component.is_free(FreedomComponent.DOF.TRANS_Z):
		raw.y = 0.0
	elif forward_only and raw.y > 0.0:
		raw.y = 0.0 # backward blocked until the nav puzzle is solved

	if not freedom_component.is_free(FreedomComponent.DOF.TRANS_X):
		raw.x = 0.0

	return raw.normalized() if raw.length() > 1.0 else raw

func _handle_movement(delta: float) -> void:
	var input_vec := _get_gated_input_vector()
	var forward := -global_transform.basis.z
	var right := global_transform.basis.x
	var wish_dir := (forward * -input_vec.y + right * input_vec.x)
	wish_dir.y = 0.0
	if wish_dir.length() > 0.001:
		wish_dir = wish_dir.normalized()

	var speed := WALK_SPEED
	if _is_crouching:
		speed *= CROUCH_MULTIPLIER
	elif Input.is_action_pressed("sprint") and not _is_crouching:
		speed *= SPRINT_MULTIPLIER

	var accel := ACCELERATION if is_on_floor() else AIR_ACCELERATION
	var target_velocity := wish_dir * speed
	velocity.x = move_toward(velocity.x, target_velocity.x, accel * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, accel * delta)

	if wish_dir.length() > 0.01 and _footstep_player and not _footstep_player.playing and is_on_floor():
		_footstep_player.stream = load("res://assets/audio/sfx/footstep.ogg") if ResourceLoader.exists("res://assets/audio/sfx/footstep.ogg") else null
		if _footstep_player.stream:
			_footstep_player.pitch_scale = randf_range(0.95, 1.05)
			_footstep_player.play()

func _handle_jump() -> void:
	if not freedom_component.is_free(FreedomComponent.DOF.TRANS_Y):
		return
	if zero_gravity:
		var vertical := 0.0
		if Input.is_action_pressed("jump"):
			vertical += 1.0
		if Input.is_action_pressed("crouch"):
			vertical -= 1.0
		velocity.y = vertical * WALK_SPEED
		return
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

func _handle_crouch() -> void:
	_is_crouching = Input.is_action_pressed("crouch") and not zero_gravity
	var target_height := CROUCH_HEIGHT if _is_crouching else STAND_HEIGHT
	_capsule.height = move_toward(_capsule.height, target_height, 4.0 * get_physics_process_delta_time())
	_collision.position.y = _capsule.height / 2.0

func _handle_head_bob(delta: float) -> void:
	if not GameManager.head_bob_enabled or zero_gravity:
		_camera_pivot.position.y = move_toward(_camera_pivot.position.y, _camera_base_y, 4.0 * delta)
		return
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	if horizontal_speed > 0.1 and is_on_floor():
		_bob_time += delta * horizontal_speed * 1.3
		var bob_offset := sin(_bob_time * 2.0) * 0.035
		_camera_pivot.position.y = _camera_base_y + bob_offset
	else:
		_camera_pivot.position.y = move_toward(_camera_pivot.position.y, _camera_base_y, 4.0 * delta)

func _regen_energy(delta: float) -> void:
	if energy < max_energy:
		energy = minf(max_energy, energy + energy_regen_per_sec * delta)
		energy_changed.emit(energy, max_energy)

func take_damage(amount: float, _source: Node = null) -> void:
	health = maxf(0.0, health - amount)
	health_changed.emit(health, max_health)
	AudioManager.play_sfx("player_hurt")
	if health <= 0.0:
		_die()

func heal(amount: float) -> void:
	health = minf(max_health, health + amount)
	health_changed.emit(health, max_health)

func _die() -> void:
	AudioManager.play_sfx("player_death")
	died.emit()
	GameManager.respawn_at_checkpoint()

## Called by level scripts when one or more DOFs are unlocked so the whole
## presentation (time dilation, HUD, audio, text) fires from one place.
## Pass a custom `label_override` for a combined unlock (e.g. "X + Z
## TRANSLATION"); otherwise the first dof's name is used.
func unlock_dof_with_presentation(dofs, hud: Node, label_override: String = "") -> void:
	var dof_list: Array = dofs if dofs is Array else [dofs]
	for dof in dof_list:
		freedom_component.unlock(dof)
		GameManager.unlock_dof_permanently(dof)
	if hud and hud.has_method("show_dof_unlock"):
		var label := label_override if label_override != "" else FreedomComponent.DOF_NAMES.get(dof_list[0], "UNKNOWN")
		hud.show_dof_unlock(label)
	AudioManager.play_dof_unlock_stinger()
	var prev_scale := Engine.time_scale
	Engine.time_scale = 0.25
	get_tree().create_timer(0.6, true, false, true).timeout.connect(func():
		Engine.time_scale = prev_scale
	)
