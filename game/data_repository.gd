# Carrega os JSONs das cidades direto de res://data.
# Decisão F1: protótipo lê JSON puro (zero dependências); a troca por SQLite
# acontece atrás desta mesma interface na F3 do Plano.
extends RefCounted


static func load_cities(dir_path: String = "res://data/cities") -> Dictionary:
	var out := {}
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_error("Pasta de cidades nao encontrada: " + dir_path)
		return out
	for f in dir.get_files():
		if not String(f).ends_with(".json"):
			continue
		var txt := FileAccess.get_file_as_string(dir_path + "/" + String(f))
		var data = JSON.parse_string(txt)
		if data is Dictionary and data.has("city_id"):
			out[String(data["city_id"])] = data
	return out


static func load_pool(path: String = "res://data/pool/distractor_pool.json") -> Array:
	var txt := FileAccess.get_file_as_string(path)
	if txt == "":
		return []
	var data = JSON.parse_string(txt)
	if data is Dictionary and data.has("cities"):
		return data["cities"]
	return []
