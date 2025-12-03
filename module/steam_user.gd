extends Resource
class_name SteamUser
## Represents a Steam user.

# -- MetaData -- #

## Steam ID of the user.
var steam_id: int

## Name of the user.
var name: String

# -- Initialization -- #

## Only ID is mandatory.
func _init(p_steam_id: int) -> void:
	steam_id = p_steam_id
