# Testes do nucleo puro. Roda headless:
#   godot --headless --path . --script res://tools/run_tests.gd
# Exit code 0 = tudo verde; 1 = falhas (usado pelo CI).
extends SceneTree

const Scoring = preload("res://core/scoring.gd")
const Progression = preload("res://core/progression.gd")
const Eligibility = preload("res://core/clue_eligibility.gd")
const PanelLib = preload("res://core/candidate_panel.gd")
const DiscardLib = preload("res://core/discard_report.gd")
const TurnEngine = preload("res://core/turn_engine.gd")

var failures: Array = []
var checks := 0


func _init() -> void:
	_test_scoring()
	_test_progression()
	_test_eligibility()
	_test_panel()
	_test_discard()
	_test_engine()
	print("")
	if failures.is_empty():
		print("TESTES: TODOS PASSARAM (%d checks)" % checks)
		quit(0)
	else:
		print("TESTES: %d FALHAS em %d checks:" % [failures.size(), checks])
		for f in failures:
			print(" - " + f)
		quit(1)


func ok(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failures.append(msg)


func eq(a, b, msg: String) -> void:
	ok(a == b, "%s (esperado=%s obtido=%s)" % [msg, str(b), str(a)])


func eqf(a: float, b: float, msg: String) -> void:
	ok(absf(a - b) < 0.0001, "%s (esperado=%f obtido=%f)" % [msg, b, a])


# ---------------- fixtures ----------------
func _city(id: String, cont: String, tier: int, lat: float, fam: String, cur: String, clim: String) -> Dictionary:
	return {
		"city_id": id, "continent": cont, "difficulty_tier": tier,
		"coords": {"lat": lat}, "language_family": fam,
		"currency_iso": cur, "climate_tag": clim,
	}


func _fixture_pool() -> Array:
	return [
		_city("bra-x", "south_america", 2, -10.0, "romance", "BRL", "tropical"),
		_city("bra-y", "south_america", 2, -12.0, "romance", "BRL", "tropical"),
		_city("mex-z", "north_america", 2, 19.0, "romance", "MXN", "desertico"),
		_city("esp-m", "europe", 1, 40.0, "romance", "EUR", "mediterraneo"),
		_city("jpn-t", "asia", 3, 35.0, "japonica", "JPY", "temperado"),
		_city("bra-w", "south_america", 4, -15.0, "romance", "BRL", "equatorial"),
	]


func _fixture_clues() -> Array:
	return [
		{"clue_id": "L1", "tier": "low", "category": "geografia", "text": "a", "analysis": {"pt-BR": "an1"}},
		{"clue_id": "L2", "tier": "low", "category": "historia", "text": "b"},
		{"clue_id": "M1", "tier": "mid", "category": "gastronomia", "text": "c"},
	]


# ---------------- suites ----------------
func _test_scoring() -> void:
	eq(Scoring.tier_base(1), 40, "base t1")
	eq(Scoring.tier_base(3), 90, "base t3")
	eq(Scoring.tier_base(5), 180, "base t5")
	eqf(Scoring.rank_multiplier(1), 1.0, "mult r1")
	eqf(Scoring.rank_multiplier(9), 1.72, "mult r9 linear")
	eqf(Scoring.rank_multiplier(10), 3.0, "r10 substitui por 3.0")
	eq(Scoring.compute_xp(60, 1.0, 0, 0, 0), 60, "xp sem bonus")
	eq(Scoring.compute_xp(60, 1.0, 1, 0, 0), 69, "bonus 1 PA livre +15%")
	eq(Scoring.compute_xp(100, 1.0, 0, 9, 0), 150, "streak capped em 5 (+50%)")
	eq(Scoring.compute_xp(60, 1.0, 0, 0, 50), 90, "clausula +50% xp")


func _test_progression() -> void:
	eq(Progression.rank_for_xp(0), 1, "rank inicial")
	eq(Progression.rank_for_xp(499), 1, "antes do r2")
	eq(Progression.rank_for_xp(500), 2, "limiar exato r2")
	eq(Progression.rank_for_xp(1299), 2, "um abaixo do r3")
	eq(Progression.rank_for_xp(1300), 3, "limiar exato r3")
	eq(Progression.rank_for_xp(56400), 10, "lendario")
	eq(Progression.rank_for_xp(999999), 10, "alem do topo")
	ok(Progression.needs_spec_choice(3), "rank 3 pede spec")
	ok(not Progression.needs_spec_choice(4), "rank 4 nao pede")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var offer: Array = Progression.offer_specs([], rng)
	eq(offer.size(), 3, "oferta tem 3 opcoes")
	var uniq := {}
	for o in offer:
		uniq[o] = true
	eq(uniq.size(), offer.size(), "sem duplicatas na oferta")


func _test_eligibility() -> void:
	eq(Eligibility.stage_clue_level(1), "low", "etapa 1 low")
	eq(Eligibility.stage_clue_level(2), "low", "etapa 2 low")
	eq(Eligibility.stage_clue_level(3), "mid", "etapa 3 mid")
	eq(Eligibility.stage_clue_level(5), "high", "etapa 5 high")
	eq(Eligibility.eligible_tiers(1), [1, 2], "janela r1")
	eq(Eligibility.eligible_tiers(4), [1, 2, 3], "janela r4")
	eq(Eligibility.eligible_tiers(6), [2, 3], "janela r6")
	eq(Eligibility.eligible_tiers(8), [3, 4], "janela r8")
	eq(Eligibility.eligible_tiers(10), [4, 5], "janela r10")
	var city := {"clues": _fixture_clues()}
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var picked := Eligibility.pick_clues(city, "low", 1, ["L1"], rng)
	eq(picked.size(), 1, "pick respeita count")
	eq(picked[0]["clue_id"], "L2", "exclui id visto")
	picked = Eligibility.pick_clues(city, "low", 5, [], rng)
	ok(picked.size() >= 3, "fallback completa com outras tiers")
	var s1 := Eligibility.variation_seed(123456, 1)
	var s2 := Eligibility.variation_seed(123456, 2)
	ok(s1 != s2, "semente de variacao muda por rodada")


func _test_panel() -> void:
	var pool := _fixture_pool()
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var p1: Array = PanelLib.build_panel("bra-x", ["esp-m"], pool, 5, rng)
	rng.seed = 42
	var p2: Array = PanelLib.build_panel("bra-x", ["esp-m"], pool, 5, rng)
	eq(p1, p2, "painel deterministico por seed")
	ok(p1.has("bra-x"), "correta sempre presente")
	eq(p1.size(), 5, "tamanho do painel")
	var uniq := {}
	for pid in p1:
		uniq[pid] = true
	eq(uniq.size(), p1.size(), "sem duplicatas")
	ok(p1.has("esp-m"), "curado prioritario entra")
	ok(p1.has("bra-y") and p1.has("bra-w"), "fill prefere mesmo continente")


func _test_discard() -> void:
	var by_id := {}
	for c in _fixture_pool():
		by_id[c["city_id"]] = c
	var target: Dictionary = by_id["bra-x"]
	var chosen: Dictionary = by_id["mex-z"]
	var panel := ["bra-y", "mex-z", "esp-m", "jpn-t", "bra-w"]
	var d := DiscardLib.build_discard(chosen, target, panel, by_id)
	ok(d["ok"], "discard ok")
	ok(d["statements"].size() >= 1 and d["statements"].size() <= 2, "1 ou 2 afirmacoes")
	ok(not d["eliminated"].has("bra-x"), "jamais elimina a correta")
	ok(d["eliminated"].size() >= 2, "elimina ao menos 2 quando ha divergencia")
	var same := DiscardLib.build_discard(by_id["bra-y"], target, panel, by_id)
	eq(same["statements"].size(), 0, "cidades gemeas nao geram afirmacao falsa")
	eq(same["eliminated"].size(), 0, "gemeas nao eliminam ninguem")


func _test_engine() -> void:
	var st := TurnEngine.new_stage_state(1, 100, 999)
	eq(st["pa"], 3, "3 PA no rank 1")
	var ctx := {"clues": _fixture_clues(), "target_id": "bra-x"}

	var before := str(st)
	var r := TurnEngine.apply_action(st, "analyze", ctx)
	ok(r["ok"], "analyze ok com analise disponivel")
	eq(r["picked"]["clue_id"], "L1", "analisa pista com analysis")
	eq(r["state"]["pa"], 2, "analyze custa 1 PA")
	eq(str(st), before, "estado de entrada imutavel")

	var poor := TurnEngine.new_stage_state(1, 5, 1)
	eq(TurnEngine.apply_action(poor, "informant", ctx)["reason"], "NO_VERBA", "informante sem verba")
	eq(TurnEngine.apply_action(st, "archive", ctx)["reason"], "LOCKED_RANK", "arquivo antes do rank 6")
	eq(TurnEngine.apply_action(st, "radar", ctx)["reason"], "LOCKED_RANK", "radar antes do rank 9")
	var nop := st.duplicate(true)
	nop["pa"] = 0
	eq(TurnEngine.apply_action(nop, "analyze", ctx)["reason"], "NO_PA", "sem PA")

	r = TurnEngine.apply_action(st, "informant", ctx)
	ok(r["ok"], "informante ok")
	eq(r["picked"]["clue_id"], "M1", "informante prefere mid")
	eq(r["state"]["verba"], 85, "informante custa 15")

	var cities := _fixture_pool_dict()
	var target := cities["bra-x"]
	var ok_state := TurnEngine.new_stage_state(1, 100, 555)
	var rt := TurnEngine.resolve_travel(ok_state, "bra-x", target, cities)
	ok(rt["correct"], "viagem correta")
	ok(rt["xp"] > 0, "xp positivo no acerto")
	eq(rt["verba_gain"], 30, "bounty cheio na 1a tentativa")
	eq(rt["rep_delta"], 10, "reputacao na 1a tentativa")
	eq(rt["state"]["streak"], 1, "carimbo de moral")

	var bad := TurnEngine.resolve_travel(ok_state, "mex-z", target, cities)
	ok(not bad["correct"], "viagem errada detectada")
	ok(bad["discard"] != null and bad["discard"]["ok"], "descarte gerado na falha")
	eq(bad["state"]["streak"], 0, "streak zera na falha")
	eq(bad["rep_delta"], -15, "-15 reputacao na falha")
	ok(not bad["frozen"], "ainda ha tentativas")
	var last := TurnEngine.new_stage_state(1, 100, 556)
	last["attempts_left"] = 1
	var frz := TurnEngine.resolve_travel(last, "mex-z", target, cities)
	ok(frz["frozen"], "congela na 3a falha")


func _fixture_pool_dict() -> Dictionary:
	var d := {}
	for c in _fixture_pool():
		d[c["city_id"]] = c
	return d
