@tool
extends Node
## SteamLobby
## 
## This script is loaded as an autoload when the plugin is enabled.
## Exposes important functions, signals and variables needed for Steam lobbies.

# -- Constants -- #

## Path to the lobby cache file. Used to rejoin lobbies that were incorrectly left.
const _lobby_cache_path: String = "user://lobby_cache/lobby.txt"

## Signal the menu can be hooked up to so it can listen for updated.
signal lobby_confirmed()
signal lobby_left()

# -- Variables -- #

## Maximum users that can be connected to the lobby at once.
## This can be altered before creation of a lobby, not during.
var max_members: int = 10

## The ID of the lobby entered. If 0 the client is not in a Steam lobby.
var lobby_id: int = 0:
	set(new_lobby_id):
		lobby_id = new_lobby_id

		# If lobby is left intentionally we will delete the file.
		if lobby_id == 0:
			DirAccess.remove_absolute(_lobby_cache_path)
		else:
			var file: FileAccess = FileAccess.open(_lobby_cache_path, FileAccess.WRITE)
			assert(file, "SteamLobby: Could not open lobby cache.")

			file.store_64(lobby_id)
			file.close()

## Dictionary mapping Steam ID to SteamUser instances.
## Contains all currently connected users.
var lobby_members: Dictionary[int, SteamUser] = {}

func _ready() -> void:
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.join_requested.connect(_on_lobby_join_requested)
	Steam.persona_state_change.connect(_on_persona_change)

	_load_lobby_id_from_cache()

# -- Cache Rejoining -- #

## Will load the lobby_id from the cache if there is a cache.
## There should only be a cache when the player had quit during a previous game without leaving gracefully.
func _load_lobby_id_from_cache() -> void:
	if not FileAccess.file_exists(_lobby_cache_path): return

	var file: FileAccess = FileAccess.open(_lobby_cache_path, FileAccess.READ)
	assert(file, "SteamLobby: Could not open lobby cache.")

	var v_lobby_id: int = file.get_64()
	file.close()

	join_lobby(v_lobby_id)

# -- Lobby Creation -- #

## Will create a lobby based on the lobby type provided.
## Types are contained in Steam.LobbyType
func create_lobby(lobby_type: Steam.LobbyType) -> void:
	if lobby_id == 0:
		Steam.createLobby(lobby_type, max_members)

## Ran when Steam sees that a lobby was created.
func _on_lobby_created(connected: int, this_lobby_id: int) -> void:
	if connected == 1:
		# Set the lobby ID
		lobby_id = this_lobby_id
	
# -- Lobby Joining -- #

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
		lobby_confirmed.emit()

	# If the response was not success
	else:
		lobby_id = 0 # This removes the cached lobby file.
		printerr("SteamLobby: Could not join lobby, response was %d." % response)

## When a join is requested through a friend we will run this.
func _on_lobby_join_requested(this_lobby_id: int, _friend_id: int) -> void:
	# Attempt to join the lobby
	join_lobby(this_lobby_id)

# -- Lobby Leaving -- #

## Leave the current lobby if there is one and reset all fields.
func leave_lobby() -> void:
	if lobby_id != 0:
		Steam.leaveLobby(lobby_id)
		lobby_id = 0
		lobby_members.clear()
		lobby_left.emit()

# -- Persona Updates -- #

## If some player changes it's persona we update that player.
## Flag is ignored here because we don't need to know what was updated.
func _on_persona_change(steam_id: int, _flag: int) -> void:
	if lobby_id > 0:
		_update_steam_user(steam_id)

## Updates SteamUser instance linked to steam_id.
func _update_steam_user(steam_id: int) -> void:
	var user: SteamUser
	if lobby_members.has(steam_id):
		user = lobby_members[steam_id]
	else:
		user = SteamUser.new(steam_id)
		lobby_members[steam_id] = user
	
	# TODO: Add more metadata here.
	user.name = Steam.getFriendPersonaName(steam_id)

# -- LobbyData -- #

# TODO: Implement a robust lobby data system.
