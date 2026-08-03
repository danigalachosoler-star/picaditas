-- src/server/Services/CurrencyService.luau
-- Dueño del monedero de cada jugador. Servicio aparte del ComboService porque
-- en el paso 5 esto es lo que se guardará con DataStore, y CLAUDE.md pide que
-- los datos del jugador vivan en un Service dedicado.
--
-- ⚠️ Este paso guarda el saldo SOLO EN MEMORIA: al salir de la partida se
-- pierde. La persistencia es el paso siguiente.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local EconomyConfig = require(ReplicatedStorage.Shared.EconomyConfig)

local REWARDS = {
	Perfect = EconomyConfig.PerfectReward,
	Good = EconomyConfig.GoodReward,
}

local CurrencyService = Knit.CreateService({
	Name = "CurrencyService",
	Client = {},
})

function CurrencyService:KnitInit()
	-- Saldo por jugador, igual que el combo: indexado por Player, listo para
	-- muchos a la vez (ver VisionYFases.md).
	self._balances = {} :: { [Player]: number }
end

function CurrencyService:KnitStart()
	for _, player in Players:GetPlayers() do
		self:_getOrCreate(player)
	end

	Players.PlayerAdded:Connect(function(player)
		self:_getOrCreate(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self._balances[player] = nil
	end)
end

function CurrencyService:_getOrCreate(player: Player): number
	local balance = self._balances[player]
	if not balance then
		balance = 0
		self._balances[player] = balance
	end
	return balance
end

-- HUECO PARA EL FUTURO: el Game Pass x2 de monedas (ver Monetizacion.md).
-- Hoy devuelve 1 siempre, así que no cambia nada. Cuando toque implementarlo,
-- este es el único sitio que hay que tocar: consultar el Game Pass del jugador
-- y devolver 2. La fórmula de abajo ya lo multiplica.
function CurrencyService:GetMultiplier(_player: Player): number
	return 1
end

-- Cuánto vale una picadita. Función aparte para poder razonar sobre ella (y
-- para que el HUD pueda enseñar el valor sin duplicar la fórmula).
function CurrencyService:GetPicaditaReward(player: Player, judgement: string, combo: number): number
	local base = REWARDS[judgement]
	if not base then
		-- Un Miss o un veredicto desconocido no paga.
		return 0
	end

	local comboMultiplier = 1 + combo * EconomyConfig.ComboFactor
	local amount = base * comboMultiplier * self:GetMultiplier(player)

	return math.max(EconomyConfig.MinReward, math.floor(amount))
end

-- Paga la picadita y devuelve (lo ganado, saldo nuevo).
function CurrencyService:AwardPicadita(player: Player, judgement: string, combo: number): (number, number)
	local earned = self:GetPicaditaReward(player, judgement, combo)
	if earned <= 0 then
		return 0, self:_getOrCreate(player)
	end

	local balance = self:_getOrCreate(player) + earned
	self._balances[player] = balance
	return earned, balance
end

function CurrencyService:GetBalance(player: Player): number
	return self:_getOrCreate(player)
end

function CurrencyService.Client:GetBalance(player: Player): number
	return self.Server:GetBalance(player)
end

return CurrencyService
