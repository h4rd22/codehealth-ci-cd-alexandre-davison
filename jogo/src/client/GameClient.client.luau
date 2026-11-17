-- GameClient: auto-farm (o herói anda sozinho) e efeitos:
-- números de dano, tremida de tela, explosão, drop de itens com brilho
-- da raridade, avisos de fase/nível e anúncio de lendário.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local evDano = remotes:WaitForChild("Dano")
local evAviso = remotes:WaitForChild("Aviso")
local evLoot = remotes:WaitForChild("Loot")

local player = Players.LocalPlayer
local pasta = workspace:WaitForChild("Monstros")

local function raridade(id)
	for i, r in ipairs(Config.Raridades) do
		if r.id == id then
			return r, i
		end
	end
	return Config.Raridades[1], 1
end

------------------------------------------------------------------------
-- Tela de efeitos (avisos e notificações)
------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "Efeitos"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 3
gui.Parent = player:WaitForChild("PlayerGui")

local faixa = Instance.new("TextLabel")
faixa.AnchorPoint = Vector2.new(0.5, 0.5)
faixa.Position = UDim2.fromScale(0.5, 0.36)
faixa.Size = UDim2.new(0.9, 0, 0, 80)
faixa.BackgroundTransparency = 1
faixa.Font = Enum.Font.GothamBlack
faixa.TextScaled = true
faixa.TextWrapped = true
faixa.TextColor3 = Color3.fromRGB(255, 225, 120)
faixa.TextStrokeColor3 = Color3.fromRGB(70, 35, 130)
faixa.TextTransparency = 1
faixa.TextStrokeTransparency = 1
faixa.Text = ""
faixa.Parent = gui
local lim = Instance.new("UITextSizeConstraint")
lim.MaxTextSize = 48
lim.Parent = faixa
local escala = Instance.new("UIScale")
escala.Parent = faixa

local function mostrarFaixa(msg, cor, tempo)
	faixa.Text = msg
	faixa.TextColor3 = cor or Color3.fromRGB(255, 225, 120)
	escala.Scale = 0.6
	TweenService:Create(escala, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	TweenService:Create(faixa, TweenInfo.new(0.3), { TextTransparency = 0, TextStrokeTransparency = 0 }):Play()
	task.delay(tempo or 2.2, function()
		if faixa.Text == msg then
			TweenService:Create(faixa, TweenInfo.new(0.5), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end

-- Notificações de itens (lado direito)
local pilha = Instance.new("Frame")
pilha.AnchorPoint = Vector2.new(1, 0)
pilha.Position = UDim2.new(1, -14, 0, 144)
pilha.Size = UDim2.fromOffset(240, 300)
pilha.BackgroundTransparency = 1
pilha.Parent = gui
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = pilha
local ordem = 0

local function notificar(texto, cor)
	ordem -= 1
	local f = Instance.new("TextLabel")
	f.LayoutOrder = ordem
	f.Size = UDim2.fromOffset(240, 30)
	f.BackgroundColor3 = Color3.fromRGB(22, 20, 34)
	f.BackgroundTransparency = 0.1
	f.Font = Enum.Font.GothamBold
	f.TextSize = 13
	f.TextColor3 = cor
	f.TextTruncate = Enum.TextTruncate.AtEnd
	f.Text = "  " .. texto
	f.TextXAlignment = Enum.TextXAlignment.Left
	f.Parent = pilha
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = f
	local s = Instance.new("UIStroke")
	s.Color = cor
	s.Thickness = 1.5
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = f
	local fila = {}
	for _, x in ipairs(pilha:GetChildren()) do
		if x:IsA("TextLabel") then
			table.insert(fila, x)
		end
	end
	if #fila > 6 then
		table.sort(fila, function(a, b)
			return a.LayoutOrder > b.LayoutOrder
		end)
		fila[1]:Destroy()
	end
	task.delay(3.5, function()
		if f.Parent then
			TweenService:Create(f, TweenInfo.new(0.4), { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
			TweenService:Create(s, TweenInfo.new(0.4), { Transparency = 1 }):Play()
			Debris:AddItem(f, 0.45)
		end
	end)
end

------------------------------------------------------------------------
-- Efeitos no mundo
------------------------------------------------------------------------
local function textoFlutuante(pos, msg, cor, tamanho)
	local ancora = Instance.new("Part")
	ancora.Anchored = true
	ancora.CanCollide = false
	ancora.CanQuery = false
	ancora.Transparency = 1
	ancora.Size = Vector3.new(0.2, 0.2, 0.2)
	ancora.Position = pos + Vector3.new(math.random(-15, 15) / 10, 3, math.random(-15, 15) / 10)
	ancora.Parent = workspace
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(220, 60)
	bb.AlwaysOnTop = true
	bb.Adornee = ancora
	bb.Parent = ancora
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = msg
	t.TextColor3 = cor
	t.TextSize = tamanho
	t.Font = Enum.Font.GothamBlack
	t.TextStrokeTransparency = 0
	t.TextStrokeColor3 = Color3.fromRGB(30, 20, 40)
	t.Parent = bb
	TweenService:Create(
		ancora,
		TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = ancora.Position + Vector3.new(0, 3, 0) }
	):Play()
	TweenService:Create(
		t,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.35),
		{ TextTransparency = 1, TextStrokeTransparency = 1 }
	):Play()
	Debris:AddItem(ancora, 0.9)
end

local function tremer(forca, duracao)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end
	task.spawn(function()
		local fim = os.clock() + duracao
		while os.clock() < fim do
			hum.CameraOffset = Vector3.new((math.random() - 0.5) * forca, (math.random() - 0.5) * forca, 0)
			task.wait()
		end
		hum.CameraOffset = Vector3.zero
	end)
end

local function explosao(pos, cor, qtd)
	for _ = 1, qtd or 10 do
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.Material = Enum.Material.Neon
		p.Color = cor
		p.Size = Vector3.new(0.6, 0.6, 0.6)
		p.Position = pos
		p.Parent = workspace
		local dir = Vector3.new(math.random() - 0.5, math.random() * 0.8 + 0.2, math.random() - 0.5).Unit
		TweenService:Create(
			p,
			TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Position = pos + dir * (4 + math.random() * 3), Size = Vector3.new(0.05, 0.05, 0.05), Transparency = 1 }
		):Play()
		Debris:AddItem(p, 0.5)
	end
end

-- Coluna de luz da cor da raridade no lugar onde o item caiu
local function feixe(pos, cor, forte)
	local altura = forte and 40 or 14
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Material = Enum.Material.Neon
	p.Color = cor
	p.Transparency = 0.25
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(altura, forte and 2 or 1, forte and 2 or 1)
	p.CFrame = CFrame.new(pos.X, pos.Y - 1 + altura / 2, pos.Z) * CFrame.Angles(0, 0, math.rad(90))
	p.Parent = workspace
	TweenService
		:Create(p, TweenInfo.new(forte and 2.2 or 1.2), { Transparency = 1, Size = Vector3.new(altura, 0.1, 0.1) })
		:Play()
	Debris:AddItem(p, forte and 2.3 or 1.3)
end

evDano.OnClientEvent:Connect(function(tipo, pos, valor, extra, xp)
	if tipo == "dano" then
		if extra then
			textoFlutuante(pos, "CRÍTICO! " .. valor, Color3.fromRGB(255, 220, 60), 34)
			tremer(0.6, 0.15)
		else
			textoFlutuante(pos, tostring(valor), Color3.new(1, 1, 1), 24)
		end
	elseif tipo == "morte" then
		explosao(pos, extra)
		textoFlutuante(pos + Vector3.new(0, 1, 0), "+" .. valor .. " ouro", Color3.fromRGB(255, 205, 70), 22)
		if xp then
			textoFlutuante(pos + Vector3.new(0, 2.5, 0), "+" .. xp .. " XP", Color3.fromRGB(80, 220, 170), 18)
		end
	end
end)

evLoot.OnClientEvent:Connect(function(tipo, pos, item, ouro)
	local r, ri = raridade(item.raridade)
	if tipo == "cheio" then
		notificar("Mochila cheia: " .. item.nome .. " virou " .. ouro .. " ouro", Color3.fromRGB(255, 205, 70))
		return
	end
	if pos then
		feixe(pos, r.cor, ri >= 4)
		textoFlutuante(pos + Vector3.new(0, 4, 0), item.nome, r.cor, ri >= 4 and 26 or 18)
	end
	if tipo == "forja" then
		notificar("🔨 Forjou: " .. item.nome .. " (" .. r.nome .. ")", r.cor)
		mostrarFaixa("FORJADO: " .. string.upper(r.nome) .. "!", r.cor, 1.6)
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root then
			explosao(root.Position, r.cor, 16)
		end
	else
		notificar(item.nome .. " (" .. r.nome .. ")", r.cor)
	end
	if ri >= 5 then
		tremer(1.2, 0.5)
	elseif ri >= 4 then
		tremer(0.6, 0.25)
	end
end)

evAviso.OnClientEvent:Connect(function(tipo, a, b)
	if tipo == "fase" then
		mostrarFaixa("FASE " .. a .. "!")
		tremer(0.8, 0.3)
	elseif tipo == "nivel" then
		mostrarFaixa("NÍVEL " .. a .. "!", Color3.fromRGB(80, 230, 180))
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root then
			explosao(root.Position, Color3.fromRGB(80, 230, 180), 18)
		end
	elseif tipo == "completo" then
		mostrarFaixa("TESTE COMPLETO! Você passou da " .. a)
	elseif tipo == "lendario" then
		mostrarFaixa(a .. " achou um item LENDÁRIO: " .. b .. "!", Color3.fromRGB(255, 160, 40), 3.5)
	end
end)

------------------------------------------------------------------------
-- Auto-farm: o herói anda sozinho até o monstro mais perto
------------------------------------------------------------------------
local alcance = Config.Heroi.Alcance
local estavaLigado = true

task.spawn(function()
	while true do
		task.wait(0.2)
		local ligado = player:GetAttribute("AutoFarm") ~= false
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if hum and root and hum.Health > 0 then
			if ligado then
				local alvo, menor = nil, math.huge
				for _, m in ipairs(pasta:GetChildren()) do
					if
						m:GetAttribute("Dono") == player.UserId
						and (m:GetAttribute("Vida") or 0) > 0
						and m.PrimaryPart
					then
						local d = (m.PrimaryPart.Position - root.Position).Magnitude
						if d < menor then
							alvo, menor = m, d
						end
					end
				end
				if alvo then
					local pos = alvo.PrimaryPart.Position
					local plano = Vector3.new(pos.X, root.Position.Y, pos.Z)
					if (plano - root.Position).Magnitude > alcance - 2.5 then
						hum:MoveTo(plano)
					else
						hum:MoveTo(root.Position)
						root.CFrame = CFrame.lookAt(root.Position, plano)
					end
				end
			elseif estavaLigado then
				hum:MoveTo(root.Position) -- acabou de desligar: para de andar
			end
		end
		estavaLigado = ligado
	end
end)
