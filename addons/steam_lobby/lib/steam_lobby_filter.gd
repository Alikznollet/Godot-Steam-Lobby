@abstract
extends Resource
class_name SteamLobbyFilter
## Filter resource for filtering lobbies from the SteamLobbyList
##
## Holds some parameters that will prompt certain filters onto the Steam backend.
## Custom LobbyData parameters are user defined.
## [br]
## Any user defined filter must use the Filter, Type, Comparison name scheme as follows:
## f_example, t_example, c_example, respectively holding the actual to filter value, the type and the comparison type.
## The name of the variable has to line up with the name of the LobbyData.

# -- Filter Types -- #

## Types of filters that can be applied.
## Includes OFF so the filter can be turned off.
enum FILTER_TYPE {
	OFF,
	STRING,
	NUMERICAL,
	NEAR_VALUE
}

# -- Default Filter parameters -- #

@export_group("Default Parameters")

## Distance Filter applied to Steam's lobby search.
## Default: Steam.LOBBY_DISTANCE_FILTER_DEFAULT
@export var distance: Steam.LobbyDistanceFilter = Steam.LOBBY_DISTANCE_FILTER_DEFAULT

# -- Filter Application -- #

## Will apply the filter to Steam's lobby search.
func apply_filters() -> void:
	Steam.addRequestLobbyListDistanceFilter(distance)
	var properties := get_property_list()

	for property in properties:
		# Bitwise and to isolate the single SCRIPT_VARIABLE thing.
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			if property.name.begins_with("f_"):
				var base: String = property.name.trim_prefix("f_")

				# Get all needed variables.
				var filter: Variant = get(property.name)
				assert("t_" + base in self, "SteamLobbyFilter: Did not find FILTER_TYPE field for %s. Define it as t_%s with type FILTER_TYPE." % [base, base])
				var filter_type: FILTER_TYPE = get("t_" + base)
				assert("c_" + base in self, "SteamLobbyFilter: Did not find Steam.LobbyComparison field for %s. Define it as c_%s with type Steam.LobbyComparison." % [base, base])
				var comparison: Steam.LobbyComparison = get("c_" + base)
				
				match filter_type:
					FILTER_TYPE.STRING:
						# Because of the way we are storing LobbyData we need to filter on the var_to_str. "\"example\"" with escapes.
						Steam.addRequestLobbyListStringFilter(base, var_to_str(filter), comparison)
					FILTER_TYPE.NUMERICAL:
						Steam.addRequestLobbyListNumericalFilter(base, filter, comparison)
					FILTER_TYPE.NEAR_VALUE:
						Steam.addRequestLobbyListNearValueFilter(base, filter)
					FILTER_TYPE.OFF:
						pass
