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
	
	if family_member_count < 0:
		push_error("family member clount cannot be negative.")
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
	
func generate_families(
	social_class: String,
	family_sizes: Array[int],
	available_surnames: Dictionary,
	used_surnames: Dictionary,
	starting_family_id: int = 0
) -> Array[Dictionary]:
	
	var families: Array[Dictionary] = []
	
	#Validate the social class
	if not FAMILY_SIZE_PROFILES.has(social_class):
		push_error("Unknown Social Class: " + social_class)
		return families
		
	if not available_surnames.has(social_class):
		push_error("Missing surname pool for " + social_class)
		return families
		
	if starting_family_id < 0:
		push_error("Family ID cannot be negative.")
		return families
		
	# Empty list = no families to generate
	if family_sizes.is_empty():
		return families
	
	#Validate all requested family sizes before making changes.
	
	var profile: Dictionary = FAMILY_SIZE_PROFILES[social_class]
	var allowed_sizes: Dictionary = profile["weights"]
	
	for family_size in family_sizes:
		if not allowed_sizes.has(family_size):
			push_error(
				"Invalid family size for " + social_class
				+ ": " + str(family_size)
			)
			return families
	
	#Build a list of unique currently available surnames.
	var surname_pool: Array = available_surnames[social_class]
	var candidate_surnames: Array[String] = []
	var candidate_lookup: Dictionary = {}
	
	for surname in surname_pool:
		if(
			typeof(surname) == TYPE_STRING
			and not surname.is_empty()
			and not used_surnames.has(surname)
			and not candidate_lookup.has(surname)
		):
			candidate_surnames.append(surname)
			candidate_lookup[surname] = true
	
	#Check capacity before assigning anything.
	if candidate_surnames.size() < family_sizes.size():
		push_error(
			"Insufficient unique surnames for " + social_class
			+ ". Required: " + str(family_sizes.size())
			+ ". Available: " + str(candidate_surnames.size())
		)
		return families
	
	#Generate one record per family.
	for i in range(family_sizes.size()):
		
		var surname_index: int = rng.randi_range(
			0,
			candidate_surnames.size() - 1
		)
		
		var selected_surname: String = candidate_surnames[
			surname_index
		]
		
		var family: Dictionary = {
			"family_id": starting_family_id + i,
			"social_class": social_class,
			"surname": selected_surname,
			"member_count": family_sizes[i]
		}
		families.append(family)
		
		#Register the surname globally.
		used_surnames[selected_surname] = true
		
		#remove it from every class pool, not just the current one.
		for pool_class in available_surnames:
			
			var pool: Array = available_surnames[pool_class]
			
			while pool.has(selected_surname):
				pool.erase(selected_surname)
				
			available_surnames[pool_class] = pool
			
	return families
