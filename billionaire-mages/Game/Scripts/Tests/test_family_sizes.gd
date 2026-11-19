
extends SceneTree

const PopulationDemography = preload(
    "res://Game/Scripts/Population/Population_Demography.gd"
)

func _initialize() -> void:

	var demography = PopulationDemography.new()
	var profiles: Dictionary = PopulationDemography.FAMILY_SIZE_PROFILES

	var tests_passed: int = 0
	var tests_failed: int = 0

	# Test every possible member count up to 1500.
	for social_class in profiles:

		var profile: Dictionary = profiles[social_class]
		var minimum_size: int = profile["min_size"]
		var allowed_sizes: Dictionary = profile["weights"]

		for member_count in range(minimum_size, 1501):

			# Repeat each test to exercise random outcomes.
			for trial in range(5):

				var sizes: Array[int] = demography.generate_family_sizes(
					social_class,
					member_count
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
						social_class,
						" | Members: ",
						member_count,
						" | Result: ",
						sizes
					)
					tests_failed += 1
				else:
					tests_passed += 1

	print("--------------------------------")
	print("Family Size Tests Complete")
	print("Passed: ", tests_passed)
	print("Failed: ", tests_failed)
	print("--------------------------------")

	quit(0 if tests_failed == 0 else 1)
