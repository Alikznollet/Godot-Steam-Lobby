extends Resource
class_name LobbyData
## Data regarding a Steam Lobby

### ! Variables come here

## Receives a dictionary as made by get_data().
## Will fill up any variable it finds in the dictionary.
func set_data(data: Dictionary) -> void:
	for key in data:
		var value: String = data[key]

		if typeof(get(key)) != TYPE_STRING:
			set(key, str_to_var(value))
		else:
			set(key, value)

## Will loop over all user defined variables and convert them to string.
## These are then put into a dictionary to be sent to other peers in the lobby.
func get_data() -> Dictionary[String, String]:
	var data: Dictionary[String, String] = {}

	for property in get_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var value = get(property.name)
			data[property.name] = str(value)

	return data
