extends SceneTree

const PopulationGenerator = preload(
	"res://Game/Scripts/Population/Population_Generator.gd"
)
const AgeGroupGenerator = preload(
	"res://Game/Scripts/Population/Age_Group_Generator.gd"
)
const FamilyHeadGenerator = preload(
	"res://Game/Scripts/Population/Family_Head_Generator.gd"
)

var passed: int = 0
var failed: int = 0


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("\n========== POPULATION + FAMILY HEAD INTEGRATION TEST ==========\n")

	for population_size in [1000, 1500]:
		print("\n--- Target population: ", population_size, " ---")

		for run_index in range(3):
			print("\nGeneration ", run_index + 1)
			_test_generation(population_size)

	print("\n========== RESULTS ==========")
	print("Passed: ", passed)
	print("Failed: ", failed)
	print("============================================================\n")

	quit()


func _test_generation(population_size: int) -> void:
	var population: Dictionary = PopulationGenerator.new().generate_population(population_size)

	_check(not population.is_empty(), "Population generation succeeds.")
	if population.is_empty():
		return

	var families: Array[Dictionary] = population["families"]
	var original_citizens: Array[Dictionary] = population["citizens"]

	_check(
		original_citizens.size() == population_size,
		"Generated citizen count matches requested population"
	)
	_check(
		population["total_population"] == population_size,
		"Reported population matches requested population."
	)

	var age_generator = AgeGroupGenerator.new()
	var age_assigned: Array[Dictionary] = (
		age_generator.assign_age_groups(families, original_citizens)
	)

	_check(
		age_assigned.size() == original_citizens.size(),
		"Age assignment preserves citizen count."
	)
	if age_assigned.is_empty():
		return

	var head_generator = FamilyHeadGenerator.new()
	var headed_citizens: Array[Dictionary] = (
		head_generator.assign_family_heads(families, age_assigned)
	)

	_check(
		headed_citizens.size() == age_assigned.size(),
		"Family-head assignment preserves citizen count."
	)
	if headed_citizens.is_empty():
		return

	_validate_heads(families, original_citizens, age_assigned, headed_citizens)


func _validate_heads(
	families: Array[Dictionary],
	original_citizens: Array[Dictionary],
	age_assigned: Array[Dictionary],
	headed_citizens: Array[Dictionary]
) -> void:
	var family_ids: Dictionary = {}
	var head_counts: Dictionary = {}

	for family in families:
		family_ids[family["family_id"]] = true
		head_counts[family["family_id"]] = 0

	for i in range(headed_citizens.size()):
		var original: Dictionary = original_citizens[i]
		var aged: Dictionary = age_assigned[i]
		var headed: Dictionary = headed_citizens[i]
		var family_id: int = headed["family_id"]

		_check(
			family_ids.has(family_id),
			"Citizen references an existing family."
		)
		if not family_ids.has(family_id):
			continue

		_check(
			original["citizen_id"] == headed["citizen_id"],
			"Citizen ID is preserved."
		)
		_check(
			original["family_id"] == headed["family_id"],
			"Family ID is preserved."
		)
		_check(
			original["sex"] == headed["sex"],
			"Sex is preserved."
		)
		_check(
			aged["age_group"] == headed["age_group"],
			"Age group is preserved by head assignment."
		)

		if headed["family_position"] == "HEAD_OF_FAMILY":
			head_counts[family_id] += 1
			_check(
				headed["age_group"] != "Child",
				"Child is never selected as family head."
			)
		else:
			_check(
				headed["family_position"] == "HOUSEHOLD_MEMBER",
				"Non-head remains a household member."
			)
		var expected_record: Dictionary = aged.duplicate(true)
		var actual_record: Dictionary = headed.duplicate(true)

		expected_record.erase("family_position")
		actual_record.erase("family_position")

		_check(
			expected_record == actual_record,
			"Head assignment changes no citizen fields except family_position."
		)

	for family_id in head_counts:
		_check(
			head_counts[family_id] == 1,
			"Family %s has exactly one head." % str(family_id)
		)


func _check(condition: bool, description: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAILED: " + description)
