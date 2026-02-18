extends Control
class_name ResizeHandles

var target:GameComponent

func _process(_delta) -> void:
	if Game.editor.edgeResizing: target = null
	elif Game.editor.settingsOpen and Game.editor.settingsMenu.levelSettings.visible:
		target = Game.editor.levelBoundsObject
	else:
		target = null
		if Game.editor.sizeDragging(): target = Game.editor.componentDragged
		if !target: target = Game.editor.focusDialog.componentFocused
		if !target or (target is Lock and target.parent.type == Door.TYPE.SIMPLE) or (target is KeyCounterElement): target = Game.editor.focusDialog.focused
		if target and target.get_script() not in Game.RESIZABLE_COMPONENTS: target = null
	visible = !!target
	if target:
		position = Game.editor.worldspaceToScreenspace(target.getDrawPosition())
		size = target.getDrawSize() * Game.editor.cameraZoom / Game.uiScale
		%diagonals.visible = target is not KeyCounter
		%vertical.visible = target is not KeyCounter

func _topleft() -> void: 		Game.editor.grab_focus(); Game.editor.startSizeDrag(target, Vector2(-1,-1))
func _top() -> void: 			Game.editor.grab_focus(); Game.editor.startSizeDrag(target, Vector2(0,-1))
func _topright() -> void: 		Game.editor.grab_focus(); Game.editor.startSizeDrag(target, Vector2(1,-1))
func _left() -> void: 			Game.editor.grab_focus(); Game.editor.startSizeDrag(target, Vector2(-1,0))
func _right() -> void: 			Game.editor.grab_focus(); Game.editor.startSizeDrag(target, Vector2(1,0))
func _bottomleft() -> void: 	Game.editor.grab_focus(); Game.editor.startSizeDrag(target, Vector2(-1,1))
func _bottom() -> void: 		Game.editor.grab_focus(); Game.editor.startSizeDrag(target, Vector2(0,1))
func _bottomright() -> void: 	Game.editor.grab_focus(); Game.editor.startSizeDrag(target, Vector2(1,1))

func _finished() -> void: Game.editor.grab_click_focus()
