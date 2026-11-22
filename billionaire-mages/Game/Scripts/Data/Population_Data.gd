extends RefCounted

class_name Population_Data


const SURNAMES_PATH: String = (
	"res://Game/Scripts/Data/Local_Surnames.json"
)

const FIRST_NAMES_MALE_PATH: String = (
	"res://Game/Scripts/Data/First_Names_Male.json"
)

const FIRST_NAMES_FEMALE_PATH: String = (
	"res://Game/Scripts/Data/First_Names_Female.json"
)

const EXPECTED_SEXES: Array[String] = [
	"male",
	"female"
]

const EXPECTED_CLASSES: Array[String] = [
	"Aristocrat",
	"Gentile",
	"Commoner",
	"Vagrant"
]




func load_surnames() -> Dictionary:
	
	if not FileAccess.file_exists(SURNAMES_PATH):
		push_error("Surnames file not found: " + SURNAMES_PATH)
		return{}
		
	var file := FileAccess.open(
		SURNAMES_PATH,
		FileAccess.READ
	)
	
	if file == null:
		push_error("Unable to open surname file.")
		return{}
	
	var json_text: String = file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var parse_result: Error = json.parse(json_text)
	
	if parse_result != OK:
		push_error(
			"JSON parsing failed at line "
			+ str(json.get_error_line())
			+ ": "
			+ json.get_error_message()
		)
		return{}
		
	var data: Variant = json.data
	
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Surname JSON must contain a Dictionnary. ")
		return{}
		
	var seen_surnames: Dictionary = {}
		
		
	for social_class in EXPECTED_CLASSES:
		
		if not data.has(social_class):
			push_error("Missing surname pool: " + social_class)
			return{}
			
		if typeof(data[social_class]) != TYPE_ARRAY:
			push_error(
				"Invalid surname pool for " + social_class
			)
			return{}
		
		var surname_pool: Array = data[social_class]
		
		for surname_value in surname_pool:
			
			if typeof(surname_value) != TYPE_STRING:
				push_error(
					"Non-string surname found in "
					+ social_class
				)
				return{}
			
			var surname: String = surname_value
			var normalized_surname: String = (
				surname.strip_edges().to_lower()
			)
			
			if normalized_surname.is_empty():
				push_error(
					"Empty surname found in " + social_class
				)
				return{}
			
			if surname != surname.strip_edges():
				push_error(
					"Surrounding whitespace in surname: "
					+ surname
				)
				return{}
				
			if seen_surnames.has(normalized_surname):
				push_error(
					"Duplicate Surnames Found: "
					+ surname
					+ " in "
					+ social_class
				)
				return{}
				
			seen_surnames[normalized_surname] = social_class
		
	return data
	
func load_first_names() -> Dictionary:
		
	var first_names: Dictionary = {
		"male": {},
		"female": {}
	}
		
	var file_paths: Dictionary = {
		"male": FIRST_NAMES_MALE_PATH,
		"female": FIRST_NAMES_FEMALE_PATH
	}
		
	for sex in EXPECTED_SEXES:
		
		var file_path: String = file_paths[sex]
		
		if not FileAccess.file_exists(file_path):
			push_error(
				"First names file not found: " + file_path
			)
			return{}
		
		var file := FileAccess.open(
			file_path,
			FileAccess.READ
		)
		
		if file == null:
			push_error(
				"Unable to open first names file: " + file_path
			)
			return{}
	
		var json_text: String = file.get_as_text()
		file.close()

		var json := JSON.new()
		var parse_result: Error = json.parse(json_text)
	
		if parse_result != OK:
			push_error(
				"First names JSON parsing failed at line: "
				+ str(json.get_error_line())
				+ ": "
				+ json.get_error_message()
			)
			return{}
		
		var data: Variant = json.data
	
		if typeof(data) != TYPE_DICTIONARY:
			push_error(
				"First names JSON must contain a Dictionnary: "
				+ sex
			)
			return{}
		
		for social_class in EXPECTED_CLASSES:
		
			if not data.has(social_class):
				push_error(
					"Missing first name pool: "
					+ sex + " / " + social_class
				)
				return{}
			
			if typeof(data[social_class]) != TYPE_ARRAY:
				push_error(
					"Invalid first name pool: "
					+ sex + " / " + social_class
				)
				return{}
			
			var name_pool: Array = data[social_class]
			var seen_names: Dictionary = {}
				
			for name_value in name_pool:
			
				if typeof(name_value) != TYPE_STRING:
					push_error(
						"Non-string first name found in "
						+ sex + " / " + social_class
					)
					return{}
				
				var first_name: String = name_value
				
				if first_name.strip_edges().is_empty():
					push_error(
						"Empty first name found in "
						+ sex + " / " + social_class
					)
					return{}
					
				var normalized_name: String = (
					first_name.to_lower()
				)
				
				if seen_names.has(normalized_name):
					push_error(
						"Duplicate first name found in "
						+ sex + " / " + social_class
						+ ": " + first_name
					)
					return{}
							
				seen_names[normalized_name] = true
				
			first_names[sex][social_class] = name_pool
					
	return first_names
