extends GameObject
class_name KeyBulk
const SCENE:PackedScene = preload("res://scenes/objects/keyBulk.tscn")

const MULTITYPEOFFSET = 3 # no magic numbers

const TYPES:int = 6
enum TYPE {NORMAL, EXACT, STAR, ROTOR, CURSE, OPERATOR}

const OPERATIONS:int = 6
enum OPERATION {SET, ADD, SUBTRACT, MULTIPLY, DIVIDE, MODULO}

# colors that use textures
const TEXTURE_COLORS:Array[Game.COLOR] = [Game.COLOR.MASTER, Game.COLOR.PURE, Game.COLOR.STONE, Game.COLOR.DYNAMITE, Game.COLOR.QUICKSILVER, Game.COLOR.ICE, Game.COLOR.MUD, Game.COLOR.GRAFFITI]

static var FILL:KeyTextureLoader = KeyTextureLoader.new("res://assets/game/key/$t/fill.png")
static var FRAME:KeyTextureLoader = KeyTextureLoader.new("res://assets/game/key/$t/frame.png")
static var FILL_GLITCH:KeyTextureLoader = KeyTextureLoader.new("res://assets/game/key/$t/fillGlitch.png")
static var FRAME_GLITCH:KeyTextureLoader = KeyTextureLoader.new("res://assets/game/key/$t/frameGlitch.png")
static var OUTLINE_MASK:KeyTextureLoader = KeyTextureLoader.new("res://assets/game/key/$t/outlineMask.png")
static var QUICKSILVER_OUTLINE_MASK:KeyTextureLoader = KeyTextureLoader.new("res://assets/game/key/quicksilver/outlineMask$t.png", true)

static var OPERATOR_FRAME:OperatorTextureLoader = OperatorTextureLoader.new("res://assets/game/key/operator/frame/$t.png")
static var OPERATOR_FILL:OperatorTextureLoader = OperatorTextureLoader.new("res://assets/game/key/operator/fill/$t.png")
static var OPERATOR_FRAME_GLITCH:OperatorTextureLoader = OperatorTextureLoader.new("res://assets/game/key/operator/frameGlitch/$t.png")
static var OPERATOR_FILL_GLITCH:OperatorTextureLoader = OperatorTextureLoader.new("res://assets/game/key/operator/fillGlitch/$t.png") 
const CURSE_FILL_DARK:Texture2D = preload("res://assets/game/key/curse/fillDark.png")

const NULL_ROTOR_SYMBOL:Texture2D = preload("res://assets/game/key/symbols/null.png")
const SIGNFLIP_SYMBOL:Texture2D = preload("res://assets/game/key/symbols/signflip.png")
const POSROTOR_SYMBOL:Texture2D = preload("res://assets/game/key/symbols/posrotor.png")
const NEGROTOR_SYMBOL:Texture2D = preload("res://assets/game/key/symbols/negrotor.png")
const INFINITE_SYMBOL:Texture2D = preload("res://assets/game/key/symbols/infinite.png")
const RECIPROCAL__SYMBOL:Texture2D = preload("res://assets/game/key/symbols/reci.png")
const RECIPROCAL_FLIP_SYMBOL:Texture2D = preload("res://assets/game/key/symbols/reciflip.png")
const RECIPROCAL_POS_SYMBOL:Texture2D = preload("res://assets/game/key/symbols/recipos.png")
const RECIPROCAL_NEG_SYMBOL:Texture2D = preload("res://assets/game/key/symbols/recineg.png")
const GLISTENING_SYMBOL:Texture2D = preload("res://assets/game/key/symbols/glistening.png")

static var TEXTURE:KeyColorsTextureLoader = KeyColorsTextureLoader.new("res://assets/game/key/$c/$t.png", TEXTURE_COLORS, true, false, {capitalised=false})
static var GLITCH:KeyColorsTextureLoader = KeyColorsTextureLoader.new("res://assets/game/key/$c/glitch$t.png", TEXTURE_COLORS, false, false, {capitalised=true})

static var OPERATION_TEXTURE:operationColorsTextureLoader = operationColorsTextureLoader.new("res://assets/game/key/$c/operator/$t.png", TEXTURE_COLORS, true, false, {capitalised=false})
static var OPERATION_GLITCH:operationColorsTextureLoader = operationColorsTextureLoader.new("res://assets/game/key/$c/operator/glitch$t.png", TEXTURE_COLORS, false, false, {capitalised=true})

const FKEYBULK:Font = preload("res://resources/fonts/fKeyBulk.fnt")

const CREATE_PARAMETERS:Array[StringName] = [
	&"position"
]
const PROPERTIES:Array[StringName] = [
	&"id", &"position", &"size",
	&"color", &"type", &"count", &"infinite", &"glistening", &"un", &"altColor", &"mode"
]								
static var ARRAYS:Dictionary[StringName,Variant] = {}

var color:Game.COLOR = Game.COLOR.WHITE
var type:TYPE = TYPE.NORMAL
var count:PackedInt64Array = M.ONE
var infinite:int = 0
var glistening:bool = false # whether the key affects glistening count or not
var altColor:Game.COLOR = Game.COLOR.WHITE
var mode:OPERATION = OPERATION.SET
var un:bool = false # whether a star or curse key is an unstar or uncurse key
var reciprocal:bool = false # whether a rotor key is reciprocal or not

var drawDropShadow:RID
var drawGlitch:RID
var drawMain:RID
var drawSymbol:RID
var drawAdditionalGlitch:RID
var drawAdditional:RID
func _init() -> void: size = Vector2(32,32)

func _ready() -> void:
	drawDropShadow = RenderingServer.canvas_item_create()
	drawGlitch = RenderingServer.canvas_item_create()
	drawMain = RenderingServer.canvas_item_create()
	drawSymbol = RenderingServer.canvas_item_create()
	drawAdditionalGlitch = RenderingServer.canvas_item_create()
	drawAdditional = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_material(drawGlitch,Game.GLITCH_MATERIAL.get_rid())
	RenderingServer.canvas_item_set_material(drawAdditionalGlitch,Game.GLITCH_MATERIAL.get_rid())
	RenderingServer.canvas_item_set_z_index(drawDropShadow,-3)
	RenderingServer.canvas_item_set_parent(drawDropShadow,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawGlitch,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawMain,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawSymbol,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawAdditionalGlitch,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawAdditional,get_canvas_item())
	Game.connect(&"goldIndexChanged",func():if color in Game.ANIMATED_COLORS: queue_redraw())

func _freed() -> void:
	RenderingServer.free_rid(drawDropShadow)
	RenderingServer.free_rid(drawGlitch)
	RenderingServer.free_rid(drawMain)
	RenderingServer.free_rid(drawSymbol)
	RenderingServer.free_rid(drawAdditionalGlitch)
	RenderingServer.free_rid(drawAdditional)

func convertNumbers(from:M.SYSTEM) -> void:
	Changes.addChange(Changes.ComponentConvertNumberChange.new(self, from, &"count"))

func outlineTex() -> Texture2D: return getOutlineTexture(color, type, un)

static func getOutlineTexture(keyColor:Game.COLOR, keyType:TYPE=TYPE.NORMAL, keyUn:bool=false) -> Texture2D:
	var textureType:KeyTextureLoader.TYPE = keyTextureType(keyType,keyUn)
	match keyColor:
		Game.COLOR.MASTER:
			match textureType:
				KeyTextureLoader.TYPE.NORMAL: return preload("res://assets/game/key/master/outlineMask.png")
				KeyTextureLoader.TYPE.EXACT: return preload("res://assets/game/key/master/outlineMaskExact.png")
		Game.COLOR.QUICKSILVER:
			return QUICKSILVER_OUTLINE_MASK.current([textureType])
		Game.COLOR.DYNAMITE:
			if textureType == KeyTextureLoader.TYPE.NORMAL: return preload("res://assets/game/key/dynamite/outlineMask.png")
	return OUTLINE_MASK.current([textureType])

func _draw() -> void:
	RenderingServer.canvas_item_clear(drawDropShadow)
	RenderingServer.canvas_item_clear(drawGlitch)
	RenderingServer.canvas_item_clear(drawMain)
	RenderingServer.canvas_item_clear(drawSymbol)
	RenderingServer.canvas_item_clear(drawAdditionalGlitch)
	RenderingServer.canvas_item_clear(drawAdditional)
	if !active and Game.playState == Game.PLAY_STATE.PLAY: return
	var rect:Rect2 = Rect2(Vector2.ZERO, size)
	RenderingServer.canvas_item_add_texture_rect(drawDropShadow,Rect2(Vector2(3,3),size),getOutlineTexture(color,type,un),false,Game.DROP_SHADOW_COLOR)
	drawKey(drawGlitch,drawMain,Vector2.ZERO,color,type,un,glitchMimic,partialInfiniteAlpha)
	if animState == ANIM_STATE.FLASH: RenderingServer.canvas_item_add_texture_rect(drawSymbol,rect,outlineTex(),false,Color(Color.WHITE,animAlpha))
	match type:
		KeyBulk.TYPE.NORMAL, KeyBulk.TYPE.EXACT:
			if !M.eq(count, M.ONE): TextDraw.outlined2(FKEYBULK,drawSymbol,M.str(count),keycountColor(),keycountOutlineColor(),14,Vector2(1,25))
		KeyBulk.TYPE.ROTOR:
			if reciprocal:
				if M.eq(count, M.nONE): RenderingServer.canvas_item_add_texture_rect(drawSymbol,rect,RECIPROCAL_FLIP_SYMBOL)
				elif M.eq(count, M.I): RenderingServer.canvas_item_add_texture_rect(drawSymbol,rect,RECIPROCAL_POS_SYMBOL)
				elif M.eq(count, M.nI): RenderingServer.canvas_item_add_texture_rect(drawSymbol,rect,RECIPROCAL_NEG_SYMBOL)
				elif M.eq(count, M.ONE): RenderingServer.canvas_item_add_texture_rect(drawSymbol,rect, RECIPROCAL__SYMBOL)
			else:
				if M.eq(count, M.nONE) or M.eq(count,M.ONE): RenderingServer.canvas_item_add_texture_rect(drawSymbol,rect,SIGNFLIP_SYMBOL)
				elif M.eq(count, M.I): RenderingServer.canvas_item_add_texture_rect(drawSymbol,rect,POSROTOR_SYMBOL)
				elif M.eq(count, M.nI): RenderingServer.canvas_item_add_texture_rect(drawSymbol,rect,NEGROTOR_SYMBOL)
		KeyBulk.TYPE.OPERATOR:
			drawOperationSymbol(drawAdditional,drawAdditionalGlitch,Vector2.ZERO,altColor,mode,glitchMimic)
	if infinite:
		if glistening:
			RenderingServer.canvas_item_add_texture_rect(drawSymbol,Rect2(Vector2(MULTITYPEOFFSET,-MULTITYPEOFFSET), size),INFINITE_SYMBOL)
		else:
			RenderingServer.canvas_item_add_texture_rect(drawSymbol,rect,INFINITE_SYMBOL)
		if infinite > 1:
			var string:String = ""
			if partialInfiniteCount: string = str(infinite-partialInfiniteCount)
			string += "/%s" % infinite
			TextDraw.outlined2(FKEYBULK,drawSymbol,string,Color("#ebe3dd"),Color("#363029"),14,Vector2(28,8))
	if glistening:
		if infinite:
			RenderingServer.canvas_item_add_texture_rect(drawSymbol,Rect2(Vector2(-MULTITYPEOFFSET,MULTITYPEOFFSET), size),GLISTENING_SYMBOL)
		else:
			RenderingServer.canvas_item_add_texture_rect(drawSymbol,rect,GLISTENING_SYMBOL)

func keycountColor() -> Color: return Color("#363029") if M.negative(M.sign(count)) else Color("#ebe3dd")
func keycountOutlineColor() -> Color: return Color("#d6cfc9") if M.negative(M.sign(count)) else Color("#363029")

static func keyTextureType(keyType:TYPE, keyUn:bool) -> KeyTextureLoader.TYPE:
	match keyType:
		TYPE.EXACT: return KeyTextureLoader.TYPE.EXACT
		TYPE.STAR: return KeyTextureLoader.TYPE.UNSTAR if keyUn else KeyTextureLoader.TYPE.STAR
		TYPE.CURSE: return KeyTextureLoader.TYPE.UNCURSE if keyUn else KeyTextureLoader.TYPE.CURSE
		TYPE.OPERATOR: return KeyTextureLoader.TYPE.OPERATOR
		_: return KeyTextureLoader.TYPE.NORMAL

static func operationTextureType(keyMode:OPERATION) -> OperatorTextureLoader.TYPE:
	match keyMode:
		OPERATION.ADD: return OperatorTextureLoader.TYPE.ADD
		OPERATION.SUBTRACT: return OperatorTextureLoader.TYPE.SUBTRACT
		OPERATION.MULTIPLY: return OperatorTextureLoader.TYPE.MULTIPLY
		OPERATION.DIVIDE: return OperatorTextureLoader.TYPE.DIVIDE
		OPERATION.MODULO: return OperatorTextureLoader.TYPE.MODULO
		_: return OperatorTextureLoader.TYPE.SET

static func drawKey(keyDrawGlitch:RID,keyDrawMain:RID, keyOffset:Vector2,keyColor:Game.COLOR,keyType:TYPE=TYPE.NORMAL,keyUn:bool=false,keyGlitchMimic:Game.COLOR=Game.COLOR.GLITCH,keyPartialInfiniteAlpha:float=1) -> void:
	var rect:Rect2 = Rect2(keyOffset, Vector2(32,32))
	var textureType:KeyTextureLoader.TYPE = keyTextureType(keyType, keyUn)
	RenderingServer.canvas_item_set_modulate(keyDrawMain, Color(Color.WHITE, keyPartialInfiniteAlpha))
	RenderingServer.canvas_item_set_modulate(keyDrawGlitch, Color(Color.WHITE, keyPartialInfiniteAlpha))
	if keyColor in TEXTURE_COLORS:
		RenderingServer.canvas_item_add_texture_rect(keyDrawMain,rect,TEXTURE.current([keyColor,textureType]))
	elif keyColor == Game.COLOR.GLITCH:
		RenderingServer.canvas_item_add_texture_rect(keyDrawGlitch,rect,FRAME_GLITCH.current([textureType]))
		RenderingServer.canvas_item_add_texture_rect(keyDrawGlitch,rect,FILL.current([textureType]),false,Game.mainTone[keyColor])
		if keyType == TYPE.CURSE: RenderingServer.canvas_item_add_texture_rect(keyDrawGlitch,rect,CURSE_FILL_DARK,false,Game.darkTone[keyColor])
		if keyGlitchMimic != Game.COLOR.GLITCH:
			if keyGlitchMimic in TEXTURE_COLORS: RenderingServer.canvas_item_add_texture_rect(keyDrawMain,rect,GLITCH.current([keyGlitchMimic,textureType]))
			else: RenderingServer.canvas_item_add_texture_rect(keyDrawMain,rect,FILL_GLITCH.current([textureType]),false,Game.mainTone[keyGlitchMimic])
	else:
		RenderingServer.canvas_item_add_texture_rect(keyDrawMain,rect,FRAME.current([textureType]))
		RenderingServer.canvas_item_add_texture_rect(keyDrawMain,rect,FILL.current([textureType]),false,Game.mainTone[keyColor])
		if keyType == TYPE.CURSE and !keyUn: RenderingServer.canvas_item_add_texture_rect(keyDrawMain,rect,CURSE_FILL_DARK,false,Game.darkTone[keyColor])

static func drawOperationSymbol(keyDrawAdditonal:RID, keyDrawGlitch:RID, keyOffset:Vector2, partColor:Game.COLOR, keyMode:OPERATION=OPERATION.SET,keyGlitchMimic:Game.COLOR=Game.COLOR.GLITCH):
	var rect:Rect2 = Rect2(keyOffset, Vector2(32,32))
	var textureType:OperatorTextureLoader.TYPE = operationTextureType(keyMode)
	if partColor in TEXTURE_COLORS:
		RenderingServer.canvas_item_add_texture_rect(keyDrawAdditonal,rect,OPERATION_TEXTURE.current([partColor,textureType]))
	elif partColor == Game.COLOR.GLITCH:
		RenderingServer.canvas_item_add_texture_rect(keyDrawGlitch,rect,OPERATOR_FRAME_GLITCH.current([textureType]))
		RenderingServer.canvas_item_add_texture_rect(keyDrawGlitch,rect,OPERATOR_FILL.current([textureType]),false,Game.mainTone[partColor])
		if keyGlitchMimic != Game.COLOR.GLITCH:
			if keyGlitchMimic in TEXTURE_COLORS: RenderingServer.canvas_item_add_texture_rect(keyDrawAdditonal,rect,OPERATION_GLITCH.current([keyGlitchMimic,textureType]))
			else: 
				RenderingServer.canvas_item_add_texture_rect(keyDrawAdditonal,rect,OPERATOR_FILL_GLITCH.current([textureType]),false,Game.mainTone[keyGlitchMimic])
	else:
		RenderingServer.canvas_item_add_texture_rect(keyDrawAdditonal,rect,OPERATOR_FRAME.current([textureType]))
		RenderingServer.canvas_item_add_texture_rect(keyDrawAdditonal,rect,OPERATOR_FILL.current([textureType]),false,Game.mainTone[partColor])

func propertyChangedInit(property:StringName) -> void:
	if property == &"type":
		if type not in [TYPE.NORMAL, TYPE.EXACT] and M.neq(count, M.ONE): Changes.addChange(Changes.PropertyChange.new(self,&"count",M.ONE))
		if type not in [TYPE.STAR, TYPE.CURSE] and un: Changes.addChange(Changes.PropertyChange.new(self,&"un",false))
		if type != TYPE.ROTOR: Changes.addChange(Changes.PropertyChange.new(self,&"reciprocal",false))
		if type == TYPE.OPERATOR: Changes.addChange(Changes.PropertyChange.new(self,&"altColor",color))
	if property == &"reciprocal":
		if reciprocal and M.eq(count, M.nONE): Changes.addChange(Changes.PropertyChange.new(self,&"count",M.ONE))
		if !reciprocal and M.eq(count, M.ONE): Changes.addChange(Changes.PropertyChange.new(self,&"count",M.nONE))

# ==== PLAY ==== #
var glitchMimic:Game.COLOR = Game.COLOR.GLITCH
var partialInfiniteCount:int = 0

enum ANIM_STATE {IDLE, FLASH}
var animState:ANIM_STATE = ANIM_STATE.IDLE
var animAlpha:float = 0
var partialInfiniteAlpha:float = 1

func _process(delta:float) -> void:
	match animState:
		ANIM_STATE.IDLE: animAlpha = 0
		ANIM_STATE.FLASH:
			animAlpha -= delta*6
			if animAlpha <= 0: animState = ANIM_STATE.IDLE
			queue_redraw()
	if infinite > 1:
		if !partialInfiniteCount and partialInfiniteAlpha < 1:
			partialInfiniteAlpha = min(partialInfiniteAlpha+delta*6, 1)
			queue_redraw()
		elif partialInfiniteCount and partialInfiniteAlpha > 0.5:
			partialInfiniteAlpha = max(partialInfiniteAlpha-delta*6, 0.5)
			queue_redraw()

func stop() -> void:
	glitchMimic = Game.COLOR.GLITCH
	partialInfiniteCount = 0
	partialInfiniteAlpha = 1
	super()

func collect(player:Player) -> void:
	if partialInfiniteCount: return
	var collectColor:Game.COLOR = effectiveColor(color)

	if glistening:
		match type:
			TYPE.NORMAL: player.changeGlisten(collectColor, M.add(player.glisten[collectColor], count))
			TYPE.EXACT: player.changeGlisten(collectColor, count)
			TYPE.ROTOR:
				if reciprocal: player.changeGlisten(collectColor, M.divide(count,player.glisten[collectColor]))
				else: player.changeGlisten(collectColor, M.times(player.glisten[collectColor], count))

	match type:
		TYPE.NORMAL: player.changeKeys(collectColor, M.add(player.key[collectColor], count))
		TYPE.EXACT: player.changeKeys(collectColor, count)
		TYPE.ROTOR:
			if reciprocal: player.changeKeys(collectColor, M.divide(count,player.key[collectColor]))
			else: player.changeKeys(collectColor, M.times(player.key[collectColor], count))
		TYPE.STAR: GameChanges.addChange(GameChanges.StarChange.new(effectiveColor(color), !un))
		TYPE.CURSE: GameChanges.addChange(GameChanges.CurseChange.new(effectiveColor(color), !un))
		TYPE.OPERATOR:
			match mode:
				OPERATION.SET: player.changeKeys(collectColor, player.key[effectiveColor(altColor)])
				OPERATION.ADD: player.changeKeys(collectColor, M.add(player.key[collectColor], player.key[effectiveColor(altColor)]))
				OPERATION.SUBTRACT: player.changeKeys(collectColor, M.sub(player.key[collectColor], player.key[effectiveColor(altColor)]))
				OPERATION.MULTIPLY: player.changeKeys(collectColor, M.times(player.key[collectColor], player.key[effectiveColor(altColor)]))
				OPERATION.DIVIDE: player.changeKeys(collectColor, M.divide(player.key[collectColor], player.key[effectiveColor(altColor)]))
				OPERATION.MODULO: player.changeKeys(collectColor, M.remainder(player.key[collectColor], player.key[effectiveColor(altColor)]))
	
	if infinite:
		flashAnimation()
		GameChanges.addChange(GameChanges.PropertyChange.new(self, &"partialInfiniteCount", infinite))
	else: GameChanges.addChange(GameChanges.PropertyChange.new(self, &"active", false))
	for object in Game.objects.values():
		if object is KeyBulk and object.infinite and object.partialInfiniteCount > 0:
			GameChanges.addChange(GameChanges.PropertyChange.new(object, &"partialInfiniteCount", object.partialInfiniteCount - 1))
	GameChanges.bufferSave()

	if color == Game.COLOR.MASTER: # not effectiveColor; doesnt trigger on glitch master
		AudioManager.play(preload("res://resources/sounds/key/master.wav"))
	else:
		match type:
			TYPE.ROTOR: AudioManager.play(preload("res://resources/sounds/key/signflip.wav"))
			TYPE.STAR:
				if un: AudioManager.play(preload("res://resources/sounds/key/unstar.wav"))
				else: AudioManager.play(preload("res://resources/sounds/key/star.wav"))
			_:
				if M.negative(M.sign(count)): AudioManager.play(preload("res://resources/sounds/key/negative.wav"))
				else: AudioManager.play(preload("res://resources/sounds/key/normal.wav"))

func setGlitch(setColor:Game.COLOR) -> void:
	GameChanges.addChange(GameChanges.PropertyChange.new(self, &"glitchMimic", setColor))
	queue_redraw()

func flashAnimation() -> void:
	animState = ANIM_STATE.FLASH
	animAlpha = 1

func propertyGameChangedDo(property:StringName) -> void:
	if property == &"active":
		%interact.process_mode = PROCESS_MODE_INHERIT if active else PROCESS_MODE_DISABLED

func effectiveColor(part:Game.COLOR) -> Game.COLOR:
	if part == Game.COLOR.GLITCH: return glitchMimic
	return part
