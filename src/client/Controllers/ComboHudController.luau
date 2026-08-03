-- src/client/Controllers/ComboHudController.luau
-- La interfaz: enseña el combo, las monedas y el resultado de cada picadita.
-- Solo PINTA lo que le manda el servidor. Nunca calcula el combo ni las
-- monedas por su cuenta, porque los buenos son los del servidor.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)

local MESSAGE_DURATION = 0.9

local FEEDBACK = {
	Perfect = { text = "¡PERFECTO!", color = Color3.fromRGB(80, 230, 120) },
	Good = { text = "BIEN", color = Color3.fromRGB(240, 210, 80) },
	Miss = { text = "¡FALLO!", color = Color3.fromRGB(240, 90, 90) },
	Escaped = { text = "¡Se te ha escapado la pelota!", color = Color3.fromRGB(240, 90, 90) },
}

local ComboHudController = Knit.CreateController({
	Name = "ComboHudController",
})

function ComboHudController:KnitInit()
	self._comboLabel = nil
	self._feedbackLabel = nil
	self._coinsLabel = nil
	self._speedLabel = nil
	-- Contador para que un mensaje viejo no borre a uno más nuevo al expirar.
	self._messageToken = 0
end

function ComboHudController:KnitStart()
	self:_build()

	local ComboService = Knit.GetService("ComboService")
	local CurrencyService = Knit.GetService("CurrencyService")

	-- Saldo de partida. A partir de aquí llega dentro de cada resultado.
	self:_showCoins(CurrencyService:GetBalance():expect())

	-- Nos suscribimos al canal por el que el servidor empuja los veredictos.
	-- Esto es el tramo servidor → cliente del viaje de ida y vuelta.
	ComboService.PicaditaResult:Connect(function(payload)
		self:_onResult(payload)
	end)

	if self._speedLabel then
		self:_showSpeed(ComboService:GetRhythmState():expect().duration)
	end
end

function ComboHudController:_onResult(payload)
	self._comboLabel.Text = if payload.combo > 0 then tostring(payload.combo) else ""

	if payload.coins then
		self:_showCoins(payload.coins)
	end

	local feedback = FEEDBACK[payload.result]
	if feedback then
		-- Enseñamos lo cobrado pegado al veredicto. Así se ve de un vistazo que
		-- tras un fallo el "+N" se desploma: perder el combo baja el sueldo.
		local text = feedback.text
		if payload.earned and payload.earned > 0 then
			text ..= string.format("   +%d", payload.earned)
		end
		self:_showMessage(text, feedback.color)
	end

	if self._speedLabel and payload.rhythm then
		self:_showSpeed(payload.rhythm.duration)
	end
end

function ComboHudController:_showCoins(amount: number)
	self._coinsLabel.Text = string.format("🪙 %d", amount)
end

function ComboHudController:_showSpeed(duration: number)
	self._speedLabel.Text = string.format("ciclo %.3fs", duration)
end

function ComboHudController:_showMessage(text: string, color: Color3)
	self._messageToken += 1
	local token = self._messageToken

	self._feedbackLabel.Text = text
	self._feedbackLabel.TextColor3 = color

	task.delay(MESSAGE_DURATION, function()
		-- Solo lo borramos si nadie ha escrito un mensaje nuevo mientras tanto.
		if self._messageToken == token then
			self._feedbackLabel.Text = ""
		end
	end)
end

function ComboHudController:_build()
	local gui = Instance.new("ScreenGui")
	gui.Name = "PicaditasHud"
	-- Que no se borre al reaparecer el personaje.
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	local combo = Instance.new("TextLabel")
	combo.Name = "Combo"
	combo.BackgroundTransparency = 1
	-- Escala (0-1 = porcentaje de la pantalla) en vez de píxeles, para que se
	-- vea igual en un móvil que en un monitor grande.
	combo.Size = UDim2.fromScale(1, 0.18)
	combo.Position = UDim2.fromScale(0, 0.08)
	combo.Font = Enum.Font.GothamBlack
	combo.TextScaled = true
	combo.TextColor3 = Color3.fromRGB(255, 255, 255)
	combo.TextStrokeTransparency = 0.4
	combo.Text = ""
	combo.Parent = gui
	self._comboLabel = combo

	local feedback = Instance.new("TextLabel")
	feedback.Name = "Feedback"
	feedback.BackgroundTransparency = 1
	feedback.Size = UDim2.fromScale(1, 0.07)
	feedback.Position = UDim2.fromScale(0, 0.27)
	feedback.Font = Enum.Font.GothamBold
	feedback.TextScaled = true
	feedback.TextStrokeTransparency = 0.5
	feedback.Text = ""
	feedback.Parent = gui
	self._feedbackLabel = feedback

	local coins = Instance.new("TextLabel")
	coins.Name = "Coins"
	coins.BackgroundTransparency = 1
	coins.Size = UDim2.fromScale(0.26, 0.055)
	coins.Position = UDim2.fromScale(0.72, 0.03)
	coins.Font = Enum.Font.GothamBold
	coins.TextScaled = true
	coins.TextXAlignment = Enum.TextXAlignment.Right
	coins.TextColor3 = Color3.fromRGB(255, 214, 90)
	coins.TextStrokeTransparency = 0.4
	coins.Text = "🪙 0"
	coins.Parent = gui
	self._coinsLabel = coins

	-- Lectura de la velocidad actual, solo en Studio: sirve para afinar la
	-- curva de SpeedConfig viendo el número mientras juegas.
	if not RunService:IsStudio() then
		return
	end

	local speed = Instance.new("TextLabel")
	speed.Name = "SpeedDebug"
	speed.BackgroundTransparency = 1
	speed.Size = UDim2.fromScale(0.2, 0.03)
	speed.Position = UDim2.fromScale(0.01, 0.95)
	speed.Font = Enum.Font.Code
	speed.TextScaled = true
	speed.TextXAlignment = Enum.TextXAlignment.Left
	speed.TextColor3 = Color3.fromRGB(170, 170, 170)
	speed.TextStrokeTransparency = 0.6
	speed.Text = ""
	speed.Parent = gui
	self._speedLabel = speed
end

return ComboHudController
