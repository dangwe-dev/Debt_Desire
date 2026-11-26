extends RefCounted

class_name Family_Head_Generator

const AGE_GROUP_WEIGHTS := {
	"Aristocrat": {
		"Elder": 70.0,
		"Adult": 20.0,
		"Teenager": 10.0,
		"Child": 0.0
	},
	"Gentile": {
		"Elder": 70.0,
		"Adult": 20.0,
		"Teenager": 10.0,
		"Child": 0.0
	},
	"Commoner": {
		"Elder": 30.0,
		"Adult": 50.0,
		"Teenager": 20.0,
		"Child": 0.0
	},
	"Vagrant": {
		"Elder": 30.0,
		"Adult": 50.0,
		"Teenager": 20.0,
		"Child": 0.0
	}
}

const SEX_WEIGHTS := {
	"Aristocrat": {
		"male": 70.0,
		"female": 30.0
	},
	"Gentile": {
		"male": 70.0,
		"female": 30.0
	},
	"Commoner": {
		"male": 50.0,
		"female": 50.0
	},
	"Vagrant": {
		"male": 50.0,
		"female": 50.0
	},
}

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _init() -> void:
	rng.randomize()
	
func assign_family_heads(
	families: Array[Dictionary],
	citizens: Array[Dictionary]
) -> Array[Dictionary]:
	
	if families.is_empty():
		push_error("Family Head Generator: Families array is empty.")
		return []
		
	if citizens.is_empty():
		push_error("Family Head Generator: Citizens arrauy is empty.")
		return []
		
	var family_classes: Dictionary = {}
	var members_by_family: Dictionary = {}
	
	
	for family in families:
		if not family.has("family_id") or not family.has("social_class"):
			push_error("Family Head Generator: Family is missing required data.")
			return []

		var family_id: int = family["family_id"]
		var social_class: String = family["social_class"]
		
		if not AGE_GROUP_WEIGHTS.has(social_class):
			push_error(
				"Family Head Generator: Unknown social class %s."
				% social_class
			)
			return []
			
		if family_classes.has(family_id):
			push_error(
				"Family Head Generator: Duplicate family ID %d."
				% family_id
			)
			return []
			
		family_classes[family_id] = social_class
		members_by_family[family_id] = []
		
	for i in range(citizens.size()):
		var citizen: Dictionary = citizens[i]
		
		for key in ["citizen_id", "family_id", "sex", "age_group"]:
			if not citizen.has(key):
				push_error(
					"Family Head Generator: Citizen is missing %s." % key
				)
				return []
				
		var family_id: int = citizen["family_id"]
		
		if not members_by_family.has(family_id):
			push_error(
				"Family Head Generator: Citizen references unknown family %d."
				% family_id
			)
			return []
			
		if citizen["sex"] not in ["male", "female"]:
			push_error("Family Head Generator: Invalid citizen sex.")
			return []
			
		members_by_family[family_id].append(i)
		
	var result: Array[Dictionary] = []
	
	for citizen in citizens:
		var copy: Dictionary = citizen.duplicate(true)
		copy["family_position"] = "HOUSEHOLD_MEMBER"
		result.append(copy)
		
	for family_id in family_classes:
		var social_class: String = family_classes[family_id]
		var member_indices: Array = members_by_family[family_id]
		
		if member_indices.is_empty():
			push_error(
				"Family Head Generator: Family %d has no citizens."
				% family_id
			)
			return []
			
		var head_index: int = _select_head_index(
			member_indices,
			citizens,
			AGE_GROUP_WEIGHTS[social_class],
			SEX_WEIGHTS[social_class]
		)
		
		if head_index == -1:
			push_error(
				"Family Head Generator: Could not select head for family %d."
				% family_id
			)
			return []
			
		result[head_index]["family_position"] = "HEAD_OF_FAMILY"
	
	return result
	
func _select_head_index(
	member_indices: Array,
	citizens: Array[Dictionary],
	age_weights: Dictionary,
	sex_weights: Dictionary
) -> int:
	
	var available_age_weights: Dictionary = {}
	
	for age_group in age_weights:
		if age_weights[age_group] <= 0.0:
			continue
			
		for index in member_indices:
			if citizens[index]["age_group"] == age_group:
				available_age_weights[age_group] = age_weights[age_group]
				break
				
	if available_age_weights.is_empty():
		return -1
		
	var selected_age_group: String = _weighted_choice(
		available_age_weights
	)
	
	var candidates_by_sex: Dictionary = {
		"male": [],
		"female": []
	}
	for index in member_indices:
		var citizen: Dictionary = citizens[index]
		
		if citizen["age_group"] == selected_age_group:
			candidates_by_sex[citizen["sex"]].append(index)
			
	var available_sex_weights: Dictionary = {}
	
	for sex in sex_weights:
		if not candidates_by_sex[sex].is_empty():
			available_sex_weights[sex] = sex_weights[sex]
			
	var selected_sex: String
	
	if available_sex_weights.size() == 1:
		selected_sex = available_sex_weights.keys()[0]
	else:
		selected_sex = _weighted_choice(available_sex_weights)
		
	var selected_candidates: Array = candidates_by_sex[selected_sex]
	
	var selected_index: int = selected_candidates[0]
	
	for index in selected_candidates:
		if citizens[index]["citizen_id"] < citizens[selected_index]["citizen_id"]:
			selected_index = index
			
	return selected_index
	
func _weighted_choice(weights: Dictionary) -> String:
	
	var total_weight: float = 0.0
	
	for weight in weights.values():
		total_weight += float(weight)
		
	if total_weight <= 0.0:
		return ""
		
	var roll: float = rng.randf_range(0.0, total_weight)
	var cumulative_weight: float = 0.0
	
	for key in weights:
		cumulative_weight += float(weights[key])
		
		if roll < cumulative_weight:
			return str(key)
		
	return str(weights.keys()[-1])
	
		
