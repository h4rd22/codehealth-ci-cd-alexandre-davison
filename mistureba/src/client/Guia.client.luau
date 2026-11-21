--!strict
-- Guia para quem acabou de entrar e botão de convidar amigos.
-- O guia mostra o próximo passo no alto da tela e uma trilha brilhante até o
-- objetivo (ovo no campo -> sua base -> fusão). Some depois da primeira fusão.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local jogador = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local mapa = workspace:WaitForChild("Mapa")

local FONTE = Enum.Font.FredokaOne

type Estado = {
	criaturas: { [string]: string },
	ovos: { string },
	roubo: string?,
	renascimentos: number,
	baseIndice: number,
	fusoes: number?,
	amigos: number?,
}
local estado: Estado? = nil

------------------------------------------------------------------------
-- Tela
------------------------------------------------------------------------
local tela = Instance.new("ScreenGui")
tela.Name = "Guia"
tela.ResetOnSpawn = false
tela.DisplayOrder = 2
tela.Parent = jogador:WaitForChild("PlayerGui")

local faixa = Instance.new("TextLabel")
faixa.Name = "Passo"
faixa.AnchorPoint = Vector2.new(0.5, 0)
faixa.Position = UDim2.new(0.5, 0, 0, 150)
faixa.Size = UDim2.new(0.55, 0, 0, 40)
faixa.BackgroundColor3 = Color3.fromRGB(35, 30, 60)
faixa.BackgroundTransparency = 0.15
faixa.Font = FONTE
faixa.TextScaled = true
faixa.TextColor3 = Color3.fromRGB(255, 230, 120)
faixa.TextStrokeTransparency = 0.3
faixa.Visible = false
faixa.Parent = tela
local cantos = Instance.new("UICorner")
cantos.CornerRadius = UDim.new(0, 12)
cantos.Parent = faixa
local borda = Instance.new("UIStroke")
borda.Color = Color3.fromRGB(255, 205, 60)
borda.Thickness = 3
borda.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
borda.Parent = faixa
local limite = Instance.new("UITextSizeConstraint")
limite.MaxTextSize = 26
limite.Parent = faixa
local pad = Instance.new("UIPadding")
pad.PaddingLeft = UDim.new(0, 10)
pad.PaddingRight = UDim.new(0, 10)
pad.PaddingTop = UDim.new(0, 4)
pad.PaddingBottom = UDim.new(0, 4)
pad.Parent = faixa

-- faixa pulsando para chamar atenção
task.spawn(function()
	while true do
		local t = TweenService:Create(borda, TweenInfo.new(0.6), { Thickness = 5 })
		t:Play()
		t.Completed:Wait()
		local v = TweenService:Create(borda, TweenInfo.new(0.6), { Thickness = 2 })
		v:Play()
		v.Completed:Wait()
	end
end)

-- Botão de convidar amigos (abaixo do AJUSTES)
local convidar = Instance.new("TextButton")
convidar.Name = "Convidar"
convidar.AnchorPoint = Vector2.new(1, 0)
convidar.Position = UDim2.new(1, -12, 0, 66)
convidar.Size = UDim2.fromOffset(110, 46)
convidar.BackgroundColor3 = Color3.fromRGB(60, 190, 230)
convidar.Font = FONTE
convidar.TextScaled = true
convidar.TextColor3 = Color3.new(1, 1, 1)
convidar.TextStrokeTransparency = 0.3
convidar.Text = "CONVIDAR"
convidar.Parent = tela
local cc = Instance.new("UICorner")
cc.CornerRadius = UDim.new(0, 12)
cc.Parent = convidar
local cb = Instance.new("UIStroke")
cb.Color = Color3.fromRGB(30, 95, 115)
cb.Thickness = 3
cb.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
cb.Parent = convidar
local cp = Instance.new("UIPadding")
cp.PaddingTop = UDim.new(0, 4)
cp.PaddingBottom = UDim.new(0, 4)
cp.PaddingLeft = UDim.new(0, 6)
cp.PaddingRight = UDim.new(0, 6)
cp.Parent = convidar

local dicaAmigos = Instance.new("TextLabel")
dicaAmigos.AnchorPoint = Vector2.new(1, 0)
dicaAmigos.Position = UDim2.new(1, -12, 0, 114)
dicaAmigos.Size = UDim2.fromOffset(150, 22)
dicaAmigos.BackgroundTransparency = 1
dicaAmigos.Font = FONTE
dicaAmigos.TextScaled = true
dicaAmigos.TextXAlignment = Enum.TextXAlignment.Right
dicaAmigos.TextColor3 = Color3.fromRGB(150, 230, 255)
dicaAmigos.TextStrokeTransparency = 0.3
dicaAmigos.Text = "+" .. math.floor(Config.AmigoBonus * 100) .. "% por amigo aqui"
dicaAmigos.Parent = tela

convidar.Activated:Connect(function()
	local ok, pode = pcall(SocialService.CanSendGameInviteAsync, SocialService, jogador)
	if ok and pode then
		pcall(SocialService.PromptGameInvite, SocialService, jogador)
	else
		convidar.Text = "INDISPONÍVEL"
		task.delay(2, function()
			convidar.Text = "CONVIDAR"
		end)
	end
end)

------------------------------------------------------------------------
-- Trilha até o objetivo
------------------------------------------------------------------------
local alvo = Instance.new("Part")
alvo.Name = "AlvoGuia"
alvo.Anchored = true
alvo.CanCollide = false
alvo.CanQuery = false
alvo.CanTouch = false
alvo.Transparency = 1
alvo.Size = Vector3.one
alvo.Parent = workspace
local fim = Instance.new("Attachment")
fim.Parent = alvo

local trilha = Instance.new("Beam")
trilha.Attachment1 = fim
trilha.Color = ColorSequence.new(Color3.fromRGB(255, 230, 90), Color3.fromRGB(255, 140, 60))
trilha.Transparency = NumberSequence.new(0.1, 0.4)
trilha.Width0 = 0.7
trilha.Width1 = 0.7
trilha.FaceCamera = true
trilha.LightEmission = 1
trilha.Texture = "rbxasset://textures/particles/sparkles_main.dds"
trilha.TextureMode = Enum.TextureMode.Static
trilha.TextureLength = 2
trilha.TextureSpeed = 1.5
trilha.Segments = 20
trilha.CurveSize0 = 0
trilha.CurveSize1 = 0
trilha.Enabled = false
trilha.Parent = alvo

local inicio: Attachment? = nil
local function prenderInicio()
	local personagem = jogador.Character
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
	if raiz and (not inicio or inicio.Parent ~= raiz) then
		local a = Instance.new("Attachment")
		a.Name = "GuiaInicio"
		a.Position = Vector3.new(0, -1.5, 0)
		a.Parent = raiz
		inicio = a
		trilha.Attachment0 = a
	end
end

local function ovoMaisPerto(origem: Vector3): Vector3?
	local pasta = workspace:FindFirstChild("Ovos")
	if not pasta then
		return nil
	end
	local melhor, posicao = math.huge, nil
	for _, ovo in pasta:GetChildren() do
		if ovo:IsA("BasePart") then
			local d = (ovo.Position - origem).Magnitude
			if d < melhor then
				melhor, posicao = d, ovo.Position
			end
		end
	end
	return posicao
end

local function contar(t: { [string]: string }): number
	local n = 0
	for _ in t do
		n += 1
	end
	return n
end

local function atualizar()
	local e = estado
	local personagem = jogador.Character
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not e or (e.fusoes or 0) > 0 or e.renascimentos > 0 then
		faixa.Visible = false
		trilha.Enabled = false
		return
	end
	prenderInicio()
	local destino: Vector3? = nil
	if #e.ovos > 0 or e.roubo then
		faixa.Text = "Leve para a SUA BASE! Siga a trilha brilhante"
		local base = mapa:FindFirstChild("Base" .. e.baseIndice)
		local chao = base and base:FindFirstChild("Chao") :: BasePart?
		destino = chao and chao.Position
	elseif contar(e.criaturas) < 3 then
		faixa.Text = "Pegue um OVO que caiu do céu! Siga a trilha brilhante"
		destino = raiz and ovoMaisPerto(raiz.Position)
	else
		faixa.Text = "Abra FUSÃO e junte 2 Misturebas da mesma raridade!"
	end
	faixa.Visible = true
	if destino and raiz then
		alvo.Position = destino + Vector3.new(0, 1, 0)
		trilha.Enabled = true
	else
		trilha.Enabled = false
	end
end

local evEstado = Remotes:WaitForChild("Estado") :: RemoteEvent
evEstado.OnClientEvent:Connect(function(novo: any)
	if type(novo) == "table" then
		estado = novo
		local amigos = tonumber(novo.amigos) or 0
		if amigos > 0 then
			dicaAmigos.Text = string.format("%d amigo(s): +%d%%", amigos, math.floor(amigos * Config.AmigoBonus * 100))
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(0.3)
		atualizar()
	end
end)
