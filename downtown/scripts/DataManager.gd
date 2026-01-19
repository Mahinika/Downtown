extends Node

## DataManager - Handles loading and caching of all JSON data files
##
## Singleton Autoload that provides centralized access to all game data loaded from JSON files.
## All data is loaded once at startup and cached in memory for fast access during gameplay.
## This manager ensures no runtime file I/O occurs during gameplay, improving performance.
##
## Key Features:
## - Loads all JSON data files at startup
## - Caches data in memory for fast access
## - Provides type-safe accessors for resources and buildings data
## - Handles JSON parsing errors gracefully
##
## Usage:
##   var resources = DataManager.get_resources_data()
##   var buildings = DataManager.get_buildings_data()

## Cache dictionary storing all loaded JSON data files.
## Key: file name (without extension), Value: parsed JSON data (Dictionary or Array)
var data_cache: Dictionary = {}

func _ready() -> void:
	print("[DataManager] _ready() called - autoload loading")
	load_all_data()

	# #region agent log
	var log_data = {
		"sessionId": "debug-session",
		"runId": "autoload-loading",
		"hypothesisId": "H1",
		"location": "DataManager.gd:24",
		"message": "DataManager _ready() executed",
		"data": {
			"autoload_loaded": true,
			"load_all_data_called": true,
			"timestamp": Time.get_unix_time_from_system()
		},
		"timestamp": Time.get_unix_time_from_system() * 1000
	}

	var log_file = FileAccess.open("c:\\Users\\Ropbe\\Desktop\\Downtown\\.cursor\\debug.log", FileAccess.WRITE_READ)
	if log_file:
		log_file.seek_end()
		log_file.store_line(JSON.stringify(log_data))
		log_file.close()
	# #endregion

## Directory path where JSON data files are stored
const DATA_DIRECTORY: String = "res://data/"

## File extension for JSON data files
const DATA_FILE_EXTENSION: String = ".json"

## Loads all JSON data files specified in the data_files array.
##
## Called automatically during _ready(). Loads resources.json and buildings.json
## from the data directory and caches them in data_cache for fast access.
## Logs success/failure for each file loaded.
func load_all_data() -> void:
	# Data files to load for Stone Age prototype
	var data_files: Array[String] = [
		"resources",
		"buildings"
	]
	
	for file_name in data_files:
		if file_name.is_empty():
			push_warning("[DataManager] Empty file name in data_files array")
			continue
		
		var path: String = DATA_DIRECTORY + file_name + DATA_FILE_EXTENSION
		var data = load_json_file(path)
		if data:
			data_cache[file_name] = data
			print("[DataManager] Loaded data: ", file_name)
		else:
			push_error("[DataManager] Failed to load data: " + path)

## Loads and parses a JSON file from the given path.
##
## Parameters:
##   path: Full file path to the JSON file (e.g., "res://data/resources.json")
##
## Returns:
##   Parsed JSON data (Dictionary or Array) on success, null on failure.
##
## Handles validation, file existence checks, and JSON parsing errors.
## Logs warnings/errors for debugging purposes.
func load_json_file(path: String) -> Variant:
	# Validate input
	if path.is_empty():
		push_error("[DataManager] Empty file path")
		return null
	
	if not FileAccess.file_exists(path):
		push_warning("[DataManager] File does not exist: " + path)
		return null
		
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("[DataManager] Failed to open file: " + path)
		return null
		
	var content: String = file.get_as_text()
	file.close()
	
	if content.is_empty():
		push_warning("[DataManager] File is empty: " + path)
		return null
	
	var json = JSON.new()
	var error = json.parse(content)
	if error == OK:
		return json.data
	else:
		push_error("[DataManager] JSON Parse Error: ", json.get_error_message(), " in ", path, " at line ", json.get_error_line())
		return null

## Retrieves cached data by key.
##
## Parameters:
##   key: Data file name (without extension) used as cache key (e.g., "resources", "buildings")
##
## Returns:
##   Cached data (Dictionary or Array) if found, null otherwise.
##
## Note: Returns null if key is empty or not found in cache.
func get_data(key: String) -> Variant:
	# Validate input
	if key.is_empty():
		push_warning("[DataManager] Empty data key")
		return null
	
	return data_cache.get(key)

## Retrieves resources data dictionary.
##
## Returns:
##   Dictionary containing all resource definitions loaded from resources.json.
##   Structure: {"resources": {resource_id: resource_data, ...}}
##
## Returns empty dictionary if resources data not loaded.
func get_resources_data() -> Dictionary:
	return get_data("resources") as Dictionary

## Retrieves buildings data dictionary.
##
## Returns:
##   Dictionary containing all building definitions loaded from buildings.json.
##   Structure: {"buildings": {building_id: building_data, ...}}
##
## Returns empty dictionary if buildings data not loaded.
func get_buildings_data() -> Dictionary:
	return get_data("buildings") as Dictionary
