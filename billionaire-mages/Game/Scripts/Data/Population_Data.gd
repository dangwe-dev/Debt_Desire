extends RefCounted

class_name Population_Data


const SURNAMES_PATH: String = (
	"res://Game/Scripts/Data/Surnames.json"
)

const EXPECTED_CLASSES: Array[String] = [
	"Oligarch",
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
