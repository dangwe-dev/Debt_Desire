extends RefCounted

class_name Population_Data


const SURNAMES_PATH: String = (
	"res://Game/Scripts/Data/Surnames.json"
)


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
	
	var json := JSON.new()
	var parse_result: Error = json.parse(file.get_as_text())
	
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
		
		
	var expected_classes: Array[String] = [
		"Oligarch",
		"Gentile",
		"Commoner",
		"Vagrant"
	]
		
	for social_class in expected_classes:
		
		if not data.has(social_class):
			push_error("Missing surname pool: " + social_class)
			return{}
			
		if typeof(data[social_class]) != TYPE_ARRAY:
			push_error(
				"Invalid surname pool for " + social_class
			)
			return{}
			
	return data
