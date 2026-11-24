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
	
const CitizenGenerator = preload(
	"res://Game/Scripts/Population/Citizen_Generator.gd"
)


const BASELINE_POPULATION: int = (
	PopulationDemography.BASELINE_POPULATION
)

const EXPECTED_ORIGINS: Array[String] = [
	"Local",
	"Foreign"
]

func generate_population(
	baseline_population: int = BASELINE_POPULATION
) -> Dictionary:
	
	if baseline_population <= 0:
		push_error("Baseline population must be greater than zero.")
		return {}
		
	var demography = PopulationDemography.new()
	var family_generator = FamilyGenerator.new()
	var citizen_generator = CitizenGenerator.new()
	var data_loader = PopulationData.new()
	
	var available_surnames: Dictionary = (
		data_loader.load_surnames()
	)
	
	if available_surnames.is_empty():
		return {}
		
	
	var first_names: Dictionary = (
		data_loader.load_first_names()
	)
	
	if first_names.is_empty():
		return {}
		
	var used_surnames: Dictionary = {
		"Local": {},
		"Foreign": {}
	}
	
	var class_distribution: Dictionary = (
		demography.generate_class_distribution(
			baseline_population
		)
	)
	
	if class_distribution.is_empty():
		return {}
	
	var origin_distribution: Dictionary = (
		demography.generate_origin_distribution(
			class_distribution
		)
	)
	
	if origin_distribution.is_empty():
		return {}
	
	var all_families: Array[Dictionary] = []
	var family_sizes_by_origin: Dictionary = {
		"Local": {},
		"Foreign": {}
	}
	
	var next_family_id: int = 0
	var total_family_members: int = 0
	
	for social_class in class_distribution:
		
		var class_origins: Dictionary = (
			origin_distribution[social_class]
		)
		
		for origin in EXPECTED_ORIGINS:
			
			var requested_members: int = (
				class_origins[origin]
			)
			
			var family_sizes: Array[int] = (
				demography.generate_family_sizes(
					origin,
					social_class,
					requested_members
				)
			)
			
			var allocated_members: int = 0
			
			for family_size in family_sizes:
				allocated_members += family_size
				
			if allocated_members != requested_members:
				push_error(
					"Family size allocation mismatch for "
					+ origin + " " + social_class
					+ ". Expected: "
					+ str(requested_members)
					+ ", allocated: "
					+ str(allocated_members)
				)
				return {}
				
			family_sizes_by_origin[origin][social_class] = (
				family_sizes
			)
			
			var generated_families: Array[Dictionary] = (
				family_generator.generate_families(
					origin,
					social_class,
					family_sizes,
					available_surnames[origin],
					used_surnames[origin],
					next_family_id
				)
			)
			
			if generated_families.size() != family_sizes.size():
				push_error(
					"Family generation failed for "
					+ origin + " " + social_class
				)
				return {}
				
			all_families.append_array(generated_families)
			
			next_family_id += generated_families.size()
			total_family_members += allocated_members
			
	if total_family_members != baseline_population:
		push_error(
			"Family population mismatch. Expected: "
			+ str(baseline_population)
			+ ", generated: "
			+ str(total_family_members)
		)
		return {}
		
	var all_citizens: Array[Dictionary] = (
		citizen_generator.generate_citizens(
			all_families,
			first_names,
			0
		)
	)
	
	if all_citizens.size() != baseline_population:
		push_error(
			"Citizen generater failed.  Expected: "
			+ str(baseline_population)
			+ ", generated: "
			+ str(all_citizens.size())
		)
		return {}
		
		
	return {
		"class_distribution": class_distribution,
		"origin_distribution": origin_distribution,
		"family_sizes": family_sizes_by_origin,
		"families": all_families,
		"citizens": all_citizens,
		"used_surnames": used_surnames,
		"total_families": all_families.size(),
		"total_family_members": total_family_members,
		"total_citizens": all_citizens.size(),
		"total_population": all_citizens.size()
	}
