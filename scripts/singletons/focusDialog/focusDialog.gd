extends Control
class_name FocusDialog

@onready var editor:Editor = get_node("/root/editor")
@onready var colorLink:Button = %colorLink

@onready var keyDialog:KeyDialog = %keyDialog
@onready var doorDialog:DoorDialog = %doorDialog
@onready var playerDialog:PlayerDialog = %playerDialog
@onready var keyCounterDialog:KeyCounterDialog = %keyCounterDialog
@onready var goalDialog:GoalDialog = %goalDialog


var focused:GameObject # the object that is currently focused
var componentFocused:GameComponent # you can focus both a door and a lock at the same time so
var interacted:NewNumberEdit # the number edit that is currently interacted
var activeDialog:Control

var above:bool = false # display above the object instead

func _ready() -> void:
	get_tree().call_group("modUI", "changedMods")

func focus(object:GameObject, dontRedirect:bool=false) -> void:
	var new:bool = object != focused
	focused = object
	Game.objectsParent.move_child(focused, -1)
	showCorrectDialog()
	if new: deinteract()
	if activeDialog: activeDialog.focus(focused, new, dontRedirect)

func showCorrectDialog() -> void:
	above = false
	for dialog in get_children():
		if dialog is not Control: continue
		dialog.visible = false
	%speechBubbler.visible = true
	activeDialog = null
	match focused.get_script():
		KeyBulk: activeDialog = keyDialog
		Door, RemoteLock: activeDialog = doorDialog
		PlayerSpawn, PlayerPlaceholderObject: activeDialog = playerDialog
		KeyCounter: activeDialog = keyCounterDialog; above = true
		Goal: activeDialog = goalDialog
		_: %speechBubbler.visible = false
	if activeDialog: activeDialog.visible = true

func defocus() -> void:
	if !focused: return
	var object:GameObject = focused
	editor.quickSet.applyOrCancel()
	if object is Door and !Mods.active(&"ZeroCopies") and M.nex(object.copies): Changes.addChange(Changes.PropertyChange.new(object,&"copies",M.ONE))
	focused = null
	if object is RemoteLock: object.queue_redraw()
	deinteract()
	defocusComponent()

func focusComponent(component:GameComponent) -> void:
	if !component:
		assert(false)
		return
	var new:bool = component != componentFocused
	componentFocused = component
	if focused != component.parent: focus(component.parent)
	if component is Lock: doorDialog.focusComponent(component, new)
	elif component is KeyCounterElement: keyCounterDialog.focusComponent(component, new)

func defocusComponent() -> void:
	if !componentFocused: return
	if componentFocused is Lock and !Mods.active(&"ZeroCostLock") and !(Mods.active(&"C3") and componentFocused.type in [Lock.TYPE.BLAST, Lock.TYPE.ALL, Lock.TYPE.EXACT]) and M.nex(componentFocused.count): Changes.addChange(Changes.PropertyChange.new(componentFocused,&"count",M.ONE))
	componentFocused = null
	deinteract()

func interact(edit:NewNumberEdit) -> void:
	deinteract()
	edit.interact()
	interacted = edit

func deinteract() -> void:
	if !interacted: return
	interacted.deinteract()
	if activeDialog: activeDialog.editDeinteracted(interacted)
	interacted = null

func interactDoorFirstEdit() -> void:
	defocusComponent()
	focus(focused)

func interactDoorLastEdit() -> void:
	defocusComponent()
	focus(focused)
	interact(%doorCopiesEdit.imaginaryEdit)

func interactLockFirstEdit(index:int) -> void:
	focusComponent(focused.locks[index])

func interactLockLastEdit(index:int) -> void:
	focusComponent(focused.locks[index])
	if componentFocused.type in [Lock.TYPE.NORMAL, Lock.TYPE.EXACT]: interact(%doorAxialNumberEdit)
	elif componentFocused.type in [Lock.TYPE.BLAST, Lock.TYPE.ALL]:
		if componentFocused.isPartial: interact(%partialBlastDenominatorEdit.imaginaryEdit)
		else: interact(%partialBlastNumeratorEdit.imaginaryEdit)
	else: deinteract()

func tabbed(numberEdit:PanelContainer) -> void:
	editor.grab_focus()
	if Input.is_key_pressed(KEY_SHIFT):
		match numberEdit.purpose:
			NumberEdit.PURPOSE.IMAGINARY: interact(numberEdit.get_parent().realEdit)
			NumberEdit.PURPOSE.REAL:
				if focused is KeyBulk:
					interact(%keyCountEdit.imaginaryEdit)
				elif focused is Door:
					if numberEdit == %doorCopiesEdit.realEdit:
						if len(focused.locks) > 0: interactLockLastEdit(-1)
						else: interactDoorLastEdit()
					elif numberEdit == %partialBlastDenominatorEdit.realEdit:
						interact(%partialBlastNumeratorEdit.imaginaryEdit)
					elif numberEdit == %partialBlastNumeratorEdit.realEdit:
						if componentFocused.index == 0: interactDoorLastEdit()
						else: interactLockLastEdit(componentFocused.index-1)
				elif focused.get_script() in [PlayerPlaceholderObject, PlayerSpawn]:
					if numberEdit == %playerKeyCountEdit.realEdit:
						playerDialog.setSelectedColor(Mods.previousColor(playerDialog.color))
						interact(%playerKeyGlistenEdit.imaginaryEdit if Mods.active(&"Glistening") else %playerKeyCountEdit.imaginaryEdit)
					if numberEdit == %playerKeyGlistenEdit.realEdit: interact(%playerKeyCountEdit.imaginaryEdit)
			NumberEdit.PURPOSE.AXIAL:
				assert(componentFocused)
				if componentFocused.index == 0: interactDoorLastEdit()
				else: interactLockLastEdit(componentFocused.index-1)
	else:
		match numberEdit.purpose:
			NumberEdit.PURPOSE.REAL:
				interact(numberEdit.get_parent().imaginaryEdit)
			NumberEdit.PURPOSE.IMAGINARY:
				if focused is KeyBulk:
					interact(%keyCountEdit.realEdit)
				elif focused is Door:
					if numberEdit == %doorCopiesEdit.imaginaryEdit:
						if len(focused.locks) > 0: interactLockFirstEdit(0)
						else: interactDoorFirstEdit()
					elif numberEdit == %partialBlastNumeratorEdit.imaginaryEdit and componentFocused.isPartial:
						interact(%partialBlastDenominatorEdit.realEdit)
					elif numberEdit in [%partialBlastNumeratorEdit.imaginaryEdit, %partialBlastDenominatorEdit.imaginaryEdit]:
						if componentFocused.index == len(focused.locks) - 1: interactDoorFirstEdit()
						else: interactLockFirstEdit(componentFocused.index+1)
				elif focused.get_script() in [PlayerPlaceholderObject, PlayerSpawn]:
					if numberEdit == (%playerKeyGlistenEdit.imaginaryEdit if Mods.active(&"Glistening") else %playerKeyCountEdit.imaginaryEdit):
						playerDialog.setSelectedColor(Mods.nextColor(playerDialog.color))
						interact(%playerKeyCountEdit.realEdit)
					if Mods.active(&"Glistening") and numberEdit == %playerKeyCountEdit.imaginaryEdit: interact(%playerKeyGlistenEdit.realEdit)
			NumberEdit.PURPOSE.AXIAL:
				assert(componentFocused)
				if componentFocused.index == len(focused.locks) - 1: interactDoorFirstEdit()
				else: interactLockFirstEdit(componentFocused.index+1)

func receiveKey(event:InputEvent) -> bool:
	if activeDialog and activeDialog.receiveKey(event): return true
	else:
		if Editor.eventIs(event, &"editDelete"):
			Changes.addChange(Changes.DeleteComponentChange.new(focused))
			Changes.bufferSave()
		else: return false
	return true

const EDGE_MARGIN:float = 4
const OBJECT_MARGIN:float = 16 # between the dialog and the object; where the speech bubbler goes
const SPEECH_BUBBLER_MARGIN:float = 10 # between speech bubbler and edge of dialog

func _process(_delta:float) -> void:
	if focused and activeDialog:
		visible = true
		# position the dialog every frame (could be optimised but i dont care)
		var flip:bool = false
		activeDialog.get_child(0).size = Vector2.ZERO
		var halfWidth:float = activeDialog.get_child(0).size.x/2
		activeDialog.get_child(0).position = Vector2(-halfWidth,0)
		var height:float = activeDialog.get_child(0).size.y
		position = editor.worldspaceToScreenspace(focused.getDrawPosition() + Vector2(focused.size.x/2,focused.size.y)) + Vector2(0,OBJECT_MARGIN)
		
		if above and position.y - height - 2*OBJECT_MARGIN - focused.size.y*editor.cameraZoom < editor.gameCont.position.y + EDGE_MARGIN: flip = true
		elif !above and position.y + height > editor.gameCont.position.y + editor.gameCont.size.y - EDGE_MARGIN: flip = true

		if above != flip: position = editor.worldspaceToScreenspace(focused.getDrawPosition() + Vector2(focused.size.x/2,0)) + Vector2(0,-OBJECT_MARGIN)
		%speechBubbler.rotation_degrees = 0 if above != flip else 180
		if flip != above: activeDialog.get_child(0).position.y = -height
		else: activeDialog.get_child(0).position.y = 0

		var speechBubblerRange:float = halfWidth
		if activeDialog == doorDialog and flip: speechBubblerRange = activeDialog.get_child(0).get_child(1).size.x/2
		%speechBubbler.position.x = 0
		if position.x < halfWidth + EDGE_MARGIN:
			%speechBubbler.position.x = max(position.x-halfWidth-EDGE_MARGIN,SPEECH_BUBBLER_MARGIN-speechBubblerRange)
			position.x = halfWidth + EDGE_MARGIN
		if position.x + halfWidth + EDGE_MARGIN > editor.gameCont.size.x:
			%speechBubbler.position.x = min(position.x+halfWidth-editor.gameCont.size.x+EDGE_MARGIN,speechBubblerRange-SPEECH_BUBBLER_MARGIN)
			position.x = editor.gameCont.size.x - halfWidth - EDGE_MARGIN
		
		if above != flip: position.y = min(position.y, editor.gameCont.position.y + editor.gameCont.size.y - SPEECH_BUBBLER_MARGIN)
		else: position.y = max(position.y, editor.gameCont.position.y + SPEECH_BUBBLER_MARGIN)
	else:
		visible = false

func focusHandlerAdded(type:GDScript, index:int) -> void:
	match type:
		Lock:
			%lockHandler.addButton(index)
			focusComponent(focused.locks[index])
		KeyCounterElement:
			%keyCounterHandler.addButton(index)
			focusComponent(focused.elements[index])
		Door: %doorsHandler.addButton(index,false)

func focusHandlerRemoved(type:GDScript, index:int) -> void:
	match type:
		Lock:
			%lockHandler.removeButton(index)
			if index != 0: focusComponent(focused.locks[index-1])
			elif len(focused.locks) > 0: focusComponent(focused.locks[0])
		KeyCounterElement:
			%keyCounterHandler.removeButton(index)
			if index != 0: focusComponent(focused.elements[index-1])
			elif len(focused.elements) > 0: focusComponent(focused.elements[0])
		Door: %doorsHandler.removeButton(index,false)
