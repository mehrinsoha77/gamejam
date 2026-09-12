class_name Interactable
extends Area3D
## Base class for anything the player can look at and press [E] on.
## Attach as the root script of any interactive prop (door, terminal,
## elevator, pickup...). Subclasses override interact() and prompt_text.

@export var prompt_text: String = "INTERACT"
@export var enabled: bool = true

## Optional: if this object has a FreedomComponent child, it becomes
## scannable/manipulable by the Vector. Leave null for purely narrative props.
var freedom_component: FreedomComponent = null

func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(3, true) # layer 3 = "interactable"
	if has_node("FreedomComponent"):
		freedom_component = get_node("FreedomComponent")

func get_prompt() -> String:
	return prompt_text

func can_interact(_player: Node) -> bool:
	return enabled

## Override in subclasses.
func interact(_player: Node) -> void:
	pass

func is_scannable() -> bool:
	return freedom_component != null
