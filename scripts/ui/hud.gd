class_name HUD
extends CanvasLayer
## Minimal, cinematic HUD. Never covers most of the screen — health/energy/
## freedom sit bottom-left, objective top-left, DOF status only appears
## in the corner as a compact six-row readout, interaction prompts are a
## single centered line, and the Vector's scan panel is its own object.

var health_bar: ProgressBar
var energy_bar: ProgressBar
var freedom_label: Label
var objective_label: Label
var weapon_label: Label
var prompt_label: Label
var dof_status: Dictionary = {} # DOF -> Label
var scan_panel: ScanPanel
var _unlock_popup: Control
var _unlock_label: Label
var _unlock_sub_label: Label

func _ready() -> void:
	layer = 10
	_build_bars()
	_build_objective()
	_build_weapon_label()
	_build_prompt()
	_build_dof_status()
	_build_unlock_popup()
	scan_panel = ScanPanel.new()
	add_child(scan_panel)

func _build_bars() -> void:
	var container := VBoxContainer.new()
	container.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	container.position = Vector2(24, -110)
	container.custom_minimum_size = Vector2(260, 90)
	add_child(container)

	health_bar = ProgressBar.new()
	health_bar.max_value = 100
	health_bar.value = 100
	health_bar.show_percentage = false
	health_bar.custom_minimum_size = Vector2(240, 18)
	health_bar.add_theme_color_override("fg_color", Color(0.85, 0.25, 0.25))
	container.add_child(_labeled_row("HEALTH", health_bar))

	energy_bar = ProgressBar.new()
	energy_bar.max_value = 100
	energy_bar.value = 100
	energy_bar.show_percentage = false
	energy_bar.custom_minimum_size = Vector2(240, 14)
	energy_bar.add_theme_color_override("fg_color", Color(0.3, 0.6, 1.0))
	container.add_child(_labeled_row("ENERGY", energy_bar))

	freedom_label = Label.new()
	freedom_label.text = "FREEDOM: 0"
	freedom_label.add_theme_color_override("font_color", Color(0.8, 0.5, 1.0))
	container.add_child(freedom_label)

func _labeled_row(text: String, bar: ProgressBar) -> Control:
	var row := VBoxContainer.new()
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	row.add_child(label)
	row.add_child(bar)
	return row

func _build_objective() -> void:
	objective_label = Label.new()
	objective_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	objective_label.position = Vector2(24, 20)
	objective_label.add_theme_font_size_override("font_size", 15)
	objective_label.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	objective_label.text = ""
	add_child(objective_label)

func _build_weapon_label() -> void:
	weapon_label = Label.new()
	weapon_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	weapon_label.position = Vector2(-220, -40)
	weapon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	weapon_label.custom_minimum_size = Vector2(200, 24)
	weapon_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	add_child(weapon_label)

func _build_prompt() -> void:
	prompt_label = Label.new()
	prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_label.position = Vector2(-150, -230)
	prompt_label.custom_minimum_size = Vector2(300, 24)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
	prompt_label.visible = false
	add_child(prompt_label)

func _build_dof_status() -> void:
	var container := VBoxContainer.new()
	container.set_anchors_preset(Control.PRESET_TOP_LEFT)
	container.position = Vector2(24, 60)
	add_child(container)
	var title := Label.new()
	title.text = "FREEDOM"
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	container.add_child(title)
	for dof in [FreedomComponent.DOF.TRANS_X, FreedomComponent.DOF.TRANS_Y, FreedomComponent.DOF.TRANS_Z, FreedomComponent.DOF.ROT_PITCH, FreedomComponent.DOF.ROT_YAW, FreedomComponent.DOF.ROT_ROLL]:
		var row := Label.new()
		row.add_theme_font_size_override("font_size", 12)
		container.add_child(row)
		dof_status[dof] = row
	refresh_dof_status(null)

func _build_unlock_popup() -> void:
	_unlock_popup = Control.new()
	_unlock_popup.set_anchors_preset(Control.PRESET_CENTER)
	_unlock_popup.custom_minimum_size = Vector2(400, 100)
	_unlock_popup.position = Vector2(-200, -50)
	_unlock_popup.visible = false
	add_child(_unlock_popup)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_unlock_popup.add_child(vbox)

	var header := Label.new()
	header.text = "DEGREE OF FREEDOM ACQUIRED"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	vbox.add_child(header)

	_unlock_label = Label.new()
	_unlock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_unlock_label.add_theme_font_size_override("font_size", 28)
	_unlock_label.add_theme_color_override("font_color", Color(1, 1, 1))
	vbox.add_child(_unlock_label)

	_unlock_sub_label = Label.new()
	_unlock_sub_label.text = "UNLOCKED"
	_unlock_sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_unlock_sub_label.add_theme_font_size_override("font_size", 13)
	_unlock_sub_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.6))
	vbox.add_child(_unlock_sub_label)

func bind_player(player: Player) -> void:
	player.health_changed.connect(func(cur, mx): health_bar.max_value = mx; health_bar.value = cur)
	player.energy_changed.connect(func(cur, mx): energy_bar.max_value = mx; energy_bar.value = cur)
	GameManager.freedom_points_changed.connect(func(total): freedom_label.text = "FREEDOM: %d" % total)
	GameManager.objective_changed.connect(func(text): objective_label.text = text)
	player.interaction_component.target_changed.connect(func(target):
		if target:
			prompt_label.text = "[ E ] " + target.get_prompt()
			prompt_label.visible = true
		else:
			prompt_label.visible = false
	)
	player.weapon_system.weapon_switched.connect(func(_idx, weapon):
		weapon_label.text = weapon.weapon_name if weapon else ""
		if weapon is FreedomManipulator:
			weapon.set_scan_panel(scan_panel)
	)
	freedom_label.text = "FREEDOM: %d" % GameManager.freedom_points
	refresh_dof_status(player.freedom_component)
	player.freedom_component.dof_state_changed.connect(func(_d, _s, _o): refresh_dof_status(player.freedom_component))

func refresh_dof_status(fc: FreedomComponent) -> void:
	for dof in dof_status.keys():
		var label: Label = dof_status[dof]
		var short := FreedomComponent.DOF_NAMES[dof]
		if fc == null or not fc.is_free(dof):
			label.text = short + "  LOCK"
			label.add_theme_color_override("font_color", Color(0.55, 0.3, 0.3))
		else:
			label.text = short + "  FREE"
			label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))

func set_objective(text: String) -> void:
	objective_label.text = text

func show_dof_unlock(dof_name: String) -> void:
	_unlock_label.text = dof_name
	_unlock_popup.visible = true
	_unlock_popup.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_unlock_popup, "modulate:a", 1.0, 0.3)
	tween.tween_interval(1.6)
	tween.tween_property(_unlock_popup, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): _unlock_popup.visible = false)
