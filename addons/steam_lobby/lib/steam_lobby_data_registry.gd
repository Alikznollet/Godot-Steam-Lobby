extends Node
class_name SteamLobbyDataRegistry
## Database for all SteamLobbyData types.
##
## Get an instance with init_from_stringname()

## ID to SCRIPT for any LobbyData class.
static var _id_to_script: Dictionary = {}

## SCRIPT to ID for any LobbyData class.
static var _script_to_id: Dictionary = {}

## Registers all LobbyData classes into the Registry with assigned ID.
static func _static_init() -> void:
	var state_classes: Array = []
	for cls in ProjectSettings.get_global_class_list():
		if cls.base == "SteamLobbyData":
			state_classes.append(cls)

	state_classes.sort_custom(func(a, b): return a["class"] < b["class"])

	for i in range(state_classes.size()):
		var data = state_classes[i]
		var path = data.path
		var resource = load(path)

		_id_to_script[i] = resource
		_script_to_id[resource] = i

# -- PUBLIC -- #

## Returns the ID for a certain LobbyData class script.
static func get_id(lobby_data_script: Script) -> int:
	assert(_script_to_id.has(lobby_data_script), "LinkStateRegistry: No existing mapping for LobbyData %s." % lobby_data_script.get_global_name())

	return _script_to_id[lobby_data_script]

## Returns the script for a certain ID, null if the id does not exist.
static func get_script_from_id(id: int) -> Script:
	return _id_to_script.get(id, null)
