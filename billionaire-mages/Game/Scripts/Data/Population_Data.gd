extends RefCounted

class_name Population_Data


const LOCAL_SURNAMES_PATH: String = (
	"res://Game/Scripts/Data/Local_Surnames.json"
)

const FOREIGN_SURNAMES_PATH: String = (
	"res://Game/Scripts/Data/Foreign_Surnames.json"
)

const FIRST_NAMES_PATH: Dictionary = {
	"male": {
		"Local": "res://Game/Scripts/Data/First_Names_Male.json",
		"Foreign": "res://Game/Scripts/Data/Foreign_First_Names_Male.json"
	},
	"female": {
		"Local": "res://Game/Scripts/Data/First_Names_Female.json",
		"Foreign": "res://Game/Scripts/Data/Foreign_First_Names_Female.json"
	}
}

const EXPECTED_SEXES: Array[String] = [
	"male",
	"female"
]

const EXPECTED_ORIGINS: Array[String] = [
	"Local",
	"Foreign"
]

const EXPECTED_CLASSES: Array[String] = [
	"Aristocrat",
	"Gentile",
	"Commoner",
	"Vagrant"
]




func load_surnames() -> Dictionary:
	
	var local_data: Dictionary = _load_surname_file(
		LOCAL_SURNAMES_PATH
	)
	
	if local_data.is_empty():
		return{}
		
	var foreign_data: Dictionary = _load_surname_file(
		FOREIGN_SURNAMES_PATH
	)
	
	if foreign_data.is_empty():
		return {}
		
	return {
		"Local": local_data,
		"Foreign": foreign_data
	}
	
func _load_surname_file(file_path: String) -> Dictionary:
	
	var data: Dictionary = _load_json_dictionary(
		file_path,
		"Surname"
	)
	if data.is_empty():
		return {}
		
	var seen_surnames: Dictionary = {}
	
	for social_class in EXPECTED_CLASSES:
		
		if not data.has(social_class):
			push_error(
				"Missing surname pool: "
				+ social_class
				+ " in "
				+ file_path
			)
			return {}
			
		if typeof(data[social_class]) != TYPE_ARRAY:
			push_error(
				"Invalid surname pool for "
				+ social_class
				+ " in "
				+ file_path
			)
			return {}
		var surname_pool: Array = data[social_class]
		
		if surname_pool.is_empty():
			push_error(
				"Empty surname pool: "
				+ social_class
				+ " in "
				+ file_path
			)
			return {}
			
		for surname_value in surname_pool:
			if typeof(surname_value) != TYPE_STRING:
				push_error(
					"Non-String surname found in "
					+ social_class
					+ " in "
					+ file_path
				)
				return {}
				
			var surname: String = surname_value
			
			var normalized_surname: String = (
				surname.strip_edges().to_lower()
			)
			
			if normalized_surname.is_empty():
				push_error(
					"Empty surname found in "
					+ social_class
					+ " in "
					+ file_path
				)
				return {}
			
			if seen_surnames.has(normalized_surname):
				push_error(
					"Duplicate surname found: "
					+ surname
					+ " in "
					+ social_class
					+ " in "
					+ file_path
				)
				return {}
				
			seen_surnames[normalized_surname] = true
			
	return data
	
func load_first_names() -> Dictionary:
		
	var first_names: Dictionary = {
		"male": {},
		"female": {}
	}
	for sex in EXPECTED_SEXES:
		
		for origin in EXPECTED_ORIGINS:
	
			var file_path: String = FIRST_NAMES_PATH[sex][origin]
			
			var data: Dictionary = _load_first_name_file(
				file_path,
				sex,
				origin
			)
			
			if data.is_empty():
				return {}
				
			first_names[sex][origin] = data
			
	return first_names

func _load_first_name_file(
	file_path: String,
	sex: String,
	origin: String
) -> Dictionary:
	
	var data: Dictionary = _load_json_dictionary(
		file_path,
		"First name"
	)
	if data.is_empty():
		return {}
		
	for social_class in EXPECTED_CLASSES:
		
		if not data.has(social_class):
			push_error(
				"Missing first-name pool: "
				+ sex + " / " + origin + " / " + social_class
			)
			return {}
			
		if typeof(data[social_class]) != TYPE_ARRAY:
			push_error(
				"Invalid first-name pool: "
				+ sex + " / " + origin + " / " + social_class
			)
			return {}
		var name_pool: Array = data[social_class]
		
		if name_pool.is_empty():
			push_error(
				"Empty first-name pool: "
				+ sex + " / " + origin + " / " + social_class
			)
			return {}
			
		var seen_names: Dictionary = {}
		
		for name_value in name_pool:
			
			if typeof(name_value) != TYPE_STRING:
				push_error(
					"Non-string first name found in "
					+ sex + " / " + origin + " / " + social_class
				)
				return {}
				
			var first_name: String = name_value
			
			if first_name.strip_edges().is_empty():
				push_error(
					"Empty first name found in "
					+ sex + " / " + origin + " / " + social_class
				)
				return {}
				
			var normalized_name: String = (
				first_name.strip_edges().to_lower()
			)
			
			if seen_names.has(normalized_name):
				push_error(
					"Duplicate first name found: "
					+ first_name
					+ " in "
					+ sex + " / " + origin + " / " + social_class
				)
				return {}
				
			seen_names[normalized_name] = true
			
	return data
	
func _load_json_dictionary(
	file_path: String,
	data_type: String
) -> Dictionary:
	
	if not FileAccess.file_exists(file_path):
		push_error(
			data_type + " file not found: " + file_path
		)
		return {}
		
	var file := FileAccess.open(
		file_path,
		FileAccess.READ
	)
	
	if file == null:
		push_error(
			"Unable to open "
			+ data_type.to_lower()
			+ " file: "
			+ file_path
		)
		return {}
		
	var json_text: String = file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var parse_result: Error = json.parse(json_text)
	
	if parse_result != OK:
		push_error(
			data_type + " JSON parsing failed in "
			+ file_path
			+ " at line "
			+ str(json.get_error_line())
			+ ": "
			+ json.get_error_message()
		)
		return {}
		
	var data: Variant = json.data
	
	if typeof(data) != TYPE_DICTIONARY:
		push_error(
			data_type
			+ " JSON must contain a Dictionary: "
			+ file_path
		)
		return {}
	
	return data
