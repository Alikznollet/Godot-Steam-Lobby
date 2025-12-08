@tool
extends Node
class_name SteamLobbyList
## Carries and updates a list of Steam lobbies.

# -- Lobbies -- #

## Lets the outside know that lobbies was updated.
signal lobbies_updated(lobbies: Array)

## List of lobbies, updated at interval refresh_time.
var lobbies: Array

# -- Filters -- #

## The Filter that is applied every time lobbies are fetched.
@export var lobby_filter: SteamLobbyFilter

# -- Timer -- #

## Whether the lobby fetching should be enabled or not.
var enabled: bool = false:
	set(n_enabled):
		enabled = n_enabled
		if enabled: 
			request_lobbies()
			_fetch_timer.start()
		else: _fetch_timer.stop()

## Timer that will trigger a lobby list request on timeout.
var _fetch_timer: Timer

## The time between every request sent to Steam.
@export var refresh_time: int

func _ready() -> void:
	Steam.lobby_match_list.connect(_receive_lobby_list)

	_fetch_timer = Timer.new()
	_fetch_timer.wait_time = refresh_time
	_fetch_timer.timeout.connect(request_lobbies)
	_fetch_timer.autostart = true

	add_child(_fetch_timer)

# -- Retrieval lobbies -- #

## Applies the SteamLobbyFilter if there is one and then requests the lobbies.
func request_lobbies() -> void:
	if lobby_filter: lobby_filter.apply_filters()

	Steam.requestLobbyList()

## Receives the lobbies from Steam.
func _receive_lobby_list(p_lobbies: Array) -> void:
	lobbies = p_lobbies
	lobbies_updated.emit(lobbies)

# TODO: Add Formatting for lobbies.
