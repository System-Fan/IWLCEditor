extends PanelContainer
class_name AxialNumberEdit

@onready var editor:Editor = get_node("/root/editor")

signal valueSet(value:PackedInt64Array)

var newlyInteracted:bool = false

var value:PackedInt64Array = M.ZERO
var bufferedSign:PackedInt64Array = M.ONE # since -0 (and 0i and -0i) cant exist, activate it when the number is set
var purpose:NumberEdit.PURPOSE = NumberEdit.PURPOSE.AXIAL

var zeroIValid:bool = false # whether or not zeroI is a vaild state
var isZeroI:bool = false

func _ready() -> void:
	Explainer.addControl(self,ControlExplanation.new("/ Number Edit("+Explainer.ARROWS_UD+"±1 [%s]×-1 [%s]×i) /", [&"numberNegate", &"numberTimesI"]))

func convertNumbers(from:M.SYSTEM) -> void:
	Changes.addChange(Changes.ConvertNumberChange.new(self, from, &"value"))
	Changes.addChange(Changes.ConvertNumberChange.new(self, from, &"bufferedSign"))

func _gui_input(event:InputEvent) -> void:
	pass
	#if Editor.isLeftClick(event): editor.focusDialog.interact(self)

func setValue(_value:PackedInt64Array, manual:bool=false) -> void:
	value = _value
	isZeroI = false
	if M.neq(bufferedSign, M.ONE) and M.ex(value):
		bufferedSign = M.ONE
	if M.eq(bufferedSign, M.nONE): %drawText.text = "-0"
	elif M.eq(bufferedSign, M.I): %drawText.text = "0i"; isZeroI = zeroIValid
	elif M.eq(bufferedSign, M.nI): %drawText.text = "-0i"
	else: %drawText.text = M.str(value)
	if !manual: valueSet.emit(value)

func increment() -> void: setValue(M.add(value, M.ONE))
func decrement() -> void: setValue(M.sub(value, M.ONE))

func deNew():
	newlyInteracted = false
	theme_type_variation = &"NumberEditPanelContainerSelected"

func receiveKey(key:InputEventKey):
	var number:int = -1
	if Editor.eventIs(key, &"numberNegate"):
		if M.nex(value): bufferedSign = M.negate(bufferedSign)
		setValue(M.negate(value))
	elif Editor.eventIs(key, &"numberTimesI"):
		if M.nex(value): bufferedSign = M.rotate(bufferedSign)
		setValue(M.rotate(value))
	else:
		match key.keycode:
			KEY_TAB: editor.focusDialog.tabbed(self)
			KEY_0, KEY_KP_0: number = 0
			KEY_1, KEY_KP_1: number = 1
			KEY_2, KEY_KP_2: number = 2
			KEY_3, KEY_KP_3: number = 3
			KEY_4, KEY_KP_4: number = 4
			KEY_5, KEY_KP_5: number = 5
			KEY_6, KEY_KP_6: number = 6
			KEY_7, KEY_KP_7: number = 7
			KEY_8, KEY_KP_8: number = 8
			KEY_9, KEY_KP_9: number = 9
			KEY_BACKSPACE:
				theme_type_variation = &"NumberEditPanelContainerSelected"
				if Input.is_key_pressed(KEY_CTRL) or newlyInteracted: setValue(M.ZERO)
				else:
					var axis:PackedInt64Array = M.saxis(value)
					setValue(M.divide(value, M.N(10)))
					if M.nex(value): bufferedSign = axis
				deNew()
			KEY_UP: increment(); deNew()
			KEY_DOWN: decrement(); deNew()
			KEY_LEFT, KEY_RIGHT: deNew()
			_: return false
	if number != -1:
		if newlyInteracted:
			bufferedSign = M.axis(value)
			if M.nex(bufferedSign): bufferedSign = M.ONE
			setValue(M.ZERO,true)
		deNew()
		if M.nex(value): setValue(M.times(M.N(number), bufferedSign))
		else: setValue(M.add(M.times(value, M.N(10)), M.times(M.N(number), M.times(M.axis(value), bufferedSign))))
	return true

func setZeroI() -> void:
	bufferedSign = M.I
	setValue(M.ZERO, true)
