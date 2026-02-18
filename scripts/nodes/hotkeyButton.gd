extends Button
class_name HotkeyButton

@export var defaultHotkey:StringName
@export var pressedHotkey:StringName

func _pressed() -> void:
	Game.editor.grab_focus()

func _ready() -> void:
	connect("toggled", queue_redraw.unbind(1))
	add_to_group(&"hotkeyButton")

func _draw() -> void:
	if disabled or Game.editor.settingsOpen: return
	var strWidth:int = int(Game.ROBOTO_MONO.get_string_size(getCurrentHotkey(),HORIZONTAL_ALIGNMENT_LEFT,-1,12).x)
	draw_string(Game.ROBOTO_MONO,Vector2((size.x-strWidth)/2,size.y+9),getCurrentHotkey(),HORIZONTAL_ALIGNMENT_LEFT,-1,12)

func getCurrentHotkey() -> String:
	if button_pressed:
		if pressedHotkey:
			return Explainer.hotkeyMap(pressedHotkey, "")
		else: return ""
	if defaultHotkey: return Explainer.hotkeyMap(defaultHotkey, "")
	else: return ""
