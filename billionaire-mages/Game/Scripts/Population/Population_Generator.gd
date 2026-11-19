extends RefCounted

class_name Population_Generator

const PopulationData = preload(
	"res://Game/Scripts/Data/Population_Data.gd"
	)

const PopulationDemography = preload(
	"res://Game/Scripts/Population/Population_Demography.gd"
)

const FamilyGenerator = preload(
	"res://Game/Scripts/Population/Family_Generator.gd"
	)

func generate_family_population(
	baseline_population: int = BASELINE_POPULATION
) -> Dictionary:
	
	#Validate reqwuested population
	if baseline_population <= 0:
		push_error("Baseline population must be greater than zero.")
		return{}
	
	#Generate social-class distribution
	var class_distribution: Dictionary = (
		demography.generate_class_distribution(baseline_population)
	)
	
	if class_distribution.is_empty():
		return{}
		
	#Allocate family members and solitary citizens
	var family_demography: Dictionary = (
		generate_family_demography(class_distribution)
	)
	if family_demography.is_empty():
		return{}
	
	#Load Surname Data
	var data_loader = PopulationData.new()
	var available_surnames: Dictionary = (
		data_loader.load_surnames()
	)
	
	if available_surnames.is_empty():
		return{}
	
	var used_surnames: Dictionary = {}
	
	var all_families: Array[Dictionary] = []
	var family_sizes_by_class: Dictionary = {}
	
	var next_family_id: int = 0
	var total_family_members: int = 0
	var total_solitary_citizens: int = 0
	
	#Generate family class by class
	for social_class in Class_Weights:
		
		var class_data: Dictionary = (
			family_demography[social_class]
		)
		
		var requested_members: int = (
			class_data["family_members"]
		)
		
		var solitary_count: int = (
			class_data["solitary_citizens"]
		)
		
		total_solitary_citizens += solitary_count
		
		var family_sizes: Array[int] = generate_family_sizes(
			social_class,
			requested_members
		)
		
		var allocated_members: int = 0
		
		for family_size in family_sizes:
			allocated_members += family_size
			
		if allocated_members != requested_members:
			push_error(
				"Family-size allocation mismatch for "
				+ social_class
			)
			return {}
			
		family_sizes_by_class[social_class] = family_sizes
		
		var generated_families: Array[Dictionary] = (
			generate_families(
				social_class,
				family_sizes,
				available_surnames,
				used_surnames,
				next_family_id
			)
		)
		
		if generated_families.size() != family_sizes.size():
			push_error(
				"Family generation failed for " + social_class
			)
			return{}
			
		all_families.append_array(generated_families)
		
		next_family_id += generated_families.size()
		total_family_members += allocated_members
		
	var generated_population: int = (
		total_family_members + total_solitary_citizens
	)
	
	if generated_population != baseline_population:
		push_error(
			"Population total mismatch. Expected: "
			+ str(baseline_population)
			+ ", generated: "
			+ str(generated_population)
		)
		return{}
		
	return{
		"class_distribution": class_distribution,
		"family_demography": family_demography,
		"family_sizes": family_sizes_by_class,
		"families": all_families,
		"used_surnames": used_surnames,
		"total_family_members": total_family_members,
		"total_solitary_citizens": total_solitary_citizens,
		"total_families": all_families.size(),
		"total_population": generated_population
		}
