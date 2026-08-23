# Núcleo puro — pontuação (única métrica: XP).
extends RefCounted

const TIER_BASE := {1: 40, 2: 60, 3: 90, 4: 130, 5: 180}
const STREAK_CAP := 5


static func tier_base(tier: int) -> int:
	if TIER_BASE.has(tier):
		return int(TIER_BASE[tier])
	return 40


# Linear até o rank 9; no rank 10 o multiplicador é SUBSTITUÍDO por 3.0.
static func rank_multiplier(rank: int) -> float:
	if rank >= 10:
		return 3.0
	return 1.0 + 0.08 * float(rank - 1)


static func compute_xp(base: int, mult: float, unused_pa: int, streak: int, bonus_pct: int) -> int:
	var s := mini(streak, STREAK_CAP)
	var raw := float(base) * mult * (1.0 + 0.15 * float(unused_pa)) * (1.0 + 0.10 * float(s)) * (1.0 + float(bonus_pct) / 100.0)
	return int(round(raw))
