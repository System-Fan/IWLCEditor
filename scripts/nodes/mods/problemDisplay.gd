extends VBoxContainer
class_name ProblemDisplay

var modId:StringName
var mod:Mods.Mod
var type:StringName
var findProblems:FindProblems
var showIndex:int = 0
var count:int:
	get(): return len(mod.problems[type])

func setup(_mod:StringName,_type:StringName, _findProblems:FindProblems) -> ProblemDisplay:
	modId = _mod
	mod = Mods.mods[modId]
	type = _type
	findProblems = _findProblems
	%nameLabel.text = getProblemName()
	return self

func setTexts() -> void:
	if count == 1: %countLabel.text = "1 instance"
	else: %countLabel.text = str(count) + " instances"
	%showIndex.text = str(showIndex+1) + "/" + str(count)
	visible = count > 0

func getProblemName() -> String:
	match [modId, type]:
		[&"MoreLockSizes", &"NstdLockSize"]: return "Nonstandard Lock Size"
		[&"MoreLockConfigs", &"NstdLockConfig"]: return "Nonstandard Lock Configuration"
		[&"ZeroCopyDoors",&"ZeroCopyDoor"]: return "Zero Copy Door"
		[&"ZeroCostLocks",&"ZeroCostLock"]: return "Zero Cost Lock"
		[&"InfCopyDoors",&"InfCopyDoor"]: return "Infinite Copy Door"
		[&"NoneColor",&"NoneColorUsed"]: return "None Color Used"

		[&"RemoteLocks", &"RemoteLock"]: return "Remote Lock"
		[&"NegatedLocks", &"NegatedLock"]: return "Negated Lock"
		[&"DynamiteColor", &"DynamiteColorUsed"]: return "Dynamite Color Used"
		[&"QuicksilverColor", &"QuicksilverColorUsed"]: return "Quicksilver Color Used"
		[&"PartialBlastLocks", &"PartialBlastLock"]: return "Partial Blast Lock"
		[&"ExactLocks", &"ExactLock"]: return "Exact Lock"
		[&"DarkAuraColors", &"DarkAuraColorUsed"]: return "Dark Aura Color Used"
		[&"AuraBreakerColors", &"AuraBreakerColorUsed"]: return "Aura Breaker Color Used"
		[&"CurseKeys", &"CurseKey"]: return "Curse/Decurse Key"
		[&"Armaments", &"LockArmament"]: return "Lock Armament"
		[&"RemainderLocks", &"RemainderLock"]: return "Remainder Lock"

		[&"DisconnectedLocks", &"DisconnectedLock"]: return "Disconnected Lock"
		[&"OutOfBounds", &"OutOfBounds"]: return "Object Out of Bounds"
		
		[&"PartialInPartialInfKeysfKey", &"PartialInfKey"]: return "Partial Infinite Key"
		[&"MoreKeyCounterWidths", &"NstdKeyCounterWidth"]: return "Nonstandard Key Counter Width"
		[&"OperatorKeys", &"OperatorKey"]: return "Operator Key"
		[&"OperatorKeys", &"ReciprocalKey"]: return "Reciprocal Key"
	return "Somebody forgot to set the ProblemDisplay text for this error :)"

func showInstance(index:int) -> void:
	showIndex = index
	setTexts()
	var component:GameComponent = mod.problems[type][index]
	if component is GameObject:
		Game.editor.focusDialog.defocusComponent()
		Game.editor.focusDialog.focus(component,true)
	else: Game.editor.focusDialog.focusComponent(component)
	Game.editor.scrollIntoView(component)

func _showPressed():
	%shower.visible = true
	%show.visible = false
	if findProblems.shownDisplay: findProblems.shownDisplay.stopShowing()
	findProblems.shownDisplay = self
	showInstance(0)

func stopShowing() -> void:
	if findProblems.shownDisplay != self: return
	findProblems.shownDisplay = null
	%show.visible = true
	%shower.visible = false

func _showLeft(): showInstance(posmod(showIndex-1,count))
func _showRight(): showInstance(posmod(showIndex+1,count))

func newInstance() -> void: setTexts()

func removeInstance(index:int) -> void:
	if count == 0:
		visible = false
		findProblems.problemsLabel.text = "Problems found:" if mod.hasProblems() else "No problems here"
		return
	if showIndex > index: showIndex -= 1
	elif showIndex == count: showInstance(index-1)
	elif showIndex == index: showInstance(index)
	setTexts()
