extends Window
class_name ExportWindow

enum EXPORT_TYPES {ROOM_GMX}

var path:String = ""
var type:EXPORT_TYPES = EXPORT_TYPES.ROOM_GMX
var fileExtension:String
var exporter:GDScript

var interacted:PanelContainer
var numberEdits:Array[NumberEdit] = []

func _ready() -> void:
	Game.editor.exportWindow = self
	if OS.has_feature('web'):
		%exportPathSetting.visible = false
	_setType(type)
	%roomIDEdit.setValue(M.N(ExportRoomGMX.roomID))
	%idIterStartEdit.setValue(M.N(ExportRoomGMX.idIterStart))

func _setType(index:int) -> void:
	type = index as EXPORT_TYPES
	%pathDialog.clear_filters()
	var fileTypeDesc:String
	match type:
		EXPORT_TYPES.ROOM_GMX:
			fileExtension = ".room.gmx"
			fileTypeDesc = "GameMaker Room File"
			%roomGMX.visible = true
			exporter = ExportRoomGMX
	%pathDialog.add_filter("*"+fileExtension, fileTypeDesc)
	%pathDialog.current_dir = "exports"
	%pathDialog.current_file = "exports/"+Game.level.name+fileExtension
	_setPath(("user://temp."+fileExtension) if OS.has_feature('web') else "")

func _close() -> void: queue_free()

func _changePath() -> void:
	if path: %pathDialog.current_file = path
	%pathDialog.visible = true
	%pathDialog.grab_focus()

func _setPath(_path:String) -> void:
	path = _path
	%path.text = path
	%export.disabled = !path

func _export():
	var file:FileAccess = FileAccess.open(path,FileAccess.ModeFlags.WRITE)
	exporter.exportFile(file)
	file.close()
	if OS.has_feature('web'): JavaScriptBridge.download_buffer(FileAccess.get_file_as_bytes(path),Game.level.name+fileExtension)
	_close()

func _input(event:InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and interacted: interacted.receiveKey(event)

func interact(edit:NumberEdit) -> void:
	deinteract()
	edit.interact()
	interacted = edit

func deinteract() -> void:
	if !interacted: return
	interacted.deinteract()
	interacted = null

# .ROOM.GMX
func _roomIDSet(value:PackedInt64Array) -> void:
	ExportRoomGMX.roomID = M.toInt(value)

func _idIterStartSet(value:PackedInt64Array) -> void:
	ExportRoomGMX.idIterStart = M.toInt(value)
