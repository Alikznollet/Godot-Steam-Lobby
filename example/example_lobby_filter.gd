extends SteamLobbyFilter
class_name ExampleLobbyFilter
## Example of a LobbyFilter.

## Lobby Name filter
@export var f_lobby_name: String = "example"
@export var t_lobby_name: FILTER_TYPE = FILTER_TYPE.STRING
@export var c_lobby_name: Steam.LobbyComparison = Steam.LOBBY_COMPARISON_EQUAL

