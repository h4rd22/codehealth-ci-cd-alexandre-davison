--!strict
-- Ajustes que só valem para quem está jogando:
-- - o dono passa pela própria porta trancada (os outros batem nela);
-- - o botão "Roubar" não aparece nas suas próprias Misturebas;
-- - o botão "Trancar" só aparece na sua base;
-- - as Misturebas das bases ficam pulando de leve (só na tela, não pesa no servidor);
-- - na sua base sobem numerozinhos "+moedas" a cada segundo.
-- O servidor confere tudo de novo, isto é só para a tela ficar certa.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Util = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Util"))

local jogador = Players.LocalPlayer
local mapa = workspace:WaitForChild("Mapa")

-- modelo -> posição original e um atraso para cada uma pular num ritmo diferente
local animadas: { [Model]: { origem: CFrame, fase: number } } = setmetatable({}, { __mode = "k" }) :: any

local function ajustar()
	for _, obj in mapa:GetDescendants() do
		if obj:IsA("ProximityPrompt") then
			local dono = obj:GetAttribute("Dono")
			if obj.Name == "Roubar" then
				obj.Enabled = dono ~= jogador.UserId
			elseif obj.Name == "Cadeado" then
				obj.Enabled = dono == jogador.UserId
			end
		elseif obj:IsA("BasePart") and obj.Name == "Porta" then
			if obj:GetAttribute("Dono") == jogador.UserId then
				obj.CanCollide = false
				obj.LocalTransparencyModifier = 0.5
			end
		elseif obj:IsA("Model") and obj:GetAttribute("Criatura") and not animadas[obj] then
			animadas[obj] = { origem = obj:GetPivot(), fase = math.random() * math.pi * 2 }
		end
	end
end

RunService.RenderStepped:Connect(function()
	local t = os.clock()
	for modelo, info in animadas do
		if modelo.Parent then
			local pulo = math.abs(math.sin(t * 2.2 + info.fase)) * 0.6
			local giro = math.sin(t * 0.8 + info.fase) * 0.25
			modelo:PivotTo(info.origem * CFrame.new(0, pulo, 0) * CFrame.Angles(0, giro, 0))
		end
	end
end)

-- "+123" subindo de uma Mistureba aleatória da sua base
local minhaBase: number? = nil
local rendaAtual = 0
local estadoRemoto = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Estado") :: RemoteEvent
estadoRemoto.OnClientEvent:Connect(function(estado: any)
	if type(estado) == "table" then
		minhaBase = estado.baseIndice
		rendaAtual = tonumber(estado.renda) or 0
	end
end)

local function numeroSubindo()
	if not minhaBase or rendaAtual <= 0 then
		return
	end
	local base = mapa:FindFirstChild("Base" .. minhaBase)
	if not base then
		return
	end
	local corpos = {}
	for _, obj in base:GetChildren() do
		if obj:IsA("Model") and obj:GetAttribute("Criatura") and obj.PrimaryPart then
			table.insert(corpos, obj.PrimaryPart)
		end
	end
	if #corpos == 0 then
		return
	end
	local alvo = corpos[math.random(1, #corpos)]
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(6, 2)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
	gui.LightInfluence = 0
	gui.AlwaysOnTop = true
	gui.MaxDistance = 90
	local rotulo = Instance.new("TextLabel")
	rotulo.Size = UDim2.fromScale(1, 1)
	rotulo.BackgroundTransparency = 1
	rotulo.Font = Enum.Font.FredokaOne
	rotulo.TextScaled = true
	rotulo.TextColor3 = Color3.fromRGB(255, 230, 80)
	rotulo.TextStrokeTransparency = 0
	rotulo.Text = "+" .. Util.numero(math.floor(rendaAtual))
	rotulo.Parent = gui
	gui.Adornee = alvo
	gui.Parent = jogador:WaitForChild("PlayerGui")
	local info = TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(gui, info, { StudsOffsetWorldSpace = Vector3.new(0, 9, 0) }):Play()
	TweenService:Create(rotulo, info, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(1.2, function()
		gui:Destroy()
	end)
end

task.spawn(function()
	while true do
		task.wait(1)
		numeroSubindo()
	end
end)

while true do
	ajustar()
	task.wait(0.4)
end
