extends Node
## Database for all SteamLobbyData types.
##
## Get an instance with init_from_stringname()

## Carries all types of user defined SteamLobbyData
var TYPES_LOBBY_DATA: Dictionary[StringName, GDScript] = {}

func _init() -> void:
	# Load all custom LinkState classes as scripts that can be instantiated.
	for cls in ProjectSettings.get_global_class_list():
		if cls.base == "SteamLobbyData":
			TYPES_LOBBY_DATA[cls["class"]] = load(cls.path)

# -- Retrieval -- #

## Will return an empty SteamLobbyData resource derived
## from the given class_name, if it exists.
func init_from_stringname(stringname: StringName) -> SteamLobbyData:
	assert(TYPES_LOBBY_DATA.has(stringname), "SteamLobbyDataDB: Class with name %s does not exist." % stringname)

	var lobby_data: SteamLobbyData = TYPES_LOBBY_DATA[stringname].new()
	return lobby_data
