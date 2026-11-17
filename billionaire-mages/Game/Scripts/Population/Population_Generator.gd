extends RefCounted

class_name Population_Generator

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _init() -> void:
	rng.randomize()

const BASELINE_POPULATION: int = 1000

const Class_Weights: Dictionary = {
	
	"Oligarch": 0.135,
	"Gentile": 0.140,
	"Commoner": 0.504,
	"Vagrant": 0.221
}

const FAMILY_WEIGHTS: Dictionary = {
	
	"Oligarch": 0.9259,
	"Gentile": 0.8929,
	"Commoner": 0.8810,
	"Vagrant": 0.8190
}

const FAMILY_SIZE_PROFILES: Dictionary = {
	
	"Oligarch": 
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
	
	for social_class in Class_Weights:
		var exact_count: float = (
			baseline_population * Class_Weights[social_class]
		)
	
		var whole_count: int = floor(exact_count)
		
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


func generate_family_demography(class_distribution: Dictionary) -> Dictionary:
	
	var allocation: Dictionary = {}
	
	for social_class in class_distribution:
		
		var class_population: int = class_distribution[social_class]
		
		var family_members: int = roundi(
			class_population * FAMILY_WEIGHTS[social_class]
		)
		
		var solitary_citizens: int = (
			class_population - family_members
		)
		allocation[social_class] = {
			"family_members": family_members,
			"solitary_citizens": solitary_citizens
		}
	
	return allocation

func generate_family_sizes(
	social_class: String,
	family_member_count: int
) -> Array[int]:
	
	var family_sizes: Array [int] = []
	
	# Validate the requested social class.
	
	if not FAMILY_SIZE_PROFILES.has(social_class):
		push_error("Unkown Social Class: " + social_class)
		return family_sizes
		
	var profile: Dictionary = FAMILY_SIZE_PROFILES[social_class]
	var minimum_size: int = profile["min_size"]
	var size_weights: Dictionary = profile["weights"]
	
	# No family can be generated below the class minimum.
	if family_member_count < minimum_size:
		if family_member_count > 0:
			push_error(
				"Insufficient family members for " + social_class
			)
			
		return family_sizes
	
	var remaining_members: int = family_member_count
	
	while remaining_members > 0:
		
		var candidate_sizes: Array[int] = []
		var candidate_weights: PackedFloat32Array = PackedFloat32Array()
		
		# Only consider family sizes that leave a valid remainder.
		for family_size in size_weights:
			
			var remainder: int = remaining_members - family_size
			
			if remainder == 0 or remainder >= minimum_size:
				candidate_sizes.append(family_size)
				candidate_weights.append(float(size_weights[family_size]))
				
	# Select one of the feasible sizes using weighted randomness.
		var selected_index: int = rng.rand_weighted(candidate_weights)
		var selected_size: int = candidate_sizes[selected_index]
		
		family_sizes.append(selected_size)
		remaining_members -= selected_size
	
	return family_sizes
