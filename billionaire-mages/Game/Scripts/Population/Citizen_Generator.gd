extends RefCounted

class_name Citizen_Generator


const EXPECTED_CLASSES: Array[String] = [
	"Aristocrat",
	"Gentile",
	"Commoner",
	"Vagrant"
]

const EXPECTED_ORIGINS: Array[String] = [
	"Local",
	"Foreign"
]

const EXPECTED_SEXES: Array[String] = [
	"male",
	"female"
]

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var name_frequencies: Dictionary = {}

func _init() -> void:
	rng.randomize()
	
func generate_citizens(
	families: Array[Dictionary],
	first_names: Dictionary,
	starting_citizen_id: int = 0
) -> Array[Dictionary]:
	
	var citizens: Array[Dictionary] = []
	
	
	if starting_citizen_id < 0:
		push_error("Citizen ID cannot be negative. ")
		return citizens
	
	if not _validate_first_names(first_names):
		return citizens
	
	if not _validate_families(families):
		return citizens
		
	if families.is_empty():
		return citizens
		
	name_frequencies.clear()
		
	var next_citizen_id: int = starting_citizen_id
	
	for family in families:
		
		var family_id: int = family["family_id"]
		var origin: String = family["origin"]
		var social_class: String = family["social_class"]
		var surname: String = family["surname"]
		var member_count: int = family["member_count"]
		
		var used_family_names: Dictionary = {}
		
		var family_sexes: Array[String] = []
		
		if member_count >= 3:
			
			if rng.randi_range(0, 1) == 0:
				family_sexes.append("male")
				family_sexes.append("female")
			else:
				family_sexes.append("female")
				family_sexes.append("male")
			
			for i in range(member_count - 2):
				family_sexes.append(
					"male"
					if rng.randi_range(0, 1) == 0
					else "female"
				)
				
		else:
			
			for i in range(member_count):
				family_sexes.append(
					"male"
					if rng.randi_range(0, 1) == 0
					else "female"
				)
		
		for i in range(member_count):
			
			var preferred_sex: String = family_sexes[i]
		
		
		
			
			var name_data: Dictionary = _select_first_name(
				preferred_sex,
				origin,
				social_class,
				first_names,
				used_family_names
			)
			
			if name_data.is_empty():
				push_error(
					"Unable to assign a unique first name to family"
					+ str(family_id)
				)
				return []
				
			var citizen: Dictionary = {
				"citizen_id": next_citizen_id,
				"family_id": family_id,
				"origin": origin,
				"social_class": social_class,
				"sex": name_data["sex"],
				"first_name": name_data["first_name"],
				"surname": surname,
				"family_position": "HOUSEHOLD_MEMBER"
			}
			citizens.append(citizen)
			next_citizen_id += 1
			
	return citizens
	
func _validate_first_names(first_names: Dictionary) -> bool:
	
	for sex in EXPECTED_SEXES:
		
		if (
			not first_names.has(sex)
			or typeof(first_names[sex]) != TYPE_DICTIONARY
		):
			push_error("Missing or invalid first-name data for " + sex)
			return false
			
		for origin in EXPECTED_ORIGINS:
			
			if (
				not first_names[sex].has(origin)
				or typeof(first_names[sex][origin]) != TYPE_DICTIONARY
			):
				push_error(
					"Missing first name data for "
					+ sex + " / " + origin
				)
				return false
				
			for social_class in EXPECTED_CLASSES:
				var origin_data: Dictionary = first_names[sex][origin]
				
				if (
					not origin_data.has(social_class)
					or typeof(origin_data[social_class]) != TYPE_ARRAY
					or origin_data[social_class].is_empty()
				):
					push_error(
						"Missing or empty first-name pool: "
						+ sex + " / " + origin + " / " + social_class
					)
					return false
				
				for first_name in origin_data[social_class]:
					
					if (
						typeof(first_name) != TYPE_STRING
						or first_name.strip_edges().is_empty()
					):
						push_error(
							"Invalid first-name in "
							+ sex + " / " + origin + " / " + social_class
						)
						return false
						
	return true
	
func _validate_families(families: Array[Dictionary]) -> bool:
	
	var seen_family_ids: Dictionary = {}
	
	for family in families:
		
		var required_keys: Array[String] = [
			"family_id",
			"origin",
			"social_class",
			"surname",
			"member_count"
		]
		
		for key in required_keys:
			
			if not family.has(key):
				push_error("Family record is missing: " + key)
				return false
				
		if typeof(family["family_id"]) != TYPE_INT:
			push_error("Family ID must be an integer. ")
			return false
			
		var family_id: int = family["family_id"]
		
		if family_id < 0 or seen_family_ids.has(family_id):
			push_error("Invalid or duplicate family ID: " + str (family_id))
			return false
			
		seen_family_ids[family_id] = true
		
		if typeof(family["origin"]) != TYPE_STRING:
			push_error("Family origin must be a string.")
			return false
		
		if not EXPECTED_ORIGINS.has(family["origin"]):
			push_error("unknown family origins: " + str(family["origin"]))
			return false
			
		if typeof(family["social_class"]) != TYPE_STRING:
			push_error("Family social class must be a string. ")
			return false
			
		if not EXPECTED_CLASSES.has(family["social_class"]):
			push_error(
				"Unknown family social class: "
				+ str(family["social_class"])
			)
			return false
			
		if typeof(family["surname"]) != TYPE_STRING:
			push_error("Family surname must be a string.")
			return false
			
		if family["surname"].strip_edges().is_empty():
			push_error("Family surname cannot be empty.")
			return false
			
		if typeof(family["member_count"]) != TYPE_INT:
			push_error("Family member count must be an integer.")
			return false
			
		if family["member_count"] < 1:
			push_error("Family must have at least one member.")
			return false
			
	return true
	
func _select_first_name(
	preferred_sex: String,
	origin: String,
	social_class: String,
	first_names: Dictionary,
	used_family_names: Dictionary
) -> Dictionary:
	
	var name_pool: Array = (
		first_names[preferred_sex][origin][social_class]
	)
	
	var pool_key: String = _get_name_pool_key(
		preferred_sex,
		origin,
		social_class
	)
	
	var selected_name: String = _pick_weighted_unused_name(
		name_pool,
		used_family_names,
		pool_key
	)
	
	if selected_name.is_empty():
		return {}
	
	var normalized_name: String = selected_name.strip_edges().to_lower()
	used_family_names[normalized_name] = true
	
	return {
		"sex": preferred_sex,
		"first_name": selected_name 
	}
	
func _get_name_pool_key(
	sex: String,
	origin: String,
	social_class: String
) -> String:
	
	return sex + "|" + origin + "|" + social_class

func _pick_weighted_unused_name(
	name_pool: Array,
	used_family_names: Dictionary,
	pool_key: String
) -> String:
	
	var candidates: Array[String] = []
	var candidate_weights: Array[float] = []
	var total_weight: float = 0.0
	
	var pool_frequencies: Dictionary = name_frequencies.get(
		pool_key,
		{}
	)
	
	for first_name in name_pool:
		
		var normalized_name: String = first_name.strip_edges().to_lower()
		
		if used_family_names.has(normalized_name):
			continue
			
		var times_selected: int = pool_frequencies.get(
			normalized_name,
			0
		)
		
		var weight: float = pow(0.5, times_selected)
		
		candidates.append(first_name)
		candidate_weights.append(weight)
		total_weight += weight
		
	if candidates.is_empty():
		return ""
		
	var roll: float = rng.randf_range(0.0, total_weight)
	var cumulative_weight: float = 0.0
	
	for i in range(candidates.size()):
		
		cumulative_weight += candidate_weights[i]
		
		if roll < cumulative_weight:
			
			var selected_name: String = candidates[i]
			var normalized_selected_name: String = (
				selected_name.strip_edges().to_lower()
			)
			
			pool_frequencies[normalized_selected_name] = (
				pool_frequencies.get(normalized_selected_name, 0) + 1
			)
			
			name_frequencies[pool_key] = pool_frequencies
			
			return selected_name
			
	var fallback_name: String = candidates.back()
	var normalized_fallback_name: String = (
		fallback_name.strip_edges().to_lower()
	)
	
	pool_frequencies[normalized_fallback_name] = (
		pool_frequencies.get(normalized_fallback_name, 0) + 1
	)
	name_frequencies[pool_key] = pool_frequencies
	
	return fallback_name
