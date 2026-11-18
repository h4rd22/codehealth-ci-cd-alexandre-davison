-- AdminMenu: painel para o dono testar o jogo na mão (nível, ouro, itens, fases, modo deus...).
-- Só aparece no Studio ou para o dono do jogo; o servidor confere de novo cada pedido.
-- Abre e fecha no botão "🛠 ADMIN" ou na tecla F2.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
if not (RunService:IsStudio() or player.UserId == game.CreatorId) then
	return
end

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local evAdmin = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Admin")

local FONTE = Enum.Font.FredokaOne
local FONTE_TEXTO = Enum.Font.GothamMedium
local OURO = Color3.fromRGB(255, 205, 80)
local MADEIRA = Color3.fromRGB(46, 30, 22)
local MADEIRA_CLARA = Color3.fromRGB(86, 56, 36)
local TEXTO = Color3.fromRGB(255, 246, 228)
local POP = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function novo(classe, pai, props)
	local o = Instance.new(classe)
	for k, v in pairs(props or {}) do
		o[k] = v
	end
	o.Parent = pai
	return o
end
local function canto(o, r)
	novo("UICorner", o, { CornerRadius = UDim.new(0, r or 8) })
end
local function contorno(o, cor, esp)
	return novo("UIStroke", o, {
		Color = cor or OURO,
		Thickness = esp or 1.5,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local gui = novo("ScreenGui", player:WaitForChild("PlayerGui"), {
	Name = "AdminMenu",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 40,
})

-- botão que abre o painel
local abrir = novo("TextButton", gui, {
	Name = "AbrirAdmin",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 8),
	Size = UDim2.fromOffset(110, 30),
	BackgroundColor3 = Color3.fromRGB(170, 40, 35),
	Font = FONTE,
	Text = "🛠 ADMIN",
	TextSize = 16,
	TextColor3 = Color3.new(1, 1, 1),
})
canto(abrir, 15)
contorno(abrir, OURO, 2)

local painel = novo("Frame", gui, {
	Name = "PainelAdmin",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 44),
	Size = UDim2.fromOffset(440, 520),
	BackgroundColor3 = MADEIRA,
	Visible = false,
})
canto(painel, 12)
contorno(painel, OURO, 3)
novo("UISizeConstraint", painel, { MaxSize = Vector2.new(440, 9999) })
novo("TextLabel", painel, {
	Size = UDim2.new(1, 0, 0, 34),
	BackgroundColor3 = Color3.fromRGB(170, 40, 35),
	Font = FONTE,
	Text = "🛠 MENU ADMIN (testes)",
	TextSize = 18,
	TextColor3 = Color3.new(1, 1, 1),
})
local resposta = novo("TextLabel", painel, {
	Position = UDim2.fromOffset(10, 38),
	Size = UDim2.new(1, -20, 0, 20),
	BackgroundTransparency = 1,
	Font = FONTE_TEXTO,
	Text = "Escolha uma ação. F2 abre/fecha.",
	TextSize = 13,
	TextColor3 = OURO,
	TextXAlignment = Enum.TextXAlignment.Left,
})
local rolagem = novo("ScrollingFrame", painel, {
	Position = UDim2.fromOffset(8, 62),
	Size = UDim2.new(1, -16, 1, -70),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 6,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
})
novo("UIListLayout", rolagem, { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })

local ordem = 0
local function proximaOrdem()
	ordem += 1
	return ordem
end

local function secao(titulo)
	novo("TextLabel", rolagem, {
		LayoutOrder = proximaOrdem(),
		Size = UDim2.new(1, -8, 0, 20),
		BackgroundTransparency = 1,
		Font = FONTE,
		Text = titulo,
		TextSize = 15,
		TextColor3 = OURO,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local linha = novo("Frame", rolagem, {
		LayoutOrder = proximaOrdem(),
		Size = UDim2.new(1, -8, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	})
	novo("UIGridLayout", linha, {
		CellSize = UDim2.new(0.25, -5, 0, 30),
		CellPadding = UDim2.fromOffset(5, 5),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	return linha
end

local function pedir(acao, a, b)
	resposta.Text = "..."
	task.spawn(function()
		local ok, r = pcall(function()
			return evAdmin:InvokeServer(acao, a, b)
		end)
		resposta.Text = ok and tostring(r) or ("erro: " .. tostring(r))
	end)
end

local function botao(pai, texto, cor, aoClicar)
	local b = novo("TextButton", pai, {
		LayoutOrder = proximaOrdem(),
		BackgroundColor3 = cor or MADEIRA_CLARA,
		Font = FONTE,
		Text = texto,
		TextSize = 13,
		TextScaled = true,
		TextColor3 = TEXTO,
		AutoButtonColor = true,
	})
	novo("UITextSizeConstraint", b, { MaxTextSize = 13 })
	novo("UIPadding", b, { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) })
	canto(b, 7)
	contorno(b, Color3.fromRGB(140, 100, 55), 1)
	local escala = novo("UIScale", b)
	b.Activated:Connect(function()
		escala.Scale = 0.9
		TweenService:Create(escala, POP, { Scale = 1 }):Play()
		aoClicar(b)
	end)
	return b
end

-- Progresso ------------------------------------------------------------
local s = secao("📈 Progresso")
botao(s, "+1 nível", nil, function()
	pedir("subirNivel", 1)
end)
botao(s, "+10 níveis", nil, function()
	pedir("subirNivel", 10)
end)
botao(s, "+1000 XP", nil, function()
	pedir("xp", 1000)
end)
botao(s, "Nível 1", nil, function()
	pedir("nivel", 1)
end)
botao(s, "+1.000 ouro", nil, function()
	pedir("ouro", 1000)
end)
botao(s, "+100.000 ouro", nil, function()
	pedir("ouro", 100000)
end)
botao(s, "Zerar ouro", nil, function()
	pedir("ouro", -1e12)
end)
botao(s, "+20 pergaminhos", Color3.fromRGB(150, 70, 230), function()
	pedir("pergaminhos", 20)
end)
botao(s, "+5 pontos hab.", Color3.fromRGB(110, 60, 170), function()
	pedir("pontos", 5)
end)

-- Fases ----------------------------------------------------------------
s = secao("🗺 Fases")
local faseEscolhida = 1
local rotFase
local function nomeFase()
	local f = Config.Fases[faseEscolhida]
	return string.format("Fase %d-%d", f.mundo or 1, f.numero or faseEscolhida)
end
botao(s, "◀ fase", nil, function()
	faseEscolhida = math.max(1, faseEscolhida - 1)
	rotFase.Text = nomeFase()
end)
rotFase = botao(s, nomeFase(), Color3.fromRGB(60, 40, 30), function()
	pedir("fase", faseEscolhida)
end)
botao(s, "fase ▶", nil, function()
	faseEscolhida = math.min(#Config.Fases, faseEscolhida + 1)
	rotFase.Text = nomeFase()
end)
botao(s, "Ir para fase", Color3.fromRGB(60, 130, 60), function()
	pedir("fase", faseEscolhida)
end)
botao(s, "Liberar todas", nil, function()
	pedir("liberar")
end)
botao(s, "Ir pro chefe", Color3.fromRGB(120, 50, 170), function()
	pedir("fase", #Config.Fases)
end)
botao(s, "Matar horda", Color3.fromRGB(170, 60, 40), function()
	pedir("matarHorda")
end)

-- Combate --------------------------------------------------------------
s = secao("⚔ Combate")
botao(s, "Curar", Color3.fromRGB(60, 130, 60), function()
	pedir("curar")
end)
botao(s, "Modo deus", Color3.fromRGB(200, 160, 40), function()
	pedir("deus")
end)
for _, mult in ipairs({ 1, 10, 100 }) do
	botao(s, "Dano x" .. mult, nil, function()
		pedir("danoX", mult)
	end)
end

-- Itens ----------------------------------------------------------------
s = secao("🎒 Itens")
local raridadeIdx = 5
local rotRar
local function pintarRaridade()
	local r = Config.Raridades[raridadeIdx]
	rotRar.Text = "T" .. raridadeIdx .. " " .. r.nome
	rotRar.BackgroundColor3 = r.cor
	rotRar.TextColor3 = r.corBorda or Color3.new(1, 1, 1)
end
botao(s, "◀ raridade", nil, function()
	raridadeIdx = math.max(1, raridadeIdx - 1)
	pintarRaridade()
end)
rotRar = botao(s, "", nil, function() end)
botao(s, "raridade ▶", nil, function()
	raridadeIdx = math.min(#Config.Raridades, raridadeIdx + 1)
	pintarRaridade()
end)
pintarRaridade()
botao(s, "10 aleatórios", nil, function()
	pedir("itens", 10)
end)
for _, slot in ipairs(Config.Slots) do
	if not slot.especial then
		botao(s, slot.icone .. " " .. slot.nome, Color3.fromRGB(70, 90, 140), function()
			pedir("item", slot.id, raridadeIdx)
		end)
	end
end
botao(s, "10 da raridade", Color3.fromRGB(70, 90, 140), function()
	pedir("itens", 10, raridadeIdx)
end)
for i, c in ipairs(Config.Conjuntos) do
	botao(s, "Conj. " .. (i == 1 and "Vila" or "Katsuki"), c.cor:Lerp(Color3.new(0, 0, 0), 0.4), function()
		pedir("conjunto", i, raridadeIdx)
	end)
end
botao(s, "Vestir melhor", Color3.fromRGB(60, 130, 60), function()
	pedir("vestirMelhor")
end)
botao(s, "Limpar mochila", Color3.fromRGB(150, 50, 40), function()
	pedir("limparMochila")
end)
botao(s, "Ver drop", nil, function()
	pedir("drop", nil, raridadeIdx)
end)

-- Classe e avatares ----------------------------------------------------
s = secao("🎭 Classe e avatares")
for _, c in ipairs(Config.Classes) do
	botao(s, c.icone .. " " .. c.nome, c.cor:Lerp(Color3.new(0, 0, 0), 0.35), function()
		pedir("classe", c.id)
	end)
end
botao(s, "Todos avatares", nil, function()
	task.spawn(function()
		for i = 1, #Config.Fases do
			pedir("avatar", i)
			task.wait(0.15)
		end
	end)
end)

-- Recomeçar ------------------------------------------------------------
s = secao("♻ Recomeçar")
local confirmar = false
botao(s, "Resetar tudo", Color3.fromRGB(170, 40, 35), function(b)
	if not confirmar then
		confirmar = true
		b.Text = "Certeza? Toque de novo"
		task.delay(3, function()
			confirmar = false
			b.Text = "Resetar tudo"
		end)
		return
	end
	confirmar = false
	b.Text = "Resetar tudo"
	pedir("resetar")
end)

-- abrir / fechar ---------------------------------------------------------
local function alternar()
	painel.Visible = not painel.Visible
	if painel.Visible then
		painel.Size = UDim2.fromOffset(440, 0)
		TweenService:Create(painel, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(440, 520) })
			:Play()
	end
end
abrir.Activated:Connect(alternar)
UserInputService.InputBegan:Connect(function(input, processado)
	if not processado and input.KeyCode == Enum.KeyCode.F2 then
		alternar()
	end
end)
