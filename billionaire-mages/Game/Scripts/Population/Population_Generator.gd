extends RefCounted

class_name Population_Generator

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
			if remainders[social_class] > remainders:
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
