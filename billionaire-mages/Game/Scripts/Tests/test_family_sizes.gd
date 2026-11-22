
extends SceneTree


const PopulationDemography = preload(
	"res://Game/Scripts/Population/Population_Demography.gd"
)


func _initialize() -> void:

	var demography = PopulationDemography.new()

	var tests_passed: int = 0
	var tests_failed: int = 0

	print("--------------------------------")
	print("Population Demography Tests")
	print("--------------------------------")


	# TEST 1: Class distribution totals exactly 1000.

	var class_distribution: Dictionary = (
		demography.generate_class_distribution(1000)
	)

	var expected_classes: Dictionary = {
		"Aristocrat": 135,
		"Gentile": 140,
		"Commoner": 504,
		"Vagrant": 221
	}

	var class_total: int = 0
	var classes_correct: bool = true

	for social_class in expected_classes:
		class_total += class_distribution.get(social_class, 0)

		if class_distribution.get(social_class, -1) != expected_classes[social_class]:
			classes_correct = false

	if class_total == 1000 and classes_correct:
		print("PASSED: Class distribution.")
		tests_passed += 1
	else:
		print("FAILED: Class distribution: ", class_distribution)
		tests_failed += 1


	# TEST 2: Origin distribution matches baseline demographics.

	var origin_distribution: Dictionary = (
		demography.generate_origin_distribution(class_distribution)
	)

	var expected_origins: Dictionary = {
		"Aristocrat": {"Local": 125, "Foreign": 10},
		"Gentile": {"Local": 125, "Foreign": 15},
		"Commoner": {"Local": 444, "Foreign": 60},
		"Vagrant": {"Local": 180, "Foreign": 41}
	}

	var origins_correct: bool = true

	for social_class in expected_origins:

		var actual: Dictionary = origin_distribution[social_class]
		var expected: Dictionary = expected_origins[social_class]

		if (
			actual["Local"] != expected["Local"]
			or actual["Foreign"] != expected["Foreign"]
			or actual["Local"] + actual["Foreign"] != class_distribution[social_class]
		):
			origins_correct = false
			print(
				"FAILED: Origin distribution for ",
				social_class,
				": ",
				actual
			)

	if origins_correct:
		print("PASSED: Local and Foreign distribution.")
		tests_passed += 1
	else:
		tests_failed += 1


	# TEST 3: Family sizes for every origin/class combination.

	var profiles: Dictionary = (
		PopulationDemography.FAMILY_SIZE_PROFILES
	)

	for origin in profiles:

		for social_class in profiles[origin]:

			var profile: Dictionary = profiles[origin][social_class]
			var minimum_size: int = profile["min_size"]
			var allowed_sizes: Dictionary = profile["weights"]

			for member_count in range(minimum_size, 1501):

				# Repeat each allocation to exercise weighted randomness.
				for trial in range(2):

					var sizes: Array[int] = (
						demography.generate_family_sizes(
							origin,
							social_class,
							member_count
						)
					)

					var generated_total: int = 0
					var valid_sizes: bool = true

					for size in sizes:

						generated_total += size

						if not allowed_sizes.has(size):
							valid_sizes = false

					if (
						sizes.is_empty()
						or generated_total != member_count
						or not valid_sizes
					):
						print(
							"FAILED: ",
							origin,
							" ",
							social_class,
							" | Members: ",
							member_count,
							" | Result: ",
							sizes
						)
						tests_failed += 1
					else:
						tests_passed += 1


	# TEST 4: One-member Foreign Aristocrat family.

	var singleton_family: Array[int] = (
		demography.generate_family_sizes(
			"Foreign",
			"Aristocrat",
			1
		)
	)

	if singleton_family == [1]:
		print("PASSED: One-member Foreign Aristocrat family.")
		tests_passed += 1
	else:
		print(
			"FAILED: One-member Foreign Aristocrat family: ",
			singleton_family
		)
		tests_failed += 1


	# TEST 5: One-member Foreign Gentile family.

	singleton_family = demography.generate_family_sizes(
		"Foreign",
		"Gentile",
		1
	)

	if singleton_family == [1]:
		print("PASSED: One-member Foreign Gentile family.")
		tests_passed += 1
	else:
		print(
			"FAILED: One-member Foreign Gentile family: ",
			singleton_family
		)
		tests_failed += 1


	print("--------------------------------")
	print("Population Demography Tests Complete")
	print("Passed: ", tests_passed)
	print("Failed: ", tests_failed)
	print("--------------------------------")

	quit(0 if tests_failed == 0 else 1)
