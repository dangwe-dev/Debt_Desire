
extends SceneTree


const PopulationData = preload(
	"res://Game/Scripts/Data/Population_Data.gd"
)


func _initialize() -> void:

	var data_loader = PopulationData.new()

	var tests_passed: int = 0
	var tests_failed: int = 0

	# --------------------------------------------------
	# TEST 1: Load surname datasets.
	# --------------------------------------------------

	var surnames: Dictionary = data_loader.load_surnames()

	if surnames.has("Local") and surnames.has("Foreign"):

		print("PASSED: Both surname origins loaded.")
		tests_passed += 1

	else:

		print("FAILED: Both surname origins loaded.")
		tests_failed += 1

	# --------------------------------------------------
	# TEST 2: Validate surname pools.
	# --------------------------------------------------

	var expected_classes: Array[String] = [
		"Aristocrat",
		"Gentile",
		"Commoner",
		"Vagrant"
	]

	for origin in ["Local", "Foreign"]:

		if not surnames.has(origin):
			continue

		var origin_data: Dictionary = surnames[origin]

		for social_class in expected_classes:

			var valid_pool: bool = (
				origin_data.has(social_class)
				and typeof(origin_data[social_class]) == TYPE_ARRAY
			)

			if valid_pool:

				print(
					"PASSED: ",
					origin,
					" ",
					social_class,
					" surname pool loaded."
				)
				tests_passed += 1

			else:

				print(
					"FAILED: ",
					origin,
					" ",
					social_class,
					" surname pool loaded."
				)
				tests_failed += 1

	# --------------------------------------------------
	# TEST 3: Same surname can exist in both origins.
	# --------------------------------------------------

	if (
		surnames.has("Local")
		and surnames.has("Foreign")
		and surnames["Local"].has("Gentile")
		and surnames["Foreign"].has("Aristocrat")
		and surnames["Local"]["Gentile"].has("Vanderbilt")
		and surnames["Foreign"]["Aristocrat"].has("Vanderbilt")
	):

		print("PASSED: Cross-origin surname overlap is allowed.")
		tests_passed += 1

	else:

		print("FAILED: Cross-origin surname overlap is allowed.")
		tests_failed += 1

	# --------------------------------------------------
	# TEST 4: Load first names.
	# --------------------------------------------------

	var first_names: Dictionary = data_loader.load_first_names()

	if first_names.has("male") and first_names.has("female"):

		print("PASSED: Both first-name datasets loaded.")
		tests_passed += 1

	else:

		print("FAILED: Both first-name datasets loaded.")
		tests_failed += 1

	# --------------------------------------------------
	# TEST 5: Validate first-name pools.
	# --------------------------------------------------

	for sex in ["male", "female"]:

		if not first_names.has(sex):
			continue

		for origin in ["Local", "Foreign"]:

			if not first_names[sex].has(origin):
				continue

			var origin_data: Dictionary = first_names[sex][origin]

			for social_class in expected_classes:

				var valid_pool: bool = (
					origin_data.has(social_class)
					and typeof(origin_data[social_class]) == TYPE_ARRAY
					and not origin_data[social_class].is_empty()
				)

				if valid_pool:

					print(
						"PASSED: ",
						sex,
						" ",
						origin,
						" ",
						social_class,
						" first-name pool loaded."
					)
					tests_passed += 1

				else:

					print(
						"FAILED: ",
						sex,
						" ",
						origin,
						" ",
						social_class,
						" first-name pool loaded."
					)
					tests_failed += 1

	# --------------------------------------------------
	# RESULTS
	# --------------------------------------------------

	print("--------------------------------")
	print("Population Data Tests Complete")
	print("Passed: ", tests_passed)
	print("Failed: ", tests_failed)
	print("--------------------------------")

	quit(0 if tests_failed == 0 else 1)
