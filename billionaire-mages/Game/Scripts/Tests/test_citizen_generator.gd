
extends SceneTree


const CitizenGenerator = preload(
	"res://Game/Scripts/Population/Citizen_Generator.gd"
)


const EXPECTED_CLASSES: Array[String] = [
	"Aristocrat",
	"Gentile",
	"Commoner",
	"Vagrant"
]

const EXPECTED_ORIGINS: Array[String] = [
	"Local",
	"Foreign"
]

const EXPECTED_SEXES: Array[String] = [
	"male",
	"female"
]


var tests_passed: int = 0
var tests_failed: int = 0


func _initialize() -> void:

	var generator = CitizenGenerator.new()

	var first_names: Dictionary = _build_first_names()

	var families: Array[Dictionary] = [
		{
			"family_id": 10,
			"origin": "Local",
			"social_class": "Aristocrat",
			"surname": "Vanderbilt",
			"member_count": 3
		},
		{
			"family_id": 11,
			"origin": "Foreign",
			"social_class": "Gentile",
			"surname": "Beaumont",
			"member_count": 2
		},
		{
			"family_id": 12,
			"origin": "Foreign",
			"social_class": "Aristocrat",
			"surname": "Rothschild",
			"member_count": 1
		}
	]
	var empty_families: Array[Dictionary] = []

	var empty_result: Array[Dictionary] = generator.generate_citizens(
		empty_families,
		first_names,
		0
	)

	_check(
		empty_result.is_empty(),
		"Empty family input returns an empty citizen array"
	)
	var citizens: Array[Dictionary] = generator.generate_citizens(
		families,
		first_names,
		100
	)

	_check(
		citizens.size() == 6,
		"Generates the correct number of citizens"
	)

	if citizens.size() == 6:
		_test_citizen_records(citizens, families, first_names)

	print("\nCitizen Generator Tests Complete")
	print("Passed: ", tests_passed)
	print("Failed: ", tests_failed)
	
	quit()


func _build_first_names() -> Dictionary:

	var result: Dictionary = {}

	for sex in EXPECTED_SEXES:
		result[sex] = {}

		for origin in EXPECTED_ORIGINS:
			result[sex][origin] = {}

			for social_class in EXPECTED_CLASSES:

				var names: Array[String] = []

				for i in range(20):
					names.append(
						"%s_%s_%s_%02d" % [
							sex,
							origin,
							social_class,
							i
						]
					)

				result[sex][origin][social_class] = names

	return result


func _test_citizen_records(
	citizens: Array[Dictionary],
	families: Array[Dictionary],
	first_names: Dictionary
) -> void:

	var family_lookup: Dictionary = {}

	for family in families:
		family_lookup[family["family_id"]] = family

	var used_names_by_family: Dictionary = {}

	for i in range(citizens.size()):

		var citizen: Dictionary = citizens[i]

		_check(
			citizen.get("citizen_id") == 100 + i,
			"Citizen ID is sequential"
		)

		var family_id: int = citizen["family_id"]

		_check(
			family_lookup.has(family_id),
			"Citizen references an existing family"
		)

		if not family_lookup.has(family_id):
			continue

		var family: Dictionary = family_lookup[family_id]

		_check(
			citizen["surname"] == family["surname"],
			"Citizen inherits the family surname"
		)

		_check(
			citizen["origin"] == family["origin"],
			"Citizen inherits the family origin"
		)

		_check(
			citizen["social_class"] == family["social_class"],
			"Citizen inherits the family social class"
		)

		var sex: String = citizen["sex"]

		_check(
			EXPECTED_SEXES.has(sex),
			"Citizen has a valid sex"
		)

		if not EXPECTED_SEXES.has(sex):
			continue

		var name: String = citizen["first_name"]

		var available_names: Array = (
			first_names[sex]
			[family["origin"]]
			[family["social_class"]]
		)

		_check(
			available_names.has(name),
			"First name comes from the correct name pool"
		)

		if not used_names_by_family.has(family_id):
			used_names_by_family[family_id] = {}

		var family_names: Dictionary = used_names_by_family[family_id]

		var normalized_name: String = name.to_lower()

		_check(
			not family_names.has(normalized_name),
			"First names are unique within each family"
		)

		family_names[normalized_name] = true


func _check(condition: bool, description: String) -> void:

	if condition:
		tests_passed += 1
	else:
		tests_failed += 1
		push_error("FAILED: " + description)
