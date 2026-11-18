-- Gravação de atributos: janela para gravar até 2 linhas extras num item.
-- Abre quando a mochila marca o atributo "ItemGravar" no jogador (botão ✒ Gravar).
-- O sorteio é todo no servidor (remote "Gravar"); aqui só desenha e comemora.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local evEstado = remotes:WaitForChild("Estado")
local evGravar = remotes:WaitForChild("Gravar")
local evAviso = remotes:WaitForChild("Aviso")

local player = Players.LocalPlayer
local G = Config.Gravacao

local COR = {
	fundo = Color3.fromRGB(22, 18, 44),
	painel = Color3.fromRGB(40, 32, 80),
	borda = Color3.fromRGB(14, 8, 28),
	dourado = Color3.fromRGB(255, 206, 72),
	texto = Color3.new(1, 1, 1),
	fraco = Color3.fromRGB(190, 182, 235),
	tinta = Color3.fromRGB(255, 84, 160),
	vermelho = Color3.fromRGB(245, 60, 80),
}
local FONTE = Enum.Font.FredokaOne
local FONTE_TEXTO = Enum.Font.GothamMedium
local POP = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local VOLTA = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local ABRIR = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local function novo(classe, pai, props)
	local o = Instance.new(classe)
	for k, v in pairs(props or {}) do
		o[k] = v
	end
	o.Parent = pai
	return o
end
local function canto(o, r)
	novo("UICorner", o, { CornerRadius = UDim.new(0, r or 10) })
end
local function contorno(o, cor, esp)
	return novo("UIStroke", o, {
		Color = cor or COR.borda,
		Thickness = esp or 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end
local function rotulo(pai, props)
	local t = novo("TextLabel", pai, {
		BackgroundTransparency = 1,
		Font = FONTE,
		TextColor3 = COR.texto,
		TextSize = 14,
	})
	for k, v in pairs(props or {}) do
		t[k] = v
	end
	novo("UIStroke", t, { Color = COR.borda, Thickness = 1.5 })
	return t
end
local function botao(pai, props)
	local b = novo("TextButton", pai, {
		Font = FONTE,
		TextSize = 14,
		TextColor3 = COR.texto,
		AutoButtonColor = true,
		BorderSizePixel = 0,
	})
	for k, v in pairs(props or {}) do
		b[k] = v
	end
	canto(b, 10)
	contorno(b, COR.borda, 2)
	return b
end

local estado = nil
local itemId = nil

------------------------------------------------------------------------
-- Janela
------------------------------------------------------------------------
local gui = novo("ScreenGui", player:WaitForChild("PlayerGui"), {
	Name = "Gravacao",
	ResetOnSpawn = false,
	DisplayOrder = 30,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
local veu = novo("TextButton", gui, {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0.45,
	Text = "",
	AutoButtonColor = false,
	Visible = false,
})
local janela = novo("Frame", veu, {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(400, 330),
	BackgroundColor3 = COR.fundo,
	BorderSizePixel = 0,
	ClipsDescendants = true,
})
canto(janela, 16)
contorno(janela, COR.dourado, 3)
local escala = novo("UIScale", janela, { Scale = 1 })
novo("UISizeConstraint", janela, { MaxSize = Vector2.new(400, 330) })
novo("UIGradient", janela, {
	Rotation = 90,
	Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(150, 140, 200)),
})
-- kanji "刻" (gravar) grande no fundo, bem apagado
rotulo(janela, {
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, 10, 1, 30),
	Size = UDim2.fromOffset(220, 220),
	Text = "刻",
	TextScaled = true,
	TextTransparency = 0.9,
	TextColor3 = COR.dourado,
	ZIndex = 1,
}).UIStroke.Enabled =
	false

-- faixa do título (rosa-choque, inclinada)
local faixa = novo("Frame", janela, {
	Position = UDim2.fromOffset(-10, 12),
	Size = UDim2.new(1, -60, 0, 36),
	BackgroundColor3 = COR.tinta,
	BorderSizePixel = 0,
	Rotation = -1.5,
	ZIndex = 2,
})
contorno(faixa, COR.borda, 3)
rotulo(faixa, {
	Position = UDim2.fromOffset(24, 0),
	Size = UDim2.new(1, -24, 1, 0),
	Text = "✒ GRAVAÇÃO",
	TextSize = 22,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 3,
})
local fechar = botao(janela, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -10, 0, 12),
	Size = UDim2.fromOffset(36, 36),
	Text = "✕",
	TextSize = 18,
	BackgroundColor3 = COR.vermelho,
	ZIndex = 4,
})

local nomeItem = rotulo(janela, {
	Position = UDim2.fromOffset(16, 58),
	Size = UDim2.new(1, -32, 0, 22),
	TextXAlignment = Enum.TextXAlignment.Left,
	TextTruncate = Enum.TextTruncate.AtEnd,
	TextSize = 16,
	ZIndex = 3,
})
local recursos = rotulo(janela, {
	Position = UDim2.fromOffset(16, 80),
	Size = UDim2.new(1, -32, 0, 18),
	TextXAlignment = Enum.TextXAlignment.Left,
	Font = FONTE_TEXTO,
	TextSize = 12,
	TextColor3 = COR.fraco,
	ZIndex = 3,
})

-- duas linhas de gravação
local linhas = {}
for i = 1, G.Linhas do
	local card = novo("Frame", janela, {
		Position = UDim2.fromOffset(16, 106 + (i - 1) * 84),
		Size = UDim2.new(1, -32, 0, 74),
		BackgroundColor3 = COR.painel,
		BorderSizePixel = 0,
		ZIndex = 3,
	})
	canto(card, 12)
	local borda = contorno(card, COR.borda, 2.5)
	local brilho = novo("Frame", card, {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 6,
	})
	canto(brilho, 12)
	local numero = rotulo(card, {
		Position = UDim2.fromOffset(8, 0),
		Size = UDim2.fromOffset(34, 74),
		Text = i == 1 and "壱" or "弐",
		TextSize = 28,
		TextColor3 = COR.dourado,
		ZIndex = 4,
	})
	local texto = rotulo(card, {
		Position = UDim2.fromOffset(48, 10),
		Size = UDim2.new(1, -190, 0, 26),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextSize = 18,
		TextScaled = true,
		ZIndex = 4,
	})
	novo("UITextSizeConstraint", texto, { MaxTextSize = 18 })
	local qual = rotulo(card, {
		Position = UDim2.fromOffset(48, 40),
		Size = UDim2.new(1, -190, 0, 20),
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = FONTE_TEXTO,
		TextSize = 12,
		ZIndex = 4,
	})
	local b = botao(card, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(128, 52),
		TextSize = 13,
		TextWrapped = true,
		BackgroundColor3 = Color3.fromRGB(56, 118, 255),
		ZIndex = 5,
	})
	linhas[i] = { card = card, borda = borda, brilho = brilho, numero = numero, texto = texto, qual = qual, botao = b }
	b.Activated:Connect(function()
		if itemId then
			evGravar:FireServer(itemId, i)
			TweenService:Create(b, POP, { Size = UDim2.fromOffset(118, 46) }):Play()
			task.delay(0.12, function()
				TweenService:Create(b, VOLTA, { Size = UDim2.fromOffset(128, 52) }):Play()
			end)
		end
	end)
end

rotulo(janela, {
	Position = UDim2.fromOffset(16, 284),
	Size = UDim2.new(1, -32, 0, 36),
	Text = "Cada linha sorteia um atributo extra e uma qualidade (Fraca → Lendária).\n"
		.. "Pergaminhos caem dos monstros, dos chefes e da Alquimia.",
	Font = FONTE_TEXTO,
	TextSize = 11,
	TextWrapped = true,
	TextColor3 = COR.fraco,
	ZIndex = 3,
}).UIStroke.Enabled =
	false

------------------------------------------------------------------------
-- Desenho
------------------------------------------------------------------------
local function itemAtual()
	if not estado or not itemId then
		return nil
	end
	for _, it in ipairs(estado.inventario or {}) do
		if it.id == itemId then
			return it
		end
	end
	return nil
end
local function raridadeDe(id)
	for i, r in ipairs(Config.Raridades) do
		if r.id == id then
			return r, i
		end
	end
	return Config.Raridades[1], 1
end

local function desenhar()
	local it = itemAtual()
	if not it then
		veu.Visible = false
		return
	end
	local r, ri = raridadeDe(it.raridade)
	nomeItem.Text = it.nome .. "  ·  Nv " .. (it.nivel or 1)
	nomeItem.TextColor3 = r.cor
	recursos.Text = string.format("📜 %d pergaminho(s)    🪙 %d ouro", estado.pergaminhos or 0, estado.ouro or 0)
	local grav = it.gravacoes or {}
	for i, l in ipairs(linhas) do
		local g = grav[i]
		local liberada = i <= #grav + 1
		local custoOuro = Config.CustoGravacao(it.nivel, ri, g ~= nil)
		local custoPerg = G.CustoPergaminhos * (g and 2 or 1)
		if g then
			local q = Config.QualidadeGravacao(g.qualidade) or G.Qualidades[1]
			l.texto.Text = Config.TextoGravacao(g)
			l.texto.TextColor3 = COR.texto
			l.qual.Text = "◆ " .. q.nome
			l.qual.TextColor3 = q.cor
			l.borda.Color = q.cor
			l.card.BackgroundColor3 = q.cor:Lerp(COR.painel, 0.75)
		else
			l.texto.Text = liberada and "Linha vazia" or "🔒 Grave a linha 壱 antes"
			l.texto.TextColor3 = COR.fraco
			l.qual.Text = liberada and "Grave para sortear um atributo" or ""
			l.qual.TextColor3 = COR.fraco
			l.borda.Color = COR.borda
			l.card.BackgroundColor3 = COR.painel
		end
		local pode = liberada and (estado.ouro or 0) >= custoOuro and (estado.pergaminhos or 0) >= custoPerg
		l.botao.Visible = liberada
		l.botao.Text = (g and "↻ REGRAVAR" or "✒ GRAVAR") .. "\n🪙 " .. custoOuro .. "  📜 " .. custoPerg
		l.botao.BackgroundColor3 = pode and (g and Color3.fromRGB(150, 70, 230) or Color3.fromRGB(56, 118, 255))
			or Color3.fromRGB(78, 74, 108)
		l.botao.TextTransparency = pode and 0 or 0.35
	end
end

local function abrir(id)
	itemId = id
	if not itemAtual() then
		return
	end
	veu.Visible = true
	escala.Scale = 0.6
	TweenService:Create(escala, ABRIR, { Scale = 1 }):Play()
	desenhar()
end
local function fecharJanela()
	veu.Visible = false
	itemId = nil
	player:SetAttribute("ItemGravar", nil)
end
fechar.Activated:Connect(fecharJanela)
veu.Activated:Connect(fecharJanela)
-- clicar na janela não fecha (o véu fica atrás)
janela.Active = true

player:GetAttributeChangedSignal("ItemGravar"):Connect(function()
	local id = player:GetAttribute("ItemGravar")
	if typeof(id) == "number" then
		abrir(id)
	end
end)

evEstado.OnClientEvent:Connect(function(novoEstado)
	estado = novoEstado
	if veu.Visible then
		desenhar()
	end
end)

------------------------------------------------------------------------
-- Comemoração da gravação (dopamina: flash, pop e tremida nas raras)
------------------------------------------------------------------------
local function tremer(forca, tempo)
	local base = janela.Position
	local fim = os.clock() + tempo
	task.spawn(function()
		while os.clock() < fim do
			janela.Position = base + UDim2.fromOffset((math.random() * 2 - 1) * forca, (math.random() * 2 - 1) * forca)
			task.wait()
		end
		janela.Position = base
	end)
end

evAviso.OnClientEvent:Connect(function(tipo, id, linha, _atributo, _valor, qualidadeId)
	if tipo ~= "gravacao" or id ~= itemId then
		return
	end
	local l = linhas[linha]
	local q = Config.QualidadeGravacao(qualidadeId)
	if not l or not q then
		return
	end
	-- flash da cor da qualidade + pop do cartão
	l.brilho.BackgroundColor3 = q.cor
	l.brilho.BackgroundTransparency = 0.1
	TweenService:Create(l.brilho, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
	local tam = l.card.Size
	TweenService:Create(l.card, POP, { Size = tam + UDim2.fromOffset(10, 6) }):Play()
	task.delay(0.12, function()
		TweenService:Create(l.card, VOLTA, { Size = tam }):Play()
	end)
	local idx = table.find(G.Qualidades, q) or 1
	if idx >= 4 then
		-- Perfeita / Lendária: carimbo grande na tela
		tremer(idx == 5 and 7 or 4, idx == 5 and 0.45 or 0.25)
		local selo = rotulo(janela, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(360, 70),
			Text = (idx == 5 and "★ LENDÁRIA! ★" or "PERFEITA!"),
			TextColor3 = q.cor,
			TextSize = 44,
			Rotation = -8,
			ZIndex = 20,
		})
		selo.UIStroke.Thickness = 4
		local esc = novo("UIScale", selo, { Scale = 2.2 })
		TweenService:Create(esc, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
			:Play()
		task.delay(1.1, function()
			TweenService:Create(selo, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
			TweenService:Create(selo.UIStroke, TweenInfo.new(0.4), { Transparency = 1 }):Play()
			task.wait(0.45)
			selo:Destroy()
		end)
	end
end)
