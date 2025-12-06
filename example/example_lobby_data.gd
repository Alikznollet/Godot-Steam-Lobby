extends SteamLobbyData
class_name ExampleLobbyData
## An example of how a user made LobbyData should look like.

## Name of the lobby.
var lobby_name: String = "invalid"

## The type of game, here just EXAMPLE.
var game_type: GAME_TYPES
enum GAME_TYPES {
	INVALID,
	EXAMPLE
}
