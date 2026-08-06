-- src/server/Services/ComboService.luau
-- LA AUTORIDAD del ritmo y del combo. El cliente solo avisa de que se pulsó
-- espacio; aquí se decide si eso fue Perfect, Good o fallo (ver ClienteYServidor.md).
--
-- El truco para poder juzgar sin fiarse del cliente: el ciclo del balón es
-- DETERMINISTA. Si el servidor sabe cuándo arrancó el ciclo de un jugador,
-- puede calcular él solo dónde está el balón en cualquier instante. El cliente
-- no le "cuenta" dónde estaba el balón, solo cuándo pulsó.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Knit = require(ReplicatedStorage.Packages.Knit)
local RhythmMath = require(ReplicatedStorage.Shared.RhythmMath)
local SkillConfig = require(ReplicatedStorage.Shared.SkillConfig)
local SkillMath = require(ReplicatedStorage.Shared.SkillMath)
local SkillTrajectories = require(ReplicatedStorage.Shared.SkillTrajectories)
local SpeedConfig = require(ReplicatedStorage.Shared.SpeedConfig)
local TimingConfig = require(ReplicatedStorage.Shared.TimingConfig)

type SkillState = {
	startTime: number,
	duration: number,
	zoneCenter: number,
	zoneHalfWidth: number,
}

type PlayerState = {
	combo: number,
	cycleStart: number,
	cycleDuration: number,
	lastResolvedBeat: number,
	rallyActive: boolean,
	-- Cuál es la próxima skill que toca (1 = la primera). Vuelve a 1 al perder
	-- el combo, para que la siguiente racha las reciba igual de pronto.
	nextSkillIndex: number,
	-- Momento de skill en curso, o nil si se está jugando normal. Mientras esto
	-- no sea nil, el ritmo de picaditas está EN PAUSA.
	skill: SkillState?,
}

local ComboService = Knit.CreateService({
	Name = "ComboService",
	Client = {
		-- Cliente → servidor: "he pulsado espacio en este instante".
		-- Es el ÚNICO canal de input. El servidor ya sabe si hay una skill
		-- activa, así que decide él si esa pulsación es una picadita o un
		-- intento de parar la barra. El cliente no tiene que enrutar nada.
		SendInput = Knit.CreateSignal(),
		-- Servidor → cliente: el veredicto y el combo que queda.
		PicaditaResult = Knit.CreateSignal(),
		-- Servidor → cliente: "empieza un momento de skill, píntalo".
		SkillStarted = Knit.CreateSignal(),
		-- Servidor → cliente: cómo acabó la skill.
		SkillResult = Knit.CreateSignal(),
	},
})

function ComboService:KnitInit()
	-- Estado indexado POR JUGADOR. Aunque ahora solo juegue uno, esto ya
	-- soporta muchos a la vez, cada uno con su balón y su ritmo propio.
	self._states = {} :: { [Player]: PlayerState }
	self._currencyService = nil
	-- La posición de la zona verde la sortea el SERVIDOR. Si la eligiera el
	-- cliente, sabría dónde va a caer antes de tiempo.
	self._random = Random.new()
end

function ComboService:KnitStart()
	-- En KnitStart ya es seguro pedir otros servicios: todos han pasado su
	-- KnitInit (ver CicloDeVidaKnit.md).
	self._currencyService = Knit.GetService("CurrencyService")

	for _, player in Players:GetPlayers() do
		self:_getOrCreateState(player)
	end

	Players.PlayerAdded:Connect(function(player)
		self:_getOrCreateState(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self._states[player] = nil
	end)

	self.Client.SendInput:Connect(function(player, clientTime)
		self:_handleInput(player, clientTime)
	end)

	-- Vigila los balones que se escapan sin que nadie los toque.
	RunService.Heartbeat:Connect(function()
		self:_checkEscapedBalls()
	end)
end

function ComboService:_getOrCreateState(player: Player): PlayerState
	local state = self._states[player]
	if state then
		return state
	end

	-- Atajo de pruebas: en Studio puedes arrancar ya con combo alto para ver
	-- la velocidad máxima. En el juego publicado esto siempre vale 0.
	local startCombo = if RunService:IsStudio() then math.max(SpeedConfig.DebugStartCombo, 0) else 0

	state = {
		combo = startCombo,
		-- Arrancamos el ritmo unos segundos en el futuro: así al entrar te da
		-- tiempo a ver el balón antes de que los toques empiecen a contar.
		cycleStart = Workspace:GetServerTimeNow() + TimingConfig.GracePeriod,
		cycleDuration = RhythmMath.GetCycleDuration(startCombo),
		-- Toques ya resueltos (acertados o perdidos). Empieza en -1 porque el
		-- primer toque del ciclo es el número 0.
		lastResolvedBeat = -1,
		-- Solo se puede "escapar" el balón si hay una racha en marcha. Antes
		-- del primer acierto estás calentando y no se te penaliza.
		rallyActive = false,
		nextSkillIndex = 1,
		skill = nil,
	}
	self._states[player] = state
	return state
end

-- Re-ancla el ciclo: cambia la duración según el combo actual y recoloca el
-- origen del reloj. ESTA ES LA PARTE DELICADA del paso 3.
--
-- El origen nuevo se expresa siempre como un INSTANTE ABSOLUTO acordado
-- (`anchorTime`), nunca como "ahora". Da igual que el servidor lo calcule con
-- retraso o que al cliente le llegue el aviso 80ms después: los dos aplican la
-- misma fórmula al mismo instante, así que llegan al mismo sitio. Si anclásemos
-- en "ahora", el "ahora" del servidor y el del cliente serían distintos y el
-- balón daría un salto en pantalla.
--
-- Tras re-anclar, el toque en `anchorTime` es el número 0.
--
-- `resolvedBeat` dice cuál es el último toque que se da por consumido, y por
-- defecto es 0: el propio `anchorTime`. Eso es lo correcto cuando anclamos en
-- un bote que el jugador ACABA de golpear. Pásale -1 cuando el balón llegue al
-- pie en `anchorTime` sin que nadie lo haya tocado todavía: así ese bote sigue
-- siendo golpeable en vez de contarse como fallo.
function ComboService:_reanchor(state: PlayerState, anchorTime: number, resolvedBeat: number?)
	state.cycleDuration = RhythmMath.GetCycleDuration(state.combo)
	state.cycleStart = anchorTime
	state.lastResolvedBeat = if resolvedBeat ~= nil then resolvedBeat else 0
end

function ComboService:_getRhythmPayload(state: PlayerState)
	return {
		startTime = state.cycleStart,
		duration = state.cycleDuration,
	}
end

-- El cliente llama a esto al arrancar para saber desde cuándo cuenta su ciclo.
-- Así dibuja el balón con el mismo reloj con el que el servidor juzga.
function ComboService:GetRhythmState(player: Player)
	return self:_getRhythmPayload(self:_getOrCreateState(player))
end

function ComboService.Client:GetRhythmState(player: Player)
	return self.Server:GetRhythmState(player)
end

-- Convierte la marca de tiempo que manda el cliente en una en la que podemos
-- confiar. Nunca la usamos tal cual: un cliente modificado puede enviar
-- cualquier cosa (un número del futuro, del pasado remoto, o basura).
function ComboService:_sanitizeInputTime(player: Player, clientTime: any): number
	local now = Workspace:GetServerTimeNow()

	-- Basura o NaN (el único valor que no es igual a sí mismo) → usamos "ahora".
	if type(clientTime) ~= "number" or clientTime ~= clientTime then
		return now
	end

	-- Le permitimos afirmar que pulsó un poco antes, para compensar su ping
	-- real. Sin esto, alguien con 150ms de latencia no acertaría jamás.
	-- Con esto acotado al ping medido, el margen para mentir es mínimo.
	local allowance = math.min(player:GetNetworkPing() * 2 + TimingConfig.LatencyGrace, TimingConfig.MaxInputLatency)
	return math.clamp(clientTime, now - allowance, now)
end

function ComboService:_handleInput(player: Player, clientTime: any)
	local state = self._states[player]
	if not state then
		return
	end

	local pressTime = self:_sanitizeInputTime(player, clientTime)

	-- Con una skill en marcha, esta pulsación es para parar la barra. El
	-- ritmo de picaditas está en pausa y no se toca.
	if state.skill then
		self:_handleSkillInput(player, state, pressTime)
		return
	end

	local beat, offset = RhythmMath.GetNearestBeat(state.cycleStart, state.cycleDuration, pressTime)

	-- Ese toque ya estaba resuelto: es una segunda pulsación sobre el mismo
	-- toque. Esto es lo que impide que machacar la tecla sea una estrategia.
	if beat <= state.lastResolvedBeat then
		self:_breakCombo(player, state, "Miss")
		return
	end

	-- Pulses bien o mal, ese toque queda consumido: no hay segundos intentos.
	state.lastResolvedBeat = beat

	local judgement = RhythmMath.Judge(offset, state.cycleDuration)
	if judgement == "Miss" then
		self:_breakCombo(player, state, "Miss")
		return
	end

	-- El instante IDEAL del toque que acaba de acertar. Ojo: no es cuándo
	-- pulsó (pudo ir 50ms pronto), sino el momento exacto en que el balón
	-- toca abajo. Es un instante que cliente y servidor ya tenían acordado,
	-- y por eso sirve de ancla limpia para el ciclo nuevo.
	local beatTime = state.cycleStart + beat * state.cycleDuration

	state.combo += 1
	state.rallyActive = true
	self:_reanchor(state, beatTime)

	-- Pagamos con el combo YA subido: si el HUD te enseña combo 6, cobras lo
	-- que vale el combo 6. Y como al fallar el combo vuelve a 0, el siguiente
	-- acierto cobra otra vez la tarifa mínima: perder la racha no solo borra
	-- el número, también te baja el sueldo por golpe.
	local earned, balance = self._currencyService:AwardPicadita(player, judgement, state.combo)

	self.Client.PicaditaResult:Fire(player, {
		result = judgement,
		combo = state.combo,
		rhythm = self:_getRhythmPayload(state),
		earned = earned,
		coins = balance,
	})

	-- ¿Este acierto ha llegado al combo de la próxima skill? Se comprueba
	-- DESPUÉS de avisar del resultado, para que el HUD ya muestre el combo
	-- nuevo cuando aparezca la barra.
	if state.combo >= SkillMath.GetThreshold(state.nextSkillIndex) then
		self:_startSkill(player, state)
	end
end

----- Momentos de skill (capa 2) -----

-- Arranca la barra épica. A partir de aquí el ritmo de picaditas queda EN
-- PAUSA: el vigilante de balones escapados salta a este jugador y su próxima
-- pulsación irá a la barra.
function ComboService:_startSkill(player: Player, state: PlayerState)
	state.nextSkillIndex += 1

	local halfWidth = SkillMath.GetZoneHalfWidth(state.combo)

	-- La zona se sortea dentro de la barra, sin pegarse a los extremos.
	local low = halfWidth + SkillConfig.EdgeMargin
	local high = 1 - low
	local center = if high > low then self._random:NextNumber(low, high) else 0.5

	state.skill = {
		-- El indicador no arranca de inmediato: LeadIn da tiempo a ver dónde
		-- ha caído la zona, y de paso absorbe el retraso del aviso por red.
		startTime = Workspace:GetServerTimeNow() + SkillConfig.LeadIn,
		duration = SkillMath.GetSweepDuration(state.combo),
		zoneCenter = center,
		zoneHalfWidth = halfWidth,
	}

	self.Client.SkillStarted:Fire(player, {
		startTime = state.skill.startTime,
		duration = state.skill.duration,
		zoneCenter = center,
		zoneHalfWidth = halfWidth,
		combo = state.combo,
	})
end

function ComboService:_handleSkillInput(player: Player, state: PlayerState, pressTime: number)
	local skill = state.skill :: SkillState

	-- La posición la calcula el SERVIDOR con su propio reloj, igual que la
	-- altura del balón. El cliente solo dice cuándo pulsó.
	local position = SkillMath.GetPosition(skill.startTime, skill.duration, pressTime)
	self:_resolveSkill(player, state, SkillMath.IsHit(position, skill.zoneCenter, skill.zoneHalfWidth), position)
end

function ComboService:_resolveSkill(player: Player, state: PlayerState, success: boolean, position: number)
	local skill = state.skill :: SkillState
	state.skill = nil

	local earned = 0
	local trajectory = nil

	if success then
		state.combo += 1
		state.rallyActive = true
		earned = self._currencyService:AwardSkill(player, state.combo)
		-- Al acertar, el balón hace una coreografía acompañando a la animación
		-- de celebración en lugar de su ciclo normal.
		trajectory = SkillConfig.DefaultTrajectory
	else
		-- Fallar una skill es un fallo grave: se pierde la racha entera.
		state.combo = 0
		state.rallyActive = false
		state.nextSkillIndex = 1
	end

	-- Volver al ritmo normal, pero NO todavía si hay celebración: el ciclo se
	-- ancla en el instante en que la coreografía TERMINA.
	--
	-- Esto no es un arreglo visual. Sin el retraso, el siguiente bote caía a
	-- 0.35-0.8s y su ventana se cerraba ANTES de que acabase la animación de
	-- 1s: se perdía el combo mientras veías la celebración, sin poder hacer nada.
	-- Y de paso, anclar al final de la coreografía es lo que hace que el balón
	-- salga de ella justo en su punto más bajo, sin ningún salto.
	--
	-- Durante la espera el vigilante de balones escapados no molesta: con
	-- cycleStart en el futuro, el toque ya resuelto es el 0 y el 1 aún no ha
	-- llegado. Es el mismo mecanismo que la cortesía de entrada al servidor.
	local celebration = SkillTrajectories.GetDuration(trajectory)

	-- Con coreografía, el balón LLEGA AL PIE justo en el instante del anclaje:
	-- es la regla de oro de las trayectorias. El jugador lo ve abajo y pulsa,
	-- así que ese bote tiene que ser golpeable (-1). Con el 0 por defecto se
	-- daba por consumido y el primer toque tras la skill salía siempre fallo,
	-- por mucho que se pulsara en el momento exacto.
	--
	-- Sin coreografía (skill fallada) sí vale el 0: no hay ningún bote en el
	-- anclaje, y así se le regala un ciclo entero para recolocarse.
	local firstBeatIsHittable = celebration > 0
	self:_reanchor(state, Workspace:GetServerTimeNow() + celebration, if firstBeatIsHittable then -1 else 0)

	self.Client.SkillResult:Fire(player, {
		ok = success,
		position = position,
		zoneCenter = skill.zoneCenter,
		zoneHalfWidth = skill.zoneHalfWidth,
		combo = state.combo,
		earned = earned,
		coins = self._currencyService:GetBalance(player),
		rhythm = self:_getRhythmPayload(state),
		-- Qué coreografía toca (nil si falló). El cliente la resuelve contra
		-- SkillTrajectories, y deduce cuándo empieza restando su duración a
		-- rhythm.startTime: va clavada al reloj compartido sin mandar más datos.
		trajectory = trajectory,
	})
end

-- Detecta los toques que se han pasado de largo sin que el jugador pulsara.
function ComboService:_checkEscapedBalls()
	local now = Workspace:GetServerTimeNow()

	for player, state in self._states do
		-- Con una skill en marcha el ritmo está en pausa: ni se le exige tocar
		-- el balón ni se le puede escapar.
		if state.skill then
			local skill = state.skill
			local deadline = SkillMath.GetDeadline(skill.startTime, skill.duration)
			-- Se le da el mismo margen de latencia que a las picaditas, para
			-- que una pulsación justa en el límite no se pierda por el camino.
			if now > deadline + TimingConfig.MaxInputLatency then
				-- Dónde se quedó parado el indicador al agotarse las pasadas.
				-- Se calcula en vez de darlo por hecho: con rebote acaba en el
				-- extremo izquierdo, sin rebote acabaría en el derecho.
				local finalPosition = SkillMath.GetPosition(skill.startTime, skill.duration, deadline)
				self:_resolveSkill(player, state, false, finalPosition)
			end
			continue
		end

		if not state.rallyActive then
			continue
		end

		local closedBeat = RhythmMath.GetLastClosedBeat(state.cycleStart, state.cycleDuration, now)
		if closedBeat > state.lastResolvedBeat then
			state.lastResolvedBeat = closedBeat
			self:_breakCombo(player, state, "Escaped")
		end
	end
end

function ComboService:_breakCombo(player: Player, state: PlayerState, reason: string)
	local lostCombo = state.combo

	-- Decisión de diseño: el combo se va a cero pero sigues jugando (nada de
	-- terminar la partida). Ver SistemaCombos.md.
	state.combo = 0
	state.rallyActive = false
	-- La próxima racha vuelve a recibir las skills desde el principio.
	state.nextSkillIndex = 1

	-- Perder el combo devuelve el balón a la velocidad base, que puede ser un
	-- frenazo enorme (de 0.35s a 0.8s de golpe). Aquí no hay ningún toque que
	-- sirva de ancla, así que anclamos "hacia atrás": calculamos dónde está el
	-- balón AHORA y colocamos el origen del ciclo nuevo de forma que caiga
	-- justo en esa misma posición. El balón sigue desde donde estaba y solo
	-- cambia el ritmo al que se mueve a partir de ahí.
	local now = Workspace:GetServerTimeNow()
	local phase = RhythmMath.GetPhase(state.cycleStart, state.cycleDuration, now)
	local newDuration = RhythmMath.GetCycleDuration(state.combo)
	self:_reanchor(state, now - phase * newDuration)

	-- El saldo NO se toca al fallar: las monedas ya ganadas son tuyas. Lo que
	-- se pierde es el multiplicador, o sea lo que cobrarás de aquí en adelante.
	self.Client.PicaditaResult:Fire(player, {
		result = reason,
		combo = 0,
		lostCombo = lostCombo,
		rhythm = self:_getRhythmPayload(state),
		earned = 0,
		coins = self._currencyService:GetBalance(player),
	})
end

-- Para que otros Services (el de monedas, el próximo paso) consulten el combo
-- sin tocar la tabla interna.
function ComboService:GetCombo(player: Player): number
	local state = self._states[player]
	return state and state.combo or 0
end

-- ⚠️ Fuerza una skill sin tener que llegar al combo. Igual que DebugAddCoins:
-- el método se define DENTRO del if, así que fuera de Studio no existe y Knit
-- no le crea remote.
if RunService:IsStudio() then
	function ComboService.Client:DebugTriggerSkill(player: Player)
		local state = self.Server._states[player]
		if not state or state.skill then
			return false
		end
		self.Server:_startSkill(player, state)
		return true
	end
end

return ComboService
