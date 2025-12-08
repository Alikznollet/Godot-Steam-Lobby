extends SteamLobbyFilter
class_name ExampleLobbyFilter
## Example of a LobbyFilter.
##
## Pay attention to the naming scheme because it is important.
## Each individual filter consist out of 3 variables.
## Variable names have to align with what you're filtering.

## Lobby Name filter
@export var f_lobby_name: String = "example"
@export var t_lobby_name: FILTER_TYPE = FILTER_TYPE.STRING
@export var c_lobby_name: Steam.LobbyComparison = Steam.LOBBY_COMPARISON_EQUAL

## GameType filter
@export var f_game_type: ExampleLobbyData.GAME_TYPES
@export var t_game_type: FILTER_TYPE = FILTER_TYPE.NUMERICAL
@export var c_game_type: Steam.LobbyComparison = Steam.LOBBY_COMPARISON_EQUAL
