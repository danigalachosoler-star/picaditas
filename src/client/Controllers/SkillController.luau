-- src/client/Controllers/SkillController.luau
-- La barra de skill épica (capa 2). Dibuja la barra, mueve el indicador y
-- enseña el resultado.
--
-- No juzga nada: la posición del indicador la calcula con la MISMA fórmula y
-- el MISMO reloj que el servidor (igual que el balón), así que lo que se ve es
-- exactamente lo que el servidor usa para decidir. El input ni siquiera se
-- enruta aquí: el InputController manda la pulsación de siempre y el servidor
-- sabe que hay una skill activa.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Knit = require(ReplicatedStorage.Packages.Knit)
local SkillMath = require(ReplicatedStorage.Shared.SkillMath)
local SkillTrajectories = require(ReplicatedStorage.Shared.SkillTrajectories)

local DEBUG_KEY = Enum.KeyCode.F3
local RESULT_HOLD = 1.4

local COLORS = {
	track = Color3.fromRGB(30, 32, 42),
	zone = Color3.fromRGB(70, 220, 110),
	marker = Color3.fromRGB(255, 255, 255),
	ok = Color3.fromRGB(120, 240, 150),
	fail = Color3.fromRGB(245, 100, 100),
}

local SkillController = Knit.CreateController({
	Name = "SkillController",
})

function SkillController:KnitInit()
	self._active = nil
	self._resultToken = 0
end

function SkillController:KnitStart()
	local ComboService = Knit.GetService("ComboService")

	self:_build()

	ComboService.SkillStarted:Connect(function(payload)
		self:_start(payload)
	end)

	ComboService.SkillResult:Connect(function(payload)
		self:_finish(payload)
	end)

	RunService.PreRender:Connect(function()
		self:_update()
	end)

	if RunService:IsStudio() then
		UserInputService.InputBegan:Connect(function(input, processed)
			if not processed and input.KeyCode == DEBUG_KEY then
				ComboService:DebugTriggerSkill()
			end
		end)
	end
end

function SkillController:IsActive(): boolean
	return self._active ~= nil
end

----- Ciclo de la skill -----

function SkillController:_start(payload)
	self._active = payload
	self._resultToken += 1

	-- La zona se coloca una vez: no se mueve durante la skill.
	self._zone.Size = UDim2.fromScale(payload.zoneHalfWidth * 2, 1)
	self._zone.Position = UDim2.fromScale(payload.zoneCenter - payload.zoneHalfWidth, 0)

	self._marker.Position = UDim2.fromScale(0, 0)
	self._track.Visible = true
	self._marker.BackgroundColor3 = COLORS.marker
	self._title.Text = "¡PARA EN LA ZONA!"
	self._title.TextColor3 = COLORS.marker
	self._frame.Visible = true
end

function SkillController:_update()
	local skill = self._active
	if not skill then
		return
	end

	local position = SkillMath.GetPosition(skill.startTime, skill.duration, Workspace:GetServerTimeNow())
	self._marker.Position = UDim2.fromScale(position, 0)
end

function SkillController:_finish(payload)
	self._active = nil

	-- El indicador se congela donde lo paró el SERVIDOR, no donde lo tenía
	-- pintado el cliente. Si hubiera un pelín de desfase por red, se ve la
	-- posición que de verdad se ha juzgado.
	self._marker.Position = UDim2.fromScale(payload.position, 0)
	self._marker.BackgroundColor3 = if payload.ok then COLORS.ok else COLORS.fail

	local hold = RESULT_HOLD

	if payload.ok then
		self:_playEpicPlaceholder(payload)

		-- La barra ya no pinta nada: estorbaría delante del truco. Se
		-- retira al momento y solo se queda el texto del premio, el tiempo
		-- que dure la coreografía del balón.
		self._track.Visible = false
		hold = math.max(SkillTrajectories.GetDuration(payload.trajectory), RESULT_HOLD)
	else
		self._title.Text = "FALLASTE — combo perdido"
		self._title.TextColor3 = COLORS.fail
	end

	-- Se deja un momento en pantalla para que se lea, y luego se recoge.
	self._resultToken += 1
	local token = self._resultToken
	task.delay(hold, function()
		if self._resultToken == token then
			self._frame.Visible = false
		end
	end)
end

-- ============================================================
-- PUNTO DE CONEXIÓN DEL EFECTO ÉPICO
-- ============================================================
-- La "vuelta al mundo" del personaje ya la reproduce el
-- CharacterAnimationController al recibir este mismo resultado. Este texto NO
-- lo sustituye: convive con él, porque es lo que dice cuánto has ganado, que
-- la animación por sí sola no cuenta.
--
-- Lo que falta por enganchar aquí:
--   · partículas / lluvia de monedas,
--   · sacudida de cámara, cámara lenta, destello,
--   · sonido de la celebración.
--
-- Todo lo que hace falta llega en `payload`: `combo` para escalar el
-- espectáculo (a más combo, más bestia, ver MecanicaDeRitmo.md) y `earned`
-- para la lluvia de monedas. No hace falta tocar nada más del sistema.
function SkillController:_playEpicPlaceholder(payload)
	self._title.Text = `⚡ ¡SKILL ÉPICA!  +{payload.earned} 🪙`
	self._title.TextColor3 = COLORS.ok
end

----- Construcción -----

function SkillController:_build()
	local gui = Instance.new("ScreenGui")
	gui.Name = "SkillBar"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 8
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.66)
	frame.Size = UDim2.new(0.62, 0, 0, 76)
	frame.BackgroundTransparency = 1
	frame.Visible = false
	frame.Parent = gui
	self._frame = frame

	local constraint = Instance.new("UISizeConstraint")
	constraint.MaxSize = Vector2.new(620, 76)
	constraint.Parent = frame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 28)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.TextScaled = true
	title.TextStrokeTransparency = 0.4
	title.Text = ""
	title.Parent = frame
	self._title = title

	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, 0, 0, 34)
	track.Position = UDim2.fromOffset(0, 36)
	track.BackgroundColor3 = COLORS.track
	track.BorderSizePixel = 0
	track.Parent = frame
	self._track = track

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(0, 6)
	trackCorner.Parent = track

	local zone = Instance.new("Frame")
	zone.BackgroundColor3 = COLORS.zone
	zone.BorderSizePixel = 0
	zone.Size = UDim2.fromScale(0.2, 1)
	zone.Parent = track
	self._zone = zone

	local zoneCorner = Instance.new("UICorner")
	zoneCorner.CornerRadius = UDim.new(0, 6)
	zoneCorner.Parent = zone

	-- El indicador se ancla por su centro, así que la posición 0..1 que
	-- calcula SkillMath cae justo en el punto medio de la aguja.
	local marker = Instance.new("Frame")
	marker.AnchorPoint = Vector2.new(0.5, 0)
	marker.Size = UDim2.new(0, 5, 1, 0)
	marker.BackgroundColor3 = COLORS.marker
	marker.BorderSizePixel = 0
	marker.ZIndex = 2
	marker.Parent = track
	self._marker = marker
end

return SkillController
