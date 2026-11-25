extends SceneTree


const AgeGroupGenerator = preload(
	"res://Game/Scripts/Population/Age_Group_Generator.gd"
)

const SOCIAL_CLASSES: Array[String] = [
	"Aristocrat",
	"Gentile",
	"Commoner",
	"Vagrant"
]

const AGE_GROUPS: Array[String] = [
	"Elder",
	"Adult",
	"Teenager",
	"Child"
]

var tests_passed: int = 0
var tests_failed: int = 0


func _initialize() -> void:
	var generator = AgeGroupGenerator.new()

	var families: Array[Dictionary] = []
	var citizens: Array[Dictionary] = []

	var next_family_id: int = 100
	var next_citizen_id: int = 1000

	# Create one test family for each class at each size from 1 to 7.
	for social_class in SOCIAL_CLASSES:
		for member_count in range(1, 8):
			var family_id: int = next_family_id
			next_family_id += 1

			families.append({
				"family_id": family_id,
				"social_class": social_class,
				"member_count": member_count
			})

			for member_index in range(member_count):
				var sex: String = (
					"male" if member_index % 2 == 0 else "female"
				)

				citizens.append({
					"citizen_id": next_citizen_id,
					"family_id": family_id,
					"sex": sex
				})

				next_citizen_id += 1

	var result: Array[Dictionary] = generator.assign_age_groups(
		families,
		citizens
	)

	_check(
		result.size() == citizens.size(),
		"Returns one age-assigned record for every citizen"
	)

	if result.size() == citizens.size():
		_check_age_rules(result, families)

	_test_invalid_inputs(generator)

	print("\nAge Group Generator Tests Complete")
	print("Passed: ", tests_passed)
	print("Failed: ", tests_failed)

	quit(0 if tests_failed == 0 else 1)


func _check_age_rules(
	citizens: Array[Dictionary],
	families: Array[Dictionary]
) -> void:
	var members_by_family: Dictionary = {}

	for citizen in citizens:
		var family_id: int = citizen["family_id"]

		if not members_by_family.has(family_id):
			members_by_family[family_id] = []

		members_by_family[family_id].append(citizen)

	for family in families:
		var family_id: int = family["family_id"]
		var social_class: String = family["social_class"]
		var member_count: int = family["member_count"]
		var members: Array = members_by_family[family_id]

		var age_counts: Dictionary = {}
		var male_adults: int = 0
		var female_adults: int = 0
		var non_adults: int = 0

		for citizen in members:
			var age_group: String = citizen["age_group"]

			_check(
				AGE_GROUPS.has(age_group),
				"Family %d: citizen has a valid age group" % family_id
			)

			age_counts[age_group] = age_counts.get(age_group, 0) + 1

			if age_group != "Adult":
				non_adults += 1

			if age_group == "Adult" and citizen["sex"] == "male":
				male_adults += 1

			if age_group == "Adult" and citizen["sex"] == "female":
				female_adults += 1

		if member_count == 1:
			_check(
				age_counts.get("Adult", 0) == 1,
				"%s size 1: member is Adult" % social_class
			)

		if social_class in ["Aristocrat", "Gentile"]:
			if member_count == 2:
				_check(
					age_counts.get("Elder", 0) >= 1,
					"%s size 2: includes an Elder" % social_class
				)

			if member_count >= 3:
				_check(
					age_counts.get("Elder", 0) >= 1,
					"%s size 3+: includes an Elder" % social_class
				)
				_check(
					age_counts.get("Adult", 0) >= 1,
					"%s size 3+: includes an Adult" % social_class
				)

		if social_class == "Commoner" and member_count >= 3:
			_check(
				male_adults >= 1,
				"Commoner size 3+: includes a male Adult"
			)
			_check(
				female_adults >= 1,
				"Commoner size 3+: includes a female Adult"
			)

		if member_count >= 4:
			_check(
				non_adults >= 1,
				"%s size 4+: includes at least one non-Adult" % social_class
			)

		if member_count > 5:
			_check(
				non_adults >= 2,
				"%s size 6+: includes at least two non-Adults" % social_class
			)

		if member_count > 6:
			for age_group in AGE_GROUPS:
				_check(
					age_counts.get(age_group, 0) >= 1,
					"%s size 7+: includes %s" % [
						social_class,
						age_group
					]
				)


func _test_invalid_inputs(generator) -> void:
	var empty_families: Array[Dictionary] = []
	var one_citizen: Array[Dictionary] = [
		{
			"citizen_id": 1,
			"family_id": 1,
			"sex": "male"
		}
	]

	var empty_result: Array[Dictionary] = generator.assign_age_groups(
		empty_families,
		one_citizen
	)

	_check(
		empty_result.is_empty(),
		"Rejects empty family input"
	)

	var mismatched_families: Array[Dictionary] = [
		{
			"family_id": 2,
			"social_class": "Commoner",
			"member_count": 2
		}
	]

	var mismatched_citizens: Array[Dictionary] = [
		{
			"citizen_id": 2,
			"family_id": 2,
			"sex": "male"
		}
	]

	var mismatched_result: Array[Dictionary] = (
		generator.assign_age_groups(
			mismatched_families,
			mismatched_citizens
		)
	)

	_check(
		mismatched_result.is_empty(),
		"Rejects family member-count mismatch"
	)


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASSED: ", description)
		tests_passed += 1
	else:
		push_error("FAILED: " + description)
		tests_failed += 1
