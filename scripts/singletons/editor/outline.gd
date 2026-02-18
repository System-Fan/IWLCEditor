extends Node2D
class_name Outline

@onready var editor:Editor = get_node("/root/editor")

var drawNormal:RID

# see outlineViewport.gd for how this works

func _ready() -> void:
	drawNormal = %outlineViewport2.createChild()

func draw() -> void:
	RenderingServer.canvas_item_clear(drawNormal)
	if Game.playState == Game.PLAY_STATE.PLAY: return
	if editor.settingsOpen:
		if editor.settingsMenu.levelSettings.visible: drawOutline(editor.levelBoundsObject,Color.GREEN)
	else: 
		if editor.focusDialog.focused: drawOutline(editor.focusDialog.focused,Color("#0f0b"))
		if editor.focusDialog.componentFocused: drawOutline(editor.focusDialog.componentFocused,Color.RED)
		if editor.multiselect.state == Multiselect.STATE.HOLDING:
			if editor.objectHovered and editor.objectHovered != editor.focusDialog.focused: drawOutline(editor.objectHovered,Color("#0f06"))
			if editor.componentHovered and editor.componentHovered != editor.focusDialog.componentFocused: drawOutline(editor.componentHovered,Color("#f008"))

func drawOutline(component:GameComponent,color:Color) -> void:
	var pos:Vector2 = component.getDrawPosition()
	if component is PlayerPlaceholderObject: pos -= component.getOffset()
	if component.get_script() in Game.RECTANGLE_COMPONENTS:
		RenderingServer.canvas_item_add_rect(drawNormal,Rect2(pos,component.getDrawSize()),color)
	else:
		RenderingServer.canvas_item_add_texture_rect(drawNormal,Rect2(pos,component.getDrawSize()),component.outlineTex(),false,color)

func _process(_delta) -> void:
	draw()
