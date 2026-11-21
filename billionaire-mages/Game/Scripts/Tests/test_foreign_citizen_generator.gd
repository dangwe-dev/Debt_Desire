
extends SceneTree


const ForeignGenerator = preload(
	"res://Game/Scripts/Population/Foreign_Citizen_Generator.gd"
)


func _initialize() -> void:

	var tests_passed: int = 0
	var tests_failed: int = 0

	var generator = ForeignGenerator.new()

	var first_names: Dictionary = {
		"male": {
			"Aristocrat": ["Arthur", "Edmund", "Victor"],
			"Gentile": ["Henry", "Edward", "Charles"],
			"Commoner": ["Thomas", "James", "William"],
			"Vagrant": ["John", "Robert", "George"]
		},
		"female": {
			"Aristocrat": ["Victoria", "Eleanor", "Catherine"],
			"Gentile": ["Elizabeth", "Margaret", "Charlotte"],
			"Commoner": ["Mary", "Alice", "Anne"],
			"Vagrant": ["Jane", "Sarah", "Emily"]
		}
	}

	var available_surnames: Dictionary = {
		"Aristocrat": ["Ashford", "Blackwood", "Cavendish"],
		"Gentile": ["Bennett", "Crawford", "Ellington"],
		"Commoner": ["Miller", "Baker", "Fletcher", "Cooper"],
		"Vagrant": ["Turner", "Parker", "Collins", "Morgan"]
	}

	var used_surnames: Dictionary = {
		"oldfamily": true
	}

	var first_name_usage: Dictionary = {}

	var foreign_counts: Dictionary = {
		"Aristocrat": 2,
		"Gentile": 3,
		"Commoner": 4,
		"Vagrant": 3
	}

	var expected_total: int = 12

	# --------------------------------------------------
	# TEST 1: Generate the requested number of citizens.
	# --------------------------------------------------

	var citizens: Array[Dictionary] = generator.generate_foreign_citizens(
		foreign_counts,
		first_names,
		available_surnames,
		used_surnames,
		first_name_usage,
		100
	)

	if citizens.size() == expected_total:
		tests_passed += 1
	else:
		tests_failed += 1
		push_error(
			"TEST 1 FAILED: Expected "
			+ str(expected_total)
			+ " citizens, received "
			+ str(citizens.size())
		)

	# --------------------------------------------------
	# TEST 2: Verify citizen IDs.
	# --------------------------------------------------

	var ids_valid: bool = true

	for i in range(citizens.size()):
		if citizens[i]["citizen_id"] != 100 + i:
			ids_valid = false
			break

	if ids_valid:
		tests_passed += 1
	else:
		tests_failed += 1
		push_error("TEST 2 FAILED: Citizen IDs are incorrect.")

	# --------------------------------------------------
	# TEST 3: Verify social-class distribution.
	# --------------------------------------------------

	var class_counts: Dictionary = {}

	for citizen in citizens:
		var social_class: String = citizen["social_class"]
		class_counts[social_class] = (
			int(class_counts.get(social_class, 0)) + 1
		)

	var class_counts_valid: bool = true

	for social_class in foreign_counts:
		if (
			int(class_counts.get(social_class, 0))
			!= foreign_counts[social_class]
		):
			class_counts_valid = false
			break

	if class_counts_valid:
		tests_passed += 1
	else:
		tests_failed += 1
		push_error("TEST 3 FAILED: Social-class counts are incorrect.")

	# --------------------------------------------------
	# TEST 4: Verify sex assignment.
	# --------------------------------------------------

	var sex_counts: Dictionary = {
		"male": 0,
		"female": 0
	}

	for citizen in citizens:
		sex_counts[citizen["sex"]] += 1

	var sex_counts_valid: bool = true

	for citizen in citizens:
		if not sex_counts.has(citizen["sex"]):
			sex_counts_valid = false

	if sex_counts_valid:
		tests_passed += 1
	else:
		tests_failed += 1
		push_error("TEST 4 FAILED: Invalid sex assignment.")

	# --------------------------------------------------
	# TEST 5: Verify surname uniqueness.
	# --------------------------------------------------

	var generated_surnames: Dictionary = {}
	var surnames_unique: bool = true

	for citizen in citizens:
		var surname: String = citizen["surname"]
		var normalized: String = surname.strip_edges().to_lower()

		if generated_surnames.has(normalized):
			surnames_unique = false
			break

		generated_surnames[normalized] = true

	if surnames_unique:
		tests_passed += 1
	else:
		tests_failed += 1
		push_error("TEST 5 FAILED: Duplicate surnames were generated.")

	# --------------------------------------------------
	# TEST 6: Verify previously used surnames are excluded.
	# --------------------------------------------------

	var old_surname_reused: bool = false

	for citizen in citizens:
		if citizen["surname"].to_lower() == "oldfamily":
			old_surname_reused = true
			break

	if not old_surname_reused:
		tests_passed += 1
	else:
		tests_failed += 1
		push_error("TEST 6 FAILED: A previously used surname was reused.")

	# --------------------------------------------------
	# TEST 7: Verify global surname registration.
	# --------------------------------------------------

	var registration_valid: bool = true

	for citizen in citizens:
		var key: String = citizen["surname"].strip_edges().to_lower()

		if not used_surnames.has(key):
			registration_valid = false
			break

	if registration_valid:
		tests_passed += 1
	else:
		tests_failed += 1
		push_error("TEST 7 FAILED: A surname was not registered.")

	# --------------------------------------------------
	# TEST 8: Verify surname removal from all pools.
	# --------------------------------------------------

	var surname_removal_valid: bool = true

	for surname in generated_surnames.keys():
		for social_class in available_surnames:
			for remaining_surname in available_surnames[social_class]:
				if remaining_surname.strip_edges().to_lower() == surname:
					surname_removal_valid = false
					break

	if surname_removal_valid:
		tests_passed += 1
	else:
		tests_failed += 1
		push_error("TEST 8 FAILED: A used surname remains in a surname pool.")

	# --------------------------------------------------
	# TEST 9: Verify first-name usage tracking.
	# --------------------------------------------------

	var usage_valid: bool = true

	for citizen in citizens:
		var sex: String = citizen["sex"]
		var key: String = citizen["first_name"].strip_edges().to_lower()

		if not first_name_usage.has(sex):
			usage_valid = false
			break

		if int(first_name_usage[sex].get(key, 0)) < 1:
			usage_valid = false
			break

	if usage_valid:
		tests_passed += 1
	else:
		tests_failed += 1
		push_error("TEST 9 FAILED: First-name usage was not registered.")

	# --------------------------------------------------
	# TEST 10: Verify foreign identification.
	# --------------------------------------------------

	var foreign_valid: bool = true

	for citizen in citizens:
		if citizen["is_foreign"] != true:
			foreign_valid = false
			break

	if foreign_valid:
		tests_passed += 1
	else:
		tests_failed += 1
		push_error("TEST 10 FAILED: Incorrect foreign identification.")

	# --------------------------------------------------
	# TEST 11: Reject negative citizen counts.
	# --------------------------------------------------

	var invalid_counts: Dictionary = {
		"Aristocrat": -1,
		"Gentile": 0,
		"Commoner": 0,
		"Vagrant": 0
	}

	var invalid_result: Array[Dictionary] = generator.generate_foreign_citizens(
		invalid_counts,
		first_names,
		available_surnames,
		used_surnames,
		first_name_usage
	)

	if invalid_result.is_empty():
		tests_passed += 1
	else:
		tests_failed += 1
		push_error("TEST 11 FAILED: Negative counts were accepted.")

	# --------------------------------------------------
	# TEST 12: Reject insufficient surname availability.
	# --------------------------------------------------

	var insufficient_surnames: Dictionary = {
		"Aristocrat": ["OnlyName"],
		"Gentile": ["OnlyGentile"],
		"Commoner": ["OnlyCommoner"],
		"Vagrant": ["OnlyVagrant"]
	}

	var insufficient_counts: Dictionary = {
		"Aristocrat": 2,
		"Gentile": 0,
		"Commoner": 0,
		"Vagrant": 0
	}

	var insufficient_result: Array[Dictionary] = generator.generate_foreign_citizens(
		insufficient_counts,
		first_names,
		insufficient_surnames,
		{},
		{}
	)

	if insufficient_result.is_empty():
		tests_passed += 1
	else:
		tests_failed += 1
		push_error("TEST 12 FAILED: Insufficient surnames were accepted.")

	# --------------------------------------------------
	# TEST 13: Reject missing first-name data.
	# --------------------------------------------------

	var invalid_first_names: Dictionary = first_names.duplicate(true)
	invalid_first_names["female"]["Commoner"] = []

	var invalid_name_result: Array[Dictionary] = generator.generate_foreign_citizens(
		{"Commoner": 1},
		invalid_first_names,
		available_surnames,
		used_surnames,
		first_name_usage
	)

	if invalid_name_result.is_empty():
		tests_passed += 1
	else:
		tests_failed += 1
		push_error("TEST 13 FAILED: Empty first-name pool was accepted.")

	# --------------------------------------------------
	# RESULTS
	# --------------------------------------------------

	print("--------------------------------")
	print("Foreign Citizen Generator Tests")
	print("Passed: ", tests_passed)
	print("Failed: ", tests_failed)
	print("--------------------------------")

	quit()
