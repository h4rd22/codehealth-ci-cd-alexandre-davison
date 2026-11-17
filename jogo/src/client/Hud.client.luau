-- Hud: tudo o que aparece na tela.
-- Nível e XP, ouro, portal de fases, menu lateral (Mochila, Forja,
-- Habilidades, Ovos), inventário com equipamentos e botão de auto-farm.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local ItemArte = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ItemArte"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local R = function(n)
	return remotes:WaitForChild(n)
end
local evEstado, evPedirEstado = R("Estado"), R("PedirEstado")
local evAutoFarm, evEquipar, evDesequipar = R("AutoFarm"), R("Equipar"), R("Desequipar")
local evVender, evForjar, evIrFase = R("Vender"), R("Forjar"), R("IrFase")
local evForjarAuto, evAlquimia, evConfigForja = R("ForjarAuto"), R("Alquimia"), R("ConfigForja")
local evVida = R("Vida")
local evRepetir, evTreinar = R("Repetir"), R("Treinar")
local evAutoVenda = R("AutoVenda")
local evAvatar, evEsconderEquip = R("Avatar"), R("EsconderEquip")

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
	painel = Color3.fromRGB(32, 25, 22), -- carvão quente
	painel2 = Color3.fromRGB(52, 39, 31), -- madeira escura
	borda = Color3.fromRGB(110, 78, 48),
	dourado = Color3.fromRGB(222, 178, 96),
	roxo = Color3.fromRGB(226, 128, 46), -- acento laranja (aba ativa, destaques)
	ouro = Color3.fromRGB(255, 208, 72),
	xp = Color3.fromRGB(90, 210, 255),
	texto = Color3.fromRGB(255, 246, 228),
	fraco = Color3.fromRGB(200, 178, 145),
	verde = Color3.fromRGB(78, 178, 74),
	cinza = Color3.fromRGB(84, 72, 64),
	vermelho = Color3.fromRGB(205, 52, 46),
	madeira = Color3.fromRGB(104, 60, 34),
	faixa = Color3.fromRGB(150, 34, 30),
}
local FONTE = Enum.Font.FredokaOne
local FONTE_TEXTO = Enum.Font.GothamMedium

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
	local f = novo("Frame", pai, { BackgroundColor3 = COR.painel, BackgroundTransparency = 0.04, BorderSizePixel = 0 })
	for k, v in pairs(props or {}) do
		f[k] = v
	end
	novo("UIGradient", f, {
		Rotation = 90,
		Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(170, 160, 150)),
	})
	return f
end
local function rotulo(pai, props)
	local t = novo("TextLabel", pai, {
		BackgroundTransparency = 1,
		Font = FONTE,
		TextColor3 = COR.texto,
		TextSize = 14,
		TextStrokeTransparency = 0.35,
		TextStrokeColor3 = Color3.fromRGB(22, 12, 8),
	})
	for k, v in pairs(props or {}) do
		t[k] = v
	end
	return t
end
local function botao(pai, props)
	local b = novo("TextButton", pai, {
		Font = FONTE,
		TextColor3 = COR.texto,
		TextSize = 14,
		TextStrokeTransparency = 0.4,
		TextStrokeColor3 = Color3.fromRGB(22, 12, 8),
		BorderSizePixel = 0,
		AutoButtonColor = true,
		BackgroundColor3 = COR.madeira,
	})
	for k, v in pairs(props or {}) do
		b[k] = v
	end
	canto(b, 8)
	novo("UIStroke", b, {
		Color = COR.dourado,
		Thickness = 1.5,
		Transparency = 0.25,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
	novo("UIGradient", b, {
		Rotation = 90,
		Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(150, 140, 130)),
	})
	return b
end
local function barra(pai, props, cor)
	local fundo = novo("Frame", pai, { BackgroundColor3 = Color3.fromRGB(20, 14, 12), BorderSizePixel = 0 })
	for k, v in pairs(props or {}) do
		fundo[k] = v
	end
	canto(fundo, 8)
	novo("UIStroke", fundo, {
		Color = Color3.fromRGB(90, 62, 38),
		Thickness = 1.5,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
	local cheio = novo("Frame", fundo, { Size = UDim2.fromScale(0, 1), BackgroundColor3 = cor, BorderSizePixel = 0 })
	canto(cheio, 8)
	novo("UIGradient", cheio, {
		Rotation = 90,
		Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(160, 160, 160)),
	})
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
	elseif atributo == "danoMult" then
		return string.format("+%.0f%% de dano", v * 100)
	else
		return string.format("+%d de dano", v)
	end
end
local cartaoItem -- cartão de item (definido logo abaixo)
local function textoItem(item)
	local s = slotInfo(item.slot)
	return "Nv " .. (item.nivel or 1) .. " · " .. textoValor(s.atributo, item.valor)
end

-- Cartão de item: fundo na cor da raridade, ícone grande, nível e brilho nos raros
cartaoItem = function(pai, item, props)
	local r, ri = raridade(item.raridade)
	local s = slotInfo(item.slot)
	local b = novo("ImageButton", pai, {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		AutoButtonColor = true,
		Image = "",
	})
	for k, v in pairs(props or {}) do
		b[k] = v
	end
	canto(b, 10)
	novo("UIGradient", b, {
		Rotation = 90,
		Color = ColorSequence.new(r.cor:Lerp(Color3.new(1, 1, 1), 0.15), r.cor:Lerp(Color3.new(0, 0, 0), 0.65)),
	})
	contorno(b, r.corBorda or r.cor:Lerp(Color3.new(1, 1, 1), 0.3), ri >= 4 and 2.5 or 1.5)
	local luz = novo("Frame", b, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.72, 0.72),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = ri >= 3 and 0.72 or 0.86,
	})
	canto(luz, 100)
	-- desenho 3D do item (muda com a categoria e o tier)
	local vp = novo("ViewportFrame", b, {
		Name = "Icone3D",
		Position = UDim2.fromScale(0.04, 0.02),
		Size = UDim2.fromScale(0.92, 0.84),
		BackgroundTransparency = 1,
		ZIndex = 2,
	})
	ItemArte.mostrar(vp, s.id, ri, r.cor, item.conjunto)
	-- selo do conjunto (canto de baixo à esquerda)
	local conj = item.conjunto and Config.ConjuntoPorId(item.conjunto)
	if conj then
		local selo = novo("Frame", b, {
			Position = UDim2.new(0, 3, 1, -13),
			Size = UDim2.fromOffset(10, 10),
			BackgroundColor3 = conj.cor,
			Rotation = 45,
			ZIndex = 4,
		})
		contorno(selo, Color3.new(1, 1, 1), 1)
	end
	-- brilho passando pelo cartão nos tiers Mítico ou acima
	if ri >= 6 then
		local sheen = novo("Frame", b, {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0,
			ZIndex = 5,
		})
		canto(sheen, 10)
		local g = novo("UIGradient", sheen, {
			Rotation = 25,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.42, 1),
				NumberSequenceKeypoint.new(0.5, 0.45),
				NumberSequenceKeypoint.new(0.58, 1),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Offset = Vector2.new(-1, 0),
		})
		TweenService:Create(
			g,
			TweenInfo.new(ri >= 8 and 1.1 or 1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false, 0.6),
			{ Offset = Vector2.new(1, 0) }
		):Play()
	end
	rotulo(b, {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -3, 1, -1),
		Size = UDim2.fromOffset(40, 12),
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = "Lv." .. (item.nivel or 1),
		TextSize = 11,
		Font = FONTE,
		TextStrokeTransparency = 0.2,
		TextStrokeColor3 = Color3.fromRGB(10, 8, 16),
		ZIndex = 3,
	})
	rotulo(b, {
		Position = UDim2.fromOffset(3, 1),
		Size = UDim2.fromOffset(20, 12),
		Text = "T" .. ri,
		TextSize = 10,
		Font = FONTE,
		TextColor3 = r.cor:Lerp(Color3.new(1, 1, 1), 0.55),
		TextStrokeTransparency = 0.3,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
	})
	if ri >= 4 then
		rotulo(b, {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -2, 0, 0),
			Size = UDim2.fromOffset(14, 14),
			Text = "✦",
			TextSize = 13,
			TextColor3 = Color3.fromRGB(255, 240, 160),
			ZIndex = 3,
		})
	end
	return b
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
local cartao = caixa(gui, { Position = UDim2.fromOffset(14, 62), Size = UDim2.new(0.42, 0, 0, 84) })
novo("UISizeConstraint", cartao, { MaxSize = Vector2.new(290, 84) })
canto(cartao, 14)
contorno(cartao, COR.dourado, 2.5)

-- Retrato do herói (foto do avatar do Roblox) com o nível num selo dourado
local retratoHeroi = novo("ImageLabel", cartao, {
	Position = UDim2.fromOffset(8, 12),
	Size = UDim2.fromOffset(58, 58),
	BackgroundColor3 = Color3.fromRGB(70, 44, 30),
	Image = "",
	ScaleType = Enum.ScaleType.Crop,
})
canto(retratoHeroi, 12)
contorno(retratoHeroi, COR.dourado, 2.5)
novo("UIGradient", retratoHeroi, {
	Rotation = 90,
	Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(215, 205, 195)),
})
task.spawn(function()
	local ok, img = pcall(function()
		return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
	end)
	if ok and img then
		retratoHeroi.Image = img
	end
end)
local nivelBola = novo("Frame", cartao, {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromOffset(62, 66),
	Size = UDim2.fromOffset(28, 28),
	BackgroundColor3 = COR.faixa,
	ZIndex = 3,
})
canto(nivelBola, 14)
contorno(nivelBola, COR.dourado, 2)
local lblNivel = rotulo(nivelBola, {
	Size = UDim2.fromScale(1, 1),
	Text = "1",
	TextSize = 15,
	Font = FONTE,
	TextColor3 = Color3.fromRGB(255, 225, 140),
	ZIndex = 4,
})

rotulo(cartao, {
	Position = UDim2.fromOffset(74, 8),
	Size = UDim2.new(1, -84, 0, 18),
	Text = player.DisplayName,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextSize = 15,
	TextTruncate = Enum.TextTruncate.AtEnd,
})
local _, vidaCheio, vidaTxt =
	barra(cartao, { Position = UDim2.fromOffset(74, 28), Size = UDim2.new(1, -84, 0, 17) }, Color3.fromRGB(230, 60, 75))
local _, xpCheio, xpTxt =
	barra(cartao, { Position = UDim2.fromOffset(74, 49), Size = UDim2.new(1, -84, 0, 12) }, COR.xp)
xpTxt.TextSize = 10
local lblPoder = rotulo(cartao, {
	Position = UDim2.fromOffset(74, 64),
	Size = UDim2.new(1, -84, 0, 14),
	Text = "",
	TextSize = 11,
	Font = FONTE_TEXTO,
	TextColor3 = COR.fraco,
	TextXAlignment = Enum.TextXAlignment.Left,
})

local caixaOuro = caixa(gui, { Position = UDim2.fromOffset(14, 154), Size = UDim2.fromOffset(150, 38) })
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
	Font = FONTE,
	TextColor3 = Color3.fromRGB(150, 95, 10),
})
local lblOuro = rotulo(caixaOuro, {
	Position = UDim2.fromOffset(38, 0),
	Size = UDim2.new(1, -46, 1, 0),
	Text = "0",
	TextSize = 18,
	Font = FONTE,
	TextColor3 = COR.ouro,
	TextXAlignment = Enum.TextXAlignment.Left,
})

------------------------------------------------------------------------
-- Portal (canto direito de cima): fase atual + botão que abre os mundos
------------------------------------------------------------------------
local btnRepetir -- criado logo depois do painel da fase
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
contorno(painelFase, COR.dourado, 2.5)

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
	Font = FONTE_TEXTO,
	TextColor3 = COR.fraco,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "Mundo 1",
})
local lblFase = rotulo(painelFase, {
	Position = UDim2.fromOffset(72, 20),
	Size = UDim2.new(1, -80, 0, 22),
	TextSize = 19,
	Font = FONTE,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "Fase 1-1",
})
local _, killCheio, killTxt =
	barra(painelFase, { Position = UDim2.fromOffset(72, 46), Size = UDim2.new(1, -82, 0, 15) }, COR.roxo)

-- Repetir a mesma fase (para farmar): não avança sozinho, mas libera a próxima no portal
btnRepetir = botao(gui, {
	Name = "Repetir",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -14, 0, 138),
	Size = UDim2.fromOffset(170, 30),
	Text = "🔁 Repetir fase: NÃO",
	TextSize = 13,
})
btnRepetir.Activated:Connect(function()
	if estado then
		evRepetir:FireServer(not estado.repetir)
	end
end)

------------------------------------------------------------------------
-- Menu lateral
------------------------------------------------------------------------
local menu = novo("Frame", gui, {
	Name = "MenuLateral",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 14, 0.55, 0),
	Size = UDim2.fromOffset(70, 5 * 78),
	BackgroundTransparency = 1,
})
novo("UIListLayout", menu, { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })

local botoesMenu, bolinhas = {}, {}
local function botaoMenu(ordem, id, icone, nome, corFundo)
	local b = novo("TextButton", menu, {
		Name = "Menu_" .. id,
		LayoutOrder = ordem,
		Size = UDim2.fromOffset(70, 70),
		BackgroundColor3 = COR.madeira,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = true,
	})
	canto(b, 35)
	contorno(b, COR.dourado, 3)
	novo(
		"UIGradient",
		b,
		{ Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(140, 130, 120)) }
	)
	-- miolo colorido de cada botão
	local mioloBotao = novo("Frame", b, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromOffset(40, 40),
		BackgroundColor3 = corFundo,
		BackgroundTransparency = 0.35,
	})
	canto(mioloBotao, 20)
	rotulo(b, {
		Position = UDim2.fromOffset(0, 9),
		Size = UDim2.new(1, 0, 0, 36),
		Text = icone,
		TextSize = 28,
		ZIndex = 2,
		Font = FONTE,
	})
	rotulo(b, {
		Position = UDim2.new(0, -6, 1, -14),
		Size = UDim2.new(1, 12, 0, 18),
		Text = nome,
		TextSize = 13,
		Font = FONTE,
		TextColor3 = Color3.fromRGB(255, 225, 150),
		TextStrokeTransparency = 0.1,
	})
	bolinhas[id] = bolinha(b)
	botoesMenu[id] = b
	return b
end
botaoMenu(1, "mochila", "🎒", "Mochila", Color3.fromRGB(70, 120, 230))
botaoMenu(2, "forja", "🔨", "Forja", Color3.fromRGB(215, 110, 45))
botaoMenu(3, "habilidades", "✨", "Habilid.", Color3.fromRGB(140, 80, 220))
botaoMenu(4, "ovos", "🥚", "Ovos", Color3.fromRGB(60, 170, 120))
botaoMenu(5, "treino", "🏋️", "Treino", Color3.fromRGB(200, 60, 60))
botaoMenu(6, "avatar", "🎭", "Avatar", Color3.fromRGB(230, 160, 40))

------------------------------------------------------------------------
-- Botão de auto-farm
------------------------------------------------------------------------
local btnAuto = botao(gui, {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -22),
	Size = UDim2.fromOffset(220, 50),
	TextSize = 17,
	Font = FONTE,
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
	canto(j, 14)
	contorno(j, COR.dourado, 3)
	local topo = novo("Frame", j, { Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = COR.faixa, BorderSizePixel = 0 })
	canto(topo, 14)
	novo("UIGradient", topo, {
		Rotation = 90,
		Color = ColorSequence.new(Color3.fromRGB(255, 190, 170), Color3.fromRGB(160, 120, 110)),
	})
	novo("Frame", topo, {
		Position = UDim2.new(0, 0, 1, -12),
		Size = UDim2.new(1, 0, 0, 12),
		BackgroundColor3 = COR.faixa,
		BorderSizePixel = 0,
	})
	-- filete dourado embaixo da faixa
	novo("Frame", topo, {
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 2),
		BackgroundColor3 = COR.dourado,
		BorderSizePixel = 0,
	})
	local lbl = rotulo(topo, {
		Position = UDim2.fromOffset(16, 0),
		Size = UDim2.new(0, 160, 1, 0),
		Text = titulo,
		TextSize = 20,
		Font = FONTE,
		TextColor3 = Color3.fromRGB(255, 220, 130),
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local fechar = botao(topo, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(32, 32),
		Text = "X",
		BackgroundColor3 = COR.vermelho,
		Font = FONTE,
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
		Size = UDim2.new(0.166, -5, 1, 0),
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
local pgTreino = criarAba(5, "treino", "🏋️ Treino")
local pgAvatar = criarAba(6, "avatar", "🎭 Avatar")

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
	Font = FONTE,
})
local listaSlots = novo(
	"Frame",
	colEquip,
	{ Position = UDim2.fromOffset(8, 30), Size = UDim2.new(1, -16, 0, #Config.Slots * 52), BackgroundTransparency = 1 }
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
	local icEmoji = rotulo(ic, { Size = UDim2.fromScale(1, 1), Text = s.icone, TextSize = 22 })
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
		Font = FONTE_TEXTO,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "",
		TextColor3 = COR.fraco,
	})
	slotUI[s.id] = { linha = linha, stroke = icStroke, nome = nome, stat = stat, ic = ic, emoji = icEmoji }
end

local lblStats = rotulo(colEquip, {
	Position = UDim2.fromOffset(10, 30 + #Config.Slots * 52 + 6),
	Size = UDim2.new(1, -20, 1, -(30 + #Config.Slots * 52 + 12)),
	TextSize = 12,
	Font = FONTE_TEXTO,
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
local NOMES_AUTOVENDA = { nada = "Desligada", comum = "até Comum", incomum = "até Incomum", raro = "até Raro" }
local btnAutoVenda = botao(colInv, {
	Name = "AutoVenda",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, 0, 0, -2),
	Size = UDim2.fromOffset(170, 22),
	Text = "💰 Venda automática: Desligada",
	TextSize = 11,
})
btnAutoVenda.Activated:Connect(function()
	if not estado then
		return
	end
	local ops = Config.AutoVendaOpcoes
	local i = table.find(ops, estado.autoVenda or "nada") or 1
	evAutoVenda:FireServer(ops[i % #ops + 1])
end)
local lblInv = rotulo(colInv, {
	Size = UDim2.new(1, -176, 0, 20),
	Text = "Mochila 0/" .. Config.LimiteInventario,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextSize = 14,
	Font = FONTE,
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
	Font = FONTE_TEXTO,
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
	detNome.TextColor3 = r.corBorda or r.cor
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
	local linhaConj = ""
	local conj = it.conjunto and Config.ConjuntoPorId(it.conjunto)
	if conj then
		local vestidas = 0
		for _, eid in pairs(estado.equipado) do
			local e = itemPorId(eid)
			if e and e.conjunto == conj.id then
				vestidas += 1
			end
		end
		linhaConj = string.format('\n<font color="#%s"><b>%s (%d/4)</b></font>', conj.cor:ToHex(), conj.nome, vestidas)
		for _, n in ipairs({ 2, 4 }) do
			local cor = vestidas >= n and "#7CFC8A" or "#9a8f80"
			linhaConj ..= string.format(' <font color="%s">%s</font>', cor, conj.bonus[n].texto)
		end
	end
	detStat.Text = "T"
		.. select(2, raridade(it.raridade))
		.. " "
		.. r.nome
		.. " · "
		.. textoItem(it)
		.. comparar
		.. linhaConj
	local v = vestido(it.id)
	btnEquipar.Visible = true
	btnEquipar.Text = v and "Tirar" or "Vestir"
	btnEquipar.BackgroundColor3 = v and COR.cinza or COR.verde
	btnVender.Visible = not v
	btnVender.Text = "Vender (+" .. (Config.ValorVenda[it.raridade] or 1) .. " ouro)"
end

-- "Assinatura" dos itens: muda só quando entra/sai/veste/seleciona item (não a cada inimigo morto)
local function assinaturaItens(extra)
	local partes = { extra or "" }
	for _, it in ipairs(estado.inventario) do
		table.insert(partes, it.id)
	end
	for slot, id in pairs(estado.equipado) do
		table.insert(partes, slot .. "=" .. id)
	end
	table.sort(partes, function(a, b)
		return tostring(a) < tostring(b)
	end)
	return table.concat(partes, ",")
end
local ultimaGradeMochila, ultimaGradeForja

local function desenharMochila()
	for _, s in ipairs(Config.Slots) do
		local ui = slotUI[s.id]
		local id = estado.equipado[s.id]
		local it = id and itemPorId(id)
		local antigo = ui.ic:FindFirstChild("Icone3D")
		if antigo and antigo:GetAttribute("Item") ~= (it and it.id or -1) then
			antigo:Destroy()
			antigo = nil
		end
		ui.emoji.Visible = it == nil
		if it and not antigo then
			local r3, ri3 = raridade(it.raridade)
			local vp = novo("ViewportFrame", ui.ic, {
				Name = "Icone3D",
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
			})
			vp:SetAttribute("Item", it.id)
			ItemArte.mostrar(vp, it.slot, ri3, r3.cor, it.conjunto)
		end
		if it then
			local r = raridade(it.raridade)
			ui.nome.Text = it.nome
			ui.nome.TextColor3 = r.corBorda or r.cor
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
	btnAutoVenda.Text = "💰 Venda automática: " .. (NOMES_AUTOVENDA[estado.autoVenda or "nada"] or "Desligada")
	btnAutoVenda.BackgroundColor3 = (estado.autoVenda or "nada") ~= "nada" and COR.verde or COR.madeira
	local assinatura = assinaturaItens("sel" .. tostring(selecionado))
	if assinatura == ultimaGradeMochila then
		desenharDetalhe()
		return
	end
	ultimaGradeMochila = assinatura
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
		local b = cartaoItem(grade, it, { Name = "Item_" .. i, LayoutOrder = i })
		if selecionado == it.id then
			contorno(b, Color3.new(1, 1, 1), 3)
		end
		if vestido(it.id) then
			-- selo verde no canto: item vestido (não cobre o nível)
			local tag = rotulo(b, {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, 2, 0, -2),
				Size = UDim2.fromOffset(18, 18),
				Text = "✔",
				TextSize = 12,
				BackgroundTransparency = 0,
				BackgroundColor3 = COR.verde,
				ZIndex = 6,
			})
			canto(tag, 9)
			contorno(tag, Color3.new(1, 1, 1), 1.5)
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
-- Aba Forja (estilo síntese): modos Forja e Alquimia, espaços para
-- preencher, preenchimento automático, nível fixo e configurações.
------------------------------------------------------------------------
local Q = Config.Forja.Quantidade
local forjaModo = "forja" -- "forja" ou "alquimia"
local slotsForja = {} -- ids dos itens colocados nos espaços
local nivelFixo = false
local FILTROS = {
	{ "Todos", 1, math.huge },
	{ "Nv 1-10", 1, 10 },
	{ "Nv 11-20", 11, 20 },
	{ "Nv 21-30", 21, 30 },
	{ "Nv 31+", 31, math.huge },
}
local filtroIdx = 1

local function capacidade()
	return forjaModo == "forja" and Q or 9
end

-- topo: modos, filtro de nível e engrenagem
local barraForja = novo("Frame", pgForja, { Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1 })
novo("UIListLayout", barraForja, {
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
})
local btnModoForja = botao(barraForja, {
	Name = "ModoForja",
	LayoutOrder = 1,
	Size = UDim2.fromScale(0.26, 1),
	Text = "⚒ Forja",
	Font = FONTE,
})
local btnModoAlq = botao(barraForja, {
	Name = "ModoAlquimia",
	LayoutOrder = 2,
	Size = UDim2.fromScale(0.26, 1),
	Text = "💰 Alquimia",
	Font = FONTE,
})
local btnFiltro =
	botao(barraForja, { Name = "FiltroNivel", LayoutOrder = 3, Size = UDim2.fromScale(0.3, 1), Text = "Nível: Todos" })
local btnEngrenagem = botao(
	barraForja,
	{ Name = "ConfigForja", LayoutOrder = 4, Size = UDim2.fromScale(0.12, 1), Text = "⚙", TextSize = 20 }
)

-- esquerda: bigorna com os espaços
local bigorna = novo("Frame", pgForja, {
	Position = UDim2.fromOffset(0, 42),
	Size = UDim2.new(0.47, -6, 1, -42),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BorderSizePixel = 0,
})
canto(bigorna, 12)
contorno(bigorna, Color3.fromRGB(150, 110, 60), 2)
novo("UIGradient", bigorna, {
	Rotation = 90,
	Color = ColorSequence.new(Color3.fromRGB(75, 58, 40), Color3.fromRGB(24, 21, 32)),
})
local lblBigorna = rotulo(bigorna, {
	Position = UDim2.fromOffset(0, 6),
	Size = UDim2.new(1, 0, 0, 20),
	Text = "⚒ FORJA",
	TextSize = 15,
	Font = FONTE,
	TextColor3 = Color3.fromRGB(255, 205, 120),
})
local gradeSlots = novo("Frame", bigorna, {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 30),
	Size = UDim2.fromOffset(3 * 56 + 2 * 6, 3 * 56 + 2 * 6),
	BackgroundTransparency = 1,
})
novo("UIGridLayout", gradeSlots, {
	CellSize = UDim2.fromOffset(56, 56),
	CellPadding = UDim2.fromOffset(6, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
})
local Y0 = 30 + 3 * 62
local lblResultado = rotulo(bigorna, {
	Position = UDim2.fromOffset(8, Y0 + 2),
	Size = UDim2.new(1, -16, 0, 18),
	Text = "",
	TextSize = 13,
	RichText = true,
})
local linhaBotoes = novo("Frame", bigorna, {
	Position = UDim2.fromOffset(8, Y0 + 24),
	Size = UDim2.new(1, -16, 0, 34),
	BackgroundTransparency = 1,
})
local btnAutoPreencher = botao(linhaBotoes, {
	Name = "AutoPreencher",
	Size = UDim2.new(0.62, -4, 1, 0),
	Text = "Preenchimento automático",
	TextSize = 12,
	TextWrapped = true,
	BackgroundColor3 = Color3.fromRGB(150, 75, 40),
})
local btnCombinar = botao(linhaBotoes, {
	Name = "Combinar",
	Position = UDim2.new(0.62, 4, 0, 0),
	Size = UDim2.new(0.38, -4, 1, 0),
	Text = "FORJAR!",
	TextSize = 16,
	Font = FONTE,
})
local btnNivelFixo = botao(bigorna, {
	Name = "NivelFixo",
	Position = UDim2.fromOffset(8, Y0 + 64),
	Size = UDim2.new(1, -16, 0, 26),
	Text = "",
	TextSize = 12,
	BackgroundColor3 = COR.painel,
})
local lblInfoForja = rotulo(bigorna, {
	Position = UDim2.fromOffset(8, Y0 + 96),
	Size = UDim2.new(1, -16, 1, -(Y0 + 100)),
	Text = "",
	TextSize = 11,
	Font = FONTE_TEXTO,
	TextWrapped = true,
	TextColor3 = COR.fraco,
	TextYAlignment = Enum.TextYAlignment.Top,
})

-- direita: itens livres da mochila
local colMochilaForja = novo("Frame", pgForja, {
	Position = UDim2.new(0.47, 6, 0, 42),
	Size = UDim2.new(0.53, -6, 1, -42),
	BackgroundColor3 = COR.painel2,
	BorderSizePixel = 0,
})
canto(colMochilaForja, 12)
local lblMochilaForja = rotulo(colMochilaForja, {
	Position = UDim2.fromOffset(10, 4),
	Size = UDim2.new(1, -20, 0, 20),
	Text = "",
	TextSize = 12,
	Font = FONTE_TEXTO,
	TextColor3 = COR.fraco,
	TextXAlignment = Enum.TextXAlignment.Left,
})
local gradeForja = novo("ScrollingFrame", colMochilaForja, {
	Position = UDim2.fromOffset(0, 26),
	Size = UDim2.new(1, 0, 1, -26),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 6,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
})
novo("UIPadding", gradeForja, {
	PaddingTop = UDim.new(0, 4),
	PaddingLeft = UDim.new(0, 8),
	PaddingRight = UDim.new(0, 8),
	PaddingBottom = UDim.new(0, 8),
})
novo("UIGridLayout", gradeForja, {
	CellSize = UDim2.fromOffset(56, 56),
	CellPadding = UDim2.fromOffset(6, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
})

-- janelinha de configurações (engrenagem)
local cfgForja = caixa(pgForja, {
	Name = "JanelaConfigForja",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(310, 236),
	Visible = false,
	ZIndex = 20,
	BackgroundTransparency = 0,
})
canto(cfgForja, 14)
contorno(cfgForja, Color3.fromRGB(200, 150, 80), 2)
rotulo(cfgForja, {
	Position = UDim2.fromOffset(12, 8),
	Size = UDim2.new(1, -24, 0, 22),
	Text = "⚙ Configurações da Forja",
	Font = FONTE,
	TextSize = 15,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 21,
})
local function cfgBotao(y, nome, cor)
	local b = botao(cfgForja, {
		Name = nome,
		Position = UDim2.fromOffset(12, y),
		Size = UDim2.new(1, -24, 0, 32),
		BackgroundColor3 = cor or COR.painel2,
		TextSize = 13,
		Text = "",
		ZIndex = 21,
	})
	return b
end
local btnCfgAuto = cfgBotao(38, "CfgAuto")
local btnCfgGrau = cfgBotao(76, "CfgGrau")
local btnCfgNivel = cfgBotao(114, "CfgNivel")
local btnCfgAgora = cfgBotao(152, "CfgAgora", Color3.fromRGB(150, 75, 40))
local btnCfgFechar = cfgBotao(194, "CfgFechar", Color3.fromRGB(70, 110, 160))
btnCfgFechar.Text = "Fechar"

local desenharForja -- definida abaixo

local function grausForjaveis()
	local l = {}
	for _, r in ipairs(Config.Raridades) do
		if r.forjavel ~= false then
			table.insert(l, r)
		end
	end
	return l
end

local function cfgAtual()
	return (estado and estado.configForja) or { auto = false, ate = "incomum", mesmoNivel = false }
end

local function enviarCfg(mudanca)
	local c = table.clone(cfgAtual())
	for k, v in pairs(mudanca) do
		c[k] = v
	end
	evConfigForja:FireServer(c)
end

btnEngrenagem.Activated:Connect(function()
	cfgForja.Visible = not cfgForja.Visible
	desenharForja()
end)
btnCfgFechar.Activated:Connect(function()
	cfgForja.Visible = false
end)
btnCfgAuto.Activated:Connect(function()
	enviarCfg({ auto = not cfgAtual().auto })
end)
btnCfgNivel.Activated:Connect(function()
	enviarCfg({ mesmoNivel = not cfgAtual().mesmoNivel })
end)
btnCfgGrau.Activated:Connect(function()
	local graus = grausForjaveis()
	local atual = 1
	for i, r in ipairs(graus) do
		if r.id == cfgAtual().ate then
			atual = i
		end
	end
	enviarCfg({ ate = graus[atual % #graus + 1].id })
end)
btnCfgAgora.Activated:Connect(function()
	evForjarAuto:FireServer(cfgAtual().ate, cfgAtual().mesmoNivel)
end)

local function itemLivre(it)
	if vestido(it.id) then
		return false
	end
	local f = FILTROS[filtroIdx]
	local nv = it.nivel or 1
	return nv >= f[2] and nv <= f[3]
end

local function noSlot(id)
	for _, s in ipairs(slotsForja) do
		if s == id then
			return true
		end
	end
	return false
end

-- pode colocar este item nos espaços agora?
local function aceita(it)
	if #slotsForja >= capacidade() or noSlot(it.id) or not itemLivre(it) then
		return false
	end
	if forjaModo == "alquimia" then
		return true
	end
	if raridade(it.raridade).forjavel == false then
		return false
	end
	local primeiro = slotsForja[1] and itemPorId(slotsForja[1])
	if primeiro then
		if primeiro.raridade ~= it.raridade or primeiro.slot ~= it.slot then
			return false
		end
		if nivelFixo and (primeiro.nivel or 1) ~= (it.nivel or 1) then
			return false
		end
	end
	return true
end

local function valorAlquimia(it)
	return math.floor((Config.ValorVenda[it.raridade] or 1) * (1 + 0.05 * ((it.nivel or 1) - 1)) + 0.5)
end

btnModoForja.Activated:Connect(function()
	forjaModo = "forja"
	slotsForja = {}
	desenharForja()
end)
btnModoAlq.Activated:Connect(function()
	forjaModo = "alquimia"
	slotsForja = {}
	desenharForja()
end)
btnFiltro.Activated:Connect(function()
	filtroIdx = filtroIdx % #FILTROS + 1
	slotsForja = {}
	desenharForja()
end)
btnNivelFixo.Activated:Connect(function()
	nivelFixo = not nivelFixo
	slotsForja = {}
	desenharForja()
end)

btnAutoPreencher.Activated:Connect(function()
	if not estado then
		return
	end
	slotsForja = {}
	local livres = {}
	for _, it in ipairs(estado.inventario) do
		if itemLivre(it) then
			table.insert(livres, it)
		end
	end
	table.sort(livres, function(a, b)
		local _, ra = raridade(a.raridade)
		local _, rb = raridade(b.raridade)
		if ra ~= rb then
			return ra < rb
		end
		return a.valor < b.valor
	end)
	if forjaModo == "alquimia" then
		for i = 1, math.min(9, #livres) do
			table.insert(slotsForja, livres[i].id)
		end
	else
		-- o primeiro grupo (raridade, e nível se "nível fixo") que tem itens suficientes
		local grupos, ordem = {}, {}
		for _, it in ipairs(livres) do
			if raridade(it.raridade).forjavel ~= false then
				local chave = it.raridade .. "|" .. it.slot .. (nivelFixo and ("#" .. (it.nivel or 1)) or "")
				if not grupos[chave] then
					grupos[chave] = {}
					table.insert(ordem, chave)
				end
				table.insert(grupos[chave], it)
			end
		end
		for _, chave in ipairs(ordem) do
			if #grupos[chave] >= Q then
				for i = 1, Q do
					table.insert(slotsForja, grupos[chave][i].id)
				end
				break
			end
		end
	end
	desenharForja()
end)

btnCombinar.Activated:Connect(function()
	if forjaModo == "forja" and #slotsForja == Q then
		evForjar:FireServer(slotsForja)
	elseif forjaModo == "alquimia" and #slotsForja >= 1 then
		evAlquimia:FireServer(slotsForja)
	else
		return
	end
	slotsForja = {}
end)

desenharForja = function()
	if not estado then
		return
	end
	-- tira dos espaços o que não existe mais
	local validos = {}
	for _, id in ipairs(slotsForja) do
		if itemPorId(id) and not vestido(id) then
			table.insert(validos, id)
		end
	end
	slotsForja = validos

	local alq = forjaModo == "alquimia"
	btnModoForja.BackgroundColor3 = alq and COR.painel or Color3.fromRGB(215, 110, 45)
	btnModoAlq.BackgroundColor3 = alq and Color3.fromRGB(200, 160, 40) or COR.painel
	btnFiltro.Text = "Nível: " .. FILTROS[filtroIdx][1] .. ""
	lblBigorna.Text = alq and "💰 ALQUIMIA" or "⚒ FORJA"
	btnNivelFixo.Visible = not alq
	btnNivelFixo.Text = (nivelFixo and "✅" or "⬜") .. "  Nível fixo (só itens do mesmo nível)"

	-- espaços
	for _, c in ipairs(gradeSlots:GetChildren()) do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	for i = 1, capacidade() do
		local id = slotsForja[i]
		local it = id and itemPorId(id)
		if it then
			local b = cartaoItem(gradeSlots, it, { Name = "Espaco_" .. i, LayoutOrder = i })
			b.Activated:Connect(function()
				table.remove(slotsForja, i)
				desenharForja()
			end)
		else
			local vazio = novo("Frame", gradeSlots, {
				Name = "Espaco_" .. i,
				LayoutOrder = i,
				BackgroundColor3 = Color3.fromRGB(15, 13, 20),
				BackgroundTransparency = 0.15,
			})
			canto(vazio, 10)
			contorno(vazio, Color3.fromRGB(110, 90, 60), 2)
		end
	end

	-- resultado e custo
	local primeiro = slotsForja[1] and itemPorId(slotsForja[1])
	local pronto
	if alq then
		local total = 0
		for _, id in ipairs(slotsForja) do
			total += valorAlquimia(itemPorId(id))
		end
		pronto = #slotsForja >= 1
		lblResultado.Text = pronto and string.format('Vira <font color="#ffcd46"><b>%d ouro</b></font>', total)
			or "Coloque de 1 a 9 itens"
		lblInfoForja.Text =
			"Transforma qualquer item em ouro.\n• Materiais: 1 a 9 itens\n• Resultado: os itens somem e você ganha ouro"
	else
		local custo = primeiro and (Config.Forja.Custo[primeiro.raridade] or 0) or 0
		if primeiro then
			local _, ri = raridade(primeiro.raridade)
			local prox = Config.Raridades[ri + 1]
			local cat = slotInfo(primeiro.slot)
			lblResultado.Text = string.format(
				'→ %s %s <font color="#%s"><b>%s</b></font> · %d ouro',
				cat.icone,
				cat.nome,
				prox.cor:ToHex(),
				prox.nome,
				custo
			)
		else
			lblResultado.Text = "Coloque " .. Q .. " itens iguais (categoria e raridade)"
		end
		pronto = #slotsForja == Q and estado.ouro >= custo
		lblInfoForja.Text = "Junte "
			.. Q
			.. " equipamentos da MESMA categoria e do mesmo grau para obter um de grau superior. O novo fica com o maior nível entre eles."
	end
	btnCombinar.BackgroundColor3 = pronto and COR.verde or COR.cinza
	btnCombinar.AutoButtonColor = pronto

	-- mochila (só itens livres)
	local assinaturaF = assinaturaItens(
		forjaModo .. "|" .. filtroIdx .. "|" .. tostring(nivelFixo) .. "|" .. table.concat(slotsForja, ";")
	)
	local mudouForja = assinaturaF ~= ultimaGradeForja
	ultimaGradeForja = assinaturaF
	if mudouForja then
		for _, c in ipairs(gradeForja:GetChildren()) do
			if c:IsA("GuiButton") then
				c:Destroy()
			end
		end
	end
	local lista = {}
	for _, it in ipairs(estado.inventario) do
		if itemLivre(it) and not noSlot(it.id) then
			table.insert(lista, it)
		end
	end
	table.sort(lista, function(a, b)
		local _, ra = raridade(a.raridade)
		local _, rb = raridade(b.raridade)
		if ra ~= rb then
			return ra < rb
		end
		return (a.nivel or 1) > (b.nivel or 1)
	end)
	lblMochilaForja.Text = #lista == 0 and "Nenhum item livre com esse filtro"
		or "Toque nos itens para colocar na forja"
	for i, it in ipairs(mudouForja and lista or {}) do
		local b = cartaoItem(gradeForja, it, { Name = "ItemForja_" .. i, LayoutOrder = i })
		if not aceita(it) then
			local veu = novo("Frame", b, {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Color3.new(0, 0, 0),
				BackgroundTransparency = 0.55,
				ZIndex = 5,
			})
			canto(veu, 10)
		end
		b.Activated:Connect(function()
			if aceita(it) then
				table.insert(slotsForja, it.id)
				desenharForja()
			end
		end)
	end

	-- configurações
	local c = cfgAtual()
	btnCfgAuto.Text = (c.auto and "✅" or "⬜") .. "  Combinação automática ao farmar"
	btnCfgAuto.BackgroundColor3 = c.auto and Color3.fromRGB(50, 130, 70) or COR.painel2
	local rAte = raridade(c.ate)
	btnCfgGrau.Text = "Grau máximo: " .. rAte.nome .. ""
	btnCfgGrau.TextColor3 = rAte.cor
	btnCfgNivel.Text = (c.mesmoNivel and "✅" or "⬜") .. "  Apenas itens do mesmo nível"
	btnCfgAgora.Text = "Combinar tudo agora (até " .. rAte.nome .. ")"
end

local function podeForjarAlgo()
	if not estado then
		return false
	end
	local cont = {}
	for _, it in ipairs(estado.inventario) do
		if not vestido(it.id) and raridade(it.raridade).forjavel ~= false then
			local chave = it.raridade .. "|" .. it.slot
			cont[chave] = (cont[chave] or 0) + 1
			if cont[chave] >= Q and estado.ouro >= (Config.Forja.Custo[it.raridade] or 0) then
				return true
			end
		end
	end
	return false
end

------------------------------------------------------------------------
-- Aba Treinamento: sobe atributos pagando ouro
------------------------------------------------------------------------
rotulo(pgTreino, {
	Size = UDim2.new(1, 0, 0, 22),
	Text = "Treine o herói com ouro. Cada nível fica mais caro: farme para treinar!",
	TextSize = 13,
	Font = FONTE_TEXTO,
	TextColor3 = COR.fraco,
	TextXAlignment = Enum.TextXAlignment.Left,
})
local listaTreino = novo("Frame", pgTreino, {
	Position = UDim2.fromOffset(0, 28),
	Size = UDim2.new(1, 0, 1, -28),
	BackgroundTransparency = 1,
})
novo("UIGridLayout", listaTreino, {
	CellSize = UDim2.new(0.5, -5, 0.5, -5),
	CellPadding = UDim2.fromOffset(10, 10),
	SortOrder = Enum.SortOrder.LayoutOrder,
})
local linhasTreino = {}
for i, tr in ipairs(Config.Treino) do
	local c = novo("Frame", listaTreino, { LayoutOrder = i, BackgroundColor3 = COR.painel2, BorderSizePixel = 0 })
	canto(c, 12)
	contorno(c, COR.borda, 2)
	local medalha = novo("Frame", c, {
		Position = UDim2.fromOffset(10, 10),
		Size = UDim2.fromOffset(54, 54),
		BackgroundColor3 = COR.madeira,
	})
	canto(medalha, 27)
	contorno(medalha, COR.dourado, 2.5)
	rotulo(medalha, { Size = UDim2.fromScale(1, 1), Text = tr.icone, TextSize = 28 })
	rotulo(c, {
		Position = UDim2.fromOffset(74, 8),
		Size = UDim2.new(1, -84, 0, 22),
		Text = tr.nome,
		TextSize = 18,
		TextColor3 = Color3.fromRGB(255, 220, 130),
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local nv = rotulo(c, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 10),
		Size = UDim2.fromOffset(80, 20),
		Text = "Nv 0",
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Right,
	})
	local efeito = rotulo(c, {
		Position = UDim2.fromOffset(74, 32),
		Size = UDim2.new(1, -84, 0, 32),
		Text = "",
		TextSize = 12,
		Font = FONTE_TEXTO,
		TextColor3 = COR.fraco,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	})
	local b = botao(c, {
		Name = "Treinar_" .. tr.id,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -8),
		Size = UDim2.new(1, -20, 0, 34),
		Text = "",
		TextSize = 15,
		BackgroundColor3 = COR.verde,
	})
	b.Activated:Connect(function()
		evTreinar:FireServer(tr.id)
	end)
	linhasTreino[tr.id] = { nv = nv, efeito = efeito, botao = b, tr = tr }
end

local function desenharTreino()
	if not estado or not estado.treino then
		return
	end
	for id, l in pairs(linhasTreino) do
		local n = estado.treino[id] or 0
		local tr = l.tr
		l.nv.Text = "Nv " .. n .. (n >= tr.max and " (máx)" or "")
		local total
		if id == "precisao" then
			total = string.format("+%.1f%% de crítico", n * tr.valor * 100)
		elseif id == "ganancia" then
			total = string.format("+%d%% de ouro", math.floor(n * tr.valor * 100 + 0.5))
		elseif id == "vitalidade" then
			total = string.format("+%d de vida", n * tr.valor)
		else
			total = string.format("+%d de dano", math.floor(n * tr.valor + 0.5))
		end
		l.efeito.Text = tr.texto:gsub("%%d", tostring(tr.valor)) .. "\nTotal agora: " .. total
		local custo = Config.CustoTreino(tr, n)
		local pode = n < tr.max and estado.ouro >= custo
		l.botao.Text = n >= tr.max and "MÁXIMO" or ("Treinar  💰 " .. custo)
		l.botao.BackgroundColor3 = pode and COR.verde or COR.cinza
		l.botao.AutoButtonColor = pode
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
		Font = FONTE,
	})
	rotulo(pagina, {
		Position = UDim2.fromOffset(0, 132),
		Size = UDim2.new(1, 0, 0, 40),
		Text = texto,
		TextSize = 13,
		Font = FONTE_TEXTO,
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
-- Janela do Portal: mundos (com imagem 3D) e fases (com o rosto do inimigo)
------------------------------------------------------------------------
local jPortal, corpoPortal, _, fecharPortal = criarJanela("🌀 Portal")
fecharPortal.Activated:Connect(fecharJanelas)

local ArteReplicada = ReplicatedStorage:WaitForChild("Arte", 10)

-- Coloca uma cópia 3D de um modelo dentro de um ViewportFrame e aponta a câmera
local function retrato(vp, modelo, enquadrar)
	local mundo = novo("WorldModel", vp)
	local m = modelo:Clone()
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
		elseif d:IsA("LuaSourceContainer") or d:IsA("ParticleEmitter") then
			d:Destroy()
		end
	end
	m.Parent = mundo
	local cam = novo("Camera", vp, { FieldOfView = 40 })
	vp.CurrentCamera = cam
	enquadrar(m, cam)
	return m
end

local function retratoInimigo(vp, nomeModelo)
	local pasta = ArteReplicada and ArteReplicada:FindFirstChild("Inimigos")
	local original = pasta and pasta:FindFirstChild(nomeModelo)
	if not original then
		return
	end
	retrato(vp, original, function(m, cam)
		local raiz = m:FindFirstChild("HumanoidRootPart", true)
			or m.PrimaryPart
			or m:FindFirstChildWhichIsA("BasePart", true)
		-- acha a PEÇA "Head" (alguns modelos têm uma pasta com esse nome)
		local cabeca = raiz
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("BasePart") and d.Name == "Head" then
				cabeca = d
				break
			end
		end
		-- enquadra rosto e ombros
		local alvo = cabeca.Position - Vector3.new(0, cabeca.Size.Y * 0.35, 0)
		local frente = raiz.CFrame.LookVector
		local dist = math.max(4.5, cabeca.Size.Y * 4)
		cam.CFrame = CFrame.lookAt(alvo + frente * dist + Vector3.new(0, 0.4, 0), alvo)
	end)
end

local function imagemMundo(vp)
	local pasta = ArteReplicada and ArteReplicada:FindFirstChild("Cenario")
	if not pasta then
		return
	end
	local cena = novo("Model", vp)
	local function poe(nome, pos, escala, rotY)
		local o = pasta:FindFirstChild(nome)
		if not o then
			return
		end
		local m = o:Clone()
		m:ScaleTo(m:GetScale() * escala)
		m:PivotTo(CFrame.new(pos) * CFrame.Angles(0, math.rad(rotY or 0), 0))
		local cx, tam = m:GetBoundingBox()
		m:PivotTo(m:GetPivot() + Vector3.new(0, pos.Y - (cx.Position.Y - tam.Y / 2), 0))
		m.Parent = cena
	end
	poe("casaFeudal", Vector3.new(-9, 0, 6), 0.35, 25)
	poe("torii", Vector3.new(2, 0, 2), 0.55, 0)
	poe("cerejeira", Vector3.new(9, 0, 4), 0.2, 0)
	poe("bambu", Vector3.new(-2, 0, 10), 0.16, 0)
	poe("cerejeira", Vector3.new(-5, 0, -2), 0.14, 90)
	local chao = Instance.new("Part")
	chao.Anchored = true
	chao.Size = Vector3.new(60, 1, 60)
	chao.Position = Vector3.new(0, -0.5, 0)
	chao.Color = Color3.fromRGB(100, 165, 75)
	chao.Material = Enum.Material.Grass
	chao.Parent = cena
	local cam = novo("Camera", vp, { FieldOfView = 45 })
	vp.CurrentCamera = cam
	cam.CFrame = CFrame.lookAt(Vector3.new(0, 7, -16), Vector3.new(0, 3, 4))
	vp.Ambient = Color3.fromRGB(170, 160, 150)
	vp.LightColor = Color3.fromRGB(255, 240, 220)
	vp.LightDirection = Vector3.new(-0.5, -1, 0.4)
end

-- coluna dos mundos
local colMundos = novo("Frame", corpoPortal, { Size = UDim2.new(0.3, -6, 1, 0), BackgroundTransparency = 1 })
novo("UIListLayout", colMundos, { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
local mundoSel = 1
local botoesMundo = {}

local function faseIndice(mundo, numero)
	for i, f in ipairs(Config.Fases) do
		if f.mundo == mundo and f.numero == numero then
			return i
		end
	end
end

for i, m in ipairs(Config.Mundos) do
	local existe = faseIndice(i, 1) ~= nil
	local b = novo("ImageButton", colMundos, {
		Name = "Mundo_" .. i,
		LayoutOrder = i,
		Size = UDim2.new(1, 0, 0, i == 1 and 150 or 70),
		BackgroundColor3 = COR.painel2,
		AutoButtonColor = true,
		Image = "",
	})
	canto(b, 12)
	local borda = contorno(b, COR.borda, 2)
	if i == 1 then
		local vp = novo("ViewportFrame", b, {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(150, 200, 255),
		})
		canto(vp, 12)
		novo("UIGradient", vp, {
			Rotation = 90,
			Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 220, 255)),
		})
		task.spawn(imagemMundo, vp)
		local sombra = novo("Frame", b, {
			Position = UDim2.new(0, 0, 1, -46),
			Size = UDim2.new(1, 0, 0, 46),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.35,
			ZIndex = 2,
		})
		canto(sombra, 12)
	end
	rotulo(b, {
		Position = UDim2.new(0, 10, 1, -44),
		Size = UDim2.new(1, -20, 0, 20),
		Text = "Mundo " .. i,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
	})
	rotulo(b, {
		Position = UDim2.new(0, 10, 1, -24),
		Size = UDim2.new(1, -20, 0, 18),
		Text = existe and m.nome or ("🔒 " .. m.nome .. " (em breve)"),
		TextSize = 12,
		TextColor3 = COR.dourado,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 3,
	})
	botoesMundo[i] = { botao = b, borda = borda, existe = existe }
	b.Activated:Connect(function()
		if existe then
			mundoSel = i
			desenhar()
		end
	end)
end

-- coluna das fases
local colFases = novo("Frame", corpoPortal, {
	Position = UDim2.new(0.3, 6, 0, 0),
	Size = UDim2.new(0.7, -6, 1, 0),
	BackgroundColor3 = COR.painel2,
	BorderSizePixel = 0,
})
canto(colFases, 12)
contorno(colFases, COR.borda, 2)
local lblMundoSel = rotulo(colFases, {
	Position = UDim2.fromOffset(12, 6),
	Size = UDim2.new(1, -24, 0, 24),
	Text = "",
	TextSize = 17,
	TextColor3 = Color3.fromRGB(255, 220, 130),
	TextXAlignment = Enum.TextXAlignment.Left,
})
local gradeFases = novo("Frame", colFases, {
	Position = UDim2.fromOffset(10, 34),
	Size = UDim2.new(1, -20, 1, -96),
	BackgroundTransparency = 1,
})
novo("UIGridLayout", gradeFases, {
	CellSize = UDim2.new(0.2, -6, 0.5, -4),
	CellPadding = UDim2.fromOffset(6, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
})

-- drops do chefe embaixo
local caixaDrops = novo("Frame", colFases, {
	Position = UDim2.new(0, 10, 1, -58),
	Size = UDim2.new(1, -20, 0, 50),
	BackgroundColor3 = Color3.fromRGB(26, 18, 30),
	BorderSizePixel = 0,
})
canto(caixaDrops, 10)
contorno(caixaDrops, Color3.fromRGB(150, 80, 220), 1.5)
rotulo(caixaDrops, {
	Position = UDim2.fromOffset(10, 2),
	Size = UDim2.new(1, -20, 0, 18),
	Text = "☠ Drops do chefe Pen (1-10)",
	TextSize = 12,
	TextColor3 = Color3.fromRGB(220, 170, 255),
	TextXAlignment = Enum.TextXAlignment.Left,
})
local listaDrops = novo("Frame", caixaDrops, {
	Position = UDim2.fromOffset(8, 22),
	Size = UDim2.new(1, -16, 0, 24),
	BackgroundTransparency = 1,
})
novo("UIListLayout", listaDrops, {
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 4),
	SortOrder = Enum.SortOrder.LayoutOrder,
	VerticalAlignment = Enum.VerticalAlignment.Center,
})
do
	local ordem = 0
	local function chip(texto, cor)
		ordem += 1
		local c = rotulo(listaDrops, {
			LayoutOrder = ordem,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 20),
			Text = " " .. texto .. " ",
			TextSize = 11,
			TextColor3 = cor,
			BackgroundTransparency = 0.2,
			BackgroundColor3 = Color3.fromRGB(14, 10, 18),
		})
		canto(c, 6)
		contorno(c, cor, 1)
	end
	local d = Config.DropsChefe
	chip("💰 " .. d.Ouro, COR.ouro)
	for _, par in ipairs(d.Equipamento) do
		local r = raridade(par[1])
		chip(r.nome .. " " .. math.floor(par[2] * 100 + 0.5) .. "%", r.cor)
	end
	for _, esp in ipairs(d.Especiais) do
		local r = raridade(esp.raridade)
		chip(esp.icone .. " " .. esp.nome .. " " .. (esp.chance * 100) .. "%", r.cor)
	end
end

-- cartões das fases (montados uma vez; o estado é atualizado em desenharPortal)
local cartoesFase = {}
local function montarCartoes(mundo)
	for _, c in ipairs(gradeFases:GetChildren()) do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	cartoesFase = {}
	for n = 1, Config.Mundos[mundo].totalFases do
		local idx = faseIndice(mundo, n)
		local f = idx and Config.Fases[idx]
		local b = novo("ImageButton", gradeFases, {
			Name = "Fase_" .. n,
			LayoutOrder = n,
			BackgroundColor3 = f and f.chefe and Color3.fromRGB(60, 25, 80) or Color3.fromRGB(40, 32, 28),
			AutoButtonColor = true,
			Image = "",
		})
		canto(b, 10)
		local borda = contorno(b, f and f.chefe and Color3.fromRGB(190, 90, 255) or COR.borda, f and f.chefe and 3 or 2)
		local vp = novo("ViewportFrame", b, {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Ambient = Color3.fromRGB(190, 180, 170),
			LightColor = Color3.fromRGB(255, 240, 220),
		})
		canto(vp, 10)
		if f then
			task.spawn(retratoInimigo, vp, f.modelo)
		end
		vp:SetAttribute("Retrato", true)
		local faixa = novo("Frame", b, {
			Position = UDim2.new(0, 0, 1, -30),
			Size = UDim2.new(1, 0, 0, 30),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.35,
			ZIndex = 2,
		})
		canto(faixa, 10)
		rotulo(b, {
			Position = UDim2.fromOffset(5, 3),
			Size = UDim2.new(1, -10, 0, 18),
			Text = mundo .. "-" .. n,
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 3,
		})
		if f and f.chefe then
			rotulo(b, {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -4, 0, 4),
				Size = UDim2.fromOffset(46, 16),
				Text = "CHEFE",
				TextSize = 11,
				TextColor3 = Color3.fromRGB(255, 120, 255),
				ZIndex = 3,
			})
		end
		local sub = rotulo(b, {
			Position = UDim2.new(0, 0, 1, -29),
			Size = UDim2.new(1, 0, 0, 14),
			Text = f and ("Nv " .. f.nivel) or "em breve",
			TextSize = 12,
			ZIndex = 3,
		})
		local estadoTxt = rotulo(b, {
			Position = UDim2.new(0, 0, 1, -15),
			Size = UDim2.new(1, 0, 0, 13),
			Text = "",
			TextSize = 10,
			TextColor3 = COR.fraco,
			ZIndex = 3,
		})
		local veu = novo("Frame", b, {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.45,
			ZIndex = 4,
			Visible = false,
		})
		canto(veu, 10)
		local cadeado = rotulo(veu, { Size = UDim2.fromScale(1, 1), Text = "🔒", TextSize = 26, ZIndex = 5 })
		cadeado.Visible = true
		b.Activated:Connect(function()
			if idx and estado and idx <= estado.faseMax and idx ~= estado.faseIdx then
				evIrFase:FireServer(idx)
				fecharJanelas()
			end
		end)
		cartoesFase[n] =
			{ idx = idx, borda = borda, sub = sub, estado = estadoTxt, veu = veu, chefe = f and f.chefe, vp = vp }
	end
end
local mundoMontado

painelFase.Activated:Connect(function()
	abrirJanela(jPortal)
	desenhar()
end)

local function desenharPortal()
	if mundoMontado ~= mundoSel then
		montarCartoes(mundoSel)
		mundoMontado = mundoSel
	end
	for i, info in pairs(botoesMundo) do
		info.borda.Color = (i == mundoSel) and COR.dourado or COR.borda
		info.borda.Thickness = (i == mundoSel) and 3 or 2
	end
	lblMundoSel.Text = "Mundo " .. mundoSel .. " · " .. Config.Mundos[mundoSel].nome
	for _, c in pairs(cartoesFase) do
		local atual = c.idx and estado and c.idx == estado.faseIdx
		local liberada = c.idx and estado and c.idx <= estado.faseMax
		c.veu.Visible = not liberada
		-- fase bloqueada mostra só a sombra do inimigo
		c.vp.ImageColor3 = liberada and Color3.new(1, 1, 1) or Color3.new(0, 0, 0)
		c.vp.ImageTransparency = liberada and 0 or 0.15
		c.estado.Text = atual and "▶ VOCÊ ESTÁ AQUI" or (liberada and "toque para ir" or "")
		c.estado.TextColor3 = atual and Color3.fromRGB(120, 255, 140) or COR.fraco
		if atual then
			c.borda.Color = Color3.fromRGB(120, 255, 140)
		elseif c.chefe then
			c.borda.Color = Color3.fromRGB(190, 90, 255)
		else
			c.borda.Color = liberada and COR.dourado or COR.borda
		end
	end
end

------------------------------------------------------------------------
------------------------------------------------------------------------
-- Aba Avatar: skins dos inimigos (chance mínima de drop), trocam o corpo e dão buff
------------------------------------------------------------------------
local topoAvatar = novo("Frame", pgAvatar, { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1 })
rotulo(topoAvatar, {
	Size = UDim2.new(1, -330, 1, 0),
	Text = "Derrote inimigos: chance mínima de ganhar o avatar deles!",
	TextSize = 12,
	Font = FONTE_TEXTO,
	TextColor3 = COR.fraco,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextWrapped = true,
})
local btnMeuVisual = botao(topoAvatar, {
	Name = "MeuVisual",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -168, 0, 0),
	Size = UDim2.fromOffset(150, 28),
	Text = "🙂 Usar meu visual",
	TextSize = 12,
})
btnMeuVisual.Activated:Connect(function()
	evAvatar:FireServer(0)
end)
local btnEsconder = botao(topoAvatar, {
	Name = "EsconderEquip",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.fromScale(1, 0),
	Size = UDim2.fromOffset(162, 28),
	Text = "👁 Equipamentos: visíveis",
	TextSize = 12,
})
btnEsconder.Activated:Connect(function()
	if estado then
		evEsconderEquip:FireServer(not estado.esconderEquip)
	end
end)

local gradeAvatar = novo("Frame", pgAvatar, {
	Position = UDim2.fromOffset(0, 36),
	Size = UDim2.new(1, 0, 1, -36),
	BackgroundTransparency = 1,
})
novo("UIGridLayout", gradeAvatar, {
	CellSize = UDim2.new(0.2, -6, 0.5, -4),
	CellPadding = UDim2.fromOffset(6, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
})

local cartoesAvatar = {}
for idx, f in ipairs(Config.Fases) do
	local rarId = Config.Avatares.Raridade[idx]
	local r = raridade(rarId)
	local b = novo("ImageButton", gradeAvatar, {
		Name = "Avatar_" .. idx,
		LayoutOrder = idx,
		BackgroundColor3 = Color3.new(1, 1, 1),
		AutoButtonColor = true,
		Image = "",
	})
	canto(b, 10)
	novo("UIGradient", b, {
		Rotation = 90,
		Color = ColorSequence.new(r.cor:Lerp(Color3.new(1, 1, 1), 0.1), r.cor:Lerp(Color3.new(0, 0, 0), 0.7)),
	})
	local borda = contorno(b, r.corBorda or r.cor, 2)
	local vp = novo("ViewportFrame", b, {
		Size = UDim2.new(1, 0, 1, -44),
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(190, 180, 170),
		LightColor = Color3.fromRGB(255, 240, 220),
		ZIndex = 2,
	})
	task.spawn(retratoInimigo, vp, f.modelo)
	rotulo(b, {
		Position = UDim2.fromOffset(4, 2),
		Size = UDim2.new(1, -8, 0, 14),
		Text = "T" .. select(2, raridade(rarId)) .. " " .. r.nome,
		TextSize = 11,
		TextColor3 = r.corBorda or Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
	})
	local faixa = novo("Frame", b, {
		Position = UDim2.new(0, 0, 1, -46),
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.3,
		ZIndex = 3,
	})
	canto(faixa, 10)
	rotulo(faixa, {
		Position = UDim2.fromOffset(4, 1),
		Size = UDim2.new(1, -8, 0, 15),
		Text = f.monstro,
		TextSize = 11,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 4,
	})
	local info = rotulo(faixa, {
		Position = UDim2.fromOffset(4, 16),
		Size = UDim2.new(1, -8, 0, 28),
		Text = "",
		TextSize = 10,
		Font = FONTE_TEXTO,
		TextColor3 = COR.fraco,
		TextWrapped = true,
		ZIndex = 4,
	})
	local veu = novo("Frame", b, {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 5,
		Visible = false,
	})
	rotulo(
		veu,
		{ Position = UDim2.fromScale(0, 0.15), Size = UDim2.new(1, 0, 0, 30), Text = "🔒", TextSize = 24, ZIndex = 6 }
	)
	b.Activated:Connect(function()
		if estado and table.find(estado.avatares or {}, idx) then
			evAvatar:FireServer(idx)
		end
	end)
	cartoesAvatar[idx] = { vp = vp, info = info, veu = veu, borda = borda, r = r, rarId = rarId }
end

local function desenharAvatares()
	if not estado then
		return
	end
	btnEsconder.Text = estado.esconderEquip and "🙈 Equipamentos: escondidos" or "👁 Equipamentos: visíveis"
	btnEsconder.BackgroundColor3 = estado.esconderEquip and COR.cinza or COR.madeira
	local chanceN = string.format("%.2f%%", Config.Avatares.ChanceNormal * 100)
	local chanceC = string.format("%.0f%%", Config.Avatares.ChanceChefe * 100)
	for idx, c in pairs(cartoesAvatar) do
		local tem = table.find(estado.avatares or {}, idx) ~= nil
		local usando = estado.avatarAtivo == idx
		c.veu.Visible = not tem
		c.vp.ImageColor3 = tem and Color3.new(1, 1, 1) or Color3.new(0, 0, 0)
		local buff = Config.Avatares.Buff[c.rarId]
		if usando then
			c.info.Text = "▶ USANDO\n" .. buff.texto
			c.info.TextColor3 = Color3.fromRGB(120, 255, 140)
			c.borda.Color = Color3.fromRGB(120, 255, 140)
			c.borda.Thickness = 3
		elseif tem then
			c.info.Text = "Toque para usar\n" .. buff.texto
			c.info.TextColor3 = COR.texto
			c.borda.Color = c.r.corBorda or c.r.cor
			c.borda.Thickness = 2
		else
			c.info.Text = "Chance: " .. (Config.Fases[idx].chefe and chanceC or chanceN) .. "\n" .. buff.texto
			c.info.TextColor3 = COR.fraco
			c.borda.Color = COR.borda
			c.borda.Thickness = 2
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
	btnRepetir.Text = estado.repetir and "🔁 Repetir fase: SIM" or "🔁 Repetir fase: NÃO"
	btnRepetir.BackgroundColor3 = estado.repetir and COR.verde or COR.madeira
	killTxt.Text = estado.kills .. " / " .. estado.meta .. "  " .. f.monstro
	TweenService
		:Create(
			killCheio,
			TweenInfo.new(0.2),
			{ Size = UDim2.fromScale(math.clamp(estado.kills / estado.meta, 0, 1), 1) }
		)
		:Play()

	bolinhas.forja.Visible = podeForjarAlgo()

	if jMenu.Visible then
		if abaAtual == "mochila" then
			desenharMochila()
		elseif abaAtual == "treino" then
			desenharTreino()
		elseif abaAtual == "avatar" then
			desenharAvatares()
		elseif abaAtual == "forja" then
			desenharForja()
		end
	end
	if jPortal.Visible then
		desenharPortal()
	end
end

evVida.OnClientEvent:Connect(function(vida, maximo)
	vidaTxt.Text = vida .. " / " .. maximo
	TweenService:Create(vidaCheio, TweenInfo.new(0.15), { Size = UDim2.fromScale(math.clamp(vida / maximo, 0, 1), 1) })
		:Play()
end)

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
	Size = UDim2.new(0.6, 0, 0, 74),
	Visible = false,
})
novo("UISizeConstraint", barraChefe, { MaxSize = Vector2.new(480, 74) })
canto(barraChefe, 12)
contorno(barraChefe, Color3.fromRGB(190, 90, 255), 2.5)
local lblChefe = rotulo(barraChefe, {
	Position = UDim2.fromOffset(12, 3),
	Size = UDim2.new(1, -24, 0, 18),
	Text = "",
	TextSize = 15,
	Font = FONTE,
	TextColor3 = Color3.fromRGB(225, 185, 255),
})
local _, chefeCheio, chefeTxt = barra(barraChefe, {
	Position = UDim2.fromOffset(12, 23),
	Size = UDim2.new(1, -24, 0, 16),
}, Color3.fromRGB(190, 90, 255))

-- Drops do chefe embaixo da barra de vida
local function chipsDrops(pai)
	local lista = novo("Frame", pai, { BackgroundTransparency = 1 })
	novo("UIListLayout", lista, {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	})
	local ordem = 0
	local function chip(texto, cor)
		ordem += 1
		local c = rotulo(lista, {
			LayoutOrder = ordem,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 18),
			Text = " " .. texto .. " ",
			TextSize = 11,
			Font = FONTE,
			TextColor3 = cor,
			BackgroundTransparency = 0.25,
			BackgroundColor3 = Color3.fromRGB(14, 12, 22),
		})
		canto(c, 6)
		contorno(c, cor, 1)
	end
	local d = Config.DropsChefe
	chip("💰 " .. d.Ouro, COR.ouro)
	for _, par in ipairs(d.Equipamento) do
		local r = raridade(par[1])
		chip(r.nome .. " " .. math.floor(par[2] * 100 + 0.5) .. "%", r.cor)
	end
	for _, esp in ipairs(d.Especiais) do
		local r = raridade(esp.raridade)
		chip(esp.icone .. " " .. esp.nome .. " " .. (esp.chance * 100) .. "%", r.cor)
	end
	return lista
end
local dropsChefe = chipsDrops(barraChefe)
dropsChefe.Position = UDim2.fromOffset(12, 46)
dropsChefe.Size = UDim2.new(1, -24, 0, 20)
rotulo(barraChefe, {
	Position = UDim2.new(1, -112, 0, 3),
	Size = UDim2.fromOffset(100, 18),
	Text = "DROPS ▼",
	TextSize = 10,
	TextColor3 = COR.fraco,
	TextXAlignment = Enum.TextXAlignment.Right,
}).Text =
	"DROPS"

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
			local resta = math.max(0, (chefe:GetAttribute("Fim") or 0) - workspace:GetServerTimeNow())
			chefeTxt.Text = string.format("%d / %d   ⏱ %d:%02d", vida, maximo, resta // 60, resta % 60)
			chefeCheio.Size = UDim2.fromScale(math.clamp(vida / maximo, 0, 1), 1)
		end
	end
end)

evPedirEstado:FireServer()
