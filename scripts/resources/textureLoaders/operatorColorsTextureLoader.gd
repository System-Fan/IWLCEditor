extends ColorsTextureLoader
class_name OperatorColorsTextureLoader

func initLoader(path:String,frames:int,params:Dictionary) -> OperatorTextureLoader:
	return OperatorTextureLoader.new(path,params.capitalised,frames)
