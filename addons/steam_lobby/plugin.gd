@tool
extends EditorPlugin

func _enable_plugin() -> void:
	add_autoload_singleton("SteamLobby", "res://addons/steam_lobby/lib/steam_lobby.gd")
	add_autoload_singleton("SteamLobbyDataDB", "res://addons/steam_lobby/lib/steam_lobby_data_db.gd")

func _disable_plugin() -> void:
	remove_autoload_singleton("SteamLobby")
	remove_autoload_singleton("SteamLobbyDataDB")

func _enter_tree() -> void:
	add_custom_type(
		"SteamLobbyList",
		"Node",
		preload("lib/steam_lobby_list.gd"),
		null
	)

func _exit_tree() -> void:
	remove_custom_type("SteamLobbyList")
