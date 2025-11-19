extends Node
## Global script that holds the lobby info for the player to read.

## Signal the menu can be hooked up to so it can listen for updated.
signal lobby_data_changed(lobby_data: LobbyData)
signal lobby_confirmed()
signal lobby_left()

## The maximum members that can connect to the lobby.
const max_members: int = 10

## Path to the lobby caching file.
const lobby_cache_path: String = "user://lobby_cache/lobby.txt"

## The ID of the lobby entered. If 0 the client is not in a Steam lobby.
var lobby_id: int = 0:
	set(new_lobby_id):
		lobby_id = new_lobby_id

		# If lobby is left intentionally we will delete the file.
		if lobby_id == 0:
			DirAccess.remove_absolute(lobby_cache_path)
		else:
			var file: FileAccess = FileAccess.open(lobby_cache_path, FileAccess.WRITE)
			assert(file, "SteamLobby: Could not open lobby cache.")

			file.store_64(lobby_id)
			file.close()

## The Members in the lobby.
var lobby_members: Array = []

## Settings of the current lobby, null if no lobby.
var lobby_data: LobbyData

func _ready() -> void:
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.join_requested.connect(_on_lobby_join_requested)
	Steam.persona_state_change.connect(_on_persona_change)
	Steam.lobby_data_update.connect(_lobby_data_updated)

	_load_lobby_id_from_cache()

## Will load the lobby_id from the cache if there is a cache.
## There should only be a cache when the player had quit during a previous game without leaving gracefully.
func _load_lobby_id_from_cache() -> void:
	if not FileAccess.file_exists(lobby_cache_path): return

	var file: FileAccess = FileAccess.open(lobby_cache_path, FileAccess.READ)
	assert(file, "SteamLobby: Could not open lobby cache.")

	var v_lobby_id: int = file.get_64()
	file.close()

	join_lobby(v_lobby_id)

## Will create a lobby.
func create_lobby(lobby_type: Steam.LobbyType, lobby_name: String) -> void:
	if lobby_id == 0:
		lobby_data = LobbyData.new()
		lobby_data.lobby_name = lobby_name
		Steam.createLobby(lobby_type, max_members)

## Ran when Steam sees that a lobby was created.
func _on_lobby_created(connected: int, this_lobby_id: int) -> void:
	if connected == 1:
		# Set the lobby ID
		lobby_id = this_lobby_id

		# Set some lobby data.
		Steam.setLobbyJoinable(lobby_id, true)
		update_lobby_data()

		# Allow P2P connections to fallback to being relayed through Steam if needed
		Steam.allowP2PPacketRelay(true)
		lobby_confirmed.emit()

## Will join a lobby.
func join_lobby(this_lobby_id: int) -> void:
	# Clear any previous lobby members lists, if you were in a previous lobby
	lobby_members.clear()

	# Make the lobby join request to Steam
	Steam.joinLobby(this_lobby_id)

## Ran when Steam sees that the user has joined a lobby.
func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	# If joining was successful
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		# Set this lobby ID as your lobby ID
		lobby_id = this_lobby_id
		lobby_data = LobbyData.new()

		# Get the lobby members
		_get_lobby_members()
		_fill_lobby_data()
		lobby_confirmed.emit()

	# Else it failed for some reason
	else:
		push_warning("Something went wrong while trying to join the lobby with ID=%d" % this_lobby_id)
		lobby_id = 0 # We do this so the file caching the lobby_id is deleted.

## When a join is requested through a friend we will run this.
func _on_lobby_join_requested(this_lobby_id: int, _friend_id: int) -> void:
	# Attempt to join the lobby
	join_lobby(this_lobby_id)

## If in a lobby we leave the lobby and reset all fields.
func leave_lobby() -> void:
	if lobby_id != 0:
		Steam.leaveLobby(lobby_id)
		lobby_id = 0
		lobby_members.clear()
		lobby_data = null
		lobby_left.emit()

## If a player's persona changes we need to update the members list.
func _on_persona_change(_this_steam_id: int, _flag: int) -> void:
	if lobby_id > 0:
		_get_lobby_members()

## Fills the lobby_members field with the current members of the lobby.
func _get_lobby_members() -> void:
	# Clear your previous lobby list
	lobby_members.clear()

	# Get the number of members from this lobby from Steam
	var num_of_members: int = Steam.getNumLobbyMembers(lobby_id)

	# Get the data of these players from Steam
	for this_member in range(0, num_of_members):
		# Get the member's Steam ID
		var member_steam_id: int = Steam.getLobbyMemberByIndex(lobby_id, this_member)

		# Get the member's Steam name
		var member_steam_name: String = Steam.getFriendPersonaName(member_steam_id)

		# Add them to the list
		lobby_members.append({"steam_id":member_steam_id, "steam_name":member_steam_name})

## Sends new local lobby data to Steam.
func update_lobby_data() -> void:
	if lobby_id == 0: return

	var data: Dictionary = lobby_data.get_data()
	for key in data:
		Steam.setLobbyData(lobby_id, key, data[key])

## Called when Steam receives new lobby data.
func _lobby_data_updated(_success: int, _lobby_id: int, _member_id: int) -> void:
	_fill_lobby_data()

## Called when Steam's lobby data is updated.
## Will update the current local lobby data with the new data.
func _fill_lobby_data() -> void:
	assert(lobby_data, "SteamLobby: No LobbyData was set.")

	# Steams LobbyData dictionary has a weird structure so we will simplify it.
	var result: Dictionary[String, String] = {}
	for entry in Steam.getAllLobbyData(lobby_id).values():
		result[entry.key] = entry.value

	lobby_data.update_data(result)
	lobby_data_changed.emit(lobby_data)
