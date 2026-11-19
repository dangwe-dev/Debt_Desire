
extends SceneTree

const PopulationData = preload(
    "res://Game/Scripts/Data/Population_Data.gd"
)


const FamilyGenerator = preload(
    "res://Game/Scripts/Population/Family_Generator.gd"
)


func _initialize() -> void:

	var tests_passed: int = 0
	var tests_failed: int = 0

	
	var family_generator = FamilyGenerator.new()
	var data_loader = PopulationData.new()

	var available_surnames: Dictionary = (
		data_loader.load_surnames()
	)

	# Stop if the source data cannot be loaded.
	if available_surnames.is_empty():
		print("FAILED: Unable to load surname data.")
		quit(1)
		return

	print("--------------------------------")
	print("Surname Data Tests")
	print("--------------------------------")

	# Test that all expected classes exist.
	for social_class in PopulationData.EXPECTED_CLASSES:

		if (
			available_surnames.has(social_class)
			and typeof(available_surnames[social_class]) == TYPE_ARRAY
		):
			tests_passed += 1
		else:
			print("FAILED: Missing class pool: ", social_class)
			tests_failed += 1

	# Test that all pools contain surnames.
	var total_surnames: int = 0

	for social_class in PopulationData.EXPECTED_CLASSES:

		var pool: Array = available_surnames[social_class]

		total_surnames += pool.size()

		if pool.is_empty():
			print("FAILED: Empty surname pool: ", social_class)
			tests_failed += 1
		else:
			tests_passed += 1

	# Test direct integration with family generation.
	var used_surnames: Dictionary = {}
	var all_families: Array[Dictionary] = []

	var next_family_id: int = 0

	for social_class in PopulationData.EXPECTED_CLASSES:

		var requested_sizes: Array[int] = [4]

		var generated: Array[Dictionary] = (
			family_generator.generate_families(
				social_class,
				requested_sizes,
				available_surnames,
				used_surnames,
				next_family_id
			)
		)

		if generated.size() == 1:
			tests_passed += 1
		else:
			print(
				"FAILED: Family generation for ",
				social_class
			)
			tests_failed += 1

		all_families.append_array(generated)
		next_family_id += generated.size()

	# Test that generated surnames are globally unique.
	var generated_surnames: Dictionary = {}

	for family in all_families:

		var surname: String = family["surname"]

		if generated_surnames.has(surname):
			print("FAILED: Repeated generated surname: ", surname)
			tests_failed += 1
		else:
			generated_surnames[surname] = true
			tests_passed += 1

	# Test that the shared registry contains every generated surname.
	if used_surnames.size() == all_families.size():
		tests_passed += 1
	else:
		print("FAILED: Used surname registry mismatch.")
		tests_failed += 1

	print("--------------------------------")
	print("Loaded surnames: ", total_surnames)
	print("Generated families: ", all_families.size())
	print("Passed: ", tests_passed)
	print("Failed: ", tests_failed)
	print("--------------------------------")

	quit(0 if tests_failed == 0 else 1)
