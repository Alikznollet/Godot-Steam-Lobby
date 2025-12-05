@tool
extends Node
class_name SteamLobbyList
## Carries and updates a list of Steam lobbies.

# TODO: Implement filters.
# -- Filters -- #


# -- Timer -- #

## Timer that will trigger a lobby list request on timeout.
var _fetch_timer: Timer

@export var refresh_time: int

func _ready() -> void:
	Steam.lobby_match_list.connect(_receive_lobby_list)

	_fetch_timer = Timer.new()
	_fetch_timer.wait_time = refresh_time
	_fetch_timer.timeout.connect(request_lobbies)
	_fetch_timer.autostart = true

	add_child(_fetch_timer)

# -- Retrieval lobbies -- #

func request_lobbies() -> void:
	# TODO: Implement filters here

	Steam.requestLobbyList()

func _receive_lobby_list(lobbies: Array) -> void:
	print(lobbies)
