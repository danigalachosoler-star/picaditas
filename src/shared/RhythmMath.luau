-- src/shared/RhythmMath.luau
-- Las cuentas del ritmo, en funciones puras (entra un número, sale un número;
-- no tocan nada del mundo). Al vivir en Shared, cliente y servidor calculan
-- EXACTAMENTE lo mismo y es imposible que se desincronicen.
--
-- Modelo: el ciclo del balón arranca en `startTime` y dura `duration`
-- segundos. El balón toca abajo en startTime, startTime + duration,
-- startTime + 2*duration... A cada uno de esos instantes lo llamamos un
-- "toque" (beat), numerado 0, 1, 2, ...

local SpeedConfig = require(script.Parent.SpeedConfig)
local TimingConfig = require(script.Parent.TimingConfig)

local RhythmMath = {}

export type Judgement = "Perfect" | "Good" | "Miss"

-- Cuánto dura el ciclo del balón para un combo dado. Es LA curva de dificultad.
--
-- Usamos "smoothstep" (x² * (3 - 2x)), una curva con forma de S: arranca plana,
-- acelera en el tramo medio y vuelve a aplanarse al llegar al techo. Elegida
-- porque sus dos extremos son planos, y eso da justo lo que queremos:
--   · los primeros combos se sienten idénticos → no castiga al que empieza,
--   · llegar al techo es imperceptible → no hay un "golpe" al tocar el límite.
-- Una recta pura tendría ese golpe seco al topar con el mínimo.
function RhythmMath.GetCycleDuration(combo: number): number
	local span = SpeedConfig.ComboAtMaxSpeed
	if span <= 0 then
		return SpeedConfig.MinCycleDuration
	end

	local progress = math.clamp(combo / span, 0, 1) ^ SpeedConfig.CurveExponent
	local eased = progress * progress * (3 - 2 * progress)

	return SpeedConfig.BaseCycleDuration + (SpeedConfig.MinCycleDuration - SpeedConfig.BaseCycleDuration) * eased
end

-- Ventanas realmente aplicables a un ciclo de esta duración. A velocidades
-- altas las de config no caben y hay que recortarlas (ver MaxWindowFraction).
function RhythmMath.GetWindows(duration: number): (number, number)
	local maxHalf = duration * TimingConfig.MaxWindowFraction
	return math.min(TimingConfig.PerfectWindow, maxHalf), math.min(TimingConfig.GoodWindow, maxHalf)
end

-- Posición dentro del ciclo, de 0 a 1 (0 = abajo, 0.5 = arriba del todo).
function RhythmMath.GetPhase(startTime: number, duration: number, t: number): number
	return ((t - startTime) / duration) % 1
end

-- Devuelve el toque más cercano al instante `t` y a cuánto se quedó.
-- El desfase lleva signo: negativo = has pulsado PRONTO, positivo = TARDE.
function RhythmMath.GetNearestBeat(startTime: number, duration: number, t: number): (number, number)
	local beat = math.round((t - startTime) / duration)
	local offset = t - (startTime + beat * duration)
	return beat, offset
end

-- Traduce un desfase en segundos al veredicto correspondiente.
function RhythmMath.Judge(offset: number, duration: number): Judgement
	local perfect, good = RhythmMath.GetWindows(duration)
	local distance = math.abs(offset)
	if distance <= perfect then
		return "Perfect"
	elseif distance <= good then
		return "Good"
	end
	return "Miss"
end

-- Último toque cuya ventana ya se cerró del todo antes de `t`. Sirve para
-- detectar los balones que se han escapado sin que el jugador pulsara nada.
function RhythmMath.GetLastClosedBeat(startTime: number, duration: number, t: number): number
	local _, good = RhythmMath.GetWindows(duration)
	return math.floor((t - good - startTime) / duration)
end

return RhythmMath
