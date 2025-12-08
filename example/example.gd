extends Control

var member_labels: Dictionary[int, Label] = {}

func _ready() -> void:
	SteamLobby.lobby_changed.connect(_new_lobby)
	_new_lobby()

func _new_lobby() -> void:
	if SteamLobby.lobby_id == 0:
		%JoinCreate.show()
		%LeaveLobby.hide()
		%LobbyName.hide()
		%LobbyID.editable = true
		%LobbyID.text = "0"

		# Remove all labels
		_clear_labels()
	else:
		# This is triggered when a new actual lobby is joined.
		%JoinCreate.hide()
		%LeaveLobby.show()
		%LobbyName.show()
		%LobbyID.editable = false
		%LobbyID.text = str(SteamLobby.lobby_id)
		if SteamLobby.lobby_data is ExampleLobbyData:
			%LobbyName.text = str(SteamLobby.lobby_data.lobby_name)
		
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
