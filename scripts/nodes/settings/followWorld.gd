extends Control
class_name followWorld

@export var offset:Vector2
var worldOffset:Vector2

func _process(_delta) -> void:
	scale = Vector2.ONE * Game.editor.cameraZoom / Game.uiScale
	position = -offset - (Game.editor.editorCamera.position - worldOffset) * scale
