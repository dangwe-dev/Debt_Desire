
extends SceneTree


const PopulationData = preload(
    "res://Game/Scripts/Data/Population_Data.gd"
)


const EXPECTED_SEXES: Array[String] = [
	"male",
    "female"
]


const EXPECTED_CLASSES: Array[String] = [
	"Aristocrat",
	"Gentile",
	"Commoner",
    "Vagrant"
]


func _initialize() -> void:

	var passed: int = 0
	var failed: int = 0

	var data_loader = PopulationData.new()

	var first_names: Dictionary = (
		data_loader.load_first_names()
	)

	if first_names.is_empty():
		print("FAILED: First names could not be loaded.")
		quit(1)
		return

	for sex in EXPECTED_SEXES:

		if not first_names.has(sex):
			print("FAILED: Missing sex: " + sex)
			failed += 1
			continue

		for social_class in EXPECTED_CLASSES:

			if not first_names[sex].has(social_class):
				print(
                    "FAILED: Missing pool: "
					+ sex + " / " + social_class
				)
				failed += 1
				continue

			var name_pool: Array = (
				first_names[sex][social_class]
			)

			if name_pool.is_empty():
				print(
                    "FAILED: Empty pool: "
					+ sex + " / " + social_class
				)
				failed += 1
				continue

			print(
                "PASSED: "
				+ sex + " / " + social_class
				+ " - "
				+ str(name_pool.size())
				+ " names"
			)

			passed += 1

	print("--------------------------------")
	print("First Name Data Tests Complete")
	print("Passed: " + str(passed))
	print("Failed: " + str(failed))
	print("--------------------------------")

	quit(0 if failed == 0 else 1)
