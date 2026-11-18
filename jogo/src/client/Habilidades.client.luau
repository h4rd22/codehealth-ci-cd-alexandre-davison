-- Habilidades (tela): árvore de magias na aba "✨ Habilid.", barra de magias
-- com recarga, efeitos visuais das magias e números de dano coloridos por elemento.
-- O servidor (src/server/Habilidades.luau) decide tudo; aqui só desenha e pede.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local Dados = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Habilidades"))
local NumerosDano = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("NumerosDano"))

-- Efeitos prontos (partículas) do Henrique: raios no corpo do atordoado, fumaça no congelado
local VFX
do
	local mod = ReplicatedStorage:WaitForChild("Shared"):FindFirstChild("VFX")
	if mod then
		local ok, m = pcall(require, mod)
		VFX = ok and m or nil
	end
end

-- Efeitos caprichados das magias: módulo do Henrique (src/shared/EfeitosMagia.luau).
-- Se ele não tiver o efeito (ou der erro), usa o efeito simples daqui.
local EfeitosMagia
do
	local mod = ReplicatedStorage:WaitForChild("Shared"):FindFirstChild("EfeitosMagia")
	if mod then
		local ok, m = pcall(require, mod)
		EfeitosMagia = ok and m or nil
	end
end
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local evEstado = remotes:WaitForChild("Estado")
local evDano = remotes:WaitForChild("Dano")
local evHab = remotes:WaitForChild("Habilidade")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local estado = nil -- último estado recebido do servidor
local fimRecarga, duracaoRecarga = {}, {}

------------------------------------------------------------------------
-- Cores e ajudantes (mesmo estilo do Hud: madeira escura + dourado)
------------------------------------------------------------------------
local COR = {
	painel = Color3.fromRGB(32, 25, 22),
	painel2 = Color3.fromRGB(52, 39, 31),
	borda = Color3.fromRGB(110, 78, 48),
	dourado = Color3.fromRGB(222, 178, 96),
	texto = Color3.fromRGB(255, 246, 228),
	fraco = Color3.fromRGB(200, 178, 145),
	verde = Color3.fromRGB(78, 178, 74),
	cinza = Color3.fromRGB(84, 72, 64),
	vermelho = Color3.fromRGB(205, 52, 46),
	madeira = Color3.fromRGB(104, 60, 34),
	ouro = Color3.fromRGB(255, 208, 72),
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
	return novo("UIStroke", o, {
		Color = cor or COR.borda,
		Thickness = esp or 1.5,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
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
	contorno(b, COR.dourado, 1.5).Transparency = 0.25
	return b
end
local function degrade(o, claro, escuro)
	return novo("UIGradient", o, {
		Rotation = 90,
		Color = ColorSequence.new(claro or Color3.new(1, 1, 1), escuro or Color3.fromRGB(150, 140, 130)),
	})
end
local function abreviar(n)
	if n >= 1e6 then
		return string.format("%.1fM", n / 1e6)
	elseif n >= 1e4 then
		return string.format("%.1fK", n / 1e3)
	end
	return tostring(n)
end

local function arvoreAtual()
	return estado and Dados.arvoreDe(estado.classe)
end
local function nivelHab(id)
	return estado and estado.habilidades and estado.habilidades[id] or 0
end
local function corRamo(ramoId)
	local el = Dados.Elementos[ramoId]
	return el and el.cor or COR.dourado
end

------------------------------------------------------------------------
-- Barra de magias (embaixo, no meio): moldura dourada, ícones grandes com
-- a cor do elemento, recarga descendo e borda girando quando está pronta
------------------------------------------------------------------------
local guiBarra = novo("ScreenGui", playerGui, {
	Name = "BarraMagias",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 2,
	Enabled = false,
})
local TAM = 64
local barra = novo("Frame", guiBarra, {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -10),
	Size = UDim2.fromOffset(Dados.SlotsBarra * (TAM + 8) + 16, TAM + 22),
	BackgroundColor3 = Color3.fromRGB(26, 18, 34),
	BackgroundTransparency = 0.08,
})
canto(barra, 18)
degrade(barra, Color3.fromRGB(255, 235, 255), Color3.fromRGB(120, 100, 130))
local bordaBarra = contorno(barra, Color3.new(1, 1, 1), 3)
local gradBordaBarra = novo("UIGradient", bordaBarra, {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, COR.dourado),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 250, 210)),
		ColorSequenceKeypoint.new(1, COR.dourado),
	}),
})
-- etiqueta "MAGIAS" presa na moldura
local etiqueta = rotulo(barra, {
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.fromOffset(16, 0),
	Size = UDim2.fromOffset(92, 20),
	Text = "MAGIAS",
	TextSize = 13,
	BackgroundTransparency = 0,
	BackgroundColor3 = Color3.fromRGB(125, 60, 210),
	TextStrokeTransparency = 0,
	ZIndex = 8,
})
canto(etiqueta, 10)
contorno(etiqueta, COR.ouro, 1.5)
local listaBarra = novo("Frame", barra, {
	Position = UDim2.fromOffset(8, 12),
	Size = UDim2.new(1, -16, 1, -18),
	BackgroundTransparency = 1,
})
novo("UIListLayout", listaBarra, {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	Padding = UDim.new(0, 8),
	VerticalAlignment = Enum.VerticalAlignment.Center,
	SortOrder = Enum.SortOrder.LayoutOrder,
})
-- aviso de pontos para gastar (em cima da barra)
local avisoPontos = rotulo(barra, {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 0, -8),
	Size = UDim2.fromOffset(300, 26),
	Text = "",
	TextSize = 19,
	TextColor3 = COR.ouro,
	TextStrokeTransparency = 0,
	Visible = false,
})
local escalaAviso = novo("UIScale", avisoPontos)
TweenService
	:Create(
		escalaAviso,
		TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Scale = 1.12 }
	)
	:Play()

local E = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("EstiloUI"))

local slots = {}
for i = 1, Dados.SlotsBarra do
	local s = novo("Frame", listaBarra, {
		Name = "Slot" .. i,
		LayoutOrder = i,
		Size = UDim2.fromOffset(TAM, TAM),
		BackgroundColor3 = Color3.fromRGB(18, 14, 22),
	})
	canto(s, 14)
	-- aura atrás do espaço (pulsa quando a magia está pronta)
	local aura = novo("Frame", s, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 14, 1, 14),
		BackgroundColor3 = COR.cinza,
		BackgroundTransparency = 1,
		ZIndex = 0,
	})
	canto(aura, 20)
	local borda = contorno(s, Color3.new(1, 1, 1), 3)
	local gradBorda = novo("UIGradient", borda, {})
	local fundoCor = novo("Frame", s, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -6, 1, -6),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.1,
		ZIndex = 1,
	})
	canto(fundoCor, 11)
	local gradFundo = novo("UIGradient", fundoCor, { Rotation = 50 })
	-- brilho de vidro na metade de cima
	local vidro = novo("Frame", fundoCor, {
		Size = UDim2.fromScale(1, 0.48),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.8,
		ZIndex = 2,
	})
	canto(vidro, 11)
	local icone = rotulo(s, { Size = UDim2.fromScale(1, 1), Text = "", TextSize = 36, ZIndex = 3 })
	-- sombra da recarga: desce de cima para baixo
	local sombra = novo("Frame", s, {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.fromScale(1, 0),
		BackgroundColor3 = Color3.fromRGB(8, 4, 16),
		BackgroundTransparency = 0.3,
		ZIndex = 4,
	})
	canto(sombra, 14)
	local tempo = rotulo(s, {
		Size = UDim2.fromScale(1, 1),
		Text = "",
		TextSize = 22,
		TextStrokeTransparency = 0,
		ZIndex = 5,
	})
	local nv = rotulo(s, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.fromOffset(34, 15),
		Text = "",
		TextSize = 11,
		BackgroundTransparency = 0,
		BackgroundColor3 = Color3.fromRGB(28, 20, 34),
		ZIndex = 6,
	})
	canto(nv, 7)
	local bordaNv = contorno(nv, COR.dourado, 1.2)
	local prio = rotulo(s, {
		Position = UDim2.fromOffset(4, 2),
		Size = UDim2.fromOffset(14, 14),
		Text = tostring(i),
		TextSize = 11,
		TextColor3 = COR.fraco,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 6,
	})
	local elem = rotulo(s, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -2, 0, 1),
		Size = UDim2.fromOffset(16, 16),
		Text = "",
		TextSize = 11,
		ZIndex = 6,
	})
	local escala = novo("UIScale", s)
	slots[i] = {
		frame = s,
		aura = aura,
		borda = borda,
		gradBorda = gradBorda,
		fundo = fundoCor,
		gradFundo = gradFundo,
		icone = icone,
		sombra = sombra,
		tempo = tempo,
		nv = nv,
		bordaNv = bordaNv,
		prio = prio,
		elem = elem,
		escala = escala,
		id = nil,
		recarregando = false,
	}
end

local function piscarSlot(id)
	for _, sl in ipairs(slots) do
		if sl.id == id then
			sl.escala.Scale = 1.28
			TweenService:Create(sl.escala, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
			local flash = novo("Frame", sl.frame, {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0.1,
				ZIndex = 7,
			})
			canto(flash, 14)
			TweenService:Create(flash, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
			Debris:AddItem(flash, 0.4)
			-- anel saindo do espaço
			local anel = novo("Frame", sl.frame, {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				ZIndex = 7,
			})
			canto(anel, 20)
			local st = contorno(anel, sl.gradFundo.Color.Keypoints[1].Value, 3)
			TweenService:Create(anel, TweenInfo.new(0.4, Enum.EasingStyle.Quad), { Size = UDim2.fromScale(1.7, 1.7) })
				:Play()
			TweenService:Create(st, TweenInfo.new(0.4), { Transparency = 1 }):Play()
			Debris:AddItem(anel, 0.45)
		end
	end
end

local function atualizarBarra()
	local arvore = arvoreAtual()
	guiBarra.Enabled = arvore ~= nil
	if not arvore then
		return
	end
	local lista = estado.barraHab or {}
	for i, sl in ipairs(slots) do
		local id = lista[i]
		local h = id and Dados.PorId[id]
		sl.id = id
		if h then
			local cor = corRamo(h.ramo)
			local suprema = h.tipo == "suprema"
			E.imagemNoTexto(sl.icone, E.iconeMagia(h))
			E.imagemNoTexto(sl.elem, E.iconeElemento(h.ramo), 1)
			sl.gradFundo.Color =
				ColorSequence.new(cor:Lerp(Color3.new(1, 1, 1), 0.45), cor:Lerp(Color3.new(0, 0, 0), 0.45))
			sl.fundo.BackgroundTransparency = 0
			local claro = suprema and Color3.fromRGB(255, 250, 200) or Color3.new(1, 1, 1)
			local base = suprema and COR.ouro or cor
			sl.gradBorda.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, base),
				ColorSequenceKeypoint.new(0.45, claro),
				ColorSequenceKeypoint.new(0.55, claro),
				ColorSequenceKeypoint.new(1, base),
			})
			sl.borda.Thickness = suprema and 4 or 3
			sl.aura.BackgroundColor3 = suprema and COR.ouro or cor
			sl.nv.Text = "Nv " .. nivelHab(id)
			sl.bordaNv.Color = suprema and COR.ouro or cor
		else
			E.imagemNoTexto(sl.icone, nil)
			E.imagemNoTexto(sl.elem, nil)
			sl.gradFundo.Color = ColorSequence.new(Color3.fromRGB(70, 60, 70), Color3.fromRGB(30, 24, 30))
			sl.fundo.BackgroundTransparency = 0.4
			sl.gradBorda.Color = ColorSequence.new(COR.borda, COR.borda)
			sl.borda.Thickness = 2
			sl.aura.BackgroundTransparency = 1
			sl.nv.Text = ""
		end
		sl.nv.Visible = h ~= nil
	end
	local pts = estado.pontosHabilidade or 0
	avisoPontos.Visible = pts > 0
	avisoPontos.Text = pts == 1 and "1 ponto de habilidade!" or ("" .. pts .. " pontos de habilidade!")
end

RunService.RenderStepped:Connect(function()
	if not guiBarra.Enabled then
		return
	end
	local agora = os.clock()
	gradBordaBarra.Offset = Vector2.new(math.sin(agora * 0.8) * 0.6, 0)
	for _, sl in ipairs(slots) do
		local fim = sl.id and fimRecarga[sl.id]
		if fim and fim > agora then
			local resta = fim - agora
			local frac = resta / math.max(0.01, duracaoRecarga[sl.id] or resta)
			sl.sombra.Size = UDim2.fromScale(1, math.clamp(frac, 0, 1))
			sl.tempo.Text = resta >= 10 and tostring(math.ceil(resta)) or string.format("%.1f", resta)
			sl.icone.TextTransparency = 0.35
			sl.aura.BackgroundTransparency = 1
			sl.recarregando = true
		else
			sl.sombra.Size = UDim2.fromScale(1, 0)
			sl.tempo.Text = ""
			sl.icone.TextTransparency = 0
			if sl.id then
				-- pronta: borda gira e a aura pulsa
				sl.gradBorda.Rotation = (agora * 160) % 360
				sl.aura.BackgroundTransparency = 0.6 + math.sin(agora * 5) * 0.15
				if sl.recarregando then
					sl.recarregando = false
					sl.escala.Scale = 1.15
					TweenService:Create(sl.escala, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
				end
			end
		end
	end
end)

------------------------------------------------------------------------
-- Árvore de habilidades (dentro da página "Habilidades" do menu)
------------------------------------------------------------------------
-- a página é criada pelo Hud (aba "✨ Habilid.")
local janelas = playerGui:WaitForChild("Janelas")
local pagina = janelas:FindFirstChild("PaginaHabilidades", true)
while not pagina do
	task.wait(0.2)
	pagina = janelas:FindFirstChild("PaginaHabilidades", true)
end

local selecionada = nil
local nos = {} -- nos[id] = {...}
local ligacoes = {} -- traços entre os nós de cada ramo
local detalhe = {}
local cabecalhos = {}
local miniBarra = {}
local construida = nil -- id da classe cuja árvore está desenhada
local confirmarReset = 0
local niveisAntes = nil -- para animar a habilidade que acabou de subir

local raizArvore = novo("Frame", pagina, {
	Name = "ArvoreMagias",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
})

-- Mensagem para classes sem árvore ainda
local semArvore = rotulo(raizArvore, {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(460, 120),
	Text = "",
	TextSize = 20,
	TextWrapped = true,
	TextColor3 = COR.fraco,
	Visible = false,
})

local conteudo = novo("Frame", raizArvore, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 })

-- Topo: pontos, dica e resetar
local topo = novo("Frame", conteudo, { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1 })
local pilulaPontos = novo("Frame", topo, {
	Size = UDim2.fromOffset(170, 34),
	BackgroundColor3 = Color3.fromRGB(120, 70, 200),
})
canto(pilulaPontos, 17)
contorno(pilulaPontos, COR.ouro, 2)
degrade(pilulaPontos, Color3.fromRGB(255, 230, 255), Color3.fromRGB(150, 110, 170))
local txtPontos = rotulo(pilulaPontos, {
	Size = UDim2.fromScale(1, 1),
	Text = "Pontos: 0",
	TextSize = 19,
	TextColor3 = COR.ouro,
	TextStrokeTransparency = 0,
})
local escalaPilula = novo("UIScale", pilulaPontos)
local brilhoPilula = TweenService:Create(
	escalaPilula,
	TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
	{ Scale = 1.08 }
)
rotulo(topo, {
	Position = UDim2.fromOffset(192, 0),
	Size = UDim2.new(1, -372, 1, 0),
	Text = "1 ponto por nível. As magias da barra saem sozinhas quando a recarga acaba.",
	TextSize = 12,
	Font = FONTE_TEXTO,
	TextColor3 = COR.fraco,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
})
local btnReset = botao(topo, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.fromScale(1, 0),
	Size = UDim2.fromOffset(172, 34),
	Text = "↺ Resetar pontos",
	TextSize = 14,
	BackgroundColor3 = COR.vermelho,
})

-- Área da árvore (esquerda) e painel de detalhes (direita)
local LARG_DETALHE = 250
local areaArvore = novo("Frame", conteudo, {
	Position = UDim2.fromOffset(0, 42),
	Size = UDim2.new(1, -(LARG_DETALHE + 10), 1, -42),
	BackgroundColor3 = Color3.fromRGB(20, 15, 14),
	BackgroundTransparency = 0.25,
})
canto(areaArvore, 12)
contorno(areaArvore, COR.borda, 1.5)
local painelDetalhe = novo("Frame", conteudo, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, 0, 0, 42),
	Size = UDim2.new(0, LARG_DETALHE, 1, -42),
	BackgroundColor3 = COR.painel2,
})
canto(painelDetalhe, 12)
contorno(painelDetalhe, COR.dourado, 2)
degrade(painelDetalhe, Color3.new(1, 1, 1), Color3.fromRGB(150, 135, 125))

local CAB, LINHA, NO = 34, 70, 52
local colunas = novo("Frame", areaArvore, {
	Position = UDim2.fromOffset(6, 4),
	Size = UDim2.new(1, -12, 0, CAB + 4 * LINHA),
	BackgroundTransparency = 1,
})

-- Mini barra (ordem de prioridade) embaixo da árvore
local faixaBarra = novo("Frame", areaArvore, {
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 6, 1, -4),
	Size = UDim2.new(1, -12, 0, 40),
	BackgroundColor3 = COR.painel,
	BackgroundTransparency = 0.2,
})
canto(faixaBarra, 10)
rotulo(faixaBarra, {
	Position = UDim2.fromOffset(8, 0),
	Size = UDim2.new(0, 120, 1, 0),
	Text = "Barra (prioridade):",
	TextSize = 12,
	TextColor3 = COR.fraco,
	TextXAlignment = Enum.TextXAlignment.Left,
})
for i = 1, Dados.SlotsBarra do
	local b = botao(faixaBarra, {
		Position = UDim2.fromOffset(128 + (i - 1) * 40, 4),
		Size = UDim2.fromOffset(34, 32),
		Text = "",
		TextSize = 20,
		BackgroundColor3 = COR.painel2,
	})
	miniBarra[i] = b
end

-- Painel de detalhes
do
	local p = painelDetalhe
	-- raios girando atrás do ícone, na cor do elemento
	detalhe.raios = novo("Frame", p, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(42, 42),
		Size = UDim2.fromOffset(124, 124),
		BackgroundTransparency = 1,
		ZIndex = 1,
	})
	detalhe.listaRaios = {}
	for i = 1, 6 do
		local r = novo("Frame", detalhe.raios, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(0, 18, 1, 0),
			Rotation = i * 30,
			BackgroundColor3 = COR.ouro,
			BackgroundTransparency = 0.15,
			BorderSizePixel = 0,
			ZIndex = 1,
		})
		novo("UIGradient", r, {
			Rotation = 90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.22, 0.15),
				NumberSequenceKeypoint.new(0.5, 0),
				NumberSequenceKeypoint.new(0.78, 0.15),
				NumberSequenceKeypoint.new(1, 1),
			}),
		})
		table.insert(detalhe.listaRaios, r)
	end
	TweenService:Create(detalhe.raios, TweenInfo.new(14, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), {
		Rotation = 360,
	}):Play()
	detalhe.iconeFundo = novo("Frame", p, {
		Position = UDim2.fromOffset(10, 10),
		Size = UDim2.fromOffset(64, 64),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 2,
	})
	canto(detalhe.iconeFundo, 16)
	detalhe.iconeBorda = contorno(detalhe.iconeFundo, COR.dourado, 3)
	detalhe.iconeGrad = novo("UIGradient", detalhe.iconeFundo, { Rotation = 45 })
	detalhe.icone = rotulo(detalhe.iconeFundo, { Size = UDim2.fromScale(1, 1), Text = "", TextSize = 38, ZIndex = 3 })
	detalhe.nome = rotulo(p, {
		Position = UDim2.fromOffset(82, 8),
		Size = UDim2.new(1, -90, 0, 26),
		Text = "",
		TextSize = 19,
		TextColor3 = Color3.fromRGB(255, 225, 140),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextScaled = true,
	})
	novo("UITextSizeConstraint", detalhe.nome, { MaxTextSize = 19 })
	detalhe.tipo = rotulo(p, {
		Position = UDim2.fromOffset(82, 34),
		Size = UDim2.new(1, -90, 0, 18),
		Text = "",
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	detalhe.nivel = rotulo(p, {
		Position = UDim2.fromOffset(82, 54),
		Size = UDim2.new(1, -90, 0, 18),
		Text = "",
		TextSize = 14,
		TextColor3 = COR.ouro,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	detalhe.desc = rotulo(p, {
		Position = UDim2.fromOffset(10, 82),
		Size = UDim2.new(1, -20, 0, 70),
		Text = "",
		TextSize = 13,
		Font = FONTE_TEXTO,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	})
	detalhe.prox = rotulo(p, {
		Position = UDim2.fromOffset(10, 154),
		Size = UDim2.new(1, -20, 0, 62),
		Text = "",
		TextSize = 12,
		Font = FONTE_TEXTO,
		TextColor3 = Color3.fromRGB(150, 235, 140),
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	})
	detalhe.info = rotulo(p, {
		Position = UDim2.fromOffset(10, 216),
		Size = UDim2.new(1, -20, 0, 34),
		Text = "",
		TextSize = 12,
		Font = FONTE_TEXTO,
		TextColor3 = COR.fraco,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	})
	detalhe.aprender = botao(p, {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 10, 1, -52),
		Size = UDim2.new(1, -20, 0, 40),
		Text = "Aprender (+1)",
		TextSize = 18,
		BackgroundColor3 = COR.verde,
	})
	detalhe.equipar = botao(p, {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 10, 1, -8),
		Size = UDim2.new(1, -96, 0, 36),
		Text = "Pôr na barra",
		TextSize = 14,
	})
	detalhe.esq = botao(p, {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -50, 1, -8),
		Size = UDim2.fromOffset(36, 36),
		Text = "◀",
		TextSize = 16,
	})
	detalhe.dir = botao(p, {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -10, 1, -8),
		Size = UDim2.fromOffset(36, 36),
		Text = "▶",
		TextSize = 16,
	})
end

local atualizarArvore -- definida abaixo

local function selecionar(id)
	selecionada = id
	atualizarArvore()
end

-- Monta os nós da árvore da classe (uma vez por classe)
local giros = {} -- gradientes que giram (bordas das supremas e linhas acesas)
local function construir(arvore)
	for _, filho in ipairs(colunas:GetChildren()) do
		filho:Destroy()
	end
	nos, ligacoes, cabecalhos, giros = {}, {}, {}, {}
	local nRamos = #arvore.ramos
	local cols = {}
	for ci, ramo in ipairs(arvore.ramos) do
		local col = novo("Frame", colunas, {
			Position = UDim2.new((ci - 1) / nRamos, 3, 0, 0),
			Size = UDim2.new(1 / nRamos, -6, 1, 0),
			BackgroundColor3 = ramo.cor,
			BackgroundTransparency = 0.55,
			ClipsDescendants = false,
		})
		cols[ramo.id] = col
		canto(col, 12)
		contorno(col, ramo.cor:Lerp(Color3.new(0, 0, 0), 0.35), 1.5).Transparency = 0.3
		-- a cor do elemento vai sumindo para o escuro
		novo("UIGradient", col, {
			Rotation = 90,
			Color = ColorSequence.new(ramo.cor:Lerp(Color3.new(1, 1, 1), 0.2), Color3.fromRGB(20, 14, 24)),
			Transparency = NumberSequence.new(0.1, 0.35),
		})
		-- símbolo grande do elemento ao fundo (marca d'água)
		rotulo(col, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.58),
			Size = UDim2.fromScale(1, 0.6),
			Text = "",
			TextSize = 110,
			TextTransparency = 0.86,
			TextStrokeTransparency = 1,
			ZIndex = 1,
		})
		-- faixa do título do ramo
		local faixaRamo = novo("Frame", col, {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 3),
			Size = UDim2.new(1, -8, 0, CAB - 8),
			BackgroundColor3 = ramo.cor:Lerp(Color3.new(0, 0, 0), 0.25),
			ZIndex = 2,
		})
		canto(faixaRamo, 9)
		contorno(faixaRamo, ramo.cor:Lerp(Color3.new(1, 1, 1), 0.5), 1.5)
		degrade(faixaRamo, Color3.new(1, 1, 1), Color3.fromRGB(120, 110, 120))
		local cab = rotulo(faixaRamo, {
			Size = UDim2.fromScale(1, 1),
			Text = ramo.nome,
			TextSize = 15,
			TextColor3 = Color3.new(1, 1, 1),
			TextStrokeTransparency = 0,
			TextStrokeColor3 = ramo.cor:Lerp(Color3.new(0, 0, 0), 0.75),
			ZIndex = 3,
		})
		cabecalhos[ramo.id] = cab
		-- linha brilhante ligando os nós do ramo (acende quando o nó de baixo libera)
		for linha = 1, 3 do
			local y = CAB + (linha - 1) * LINHA + NO - 2
			local alto = LINHA - NO + 4
			local brilhoLig = novo("Frame", col, {
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, y),
				Size = UDim2.fromOffset(14, alto),
				BackgroundColor3 = ramo.cor,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = 2,
			})
			canto(brilhoLig, 7)
			local lig = novo("Frame", col, {
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, y),
				Size = UDim2.fromOffset(6, alto),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				ZIndex = 2,
			})
			canto(lig, 3)
			local gradLig = novo("UIGradient", lig, { Rotation = 90 })
			ligacoes[ramo.id .. linha] = { linha = lig, brilho = brilhoLig, grad = gradLig, cor = ramo.cor }
		end
	end
	for _, h in ipairs(arvore.lista) do
		local col = cols[h.ramo]
		local cor = corRamo(h.ramo)
		local redondo = h.tipo == "passiva"
		local raioCanto = redondo and NO / 2 or 14
		local yNo = CAB + (h.linha - 1) * LINHA
		-- auréola atrás do nó (acende quando aprendido / pulsa quando dá para aprender)
		local halo = novo("Frame", col, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0, yNo + NO / 2),
			Size = UDim2.fromOffset(NO + 16, NO + 16),
			BackgroundColor3 = cor,
			BackgroundTransparency = 1,
			ZIndex = 2,
		})
		canto(halo, raioCanto + 8)
		local brilho = novo("Frame", col, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0, yNo + NO / 2),
			Size = UDim2.fromOffset(NO + 10, NO + 10),
			BackgroundColor3 = COR.ouro,
			BackgroundTransparency = 0.45,
			Visible = false,
			ZIndex = 2,
		})
		canto(brilho, raioCanto + 5)
		TweenService:Create(
			brilho,
			TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ BackgroundTransparency = 0.9, Size = UDim2.fromOffset(NO + 20, NO + 20) }
		):Play()
		local b = novo("TextButton", col, {
			Name = "No_" .. h.id,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, yNo),
			Size = UDim2.fromOffset(NO, NO),
			BackgroundColor3 = Color3.new(1, 1, 1),
			Text = "",
			AutoButtonColor = false,
			ZIndex = 3,
		})
		canto(b, raioCanto)
		local borda = contorno(b, Color3.new(1, 1, 1), h.tipo == "suprema" and 3.5 or 3)
		local gradBorda = novo("UIGradient", borda, {})
		if h.tipo == "suprema" then
			table.insert(giros, gradBorda)
		end
		local grad = novo("UIGradient", b, { Rotation = 45 })
		-- vidro na metade de cima
		local vidro = novo("Frame", b, {
			Size = UDim2.fromScale(1, 0.5),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.78,
			ZIndex = 4,
		})
		canto(vidro, raioCanto)
		local ic = rotulo(b, { Size = UDim2.fromScale(1, 1), Text = "", TextSize = 30, ZIndex = 5 })
		E.imagemNoTexto(ic, E.iconeMagia(h), 0.72)
		local nv = rotulo(b, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 1),
			Size = UDim2.fromOffset(40, 16),
			BackgroundTransparency = 0,
			BackgroundColor3 = Color3.fromRGB(26, 18, 30),
			Text = "0/" .. h.max,
			TextSize = 11,
			ZIndex = 6,
		})
		canto(nv, 8)
		local bordaNv = contorno(nv, cor, 1.2)
		local cadeado = rotulo(b, {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 4, 0, -6),
			Size = UDim2.fromOffset(22, 22),
			Text = "",
			TextSize = 15,
			ZIndex = 7,
		})
		E.imagemNoTexto(cadeado, E.ICONES.cadeado, 1)
		local estrela = h.tipo == "suprema"
				and rotulo(b, {
					Position = UDim2.fromOffset(-8, -8),
					Size = UDim2.fromOffset(22, 22),
					Text = "",
					TextSize = 20,
					ZIndex = 7,
				})
			or nil
		if estrela then
			E.imagemNoTexto(estrela, E.ICONES.estrela, 1)
		end
		local escala = novo("UIScale", b)
		b.MouseEnter:Connect(function()
			TweenService:Create(escala, TweenInfo.new(0.12), { Scale = 1.08 }):Play()
		end)
		b.MouseLeave:Connect(function()
			TweenService:Create(escala, TweenInfo.new(0.12), { Scale = 1 }):Play()
		end)
		b.Activated:Connect(function()
			selecionar(h.id)
		end)
		nos[h.id] = {
			hab = h,
			botao = b,
			borda = borda,
			gradBorda = gradBorda,
			grad = grad,
			icone = ic,
			nv = nv,
			bordaNv = bordaNv,
			cadeado = cadeado,
			brilho = brilho,
			halo = halo,
			estrela = estrela,
			escala = escala,
			coluna = col,
			centro = UDim2.new(0.5, 0, 0, yNo + NO / 2),
		}
	end
	construida = arvore.classe
	selecionada = selecionada and nos[selecionada] and selecionada or arvore.lista[1].id
end

-- Animação ao aprender: explosão de faíscas da cor do elemento, anel e "+1"
local function festejar(id, nivelNovo)
	local no = nos[id]
	if not no then
		return
	end
	local cor = corRamo(no.hab.ramo)
	no.escala.Scale = 1.45
	TweenService:Create(no.escala, TweenInfo.new(0.45, Enum.EasingStyle.Elastic), { Scale = 1 }):Play()
	for i = 1, 14 do
		local ang = i / 14 * math.pi * 2 + math.random() * 0.3
		local dist = 46 + math.random() * 26
		local f = novo("Frame", no.coluna, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = no.centro,
			Size = UDim2.fromOffset(9, 9),
			Rotation = math.deg(ang),
			BackgroundColor3 = i % 3 == 0 and Color3.new(1, 1, 1) or cor,
			ZIndex = 9,
		})
		canto(f, 3)
		TweenService:Create(f, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = no.centro + UDim2.fromOffset(math.cos(ang) * dist, math.sin(ang) * dist),
			Size = UDim2.fromOffset(2, 2),
			BackgroundTransparency = 1,
		}):Play()
		Debris:AddItem(f, 0.6)
	end
	local anel = novo("Frame", no.coluna, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = no.centro,
		Size = UDim2.fromOffset(NO, NO),
		BackgroundTransparency = 1,
		ZIndex = 9,
	})
	canto(anel, 60)
	local st = contorno(anel, cor:Lerp(Color3.new(1, 1, 1), 0.3), 4)
	TweenService
		:Create(anel, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { Size = UDim2.fromOffset(NO * 2.3, NO * 2.3) })
		:Play()
	TweenService:Create(st, TweenInfo.new(0.5), { Transparency = 1, Thickness = 1 }):Play()
	Debris:AddItem(anel, 0.55)
	local txt = rotulo(no.coluna, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = no.centro,
		Size = UDim2.fromOffset(120, 30),
		Text = nivelNovo == 1 and "NOVA!" or ("+1  Nv " .. nivelNovo),
		TextSize = 22,
		TextColor3 = cor:Lerp(Color3.new(1, 1, 1), 0.35),
		TextStrokeTransparency = 0,
		ZIndex = 10,
	})
	local esc = novo("UIScale", txt, { Scale = 0.4 })
	TweenService:Create(esc, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1.15 }):Play()
	TweenService:Create(txt, TweenInfo.new(0.9, Enum.EasingStyle.Quad), {
		Position = no.centro - UDim2.fromOffset(0, 48),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()
	Debris:AddItem(txt, 0.95)
end

-- gira as bordas das supremas e faz o brilho correr nas linhas acesas
RunService.RenderStepped:Connect(function()
	if not (pagina.Visible and conteudo.Visible) then
		return
	end
	local t = os.clock()
	for _, g in ipairs(giros) do
		g.Rotation = (t * 120) % 360
	end
	for _, l in pairs(ligacoes) do
		if l.acesa then
			l.grad.Offset = Vector2.new(0, ((t * 1.2) % 2) - 1)
		end
	end
end)

local function motivoBloqueio(h)
	local niveis = estado.habilidades or {}
	if h.requer > 0 and Dados.gastos(niveis, h.ramo) < h.requer then
		return string.format("Gaste %d pontos em %s (tem %d)", h.requer, h.ramo, Dados.gastos(niveis, h.ramo))
	end
	if h.requerTotal and Dados.gastos(niveis) < h.requerTotal then
		return string.format("Gaste %d pontos na árvore (tem %d)", h.requerTotal, Dados.gastos(niveis))
	end
	return nil
end

atualizarArvore = function()
	if not estado then
		return
	end
	local arvore = arvoreAtual()
	if not arvore then
		conteudo.Visible = false
		semArvore.Visible = true
		local nomeClasse = estado.classe and (estado.classe:sub(1, 1):upper() .. estado.classe:sub(2)) or "herói"
		semArvore.Text = "As habilidades do "
			.. nomeClasse
			.. " chegam em breve!\nPor enquanto só o Mago tem a árvore de magias."
		return
	end
	semArvore.Visible = false
	conteudo.Visible = true
	if construida ~= arvore.classe then
		construir(arvore)
	end
	local niveis = estado.habilidades or {}
	local pontos = estado.pontosHabilidade or 0
	if niveisAntes then
		for id, n in pairs(niveis) do
			if n > (niveisAntes[id] or 0) then
				festejar(id, n)
			end
		end
	end
	niveisAntes = table.clone(niveis)
	txtPontos.Text = "Pontos: " .. pontos
	if pontos > 0 then
		brilhoPilula:Play()
	else
		brilhoPilula:Cancel()
		escalaPilula.Scale = 1
	end
	local gastos = Dados.gastos(niveis)
	local custo = Dados.CustoReset(estado.nivel or 1)
	if os.clock() > confirmarReset then
		btnReset.Text = "↺ Resetar (" .. abreviar(custo) .. " ouro)"
	end
	btnReset.AutoButtonColor = gastos > 0
	btnReset.BackgroundColor3 = (gastos > 0 and (estado.ouro or 0) >= custo) and COR.vermelho or COR.cinza

	for _, ramo in ipairs(arvore.ramos) do
		local g = Dados.gastos(niveis, ramo.id)
		cabecalhos[ramo.id].Text = ramo.nome .. (g > 0 and ("  " .. g) or "")
	end
	for id, no in pairs(nos) do
		local h = no.hab
		local n = niveis[id] or 0
		local bloqueio = motivoBloqueio(h)
		local pode = Dados.podeAprender(niveis, pontos, estado.classe, id)
		no.nv.Text = n .. "/" .. h.max
		no.nv.TextColor3 = n >= h.max and COR.ouro or COR.texto
		no.cadeado.Visible = bloqueio ~= nil
		no.brilho.Visible = pode
		local cor = corRamo(h.ramo)
		local suprema = h.tipo == "suprema"
		local branco = Color3.new(1, 1, 1)
		if bloqueio then
			no.grad.Color = ColorSequence.new(Color3.fromRGB(110, 100, 105), Color3.fromRGB(45, 38, 44))
			no.icone.TextTransparency = 0.55
			no.gradBorda.Color = ColorSequence.new(Color3.fromRGB(90, 80, 85), Color3.fromRGB(60, 52, 58))
			no.halo.BackgroundTransparency = 1
		elseif n == 0 then
			local apagada = cor:Lerp(COR.cinza, 0.5)
			no.grad.Color = ColorSequence.new(apagada:Lerp(branco, 0.3), apagada:Lerp(Color3.new(0, 0, 0), 0.4))
			no.icone.TextTransparency = 0.1
			no.gradBorda.Color = ColorSequence.new(apagada, apagada:Lerp(branco, 0.3))
			no.halo.BackgroundTransparency = 1
		else
			no.grad.Color = ColorSequence.new(cor:Lerp(branco, 0.5), cor:Lerp(Color3.new(0, 0, 0), 0.35))
			no.icone.TextTransparency = 0
			local base = suprema and COR.ouro or cor:Lerp(branco, 0.2)
			no.gradBorda.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, base),
				ColorSequenceKeypoint.new(0.5, branco),
				ColorSequenceKeypoint.new(1, base),
			})
			no.halo.BackgroundTransparency = n >= h.max and 0.45 or 0.7
		end
		if id == selecionada then
			no.gradBorda.Color = ColorSequence.new(branco, Color3.fromRGB(255, 240, 180))
			no.borda.Thickness = 4.5
		else
			no.borda.Thickness = suprema and 3.5 or 3
		end
	end
	-- traços: acendem quando o nó de baixo já está liberado
	for _, ramo in ipairs(arvore.ramos) do
		for linha = 1, 3 do
			local lig = ligacoes[ramo.id .. linha]
			local liberado = false
			for _, h in ipairs(arvore.lista) do
				if h.ramo == ramo.id and h.linha == linha + 1 then
					liberado = motivoBloqueio(h) == nil
				end
			end
			lig.acesa = liberado
			if liberado then
				lig.grad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, ramo.cor),
					ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
					ColorSequenceKeypoint.new(1, ramo.cor),
				})
				lig.brilho.BackgroundTransparency = 0.65
			else
				lig.grad.Color = ColorSequence.new(COR.cinza, COR.cinza)
				lig.grad.Offset = Vector2.zero
				lig.brilho.BackgroundTransparency = 1
			end
		end
	end
	-- mini barra
	local lista = estado.barraHab or {}
	for i, b in ipairs(miniBarra) do
		local h = lista[i] and Dados.PorId[lista[i]]
		E.imagemNoTexto(b, h and E.iconeMagia(h) or nil)
		b.BackgroundColor3 = h and corRamo(h.ramo):Lerp(COR.painel, 0.35) or COR.painel2
	end

	-- detalhes
	local h = Dados.PorId[selecionada]
	if not h then
		return
	end
	local n = niveis[h.id] or 0
	local cor = corRamo(h.ramo)
	E.imagemNoTexto(detalhe.icone, E.iconeMagia(h), 0.75)
	detalhe.iconeGrad.Color = ColorSequence.new(cor:Lerp(Color3.new(1, 1, 1), 0.5), cor:Lerp(Color3.new(0, 0, 0), 0.35))
	for _, r in ipairs(detalhe.listaRaios) do
		r.BackgroundColor3 = h.tipo == "suprema" and COR.ouro or cor
	end
	detalhe.iconeBorda.Color = h.tipo == "suprema" and COR.ouro or Color3.new(1, 1, 1)
	detalhe.nome.Text = h.nome
	local nomeTipo = h.tipo == "suprema" and "SUPREMA" or (h.tipo == "ativa" and "ATIVA" or "PASSIVA")
	detalhe.tipo.Text = nomeTipo .. " · " .. (Dados.Elementos[h.ramo] and Dados.Elementos[h.ramo].nome or "")
	detalhe.tipo.TextColor3 = cor:Lerp(Color3.new(1, 1, 1), 0.25)
	detalhe.nivel.Text = "Nível " .. n .. " / " .. h.max
	detalhe.desc.Text = Dados.descricao(h, math.max(1, n))
	if n > 0 and n < h.max then
		detalhe.prox.Text = "Próximo nível: " .. Dados.descricao(h, n + 1)
	elseif n >= h.max then
		detalhe.prox.Text = "Nível máximo!"
	else
		detalhe.prox.Text = ""
	end
	local info = {}
	if h.recarga then
		local textoRecarga = string.format("Recarga: %.1fs", Dados.valor(h, "recarga", math.max(1, n)))
		table.insert(info, (string.gsub(textoRecarga, "%.0s", "s")))
	end
	local bloqueio = motivoBloqueio(h)
	if bloqueio then
		table.insert(info, bloqueio)
	end
	detalhe.info.Text = table.concat(info, "\n")
	detalhe.info.TextColor3 = bloqueio and Color3.fromRGB(255, 130, 110) or COR.fraco

	local pode, motivo = Dados.podeAprender(niveis, pontos, estado.classe, h.id)
	detalhe.aprender.Text = pode and (n == 0 and "Aprender (1 ponto)" or "Subir nível (1 ponto)")
		or (motivo == "Nível máximo" and "Máximo" or (motivo == "Sem pontos" and "Sem pontos" or "Bloqueada"))
	detalhe.aprender.BackgroundColor3 = pode and COR.verde or COR.cinza
	detalhe.aprender.AutoButtonColor = pode

	local ativa = Dados.eAtiva(h)
	local pos = table.find(lista, h.id)
	detalhe.equipar.Visible = ativa
	detalhe.esq.Visible = ativa and pos ~= nil
	detalhe.dir.Visible = ativa and pos ~= nil
	if ativa then
		if pos then
			detalhe.equipar.Text = "Tirar da barra (" .. pos .. "º)"
			detalhe.equipar.BackgroundColor3 = COR.madeira
		elseif n == 0 then
			detalhe.equipar.Text = "Aprenda primeiro"
			detalhe.equipar.BackgroundColor3 = COR.cinza
		elseif #lista >= Dados.SlotsBarra then
			detalhe.equipar.Text = "Barra cheia"
			detalhe.equipar.BackgroundColor3 = COR.cinza
		else
			detalhe.equipar.Text = "Pôr na barra"
			detalhe.equipar.BackgroundColor3 = Color3.fromRGB(70, 110, 190)
		end
	end
end

-- Botões
detalhe.aprender.Activated:Connect(function()
	if selecionada then
		evHab:FireServer("aprender", selecionada) -- a animação sai quando o servidor confirma
	end
end)
detalhe.equipar.Activated:Connect(function()
	if not (selecionada and estado) then
		return
	end
	if table.find(estado.barraHab or {}, selecionada) then
		evHab:FireServer("tirar", selecionada)
	else
		evHab:FireServer("equipar", selecionada)
	end
end)
detalhe.esq.Activated:Connect(function()
	if selecionada then
		evHab:FireServer("mover", selecionada, -1)
	end
end)
detalhe.dir.Activated:Connect(function()
	if selecionada then
		evHab:FireServer("mover", selecionada, 1)
	end
end)
for i, b in ipairs(miniBarra) do
	b.Activated:Connect(function()
		local id = estado and estado.barraHab and estado.barraHab[i]
		if id then
			selecionar(id)
		end
	end)
end
btnReset.Activated:Connect(function()
	if not estado or Dados.gastos(estado.habilidades) <= 0 then
		return
	end
	if os.clock() < confirmarReset then
		confirmarReset = 0
		evHab:FireServer("resetar")
	else
		confirmarReset = os.clock() + 3
		btnReset.Text = "Certeza? Clique de novo"
		task.delay(3.05, atualizarArvore)
	end
end)

------------------------------------------------------------------------
-- Bolinha no botão "Habilid." do menu quando há pontos
------------------------------------------------------------------------
local bolinhaMenu
local function atualizarBolinha()
	local hud = playerGui:FindFirstChild("Hud")
	local b = hud and hud:FindFirstChild("Menu_habilidades", true)
	if not b then
		return
	end
	if not bolinhaMenu or bolinhaMenu.Parent ~= b then
		bolinhaMenu = rotulo(b, {
			Name = "PontosHab",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(1, -6, 0, 8),
			Size = UDim2.fromOffset(24, 24),
			BackgroundTransparency = 0,
			BackgroundColor3 = Color3.fromRGB(150, 80, 240),
			Text = "",
			TextSize = 13,
			ZIndex = 10,
		})
		canto(bolinhaMenu, 12)
		contorno(bolinhaMenu, COR.ouro, 2)
	end
	local pts = estado and arvoreAtual() and estado.pontosHabilidade or 0
	bolinhaMenu.Visible = pts > 0
	bolinhaMenu.Text = tostring(pts)
end

evEstado.OnClientEvent:Connect(function(novo_)
	local pontosAntes = estado and estado.pontosHabilidade
	estado = novo_
	atualizarBarra()
	atualizarArvore()
	atualizarBolinha()
	if pontosAntes and (estado.pontosHabilidade or 0) > pontosAntes and arvoreAtual() then
		-- ganhou ponto: a pílula pula
		escalaAviso.Scale = 1.6
	end
end)

------------------------------------------------------------------------
-- Efeitos das magias no mundo
------------------------------------------------------------------------
local pastaFx = Instance.new("Folder")
pastaFx.Name = "FxMagias"
pastaFx.Parent = workspace

local function fx(tamanho, cor, forma, material)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = material or Enum.Material.Neon
	p.Color = cor
	p.Size = tamanho
	if forma then
		p.Shape = forma
	end
	p.Parent = pastaFx
	return p
end
local function tw(o, tempo, props, estilo, direcao)
	local t = TweenService:Create(
		o,
		TweenInfo.new(tempo, estilo or Enum.EasingStyle.Quad, direcao or Enum.EasingDirection.Out),
		props
	)
	t:Play()
	return t
end
local function luz(parte, cor, alcance, brilho)
	return novo("PointLight", parte, { Color = cor, Range = alcance, Brightness = brilho or 3 })
end
local function rastro(parte, cor, largura, vida)
	local a0 = novo("Attachment", parte, { Position = Vector3.new(0, largura / 2, 0) })
	local a1 = novo("Attachment", parte, { Position = Vector3.new(0, -largura / 2, 0) })
	novo("Trail", parte, {
		Attachment0 = a0,
		Attachment1 = a1,
		Color = ColorSequence.new(cor:Lerp(Color3.new(1, 1, 1), 0.5), cor),
		Transparency = NumberSequence.new(0.1, 1),
		LightEmission = 1,
		Lifetime = vida,
		FaceCamera = true,
	})
end
local function chao(pos)
	-- os inimigos ficam ~2,5 studs acima do chão
	local r = workspace:Raycast(
		pos + Vector3.new(0, 3, 0),
		Vector3.new(0, -30, 0),
		(function()
			local p = RaycastParams.new()
			p.FilterType = Enum.RaycastFilterType.Exclude
			p.FilterDescendantsInstances = { pastaFx, workspace:FindFirstChild("Monstros"), player.Character }
			return p
		end)()
	)
	return r and r.Position or pos - Vector3.new(0, 2.5, 0)
end
local function anelChao(centro, cor, raioFinal, tempo, material)
	local base = chao(centro)
	local anel = fx(Vector3.new(0.3, 1, 1), cor, Enum.PartType.Cylinder, material)
	anel.CFrame = CFrame.new(base + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.rad(90))
	anel.Transparency = 0.15
	tw(anel, tempo, { Size = Vector3.new(0.2, raioFinal * 2, raioFinal * 2), Transparency = 1 })
	Debris:AddItem(anel, tempo + 0.05)
	return anel
end
local function estilhacos(pos, cor, qtd, dist, material)
	for _ = 1, qtd do
		local s = fx(Vector3.new(0.35, 0.35, 0.35) * (0.6 + math.random()), cor, nil, material)
		s.CFrame = CFrame.new(pos) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
		local d = Vector3.new(math.random() - 0.5, math.random() * 0.9 + 0.1, math.random() - 0.5).Unit
		tw(s, 0.5, {
			Position = pos + d * (dist * (0.5 + math.random() * 0.6)),
			Size = Vector3.new(0.05, 0.05, 0.05),
			Transparency = 1,
		})
		Debris:AddItem(s, 0.55)
	end
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

-- Faixa grande na tela para as supremas e o eco
local guiFx = novo("ScreenGui", playerGui, {
	Name = "FxMagiasTela",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 4,
})
local faixaSuprema = rotulo(guiFx, {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.24),
	Size = UDim2.new(0.8, 0, 0, 60),
	Text = "",
	TextSize = 44,
	TextTransparency = 1,
	TextStrokeTransparency = 1,
})
local contornoFaixa = novo("UIStroke", faixaSuprema, { Thickness = 3, Transparency = 1 })
local escalaFaixa = novo("UIScale", faixaSuprema)
local function anunciar(texto, cor)
	faixaSuprema.Text = texto
	faixaSuprema.TextColor3 = cor
	contornoFaixa.Color = cor:Lerp(Color3.new(0, 0, 0), 0.7)
	escalaFaixa.Scale = 2
	faixaSuprema.TextTransparency = 0
	contornoFaixa.Transparency = 0
	tw(escalaFaixa, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
	task.delay(1.4, function()
		if faixaSuprema.Text == texto then
			tw(faixaSuprema, 0.4, { TextTransparency = 1 })
			tw(contornoFaixa, 0.4, { Transparency = 1 })
		end
	end)
end

-- Raio em zigue-zague entre dois pontos
local function raioZigue(a, b, cor, grossura, tempo)
	local partes = math.max(3, math.floor((b - a).Magnitude / 3))
	local anterior = a
	for i = 1, partes do
		local alvo = a:Lerp(b, i / partes)
		if i < partes then
			alvo += Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 2.2
		end
		local comp = (alvo - anterior).Magnitude
		local seg = fx(Vector3.new(grossura, grossura, comp), cor)
		seg.CFrame = CFrame.lookAt((anterior + alvo) / 2, alvo)
		tw(seg, tempo, { Transparency = 1, Size = Vector3.new(grossura * 0.2, grossura * 0.2, comp) })
		Debris:AddItem(seg, tempo + 0.05)
		-- núcleo branco
		local nucleo = fx(Vector3.new(grossura * 0.4, grossura * 0.4, comp), Color3.new(1, 1, 1))
		nucleo.CFrame = seg.CFrame
		tw(nucleo, tempo * 0.7, { Transparency = 1 })
		Debris:AddItem(nucleo, tempo)
		anterior = alvo
	end
end

local function raioDoCeu(pos, cor, grosso)
	local topoRaio = pos + Vector3.new(math.random(-4, 4), 45, math.random(-4, 4))
	raioZigue(topoRaio, pos, cor, grosso and 0.9 or 0.6, 0.3)
	local clarao = fx(Vector3.new(2, 2, 2), Color3.new(1, 1, 1), Enum.PartType.Ball)
	clarao.Position = pos
	luz(clarao, cor, 18, 6)
	tw(clarao, 0.25, { Size = Vector3.new(7, 7, 7), Transparency = 1 })
	Debris:AddItem(clarao, 0.3)
	anelChao(pos, cor, grosso and 6 or 4, 0.35)
	estilhacos(pos, cor, 6, 5)
end

local COR_GELO = Dados.Elementos.gelo.cor
local COR_RAIO = Dados.Elementos.raio.cor
local COR_FOGO = Dados.Elementos.fogo.cor

local Efeito = {}

Efeito.lancaGelo = function(d)
	local de = d.de + Vector3.new(0, 1.2, 0)
	local para = d.para + Vector3.new(0, 1.2, 0)
	local dist = (para - de).Magnitude
	local lanca = fx(Vector3.new(0.7, 0.7, 4.5), COR_GELO, nil, Enum.Material.Glass)
	lanca.Transparency = 0.1
	local ponta = fx(Vector3.new(0.4, 0.4, 1.6), Color3.new(1, 1, 1))
	luz(lanca, COR_GELO, 12, 4)
	rastro(lanca, COR_GELO, 1.4, 0.35)
	local tempo = dist / 70
	local t0 = os.clock()
	local con
	con = RunService.Heartbeat:Connect(function()
		local a = math.min((os.clock() - t0) / tempo, 1)
		local p = de:Lerp(para, a)
		local cf = CFrame.lookAt(p, para + (para - de).Unit)
		lanca.CFrame = cf
		ponta.CFrame = cf * CFrame.new(0, 0, -2.6)
		if math.random() < 0.5 then
			estilhacos(p, COR_GELO, 1, 2, Enum.Material.Ice)
		end
		if a >= 1 then
			con:Disconnect()
			lanca:Destroy()
			ponta:Destroy()
			estilhacos(p, COR_GELO, 8, 4, Enum.Material.Ice)
		end
	end)
end

Efeito.novaGelo = function(d)
	local base = chao(d.centro)
	anelChao(d.centro, COR_GELO, d.raio, 0.45, Enum.Material.Ice)
	anelChao(d.centro, Color3.new(1, 1, 1), d.raio * 0.8, 0.3)
	-- espinhos de gelo brotando em círculo
	for i = 1, 14 do
		local ang = i / 14 * math.pi * 2
		local dist = d.raio * (0.45 + math.random() * 0.5)
		local pos = base + Vector3.new(math.cos(ang) * dist, 0, math.sin(ang) * dist)
		local alt = 2.5 + math.random() * 2.5
		local esp = fx(Vector3.new(0.9, 0.1, 0.9), COR_GELO:Lerp(Color3.new(1, 1, 1), 0.3), nil, Enum.Material.Ice)
		esp.Transparency = 0.15
		esp.CFrame = CFrame.new(pos)
			* CFrame.Angles(math.rad(math.random(-20, 20)), ang, math.rad(math.random(-20, 20)))
		tw(
			esp,
			0.18,
			{ Size = Vector3.new(0.9, alt, 0.9), CFrame = esp.CFrame * CFrame.new(0, alt / 2, 0) },
			Enum.EasingStyle.Back
		)
		task.delay(1.1 + math.random() * 0.3, function()
			tw(esp, 0.35, { Transparency = 1, Size = Vector3.new(0.2, 0.2, 0.2) })
		end)
		Debris:AddItem(esp, 1.8)
	end
	local bola = fx(Vector3.new(2, 2, 2), COR_GELO, Enum.PartType.Ball, Enum.Material.ForceField)
	bola.Position = d.centro
	luz(bola, COR_GELO, d.raio * 2, 5)
	tw(bola, 0.4, { Size = Vector3.new(d.raio * 2, d.raio * 2, d.raio * 2), Transparency = 1 })
	Debris:AddItem(bola, 0.45)
	tremer(0.5, 0.2)
end

Efeito.nevasca = function(d)
	local base = chao(d.centro)
	local disco = fx(Vector3.new(0.3, d.raio * 2, d.raio * 2), COR_GELO, Enum.PartType.Cylinder, Enum.Material.Ice)
	disco.CFrame = CFrame.new(base + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.rad(90))
	disco.Transparency = 0.45
	local nuvem =
		fx(Vector3.new(d.raio * 2, 1, d.raio * 2), Color3.fromRGB(200, 230, 255), nil, Enum.Material.SmoothPlastic)
	nuvem.Transparency = 1
	nuvem.Position = base + Vector3.new(0, 14, 0)
	local neve = novo("ParticleEmitter", nuvem, {
		Color = ColorSequence.new(Color3.new(1, 1, 1), COR_GELO),
		LightEmission = 0.6,
		Size = NumberSequence.new(0.5, 0.2),
		Lifetime = NumberRange.new(1, 1.4),
		Rate = 220,
		Speed = NumberRange.new(14, 22),
		SpreadAngle = Vector2.new(12, 12),
		EmissionDirection = Enum.NormalId.Bottom,
		Acceleration = Vector3.new(6, 0, 0),
	})
	-- anéis girando
	local giro = fx(Vector3.new(0.4, d.raio * 1.6, d.raio * 1.6), Color3.new(1, 1, 1), Enum.PartType.Cylinder)
	giro.Transparency = 0.7
	giro.CFrame = disco.CFrame * CFrame.new(0.4, 0, 0)
	luz(disco, COR_GELO, d.raio * 2.5, 3)
	local t0 = os.clock()
	local con
	con = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		giro.CFrame = CFrame.new(base + Vector3.new(0, 0.5 + math.sin(t * 6) * 0.3, 0))
			* CFrame.Angles(0, t * 4, 0)
			* CFrame.Angles(0, 0, math.rad(90))
		if t > d.duracao then
			con:Disconnect()
		end
	end)
	task.delay(d.duracao, function()
		neve.Enabled = false
		tw(disco, 0.5, { Transparency = 1 })
		tw(giro, 0.5, { Transparency = 1 })
		anelChao(d.centro, Color3.new(1, 1, 1), d.raio * 1.2, 0.5, Enum.Material.Ice)
		estilhacos(d.centro, COR_GELO, 20, 10, Enum.Material.Ice)
		tremer(0.8, 0.3)
	end)
	Debris:AddItem(disco, d.duracao + 0.6)
	Debris:AddItem(giro, d.duracao + 0.6)
	Debris:AddItem(nuvem, d.duracao + 1.6)
end

Efeito.correnteRaio = function(d)
	local anterior = d.de + Vector3.new(0, 1.5, 0)
	for i, p in ipairs(d.pontos) do
		local a = anterior
		task.delay((i - 1) * 0.07, function()
			raioZigue(a, p, COR_RAIO, 0.45, 0.22)
			local c = fx(Vector3.new(1.5, 1.5, 1.5), Color3.new(1, 1, 1), Enum.PartType.Ball)
			c.Position = p
			luz(c, COR_RAIO, 12, 5)
			tw(c, 0.2, { Size = Vector3.new(4, 4, 4), Transparency = 1 })
			Debris:AddItem(c, 0.25)
			estilhacos(p, COR_RAIO, 4, 3)
		end)
		anterior = p
	end
end

Efeito.furiaTrovao = function(d)
	for _, p in ipairs(d.pontos) do
		anelChao(p, COR_RAIO, 3, 0.25)
		task.delay(0.2, function()
			raioDoCeu(p, COR_RAIO, true)
		end)
	end
	task.delay(0.2, function()
		tremer(0.6, 0.2)
	end)
end

Efeito.tempestade = function(d)
	local cc = novo("ColorCorrectionEffect", Lighting, {
		Name = "FxTempestade",
		Brightness = 0,
		Contrast = 0,
		TintColor = Color3.new(1, 1, 1),
	})
	tw(cc, 0.4, { Brightness = -0.12, Contrast = 0.15, TintColor = Color3.fromRGB(200, 205, 255) })
	task.delay(d.duracao, function()
		tw(cc, 0.6, { Brightness = 0, Contrast = 0, TintColor = Color3.new(1, 1, 1) })
		Debris:AddItem(cc, 0.7)
	end)
end

Efeito.tempestadeGolpe = function(d)
	raioDoCeu(d.pos, COR_RAIO, false)
	tremer(0.3, 0.08)
end

local function explosaoFogo(pos, raio, forte)
	local bola = fx(Vector3.new(2, 2, 2), COR_FOGO, Enum.PartType.Ball)
	bola.Position = pos
	luz(bola, COR_FOGO, raio * 2, forte and 5 or 2.5)
	tw(bola, 0.35, { Size = Vector3.new(raio * 2, raio * 2, raio * 2), Transparency = 1 })
	Debris:AddItem(bola, 0.4)
	local miolo = fx(Vector3.new(1.5, 1.5, 1.5), Color3.fromRGB(255, 240, 160), Enum.PartType.Ball)
	miolo.Position = pos
	tw(miolo, 0.25, { Size = Vector3.new(raio, raio, raio), Transparency = 1 })
	Debris:AddItem(miolo, 0.3)
	anelChao(pos, COR_FOGO, raio * 1.1, 0.4)
	estilhacos(pos, Color3.fromRGB(255, 180, 60), forte and 24 or 10, raio * 1.2)
	-- fumaça escura subindo
	for _ = 1, forte and 8 or 3 do
		local f = fx(Vector3.new(2, 2, 2), Color3.fromRGB(60, 45, 40), Enum.PartType.Ball, Enum.Material.SmoothPlastic)
		f.Transparency = 0.35
		f.Position = pos + Vector3.new(math.random(-2, 2), 0, math.random(-2, 2))
		tw(f, 1, {
			Position = f.Position + Vector3.new(0, 5 + math.random() * 3, 0),
			Size = Vector3.new(5, 5, 5),
			Transparency = 1,
		})
		Debris:AddItem(f, 1.05)
	end
end

Efeito.bolaFogo = function(d)
	local de = d.de + Vector3.new(0, 1.6, 0)
	local para = d.para
	local dist = (para - de).Magnitude
	local bola = fx(Vector3.new(1.8, 1.8, 1.8), COR_FOGO, Enum.PartType.Ball)
	local miolo = fx(Vector3.new(1, 1, 1), Color3.fromRGB(255, 240, 160), Enum.PartType.Ball)
	novo("Fire", bola, { Color = COR_FOGO, SecondaryColor = Color3.fromRGB(255, 220, 80), Size = 4, Heat = 6 })
	luz(bola, COR_FOGO, 14, 4)
	rastro(bola, COR_FOGO, 1.6, 0.35)
	local t0 = os.clock()
	local con
	con = RunService.Heartbeat:Connect(function()
		local a = math.min((os.clock() - t0) / d.tempo, 1)
		local p = de:Lerp(para, a) + Vector3.new(0, math.sin(a * math.pi) * dist * 0.15, 0)
		bola.Position = p
		miolo.Position = p
		if a >= 1 then
			con:Disconnect()
			bola:Destroy()
			miolo:Destroy()
			explosaoFogo(para, d.raio, false)
		end
	end)
	Debris:AddItem(bola, d.tempo + 0.5)
	Debris:AddItem(miolo, d.tempo + 0.5)
end

Efeito.anelChamas = function(d)
	local base = chao(d.centro)
	anelChao(d.centro, COR_FOGO, d.raio, 0.4)
	anelChao(d.centro, Color3.fromRGB(255, 220, 90), d.raio * 0.85, 0.5)
	-- labaredas indo para fora
	for i = 1, 18 do
		local ang = i / 18 * math.pi * 2
		local dir = Vector3.new(math.cos(ang), 0, math.sin(ang))
		local chama = fx(Vector3.new(1.2, 2.5, 1.2), i % 2 == 0 and COR_FOGO or Color3.fromRGB(255, 200, 60))
		chama.Position = base + dir * 1.5 + Vector3.new(0, 1.2, 0)
		tw(chama, 0.4, {
			Position = base + dir * d.raio + Vector3.new(0, 1.6, 0),
			Size = Vector3.new(0.3, 4, 0.3),
			Transparency = 1,
		})
		Debris:AddItem(chama, 0.45)
	end
	local brilho = fx(Vector3.new(2, 2, 2), COR_FOGO, Enum.PartType.Ball)
	brilho.Position = d.centro
	brilho.Transparency = 0.8
	luz(brilho, COR_FOGO, d.raio * 1.5, 2)
	tw(brilho, 0.3, { Size = Vector3.new(d.raio * 0.8, d.raio * 0.8, d.raio * 0.8), Transparency = 1 })
	Debris:AddItem(brilho, 0.45)
	tremer(0.4, 0.15)
end

Efeito.meteoro = function(d)
	local base = chao(d.centro)
	-- alvo vermelho piscando no chão
	local mira = fx(Vector3.new(0.2, d.raio * 2, d.raio * 2), Color3.fromRGB(255, 50, 30), Enum.PartType.Cylinder)
	mira.CFrame = CFrame.new(base + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.rad(90))
	mira.Transparency = 0.6
	TweenService:Create(
		mira,
		TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Transparency = 0.25 }
	):Play()
	Debris:AddItem(mira, d.tempo)
	-- a pedra
	local inicio = base + Vector3.new(-25, 60, 20)
	local pedra = fx(Vector3.new(6, 6, 6), Color3.fromRGB(90, 40, 25), Enum.PartType.Ball, Enum.Material.Basalt)
	local nucleo = fx(Vector3.new(5, 5, 5), COR_FOGO, Enum.PartType.Ball)
	nucleo.Transparency = 0.3
	novo("Fire", pedra, { Color = COR_FOGO, SecondaryColor = Color3.fromRGB(255, 230, 90), Size = 14, Heat = 20 })
	luz(pedra, COR_FOGO, 30, 8)
	rastro(pedra, COR_FOGO, 5, 0.6)
	local t0 = os.clock()
	local con
	con = RunService.Heartbeat:Connect(function()
		local a = math.min((os.clock() - t0) / d.tempo, 1)
		local p = inicio:Lerp(base + Vector3.new(0, 2, 0), a * a)
		pedra.CFrame = CFrame.new(p) * CFrame.Angles(a * 8, a * 5, 0)
		nucleo.Position = p
		if a >= 1 then
			con:Disconnect()
			pedra:Destroy()
			nucleo:Destroy()
			explosaoFogo(base + Vector3.new(0, 1.5, 0), d.raio, true)
			anelChao(d.centro, Color3.fromRGB(255, 240, 180), d.raio * 2, 0.6)
			-- cratera brilhando
			local cratera = fx(Vector3.new(0.25, d.raio * 1.2, d.raio * 1.2), COR_FOGO, Enum.PartType.Cylinder)
			cratera.CFrame = CFrame.new(base + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.rad(90))
			cratera.Transparency = 0.2
			tw(cratera, 2, { Transparency = 1 }, Enum.EasingStyle.Linear)
			Debris:AddItem(cratera, 2.1)
			tremer(2.2, 0.6)
		end
	end)
	Debris:AddItem(pedra, d.tempo + 0.5)
end

-- faixa grande na tela quando sai uma suprema
local SUPREMAS = {
	nevasca = { "NEVASCA ETERNA!", COR_GELO },
	tempestade = { "TEMPESTADE DIVINA!", COR_RAIO },
	meteoro = { "METEORO INFERNAL!", COR_FOGO },
}

Efeito.explosaoMorte = function(d)
	explosaoFogo(d.centro, d.raio * 0.7, false)
end

------------------------------------------------------------------------
-- Números de dano coloridos por elemento
------------------------------------------------------------------------
local function numero(pos, texto, cor, tamanho)
	local ancora = Instance.new("Part")
	ancora.Anchored = true
	ancora.CanCollide = false
	ancora.CanQuery = false
	ancora.Transparency = 1
	ancora.Size = Vector3.new(0.2, 0.2, 0.2)
	ancora.Position = pos + Vector3.new(math.random(-20, 20) / 10, 3 + math.random() * 1.5, math.random(-20, 20) / 10)
	ancora.Parent = pastaFx
	local bb = novo("BillboardGui", ancora, {
		Size = UDim2.fromOffset(260, 70),
		AlwaysOnTop = true,
		Adornee = ancora,
	})
	local t = novo("TextLabel", bb, {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = texto,
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = tamanho,
		Font = FONTE,
	})
	local st = novo("UIStroke", t, {
		Color = cor:Lerp(Color3.new(0, 0, 0), 0.8),
		Thickness = tamanho >= 30 and 3.2 or 2.2,
	})
	novo("UIGradient", t, { Rotation = 90, Color = ColorSequence.new(cor:Lerp(Color3.new(1, 1, 1), 0.6), cor) })
	local esc = novo("UIScale", t, { Scale = tamanho >= 30 and 2.2 or 1.6 })
	tw(esc, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
	tw(ancora, 0.9, { Position = ancora.Position + Vector3.new(0, 3.5, 0) })
	TweenService:Create(
		t,
		TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.45),
		{ TextTransparency = 1 }
	):Play()
	TweenService:Create(
		st,
		TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.45),
		{ Transparency = 1 }
	):Play()
	Debris:AddItem(ancora, 1)
end

evDano.OnClientEvent:Connect(function(tipo, a, b, c, d)
	if tipo == "magia" then
		local tocou = false
		if EfeitosMagia and type(b) == "table" then
			local ok, r = pcall(EfeitosMagia.tocar, a, b)
			tocou = ok and r == true
		end
		local f = Efeito[a]
		if SUPREMAS[a] then
			anunciar(SUPREMAS[a][1], SUPREMAS[a][2])
		end
		if not tocou and f and type(b) == "table" then
			f(b)
		elseif a == "eco" and type(b) == "table" then
			numero(b.pos + Vector3.new(0, 3, 0), "ECO! " .. tostring(b.nome), Dados.Elementos.arcano.cor, 26)
		end
		piscarSlot(a)
	elseif tipo == "recarga" then
		fimRecarga[a] = os.clock() + b
		duracaoRecarga[a] = b
	elseif tipo == "danoElem" then
		-- número na cor do elemento (gelo azul-claro, fogo laranja, raio roxo); crítico maior com "!"
		NumerosDano.mostrar(a, b, d or "arcano", { critico = c == true, menor = d == "queima" })
	end
end)

------------------------------------------------------------------------
-- Visual dos efeitos nos inimigos: congelado, lento, atordoado, queimando
------------------------------------------------------------------------
local visuais = {} -- visuais[modelo] = {...}

local function visualDe(m)
	local v = visuais[m]
	if v then
		return v
	end
	local raiz = m.PrimaryPart
	if not raiz then
		return nil
	end
	local h = novo("Highlight", m, {
		Name = "Elemento",
		FillTransparency = 1,
		OutlineTransparency = 1,
		DepthMode = Enum.HighlightDepthMode.Occluded,
	})
	local barraVida = m:FindFirstChild("Barra")
	local offset = barraVida and barraVida.StudsOffsetWorldSpace or Vector3.new(0, 4, 0)
	local bb = novo("BillboardGui", raiz, {
		Name = "StatusMagia",
		Size = UDim2.fromOffset(120, 26),
		StudsOffsetWorldSpace = offset + Vector3.new(0, 1.4, 0),
		AlwaysOnTop = true,
		MaxDistance = 90,
	})
	local txt = rotulo(bb, { Size = UDim2.fromScale(1, 1), Text = "", TextSize = 20 })
	local fogo = novo("ParticleEmitter", raiz, {
		Name = "Queimando",
		Color = ColorSequence.new(Color3.fromRGB(255, 220, 90), COR_FOGO),
		LightEmission = 1,
		Size = NumberSequence.new(1.1, 0),
		Lifetime = NumberRange.new(0.4, 0.7),
		Rate = 24,
		Speed = NumberRange.new(3, 6),
		SpreadAngle = Vector2.new(25, 25),
		EmissionDirection = Enum.NormalId.Top,
		Enabled = false,
	})
	v = { highlight = h, texto = txt, fogo = fogo, gelo = nil }
	visuais[m] = v
	return v
end

local acumulado = 0
RunService.Heartbeat:Connect(function(dt)
	acumulado += dt
	if acumulado < 0.12 then
		return
	end
	acumulado = 0
	local agora = workspace:GetServerTimeNow()
	local pasta = workspace:FindFirstChild("Monstros")
	if not pasta then
		return
	end
	for m, v in pairs(visuais) do
		if not m.Parent then
			if v.gelo then
				v.gelo:Destroy()
			end
			visuais[m] = nil
		end
	end
	for _, m in ipairs(pasta:GetChildren()) do
		if m:GetAttribute("Dono") == player.UserId and m.PrimaryPart then
			local congelado = (m:GetAttribute("CongeladoAte") or 0) > agora
			local atordoado = (m:GetAttribute("AtordoadoAte") or 0) > agora
			local lento = (m:GetAttribute("LentoAte") or 0) > agora
			local queimando = (m:GetAttribute("QueimaAte") or 0) > agora
			local vivoM = (m:GetAttribute("Vida") or 0) > 0
			if congelado or atordoado or lento or queimando or visuais[m] then
				local v = visualDe(m)
				if v then
					local icones = {}
					if congelado then
						table.insert(icones, "CONGELADO")
					elseif lento then
						table.insert(icones, "LENTO")
					end
					if atordoado then
						table.insert(icones, "TONTO")
					end
					if queimando then
						table.insert(icones, "QUEIMANDO")
					end
					v.texto.Text = vivoM and table.concat(icones, " · ") or ""
					v.fogo.Enabled = queimando and vivoM
					local hl = v.highlight
					if congelado then
						hl.FillColor = Color3.fromRGB(60, 160, 255)
						hl.FillTransparency = 0.55
						hl.OutlineColor = COR_GELO
						hl.OutlineTransparency = 0
					elseif atordoado then
						hl.FillColor = COR_RAIO
						hl.FillTransparency = 0.6 + math.random() * 0.2
						hl.OutlineColor = COR_RAIO
						hl.OutlineTransparency = 0
					elseif queimando then
						hl.FillColor = COR_FOGO
						hl.FillTransparency = 0.55 + math.random() * 0.25
						hl.OutlineColor = Color3.fromRGB(255, 200, 80)
						hl.OutlineTransparency = 0.3
					elseif lento then
						hl.FillColor = COR_GELO
						hl.FillTransparency = 0.8
						hl.OutlineColor = COR_GELO
						hl.OutlineTransparency = 0.2
					else
						hl.FillTransparency = 1
						hl.OutlineTransparency = 1
					end
					-- partículas prontas (VFX do Henrique), uma vez por efeito novo
					if VFX and vivoM then
						local fimAtordoado = m:GetAttribute("AtordoadoAte") or 0
						if atordoado and fimAtordoado > (v.raioAte or 0) then
							v.raioAte = fimAtordoado
							pcall(VFX.corpo, "Raio/Electrocuted", m, fimAtordoado - agora)
						end
						local fimCongelado = m:GetAttribute("CongeladoAte") or 0
						if congelado and fimCongelado > (v.geloAte or 0) then
							v.geloAte = fimCongelado
							pcall(VFX.grudar, "Gelo/TorsoIce", m.PrimaryPart, fimCongelado - agora)
						end
					end
					-- bloco de gelo em volta de quem está congelado
					if congelado and vivoM and not v.gelo then
						local cf, tam = m:GetBoundingBox()
						local bloco = fx(tam * 1.08, Color3.fromRGB(80, 170, 255), nil, Enum.Material.Ice)
						bloco.Transparency = 0.62
						bloco.CFrame = cf
						v.gelo = bloco
						estilhacos(cf.Position, COR_GELO, 5, 3, Enum.Material.Ice)
					elseif (not congelado or not vivoM) and v.gelo then
						local bloco = v.gelo
						v.gelo = nil
						estilhacos(bloco.Position, COR_GELO, 6, 4, Enum.Material.Ice)
						tw(bloco, 0.15, { Transparency = 1 })
						Debris:AddItem(bloco, 0.2)
					end
				end
			end
		end
	end
end)

-- pede o estado de novo caso tenha chegado antes deste script
local evPedir = remotes:FindFirstChild("PedirEstado")
if evPedir then
	evPedir:FireServer()
end
