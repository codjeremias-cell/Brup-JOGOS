# Núcleo puro — progressão de ranks e especializações.
extends RefCounted

const RANK_XP := {2: 500, 3: 1300, 4: 2580, 5: 4630, 6: 7910, 7: 13150, 8: 21540, 9: 34960, 10: 56400}
const SPEC_RANKS := [3, 5, 7, 9]
const RESPEC_COST := 2
const MAX_ATTEMPTS := 3

const SPEC_POOL := ["geografo", "gastronoma", "historiador", "linguista", "cartografa", "cosmopolita"]


static func rank_for_xp(xp: int) -> int:
	var rank := 1
	for threshold in RANK_XP.keys():
		if xp >= int(RANK_XP[threshold]) and int(threshold) > rank:
			rank = int(threshold)
	return rank


static func needs_spec_choice(rank: int) -> bool:
	return SPEC_RANKS.has(rank)


# Oferece sempre 3 especializações ainda não possuídas (determinística dado o rng).
static func offer_specs(owned: Array, rng: RandomNumberGenerator) -> Array:
	var candidates: Array = []
	for s in SPEC_POOL:
		if not owned.has(s):
			candidates.append(s)
	_shuffle(candidates, rng)
	return candidates.slice(0, mini(3, candidates.size()))


static func _shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
