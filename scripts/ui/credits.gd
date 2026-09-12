extends CanvasLayer
## Simple scrolling-free credits screen. Update the CREDITS array below as
## the team/assets come together — see ASSETS_NEEDED.md for licensing notes.

const CREDITS := [
	["DEGREES OF FREEDOM", ""],
	["A GAME ABOUT WHAT FREEDOM COSTS", ""],
	["", ""],
	["PROGRAMMING & DESIGN", "Your Team Here"],
	["ART & ENVIRONMENT", "TBD — see ASSETS_NEEDED.md"],
	["MUSIC & SOUND", "TBD — see ASSETS_NEEDED.md"],
	["SPECIAL THANKS", "Everyone who plays this jam build"],
]

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var bg := ColorRect.new()
	bg.color = Color(0.01, 0.01, 0.02)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(600, 0)
	box.position = Vector2(200, 60)
	box.add_theme_constant_override("separation", 18)
	scroll.add_child(box)

	for entry in CREDITS:
		var heading: Label = Label.new()
		heading.text = entry[0]
		heading.add_theme_font_size_override("font_size", 20)
		heading.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
		box.add_child(heading)
		if entry[1] != "":
			var sub := Label.new()
			sub.text = entry[1]
			sub.add_theme_color_override("font_color", Color(0.65, 0.68, 0.75))
			box.add_child(sub)

	var back := Button.new()
	back.text = "BACK"
	back.position = Vector2(24, 24)
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	add_child(back)
