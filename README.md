> [!WARNING]
> This plugin is all but complete. I myself am still learning as I go, so expect bugs and missing functionality. If there's any important features that I'm missing or bugs you came across you can create an issue and I will look into it. If you want you can also contribute features/bug-fixes yourself.

# Godot SteamLobby
A plugin for Godot that aims to make Steam lobby managing easier.

## Dependencies

The plugin requires **two** things to work:
- A working [GodotSteam](https://godotsteam.com/) installation in the project.
- Steam client is required to be open.

> [!IMPORTANT]
> Do not forget to set you AppID in the Godot Project settings under `steam/initialization/app_id`. If you do not have one yet, `480` can be used.

## Usage

### `SteamLobby`

The main node of the plugin is `SteamLobby`. This is an autoload node that is automatically added to your global scripts when the plugin is enabled. 

Functions, Signals and Properties:
- `lobby_changed`: a signal that is emitted whenever the lobby has undergone a change.
- `max_members`: the maximum members that the lobby can hold.
- `lobby_id`: the id of the current lobby, 0 if none.
- `lobby_members`: dictionary mapping steamid64 to `SteamUser` resources.
- `create_lobby(type, lobby_data)`: attempts to create a lobby with given type and `SteamLobbyData`.
- `join_lobby(lobby_id)`: attempts to join the lobby with id lobby_id.
- `leave_lobby()`: leaves the current lobby if in one.
- `lobby_data`: field holding a SteamLobbyData resource, the exact type is the one provided to `create_lobby()` or received from the owner of the lobby.
- `is_owner_me()`: tells whether you are the owner of the lobby or not.

Some extra functionality includes caching of the `lobby_id` if the lobby is not left cleanly, and then using that cache to rejoin that lobby on boot. When anything changes inside the `lobby_data` resource the script will automatically update lobby data on Steam.

### `SteamLobbyData`

An abstract resource holding imporant data regarding a lobby. The resource does not need to be abstract, but it is useless on it's own so this enforces implementation. 

Functions, Signals and Properties:
- `change_property(property, value)`: function used to set the value of `property` to `value`. This replaces direct assignment for lobby data resources, since direct assignment can't automatically send out a signal to notify the outside of it's change.

All you need to do to define your own `SteamLobbyData` is implement it and give it a unique name, then add the fields you need.

> [!IMPORTANT]
> The current implementation only allows types that are supported by `var_to_str()` and `str_to_var()`. This means any non resource or node.

An example of such an implementation can be found in `example/example_lobby_data.gd`.

### `SteamLobbyDataDB`

Another autoload, it holds all custom `SteamLobbyData` implementations.

Functions, Signals and Properties:
- `init_from_stringname(stringname)`: returns the script-instance for the provided stringname if it is a `SteamLobbyData` implementation. This is mainly used in the plugin, but can be used outside of it too where needed.

### `SteamUser`

Initialized with a steamid64 and holds the `name` and `steam_id` of a steam user.

### `SteamLobbyList`

Node that can be added to any scene, will periodically retrieve lobbies from Steam for the current gameID and apply filters to that search.

Functions, Signals and Properties:
- `lobbies_updated`: signal that is emitted when new lobbies arrive, also carries that list of lobbies.
- `lobbies`: holds whatever the latest received list of lobbies is.
- `lobby_filter`: the `SteamLobbyFilter` resource used to filter the search for lobbies.
- `enabled`: a boolean indicating whether to search for lobbies or not.
- `refresh_time`: time in seconds of how long to wait before fetching lobbies again.
- `request_lobbies()`: requests new lobbies from steam, after applying all current filters.

This node can be found directly in the add-menu.

### `SteamLobbyFilter`

Another abstract resource holding different filters that are then applied to lobby search. When implementing a `SteamLobbyFilter` the naming schemes are **incredibly** important, they go as follows:

- You can only filter on lobby data that exists, the name is thus very important.
- A prefix is added to the variable name for each mandatory filter variable.
- Pay attention to the usage of 0. It is handled loosely by the Steam backend.

Each piece of lobby data you want to filter should be three variables in the filter:
- `f_{variable_name}`: the actual value to check against.
- `t_{variable_name}`: the type of filter. Any of `FILTER_TYPE` enum.
- `c_{variable_name}`: the comparison of the filter, can be any of `Steam.LobbyComparison`.

An optional distance filter can also be set via the `distance` field. This holds any of `Steam.LobbyDistanceFilter`, but is by default `Steam.LOBBY_DISTANCE_FILTER_DEFAULT`.

An example of a correct filter implementation is provided in `example/example_lobby_filter.gd`.
