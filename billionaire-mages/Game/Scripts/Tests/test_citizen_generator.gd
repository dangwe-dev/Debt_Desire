
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
		# Test missing family data
	var invalid_families: Array[Dictionary] = [
		{
			"family_id": 20,
			"origin": "Local",
			"social_class": "Aristocrat",
			"member_count": 3
		}
	]

	var invalid_result: Array[Dictionary] = generator.generate_citizens(
		invalid_families,
		first_names,
		0
	)

	_check(
		invalid_result.is_empty(),
		"Missing family surname returns an empty citizen array"
	)
		# Test invalid family origin
	var invalid_origin_families: Array[Dictionary] = [
		{
			"family_id": 21,
			"origin": "Martian",
			"social_class": "Aristocrat",
			"surname": "Example",
			"member_count": 2
		}
	]

	var invalid_origin_result: Array[Dictionary] = (
		generator.generate_citizens(
			invalid_origin_families,
			first_names,
			0
		)
	)

	_check(
		invalid_origin_result.is_empty(),
		"Invalid family origin returns an empty citizen array"
	)
		# Test invalid social class
	var invalid_class_families: Array[Dictionary] = [
		{
			"family_id": 22,
			"origin": "Local",
			"social_class": "Royalty",
			"surname": "Example",
			"member_count": 2
		}
	]

	var invalid_class_result: Array[Dictionary] = (
		generator.generate_citizens(
			invalid_class_families,
			first_names,
			0
		)
	)

	_check(
		invalid_class_result.is_empty(),
		"Invalid social class returns an empty citizen array"
	)
		# Test zero family members
	var zero_member_families: Array[Dictionary] = [
		{
			"family_id": 23,
			"origin": "Local",
			"social_class": "Commoner",
			"surname": "Example",
			"member_count": 0
		}
	]

	var zero_member_result: Array[Dictionary] = (
		generator.generate_citizens(
			zero_member_families,
			first_names,
			0
		)
	)

	_check(
		zero_member_result.is_empty(),
		"Zero-member family returns an empty citizen array"
	)
		# Test negative family member count
	var negative_member_families: Array[Dictionary] = [
		{
			"family_id": 24,
			"origin": "Local",
			"social_class": "Commoner",
			"surname": "Example",
			"member_count": -2
		}
	]

	var negative_member_result: Array[Dictionary] = (
		generator.generate_citizens(
			negative_member_families,
			first_names,
			0
		)
	)

	_check(
		negative_member_result.is_empty(),
		"Negative member count returns an empty citizen array"
	)
		# Test duplicate family IDs
	var duplicate_id_families: Array[Dictionary] = [
		{
			"family_id": 25,
			"origin": "Local",
			"social_class": "Commoner",
			"surname": "Smith",
			"member_count": 2
		},
		{
			"family_id": 25,
			"origin": "Foreign",
			"social_class": "Gentile",
			"surname": "Beaumont",
			"member_count": 3
		}
	]

	var duplicate_id_result: Array[Dictionary] = (
		generator.generate_citizens(
			duplicate_id_families,
			first_names,
			0
		)
	)

	_check(
		duplicate_id_result.is_empty(),
		"Duplicate family IDs return an empty citizen array"
	)
		# Test negative starting citizen ID
	var negative_id_result: Array[Dictionary] = (
		generator.generate_citizens(
			families,
			first_names,
			-1
		)
	)

	_check(
		negative_id_result.is_empty(),
		"Negative starting citizen ID returns an empty citizen array"
	)
		# Test empty surname
	var empty_surname_families: Array[Dictionary] = families.duplicate(true)
	empty_surname_families[0]["surname"] = ""

	var empty_surname_result: Array[Dictionary] = (
		generator.generate_citizens(
			empty_surname_families,
			first_names
		)
	)

	_check(
		empty_surname_result.is_empty(),
		"Empty family surname returns an empty citizen array"
	)
		# Test empty first-name pool
	var empty_first_name_data: Dictionary = first_names.duplicate(true)
	empty_first_name_data["male"]["Local"]["Aristocrat"] = []

	var empty_first_name_result: Array[Dictionary] = (
		generator.generate_citizens(
			families,
			empty_first_name_data
		)
	)

	_check(
		empty_first_name_result.is_empty(),
		"Empty first-name pool returns an empty citizen array"
	)
		# Test whitespace-only first name
	var whitespace_first_name_data: Dictionary = first_names.duplicate(true)
	whitespace_first_name_data["male"]["Local"]["Aristocrat"][0] = "   "

	var whitespace_first_name_result: Array[Dictionary] = (
		generator.generate_citizens(
			families,
			whitespace_first_name_data
		)
	)

	_check(
		whitespace_first_name_result.is_empty(),
		"Whitespace-only first name returns an empty citizen array"
	)
		# Test exhausted first-name pools
	var exhausted_first_name_data: Dictionary = first_names.duplicate(true)

	exhausted_first_name_data["male"]["Local"]["Aristocrat"] = ["Alex"]
	exhausted_first_name_data["female"]["Local"]["Aristocrat"] = ["Alex"]

	var exhausted_families: Array[Dictionary] = [
		{
			"family_id": 30,
			"origin": "Local",
			"social_class": "Aristocrat",
			"surname": "Test",
			"member_count": 2
		}
	]

	var exhausted_result: Array[Dictionary] = (
		generator.generate_citizens(
			exhausted_families,
			exhausted_first_name_data
		)
	)

	_check(
		exhausted_result.is_empty(),
		"Exhausted first-name pools return an empty citizen array"
	)
		# Test first-name reuse across different families
	var repeated_name_data: Dictionary = first_names.duplicate(true)

	repeated_name_data["male"]["Local"]["Aristocrat"] = ["Alex"]
	repeated_name_data["female"]["Local"]["Aristocrat"] = ["Alex"]

	var repeated_name_families: Array[Dictionary] = [
		{
			"family_id": 40,
			"origin": "Local",
			"social_class": "Aristocrat",
			"surname": "Vanderbilt",
			"member_count": 1
		},
		{
			"family_id": 41,
			"origin": "Local",
			"social_class": "Aristocrat",
			"surname": "Rockefeller",
			"member_count": 1
		}
	]

	var repeated_name_result: Array[Dictionary] = (
		generator.generate_citizens(
			repeated_name_families,
			repeated_name_data
		)
	)

	var names_match: bool = (
		repeated_name_result.size() == 2
		and repeated_name_result[0]["first_name"] == "Alex"
		and repeated_name_result[1]["first_name"] == "Alex"
	)

	_check(
		names_match,
		"First names can repeat across different families"
	)
		# Test sequential citizen IDs from a nonzero starting ID
	var sequential_id_result: Array[Dictionary] = (
		generator.generate_citizens(
			families,
			first_names,
			500
		)
	)

	var sequential_ids_valid: bool = (
		sequential_id_result.size() == 6
	)

	for i in range(sequential_id_result.size()):
		if sequential_id_result[i]["citizen_id"] != 500 + i:
			sequential_ids_valid = false
			break

	_check(
		sequential_ids_valid,
		"Citizen IDs are sequential from a nonzero starting ID"
	)
		# Test Foreign citizens receive Foreign first names
	var foreign_families: Array[Dictionary] = [
		{
			"family_id": 50,
			"origin": "Foreign",
			"social_class": "Aristocrat",
			"surname": "Rothschild",
			"member_count": 1
		}
	]

	var foreign_result: Array[Dictionary] = (
		generator.generate_citizens(
			foreign_families,
			first_names
		)
	)

	var foreign_name_valid: bool = false

	if foreign_result.size() == 1:
		var generated_name: String = foreign_result[0]["first_name"]
		var male_foreign_names: Array = (
			first_names["male"]["Foreign"]["Aristocrat"]
		)
		var female_foreign_names: Array = (
			first_names["female"]["Foreign"]["Aristocrat"]
		)

		foreign_name_valid = (
			male_foreign_names.has(generated_name)
			or female_foreign_names.has(generated_name)
		)

	_check(
		foreign_name_valid,
		"Foreign citizens receive first names from Foreign pools"
	)
		# Test Local citizens receive Local first names
	var local_families: Array[Dictionary] = [
		{
			"family_id": 51,
			"origin": "Local",
			"social_class": "Aristocrat",
			"surname": "Vanderbilt",
			"member_count": 1
		}
	]

	var local_result: Array[Dictionary] = (
		generator.generate_citizens(
			local_families,
			first_names
		)
	)

	var local_name_valid: bool = false

	if local_result.size() == 1:
		var generated_name: String = local_result[0]["first_name"]
		var male_local_names: Array = (
			first_names["male"]["Local"]["Aristocrat"]
		)
		var female_local_names: Array = (
			first_names["female"]["Local"]["Aristocrat"]
		)

		local_name_valid = (
			male_local_names.has(generated_name)
			or female_local_names.has(generated_name)
		)

	_check(
		local_name_valid,
		"Local citizens receive first names from Local pools"
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
