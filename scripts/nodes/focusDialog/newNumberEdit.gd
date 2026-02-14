extends PanelContainer
class_name NewNumberEdit

signal valueSet(value:PackedInt64Array)

const FNUMBEREDIT:Font = preload("res://resources/fonts/fNumberEdit.tres")

enum CURSOR_MODE {NORMAL, NUMBER}

var cursorMode:CURSOR_MODE = CURSOR_MODE.NORMAL:
	set(to):
		cursorMode = to
		match cursorMode:
			CURSOR_MODE.NUMBER: %cursor.color = Color("#0083fd88")
			_: %cursor.color = Color("#00ffffaa")
var cursorStart:int = 0
var cursorEnd:int = 0

var cursorSelectedNumber:int = 0 # used in NUMBER mode

var text:String = ""
var textLen:int = 0

var numbers:int = 0
var numberStarts:Array[int] = []
var numberEnds:Array[int] = []
var numberValues:Array[int] = []
var numberSemiNegative:Array[bool] = [] # if a number is negative but like only kinda (the - is instead of a + of the number before it, not part of the number)
var texts:Array[String] = [] # one at the start and one after each number. may be empty
var currentExpression:Array = []
var expressionErrored:bool = false

func _ready() -> void:
	parseText()
	buildText()

func parseText() -> void:
	textLen = len(text)
	# tokenize; extract numbers
	var i:int = 0
	var thisNumberStart:int = -1 # -1 for not currently parsing a number
	var previousNumberEnd:int = 0
	numberStarts.clear()
	numberEnds.clear()
	numberValues.clear()
	numberSemiNegative.clear()
	texts.clear()
	numbers = 0
	var isNumber:bool
	var front:Array[Vector2i] = []
	var tokens:Array[Vector2i] = []
	var layer:int = 0
	for symbol in text + " ":
		isNumber = "0123456789".contains(symbol) or (!isNumber and symbol == "-" and i + 1 != textLen and "0123456789".contains(text[i+1]))
		# end of text
		if previousNumberEnd != -1 and isNumber or i == textLen:
			texts.append(text.substr(previousNumberEnd, i-previousNumberEnd))
		if isNumber:
			# start of number
			if thisNumberStart == -1:
				numbers += 1
				numberStarts.append(i)
				numberSemiNegative.append(i > 0 && text[i-1] == "-")
				thisNumberStart = i
				previousNumberEnd = -1
		else:
			# end of number
			if thisNumberStart != -1:
				var value:int = text.substr(thisNumberStart,i-thisNumberStart).to_int()
				numberEnds.append(i)
				numberValues.append(value)
				thisNumberStart = -1
				previousNumberEnd = i
				tokens.append(Vector2i(TOKEN.NUMBER,numbers-1))
			match symbol:
				")":
					layer -= 1
					if layer < 0: # insert missing lbracket at start
						layer = 0
						front.append(Vector2i(TOKEN.LBRACKET, 0))
					tokens.append(Vector2i(TOKEN.RBRACKET, 0))
				"(":
					layer += 1
					tokens.append(Vector2i(TOKEN.LBRACKET, 0))
				"+": tokens.append(Vector2i(TOKEN.CROSS, 0))
				"-": tokens.append(Vector2i(TOKEN.DASH, 0))
				"x": tokens.append(Vector2i(TOKEN.X, 0))
				"/": tokens.append(Vector2i(TOKEN.SLASH, 0))
				"i": tokens.append(Vector2i(TOKEN.I, 0))
		i += 1
	# insert missing rbrackets at end
	while layer > 0:
		layer -= 1
		tokens.append(Vector2i(TOKEN.RBRACKET, 0))
	front.append_array(tokens)
	tokens = front
	# parse tokens into expression
	if tokens: currentExpression = parseTokens(tokens, STEP.SUM)
	else: currentExpression = []
	evaluate()

func evaluate() -> void:
	expressionErrored = false
	var result:PackedInt64Array = evaluateExpression(currentExpression)
	if !expressionErrored: valueSet.emit(result)

enum TOKEN {NUMBER, LBRACKET, RBRACKET, CROSS, DASH, X, SLASH, I}
enum STEP {VALUE, PRODUCT, SUM} # symbol in the parsing expression grammar

# expands back to front
# i dont think im using this right lmao
# Sum     ← (Sum ('+' / '-'))? Product
# Product ← (Product ('*' / '/'))? Value
# Value   ← '-'* ([0-9]+ / ('(' Sum ')')+) 'i'*

# tokens is Array[Vector2i(TOKEN, data)]
# data is the number index when the token is a TOKEN.NUMBER. otherwise unused
func parseTokens(tokens:Array[Vector2i], step:STEP) -> Array: # returns expression
	match step:
		STEP.SUM:
			var layer:int = 0
			for index in range(len(tokens)-1,-1,-1):
				var token:TOKEN = tokens[index].x as TOKEN
				match token:
					TOKEN.RBRACKET: layer += 1
					TOKEN.LBRACKET: layer -= 1
					TOKEN.CROSS, TOKEN.DASH:
						if layer == 0:
							if index == 0 or index == len(tokens)-1:
								# sum error!
								return [EXPRESSION.ERROR]
							# sum!
							return [
								EXPRESSION.ADD if token == TOKEN.CROSS else EXPRESSION.SUB,
								parseTokens(tokens.slice(0,index), STEP.SUM),
								parseTokens(tokens.slice(index+1), STEP.PRODUCT)
							]
			return parseTokens(tokens, STEP.PRODUCT)
		STEP.PRODUCT:
			var layer:int = 0
			for index in range(len(tokens)-1,-1,-1):
				var token:TOKEN = tokens[index].x as TOKEN
				match token:
					TOKEN.RBRACKET: layer += 1
					TOKEN.LBRACKET: layer -= 1
					TOKEN.X, TOKEN.SLASH:
						if layer == 0:
							if index == 0 or index == len(tokens)-1:
								# product error!
								return [EXPRESSION.ERROR]
							# product!
							return [
								EXPRESSION.TIMES if token == TOKEN.X else EXPRESSION.DIVIDE,
								parseTokens(tokens.slice(0,index), STEP.PRODUCT),
								parseTokens(tokens.slice(index+1), STEP.VALUE)
							]
			return parseTokens(tokens, STEP.VALUE)
		STEP.VALUE, _:
			var axis:PackedInt64Array = M.ONE
			while tokens[0].x == TOKEN.DASH:
				tokens.pop_front()
				axis = M.negate(axis)
			while tokens[-1].x == TOKEN.I:
				tokens.pop_back()
				axis = M.rotate(axis)
			if tokens[0].x == TOKEN.LBRACKET and tokens[-1].x == TOKEN.RBRACKET:
				tokens.pop_front()
				tokens.pop_back()
				if len(tokens) == 0:
					# empty brackets error!
					return [EXPRESSION.ERROR]
				# check for implicit multiplication
				var implicitMultCheck:bool = false
				var layer:int = 0
				for index in range(len(tokens)-1,-1,-1):
					var token = tokens[index].x as TOKEN
					match token:
						TOKEN.LBRACKET:
							layer -= 1
							implicitMultCheck = true
						TOKEN.RBRACKET:
							layer += 1
							if layer == 0 and implicitMultCheck:
								if index == 0 or index == len(tokens) - 2:
									# implicit multiplication error!
									return [EXPRESSION.ERROR]
								# implicit multiplication!
								return [
									EXPRESSION.TIMES,
									parseTokens(tokens.slice(0,index), STEP.SUM),
									parseTokens(tokens.slice(index+2), STEP.SUM)
								]
						_: implicitMultCheck = false
				# bracketed sum!
				if M.neq(axis, M.ONE):
					return [
						EXPRESSION.AXIS, axis,
						parseTokens(tokens, STEP.SUM)
					]
				return parseTokens(tokens.slice(1,-1), STEP.SUM)
			if len(tokens) > 1 or tokens[0].x != TOKEN.NUMBER:
				# value error!
				return [EXPRESSION.ERROR]
			# value!
			if M.neq(axis, M.ONE):
				return [EXPRESSION.AXIS, axis, [EXPRESSION.NUMBER, tokens[0].y]]
			return [EXPRESSION.NUMBER, tokens[0].y]

enum EXPRESSION {NUMBER, AXIS, ADD, SUB, TIMES, DIVIDE, ERROR}
# number: [EXPRESSION.NUMBER, number index]
# axis: [EXPRESSION.AXIS, axis, expression]
# operator: [EXPRESSION.operator, expression, expression]
# error: [EXPRESSION.error, information]

func evaluateExpression(expression:Array) -> PackedInt64Array:
	if len(expression) == 0: return M.ZERO
	match expression[0]:
		EXPRESSION.NUMBER: return M.N(numberValues[expression[1]])
		EXPRESSION.AXIS: return M.times(expression[1], evaluateExpression(expression[2]))
		EXPRESSION.ADD: return M.add(evaluateExpression(expression[1]), evaluateExpression(expression[2]))
		EXPRESSION.SUB: return M.sub(evaluateExpression(expression[1]), evaluateExpression(expression[2]))
		EXPRESSION.TIMES: return M.times(evaluateExpression(expression[1]), evaluateExpression(expression[2]))
		EXPRESSION.DIVIDE: return M.divide(evaluateExpression(expression[1]), evaluateExpression(expression[2]))
		EXPRESSION.ERROR, _:
			expressionErrored = true
			return M.ZERO

func buildText() -> void:
	var formattedText:String = texts[0]
	for i in numbers:
		formattedText += "[color=ffffff]%s[/color]" % numberValues[i]
		formattedText += texts[i+1]
	%drawText.text = formattedText
	text = %drawText.get_parsed_text()
	placeCursor()

func receiveKey(key:InputEventKey) -> bool:
	Game.editor.grab_focus()
	match key.keycode:
		KEY_RIGHT:
			cursorMode = CURSOR_MODE.NORMAL
			if Input.is_key_pressed(KEY_SHIFT):
				if Input.is_key_pressed(KEY_CTRL): cursorEnd = nextPointOfInterest()
				else: cursorEnd = min(textLen, cursorEnd+1)
			else:
				if cursorEnd > cursorStart: cursorStart = cursorEnd
				elif cursorStart < textLen:
					if Input.is_key_pressed(KEY_CTRL): cursorStart = nextPointOfInterest()
					else: cursorStart += 1
					cursorEnd = cursorStart
					numberCaptureCursor(cursorStart)
			placeCursor()
		KEY_LEFT:
			cursorMode = CURSOR_MODE.NORMAL
			if Input.is_key_pressed(KEY_SHIFT):
				if Input.is_key_pressed(KEY_CTRL): cursorStart = previousPointOfInterest()
				else: cursorStart = max(0, cursorStart-1)
			else:
				if cursorEnd > cursorStart: cursorEnd = cursorStart
				elif cursorStart > 0:
					if Input.is_key_pressed(KEY_CTRL): cursorStart = previousPointOfInterest()
					else: cursorStart -= 1
					cursorEnd = cursorStart
					numberCaptureCursor(cursorStart)
			placeCursor()
		KEY_UP:
			match cursorMode:
				CURSOR_MODE.NORMAL:
					for number in numbers:
						if numberStarts[number] >= cursorStart && numberEnds[number] <= cursorEnd: changeNumber(number, 1)
					buildText()
				CURSOR_MODE.NUMBER:
					changeNumber(cursorSelectedNumber, 1)
					numberCaptureCursor(cursorStart)
					buildText()
					buildText()
		KEY_DOWN:
			match cursorMode:
				CURSOR_MODE.NORMAL:
					for number in numbers:
						if numberStarts[number] >= cursorStart && numberEnds[number] <= cursorEnd: changeNumber(number, -1)
					buildText()
				CURSOR_MODE.NUMBER:
					changeNumber(cursorSelectedNumber, -1)
					numberCaptureCursor(cursorStart)
					buildText()
		KEY_TAB:
			match cursorMode:
				_:
					if Input.is_key_pressed(KEY_SHIFT):
						for number in range(numbers,0,-1): if numberStarts[number-1] < cursorStart:
							numberCaptureCursor(numberStarts[number-1]); break
					else:
						for number in numbers: if numberEnds[number] > cursorEnd:
							numberCaptureCursor(numberStarts[number]); break
			placeCursor()
		KEY_A:
			if Input.is_key_pressed(KEY_CTRL):
				cursorMode = CURSOR_MODE.NORMAL
				cursorStart = 0
				cursorEnd = textLen
				placeCursor()
		KEY_BACKSPACE:
			if text == "": return true
			match cursorMode:
				CURSOR_MODE.NORMAL:
					if cursorEnd == cursorStart:
						var prevStart:int = cursorStart
						if Input.is_key_pressed(KEY_CTRL): cursorStart = previousPointOfInterest()
						else: cursorStart -= 1
						text = text.erase(cursorStart, prevStart-cursorStart)
						cursorEnd = cursorStart
						parseText()
						buildText()
					else:
						text = text.erase(cursorStart, cursorEnd - cursorStart)
						cursorEnd = cursorStart
						parseText()
						buildText()
				CURSOR_MODE.NUMBER:
					if numberValues[cursorSelectedNumber] == 0 or Input.is_key_pressed(KEY_CTRL):
						cursorMode = CURSOR_MODE.NORMAL
						text = text.erase(cursorStart, cursorEnd - cursorStart)
						cursorEnd = cursorStart
						parseText()
						buildText()
					else:
						setNumber(cursorSelectedNumber, 0)
						numberCaptureCursor(cursorStart)
						buildText()
		_:
			match cursorMode:
				CURSOR_MODE.NORMAL:
					if key.keycode >= 32 and key.keycode < 128:
						var character:String = char(key.unicode)
						if cursorEnd > cursorStart:
							text = text.erase(cursorStart, cursorEnd - cursorStart)
						elif "0123456789".contains(character):
							var endNumber:int = numberEnds.find(cursorStart)
							if endNumber != -1:
								setNumber(endNumber, numberValues[endNumber]*10+character.to_int())
								cursorStart = numberValues[endNumber]
								cursorEnd = cursorStart
								buildText()
								return true
							var startNumber:int = numberStarts.find(cursorStart)
							if startNumber != -1:
								setNumber(startNumber, character.to_int()*(10**len(numberValues[startNumber])) + numberValues[startNumber])
								cursorStart += 1
								cursorEnd = cursorStart
								buildText()
								return true
						text = text.insert(cursorStart, character)
						cursorStart += 1
						cursorEnd = cursorStart
						parseText()
						buildText()
				CURSOR_MODE.NUMBER:
					if Editor.eventIs(key, &"numberTimesI"): pass
					elif Editor.eventIs(key, &"numberNegate"):
						setNumber(cursorSelectedNumber, -numberValues[cursorSelectedNumber])
						numberCaptureCursor(cursorStart)
						buildText()
					else: return false
	return true

## for ctrl+right
func nextPointOfInterest() -> int:
	var pointOfInterest:int = textLen
	for number in numbers:
		if numberEnds[number] > cursorEnd: pointOfInterest = min(numberEnds[number], pointOfInterest)
		if numberStarts[number] > cursorEnd: pointOfInterest = min(numberStarts[number], pointOfInterest)
	return pointOfInterest

## for ctrl+left
func previousPointOfInterest() -> int:
	var pointOfInterest:int = 0
	for number in numbers:
		if numberEnds[number] < cursorStart: pointOfInterest = max(numberEnds[number], pointOfInterest)
		if numberStarts[number] < cursorStart: pointOfInterest = max(numberStarts[number], pointOfInterest)
	return pointOfInterest

func changeNumber(number:int, by:int) -> void:
	if numberSemiNegative[number]: setNumber(number, numberValues[number] - by)
	else: setNumber(number, numberValues[number] + by)

func setNumber(number:int, to:int) -> void:
	var prevLen:int = numberEnds[number] - numberStarts[number]
	numberValues[number] = to
	numberCheckSign(number)
	var lenChange:int = len(str(numberValues[number])) - prevLen
	numberEnds[number] += lenChange
	for shiftedNumber in range(number+1, numbers):
		numberStarts[shiftedNumber] += lenChange
		numberEnds[shiftedNumber] += lenChange
	textLen += lenChange
	evaluate()

func numberCheckSign(number:int) -> void:
	if numberSemiNegative[number]:
		if numberValues[number] <= 0:
			numberValues[number] *= -1
			texts[number][-1] = "+"
			numberSemiNegative[number] = false
	else:
		if numberValues[number] < 0 and texts[number][-1] == "+":
			numberValues[number] *= -1
			texts[number][-1] = "-"
			numberSemiNegative[number] = true


func numberCaptureCursor(fromPosition:int) -> void:
	for number in numbers:
		if fromPosition >= numberStarts[number] and fromPosition <= numberEnds[number]:
			cursorStart = numberStarts[number]
			cursorEnd = numberEnds[number]
			cursorSelectedNumber = number
			cursorMode = CURSOR_MODE.NUMBER
			return

func placeCursor() -> void:
	%cursor.position.x = FNUMBEREDIT.get_string_size(text.substr(0,cursorStart)).x - 1
	%cursor.size.x = FNUMBEREDIT.get_string_size(text.substr(0,cursorEnd)).x - %cursor.position.x + 1
