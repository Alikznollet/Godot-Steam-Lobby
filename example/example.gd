extends Control

var member_labels: Dictionary[int, Label] = {}

func _ready() -> void:
	SteamLobby.lobby_changed.connect(_new_lobby)
	_new_lobby()

func _new_lobby() -> void:
	if SteamLobby.lobby_id == 0:
		%JoinCreate.show()
		%LeaveLobby.hide()
		%LobbyID.editable = true
		%LobbyID.text = "0"

		# Remove all labels
		for label: Label in member_labels.values():
			label.queue_free()
		member_labels.clear()
	else:
		# This is triggered when a new actual lobby is joined.
		%JoinCreate.hide()
		%LeaveLobby.show()
		%LobbyID.editable = false
		%LobbyID.text = str(SteamLobby.lobby_id)
		
		# Generate or update the label for each member
		for member: SteamUser in SteamLobby.lobby_members.values():
			if not member_labels.has(member.steam_id):
				member_labels[member.steam_id] = Label.new()
				%MembersList.add_child(member_labels[member.steam_id])

			member_labels[member.steam_id].text = "Name: %s\nID: %d" % [member.name, member.steam_id]
			

func _on_create_lobby_pressed() -> void:
	SteamLobby.create_lobby(Steam.LobbyType.LOBBY_TYPE_PUBLIC)

func _on_join_lobby_pressed() -> void:
	SteamLobby.join_lobby(int(%LobbyID.text))

func _on_leave_lobby_pressed() -> void:
	SteamLobby.leave_lobby()
