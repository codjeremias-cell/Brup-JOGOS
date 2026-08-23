# Núcleo puro — montagem do painel de candidatas.
# Curados (campo distractors) entram primeiro; o restante vem do pool por
# afinidade (mesmo continente, tier próximo), embaralhado por semente.
extends RefCounted


static func build_panel(target_id: String, curated: Array, pool_cities: Array, size: int, rng: RandomNumberGenerator) -> Array:
	var ids: Array = [target_id]
	var chosen := {target_id: true}

	for d in curated:
		if ids.size() >= size:
			break
		var did := String(d)
		if did != target_id and not chosen.has(did):
			ids.append(did)
			chosen[did] = true

	var target: Dictionary = {}
	for p in pool_cities:
		if String(p.get("city_id", "")) == target_id:
			target = p
			break

	# Embaralha antes de ordenar estável: empates ficam aleatórios por semente.
	var fill: Array = []
	for p in pool_cities:
		var pid := String(p.get("city_id", ""))
		if pid == "" or chosen.has(pid):
			continue
		fill.append(p)
	_shuffle(fill, rng)
	fill.sort_custom(func(a, b): return _affinity(a, target) < _affinity(b, target))

	for p in fill:
		if ids.size() >= size:
			break
		ids.append(String(p["city_id"]))
	return ids


# Menor = mais parecido com o alvo. Continente igual vale muito; tier próximo desempata.
static func _affinity(city: Dictionary, target: Dictionary) -> float:
	var score := 1.0
	if not target.is_empty() and String(city.get("continent", "")) == String(target.get("continent", "")):
		score = 0.0
	var dt := 2.0
	if not target.is_empty():
		dt = absf(float(city.get("difficulty_tier", 0)) - float(target.get("difficulty_tier", 0)))
	return score + dt * 0.1


static func _shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
