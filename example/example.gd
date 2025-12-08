extends Control

var member_labels: Dictionary[int, Label] = {}

func _ready() -> void:
	SteamLobby.lobby_changed.connect(_new_lobby)
	_new_lobby()

func _new_lobby() -> void:
	if SteamLobby.lobby_id == 0:
		%JoinCreate.show()
		%Filters.show()
		%SteamLobbyList.enabled = true
		%LeaveLobby.hide()
		%LobbyName.hide()
		%GameType.hide()
		%LobbyID.editable = true
		%LobbyID.text = "0"

		# Remove all labels
		_clear_labels()
	else:
		# This is triggered when a new actual lobby is joined.
		%JoinCreate.hide()
		%Filters.hide()
		%SteamLobbyList.enabled = false
		%LeaveLobby.show()
		%LobbyName.show()
		%GameType.show()
		%LobbyID.editable = false
		%LobbyID.text = str(SteamLobby.lobby_id)
		if SteamLobby.lobby_data is ExampleLobbyData:
			%LobbyName.text = str(SteamLobby.lobby_data.lobby_name)
			%GameType.selected = SteamLobby.lobby_data.game_type
		
		# Generate or update the label for each member
		_clear_labels()
		for member: SteamUser in SteamLobby.lobby_members.values():
			if not member_labels.has(member.steam_id):
				member_labels[member.steam_id] = Label.new()
				%MembersList.add_child(member_labels[member.steam_id])

			member_labels[member.steam_id].text = "Name: %s\nID: %d" % [member.name, member.steam_id]

## ! Ew this feels wrong
func _clear_labels():
	for label: Label in member_labels.values():
		label.queue_free()
	member_labels.clear()

func _on_create_lobby_pressed() -> void:
	var example_data := ExampleLobbyData.new()
	example_data.lobby_name = "example"
	example_data.game_type = ExampleLobbyData.GAME_TYPES.EXAMPLE

	SteamLobby.create_lobby(Steam.LobbyType.LOBBY_TYPE_PUBLIC, example_data)

func _on_join_lobby_pressed() -> void: 
	SteamLobby.join_lobby(int(%LobbyID.text))

func _on_leave_lobby_pressed() -> void:
	SteamLobby.leave_lobby()

func _on_lobby_name_text_submitted(new_text: String) -> void:
	if SteamLobby.lobby_data is ExampleLobbyData:
		SteamLobby.lobby_data.change_property("lobby_name", new_text)

func _on_steam_lobby_list_lobbies_updated(lobbies: Array) -> void:
	print(lobbies)

func _on_option_button_item_selected(index: int) -> void:
	if SteamLobby.lobby_data is ExampleLobbyData:
		SteamLobby.lobby_data.change_property("game_type", index)

func _on_filter_game_type_item_selected(index: int) -> void:
	if index == -1: %SteamLobbyList.lobby_filter.t_game_type = SteamLobbyFilter.FILTER_TYPE.OFF
	else: %SteamLobbyList.lobby_filter.t_game_type = SteamLobbyFilter.FILTER_TYPE.NUMERICAL
	%SteamLobbyList.lobby_filter.f_game_type = index

func _on_filter_lobby_name_text_submitted(new_text: String) -> void:
	if new_text.is_empty(): %SteamLobbyList.lobby_filter.t_lobby_name = SteamLobbyFilter.FILTER_TYPE.OFF
	else: %SteamLobbyList.lobby_filter.t_lobby_name = SteamLobbyFilter.FILTER_TYPE.STRING
	%SteamLobbyList.lobby_filter.f_lobby_name = new_text
