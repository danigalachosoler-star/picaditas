-- src/shared/SkillTrajectories.luau
-- Coreografías del balón durante una skill.
--
-- Al clavar una skill, el balón deja de hacer su ciclo de picadita y pasa a
-- seguir un recorrido escrito a mano que acompaña a la animación del
-- personaje. Cuando la coreografía acaba, vuelve al ciclo normal.
--
-- ⚠️ REGLA DE ORO DE UNA TRAYECTORIA: tiene que EMPEZAR y ACABAR en Vector3.zero
-- (o sea, en el punto de contacto del pie). El ciclo normal está en su punto
-- más bajo justo ahí, así que empezar y terminar en cero es lo que hace que no
-- haya ningún salto al entrar ni al salir.
--
-- CÓMO AÑADIR UNA SKILL NUEVA:
--   1. Escribe una entrada más en Definitions con su duración, su contactTime
--      y su GetOffset.
--   2. Haz que el servidor mande ese id en el resultado de la skill.
--   Nada más: el BallController resuelve el id contra esta tabla.
--
-- Vive en Shared porque el SERVIDOR necesita la duración (para saber cuánto
-- retrasar la vuelta al ritmo normal) y el CLIENTE necesita la forma.

local BallConfig = require(script.Parent.BallConfig)

local SkillTrajectories = {}

export type Trajectory = {
	-- Cuánto dura la coreografía entera, en segundos. Debe cuadrar con la
	-- duración de la animación del personaje.
	duration: number,
	-- Instante en el que el pie golpea el balón, medido desde el inicio.
	-- ⚠️ Tiene que coincidir con el marker `Contacto` de la animación. El
	-- CharacterAnimationController mide el valor real y lo imprime en Studio
	-- la primera vez que se reproduce: copia ese número aquí.
	contactTime: number,
	-- Dónde está el balón en el instante `t`, respecto al punto de contacto.
	-- Y va en vertical del mundo; X/Z son relativos al personaje (Z negativo
	-- es hacia delante).
	GetOffset: (t: number) -> Vector3,
}

----- Vuelta al mundo -----

-- OJO, que es fácil confundirse: la vuelta al mundo NO es una chilena. Es un
-- truco de freestyle a ras de suelo — el jugador pasa la pierna por encima del
-- balón mientras sigue haciendo picaditas. El balón se queda BAJO, cerca del
-- pie. Nada de dispararlo por los aires ni alejarlo del cuerpo.
--
-- O sea: es una picadita normal, pero con más tiempo en el aire para que quepa
-- el gesto de la pierna. Por eso usa la misma parábola que el ciclo normal.

-- Altura del bote, como múltiplo de la de una picadita normal
-- (BallConfig.BounceHeight). 1.0 = idéntica; 1.15 = un pelín más alta, para
-- dar aire al gesto sin que parezca otro movimiento.
local VUELTA_HEIGHT_SCALE = 1.0

-- Segundos que el balón descansa en el pie al FINAL, antes de retomar el ciclo.
-- Con 0 aterriza justo en el último fotograma. Súbelo si quieres que caiga un
-- poco antes y se quede un instante quieto para rematar el gesto.
local VUELTA_SETTLE = 0

local VUELTA_DURATION = 1

-- Medido de verdad con el marker de la animación (lo imprime el
-- CharacterAnimationController en Studio la primera vez).
local VUELTA_CONTACT = 0.104

local function vueltaAlMundo(t: number): Vector3
	-- Antes del toque el balón está en el pie, esperando. Como el contacto cae
	-- muy pronto (0.1s de 1s), este tramo es apenas un suspiro.
	if t <= VUELTA_CONTACT then
		return Vector3.zero
	end

	-- Tiempo de vuelo: desde que la pierna lo toca hasta que vuelve al pie.
	local airtime = VUELTA_DURATION - VUELTA_CONTACT - VUELTA_SETTLE
	if airtime <= 0 then
		return Vector3.zero
	end

	local u = (t - VUELTA_CONTACT) / airtime
	if u >= 1 then
		-- Ya ha aterrizado; espera en el pie el resto del gesto.
		return Vector3.zero
	end

	-- La MISMA parábola que el ciclo normal (ver BallController), solo que
	-- estirada en el tiempo. Así se ve como una picadita de siempre, más lenta.
	local apex = BallConfig.BounceHeight * VUELTA_HEIGHT_SCALE
	return Vector3.new(0, 4 * apex * u * (1 - u), 0)
end

SkillTrajectories.Definitions = {
	vuelta_al_mundo = {
		duration = VUELTA_DURATION,
		contactTime = VUELTA_CONTACT,
		GetOffset = vueltaAlMundo,
	},
} :: { [string]: Trajectory }

function SkillTrajectories.Get(id: string?): Trajectory?
	if id == nil then
		return nil
	end
	return SkillTrajectories.Definitions[id]
end

-- Cuánto dura la coreografía de una skill. 0 si no tiene ninguna, para que el
-- servidor pueda sumarlo sin comprobar nada.
function SkillTrajectories.GetDuration(id: string?): number
	local trajectory = SkillTrajectories.Get(id)
	return if trajectory then trajectory.duration else 0
end

return SkillTrajectories
