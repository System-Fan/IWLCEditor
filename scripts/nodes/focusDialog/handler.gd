extends HFlowContainer
class_name Handler

@export var buttonGroup:ButtonGroup

var buttons:Array[HandlerButton] = []
var add:Button
var remove:Button
var selected:int = -1

var manuallySetting:bool = false # dont send signal (hacky)

func _ready() -> void:
	add = Button.new()
	add.theme_type_variation = &"SelectorButton"
	add.icon = preload("res://assets/ui/focusDialog/handler/add.png")
	add.connect(&"pressed", addComponent)
	add_child(add)
	remove = Button.new()
	remove.theme_type_variation = &"SelectorButton"
	remove.icon = preload("res://assets/ui/focusDialog/handler/remove.png")
	remove.connect(&"pressed", removeComponent)
	add_child(remove)

	buttonGroup.connect("pressed", _select)

func addComponent() -> void: pass
func removeComponent() -> void: pass

func deleteButtons() -> void:
	for button in buttons:
		button.deleted = true
		button._draw()
		button.queue_free()
	buttons = []

func setSelect(index:int) -> void:
	manuallySetting = true
	buttons[index].button_pressed = true
	manuallySetting = false
	selected = index

func _select(button:Button) -> void: # not necessarily HandlerButton since lockhandler's buttongroup is shared with [%s]pend
	selected = button.index

static func buttonType() -> GDScript: return HandlerButton

func addButton(index:int=len(buttons),select:bool=true) -> void:
	var button:HandlerButton = buttonType().new(index, self)
	buttons.append(button)
	add_child(button)
	move_child(add, -1)
	move_child(remove, -1)
	if select: button.button_pressed = true
	else: selected = -1
	remove.visible = true

func removeButton(index:int=selected,select:bool=true) -> void:
	var button:HandlerButton = buttons.pop_at(index)
	button.deleted = true
	button._draw()
	button.queue_free()
	for i in range(index, len(buttons)):
		buttons[i].index -= 1
	if len(buttons) == 0:
		remove.visible = false
		selected = -1
	elif select: setSelect(len(buttons)-1)
	Changes.bufferSave()

func redrawButton(index:int) -> void:
	buttons[index].queue_redraw()

class HandlerButton extends Button:
	var index:int
	var handler:Handler
	
	var deleted:bool=false

	func _init(_index:int,_handler:Handler) -> void:
		custom_minimum_size = Vector2(16,16)
		index = _index
		handler = _handler
		button_group = handler.buttonGroup
		toggle_mode = true
		z_index = 1
		theme_type_variation = &"SelectorButton"
		
	func _notification(what: int) -> void:
		match what:
			NOTIFICATION_PREDELETE: _freed()

	func _freed() -> void: pass
