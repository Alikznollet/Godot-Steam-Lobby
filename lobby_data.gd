extends Resource
class_name LobbyData
## Settings that are important for starting the game
##
## It's important that the variable names match the names we use in the Steam Lobby.
## When adding a variable don't forget to also add it to the get_data() function.

signal game_started()

## Name of the lobby.
var lobby_name: String = ""

## Size of the world we'll be playing on.
var world_size: int = 5

## Whether the game has started or not.
var started: bool = false:
	set(new_started):
		if not started and new_started: # If started flips to true we will emit the signal.
			game_started.emit()
		started = new_started

## Fill the LobbyData with incoming data.
func update_data(data: Dictionary) -> void:
	for i in data:
		var body: Dictionary = data[i]

		if typeof(get(body.key)) != TYPE_STRING:
			set(body.key, str_to_var(body.value))
		else:
			set(body.key, body.value)

## Export the LobbyData to a Dictionary that can be used to set the Steam Lobby Data.
func get_data() -> Dictionary[String, String]:
	return {
		"lobby_name": lobby_name,
		"world_size": str(world_size),
		"started": str(started).to_lower()
	}

## This is exclusively meant for when we send the data over rpc.
func to_dictionary() -> Dictionary:
	return {
		"lobby_name": lobby_name,
		"world_size": world_size,
		"started": started
	}

## Same goes here as for above function.
static func from_dictionary(dictionary: Dictionary) -> LobbyData:
	var lobby_data: LobbyData = LobbyData.new()
	for key in dictionary:
		lobby_data.set(key, dictionary[key])
	return lobby_data
