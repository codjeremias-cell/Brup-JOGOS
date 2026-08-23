# Núcleo puro — máquina de estados da etapa (investigação tática em turnos).
# Estados são imutáveis entre chamadas: toda ação devolve um novo Dictionary.
extends RefCounted

const ScoringLib = preload("res://core/scoring.gd")
const DiscardLib = preload("res://core/discard_report.gd")

const INFORMANT_COST := 15
const ARCHIVE_RANK := 6
const RADAR_RANK := 9
const REP_PER_FAIL := 15

const BOUNTY_VERBA := {1: 30, 2: 40, 3: 55, 4: 70, 5: 90}
const BOUNTY_REP := {1: 10, 2: 12, 3: 15, 4: 18, 5: 22}


# Estado inicial de uma etapa. PA = 3 (4 a partir do rank 5).
static func new_stage_state(rank: int, verba: int, stage_seed: int) -> Dictionary:
	return {
		"rank": rank,
		"pa": 4 if rank >= 5 else 3,
		"verba": verba,
		"attempts_left": 3,
		"streak": 0,
		"panel": [],
		"eliminated": [],
		"seen_clue_ids": [],
		"analyses_seen": [],
		"fuso_revealed": false,
		"seed_counter": 0,
		"stage_seed": stage_seed,
	}


static func _rng_of(state: Dictionary) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(state["stage_seed"]) * 7919 + int(state["seed_counter"])
	return rng


# Ações: "analyze", "informant", "archive", "radar".
# ctx: {clues: Array de dicas da cidade-alvo, target_id: String}
# Retorna {ok:true, state: novo_estado, picked?: Variant} ou {ok:false, reason:String}.
static func apply_action(state: Dictionary, action: String, ctx: Dictionary) -> Dictionary:
	if not ["analyze", "informant", "archive", "radar"].has(action):
		return {"ok": false, "reason": "UNKNOWN_ACTION"}

	var s: Dictionary = state.duplicate(true)
	var rng := _rng_of(s)
	s["seed_counter"] = int(s["seed_counter"]) + 1

	match action:
		"analyze":
			if int(s["pa"]) < 1:
				return {"ok": false, "reason": "NO_PA"}
			var clues: Array = ctx.get("clues", [])
			var candidates: Array = []
			for c in clues:
				if c is Dictionary and c.get("analysis", null) != null and not s["analyses_seen"].has(c["clue_id"]):
					candidates.append(c)
			if candidates.is_empty():
				return {"ok": false, "reason": "NO_ANALYSIS_LEFT"}
			var picked: Dictionary = candidates[rng.randi_range(0, candidates.size() - 1)]
			s["pa"] = int(s["pa"]) - 1
			s["analyses_seen"].append(picked["clue_id"])
			return {"ok": true, "state": s, "picked": picked}
		"informant":
			if int(s["pa"]) < 1:
				return {"ok": false, "reason": "NO_PA"}
			if int(s["verba"]) < INFORMANT_COST:
				return {"ok": false, "reason": "NO_VERBA"}
			var clues: Array = ctx.get("clues", [])
			var mid: Array = []
			var any_unseen: Array = []
			for c in clues:
				if c is Dictionary and not s["seen_clue_ids"].has(c["clue_id"]):
					any_unseen.append(c)
					if String(c.get("tier", "")) == "mid":
						mid.append(c)
			if any_unseen.is_empty():
				return {"ok": false, "reason": "NO_CLUES_LEFT"}
			var source: Array = mid if not mid.is_empty() else any_unseen
			var picked: Dictionary = source[rng.randi_range(0, source.size() - 1)]
			s["pa"] = int(s["pa"]) - 1
			s["verba"] = int(s["verba"]) - INFORMANT_COST
			s["seen_clue_ids"].append(picked["clue_id"])
			return {"ok": true, "state": s, "picked": picked}
		"archive":
			if int(s["rank"]) < ARCHIVE_RANK:
				return {"ok": false, "reason": "LOCKED_RANK"}
			if int(s["pa"]) < 2:
				return {"ok": false, "reason": "NO_PA"}
			var removable: Array = []
			for pid in s["panel"]:
				if pid != String(ctx.get("target_id", "")) and not s["eliminated"].has(pid):
					removable.append(pid)
			if removable.size() < 2:
				return {"ok": false, "reason": "NOTHING_TO_REMOVE"}
			for i in range(2):
				var idx := rng.randi_range(0, removable.size() - 1)
				s["eliminated"].append(removable[idx])
				removable.remove_at(idx)
			s["pa"] = int(s["pa"]) - 2
			return {"ok": true, "state": s}
		"radar":
			if int(s["rank"]) < RADAR_RANK:
				return {"ok": false, "reason": "LOCKED_RANK"}
			if int(s["pa"]) < 1:
				return {"ok": false, "reason": "NO_PA"}
			s["fuso_revealed"] = true
			s["pa"] = int(s["pa"]) - 1
			return {"ok": true, "state": s}

	return {"ok": false, "reason": "UNKNOWN_ACTION"}


# Resolve uma viagem. attempt = 1-based. Nunca muta o estado de entrada.
static func resolve_travel(state: Dictionary, chosen_id: String, target_city: Dictionary, cities_by_id: Dictionary) -> Dictionary:
	var s: Dictionary = state.duplicate(true)
	var target_id := String(target_city.get("city_id", ""))
	var correct := chosen_id == target_id
	var attempt := 4 - int(s["attempts_left"])  # 1ª, 2ª ou 3ª tentativa
	var tier := int(target_city.get("difficulty_tier", 1))

	var out := {"ok": true, "correct": correct, "xp": 0, "verba_gain": 0, "rep_delta": 0, "stamps": int(s["streak"]), "frozen": false, "discard": null}

	if correct:
		var base := ScoringLib.tier_base(tier)
		out["xp"] = ScoringLib.compute_xp(base, ScoringLib.rank_multiplier(int(s["rank"])), int(s["pa"]), int(s["streak"]), 0)
		out["verba_gain"] = _bounty(BOUNTY_VERBA, tier, attempt)
		out["rep_delta"] = _bounty(BOUNTY_REP, tier, attempt)
		s["streak"] = mini(int(s["streak"]) + 1, ScoringLib.STREAK_CAP)
	else:
		s["streak"] = 0
		out["rep_delta"] = -REP_PER_FAIL
		var remaining: Array = []
		for pid in s["panel"]:
			if pid != chosen_id and pid != target_id:
				remaining.append(pid)
		var chosen_city: Dictionary = cities_by_id.get(chosen_id, {})
		var discard: Dictionary = DiscardLib.build_discard(chosen_city, target_city, remaining, cities_by_id)
		out["discard"] = discard
		if discard.get("ok", false):
			for pid in discard["eliminated"]:
				if not s["eliminated"].has(pid):
					s["eliminated"].append(pid)

	s["attempts_left"] = int(s["attempts_left"]) - 1
	out["frozen"] = int(s["attempts_left"]) <= 0
	out["state"] = s
	return out


# Bounty integral na 1ª tentativa, metade na 2ª, zero na 3ª.
static func _bounty(table: Dictionary, tier: int, attempt: int) -> int:
	var full := int(table.get(tier, 0))
	if attempt == 1:
		return full
	elif attempt == 2:
		return int(full / 2.0)
	return 0
