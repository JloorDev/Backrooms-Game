class_name PrefabRegistry

#  Estructura:
#  - "name": nombre de la carpeta
#  - "chance": % de aparición entre tipos (suma no necesita ser 100)
#  - "variations": lista de variaciones con su peso relativo entre sí
#    Cada variación puede ser:
#      - String simple "a" → peso igual a las demás
#      - Dictionary {"v": "b", "weight": 0.3} → aparece menos (opcional)
#
#  Ejemplo:
#    variation "a" sin peso  → peso 1.0 (normal)
#    variation "b" weight 0.3 → aparece ~3x menos que "a"

const ROOMS = [
	{
		"name": "normal",
		"chance": 100.0, 
		"variations": [
			"a",
			"b",
			"c",
		]
	},
]

const CORRIDORS = [
	{
		"name": "straight",
		"chance": 60.0,
		"variations": [
			"a",
			"b",
		]
	},
]

static func pick_room(rng: RandomNumberGenerator) -> String:
	var type = _pick_by_chance(ROOMS, rng)
	var variation = _pick_variation(type["variations"], rng)
	return "res://prefabs/rooms/%s/variation_%s.tscn" % [type["name"], variation]

static func pick_corridor(rng: RandomNumberGenerator) -> String:
	var type = _pick_by_chance(CORRIDORS, rng)
	var variation = _pick_variation(type["variations"], rng)
	return "res://prefabs/corridors/%s/variation_%s.tscn" % [type["name"], variation]

static func _pick_by_chance(items: Array, rng: RandomNumberGenerator) -> Dictionary:
	var total = 0.0
	for item in items:
		total += float(item["chance"])
	var roll = rng.randf() * total
	var acc  = 0.0
	for item in items:
		acc += float(item["chance"])
		if roll <= acc:
			return item
	return items[-1]

static func _pick_variation(variations: Array, rng: RandomNumberGenerator) -> String:
	var total = 0.0
	for v in variations:
		total += _get_weight(v)

	var roll = rng.randf() * total
	var acc  = 0.0
	for v in variations:
		acc += _get_weight(v)
		if roll <= acc:
			return _get_name(v)

	return _get_name(variations[-1])

static func _get_weight(v) -> float:
	if v is Dictionary:
		return float(v.get("weight", 1.0))
	return 1.0

static func _get_name(v) -> String:
	if v is Dictionary:
		return v["v"]
	return v
