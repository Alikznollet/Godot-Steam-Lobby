extends Node
## SteamLobby
## 
## This script is loaded as an autoload when the plugin is enabled.
## Exposes important functions, signals and variables needed for Steam lobbies.

# -- Constants -- #

## Path to the lobby cache file. Used to rejoin lobbies that were incorrectly left.
const _lobby_cache_path: String = "user://lobby_cache.txt"

# -- Variables -- #

## Maximum users that can be connected to the lobby at once.
## This can be altered before creation of a lobby, not during.
var max_members: int = 10

## The ID of the lobby entered. If 0 the client is not in a Steam lobby.
var lobby_id: int = 0:
	set(new_lobby_id):
		lobby_id = new_lobby_id

		# If lobby is left intentionally we will delete the file and reset LobbyData.
		if lobby_id == 0:
			DirAccess.remove_absolute(_lobby_cache_path)
			lobby_data = null
			_tmp_lobby_data = null
		else:
			var file: FileAccess = FileAccess.open(_lobby_cache_path, FileAccess.WRITE)
			assert(file, "SteamLobby: Could not open lobby cache for write.")

			file.store_64(lobby_id)
			file.close()

## Dictionary mapping Steam ID to SteamUser instances.
## Contains all currently connected users.
var lobby_members: Dictionary[int, SteamUser] = {}

func _ready() -> void:
	# Will initialize the app_id filled in inside of the editor.
	Steam.steamInitEx(ProjectSettings.get_setting("steam/initialization/app_id"), true)

	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.join_requested.connect(_on_lobby_join_requested)
	Steam.persona_state_change.connect(_on_persona_change)
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	Steam.lobby_data_update.connect(_on_lobby_data_steam_update)

	_load_lobby_id_from_cache()

# -- Cache Rejoining -- #

## Will load the lobby_id from the cache if there is a cache.
## There should only be a cache when the player had quit during a previous game without leaving gracefully.
func _load_lobby_id_from_cache() -> void:
	if not FileAccess.file_exists(_lobby_cache_path): return

	var file: FileAccess = FileAccess.open(_lobby_cache_path, FileAccess.READ)
	assert(file, "SteamLobby: Could not open lobby cache for read.")

	var v_lobby_id: int = file.get_64()
	file.close()

	join_lobby(v_lobby_id)

# -- Lobby Creation -- #

## Will create a lobby based on the lobby type provided.
## Types are contained in Steam.LobbyType
func create_lobby(lobby_type: Steam.LobbyType, init_lobby_data: SteamLobbyData) -> void:
	if lobby_id == 0:
		Steam.createLobby(lobby_type, max_members)

		# Update the temporary lobby data.
		_tmp_lobby_data = init_lobby_data

## Ran when Steam sees that a lobby was created.
func _on_lobby_created(connected: int, this_lobby_id: int) -> void:
	if connected == 1:
		# Set the lobby ID
		lobby_id = this_lobby_id

		# Set lobby data and tell the lobby what type of LobbyData is used.
		lobby_data = _tmp_lobby_data
		Steam.setLobbyData(lobby_id, "ld_type", var_to_str(SteamLobbyDataRegistry.get_id(lobby_data.get_script())))
		_on_lobby_data_local_update() # Make sure to trigger a local update after init.
	
# -- Lobby Joining -- #

## Signal emitted when a lobby is joined. This can be either a creation or a join itself.
signal lobby_joined()

## Will try to join the lobby with provided ID.
func join_lobby(lobby_id: int) -> void:
	# Clear any previous lobby members lists, if you were in a previous lobby
	lobby_members.clear()

	# Make the lobby join request to Steam
	Steam.joinLobby(lobby_id)

## Ran when Steam sees that the user has joined a lobby.
func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	# If joining was successful
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		# Set this lobby ID as your lobby ID
		lobby_id = this_lobby_id
		lobby_joined.emit()

		# Get all currently connected members.
		_fetch_lobby_members()

	# If the response was not success
	else:
		lobby_id = 0 # This removes the cached lobby file.
		printerr("SteamLobby: Could not join lobby, response was %d." % response)

## When a join is requested through a friend we will run this.
func _on_lobby_join_requested(this_lobby_id: int, _friend_id: int) -> void:
	# Attempt to join the lobby
	join_lobby(this_lobby_id)

# -- Lobby Leaving -- #

## Emitted when a lobby is left.
signal lobby_left()

## Leave the current lobby if there is one and reset all fields.
func leave_lobby() -> void:
	if lobby_id != 0:
		Steam.leaveLobby(lobby_id)
		lobby_id = 0
		lobby_members.clear()
		lobby_left.emit()

# -- Updates -- #

## Emitted when a user joins the lobby.
signal user_joined(user: SteamUser)

## Emitted when a user leaves the lobby.
signal user_left(user: SteamUser)

## Emitted when a user's metadata is updated.
signal user_updated(user: SteamUser)

## If some player changes it's persona we update that player.
## Flag is ignored here because we don't need to know what was updated.
func _on_persona_change(steam_id: int, _flag: int) -> void:
	if lobby_id > 0:
		if user_in_lobby(steam_id): _update_steam_user(steam_id)

## Updates SteamUser instance linked to steam_id.
func _update_steam_user(steam_id: int) -> void:
	var present: bool = lobby_members.has(steam_id)
	var user: SteamUser
	if present:
		user = lobby_members[steam_id]
	else:
		user = SteamUser.new(steam_id)
		lobby_members[steam_id] = user
	
	# TODO: Add more metadata here.
	user.name = Steam.getFriendPersonaName(steam_id)

	# Emit the correct signal
	if present:
		user_updated.emit(user)
	else:
		user_joined.emit(user)

## Will remove the user with steam_id from the members list.
## This normally means they have left the lobby.
func _remove_steam_user(steam_id: int) -> void:
	if not lobby_members.has(steam_id): return # Doesn't have id so exit gracefully

	var user: SteamUser = lobby_members[steam_id]
	lobby_members.erase(steam_id)

	user_left.emit(user)

## Updates the lobby according to the chat_state.
func _on_lobby_chat_update(this_lobby_id: int, changer_id: int, making_change_id, chat_state: int) -> void:
	# TODO: Handle other important ChatUpdates.
	match chat_state:
		Steam.CHAT_MEMBER_STATE_CHANGE_LEFT:
			_remove_steam_user(changer_id)
		Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED:
			_update_steam_user(changer_id)

## Will fill the lobby_members dictionary with all currently connected users.
func _fetch_lobby_members() -> void:
	for i in range(Steam.getNumLobbyMembers(lobby_id)):
		var id: int = Steam.getLobbyMemberByIndex(lobby_id, i)
		_update_steam_user(id)

# -- LobbyData -- #

## Emitted when the SteamLobbyData is updated.
signal lobby_data_updated(lobby_data: SteamLobbyData)

## Holds LobbyData that was passed to the create_lobby function.
## When confirmation is returned then the lobby_data field is populated with this value.
var _tmp_lobby_data: SteamLobbyData

## LobbyData associated to the current lobby.
var lobby_data: SteamLobbyData:
	set(new_lobby_data):
		if lobby_data:
			lobby_data.local_update.disconnect(_on_lobby_data_local_update)
			lobby_data.external_update.disconnect(_on_lobby_data_external_update)
		
		if new_lobby_data:
			new_lobby_data.local_update.connect(_on_lobby_data_local_update)
			new_lobby_data.external_update.connect(_on_lobby_data_external_update)

		lobby_data = new_lobby_data

## Changes the property with key to value in the current LobbyData instance.
## Will return false if the property does not exist or LobbyData itself does not exist.
func change_lobby_data_property(key: String, value: Variant) -> bool:
	if not lobby_data: printerr("SteamLobby: No current LobbyData to alter."); return false

	var valid: bool = lobby_data.change_property(key, value)
	return valid

## Reacts to a local update from the lobby_data field.
## No need to check for lobby ownership since steam does not let others edit LobbyData.
func _on_lobby_data_local_update() -> void:
	var data: Dictionary = lobby_data.get_data()
	for key in data:
		var value: String = data[key]
		Steam.setLobbyData(lobby_id, key, value)

## Reacts to an external update from the lobby_data field.
func _on_lobby_data_external_update() -> void:
	lobby_data_updated.emit(lobby_data)

## Triggered when the Steam's LobbyData is changed.
## Updates the current SteamLobbyData object in lobby_data.
func _on_lobby_data_steam_update(success: int, _lobby_id: int, issuer_id: int) -> void:
	# If there's no lobby data yet we'll instantiate a new one from the ld_type field.
	if not lobby_data:
		var ld_type: int = str_to_var(Steam.getLobbyData(lobby_id, "ld_type"))
		lobby_data = SteamLobbyDataRegistry.get_script_from_id(ld_type).new()
		
	# We need to slightly reformat.
	var raw_data: Dictionary = Steam.getAllLobbyData(lobby_id)
	var data: Dictionary = {}

	# This removes the indexes from the dict.
	for idx in raw_data:
		var val: Dictionary = raw_data[idx]
		data[val.key] = val.value

	lobby_data.update(data)

# -- Utility Functions -- #

## Returns the Steam ID of the current lobby owner.
func get_lobby_owner() -> int:
	return Steam.getLobbyOwner(lobby_id)

## Returns whether the current user is owner of the current lobby or not.
func is_owner_me() -> bool:
	return Steam.getLobbyOwner(lobby_id) == Steam.getSteamID()

## Check whether a certain user is in the lobby or not.
## This is checked against the Steam side to be sure.
func user_in_lobby(steam_id: int) -> bool:
	var present: bool = false
	for i in range(Steam.getNumLobbyMembers(lobby_id)):
		var s_id: int = Steam.getLobbyMemberByIndex(lobby_id, i)
		if s_id == steam_id: present = true

	return present
