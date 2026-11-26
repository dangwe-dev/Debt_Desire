extends SceneTree


const FamilyHeadGenerator = preload(
	"res://Game/Scripts/Population/Family_Head_Generator.gd"
)


var tests_passed: int = 0
var tests_failed: int = 0


func _initialize() -> void:

	var generator = FamilyHeadGenerator.new()

	var families: Array[Dictionary] = [
		{"family_id": 10, "social_class": "Aristocrat"},
		{"family_id": 20, "social_class": "Gentile"},
		{"family_id": 30, "social_class": "Commoner"},
		{"family_id": 40, "social_class": "Vagrant"}
	]

	var citizens: Array[Dictionary] = [
		# Family 10: Elder males are eligible; lowest ID must win.
		{"citizen_id": 103, "family_id": 10, "sex": "male", "age_group": "Elder"},
		{"citizen_id": 101, "family_id": 10, "sex": "male", "age_group": "Elder"},
		{"citizen_id": 102, "family_id": 10, "sex": "female", "age_group": "Elder"},
		{"citizen_id": 104, "family_id": 10, "sex": "female", "age_group": "Child"},

		# Family 20: Only one eligible sex in the selected age group.
		{"citizen_id": 201, "family_id": 20, "sex": "female", "age_group": "Adult"},
		{"citizen_id": 202, "family_id": 20, "sex": "female", "age_group": "Adult"},
		{"citizen_id": 203, "family_id": 20, "sex": "male", "age_group": "Child"},

		# Family 30: Adult is the only eligible age group.
		{"citizen_id": 301, "family_id": 30, "sex": "male", "age_group": "Adult"},
		{"citizen_id": 302, "family_id": 30, "sex": "female", "age_group": "Child"},

		# Family 40: Teenager is the only eligible age group.
		{"citizen_id": 401, "family_id": 40, "sex": "female", "age_group": "Teenager"},
		{"citizen_id": 402, "family_id": 40, "sex": "male", "age_group": "Child"}
	]

	var original_citizens: Array[Dictionary] = citizens.duplicate(true)

	var result: Array[Dictionary] = generator.assign_family_heads(
		families,
		citizens
	)

	_check(
		result.size() == citizens.size(),
		"Output contains the same number of citizens."
	)

	if result.size() == citizens.size():
		_check_family_head_counts(families, result)
		_check_no_child_heads(result)
		_check_family_membership_unchanged(citizens, result)

		_check(
			_get_head_id(result, 10) == 101,
			"Lowest citizen_id wins when age and sex are tied."
		)

		_check(
			_get_head_id(result, 20) == 201,
			"Single-sex eligible group selects its lowest citizen_id."
		)

		_check(
			_get_head_id(result, 30) == 301,
			"Adult-only eligible family selects its adult."
		)

		_check(
			_get_head_id(result, 40) == 401,
			"Teenager-only eligible family can select a teenager."
		)

	_check(
		citizens == original_citizens,
		"Input citizens are not modified."
	)

	print("--------------------------------")
	print("Family Head Generator Tests")
	print("Passed: ", tests_passed)
	print("Failed: ", tests_failed)
	print("--------------------------------")

	quit(0 if tests_failed == 0 else 1)


func _check_family_head_counts(
	families: Array[Dictionary],
	result: Array[Dictionary]
) -> void:

	for family in families:
		var family_id: int = family["family_id"]
		var head_count: int = 0

		for citizen in result:
			if citizen["family_id"] == family_id:
				if citizen["family_position"] == "HEAD_OF_FAMILY":
					head_count += 1

		_check(
			head_count == 1,
			"Family %d has exactly one head." % family_id
		)


func _check_no_child_heads(result: Array[Dictionary]) -> void:

	for citizen in result:
		if citizen["family_position"] == "HEAD_OF_FAMILY":
			_check(
				citizen["age_group"] != "Child",
				"Selected head is not a child."
			)


func _check_family_membership_unchanged(
	original: Array[Dictionary],
	result: Array[Dictionary]
) -> void:

	for i in range(original.size()):
		_check(
			original[i]["citizen_id"] == result[i]["citizen_id"]
			and original[i]["family_id"] == result[i]["family_id"]
			and original[i]["age_group"] == result[i]["age_group"]
			and original[i]["sex"] == result[i]["sex"],
			"Citizen identity and demographics remain unchanged."
		)


func _get_head_id(
	result: Array[Dictionary],
	family_id: int
) -> int:

	for citizen in result:
		if (
			citizen["family_id"] == family_id
			and citizen["family_position"] == "HEAD_OF_FAMILY"
		):
			return citizen["citizen_id"]

	return -1


func _check(condition: bool, description: String) -> void:

	if condition:
		print("PASSED: ", description)
		tests_passed += 1
	else:
		print("FAILED: ", description)
		tests_failed += 1
