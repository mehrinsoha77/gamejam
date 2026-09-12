extends Node
## DialogueManager (autoload singleton)
## Story delivery: short AI transmissions, radio chatter, terminal text.
## Never blocks input for long — 1-3 sentence chunks, skippable, non-modal
## by default (gameplay keeps running; call queue_lines(lines, true) to
## slow time for a beat that truly needs the player's full attention).

signal dialogue_started
signal dialogue_finished
signal line_shown(speaker: String, text: String)

var _box: DialogueBox
var _queue: Array = []
var _slow_time: bool = false
var _active: bool = false

func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	_box = DialogueBox.new()
	layer.add_child(_box)
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_pressed("dialogue_continue"):
		_advance()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		_skip_all()
		get_viewport().set_input_as_handled()

## lines: Array of {"speaker": String, "text": String}
func queue_lines(lines: Array, slow_time: bool = false) -> void:
	_queue.append_array(lines)
	_slow_time = slow_time
	if not _active:
		_active = true
		dialogue_started.emit()
		if _slow_time:
			Engine.time_scale = 0.35
		_advance()

func _advance() -> void:
	if _box.is_revealing():
		_box.skip_reveal()
		return
	if _queue.is_empty():
		_end()
		return
	var line: Dictionary = _queue.pop_front()
	_box.show_line(line.get("speaker", "AI SYSTEM"), line.get("text", ""))
	line_shown.emit(line.get("speaker", ""), line.get("text", ""))

func _skip_all() -> void:
	_queue.clear()
	_end()

func _end() -> void:
	_active = false
	if _slow_time:
		Engine.time_scale = 1.0
		_slow_time = false
	_box.hide_box()
	dialogue_finished.emit()

func is_active() -> bool:
	return _active

## Convenience for a single-line AI transmission.
func say(text: String, speaker: String = "AI SYSTEM") -> void:
	queue_lines([{"speaker": speaker, "text": text}])
