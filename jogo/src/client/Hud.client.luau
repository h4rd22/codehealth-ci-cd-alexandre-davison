-- Hud: tudo o que aparece na tela.
-- Nível e XP, ouro, portal de fases, menu lateral (Mochila, Forja,
-- Habilidades, Ovos), inventário com equipamentos e botão de auto-farm.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local R = function(n)
	return remotes:WaitForChild(n)
end
local evEstado, evPedirEstado = R("Estado"), R("PedirEstado")
local evAutoFarm, evEquipar, evDesequipar = R("AutoFarm"), R("Equipar"), R("Desequipar")
local evVender, evForjar, evIrFase = R("Vender"), R("Forjar"), R("IrFase")

local player = Players.LocalPlayer
pcall(function()
	game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
	game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)
-- A janela do chat ficava em cima do cartão do herói; no teste ela fica escondida.
pcall(function()
	game:GetService("TextChatService"):WaitForChild("ChatWindowConfiguration", 5).Enabled = false
end)

------------------------------------------------------------------------
-- Cores e ajudantes
------------------------------------------------------------------------
local COR = {
	painel = Color3.fromRGB(22, 20, 34),
	painel2 = Color3.fromRGB(34, 31, 52),
	borda = Color3.fromRGB(70, 62, 110),
	roxo = Color3.fromRGB(150, 120, 255),
	ouro = Color3.fromRGB(255, 205, 70),
	xp = Color3.fromRGB(80, 220, 170),
	texto = Color3.fromRGB(240, 238, 250),
	fraco = Color3.fromRGB(165, 160, 190),
	verde = Color3.fromRGB(60, 185, 95),
	cinza = Color3.fromRGB(85, 85, 98),
	vermelho = Color3.fromRGB(235, 70, 70),
}

local function novo(classe, pai, props)
	local o = Instance.new(classe)
	for k, v in pairs(props or {}) do
		o[k] = v
	end
	o.Parent = pai
	return o
end
local function canto(o, r)
	return novo("UICorner", o, { CornerRadius = UDim.new(0, r or 10) })
end
local function contorno(o, cor, esp)
	return novo(
		"UIStroke",
		o,
		{ Color = cor or COR.borda, Thickness = esp or 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }
	)
end
local function caixa(pai, props)
	local f = novo("Frame", pai, { BackgroundColor3 = COR.painel, BackgroundTransparency = 0.08, BorderSizePixel = 0 })
	for k, v in pairs(props or {}) do
		f[k] = v
	end
	return f
end
local function rotulo(pai, props)
	local t = novo(
		"TextLabel",
		pai,
		{ BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextColor3 = COR.texto, TextSize = 14 }
	)
	for k, v in pairs(props or {}) do
		t[k] = v
	end
	return t
end
local function botao(pai, props)
	local b = novo("TextButton", pai, {
		Font = Enum.Font.GothamBold,
		TextColor3 = COR.texto,
		TextSize = 14,
		BorderSizePixel = 0,
		AutoButtonColor = true,
		BackgroundColor3 = COR.painel2,
	})
	for k, v in pairs(props or {}) do
		b[k] = v
	end
	canto(b, 8)
	return b
end
local function barra(pai, props, cor)
	local fundo = novo("Frame", pai, { BackgroundColor3 = Color3.fromRGB(45, 40, 65), BorderSizePixel = 0 })
	for k, v in pairs(props or {}) do
		fundo[k] = v
	end
	canto(fundo, 8)
	local cheio = novo("Frame", fundo, { Size = UDim2.fromScale(0, 1), BackgroundColor3 = cor, BorderSizePixel = 0 })
	canto(cheio, 8)
	local txt = rotulo(fundo, { Size = UDim2.fromScale(1, 1), TextSize = 12, ZIndex = 3 })
	return fundo, cheio, txt
end
local function bolinha(pai)
	local b = novo("Frame", pai, {
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.new(1, -10, 0, -4),
		BackgroundColor3 = COR.vermelho,
		Visible = false,
		ZIndex = 5,
	})
	canto(b, 7)
	contorno(b, Color3.new(1, 1, 1), 1.5)
	return b
end

local function raridade(id)
	for i, r in ipairs(Config.Raridades) do
		if r.id == id then
			return r, i
		end
	end
	return Config.Raridades[1], 1
end
local function slotInfo(id)
	for _, s in ipairs(Config.Slots) do
		if s.id == id then
			return s
		end
	end
end
local function textoValor(atributo, v)
	if atributo == "critico" then
		return string.format("+%.1f%% de crítico", v * 100)
	elseif atributo == "ouro" then
		return string.format("+%.0f%% de ouro", v * 100)
	elseif atributo == "velocidade" then
		return string.format("+%d de velocidade", v)
	else
		return string.format("+%d de dano", v)
	end
end
local function textoItem(item)
	local s = slotInfo(item.slot)
	return textoValor(s.atributo, item.valor)
end

------------------------------------------------------------------------
-- Telas
------------------------------------------------------------------------
local gui = novo(
	"ScreenGui",
	player:WaitForChild("PlayerGui"),
	{ Name = "Hud", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 1 }
)
local guiJanelas = novo(
	"ScreenGui",
	player.PlayerGui,
	{ Name = "Janelas", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 5 }
)

local estado = nil
local autoFarm = true
player:SetAttribute("AutoFarm", true)

------------------------------------------------------------------------
-- Cartão do herói (canto esquerdo de cima): nível, XP e ouro
------------------------------------------------------------------------
local cartao = caixa(gui, { Position = UDim2.fromOffset(14, 62), Size = UDim2.new(0.42, 0, 0, 70) })
novo("UISizeConstraint", cartao, { MaxSize = Vector2.new(290, 70) })
canto(cartao, 14)
contorno(cartao, COR.roxo, 2)

local nivelBola = novo(
	"Frame",
	cartao,
	{ Position = UDim2.fromOffset(8, 7), Size = UDim2.fromOffset(56, 56), BackgroundColor3 = Color3.new(1, 1, 1) }
)
canto(nivelBola, 28)
novo(
	"UIGradient",
	nivelBola,
	{ Rotation = 45, Color = ColorSequence.new(Color3.fromRGB(170, 120, 255), Color3.fromRGB(80, 60, 200)) }
)
contorno(nivelBola, Color3.fromRGB(230, 220, 255), 2)
rotulo(nivelBola, {
	Position = UDim2.fromOffset(0, 7),
	Size = UDim2.new(1, 0, 0, 12),
	Text = "NÍVEL",
	TextSize = 10,
	TextColor3 = Color3.fromRGB(230, 225, 255),
})
local lblNivel = rotulo(nivelBola, {
	Position = UDim2.fromOffset(0, 18),
	Size = UDim2.new(1, 0, 0, 30),
	Text = "1",
	TextSize = 26,
	Font = Enum.Font.GothamBlack,
})

rotulo(cartao, {
	Position = UDim2.fromOffset(74, 8),
	Size = UDim2.new(1, -84, 0, 18),
	Text = player.DisplayName,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextSize = 15,
	TextTruncate = Enum.TextTruncate.AtEnd,
})
local _, xpCheio, xpTxt =
	barra(cartao, { Position = UDim2.fromOffset(74, 32), Size = UDim2.new(1, -84, 0, 16) }, COR.xp)
local lblPoder = rotulo(cartao, {
	Position = UDim2.fromOffset(74, 50),
	Size = UDim2.new(1, -84, 0, 14),
	Text = "",
	TextSize = 11,
	Font = Enum.Font.Gotham,
	TextColor3 = COR.fraco,
	TextXAlignment = Enum.TextXAlignment.Left,
})

local caixaOuro = caixa(gui, { Position = UDim2.fromOffset(14, 140), Size = UDim2.fromOffset(150, 38) })
canto(caixaOuro, 19)
contorno(caixaOuro, Color3.fromRGB(150, 115, 30), 2)
local moeda = novo("Frame", caixaOuro, {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromOffset(20, 19),
	Size = UDim2.fromOffset(22, 22),
	BackgroundColor3 = COR.ouro,
})
canto(moeda, 11)
contorno(moeda, Color3.fromRGB(190, 130, 20), 2)
rotulo(moeda, {
	Size = UDim2.fromScale(1, 1),
	Text = "$",
	TextSize = 13,
	Font = Enum.Font.GothamBlack,
	TextColor3 = Color3.fromRGB(150, 95, 10),
})
local lblOuro = rotulo(caixaOuro, {
	Position = UDim2.fromOffset(38, 0),
	Size = UDim2.new(1, -46, 1, 0),
	Text = "0",
	TextSize = 18,
	Font = Enum.Font.GothamBlack,
	TextColor3 = COR.ouro,
	TextXAlignment = Enum.TextXAlignment.Left,
})

------------------------------------------------------------------------
-- Portal (canto direito de cima): fase atual + botão que abre os mundos
------------------------------------------------------------------------
local painelFase = novo("TextButton", gui, {
	Name = "PainelFase",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -14, 0, 62),
	Size = UDim2.new(0.5, 0, 0, 70),
	BackgroundColor3 = COR.painel,
	BackgroundTransparency = 0.08,
	BorderSizePixel = 0,
	Text = "",
	AutoButtonColor = false,
})
novo("UISizeConstraint", painelFase, { MaxSize = Vector2.new(300, 70) })
canto(painelFase, 14)
contorno(painelFase, COR.roxo, 2)

-- Ícone do portal: um redemoinho que gira
local portal = novo(
	"Frame",
	painelFase,
	{ Position = UDim2.fromOffset(7, 7), Size = UDim2.fromOffset(56, 56), BackgroundColor3 = Color3.new(1, 1, 1) }
)
canto(portal, 28)
local giro = novo("UIGradient", portal, {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 60, 255)),
		ColorSequenceKeypoint.new(0.35, Color3.fromRGB(60, 200, 255)),
		ColorSequenceKeypoint.new(0.7, Color3.fromRGB(210, 80, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 60, 255)),
	}),
})
contorno(portal, Color3.fromRGB(200, 180, 255), 2)
local miolo = novo("Frame", portal, {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(30, 30),
	BackgroundColor3 = Color3.fromRGB(15, 10, 35),
})
canto(miolo, 15)
local brilhoMiolo = novo("UIStroke", miolo, { Color = Color3.fromRGB(180, 230, 255), Thickness = 2 })
local miolo2 = novo("Frame", miolo, {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(12, 12),
	BackgroundColor3 = Color3.fromRGB(200, 170, 255),
})
canto(miolo2, 6)
local t0 = os.clock()
RunService.RenderStepped:Connect(function()
	local t = os.clock() - t0
	giro.Rotation = (t * 120) % 360
	brilhoMiolo.Transparency = 0.3 + 0.3 * math.sin(t * 3)
	local s = 12 + 3 * math.sin(t * 4)
	miolo2.Size = UDim2.fromOffset(s, s)
end)

local lblMundo = rotulo(painelFase, {
	Position = UDim2.fromOffset(72, 6),
	Size = UDim2.new(1, -80, 0, 14),
	TextSize = 11,
	Font = Enum.Font.Gotham,
	TextColor3 = COR.fraco,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "Mundo 1",
})
local lblFase = rotulo(painelFase, {
	Position = UDim2.fromOffset(72, 20),
	Size = UDim2.new(1, -80, 0, 22),
	TextSize = 19,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "Fase 1-1",
})
local _, killCheio, killTxt =
	barra(painelFase, { Position = UDim2.fromOffset(72, 46), Size = UDim2.new(1, -82, 0, 15) }, COR.roxo)

------------------------------------------------------------------------
-- Menu lateral
------------------------------------------------------------------------
local menu = novo("Frame", gui, {
	Name = "MenuLateral",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 14, 0.55, 0),
	Size = UDim2.fromOffset(70, 4 * 78),
	BackgroundTransparency = 1,
})
novo("UIListLayout", menu, { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })

local botoesMenu, bolinhas = {}, {}
local function botaoMenu(ordem, id, icone, nome, corFundo)
	local b = novo("TextButton", menu, {
		Name = "Menu_" .. id,
		LayoutOrder = ordem,
		Size = UDim2.fromOffset(70, 70),
		BackgroundColor3 = corFundo,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = true,
	})
	canto(b, 16)
	contorno(b, Color3.fromRGB(255, 255, 255), 2).Transparency = 0.6
	novo(
		"UIGradient",
		b,
		{ Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(170, 170, 170)) }
	)
	rotulo(b, {
		Position = UDim2.fromOffset(0, 6),
		Size = UDim2.new(1, 0, 0, 36),
		Text = icone,
		TextSize = 30,
		Font = Enum.Font.GothamBold,
	})
	rotulo(b, {
		Position = UDim2.new(0, 0, 1, -24),
		Size = UDim2.new(1, 0, 0, 18),
		Text = nome,
		TextSize = 12,
		Font = Enum.Font.GothamBlack,
		TextStrokeTransparency = 0.5,
	})
	bolinhas[id] = bolinha(b)
	botoesMenu[id] = b
	return b
end
botaoMenu(1, "mochila", "🎒", "Mochila", Color3.fromRGB(70, 120, 230))
botaoMenu(2, "forja", "🔨", "Forja", Color3.fromRGB(215, 110, 45))
botaoMenu(3, "habilidades", "✨", "Habilid.", Color3.fromRGB(140, 80, 220))
botaoMenu(4, "ovos", "🥚", "Ovos", Color3.fromRGB(60, 170, 120))

------------------------------------------------------------------------
-- Botão de auto-farm
------------------------------------------------------------------------
local btnAuto = botao(gui, {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -22),
	Size = UDim2.fromOffset(220, 50),
	TextSize = 17,
	Font = Enum.Font.GothamBlack,
})
canto(btnAuto, 14)
contorno(btnAuto, Color3.new(1, 1, 1), 2).Transparency = 0.6
local function pintarAuto()
	btnAuto.Text = autoFarm and "AUTO-FARM: LIGADO" or "AUTO-FARM: DESLIGADO"
	btnAuto.BackgroundColor3 = autoFarm and COR.verde or COR.cinza
end
pintarAuto()
btnAuto.Activated:Connect(function()
	autoFarm = not autoFarm
	player:SetAttribute("AutoFarm", autoFarm)
	evAutoFarm:FireServer(autoFarm)
	pintarAuto()
end)

------------------------------------------------------------------------
-- Janela genérica
------------------------------------------------------------------------
local fundoEscuro = novo("TextButton", guiJanelas, {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0.45,
	Text = "",
	AutoButtonColor = false,
	Visible = false,
})

local function criarJanela(titulo)
	local j = caixa(guiJanelas, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.fromScale(0.94, 0.8),
		Visible = false,
		BackgroundTransparency = 0.02,
	})
	novo("UISizeConstraint", j, { MaxSize = Vector2.new(760, 480) })
	canto(j, 18)
	contorno(j, COR.roxo, 2.5)
	local topo =
		novo("Frame", j, { Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = COR.painel2, BorderSizePixel = 0 })
	canto(topo, 18)
	novo("Frame", topo, {
		Position = UDim2.new(0, 0, 1, -12),
		Size = UDim2.new(1, 0, 0, 12),
		BackgroundColor3 = COR.painel2,
		BorderSizePixel = 0,
	})
	local lbl = rotulo(topo, {
		Position = UDim2.fromOffset(16, 0),
		Size = UDim2.new(0, 160, 1, 0),
		Text = titulo,
		TextSize = 18,
		Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local fechar = botao(topo, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(32, 32),
		Text = "X",
		BackgroundColor3 = COR.vermelho,
		Font = Enum.Font.GothamBlack,
	})
	local corpo = novo(
		"Frame",
		j,
		{ Position = UDim2.fromOffset(12, 56), Size = UDim2.new(1, -24, 1, -68), BackgroundTransparency = 1 }
	)
	return j, corpo, topo, fechar, lbl
end

local janelaAberta = nil
local function fecharJanelas()
	if janelaAberta then
		janelaAberta.Visible = false
	end
	janelaAberta = nil
	fundoEscuro.Visible = false
end
local function abrirJanela(j)
	if janelaAberta and janelaAberta ~= j then
		janelaAberta.Visible = false
	end
	janelaAberta = j
	fundoEscuro.Visible = true
	j.Visible = true
	local esc = j:FindFirstChildOfClass("UIScale") or novo("UIScale", j)
	esc.Scale = 0.9
	TweenService:Create(esc, TweenInfo.new(0.18, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end
fundoEscuro.Activated:Connect(fecharJanelas)

------------------------------------------------------------------------
-- Janela do menu: abas Mochila / Forja / Habilidades / Ovos
------------------------------------------------------------------------
local jMenu, corpoMenu, topoMenu, fecharMenu, lblTituloMenu = criarJanela("Menu")
fecharMenu.Activated:Connect(fecharJanelas)
lblTituloMenu.Visible = false

local abas = novo(
	"Frame",
	topoMenu,
	{ Position = UDim2.fromOffset(10, 7), Size = UDim2.new(1, -60, 0, 32), BackgroundTransparency = 1 }
)
novo(
	"UIListLayout",
	abas,
	{ FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }
)

local paginas, botoesAba = {}, {}
local abaAtual = "mochila"
local function criarAba(ordem, id, texto)
	local b = botao(abas, {
		Name = "Aba_" .. id,
		LayoutOrder = ordem,
		Size = UDim2.new(0.24, -5, 1, 0),
		Text = texto,
		TextSize = 13,
		TextScaled = false,
	})
	botoesAba[id] = b
	local p = novo("Frame", corpoMenu, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false })
	paginas[id] = p
	return p
end
local pgMochila = criarAba(1, "mochila", "🎒 Mochila")
local pgForja = criarAba(2, "forja", "🔨 Forja")
local pgHab = criarAba(3, "habilidades", "✨ Habilid.")
local pgOvos = criarAba(4, "ovos", "🥚 Ovos")

local desenhar -- definida mais abaixo
local function mostrarAba(id)
	abaAtual = id
	for k, p in pairs(paginas) do
		p.Visible = (k == id)
	end
	for k, b in pairs(botoesAba) do
		b.BackgroundColor3 = (k == id) and COR.roxo or COR.painel
	end
	if id == "mochila" then
		bolinhas.mochila.Visible = false
	end
	if desenhar then
		desenhar()
	end
end
for id, b in pairs(botoesAba) do
	b.Activated:Connect(function()
		mostrarAba(id)
	end)
end
for id, b in pairs(botoesMenu) do
	b.Activated:Connect(function()
		abrirJanela(jMenu)
		mostrarAba(id)
	end)
end

------------------------------------------------------------------------
-- Aba Mochila: equipamentos vestidos + inventário
------------------------------------------------------------------------
local colEquip =
	novo("Frame", pgMochila, { Size = UDim2.new(0.36, -6, 1, 0), BackgroundColor3 = COR.painel2, BorderSizePixel = 0 })
canto(colEquip, 12)
rotulo(colEquip, {
	Position = UDim2.fromOffset(10, 6),
	Size = UDim2.new(1, -20, 0, 20),
	Text = "Vestindo",
	TextXAlignment = Enum.TextXAlignment.Left,
	TextSize = 14,
	Font = Enum.Font.GothamBlack,
})
local listaSlots = novo(
	"Frame",
	colEquip,
	{ Position = UDim2.fromOffset(8, 30), Size = UDim2.new(1, -16, 0, 4 * 52), BackgroundTransparency = 1 }
)
novo("UIListLayout", listaSlots, { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder })

local slotUI = {}
for i, s in ipairs(Config.Slots) do
	local linha = novo("TextButton", listaSlots, {
		LayoutOrder = i,
		Size = UDim2.new(1, 0, 0, 48),
		BackgroundColor3 = COR.painel,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = true,
	})
	canto(linha, 10)
	local ic = novo("Frame", linha, {
		Position = UDim2.fromOffset(4, 4),
		Size = UDim2.fromOffset(40, 40),
		BackgroundColor3 = Color3.fromRGB(50, 46, 70),
	})
	canto(ic, 8)
	local icStroke = contorno(ic, COR.cinza, 2)
	rotulo(ic, { Size = UDim2.fromScale(1, 1), Text = s.icone, TextSize = 22 })
	local nome = rotulo(linha, {
		Position = UDim2.fromOffset(52, 5),
		Size = UDim2.new(1, -56, 0, 18),
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = s.nome .. ": vazio",
		TextColor3 = COR.fraco,
	})
	local stat = rotulo(linha, {
		Position = UDim2.fromOffset(52, 24),
		Size = UDim2.new(1, -56, 0, 16),
		TextSize = 11,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "",
		TextColor3 = COR.fraco,
	})
	slotUI[s.id] = { linha = linha, stroke = icStroke, nome = nome, stat = stat }
end

local lblStats = rotulo(colEquip, {
	Position = UDim2.fromOffset(10, 30 + 4 * 52 + 6),
	Size = UDim2.new(1, -20, 1, -(30 + 4 * 52 + 12)),
	TextSize = 12,
	Font = Enum.Font.Gotham,
	TextColor3 = COR.texto,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextWrapped = true,
	RichText = true,
	Text = "",
})

local colInv = novo(
	"Frame",
	pgMochila,
	{ Position = UDim2.new(0.36, 6, 0, 0), Size = UDim2.new(0.64, -6, 1, 0), BackgroundTransparency = 1 }
)
local lblInv = rotulo(colInv, {
	Size = UDim2.new(1, 0, 0, 20),
	Text = "Mochila 0/" .. Config.LimiteInventario,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextSize = 14,
	Font = Enum.Font.GothamBlack,
})
local grade = novo("ScrollingFrame", colInv, {
	Position = UDim2.fromOffset(0, 24),
	Size = UDim2.new(1, 0, 1, -24 - 76),
	BackgroundColor3 = COR.painel2,
	BorderSizePixel = 0,
	ScrollBarThickness = 6,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollingDirection = Enum.ScrollingDirection.Y,
})
canto(grade, 12)
novo("UIPadding", grade, {
	PaddingTop = UDim.new(0, 8),
	PaddingLeft = UDim.new(0, 8),
	PaddingRight = UDim.new(0, 8),
	PaddingBottom = UDim.new(0, 8),
})
novo("UIGridLayout", grade, {
	CellSize = UDim2.fromOffset(58, 58),
	CellPadding = UDim2.fromOffset(6, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
})

local detalhe = novo("Frame", colInv, {
	Position = UDim2.new(0, 0, 1, -70),
	Size = UDim2.new(1, 0, 0, 70),
	BackgroundColor3 = COR.painel2,
	BorderSizePixel = 0,
})
canto(detalhe, 12)
local detNome = rotulo(detalhe, {
	Position = UDim2.fromOffset(10, 6),
	Size = UDim2.new(1, -150, 0, 20),
	TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextTruncate = Enum.TextTruncate.AtEnd,
	Text = "Toque num item",
})
local detStat = rotulo(detalhe, {
	Position = UDim2.fromOffset(10, 28),
	Size = UDim2.new(1, -150, 0, 36),
	TextSize = 12,
	Font = Enum.Font.Gotham,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextWrapped = true,
	RichText = true,
	TextColor3 = COR.fraco,
	Text = "para ver os atributos.",
})
local btnEquipar = botao(detalhe, {
	Name = "BtnVestir",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -8, 0, 6),
	Size = UDim2.fromOffset(130, 27),
	Text = "Vestir",
	BackgroundColor3 = COR.verde,
	Visible = false,
})
local btnVender = botao(detalhe, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -8, 0, 37),
	Size = UDim2.fromOffset(130, 27),
	Text = "Vender",
	BackgroundColor3 = Color3.fromRGB(160, 120, 40),
	Visible = false,
})

local selecionado = nil -- id do item ou "slot:<id>"

local function itemPorId(id)
	if not estado then
		return nil
	end
	for _, it in ipairs(estado.inventario) do
		if it.id == id then
			return it
		end
	end
end
local function vestido(id)
	if not estado then
		return false
	end
	for _, eid in pairs(estado.equipado) do
		if eid == id then
			return true
		end
	end
	return false
end

btnEquipar.Activated:Connect(function()
	if type(selecionado) == "number" then
		if vestido(selecionado) then
			local it = itemPorId(selecionado)
			if it then
				evDesequipar:FireServer(it.slot)
			end
		else
			evEquipar:FireServer(selecionado)
		end
	end
end)
btnVender.Activated:Connect(function()
	if type(selecionado) == "number" and not vestido(selecionado) then
		evVender:FireServer(selecionado)
		selecionado = nil
	end
end)

local function desenharDetalhe()
	local it = type(selecionado) == "number" and itemPorId(selecionado) or nil
	if not it then
		detNome.Text = "Toque num item"
		detNome.TextColor3 = COR.texto
		detStat.Text = "para ver os atributos."
		btnEquipar.Visible, btnVender.Visible = false, false
		return
	end
	local r = raridade(it.raridade)
	local s = slotInfo(it.slot)
	detNome.Text = s.icone .. " " .. it.nome
	detNome.TextColor3 = r.cor
	local comparar = ""
	local atualId = estado.equipado[it.slot]
	local atual = atualId and itemPorId(atualId)
	if atual and atual.id ~= it.id then
		local dif = it.valor - atual.valor
		local cor = dif >= 0 and "#5fe08a" or "#ff6b6b"
		comparar = string.format(
			'  <font color="%s">(%s em relação ao vestido)</font>',
			cor,
			dif >= 0 and "melhor" or "pior"
		)
	end
	detStat.Text = r.nome .. " · " .. textoItem(it) .. comparar
	local v = vestido(it.id)
	btnEquipar.Visible = true
	btnEquipar.Text = v and "Tirar" or "Vestir"
	btnEquipar.BackgroundColor3 = v and COR.cinza or COR.verde
	btnVender.Visible = not v
	btnVender.Text = "Vender (+" .. (Config.ValorVenda[it.raridade] or 1) .. " ouro)"
end

local function desenharMochila()
	for _, s in ipairs(Config.Slots) do
		local ui = slotUI[s.id]
		local id = estado.equipado[s.id]
		local it = id and itemPorId(id)
		if it then
			local r = raridade(it.raridade)
			ui.nome.Text = it.nome
			ui.nome.TextColor3 = r.cor
			ui.stat.Text = textoItem(it)
			ui.stroke.Color = r.cor
		else
			ui.nome.Text = s.nome .. ": vazio"
			ui.nome.TextColor3 = COR.fraco
			ui.stat.Text = ""
			ui.stroke.Color = COR.cinza
		end
	end
	local st = estado.stats
	lblStats.Text = string.format(
		"<b>Poder do herói</b>\nDano: <b>%d</b>\nCrítico: <b>%.1f%%</b>\nOuro: <b>+%.0f%%</b>\nVelocidade: <b>%d</b>",
		st.dano,
		st.critico * 100,
		(st.ouro - 1) * 100,
		st.velocidade
	)

	lblInv.Text = string.format("Mochila %d/%d", #estado.inventario, Config.LimiteInventario)
	for _, c in ipairs(grade:GetChildren()) do
		if c:IsA("GuiButton") then
			c:Destroy()
		end
	end
	local lista = table.clone(estado.inventario)
	table.sort(lista, function(a, b)
		local _, ra = raridade(a.raridade)
		local _, rb = raridade(b.raridade)
		if ra ~= rb then
			return ra > rb
		end
		return a.id > b.id
	end)
	for i, it in ipairs(lista) do
		local r = raridade(it.raridade)
		local s = slotInfo(it.slot)
		local b = novo("TextButton", grade, {
			Name = "Item_" .. i,
			LayoutOrder = i,
			BackgroundColor3 = r.cor:Lerp(Color3.new(0, 0, 0), 0.55),
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = true,
		})
		canto(b, 10)
		contorno(b, selecionado == it.id and Color3.new(1, 1, 1) or r.cor, selecionado == it.id and 3 or 2)
		rotulo(b, { Size = UDim2.new(1, 0, 1, -8), Text = s.icone, TextSize = 26 })
		if vestido(it.id) then
			local tag = rotulo(b, {
				Position = UDim2.new(0, 0, 1, -16),
				Size = UDim2.new(1, 0, 0, 14),
				Text = "VESTIDO",
				TextSize = 9,
				Font = Enum.Font.GothamBlack,
				BackgroundTransparency = 0.2,
				BackgroundColor3 = COR.verde,
			})
			canto(tag, 6)
		end
		b.Activated:Connect(function()
			selecionado = it.id
			desenharMochila()
		end)
	end
	desenharDetalhe()
end

for _, s in ipairs(Config.Slots) do
	slotUI[s.id].linha.Activated:Connect(function()
		local id = estado and estado.equipado[s.id]
		if id then
			selecionado = id
			desenharMochila()
		end
	end)
end

------------------------------------------------------------------------
-- Aba Forja
------------------------------------------------------------------------
rotulo(pgForja, {
	Size = UDim2.new(1, 0, 0, 40),
	TextWrapped = true,
	TextSize = 13,
	Font = Enum.Font.Gotham,
	TextColor3 = COR.fraco,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "Junte "
		.. Config.Forja.Quantidade
		.. " itens da mesma raridade para criar 1 item da raridade de cima. Itens vestidos não entram. Os mais fracos são usados primeiro.",
})
local listaForja = novo("ScrollingFrame", pgForja, {
	Position = UDim2.fromOffset(0, 46),
	Size = UDim2.new(1, 0, 1, -46),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 6,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
})
novo("UIListLayout", listaForja, { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })

local linhasForja = {}
for i = 1, #Config.Raridades - 1 do
	local de, para = Config.Raridades[i], Config.Raridades[i + 1]
	local l = novo(
		"Frame",
		listaForja,
		{ LayoutOrder = i, Size = UDim2.new(1, -8, 0, 62), BackgroundColor3 = COR.painel2, BorderSizePixel = 0 }
	)
	canto(l, 12)
	local function chip(x, r, txt)
		local c = novo("Frame", l, {
			Position = UDim2.fromOffset(x, 11),
			Size = UDim2.fromOffset(40, 40),
			BackgroundColor3 = r.cor:Lerp(Color3.new(0, 0, 0), 0.5),
		})
		canto(c, 8)
		contorno(c, r.cor, 2)
		rotulo(c, { Size = UDim2.fromScale(1, 1), Text = txt, TextSize = 15, Font = Enum.Font.GothamBlack })
	end
	chip(10, de, Config.Forja.Quantidade .. "x")
	rotulo(l, { Position = UDim2.fromOffset(52, 0), Size = UDim2.fromOffset(26, 62), Text = "→", TextSize = 20 })
	chip(80, para, "1x")
	local txt = rotulo(l, {
		Position = UDim2.fromOffset(130, 8),
		Size = UDim2.new(1, -270, 0, 46),
		TextSize = 12,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		RichText = true,
		Text = "",
	})
	local b = botao(l, {
		Name = "Forjar_" .. de.id,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(120, 40),
		Text = "Forjar",
		Font = Enum.Font.GothamBlack,
		TextSize = 15,
	})
	b.Activated:Connect(function()
		evForjar:FireServer(de.id)
	end)
	linhasForja[i] = { txt = txt, btn = b, de = de, para = para }
end

local function podeForjar(rarId)
	if not estado then
		return false, 0
	end
	local n = 0
	for _, it in ipairs(estado.inventario) do
		if it.raridade == rarId and not vestido(it.id) then
			n += 1
		end
	end
	return n >= Config.Forja.Quantidade and estado.ouro >= (Config.Forja.Custo[rarId] or 0), n
end

local function desenharForja()
	for _, l in ipairs(linhasForja) do
		local ok, n = podeForjar(l.de.id)
		local custo = Config.Forja.Custo[l.de.id] or 0
		l.txt.Text = string.format(
			'<b>%s → %s</b>\nVocê tem <b>%d</b> · custa <font color="#ffcd46"><b>%d ouro</b></font>',
			l.de.nome,
			l.para.nome,
			n,
			custo
		)
		l.btn.BackgroundColor3 = ok and Color3.fromRGB(215, 110, 45) or COR.cinza
		l.btn.AutoButtonColor = ok
		l.btn.TextTransparency = ok and 0 or 0.4
	end
end

------------------------------------------------------------------------
-- Abas Habilidades e Ovos (em breve)
------------------------------------------------------------------------
local function emBreve(pagina, icone, titulo, texto, qtd)
	local g = novo("Frame", pagina, { Size = UDim2.new(1, 0, 0, 90), BackgroundTransparency = 1 })
	novo("UIListLayout", g, {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 10),
	})
	for _ = 1, qtd do
		local c = novo("Frame", g, { Size = UDim2.fromOffset(78, 78), BackgroundColor3 = COR.painel2 })
		canto(c, 14)
		contorno(c, COR.borda, 2)
		rotulo(c, { Size = UDim2.fromScale(1, 1), Text = icone, TextSize = 32, TextTransparency = 0.5 })
		rotulo(c, {
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -4, 1, -2),
			Size = UDim2.fromOffset(20, 20),
			Text = "🔒",
			TextSize = 14,
		})
	end
	rotulo(pagina, {
		Position = UDim2.fromOffset(0, 104),
		Size = UDim2.new(1, 0, 0, 26),
		Text = titulo,
		TextSize = 20,
		Font = Enum.Font.GothamBlack,
	})
	rotulo(pagina, {
		Position = UDim2.fromOffset(0, 132),
		Size = UDim2.new(1, 0, 0, 40),
		Text = texto,
		TextSize = 13,
		Font = Enum.Font.Gotham,
		TextColor3 = COR.fraco,
		TextWrapped = true,
	})
end
emBreve(
	pgHab,
	"✨",
	"Habilidades — em breve",
	"Aqui vão ficar as habilidades do herói. Vamos definir quais serão com o tempo.",
	4
)
emBreve(
	pgOvos,
	"🥚",
	"Ovos de Pet — em breve",
	"Aqui você vai chocar ovos para ganhar pets que lutam junto com o herói.",
	3
)

------------------------------------------------------------------------
-- Janela do Portal: mundos e fases
------------------------------------------------------------------------
local jPortal, corpoPortal, _, fecharPortal = criarJanela("🌀 Portal")
fecharPortal.Activated:Connect(fecharJanelas)
painelFase.Activated:Connect(function()
	abrirJanela(jPortal)
	desenhar()
end)

local colMundos = novo("Frame", corpoPortal, { Size = UDim2.new(0.32, -6, 1, 0), BackgroundTransparency = 1 })
novo("UIListLayout", colMundos, { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
local mundoSel = 1
local botoesMundo = {}
for i, m in ipairs(Config.Mundos) do
	local b =
		botao(colMundos, { LayoutOrder = i, Size = UDim2.new(1, 0, 0, 54), Text = "", BackgroundColor3 = COR.painel2 })
	rotulo(b, {
		Position = UDim2.fromOffset(10, 6),
		Size = UDim2.new(1, -20, 0, 20),
		Text = "Mundo " .. i,
		TextSize = 15,
		Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	rotulo(b, {
		Position = UDim2.fromOffset(10, 27),
		Size = UDim2.new(1, -20, 0, 18),
		Text = m.nome,
		TextSize = 12,
		Font = Enum.Font.Gotham,
		TextColor3 = COR.fraco,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	botoesMundo[i] = b
	b.Activated:Connect(function()
		mundoSel = i
		desenhar()
	end)
end

local colFases = novo("Frame", corpoPortal, {
	Position = UDim2.new(0.32, 6, 0, 0),
	Size = UDim2.new(0.68, -6, 1, 0),
	BackgroundColor3 = COR.painel2,
	BorderSizePixel = 0,
})
canto(colFases, 12)
local lblMundoSel = rotulo(colFases, {
	Position = UDim2.fromOffset(12, 6),
	Size = UDim2.new(1, -24, 0, 24),
	Text = "",
	TextSize = 16,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Left,
})
local gradeFases = novo(
	"Frame",
	colFases,
	{ Position = UDim2.fromOffset(12, 36), Size = UDim2.new(1, -24, 1, -48), BackgroundTransparency = 1 }
)
novo("UIGridLayout", gradeFases, {
	CellSize = UDim2.new(0.2, -8, 0, 56),
	CellPadding = UDim2.fromOffset(8, 8),
	SortOrder = Enum.SortOrder.LayoutOrder,
})

local function faseIndice(mundo, numero)
	for i, f in ipairs(Config.Fases) do
		if f.mundo == mundo and f.numero == numero then
			return i
		end
	end
end

local function desenharPortal()
	for i, b in pairs(botoesMundo) do
		local temFase = faseIndice(i, 1) ~= nil
		b.BackgroundColor3 = (i == mundoSel) and COR.roxo or COR.painel2
		b.TextTransparency = temFase and 0 or 0.5
	end
	local m = Config.Mundos[mundoSel]
	lblMundoSel.Text = "Mundo " .. mundoSel .. " · " .. m.nome
	for _, c in ipairs(gradeFases:GetChildren()) do
		if c:IsA("GuiButton") then
			c:Destroy()
		end
	end
	for n = 1, m.totalFases do
		local idx = faseIndice(mundoSel, n)
		local atual = idx and estado and idx == estado.faseIdx
		local liberada = idx and estado and idx <= estado.faseMax
		local b = botao(
			gradeFases,
			{ Name = "Fase_" .. n, LayoutOrder = n, Text = "", AutoButtonColor = liberada and not atual }
		)
		local nome = mundoSel .. "-" .. n
		if atual then
			b.BackgroundColor3 = COR.roxo
			contorno(b, Color3.new(1, 1, 1), 2)
		elseif liberada then
			b.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
		else
			b.BackgroundColor3 = Color3.fromRGB(45, 42, 60)
		end
		rotulo(b, {
			Position = UDim2.fromOffset(0, 6),
			Size = UDim2.new(1, 0, 0, 22),
			Text = nome,
			TextSize = 17,
			Font = Enum.Font.GothamBlack,
			TextTransparency = (liberada or atual) and 0 or 0.5,
		})
		local sub = atual and "aqui" or (liberada and "ir" or (idx and "🔒" or "em breve"))
		rotulo(b, {
			Position = UDim2.fromOffset(0, 30),
			Size = UDim2.new(1, 0, 0, 16),
			Text = sub,
			TextSize = 11,
			Font = Enum.Font.Gotham,
			TextColor3 = COR.fraco,
		})
		if liberada and not atual then
			b.Activated:Connect(function()
				evIrFase:FireServer(idx)
				fecharJanelas()
			end)
		end
	end
end

------------------------------------------------------------------------
-- Atualizar tudo quando chega o estado novo do servidor
------------------------------------------------------------------------
local ouroAntes, qtdItensAntes = nil, nil

desenhar = function()
	if not estado then
		return
	end
	lblNivel.Text = tostring(estado.nivel)
	xpTxt.Text = estado.xp .. " / " .. estado.xpProx .. " XP"
	TweenService
		:Create(
			xpCheio,
			TweenInfo.new(0.25),
			{ Size = UDim2.fromScale(math.clamp(estado.xp / estado.xpProx, 0, 1), 1) }
		)
		:Play()
	lblPoder.Text = string.format("Dano %d · Crítico %.0f%%", estado.stats.dano, estado.stats.critico * 100)
	lblOuro.Text = tostring(estado.ouro)

	local f = Config.Fases[estado.faseIdx]
	lblMundo.Text = "Mundo " .. f.mundo .. " · " .. Config.Mundos[f.mundo].nome
	lblFase.Text = "Fase " .. f.nome
	killTxt.Text = estado.kills .. " / " .. estado.meta .. "  " .. f.monstro
	TweenService
		:Create(
			killCheio,
			TweenInfo.new(0.2),
			{ Size = UDim2.fromScale(math.clamp(estado.kills / estado.meta, 0, 1), 1) }
		)
		:Play()

	local algumaForja = false
	for i = 1, #Config.Raridades - 1 do
		if podeForjar(Config.Raridades[i].id) then
			algumaForja = true
		end
	end
	bolinhas.forja.Visible = algumaForja

	if jMenu.Visible then
		if abaAtual == "mochila" then
			desenharMochila()
		elseif abaAtual == "forja" then
			desenharForja()
		end
	end
	if jPortal.Visible then
		desenharPortal()
	end
end

evEstado.OnClientEvent:Connect(function(novoEstado)
	estado = novoEstado
	if ouroAntes and estado.ouro > ouroAntes then
		moeda.Size = UDim2.fromOffset(28, 28)
		TweenService:Create(moeda, TweenInfo.new(0.2), { Size = UDim2.fromOffset(22, 22) }):Play()
	end
	if qtdItensAntes and #estado.inventario > qtdItensAntes and not (jMenu.Visible and abaAtual == "mochila") then
		bolinhas.mochila.Visible = true
	end
	ouroAntes, qtdItensAntes = estado.ouro, #estado.inventario
	if selecionado and type(selecionado) == "number" and not itemPorId(selecionado) then
		selecionado = nil
	end
	desenhar()
end)

------------------------------------------------------------------------
-- Barra de vida do chefe (topo da tela)
------------------------------------------------------------------------
local barraChefe = caixa(gui, {
	Name = "BarraChefe",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 148),
	Size = UDim2.new(0.6, 0, 0, 46),
	Visible = false,
})
novo("UISizeConstraint", barraChefe, { MaxSize = Vector2.new(460, 46) })
canto(barraChefe, 12)
contorno(barraChefe, Color3.fromRGB(190, 90, 255), 2.5)
local lblChefe = rotulo(barraChefe, {
	Position = UDim2.fromOffset(12, 3),
	Size = UDim2.new(1, -24, 0, 18),
	Text = "",
	TextSize = 15,
	Font = Enum.Font.GothamBlack,
	TextColor3 = Color3.fromRGB(225, 185, 255),
})
local _, chefeCheio, chefeTxt = barra(barraChefe, {
	Position = UDim2.fromOffset(12, 23),
	Size = UDim2.new(1, -24, 0, 16),
}, Color3.fromRGB(190, 90, 255))

local pastaMonstros = workspace:WaitForChild("Monstros")
task.spawn(function()
	while true do
		task.wait(0.1)
		local chefe
		for _, m in ipairs(pastaMonstros:GetChildren()) do
			if m:GetAttribute("Chefe") and m:GetAttribute("Dono") == player.UserId then
				chefe = m
			end
		end
		barraChefe.Visible = chefe ~= nil
		if chefe then
			local vida = chefe:GetAttribute("Vida") or 0
			local maximo = chefe:GetAttribute("VidaMax") or 1
			lblChefe.Text = "☠ " .. chefe.Name
			chefeTxt.Text = vida .. " / " .. maximo
			chefeCheio.Size = UDim2.fromScale(math.clamp(vida / maximo, 0, 1), 1)
		end
	end
end)

evPedirEstado:FireServer()
