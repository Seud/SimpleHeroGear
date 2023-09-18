class_name CharacterInfoPreloader
extends ResourcePreloader

const BASE_DIR = "res://src/characters/info/"

# Called when the node enters the scene tree for the first time.
func _ready():
	# Load all resources
	var dir = DirAccess.open(BASE_DIR)
	assert(dir, "Cannot access path to preload CharacterInfo resources, is BASE_DIR correct ?")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				var resource = load(BASE_DIR + file_name)
				if resource is CharacterInfo:
					add_resource(resource.id, resource)
			file_name = dir.get_next()
