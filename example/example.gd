extends Control
## An example scene demonstrating plugin functionality.

# Dictionary holding SteamID to corresponding member label.
var member_labels: Dictionary[int, Label] = {}

func _ready() -> void:
	SteamLobby.user_joined.connect(_user_joined)
	SteamLobby.user_left.connect(_user_left)
	SteamLobby.user_updated.connect(_user_updated)
	SteamLobby.lobby_data_updated.connect(_lobby_data_updated)
	SteamLobby.lobby_joined.connect(_lobby_joined)
	SteamLobby.lobby_left.connect(_lobby_left)

	_lobby_left()

# -- Visual changes -- #

## Reacts to the user joined signal from SteamLobby
func _user_joined(user: SteamUser) -> void:
	var label: Label = Label.new()
	label.text = "Name: %s\nID: %d" % [user.name, user.steam_id]
	member_labels[user.steam_id] = label
	%MembersList.add_child(label)

## Reacts to the user left signal.
func _user_left(user: SteamUser) -> void:
	var label: Label = member_labels[user.steam_id]
	label.queue_free()
	member_labels.erase(user.steam_id)

## Reacts to the user updated signal.
func _user_updated(user: SteamUser) -> void:
	var label: Label = member_labels[user.steam_id]
	label.text = "Name: %s\nID: %d" % [user.name, user.steam_id]

## Clears all labels.
func _clear_labels():
	for label: Label in member_labels.values():
		label.queue_free()
	member_labels.clear()

## Reacts to the lobby_data_updated signal from SteamLobby.
func _lobby_data_updated(lobby_data: ExampleLobbyData) -> void:
	%LobbyName.text = str(lobby_data.lobby_name)
	%GameType.selected = lobby_data.game_type

func _lobby_joined() -> void:
	%JoinCreate.hide()
	%Filters.hide()
	%SteamLobbyList.enabled = false
	%LeaveLobby.show()
	%LobbyDetails.show()
	%LobbyID.editable = false
	%LobbyID.text = str(SteamLobby.lobby_id)
	%LobbyName.editable = SteamLobby.is_owner_me()
	%GameType.disabled = !SteamLobby.is_owner_me()

func _lobby_left() -> void:
	%JoinCreate.show()
	%Filters.show()
	%SteamLobbyList.enabled = true
	%LeaveLobby.hide()
	%LobbyDetails.hide()
	%LobbyID.editable = true
	%LobbyID.text = "0"

	# Remove all labels
	_clear_labels()

# -- Joining, leaving and creating -- #

func _on_create_lobby_pressed() -> void:
	var example_data := ExampleLobbyData.new()
	example_data.lobby_name = "example"
	example_data.game_type = ExampleLobbyData.GAME_TYPES.EXAMPLE

	SteamLobby.create_lobby(Steam.LobbyType.LOBBY_TYPE_PUBLIC, example_data)

func _on_join_lobby_pressed() -> void: 
	SteamLobby.join_lobby(int(%LobbyID.text))

func _on_leave_lobby_pressed() -> void:
	SteamLobby.leave_lobby()

# -- Changing LobbyData -- #

func _on_lobby_name_text_submitted(new_text: String) -> void:
	SteamLobby.change_lobby_data_property("lobby_name", new_text)

func _on_option_button_item_selected(index: int) -> void:
	SteamLobby.change_lobby_data_property("game_type", index)

# -- Filtering and lobbies -- #

## Prints all retrieved lobbies.
func _on_steam_lobby_list_lobbies_updated(lobbies: Array) -> void:
	print(lobbies)

func _on_filter_game_type_item_selected(index: int) -> void:
	if index == 2: %SteamLobbyList.lobby_filter.t_game_type = SteamLobbyFilter.FILTER_TYPE.OFF
	else: 
		%SteamLobbyList.lobby_filter.t_game_type = SteamLobbyFilter.FILTER_TYPE.NUMERICAL
		%SteamLobbyList.lobby_filter.f_game_type = index

func _on_filter_lobby_name_text_submitted(new_text: String) -> void:
	if new_text.is_empty(): %SteamLobbyList.lobby_filter.t_lobby_name = SteamLobbyFilter.FILTER_TYPE.OFF
	else: %SteamLobbyList.lobby_filter.t_lobby_name = SteamLobbyFilter.FILTER_TYPE.STRING
	%SteamLobbyList.lobby_filter.f_lobby_name = new_text
