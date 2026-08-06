-- src/shared/SkillMath.luau
-- Las cuentas de las skills, en funciones puras. Igual que RhythmMath: al
-- vivir en Shared, cliente y servidor calculan lo mismo y no pueden
-- desincronizarse. El cliente las usa para DIBUJAR, el servidor para JUZGAR.

local SkillConfig = require(script.Parent.SkillConfig)

local SkillMath = {}

-- Combo en el que aparece la skill número `index` (la primera es la 1).
--
-- El primer hueco es FirstGap y cada siguiente se multiplica por GapGrowth,
-- con un techo en MaxGap. Con los valores por defecto sale:
--   skill 1 → combo 5,  2 → 13,  3 → 24,  4 → 39,  5 → 59,  6 → 86...
function SkillMath.GetThreshold(index: number): number
	if index <= 1 then
		return SkillConfig.FirstCombo
	end

	local threshold = SkillConfig.FirstCombo
	local gap = SkillConfig.FirstGap

	for _ = 2, index do
		threshold += math.min(math.round(gap), SkillConfig.MaxGap)
		gap *= SkillConfig.GapGrowth
	end

	return threshold
end

-- Interpolación suave entre dos valores según el combo. Es la misma curva en S
-- que usa la velocidad del balón: plana al principio (no castiga al que
-- empieza) y plana al final (llegar al techo no se nota).
local function scaleWithCombo(combo: number, from: number, to: number): number
	local span = SkillConfig.ComboAtMaxDifficulty
	if span <= 0 then
		return to
	end

	local progress = math.clamp(combo / span, 0, 1)
	local eased = progress * progress * (3 - 2 * progress)
	return from + (to - from) * eased
end

-- Cuánto tarda el indicador en cruzar la barra entera. Baja con el combo.
function SkillMath.GetSweepDuration(combo: number): number
	return scaleWithCombo(combo, SkillConfig.BaseSweepDuration, SkillConfig.MinSweepDuration)
end

-- Media anchura de la zona verde. Hoy es constante: la dificultad sube solo
-- por velocidad. Para que también se encoja, cambia el return por algo como
--   scaleWithCombo(combo, SkillConfig.ZoneHalfWidth, SkillConfig.MinZoneHalfWidth)
function SkillMath.GetZoneHalfWidth(_combo: number): number
	return SkillConfig.ZoneHalfWidth
end

-- Dónde está el indicador en el instante `t`, de 0 (izquierda) a 1 (derecha).
--
-- Va y viene: la primera pasada recorre 0→1, en el extremo REBOTA y la
-- segunda recorre 1→0, y así hasta agotar SkillConfig.Sweeps pasadas. Es una
-- onda triangular recortada, no un bucle infinito: al agotarse se queda
-- quieta en el extremo y la skill se da por fallada.
--
-- Antes de arrancar (durante el LeadIn) se queda en 0.
function SkillMath.GetPosition(startTime: number, duration: number, t: number): number
	if duration <= 0 then
		return 0
	end

	-- Cuántas pasadas completas llevamos, con decimales. Recortado al total,
	-- que es lo que congela el indicador cuando se acaba el tiempo.
	local progress = math.clamp((t - startTime) / duration, 0, SkillConfig.Sweeps)

	local leg = math.floor(progress)
	local within = progress - leg

	-- Pasadas pares van hacia la derecha, impares hacia la izquierda.
	return if leg % 2 == 0 then within else 1 - within
end

function SkillMath.IsHit(position: number, zoneCenter: number, zoneHalfWidth: number): boolean
	return math.abs(position - zoneCenter) <= zoneHalfWidth
end

-- Instante en el que se agotan todas las pasadas. Pasado eso sin pulsar, la
-- skill se da por fallada.
function SkillMath.GetDeadline(startTime: number, duration: number): number
	return startTime + duration * SkillConfig.Sweeps
end

return SkillMath
