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
			set(property, str_to_var(data[property]))
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

## Locally updates a property from outside.
## Using this function to change properties is mandatory if you want others to get the updates.
## Will let the user know if an attempt to change a non-existing property is done.
func change_property(property: StringName, value: Variant) -> bool:
	if property in self:
		set(property, value)
		local_update.emit()
		return true
	# Gracefully lets the user know that this field does not exist. We don't need to panic here because no state change happens.
	printerr("SteamLobbyData: Field %s does not exist in %s." % [property, get_script().get_global_name()])
	return false
