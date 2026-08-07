-- src/client/Controllers/BallController.luau
-- El balón: bota en bucle delante del personaje siguiendo el reloj del
-- servidor, y durante una skill sigue una coreografía escrita a mano
-- (ver SkillTrajectories.luau) en vez de su ciclo normal.
--
-- Es puramente visual, por eso vive en el CLIENTE (ver ClienteYServidor.md).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Knit = require(ReplicatedStorage.Packages.Knit)
local BallConfig = require(ReplicatedStorage.Shared.BallConfig)
local Catalog = require(ReplicatedStorage.Shared.Catalog)
local RhythmMath = require(ReplicatedStorage.Shared.RhythmMath)
local SkillTrajectories = require(ReplicatedStorage.Shared.SkillTrajectories)

local BallController = Knit.CreateController({
	Name = "BallController",
})

function BallController:KnitInit()
	self._ball = nil
	self._connection = nil
	self._paused = false

	-- Coreografía en curso al clavar una skill, o nil si el balón va a su bola.
	self._trajectory = nil

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

	-- El servidor cambia la velocidad al acertar y al fallar, y nos manda el
	-- ritmo nuevo en el mismo mensaje del resultado. No hace falta un canal
	-- aparte: los dos momentos coinciden siempre.
	ComboService.PicaditaResult:Connect(function(payload)
		if payload.rhythm then
			self._rhythm = payload.rhythm
		end
	end)

	-- Durante una skill el balón se congela donde esté: el momento de skill es
	-- aparte y el ritmo de picaditas está en pausa. Al resolverse, el servidor
	-- manda un ritmo re-anclado y el balón arranca de nuevo desde abajo.
	ComboService.SkillStarted:Connect(function()
		self._paused = true
	end)

	ComboService.SkillResult:Connect(function(payload)
		if payload.rhythm then
			self._rhythm = payload.rhythm
		end
		self._paused = false
		self:_beginTrajectory(payload)
	end)

	self:_watchSkin()

	-- PreRender (antes se llamaba RenderStepped) se dispara una vez por frame,
	-- justo antes de dibujar. Es el sitio correcto para mover algo visual:
	-- así el movimiento va suave sea cual sea los FPS del jugador.
	self._connection = RunService.PreRender:Connect(function()
		self:_update()
	end)
end

-- Pinta el balón con la skin equipada y se queda escuchando por si cambia.
function BallController:_watchSkin()
	local InventoryService = Knit.GetService("InventoryService")

	-- Al equipar en la tienda, el servidor manda lo que llevas puesto y el
	-- balón cambia de color al momento, sin recargar nada.
	InventoryService.EquippedChanged:Connect(function(equipped)
		self:_applySkin(equipped)
	end)

	-- El color de arranque va en su propio hilo porque pedirlo espera a que
	-- cargue el perfil, y no queremos retrasar por eso el resto del arranque.
	-- Mientras tanto el balón se ve con el color por defecto.
	task.spawn(function()
		self:_applySkin(InventoryService:GetSnapshot():expect().equipped)
	end)
end

function BallController:_applySkin(equipped)
	-- Sin skin equipada (o con una que ya no está en el catálogo), el color
	-- de siempre.
	self._ball.Color = Catalog.GetBallColor(equipped) or BallConfig.Color
end

-- Dónde estaría el balón en su punto más bajo AHORA MISMO: el punto de
-- contacto con el pie, calculado desde el personaje.
--
-- PointToWorldSpace aplica también la ROTACIÓN del personaje, así que el
-- offset "hacia delante" sigue siendo hacia delante aunque el jugador gire.
-- Devuelve nil si todavía no hay personaje (justo al entrar, o al reaparecer).
function BallController:_getRoot(): BasePart?
	local character = Players.LocalPlayer.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

function BallController:_getContactPoint(): Vector3?
	local root = self:_getRoot()
	if not root then
		return nil
	end
	return root.CFrame:PointToWorldSpace(BallConfig.ContactOffset)
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

	-- El punto de contacto se recalcula CADA FRAME: así el balón acompaña al
	-- personaje si anda o gira, en vez de quedarse en un sitio fijo del mundo.
	local contact = self:_getContactPoint()
	if not contact then
		-- Sin personaje (reapareciendo) escondemos el balón en vez de dejarlo
		-- flotando en la última posición conocida.
		self._ball.Transparency = 1
		return
	end
	self._ball.Transparency = 0

	local now = Workspace:GetServerTimeNow()

	-- Con una coreografía en marcha, el balón la sigue en vez de botar.
	local offset = self:_getTrajectoryOffset(now)
	if offset then
		-- X/Z van en el sistema del personaje (para que "hacia delante" siga
		-- siendo hacia delante si gira); la altura, en vertical del mundo.
		local root = self:_getRoot()
		local horizontal = if root
			then root.CFrame:VectorToWorldSpace(Vector3.new(offset.X, 0, offset.Z))
			else Vector3.zero
		self._ball.Position = contact + horizontal + Vector3.new(0, offset.Y, 0)
		return
	end

	-- Durante la barra de skill el balón se queda quieto EN EL PIE, pero sigue
	-- acompañando al personaje. Por eso la pausa se comprueba aquí y no antes.
	local t = 0
	if not self._paused then
		-- GetServerTimeNow() es un reloj que Roblox mantiene sincronizado entre
		-- el servidor y todos los clientes. Es lo que permite que las dos
		-- máquinas coincidan sin mandarse mensajes constantemente.
		t = RhythmMath.GetPhase(rhythm.startTime, rhythm.duration, now)
	end

	-- Parábola de rebote: vale 0 en t=0, llega al máximo en t=0.5 y vuelve a 0
	-- en t=1. Da el aspecto de un balón real (rápido abajo, lento arriba),
	-- a diferencia de un movimiento lineal o de un seno.
	local height = 4 * BallConfig.BounceHeight * t * (1 - t)

	-- La altura se suma en vertical del MUNDO, no del personaje: si el
	-- personaje se inclina, el balón sigue botando hacia arriba.
	self._ball.Position = contact + Vector3.new(0, height, 0)
end

-- Arranca la coreografía que toque, si la skill se acertó.
--
-- El instante de inicio NO viene en el mensaje: se deduce de rhythm.startTime,
-- que el servidor ancló justo al FINAL de la coreografía. Restarle la duración
-- da el principio, medido con el reloj compartido. Así la coreografía va
-- clavada a lo que el servidor cree, sin mandar ningún dato más.
function BallController:_beginTrajectory(payload)
	local trajectory = SkillTrajectories.Get(payload.trajectory)
	if not trajectory or not payload.rhythm then
		self._trajectory = nil
		return
	end

	self._trajectory = {
		definition = trajectory,
		startTime = payload.rhythm.startTime - trajectory.duration,
	}
end

-- Desplazamiento del balón respecto al pie, o nil si no hay coreografía activa.
function BallController:_getTrajectoryOffset(now: number): Vector3?
	local active = self._trajectory
	if not active then
		return nil
	end

	local elapsed = now - active.startTime
	if elapsed < 0 then
		-- Aún no ha empezado (el aviso llegó antes de tiempo): el balón espera
		-- en el pie, que es donde arranca la coreografía.
		return Vector3.zero
	end

	if elapsed >= active.definition.duration then
		-- Terminada. Se suelta y el ciclo normal toma el relevo: en este mismo
		-- instante su fase es 0, o sea el balón está en el pie. Justo donde
		-- acaba la coreografía, así que no se ve ningún salto.
		self._trajectory = nil
		return nil
	end

	return active.definition.GetOffset(elapsed)
end

return BallController
