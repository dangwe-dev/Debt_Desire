extends RefCounted

class_name Kinless_Citizen_Generator


const EXPECTED_CLASSES: Array[String] = [
	"Aristocrat",
	"Gentile",
	"Commoner",
	"Vagrant"
]

const EXPECTED_SEXES: Array[String] = [
	"male",
	"female"
]

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _init() -> void:
	rng.randomize()


func generate_kinless_citizen(
	kinless_counts_by_class: Dictionary,
	first_names: Dictionary,
	available_surnames: Dictionary,
	used_surnames: Dictionary,
	first_name_usage: Dictionary,
	starting_citizen_id: int = 0
) -> Array[Dictionary]:
	
	var citizens: Array[Dictionary] = []
	
	# Validate the starting ID.
	if starting_citizen_id < 0:
		push_error("Citizen ID cannot be negative. ")
		return citizens
	
	#Validate all requested counts and required data
	#before generating any citizens.
	for social_class in EXPECTED_CLASSES:
		
		var requested_count: int = int(
			kinless_counts_by_class.get(social_class, 0)
		)
		
		if requested_count < 0:
			push_error(
				"Kinless citizen count cannot be negative for "
				+ social_class
			)
			return citizens
		
		if not available_surnames.has(social_class):
			push_error("Missing surname pool for " + social_class
			)
			return citizens
			
		if not first_names.has("male") or not first_names.has("female"):
			push_error("Missing male or female first-name data.")
			return citizens
			
		for sex in EXPECTED_SEXES:
			if (
				not first_names[sex].has(social_class)
				or first_names[sex][social_class].is_empty()
			):
				push_error(
					"Missing or empty first-name pool: "
					+ sex + " / " + social_class
				)
				return citizens
				
		var available_count: int = (
			_get_available_surname_count(
				social_class,
				available_surnames,
				used_surnames
			)
		)
		
		if available_count < requested_count:
			push_error(
				"Insufficient unique surnames for kinless "
				+ social_class
				+ ". Required: " + str(requested_count)
				+ ". Available: " + str(available_count)
			)
			return citizens
			
	var next_citizen_id: int = starting_citizen_id
	
	for social_class in EXPECTED_CLASSES:
		
		var requested_count: int = int(
			kinless_counts_by_class.get(social_class, 0)
		)
		
		for i in range(requested_count):
			
			#Assign sex with equal probability.
			var sex: String = (
				"male"
				if rng.randi_range(0, 1) == 0
				else "female"
			)
			
			#Select a first name using its previous usage.
			var first_name: String = _select_first_name(
				sex,
				social_class,
				first_names,
				first_name_usage
			)
			
			#Select a unique surname from this class.
			var surname: String = _select_surname(
				social_class,
				available_surnames,
				used_surnames
			)
			
			if first_name.is_empty() or surname.is_empty():
				push_error(
					"Failed to generate kinless citizen in "
					+ social_class
				)
				return[]
				
			var citizen: Dictionary = {
				"citizen_id": next_citizen_id,
				"social_class": social_class,
				"sex": sex,
				"first_name": first_name,
				"surname": surname,
				"is kinless": true
			}
			
			citizens.append(citizen)
			next_citizen_id += 1
			
	return citizens
	
func _get_available_surname_count(
	social_class: String,
	available_surnames: Dictionary,
	used_surnames: Dictionary
) -> int:
	
	var count: int = 0
	var seen: Dictionary = {}
	
	for surname in available_surnames[social_class]:
		
		if typeof(surname) != TYPE_STRING:
			continue
			
		var normalized: String = surname.strip_edges().to_lower()
		
		if normalized.is_empty():
			continue
		
		if used_surnames.has(normalized):
			continue
			
		if seen.has(normalized):
			continue
			
		seen[normalized] = true
		count += 1
		
	return count
	
func _select_first_name(
	sex: String,
	social_class: String,
	first_name: Dictionary,
	first_name_usage: Dictionary
) -> String:
	
	var name_pool: Array = first_names[sex][social_class]
	var usage_by_sex: Dictionary = first_name_usage.get(sex, {})
	
	var weights: PackedFloat32Array = PackedInt32Array()
	
	for first_name in name_pool:
		
		var normalized: String = first_name.strip_edges().to_lower()
		var previous_uses: int = int(
			usage_by_sex.get(normalized, 0)
		)
		
		var weight: float = 1.0 / (1.0 + previous_uses)
		weights.append(weight)
		
	var selected_index: int = rng.rand_weighted(weights)
	var selected_name: String = name_pool[selected_index]
	
	var selected_keys: String = selected_name.strip_edges().to_lower()
	
	usage_by_sex[selected_keys] = (
		int(usage_by_sex.get(selected_keys, 0)) + 1
	)
	
	first_name_usage[sex] = usage_by_sex
		
	return selected_name
	
func _select_surname(
	social_class: String,
	available_surnames: Dictionary,
	used_surnames: Dictionary
) -> String:
	
	var candidates: Array[String] = []
	var seen: Dictionary = {}
	
	for surname in available_surnames[social_class]:
		
		if typeof(surname) != TYPE_STRING:
			continue
			
		var normalized: String = surname.strip_edges().to_lower()
		
		if normalized.is_empty():
			continue
		
		if used_surnames.has(normalized) or seen.has(normalized):
			continue
			
		candidates.append(surname)
		seen[normalized] = true
		
		if candidates.is_empty():
			return ""
		
		var selected_index: int = rng.randi_range(
			0,
			candidates.size() -1
		)
		
		var selected_surname: String = candidates[selected_index]
		var selected_keys: String = selected_surname.strip_edges().is_lower()
		
		used_surnames[selected_keys] = true
		
		for pool_class in available_surnames.keys():
		
			var pool: Array = available_surnames[pool_class]
			
			for i in range(pool.size() - 1, -1, -1):
				if pool[i].strip_edges().to_lower() == selected_keys:
					pool.remove_at(i)
					
			available_surnames[pool_class] = pool
			
		return selected_surnames
