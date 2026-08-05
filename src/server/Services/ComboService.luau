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
local SpeedConfig = require(ReplicatedStorage.Shared.SpeedConfig)
local TimingConfig = require(ReplicatedStorage.Shared.TimingConfig)

type PlayerState = {
	combo: number,
	cycleStart: number,
	cycleDuration: number,
	lastResolvedBeat: number,
	rallyActive: boolean,
}

local ComboService = Knit.CreateService({
	Name = "ComboService",
	Client = {
		-- Cliente → servidor: "he pulsado espacio en este instante".
		SendInput = Knit.CreateSignal(),
		-- Servidor → cliente: el veredicto y el combo que queda.
		PicaditaResult = Knit.CreateSignal(),
	},
})

function ComboService:KnitInit()
	-- Estado indexado POR JUGADOR. Aunque ahora solo juegue uno, esto ya
	-- soporta muchos a la vez, cada uno con su balón y su ritmo propio.
	self._states = {} :: { [Player]: PlayerState }
	self._currencyService = nil
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
-- Tras re-anclar, el toque en `anchorTime` es el número 0 y el siguiente el 1.
function ComboService:_reanchor(state: PlayerState, anchorTime: number)
	state.cycleDuration = RhythmMath.GetCycleDuration(state.combo)
	state.cycleStart = anchorTime
	state.lastResolvedBeat = 0
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
end

-- Detecta los toques que se han pasado de largo sin que el jugador pulsara.
function ComboService:_checkEscapedBalls()
	local now = Workspace:GetServerTimeNow()

	for player, state in self._states do
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

return ComboService
