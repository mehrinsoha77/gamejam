extends Node
## DialogueManager (autoload singleton)
## Story delivery: short AI transmissions, radio chatter, terminal text.
## Never blocks the player: movement/look/interact all keep working while a
## line is showing. Dismiss/advance with E, Space, Enter, or Esc — no new
## control to learn, and there's no way to get stuck reading it.

signal dialogue_started
signal dialogue_finished
signal line_shown(speaker: String, text: String)

const AUTO_ADVANCE_DELAY := 4.0

var _box: DialogueBox
var _queue: Array = []
var _active: bool = false
var _auto_timer: SceneTreeTimer

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
	if event.is_action_pressed("dialogue_continue") or event.is_action_pressed("interact"):
		_advance()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		_skip_all()
		get_viewport().set_input_as_handled()

## lines: Array of {"speaker": String, "text": String}
## `slow_time` is accepted for call-site compatibility but no longer slows
## or pauses gameplay — dialogue is always non-blocking now (see fix notes
## in git history: it used to freeze the game because the player had no
## way to know a keypress was expected).
func queue_lines(lines: Array, _slow_time: bool = false) -> void:
	_queue.append_array(lines)
	if not _active:
		_active = true
		dialogue_started.emit()
		_advance()

func _advance() -> void:
	if _box.is_revealing():
		_box.skip_reveal()
		_restart_auto_timer()
		return
	if _queue.is_empty():
		_end()
		return
	var line: Dictionary = _queue.pop_front()
	_box.show_line(line.get("speaker", "AI SYSTEM"), line.get("text", ""))
	line_shown.emit(line.get("speaker", ""), line.get("text", ""))
	_restart_auto_timer()

## Safety net: even if the player never presses anything, the line clears
## itself a few seconds after it finishes typing out.
func _restart_auto_timer() -> void:
	_auto_timer = get_tree().create_timer(AUTO_ADVANCE_DELAY)
	_auto_timer.timeout.connect(_on_auto_timeout)

func _on_auto_timeout() -> void:
	if not _active or _box.is_revealing():
		return
	_advance()

func _skip_all() -> void:
	_queue.clear()
	_end()

func _end() -> void:
	_active = false
	_box.hide_box()
	dialogue_finished.emit()

func is_active() -> bool:
	return _active

## Convenience for a single-line AI transmission.
func say(text: String, speaker: String = "AI SYSTEM") -> void:
	queue_lines([{"speaker": speaker, "text": text}])
