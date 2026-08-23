# Tela única do protótipo (F1): um caso de 5 etapas com as cidades-piloto.
# UI de programador — o objetivo é validar o gate "você jogaria de novo agora?".
extends Control

const Repo = preload("res://game/data_repository.gd")
const Scoring = preload("res://core/scoring.gd")
const Progression = preload("res://core/progression.gd")
const Eligibility = preload("res://core/clue_eligibility.gd")
const PanelLib = preload("res://core/candidate_panel.gd")
const TurnEngine = preload("res://core/turn_engine.gd")

const CASE_CITIES := [
	"bra-rio-de-janeiro", "bra-sao-paulo", "bra-salvador",
	"bra-manaus", "bra-ouro-preto",
]
const START_VERBA := 120

var cities: Dictionary = {}
var pool: Array = []
var xp_total := 0
var verba: int = START_VERBA
var rep_total := 0
var postais: Array = []
var stage_index := 0
var target_id := ""
var state: Dictionary = {}
var current_clues: Array = []
var case_seed_base := 1
var round_index := 0

var stats_label: Label
var carta_label: Label
var log_label: Label
var panel_grid: GridContainer
var result_label: Label
var next_btn: Button
var restart_btn: Button


func _ready() -> void:
	cities = Repo.load_cities()
	pool = Repo.load_pool()
	case_seed_base = int(Time.get_unix_time_from_system())
	_build_ui()
	_start_case()


# ---------------------------------------------------------------- UI base
func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(margin)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 12)
	scroll.add_child(vbox)

	vbox.add_child(_label("NA TRILHA DA HERDEIRA — protótipo F1", 22))
	stats_label = _label("", 16)
	vbox.add_child(stats_label)
	carta_label = _label("", 17)
	carta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	carta_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_box(carta_label))

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	vbox.add_child(actions)
	actions.add_child(_action_btn("Analisar Pista (1 PA)", _on_analyze))
	actions.add_child(_action_btn("Informante (1 PA +15)", _on_informant))
	actions.add_child(_action_btn("Arquivo (rank 6)", _on_archive))
	actions.add_child(_action_btn("Radar (rank 9)", _on_radar))

	log_label = _label("", 14)
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_box(log_label))

	panel_grid = GridContainer.new()
	panel_grid.columns = 2
	panel_grid.add_theme_constant_override("h_separation", 8)
	panel_grid.add_theme_constant_override("v_separation", 8)
	vbox.add_child(panel_grid)

	result_label = _label("", 18)
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(result_label)

	next_btn = Button.new()
	next_btn.text = "Próxima etapa"
	next_btn.visible = false
	next_btn.pressed.connect(_next_stage)
	vbox.add_child(next_btn)

	restart_btn = Button.new()
	restart_btn.text = "Jogar caso de novo"
	restart_btn.visible = false
	restart_btn.pressed.connect(_start_case)
	vbox.add_child(restart_btn)


func _label(text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _box(inner: Control) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_child(inner)
	return p


func _action_btn(txt: String, fn: Callable) -> Button:
	var b := Button.new()
	b.text = txt
	b.pressed.connect(fn)
	return b


# ---------------------------------------------------------------- fluxo
func _start_case() -> void:
	xp_total = 0
	verba = START_VERBA
	rep_total = 0
	postais = []
	stage_index = 0
	next_btn.visible = false
	restart_btn.visible = false
	result_label.text = ""
	log_label.text = ""
	_start_stage()


func _start_stage() -> void:
	target_id = CASE_CITIES[stage_index]
	round_index = 0
	next_btn.visible = false
	result_label.text = "Etapa %d de %d" % [stage_index + 1, CASE_CITIES.size()]
	_deal_clues()


func _deal_clues() -> void:
	var city: Dictionary = cities[target_id]
	var seed_v: int = Eligibility.variation_seed(case_seed_base + hash(target_id), stage_index * 10 + round_index)
	var level := Eligibility.stage_clue_level(stage_index + 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	current_clues = Eligibility.pick_clues(city, level, 3, [], rng)
	state = TurnEngine.new_stage_state(Progression.rank_for_xp(xp_total), verba, seed_v)
	state["panel"] = _panel_for_rank(seed_v, rng)
	log_label.text = ""
	_render()


func _panel_for_rank(seed_v: int, rng: RandomNumberGenerator) -> Array:
	var size := 12 if Progression.rank_for_xp(xp_total) >= 4 else 8
	var combined: Array = pool.duplicate(true)
	for cid in cities.keys():
		if cid != target_id and not CASE_CITIES.has(cid):
			combined.append(cities[cid])
	return PanelLib.build_panel(target_id, cities[target_id].get("distractors", []), combined, size, rng)


func _render() -> void:
	stats_label.text = "Rank %d · XP %d · Verba %d · Rep %d · PA %d · Tentativas %d" % [
		Progression.rank_for_xp(xp_total), xp_total, verba, rep_total,
		int(state["pa"]), int(state["attempts_left"]),
	]
	var txt := "CARTA ANÔNIMA:\n"
	for i in range(current_clues.size()):
		txt += "%d) %s\n\n" % [i + 1, current_clues[i]["text"]["pt-BR"]]
	if bool(state["fuso_revealed"]):
		var t: Dictionary = cities[target_id]
		txt += "📡 Radar: fuso UTC%+.0f (%s)\n" % [float(t.get("utc_offset", 0.0)), t.get("timezone", "")]
	carta_label.text = txt
	_render_panel()


func _render_panel() -> void:
	for child in panel_grid.get_children():
		child.queue_free()
	for pid in state["panel"]:
		var b := Button.new()
		var eliminated: bool = state["eliminated"].has(pid)
		b.text = ("✖ " if eliminated else "") + display_name(String(pid))
		b.disabled = eliminated
		b.custom_minimum_size = Vector2(300, 48)
		b.pressed.connect(_travel.bind(String(pid)))
		panel_grid.add_child(b)


func display_name(id: String) -> String:
	if cities.has(id):
		return String(cities[id]["names"]["pt-BR"])
	return id


func _log(line: String) -> void:
	log_label.text += line + "\n"


# ---------------------------------------------------------------- ações
func _apply(action: String) -> Dictionary:
	return TurnEngine.apply_action(state, action, {"clues": current_clues, "target_id": target_id})


func _on_analyze() -> void:
	var r := _apply("analyze")
	if not r["ok"]:
		_log("⚠ " + str(r["reason"]))
	else:
		state = r["state"]
		var picked: Dictionary = r["picked"]
		_log("🔍 Análise: " + String(picked["analysis"]["pt-BR"]))
	_render()


func _on_informant() -> void:
	var r := _apply("informant")
	if not r["ok"]:
		_log("⚠ " + str(r["reason"]))
	else:
		state = r["state"]
		var picked: Dictionary = r["picked"]
		_log("🗣 Informante [%s]: %s" % [picked["category"], picked["text"]["pt-BR"]])
	_render()


func _on_archive() -> void:
	var r := _apply("archive")
	_log("⚠ " + str(r["reason"]) if not r["ok"] else "🗂 2 candidatas eliminadas.")
	if r["ok"]:
		state = r["state"]
		_render()


func _on_radar() -> void:
	var r := _apply("radar")
	_log("⚠ " + str(r["reason"]) if not r["ok"] else "")
	if r["ok"]:
		state = r["state"]
		_render()


# ---------------------------------------------------------------- viagem
func _travel(chosen_id: String) -> void:
	var r := TurnEngine.resolve_travel(state, chosen_id, cities[target_id], cities)
	state = r["state"]

	if r["correct"]:
		xp_total += int(r["xp"])
		verba += int(r["verba_gain"])
		rep_total += int(r["rep_delta"])
		postais.append(target_id)
		result_label.text = "✅ ACERTOU! %s · +%d XP · +%d Verba · +%d Rep" % [
			display_name(target_id), int(r["xp"]), int(r["verba_gain"]), int(r["rep_delta"]),
		]
		stage_index += 1
		if stage_index >= CASE_CITIES.size():
			_case_complete()
		else:
			next_btn.visible = true
		_render_stats_only()
		return

	rep_total += int(r["rep_delta"])
	var msg := "❌ Errou! −15 Rep."
	if r["discard"] != null and r["discard"]["ok"]:
		msg += "\n" + discard_text(r["discard"])
	_render_result_and_log(msg)
	if bool(r["frozen"]):
		round_index += 1
		_deal_clues()
		_append_frozen_note()
	else:
		_render()


func _render_stats_only() -> void:
	stats_label.text = "Rank %d · XP %d · Verba %d · Rep %d" % [
		Progression.rank_for_xp(xp_total), xp_total, verba, rep_total,
	]


func _render_result_and_log(msg: String) -> void:
	result_label.text = msg
	_log(msg)


func _append_frozen_note() -> void:
	_log("❄️ Etapa reiniciada com novas pistas (anti-decoreba). Tentativas restauradas.")


func discard_text(d: Dictionary) -> String:
	var attr_pt := {
		"continent": "continente", "hemisphere": "hemisfério",
		"language_family": "família linguística", "currency_iso": "moeda",
		"climate_tag": "clima",
	}
	var val_pt := {
		"south_america": "América do Sul", "north_america": "América do Norte",
		"europe": "Europa", "asia": "Ásia", "africa": "África", "oceania": "Oceania",
		"sul": "Sul", "norte": "Norte", "romance": "românica",
	}
	var parts: Array = []
	for s in d["statements"]:
		var v = str(s["value"])
		parts.append("%s = %s" % [attr_pt.get(s["attr"], str(s["attr"])), val_pt.get(v, v)])
	var names: Array = []
	for pid in d["eliminated"]:
		names.append(display_name(String(pid)))
	return "📌 Descarte — procure onde %s. Fora do painel: %s." % [
		" e ".join(parts), ", ".join(names),
	]


# ---------------------------------------------------------------- fim de caso
func _case_complete() -> void:
	result_label.text = "🎉 CASO CONCLUÍDO! Postais: %d/5 · XP total: %d · Verba: %d" % [
		postais.size(), xp_total, verba,
	]
	restart_btn.visible = true
