class_name SettingsMenu
extends Control
## Shared settings panel used by both the Main Menu and the Pause Menu.
## Reads/writes GameManager's persisted settings fields directly.

signal closed

var _panel: PanelContainer

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(460, 440)
	_panel.position = Vector2(-230, -220)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.09, 0.97)
	style.border_color = Color(0.35, 0.7, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	_panel.add_child(vbox)

	var title := Label.new()
	title.text = "SETTINGS"
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)

	_add_slider(vbox, "MASTER VOLUME", GameManager.master_volume, func(v): GameManager.master_volume = v; GameManager.apply_settings())
	_add_slider(vbox, "MUSIC VOLUME", GameManager.music_volume, func(v): GameManager.music_volume = v; GameManager.apply_settings())
	_add_slider(vbox, "SFX VOLUME", GameManager.sfx_volume, func(v): GameManager.sfx_volume = v; GameManager.apply_settings())
	_add_slider(vbox, "MOUSE SENSITIVITY", GameManager.mouse_sensitivity * 500.0, func(v): GameManager.mouse_sensitivity = v / 500.0)
	_add_slider(vbox, "FIELD OF VIEW", (GameManager.fov - 60.0) / 60.0, func(v): GameManager.fov = 60.0 + v * 60.0)

	_add_toggle(vbox, "HEAD BOB", GameManager.head_bob_enabled, func(on): GameManager.head_bob_enabled = on)
	_add_toggle(vbox, "SCREEN SHAKE", GameManager.screen_shake_enabled, func(on): GameManager.screen_shake_enabled = on)
	_add_toggle(vbox, "SUBTITLES", GameManager.subtitles_enabled, func(on): GameManager.subtitles_enabled = on)
	_add_toggle(vbox, "FULLSCREEN", GameManager.fullscreen, func(on): GameManager.fullscreen = on; GameManager.apply_settings())
	_add_toggle(vbox, "VSYNC", GameManager.vsync_enabled, func(on): GameManager.vsync_enabled = on; GameManager.apply_settings())

	var back := Button.new()
	back.text = "BACK"
	back.pressed.connect(_on_back)
	vbox.add_child(back)

func _add_slider(vbox: VBoxContainer, label_text: String, value: float, on_change: Callable) -> void:
	var row := VBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 12)
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = clampf(value, 0.0, 1.0)
	slider.value_changed.connect(func(v): on_change.call(v))
	row.add_child(slider)
	vbox.add_child(row)

func _add_toggle(vbox: VBoxContainer, label_text: String, value: bool, on_change: Callable) -> void:
	var row := HBoxContainer.new()
	var check := CheckButton.new()
	check.button_pressed = value
	check.toggled.connect(func(on): on_change.call(on))
	row.add_child(check)
	var label := Label.new()
	label.text = label_text
	row.add_child(label)
	vbox.add_child(row)

func _on_back() -> void:
	GameManager.save_settings()
	closed.emit()
	queue_free()
