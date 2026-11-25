extends RefCounted

class_name Age_Group_Generator

const AGE_GROUPS := [
	"Elder",
	"Adult",
	"Teenager",
	"Child"
]

const UPPER_CLASSES := [
	"Aristocrat",
	"Gentile"
]

const VALID_CLASSES := [
	"Aristocrat",
	"Gentile",
	"Commoner",
	"Vagrant"
]

const GENERAL_WEIGHTS := {
	"Aristocrat": {
		"Elder": 10.0,
		"Adult": 40.0,
		"Teenager": 25.0,
		"Child": 25.0
	},
	"Gentile": {
		"Elder": 10.0,
		"Adult": 40.0,
		"Teenager": 25.0,
		"Child": 25.0
	},
	"Commoner": {
		"Elder": 20.0,
		"Adult": 50.0,
		"Teenager": 15.0,
		"Child": 15.0
	},
	"Vagrant": {
		"Elder": 20.0,
		"Adult": 50.0,
		"Teenager": 15.0,
		"Child": 15.0
	}
} 
const NON_ADULT_WEIGHTS := {
	"Aristocrat": {
		"Elder": 30.0,
		"Teenager": 40.0,
		"Child": 30.0
	},
	"Gentile": {
		"Elder": 30.0,
		"Teenager": 40.0,
		"Child": 30.0
	},
	"Commoner": {
		"Elder": 40.0,
		"Teenager": 30.0,
		"Child": 30.0
	},
	"Vagrant": {
		"Elder": 40.0,
		"Teenager": 30.0,
		"Child": 30.0
	}
}


var _rng := RandomNumberGenerator.new()

func assign_age_groups(
	families: Array[Dictionary],
	citizens: Array[Dictionary]
) -> Array[Dictionary]:
	
	_rng.randomize()
	
	if not _validate_input(families, citizens):
		return []
		
	var members_by_family: Dictionary = {}
	
	for i in range(citizens.size()):
		var family_id: int = citizens[i]["family_id"]
		
		if not members_by_family.has(family_id):
			members_by_family[family_id] = []
			
		members_by_family[family_id].append(i)
		
	var assignments: Dictionary = {}
	
	for family in families:
		var family_id: int = family["family_id"]
		var social_class: String = family["social_class"]
		var members: Array = members_by_family[family_id]
		var member_count: int = members.size()
		
		if not _assign_family_ages(
			members,
			member_count,
			social_class,
			citizens,
			assignments
		):
			push_error(
				"Age group generator: Failed to assign ages to family %d."
				% family_id
			)
			return []
		
	var result: Array[Dictionary] = []
	
	for i in range(citizens.size()):
		var citizen: Dictionary = citizens[i].duplicate(true)
		
		if not assignments.has(i):
			push_error(
				"Age group generator: Citizen %d has no age assignment."
				% citizen["citizen_id"]
			)
			return []
			
		citizen["age_group"] = assignments[i]
		result.append(citizen)
		
	return result
	
func _assign_family_ages(
	members: Array,
	member_count: int,
	social_class: String,
	citizens: Array[Dictionary],
	assignments: Dictionary
) -> bool:
	
	var is_upper_class: bool = social_class in UPPER_CLASSES
	
	if member_count == 1:
		return _assign_random_member(
			members, "Adult", assignments
		)
	
	if member_count == 2 and is_upper_class:
		if not _assign_random_member(
			members, "Elder", assignments
		):
			return false
		
		var remaining_member: int = _get_unassigned_member(
			members, assignments
		)
		
		if remaining_member == -1:
			return false
		
		assignments[remaining_member] = _weighted_choice(
			GENERAL_WEIGHTS[social_class]
		)
		return true
		
	if member_count == 2:
		if not _assign_random_member(
			members, "Adult", assignments
		):
			return false
			
	if is_upper_class and member_count >= 3:
		if not _assign_random_member(
			members, "Elder", assignments
		):
			return false
			
		if not _assign_random_member(
			members, "Adult", assignments
		):
			return false
			
	elif social_class == "Commoner" and member_count >= 3:
		if not _assign_random_member_of_sex(
			members, "male", citizens, "Adult", assignments
		):
			return false
			
		if not _assign_random_member_of_sex(
			members, "female", citizens, "Adult", assignments
		):
			return false
		
		
	var required_non_adults: int = 0
	
	if member_count >= 4:
		required_non_adults = 1
		
	if member_count > 5:
		required_non_adults = 2
		
	var current_non_adults: int = _count_non_adults(
		members, assignments
	)
	while current_non_adults < required_non_adults:
		var age_group: String = _weighted_choice(
			NON_ADULT_WEIGHTS[social_class]
		)
		
		if not _assign_random_member(members,age_group, assignments):
			return false
			
		current_non_adults += 1
	
			
	if member_count > 6:
		for age_group in AGE_GROUPS:
			if not _has_age_group(members, age_group, assignments):
				if not _assign_random_member(members, age_group, assignments):
					return false
	
	while _get_unassigned_member(members, assignments) != -1:
		var age_group: String = _weighted_choice(
			GENERAL_WEIGHTS[social_class]
		)
		
		if not _assign_random_member(members, age_group, assignments):
			return false
	
	return true
	
func _family_has_assigned_sex(
	members: Array,
	sex: String,
	citizens: Array[Dictionary],
	assignments: Dictionary
) -> bool:
	
	for index in members:
		if citizens[index]["sex"] == sex and assignments.has(index):
			return true
			
	return false
	
func _validate_input(
	families: Array[Dictionary],
	citizens: Array[Dictionary]
) -> bool:
	
	if families.is_empty():
		push_error("Age Group Generator: Families array is empty.")
		return false
		
	if citizens.is_empty():
		push_error("Age Group Generator: Citizens array is empty.")
		return false
		
	var family_ids: Dictionary = {}
	var citizen_ids: Dictionary = {}
	var expected_member_counts: Dictionary = {}
	
	for family in families:
		if not family.has("family_id"):
			push_error("Age Group Generator: Family missing family_id.")
			return false
			
		if not family.has("member_count"):
			push_error("Age Group Generator: Family missing member_count.")
			return false
			
		if not family.has("social_class"):
			push_error("Age Group Generator: Family missing social_class.")
			return false
			
		var family_id = family["family_id"]
		var member_count = family["member_count"]
		var social_class = family["social_class"]
		
		if typeof(family_id) != TYPE_INT:
			push_error("Age Group Generator: Invalid family_id.")
			return false
			
		if family_ids.has(family_id):
			push_error("Age Group Generator: Duplicate family_id.")
			return false
			
		if typeof(member_count) != TYPE_INT or member_count < 1:
			push_error("Age Group Generator: Invalid member_count.")
			return false
			
		if typeof(social_class) != TYPE_STRING:
			push_error("Age Group Generator: Invalid social_class.")
			return false
			
		if social_class not in VALID_CLASSES:
			push_error(
				"Age Group Generator: Unknown social class %s."
				% social_class
			)
			return false
			
		family_ids[family_id] = true
		expected_member_counts[family_id] = member_count
		
	var actual_member_counts: Dictionary = {}
	
	for citizen in citizens:
		if not citizen.has("citizen_id"):
			push_error("Age Group Generator: Citizen missing citizen_id.")
			return false
			
		if not citizen.has("family_id"):
			push_error("Age Group Generator: Citizen missing family_id.")
			return false
			
		if not citizen.has("sex"):
			push_error("Age Group Generator: citizen missing sex.")
			return false
			
		var citizen_id = citizen["citizen_id"]
		var family_id = citizen["family_id"]
		var sex = citizen["sex"]
		
		if typeof(citizen_id) != TYPE_INT:
			push_error("Age Group Generator: Invalid citizen_id.")
			return false
			
		if citizen_ids.has(citizen_id):
			push_error("Age Group Generator: Duplicate citizen_id.")
			return false
			
		if typeof(family_id) != TYPE_INT:
			push_error("Age Group Generator: Invalid citizen family_id.")
			return false
			
		if not family_ids.has(family_id):
			push_error(
				"Age Group Generator: Citizen references unknown family."
			)
			return false
			
		if sex not in ["male", "female"]:
			push_error("Age Group Generator: Invalid citizen sex.")
			return false
			
		citizen_ids[citizen_id] = true
		
		actual_member_counts[family_id] = (
			actual_member_counts.get(family_id, 0) + 1
		)
		
	for family_id in family_ids:
		var expected: int = expected_member_counts[family_id]
		var actual: int = actual_member_counts.get(family_id, 0)
		
		if actual != expected:
			push_error(
				"Age Group Generator: Family %d expected %d members, found %d."
				% [family_id, expected, actual]
			)
			return false
	return true
	
func _assign_random_member(
	members: Array,
	age_group: String,
	assignments: Dictionary
) -> bool:
	
	var index: int = _get_unassigned_member(
		members, assignments
	)
	
	if index == -1:
		return false
	
	assignments[index] = age_group
	return true
	
func _assign_random_member_of_sex(
	members: Array,
	sex: String,
	citizens: Array[Dictionary],
	age_group: String,
	assignments: Dictionary
) -> bool:
	
	var candidates: Array[int] = []
	
	for index in members:
		if assignments.has(index):
			continue
			
		if citizens[index]["sex"] == sex:
			candidates.append(index)
			
	if candidates.is_empty():
		push_error(
			"Age Group Generator: No available %s citizen for %s assignment."
			% [sex, age_group]
		)
		return false
		
	var selected_index: int = candidates[
		_rng.randi_range(0, candidates.size() -1)
	]
	
	assignments[selected_index] = age_group
	return true
	
func _get_unassigned_member(
	members: Array,
	assignemnts: Dictionary
) -> int:
	
	var candidates: Array[int] = []
	
	for index in members:
		if not assignemnts.has(index):
			candidates.append(index)
			
	if candidates.is_empty():
		return -1
		
	return candidates[
		_rng.randi_range(0, candidates.size() -1)
	]
	
func _has_age_group(
	members: Array,
	age_group: String,
	assignments: Dictionary
) -> bool:
	
	for index in members:
		if assignments.get(index, "") == age_group:
			return true
			
	return false
	
func _count_non_adults(
	members: Array,
	assignments: Dictionary
) -> int:
	
	var count: int = 0
	
	for index in members:
		var age_group: String = assignments.get(index, "")
		
		if age_group in ["Elder", "Teenager", "Child"]:
			count += 1
			
	return count
	
func _weighted_choice(weights: Dictionary) -> String:
	
	var total_weight: float = 0.0
	
	for weight in weights.values():
		total_weight += float(weight)
		
	var roll: float = _rng.randf_range(0.0, total_weight)
	var cumulative_weight: float = 0.0
	
	for age_group in weights:
		cumulative_weight += float(weights[age_group])
		
		if roll < cumulative_weight:
			return age_group
			
	return weights.keys()[-1]
