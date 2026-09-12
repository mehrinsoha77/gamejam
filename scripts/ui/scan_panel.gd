class_name ScanPanel
extends Control
## Compact DOF readout for whatever the Vector is currently scanning.
## Deliberately NOT a spreadsheet: six checkmarks/crosses plus a mode label.

var _panel: PanelContainer
var _name_label: Label
var _mode_label: Label
var _rows: Dictionary = {} # DOF -> Label

const ROW_ORDER := [
	FreedomComponent.DOF.TRANS_X, FreedomComponent.DOF.TRANS_Y, FreedomComponent.DOF.TRANS_Z,
	FreedomComponent.DOF.ROT_PITCH, FreedomComponent.DOF.ROT_YAW, FreedomComponent.DOF.ROT_ROLL,
]
const SHORT_NAMES := {
	FreedomComponent.DOF.TRANS_X: "X", FreedomComponent.DOF.TRANS_Y: "Y", FreedomComponent.DOF.TRANS_Z: "Z",
	FreedomComponent.DOF.ROT_PITCH: "PITCH", FreedomComponent.DOF.ROT_YAW: "YAW", FreedomComponent.DOF.ROT_ROLL: "ROLL",
}

func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	position = Vector2(-260, 90)
	custom_minimum_size = Vector2(240, 220)
	visible = false

	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.02, 0.08, 0.82)
	style.border_color = Color(0.7, 0.4, 1.0, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	_panel.add_child(vbox)

	_name_label = Label.new()
	_name_label.add_theme_color_override("font_color", Color(0.85, 0.6, 1.0))
	vbox.add_child(_name_label)

	vbox.add_child(HSeparator.new())

	for dof in ROW_ORDER:
		var row := HBoxContainer.new()
		vbox.add_child(row)
		var label := Label.new()
		label.text = SHORT_NAMES[dof]
		label.custom_minimum_size = Vector2(60, 0)
		row.add_child(label)
		var value := Label.new()
		value.text = "—"
		row.add_child(value)
		_rows[dof] = value

	vbox.add_child(HSeparator.new())
	_mode_label = Label.new()
	_mode_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	_mode_label.add_theme_font_size_override("font_size", 13)
	vbox.add_child(_mode_label)

func show_scan(display_name: String, fc: FreedomComponent, mode_text: String) -> void:
	visible = true
	_name_label.text = display_name
	for dof in ROW_ORDER:
		var label: Label = _rows[dof]
		if not fc.is_relevant(dof):
			label.text = "n/a"
			label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
		elif fc.is_free(dof):
			label.text = "FREE"
			label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
		else:
			label.text = "LOCKED"
			label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	_mode_label.text = "MODE: " + mode_text

func hide_scan() -> void:
	visible = false
