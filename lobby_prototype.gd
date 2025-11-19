extends Node3D
class_name LobbyPrototype
## Prototype Lobby Handler.

func _ready() -> void:
	%Leave.hide()
	SteamLobby.lobby_data_changed.connect(_update_lobby_data_visual)
	SteamLobby.lobby_confirmed.connect(_show_lobby_info)
	SteamLobby.lobby_left.connect(_show_create_join_info)

## Show what you need to see when in a lobby.
func _show_lobby_info() -> void:
	%CreateJoin.hide()
	%LobbyData.show()
	%Leave.show()

## Show what you need to see when not in a lobby.
func _show_create_join_info() -> void:
	%CreateJoin.show()
	%LobbyData.hide()
	%Leave.hide()

## Update the visuals for the lobby data.
func _update_lobby_data_visual(lobby_data: LobbyData) -> void:
	%LobbyName.text = lobby_data.lobby_name
	%WorldSize.text = str(lobby_data.world_size)
	%Started.button_pressed = lobby_data.started

func _process(_delta: float) -> void:
	%LobbyID.text = str(SteamLobby.lobby_id)
	%LobbyMembers.text = str(SteamLobby.lobby_members)

func _on_join_pressed() -> void:
	SteamLobby.join_lobby(int(%JoinID.text))

func _on_create_pressed() -> void:
	if len(%Name.text) == 0: return

	SteamLobby.create_lobby(Steam.LOBBY_TYPE_FRIENDS_ONLY, %Name.text)

func _on_leave_pressed() -> void:
	SteamLobby.leave_lobby()

func _on_lobby_name_text_submitted(new_text: String) -> void:
	SteamLobby.lobby_data.lobby_name = new_text
	SteamLobby.update_lobby_data()

## ! Need to make sure this does not even show if not the lobby leader!
func _on_started_toggled(toggled_on: bool) -> void:
	SteamLobby.lobby_data.started = toggled_on
	SteamLobby.update_lobby_data()

func _on_world_size_text_submitted(new_text: String) -> void:
	if not new_text.is_valid_int(): push_warning("World Size needs to be a valid integer."); return
	SteamLobby.lobby_data.world_size = int(new_text)
	SteamLobby.update_lobby_data()
