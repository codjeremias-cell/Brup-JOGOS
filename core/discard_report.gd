# Núcleo puro — Relatório de Descarte.
# Gera apenas afirmações verdadeiras comparando atributos da cidade escolhida
# contra o alvo; elimina do painel as candidatas que violam o atributo do alvo.
# JAMAIS elimina a cidade-alvo.
extends RefCounted

const ATTRS := ["continent", "hemisphere", "language_family", "currency_iso", "climate_tag"]


static func hemisphere(city: Dictionary) -> String:
	var lat := float(city.get("coords", {}).get("lat", 0.0))
	return "sul" if lat < 0.0 else "norte"


# statements: lista de {attr, value} (chave i18n composta na camada de UI).
# eliminated: city_ids removidos do painel.
static func build_discard(chosen: Dictionary, target: Dictionary, panel_ids: Array, cities_by_id: Dictionary) -> Dictionary:
	var scored: Array = []
	for attr in ATTRS:
		var tval = _attr(target, attr)
		var elim: Array = []
		for pid in panel_ids:
			var ps := String(pid)
			if ps == String(target.get("city_id", "")):
				continue
			if not cities_by_id.has(ps):
				continue
			if _attr(cities_by_id[ps], attr) != tval:
				elim.append(ps)
		if elim.size() > 0:
			scored.append({"attr": attr, "value": tval, "elim": elim})

	scored.sort_custom(func(a, b): return a["elim"].size() > b["elim"].size())

	var statements: Array = []
	var eliminated: Array = []
	var seen := {}
	for s in scored:
		if statements.size() >= 2:
			break
		statements.append({"attr": s["attr"], "value": s["value"]})
		for pid in s["elim"]:
			if not seen.has(pid):
				seen[pid] = true
				eliminated.append(pid)

	return {"ok": true, "statements": statements, "eliminated": eliminated}


static func _attr(city: Dictionary, attr: String):
	match attr:
		"hemisphere":
			return hemisphere(city)
		_:
			return city.get(attr, "")
