extends PanelContainer
class_name FindProblems

@onready var modsWindow:ModsWindow = get_parent()
@onready var problemsLabel:Label = %problemsLabel
var buttonGroup:ButtonGroup = ButtonGroup.new()
var firstButton:bool = false

var problems:int = 0:
	set(value):
		problems = value
		%saveChanges.disabled = problems > 0
		if problems == 0: %saveChanges.text = "Save Changes"
		elif problems == 1: %saveChanges.text = "1 problem"
		else: %saveChanges.text = str(problems) + " problems"

var problemDisplays:Dictionary[StringName,Dictionary] = {} # Dictionary[mod, Dictionary[type, problemdisplay]]
var shownDisplay:ProblemDisplay
var isReady:bool = false

func _ready() -> void:
	buttonGroup.pressed.connect(_modSelected)

func setup() -> void:
	isReady = false
	Game.editor.findProblems = self
	firstButton = true
	problems = 0
	for child in %modsAdded.get_children(): child.queue_free()
	for child in %modsRemoved.get_children(): child.queue_free()
	for mod in Mods.mods.values(): mod.clearProblems()
	
	problemDisplays = {}
	for mod in Mods.mods.keys():
		problemDisplays[mod] = {}
		for problemType in Mods.mods[mod].problems.keys():
			problemDisplays[mod][problemType] = preload("res://scenes/problemDisplay.tscn").instantiate().setup(mod,problemType,self)
	
	for object in Game.objects.values():
		object.problems.clear()
		findProblems(object)
	for component in Game.components.values():
		component.problems.clear()
		findProblems(component)
	for mod in Mods.mods.keys():
		if mod in modsWindow.modsAdded: %modsAdded.add_child(ModSelectButton.new(self,mod))
		elif mod in modsWindow.modsRemoved: %modsRemoved.add_child(ModSelectButton.new(self,mod))
	isReady = true

func _modSelected(button:ModSelectButton) -> void:
	%modName.text = button.mod.name
	var anyProblems:bool = false
	for child in %problems.get_children(): %problems.remove_child(child)
	if shownDisplay: shownDisplay.stopShowing()

	for problemType in button.mod.problems.keys():
		%problems.add_child(problemDisplays[button.modId][problemType])
		problemDisplays[button.modId][problemType].setTexts()
		if len(button.mod.problems[problemType]) != 0:
			anyProblems = true
	%problemsLabel.text = "Problems found:" if anyProblems else "No problems here"

func findProblems(component:GameComponent) -> void:
	if component is Lock:
		if &"DisconnectedLocks" in modsWindow.modsRemoved:
			var rect:Rect2 = Rect2(component.position, component.size)
			var bounds:Rect2 = Rect2(component.getOffset(), component.parent.size)
			noteProblem(&"DisconnectedLocks", &"DisconnectedLock", component, !bounds.intersects(rect))
	else:
		if &"OutOfBounds" in modsWindow.modsRemoved:
			var rect:Rect2 = Rect2(component.position, component.size)
			noteProblem(&"OutOfBounds", &"OutOfBounds", component, !Game.levelBounds.intersects(rect))

	match component.get_script():
		KeyBulk:
			findColorProblems(component, component.color)
			if &"CurseKeys" in modsWindow.modsRemoved:
				noteProblem(&"CurseKeys", &"CurseKey", component, component.type == KeyBulk.TYPE.CURSE)
			if &"PartialInfKeys" in modsWindow.modsRemoved:
				noteProblem(&"PartialInfKeys", &"PartialInfKey", component, component.infinite not in [0, 1])
			if &"Glistening" in modsWindow.modsRemoved:
				noteProblem(&"Glistening", &"GlisteningKey", component, component.glistening)
			if &"OperatorKeys" in modsWindow.modsRemoved:
				noteProblem(&"OperatorKeys", &"OperatorKey", component, component.type == KeyBulk.TYPE.OPERATOR)
				noteProblem(&"OperatorKeys", &"ReciprocalKey", component, component.type == KeyBulk.TYPE.ROTOR and component.reciprocal)
		Lock, RemoteLock:
			findColorProblems(component, component.color)
			if component is Lock:
				if &"MoreLockSizes" in modsWindow.modsRemoved:
					noteProblem(&"MoreLockSizes", &"NstdLockSize", component, component.parent.type != Door.TYPE.SIMPLE and component.size not in Lock.SIZES)
				if &"MoreLockConfigs" in modsWindow.modsRemoved:
					noteProblem(&"MoreLockConfigs", &"NstdLockConfig", component, component.parent.type != Door.TYPE.SIMPLE and component.configuration in [
						Lock.CONFIGURATION.spr7A, Lock.CONFIGURATION.spr9A, Lock.CONFIGURATION.spr9B, Lock.CONFIGURATION.spr10A, Lock.CONFIGURATION.spr11A, Lock.CONFIGURATION.spr13A,
						Lock.CONFIGURATION.spr24B
					])
			if &"ZeroCostLocks" in modsWindow.modsRemoved:
				noteProblem(&"ZeroCostLocks", &"ZeroCostLock", component, M.nex(component.count))
			if &"RemoteLocks" in modsWindow.modsRemoved:
				noteProblem(&"RemoteLocks", &"RemoteLock", component, component is RemoteLock)
			if &"NegatedLocks" in modsWindow.modsRemoved:
				noteProblem(&"NegatedLocks", &"NegatedLock", component, component.negated)
			if &"PartialBlastLocks" in modsWindow.modsRemoved:
				noteProblem(&"PartialBlastLocks", &"PartialBlastLock", component, \
					component.type == Lock.TYPE.BLAST and (component.isPartial or M.neq(component.count, component.denominator)) \
					or component.type == Lock.TYPE.ALL and (component.isPartial or M.neq(component.count, M.ONE) or M.neq(component.denominator, M.ONE)))
			if &"ExactLocks" in modsWindow.modsRemoved:
				noteProblem(&"ExactLocks", &"ExactLock", component, component.type == Lock.TYPE.EXACT)
			if &"Armaments" in modsWindow.modsRemoved:
				noteProblem(&"Armaments", &"LockArmament", component, component.armament)
			if &"RemainderLocks" in modsWindow.modsRemoved:
				noteProblem(&"RemainderLocks", &"RemainderLock", component, component.type == Lock.TYPE.REMAINDER)
			if &"Glistening" in modsWindow.modsRemoved:
				noteProblem(&"Glistening", &"GlisteningLock", component, component.type == Lock.TYPE.GLISTENING)
		Door:
			findColorProblems(component, component.colorSpend)
			if &"ZeroCopyDoors" in modsWindow.modsRemoved:
				noteProblem(&"ZeroCopyDoors", &"ZeroCopyDoor", component, M.nex(component.copies))
			if &"InfCopyDoors" in modsWindow.modsRemoved:
				noteProblem(&"InfCopyDoors", &"InfCopyDoor", component, M.ex(component.infCopies))
		KeyCounter:
			if &"MoreKeyCounterWidths" in modsWindow.modsRemoved:
				noteProblem(&"MoreKeyCounterWidths", &"NstdKeyCounterWidth", component, KeyCounter.WIDTH_AMOUNT.find(component.size.x) in [KeyCounter.WIDTH.VLONG, KeyCounter.WIDTH.EXLONG])
		KeyCounterElement:
			findColorProblems(component, component.color)

func findColorProblems(component:GameComponent, color:Game.COLOR) -> void:
	if &"NoneColor" in modsWindow.modsRemoved: noteProblem(&"NoneColor", &"NoneColorUsed", component, color == Game.COLOR.NONE)
	if &"DynamiteColor" in modsWindow.modsRemoved: noteProblem(&"DynamiteColor", &"DynamiteColorUsed", component, color == Game.COLOR.DYNAMITE)
	if &"QuicksilverColor" in modsWindow.modsRemoved: noteProblem(&"QuicksilverColor", &"QuicksilverColorUsed", component, color == Game.COLOR.QUICKSILVER)
	if &"DarkAuraColors" in modsWindow.modsRemoved: noteProblem(&"DarkAuraColors", &"DarkAuraColorUsed", component, color in [Game.COLOR.MAROON, Game.COLOR.FOREST, Game.COLOR.NAVY])
	if &"AuraBreakerColors" in modsWindow.modsRemoved: noteProblem(&"AuraBreakerColors", &"AuraBreakerColorUsed", component, color in [Game.COLOR.ICE, Game.COLOR.MUD, Game.COLOR.GRAFFITI])

func noteProblem(mod:StringName, type:StringName, component:GameComponent, isProblem:bool) -> void:
	var problem:Array = [mod, type]
	if isProblem and problem not in component.problems:
		component.problems.append(problem)
		Mods.mods[mod].problems[type].append(component)
		problems += 1
		if isReady: problemDisplays[mod][type].newInstance()
	elif !isProblem and problem in component.problems:
		component.problems.erase(problem)
		var index = Mods.mods[mod].problems[type].find(component)
		Mods.mods[mod].problems[type].remove_at(index)
		problems -= 1
		if isReady: problemDisplays[mod][type].removeInstance(index)
	if isReady: Mods.mods[mod].selectButton.setIcon()

func componentRemoved(component:GameComponent) -> void:
	for problem in component.problems:
		noteProblem(problem[0], problem[1], component, false)

class ModSelectButton extends Button:
	const NO_PROBLEM:Texture2D = preload("res://assets/ui/mods/noProblem.png")
	const PROBLEM:Texture2D = preload("res://assets/ui/mods/problem.png")

	var findProblems:FindProblems
	var modId:StringName
	var mod:Mods.Mod

	func _init(_findProblems:FindProblems, _modId:StringName) -> void:
		toggle_mode = true
		findProblems = _findProblems
		button_group = findProblems.buttonGroup
		modId = _modId
		mod = Mods.mods[modId]
		mod.selectButton = self
		text = mod.name
		setIcon()
		theme_type_variation = &"RadioButtonText"
		if findProblems.firstButton:
			button_pressed = true
			findProblems.firstButton = false

	func setIcon() -> void:
		if mod.hasProblems(): icon = PROBLEM
		else: icon = NO_PROBLEM
