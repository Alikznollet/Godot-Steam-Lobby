@abstract
extends Resource
class_name SteamLobbyData
## Abstract resource representing LobbyData
##
## User can extend this class and then use it to store and easily manage lobby data
## via a custom script instead of separate Steam API functions.

# -- External updates -- #

## Signals the outside that LobbyData was changed from the outside.
signal external_update()

## Updates the LobbyData based on data it has received.
## Will only update fields that it knows.
func update(data: Dictionary) -> void:
	for property in data:
		if property in self:
			self[property] = str_to_var(data[property])
	external_update.emit()

## Returns a dictionary of every user defined variable
## mapped to it's value as a string.
## String values are mandatory for Steam LobbyData.
func get_data() -> Dictionary:
	var data: Dictionary = {}
	var properties := get_property_list()

	for property in properties:
		# Bitwise and to isolate the single SCRIPT_VARIABLE thing.
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			data[property.name] = var_to_str(get(property.name))

	return data

# -- Local update -- #

## Emitted when lobby_data is changed locally.
signal local_update()

## Override 
func _set(property: StringName, value: Variant) -> bool:
	if property in self:
		self[property] = value
		local_update.emit()
		return true
	return false
