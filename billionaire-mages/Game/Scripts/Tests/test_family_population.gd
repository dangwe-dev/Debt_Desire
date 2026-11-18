
extends SceneTree


const PopulationGenerator = preload(
	"res://Game/Scripts/Population/Population_Generator.gd"
)


func _initialize() -> void:

	var tests_passed: int = 0
	var tests_failed: int = 0

	var generator = PopulationGenerator.new()

	var result: Dictionary = (
		generator.generate_family_member_count()
	)

	if result.is_empty():
		print("FAILED: Family population generation.")
		quit(1)
		return

	print("--------------------------------")
	print("Family Population Integration Test")
	print("--------------------------------")

	# Test total population.
	if result["total_population"] == 1000:
		tests_passed += 1
	else:
		print("FAILED: Incorrect total population.")
		tests_failed += 1

	# Test family members + solitary citizens.
	if (
		result["total_family_members"]
		+ result["total_solitary_citizens"]
		== result["total_population"]
	):
		tests_passed += 1
	else:
		print("FAILED: Population accounting mismatch.")
		tests_failed += 1

	# Test that every family has a unique surname.
	var seen_surnames: Dictionary = {}

	for family in result["families"]:

		var surname: String = family["surname"]

		if seen_surnames.has(surname):
			print("FAILED: Duplicate surname: ", surname)
			tests_failed += 1
		else:
			seen_surnames[surname] = true
			tests_passed += 1

	# Test that family IDs are unique.
	var seen_ids: Dictionary = {}

	for family in result["families"]:

		var family_id: int = family["family_id"]

		if seen_ids.has(family_id):
			print("FAILED: Duplicate family ID: ", family_id)
			tests_failed += 1
		else:
			seen_ids[family_id] = true
			tests_passed += 1

	# Test that family sizes match the demographic allocation.
	for social_class in result["class_distribution"]:

		var expected_members: int = (
			result["family_demography"][social_class]["family_members"]
		)

		var actual_members: int = 0

		for family in result["families"]:
			if family["social_class"] == social_class:
				actual_members += family["member_count"]

		if actual_members == expected_members:
			tests_passed += 1
		else:
			print(
				"FAILED: Family member mismatch for ",
				social_class
			)
			tests_failed += 1

	# Test that the surname registry matches generated families.
	if result["used_surnames"].size() == result["total_families"]:
		tests_passed += 1
	else:
		print("FAILED: Surname registry mismatch.")
		tests_failed += 1

	print("--------------------------------")
	print("Population: ", result["total_population"])
	print("Family members: ", result["total_family_members"])
	print("Solitary citizens: ", result["total_solitary_citizens"])
	print("Families: ", result["total_families"])
	print("Unique surnames: ", seen_surnames.size())
	print("Passed: ", tests_passed)
	print("Failed: ", tests_failed)
	print("--------------------------------")

	quit(0 if tests_failed == 0 else 1)
