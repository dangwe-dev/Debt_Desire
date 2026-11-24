
extends SceneTree

const PopulationGenerator = preload(
	"res://Game/Scripts/Population/Population_Generator.gd"
)

var passed: int = 0
var failed: int = 0


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("\n========== POPULATION GENERATOR TESTS ==========\n")

	var generator = PopulationGenerator.new()
	var signatures: Array[String] = []

	for generation in range(3):
		var population: Dictionary = (
			generator.generate_population()
		)

		_check(
			not population.is_empty(),
			"Generation " + str(generation + 1) + " succeeds."
		)

		if population.is_empty():
			continue

		_validate_population(population)

		signatures.append(
			_get_population_signature(population)
		)

	if signatures.size() == 3:
		var populations_differ: bool = false

		for i in range(1, signatures.size()):
			if signatures[i] != signatures[0]:
				populations_differ = true
				break

		_check(
			populations_differ,
			"Repeated generations produce different populations."
		)

	print("\n========== RESULTS ==========")
	print("Passed: ", passed)
	print("Failed: ", failed)
	print("================================\n")

	quit()


func _validate_population(population: Dictionary) -> void:

	var families: Array = population["families"]
	var citizens: Array = population["citizens"]

	var class_distribution: Dictionary = (
		population["class_distribution"]
	)

	var origin_distribution: Dictionary = (
		population["origin_distribution"]
	)

	var family_sizes: Dictionary = (
		population["family_sizes"]
	)

	var expected_population: int = (
		population["total_population"]
	)

	_check(
		expected_population == 1000,
		"Population contains exactly 1000 citizens."
	)

	_check(
		citizens.size() == expected_population,
		"Citizen array matches the population total."
	)

	_check(
		population["total_citizens"] == citizens.size(),
		"Reported citizen total is correct."
	)

	_check(
		population["total_families"] == families.size(),
		"Reported family total is correct."
	)

	_check(
		population["total_family_members"] == citizens.size(),
		"Total family members match citizen count."
	)

	# Validate family IDs and surnames.

	var families_by_id: Dictionary = {}
	var surnames_by_origin: Dictionary = {
		"Local": {},
		"Foreign": {}
	}

	for i in range(families.size()):
		var family: Dictionary = families[i]

		var family_id: int = family["family_id"]
		var origin: String = family["origin"]
		var surname: String = family["surname"]
		var member_count: int = family["member_count"]

		_check(
			family_id == i,
			"Family IDs are sequential."
		)

		_check(
			not families_by_id.has(family_id),
			"Family IDs are unique."
		)

		families_by_id[family_id] = family

		_check(
			origin in ["Local", "Foreign"],
			"Family has a valid origin."
		)

		_check(
			member_count >= 1,
			"Every family has at least one member."
		)

		if surnames_by_origin.has(origin):
			_check(
				not surnames_by_origin[origin].has(surname),
				"Family surnames are unique within each origin."
			)

			surnames_by_origin[origin][surname] = true

	# Validate citizens and their family membership.

	var citizen_ids: Dictionary = {}
	var actual_family_members: Dictionary = {}

	var actual_class_counts: Dictionary = {}
	var actual_origin_counts: Dictionary = {}

	for social_class in class_distribution:
		actual_class_counts[social_class] = 0

		actual_origin_counts[social_class] = {
			"Local": 0,
			"Foreign": 0
		}

	for i in range(citizens.size()):
		var citizen: Dictionary = citizens[i]

		var citizen_id: int = citizen["citizen_id"]
		var family_id: int = citizen["family_id"]
		var social_class: String = citizen["social_class"]
		var origin: String = citizen["origin"]

		_check(
			citizen_id == i,
			"Citizen IDs are sequential."
		)

		_check(
			not citizen_ids.has(citizen_id),
			"Citizen IDs are unique."
		)

		citizen_ids[citizen_id] = true

		_check(
			families_by_id.has(family_id),
			"Every citizen belongs to an existing family."
		)

		if not families_by_id.has(family_id):
			continue

		var family: Dictionary = families_by_id[family_id]

		_check(
			citizen["surname"] == family["surname"],
			"Citizen inherits their family's surname."
		)

		_check(
			citizen["origin"] == family["origin"],
			"Citizen origin matches their family."
		)

		_check(
			citizen["social_class"] == family["social_class"],
			"Citizen class matches their family."
		)

		actual_family_members[family_id] = (
			actual_family_members.get(family_id, 0) + 1
		)

		actual_class_counts[social_class] += 1
		actual_origin_counts[social_class][origin] += 1

	# Validate actual family membership against declared sizes.

	for family_id in families_by_id:
		var family: Dictionary = families_by_id[family_id]

		var actual_count: int = (
			actual_family_members.get(family_id, 0)
		)

		_check(
			actual_count == family["member_count"],
			"Family member count matches its citizen records."
		)

	# Validate class and origin allocations.

	for social_class in class_distribution:
		_check(
			actual_class_counts[social_class]
			== class_distribution[social_class],
			social_class + " population matches its allocation."
		)

		for origin in ["Local", "Foreign"]:
			_check(
				actual_origin_counts[social_class][origin]
				== origin_distribution[social_class][origin],
				social_class + " " + origin
				+ " population matches its allocation."
			)

	# Validate family-size allocations.

	for origin in ["Local", "Foreign"]:
		for social_class in class_distribution:
			var sizes: Array = (
				family_sizes[origin][social_class]
			)

			var allocated_members: int = 0

			for size in sizes:
				allocated_members += size

			_check(
				allocated_members
				== origin_distribution[social_class][origin],
				origin + " " + social_class
				+ " family sizes match their allocation."
			)


func _get_population_signature(
	population: Dictionary
) -> String:

	var signature: String = ""

	for citizen in population["citizens"]:
		signature += (
			str(citizen["first_name"])
			+ "|"
			+ str(citizen["surname"])
			+ "|"
			+ str(citizen["origin"])
			+ "|"
			+ str(citizen["social_class"])
			+ ";"
		)

	return signature


func _check(condition: bool, description: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAILED: " + description)
