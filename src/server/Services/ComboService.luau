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
local BallConfig = require(ReplicatedStorage.Shared.BallConfig)
local RhythmMath = require(ReplicatedStorage.Shared.RhythmMath)
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
end

function ComboService:KnitStart()
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

	state = {
		combo = 0,
		-- Arrancamos el ritmo unos segundos en el futuro: así al entrar te da
		-- tiempo a ver el balón antes de que los toques empiecen a contar.
		cycleStart = Workspace:GetServerTimeNow() + TimingConfig.GracePeriod,
		cycleDuration = BallConfig.CycleDuration,
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

-- El cliente llama a esto al arrancar para saber desde cuándo cuenta su ciclo.
-- Así dibuja el balón con el mismo reloj con el que el servidor juzga.
function ComboService:GetRhythmState(player: Player)
	local state = self:_getOrCreateState(player)
	return {
		startTime = state.cycleStart,
		duration = state.cycleDuration,
	}
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

	local judgement = RhythmMath.Judge(offset)
	if judgement == "Miss" then
		self:_breakCombo(player, state, "Miss")
		return
	end

	state.combo += 1
	state.rallyActive = true

	self.Client.PicaditaResult:Fire(player, {
		result = judgement,
		combo = state.combo,
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

	self.Client.PicaditaResult:Fire(player, {
		result = reason,
		combo = 0,
		lostCombo = lostCombo,
	})
end

-- Para que otros Services (el de monedas, el próximo paso) consulten el combo
-- sin tocar la tabla interna.
function ComboService:GetCombo(player: Player): number
	local state = self._states[player]
	return state and state.combo or 0
end

return ComboService
