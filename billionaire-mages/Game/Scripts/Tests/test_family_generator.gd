
extends SceneTree


const FamilyGenerator = preload(
	"res://Game/Scripts/Population/Family_Generator.gd"
)


var tests_passed: int = 0
var tests_failed: int = 0


func _initialize() -> void:

	var generator = FamilyGenerator.new()

	# Separate surname registries for each origin.
	var local_surnames: Dictionary = {
		"Aristocrat": ["Shared"],
		"Gentile": ["Shared", "LocalGentile"],
		"Commoner": ["LocalCommoner"],
		"Vagrant": ["LocalVagrant"]
	}

	var foreign_surnames: Dictionary = {
	"Aristocrat": ["Shared"],
	"Gentile": ["ForeignGentile"],
	"Commoner": ["ForeignCommoner"],
	"Vagrant": ["ForeignVagrant"]
}

	var local_used: Dictionary = {}
	var foreign_used: Dictionary = {}

	# --------------------------------------------------
	# TEST 1: Generate a Local Aristocrat family.
	# --------------------------------------------------

	var local_aristocrats: Array[Dictionary] = (
		generator.generate_families(
			"Local",
			"Aristocrat",
			[6],
			local_surnames,
			local_used,
			0
		)
	)

	_check(
		local_aristocrats.size() == 1,
		"Local Aristocrat family generated."
	)

	if local_aristocrats.size() == 1:

		var family: Dictionary = local_aristocrats[0]

		_check(
			family["family_id"] == 0,
			"First family receives ID 0."
		)

		_check(
			family["origin"] == "Local",
			"Local family has correct origin."
		)

		_check(
			family["social_class"] == "Aristocrat",
			"Local family has correct social class."
		)

		_check(
			family["surname"] == "Shared",
			"Local family receives its available surname."
		)

		_check(
			family["member_count"] == 6,
			"Local family has correct member count."
		)

		_check(
			local_used.has("Shared"),
			"Local surname is registered as used."
		)

		_check(
			not local_surnames["Gentile"].has("Shared"),
			"Local surname is removed from other class pools."
		)

	# --------------------------------------------------
	# TEST 2: Generate a Foreign Aristocrat family.
	# The same surname must be allowed in another origin.
	# --------------------------------------------------

	var foreign_aristocrats: Array[Dictionary] = (
		generator.generate_families(
			"Foreign",
			"Aristocrat",
			[1],
			foreign_surnames,
			foreign_used,
			1
		)
	)

	_check(
		foreign_aristocrats.size() == 1,
		"One-member Foreign Aristocrat family generated."
	)

	if foreign_aristocrats.size() == 1:

		var family: Dictionary = foreign_aristocrats[0]

		_check(
			family["family_id"] == 1,
			"Foreign family receives the next global ID."
		)

		_check(
			family["origin"] == "Foreign",
			"Foreign family has correct origin."
		)

		_check(
			family["member_count"] == 1,
			"Foreign family can contain one member."
		)

		_check(
			family["surname"] == "Shared",
			"Foreign family can reuse a Local surname."
		)

		_check(
			foreign_used.has("Shared"),
			"Foreign surname is registered independently."
		)

		_check(
			local_used.has("Shared"),
			"Local surname registration remains intact."
		)

	# --------------------------------------------------
	# TEST 3: Generate another Local family.
	# It must not reuse the Local Aristocrat surname.
	# --------------------------------------------------

	var local_gentiles: Array[Dictionary] = (
		generator.generate_families(
			"Local",
			"Gentile",
			[4],
			local_surnames,
			local_used,
			2
		)
	)

	_check(
		local_gentiles.size() == 1,
		"Local Gentile family generated."
	)

	if local_gentiles.size() == 1:

		var family: Dictionary = local_gentiles[0]

		_check(
			family["family_id"] == 2,
			"Next Local family receives global ID 2."
		)

		_check(
			family["surname"] == "LocalGentile",
			"Local Gentile receives an unused Local surname."
		)

		_check(
			not family["surname"] == "Shared",
			"Local surname cannot be reused across classes."
		)

	# --------------------------------------------------
	# TEST 4: Invalid family size must not modify data.
	# --------------------------------------------------

	var before_invalid: Dictionary = local_surnames.duplicate(true)
	var used_before_invalid: Dictionary = local_used.duplicate(true)

	var invalid_result: Array[Dictionary] = (
		generator.generate_families(
			"Local",
			"Aristocrat",
			[999],
			local_surnames,
			local_used,
			3
		)
	)

	_check(
		invalid_result.is_empty(),
		"Invalid family size is rejected."
	)

	_check(
		local_surnames == before_invalid
		and local_used == used_before_invalid,
		"Invalid family size does not modify surname registries."
	)

	# --------------------------------------------------
	# TEST 5: Insufficient surnames must not modify data.
	# --------------------------------------------------

	var limited_surnames: Dictionary = {
		"Aristocrat": ["OnlySurname"],
		"Gentile": ["OnlySurname"],
		"Commoner": [],
		"Vagrant": []
	}

	var limited_used: Dictionary = {}

	var before_insufficient: Dictionary = (
		limited_surnames.duplicate(true)
	)

	var insufficient_result: Array[Dictionary] = (
		generator.generate_families(
			"Local",
			"Aristocrat",
			[4, 5],
			limited_surnames,
			limited_used,
			3
		)
	)

	_check(
		insufficient_result.is_empty(),
		"Insufficient surname pool is rejected."
	)

	_check(
		limited_surnames == before_insufficient
		and limited_used.is_empty(),
		"Insufficient surnames do not partially modify registries."
	)

	# --------------------------------------------------
	# TEST 6: Invalid origin must be rejected.
	# --------------------------------------------------

	var invalid_origin_result: Array[Dictionary] = (
		generator.generate_families(
			"Unknown",
			"Aristocrat",
			[6],
			local_surnames,
			local_used,
			3
		)
	)

	_check(
		invalid_origin_result.is_empty(),
		"Unknown origin is rejected."
	)

	# --------------------------------------------------
	# TEST 7: Invalid social class must be rejected.
	# --------------------------------------------------

	var invalid_class_result: Array[Dictionary] = (
		generator.generate_families(
			"Local",
			"Unknown",
			[6],
			local_surnames,
			local_used,
			3
		)
	)

	_check(
		invalid_class_result.is_empty(),
		"Unknown social class is rejected."
	)

	# --------------------------------------------------
	# RESULTS
	# --------------------------------------------------

	print("--------------------------------")
	print("Family Generator Tests Complete")
	print("Passed: ", tests_passed)
	print("Failed: ", tests_failed)
	print("--------------------------------")

	quit(0 if tests_failed == 0 else 1)


func _check(condition: bool, description: String) -> void:

	if condition:
		print("PASSED: ", description)
		tests_passed += 1
	else:
		print("FAILED: ", description)
		tests_failed += 1
