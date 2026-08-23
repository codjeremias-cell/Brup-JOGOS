# Núcleo puro — elegibilidade de dicas por etapa/rank e variação anti-decoreba.
extends RefCounted

const CLUES_PER_LEVEL := 3


# Etapas 1-2 -> low; 3-4 -> mid; 5 -> high.
static func stage_clue_level(stage_in_case: int) -> String:
	if stage_in_case <= 2:
		return "low"
	if stage_in_case <= 4:
		return "mid"
	return "high"


# Janela de difficulty_tier sorteável por rank.
static func eligible_tiers(rank: int) -> Array:
	if rank <= 2:
		return [1, 2]
	elif rank <= 4:
		return [1, 2, 3]
	elif rank <= 6:
		return [2, 3]
	elif rank <= 8:
		return [3, 4]
	return [4, 5]


# Sorteia `count` dicas do nível pedido, excluindo as já vistas.
# Se o nível estiver esgotado, completa com qualquer dica não vista (fallback documentado).
static func pick_clues(city: Dictionary, level: String, count: int, exclude_ids: Array, rng: RandomNumberGenerator) -> Array:
	var clues: Array = city.get("clues", [])
	var preferred: Array = []
	var fallback: Array = []
	for c in clues:
		if not (c is Dictionary):
			continue
		var cid := String(c.get("clue_id", ""))
		if cid == "" or exclude_ids.has(cid):
			continue
		if String(c.get("tier", "")) == level:
			preferred.append(c)
		else:
			fallback.append(c)
	_shuffle(preferred, rng)
	var out := preferred.slice(0, mini(count, preferred.size()))
	for c in fallback:
		if out.size() >= count:
			break
		out.append(c)
	return out


# Variação anti-decoreba: mesma cidade/tier, outro conjunto — nova semente.
static func variation_seed(base_seed: int, round_index: int) -> int:
	return base_seed * 100003 + round_index * 7919


static func _shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
