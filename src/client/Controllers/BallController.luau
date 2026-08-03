-- src/client/Controllers/BallController.luau
-- Ciclo visual del balón: sube y baja en bucle en un punto fijo del mundo.
-- Es puramente visual, por eso vive en el CLIENTE (ver ClienteYServidor.md).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Knit = require(ReplicatedStorage.Packages.Knit)
local BallConfig = require(ReplicatedStorage.Shared.BallConfig)
local RhythmMath = require(ReplicatedStorage.Shared.RhythmMath)

local BallController = Knit.CreateController({
	Name = "BallController",
})

function BallController:KnitInit()
	self._ball = nil
	self._connection = nil

	-- Cuándo arrancó nuestro ciclo y cuánto dura. Nos lo dice el SERVIDOR.
	self._rhythm = nil
end

function BallController:KnitStart()
	self._ball = self:_createBall()

	-- Le preguntamos al servidor por nuestro ritmo. Es la pieza clave del
	-- paso 2: antes el balón llevaba su propio contador, y eso se iba
	-- separando poco a poco del reloj del servidor. Resultado: verías el
	-- balón abajo y el servidor diría que fallaste. Ahora los dos calculan
	-- la posición con la MISMA fórmula y el MISMO reloj, así que es imposible
	-- que se desincronicen.
	local ComboService = Knit.GetService("ComboService")
	self._rhythm = ComboService:GetRhythmState():expect()

	-- PreRender (antes se llamaba RenderStepped) se dispara una vez por frame,
	-- justo antes de dibujar. Es el sitio correcto para mover algo visual:
	-- así el movimiento va suave sea cual sea los FPS del jugador.
	self._connection = RunService.PreRender:Connect(function()
		self:_update()
	end)
end

-- Crea el balón por código. Al crearlo desde un LocalScript, la Part solo
-- existe en la máquina de este jugador: el servidor y los demás no la ven.
function BallController:_createBall(): BasePart
	local ball = Instance.new("Part")
	ball.Name = "PicaditaBall"
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.one * (BallConfig.Radius * 2)
	ball.Color = BallConfig.Color
	ball.Material = Enum.Material.SmoothPlastic
	ball.Position = BallConfig.Origin

	-- Anchored: la física de Roblox no lo toca, lo movemos nosotros a mano.
	-- Así el movimiento es 100% predecible (lo necesitamos para el timing).
	ball.Anchored = true
	-- Que no choque ni empuje al personaje mientras pasa a su lado.
	ball.CanCollide = false
	ball.CanQuery = false
	ball.CanTouch = false

	ball.Parent = Workspace
	return ball
end

function BallController:_update()
	local rhythm = self._rhythm
	if not rhythm then
		return
	end

	-- GetServerTimeNow() es un reloj que Roblox mantiene sincronizado entre el
	-- servidor y todos los clientes. Es lo que permite que las dos máquinas
	-- coincidan sin mandarse mensajes constantemente.
	local t = RhythmMath.GetPhase(rhythm.startTime, rhythm.duration, Workspace:GetServerTimeNow())

	-- Parábola de rebote: vale 0 en t=0, llega al máximo en t=0.5 y vuelve a 0
	-- en t=1. Da el aspecto de un balón real (rápido abajo, lento arriba),
	-- a diferencia de un movimiento lineal o de un seno.
	local height = 4 * BallConfig.BounceHeight * t * (1 - t)

	self._ball.Position = BallConfig.Origin + Vector3.new(0, height, 0)
end

return BallController
