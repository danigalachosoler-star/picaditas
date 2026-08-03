-- src/shared/RhythmMath.luau
-- Las cuentas del ritmo, en funciones puras (entra un número, sale un número;
-- no tocan nada del mundo). Al vivir en Shared, cliente y servidor calculan
-- EXACTAMENTE lo mismo y es imposible que se desincronicen.
--
-- Modelo: el ciclo del balón arranca en `startTime` y dura `duration`
-- segundos. El balón toca abajo en startTime, startTime + duration,
-- startTime + 2*duration... A cada uno de esos instantes lo llamamos un
-- "toque" (beat), numerado 0, 1, 2, ...

local TimingConfig = require(script.Parent.TimingConfig)

local RhythmMath = {}

export type Judgement = "Perfect" | "Good" | "Miss"

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
function RhythmMath.Judge(offset: number): Judgement
	local distance = math.abs(offset)
	if distance <= TimingConfig.PerfectWindow then
		return "Perfect"
	elseif distance <= TimingConfig.GoodWindow then
		return "Good"
	end
	return "Miss"
end

-- Último toque cuya ventana ya se cerró del todo antes de `t`. Sirve para
-- detectar los balones que se han escapado sin que el jugador pulsara nada.
function RhythmMath.GetLastClosedBeat(startTime: number, duration: number, t: number): number
	return math.floor((t - TimingConfig.GoodWindow - startTime) / duration)
end

return RhythmMath
