extends RefCounted

class_name Population_Demography

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _init() -> void:
	rng.randomize()
	
	
const BASELINE_POPULATION: int = 1000
	
	
const CLASS_WEIGHTS: Dictionary = {
	
	"Aristocrat": 0.135,
	"Gentile": 0.140,
	"Commoner": 0.504,
	"Vagrant": 0.221
}

const ORIGIN_WEIGHTS: Dictionary = {
	"Local": {
		"Aristocrat": 0.926,
		"Gentile": 0.893,
		"Commoner": 0.881,
		"Vagrant": 0.819
	},
	"Foreign": {
		"Aristocrat": 0.074,
		"Gentile": 0.107,
		"Commoner": 0.119,
		"Vagrant": 0.181
	}
}

const FAMILY_SIZE_PROFILES: Dictionary = {
	"Local": {
		"Aristocrat": 
			{
				"min_size": 4,
				"weights":
					{
						4: 5, 
						5: 15,
						6: 40,
						7: 30,
						8: 10
					}
			},
		"Gentile":
			{
				"min_size": 4,
				"weights":
					{
						4: 5,
						5: 15,
						6: 40,
						7: 30,
						8: 10
					}
			},
		"Commoner": 
			{
				"min_size": 2,
				"weights":
					{
						2: 15,
						3: 25,
						4: 20,
						5: 15,
						6: 10,
						7: 5,
						8: 4,
						9: 3,
						10: 3
					}
			},
		"Vagrant":
			{
				"min_size": 2,
				"weights":
					{
						2: 10.3,
						3: 20.5,
						4: 20.5,
						5: 17.9,
						6: 12.8,
						7: 10.3,
						8: 7.7
					}
			}
	},
	"Foreign": {
		"Aristocrat": {
			"min_size": 1,
			"weights": {
				1: 5,
				2: 15,
				3: 40,
				4: 30,
				5: 10
			}
		},
		"Gentile": {
			"min_size": 1,
			"weights": {
				1: 5,
				2: 15,
				3: 40,
				4: 30,
				5: 10
			}
		},
		"Commoner": {
			"min_size": 2,
			"weights": {
				2: 15,
				3: 25,
				4: 20,
				5: 15,
				6: 10,
				7: 5,
				8: 4,
				9: 3,
				10: 3
			}
		},
		"Vagrant": {
			"min_size": 2,
			"weights": {
				2: 10.3,
				3: 20.5,
				4: 20.5,
				5: 17.9,
				6: 12.8,
				7: 10.3,
				8: 7.7
			}
		}
	}		
}


func generate_class_distribution(
	baseline_population: int = BASELINE_POPULATION
	) -> Dictionary:
	
	if baseline_population <= 0:
		push_error("Baseline population must be greater than zero.")
		return {}
	
	var distribution: Dictionary = {}
	var remainders: Dictionary = {}
	var allocated_population: int = 0
	
	
	# Calculate the initial whole-number allocations.
	
	for social_class in CLASS_WEIGHTS:
		var exact_count: float = (
			baseline_population * CLASS_WEIGHTS[social_class]
		)
	
		var whole_count: int = floori(exact_count)
		
		distribution[social_class] = whole_count
		remainders[social_class] = exact_count - whole_count
		
		allocated_population += whole_count
	
	# Distribute remaining citizens using the largest remainders.
	var remaining_population: int = (
		baseline_population - allocated_population
	)
	
	while remaining_population > 0:
		var highest_class: String = ""
		var highest_remainder: float = -1.0
		
		for social_class in remainders:
			if remainders[social_class] > highest_remainder:
				highest_remainder = remainders[social_class]
				highest_class = social_class
				
		distribution[highest_class] += 1
		remainders[highest_class] = -1.0 
		
		remaining_population -= 1
	
	return distribution



func generate_origin_distribution(
	class_distribution: Dictionary
) -> Dictionary:
	
	var allocation: Dictionary = {}
	
	for social_class in class_distribution:
		
		if not ORIGIN_WEIGHTS["Local"].has(social_class):
			push_error("Unknown social class: " + str(social_class))
			return{}
		
		var class_population: int = class_distribution[social_class]
		
		if class_population < 0:
			push_error("Class population cannot be negative.")
			return{}
		
		var foreign_exact: float = (
			class_population * ORIGIN_WEIGHTS["Foreign"][social_class]
		)
		
		var local_exact: float = (
			class_population * ORIGIN_WEIGHTS["Local"][social_class]
		)
		
		
		var local_count: int = floori(local_exact)
		var foreign_count: int = class_population - local_count
		
		var remaining: int = (
			class_population - local_count - foreign_count
		)
		
		if remaining > 0:
			var local_remainder: float = local_exact - local_count
			var foreign_remainder: float = foreign_exact - foreign_count
			
			if local_remainder >= foreign_remainder:
				local_count += remaining
		
		allocation[social_class] = {
			"Local": local_count,
			"Foreign": foreign_count
		}
	
	return allocation

func generate_family_sizes(
	origin: String,
	social_class: String,
	family_member_count: int
) -> Array[int]:
	
	var family_sizes: Array [int] = []
	
	# Validate the requested social class.
	
	if not FAMILY_SIZE_PROFILES.has(origin):
		push_error("Unkown origin: " + origin)
		return family_sizes
	
	var origin_profiles: Dictionary = FAMILY_SIZE_PROFILES[origin]
	
	if not origin_profiles.has(social_class):
		push_error(
			"Unknown social class for origin "
			+ origin + ": "+ social_class
		)
		return family_sizes
		
		
	if family_member_count < 0:
		push_error("family member clount cannot be negative.")
		return family_sizes
	
	
	var profile: Dictionary = origin_profiles[social_class]
	var minimum_size: int = profile["min_size"]
	var size_weights: Dictionary = profile["weights"]
	
	if family_member_count == 0:
		return family_sizes
		
		
	if family_member_count < minimum_size:
		if family_member_count > 0:
			push_error(
				"Insufficient family members for " 
				+ origin + " " + social_class
			)
			return family_sizes
	
	var remaining_members: int = family_member_count
	
	while remaining_members > 0:
		
		var candidate_sizes: Array[int] = []
		var candidate_weights: PackedFloat32Array = (
			PackedFloat32Array()
		)
		
		# Only consider family sizes that leave a valid remainder.
		for family_size in size_weights:
			
			if family_size > remaining_members:
				continue
			
			var remainder: int = remaining_members - family_size
			
			if remainder == 0 or remainder >= minimum_size:
				candidate_sizes.append(family_size)
				candidate_weights.append(
					float(size_weights[family_size])
				)
			
			
		if candidate_sizes.is_empty():
			push_error(
				"Unable to allocate remaining family member for"
				+ social_class
				)
			return[]
		
		
	# Select one of the feasible sizes using weighted randomness.
		var selected_index: int = rng.rand_weighted(candidate_weights)
		var selected_size: int = candidate_sizes[selected_index]
		
		family_sizes.append(selected_size)
		remaining_members -= selected_size
	
	return family_sizes
	
