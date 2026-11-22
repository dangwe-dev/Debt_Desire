extends RefCounted

class_name  FamilyGenerator


const PopulationDemography = preload(
	"res://Game/Scripts/Population/Population_Demography.gd"
)

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _init() -> void:
	rng.randomize()

func generate_families(
	origin: String,
	social_class: String,
	family_sizes: Array[int],
	available_surnames: Dictionary,
	used_surnames: Dictionary,
	starting_family_id: int = 0
) -> Array[Dictionary]:
	
	var families: Array[Dictionary] = []
	
	#Validate the social class
	if not PopulationDemography.FAMILY_SIZE_PROFILES.has(origin):
		push_error("Unknown Origin: " + origin)
		return families
		
	var origin_profiles: Dictionary = (
		PopulationDemography.FAMILY_SIZE_PROFILES[origin]
	)
		
	if not origin_profiles.has(social_class):
		push_error(
			"Unknown social class for " + origin + ": " + social_class
		)
		return families
		
	if not available_surnames.has(social_class):
		push_error(
			"Missing surname pool for " + origin + " " + social_class
		)
		return families
	
	if typeof(available_surnames[social_class]) != TYPE_ARRAY:
		push_error("Surname pool must be an Array.")
		return families
		
	if starting_family_id < 0:
		push_error("Family ID cannot be negative.")
		return families
		
	# Empty list = no families to generate
	if family_sizes.is_empty():
		return families
	
	#Validate all requested family sizes before making changes.
	
	var profile: Dictionary = origin_profiles[social_class]
	var allowed_sizes: Dictionary = profile["weights"]
	
	for family_size in family_sizes:
		if not allowed_sizes.has(family_size):
			push_error(
				"Invalid family size for " 
				+ origin + " " + social_class
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
			"Insufficient unique surnames for " 
			+ origin + social_class
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
		candidate_surnames.remove_at(surname_index)
		
		var family: Dictionary = {
			"family_id": starting_family_id + i,
			"origin": origin,
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
