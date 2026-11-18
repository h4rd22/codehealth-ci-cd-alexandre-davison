-- Habilidades (tela): árvore de magias na aba "✨ Habilid.", barra de magias
-- com recarga, efeitos visuais das magias e números de dano coloridos por elemento.
-- O servidor (src/server/Habilidades.luau) decide tudo; aqui só desenha e pede.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local Dados = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Habilidades"))
-- os efeitos visuais das magias ficam no módulo do Henrique
local EfeitosMagia = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("EfeitosMagia"))
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
-- Barra de magias (embaixo, no meio): ícone, recarga e brilho ao lançar
------------------------------------------------------------------------
local guiBarra = novo("ScreenGui", playerGui, {
	Name = "BarraMagias",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 2,
	Enabled = false,
})
local barra = novo("Frame", guiBarra, {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -12),
	Size = UDim2.fromOffset(Dados.SlotsBarra * 66 + 16, 78),
	BackgroundColor3 = COR.painel,
	BackgroundTransparency = 0.15,
})
canto(barra, 14)
contorno(barra, COR.dourado, 2)
degrade(barra)
local listaBarra = novo("Frame", barra, {
	Position = UDim2.fromOffset(8, 8),
	Size = UDim2.new(1, -16, 1, -16),
	BackgroundTransparency = 1,
})
novo("UIListLayout", listaBarra, {
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 6),
	VerticalAlignment = Enum.VerticalAlignment.Center,
	SortOrder = Enum.SortOrder.LayoutOrder,
})
-- aviso de pontos para gastar (em cima da barra)
local avisoPontos = rotulo(barra, {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 0, -4),
	Size = UDim2.fromOffset(280, 26),
	Text = "",
	TextSize = 18,
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

local slots = {}
for i = 1, Dados.SlotsBarra do
	local s = novo("Frame", listaBarra, {
		Name = "Slot" .. i,
		LayoutOrder = i,
		Size = UDim2.fromOffset(60, 60),
		BackgroundColor3 = COR.painel2,
	})
	canto(s, 12)
	local borda = contorno(s, COR.borda, 2.5)
	local fundoCor = novo("Frame", s, {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = COR.cinza,
		BackgroundTransparency = 0.55,
	})
	canto(fundoCor, 12)
	degrade(fundoCor, Color3.new(1, 1, 1), Color3.fromRGB(90, 80, 80))
	local icone = rotulo(s, { Size = UDim2.fromScale(1, 1), Text = "", TextSize = 30, ZIndex = 2 })
	-- sombra da recarga: desce de cima para baixo
	local sombra = novo("Frame", s, {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.fromScale(1, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.4,
		ZIndex = 3,
	})
	canto(sombra, 12)
	local tempo = rotulo(s, { Size = UDim2.fromScale(1, 1), Text = "", TextSize = 20, ZIndex = 4 })
	local nv = rotulo(s, {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -3, 1, -1),
		Size = UDim2.fromOffset(30, 14),
		Text = "",
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 5,
	})
	local prio = rotulo(s, {
		Position = UDim2.fromOffset(4, 1),
		Size = UDim2.fromOffset(14, 14),
		Text = tostring(i),
		TextSize = 11,
		TextColor3 = COR.fraco,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 5,
	})
	local escala = novo("UIScale", s)
	slots[i] = {
		frame = s,
		borda = borda,
		fundo = fundoCor,
		icone = icone,
		sombra = sombra,
		tempo = tempo,
		nv = nv,
		prio = prio,
		escala = escala,
		id = nil,
	}
end

local function piscarSlot(id)
	for _, sl in ipairs(slots) do
		if sl.id == id then
			sl.escala.Scale = 1.25
			TweenService:Create(sl.escala, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
			local flash = novo("Frame", sl.frame, {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0.2,
				ZIndex = 6,
			})
			canto(flash, 12)
			TweenService:Create(flash, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
			Debris:AddItem(flash, 0.35)
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
			sl.icone.Text = h.icone
			sl.borda.Color = h.tipo == "suprema" and COR.ouro or cor
			sl.borda.Thickness = h.tipo == "suprema" and 3.5 or 2.5
			sl.fundo.BackgroundColor3 = cor
			sl.fundo.BackgroundTransparency = 0.5
			sl.nv.Text = "Nv" .. nivelHab(id)
		else
			sl.icone.Text = ""
			sl.borda.Color = COR.borda
			sl.borda.Thickness = 2
			sl.fundo.BackgroundColor3 = COR.cinza
			sl.fundo.BackgroundTransparency = 0.7
			sl.nv.Text = ""
		end
	end
	local pts = estado.pontosHabilidade or 0
	avisoPontos.Visible = pts > 0
	avisoPontos.Text = pts == 1 and "✨ 1 ponto de habilidade!" or ("✨ " .. pts .. " pontos de habilidade!")
end

RunService.RenderStepped:Connect(function()
	if not guiBarra.Enabled then
		return
	end
	local agora = os.clock()
	for _, sl in ipairs(slots) do
		local fim = sl.id and fimRecarga[sl.id]
		if fim and fim > agora then
			local resta = fim - agora
			local frac = resta / math.max(0.01, duracaoRecarga[sl.id] or resta)
			sl.sombra.Size = UDim2.fromScale(1, math.clamp(frac, 0, 1))
			sl.tempo.Text = resta >= 10 and tostring(math.ceil(resta)) or string.format("%.1f", resta)
		else
			sl.sombra.Size = UDim2.fromScale(1, 0)
			sl.tempo.Text = ""
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
	Text = "✨ Pontos: 0",
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
	Position = UDim2.fromOffset(180, 0),
	Size = UDim2.new(1, -360, 1, 0),
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

local CAB, LINHA, NO = 30, 66, 54
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
	detalhe.iconeFundo = novo("Frame", p, {
		Position = UDim2.fromOffset(10, 10),
		Size = UDim2.fromOffset(64, 64),
		BackgroundColor3 = COR.cinza,
	})
	canto(detalhe.iconeFundo, 14)
	detalhe.iconeBorda = contorno(detalhe.iconeFundo, COR.dourado, 3)
	degrade(detalhe.iconeFundo)
	detalhe.icone = rotulo(detalhe.iconeFundo, { Size = UDim2.fromScale(1, 1), Text = "", TextSize = 36 })
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
local function construir(arvore)
	for _, filho in ipairs(colunas:GetChildren()) do
		filho:Destroy()
	end
	nos, ligacoes, cabecalhos = {}, {}, {}
	local nRamos = #arvore.ramos
	for ci, ramo in ipairs(arvore.ramos) do
		local col = novo("Frame", colunas, {
			Position = UDim2.new((ci - 1) / nRamos, 2, 0, 0),
			Size = UDim2.new(1 / nRamos, -4, 1, 0),
			BackgroundColor3 = ramo.cor,
			BackgroundTransparency = 0.9,
		})
		canto(col, 10)
		local cab = rotulo(col, {
			Size = UDim2.new(1, 0, 0, CAB - 4),
			Text = ramo.icone .. " " .. ramo.nome,
			TextSize = 15,
			TextColor3 = ramo.cor:Lerp(Color3.new(1, 1, 1), 0.3),
			TextStrokeTransparency = 0,
		})
		cabecalhos[ramo.id] = cab
		-- traço vertical ligando os nós do ramo
		for linha = 1, 3 do
			local lig = novo("Frame", col, {
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, CAB + (linha - 1) * LINHA + NO),
				Size = UDim2.fromOffset(5, LINHA - NO),
				BackgroundColor3 = COR.cinza,
				BorderSizePixel = 0,
			})
			ligacoes[ramo.id .. linha] = lig
		end
	end
	for _, h in ipairs(arvore.lista) do
		local ci = 1
		for i, r in ipairs(arvore.ramos) do
			if r.id == h.ramo then
				ci = i
			end
		end
		local col = colunas:GetChildren()[ci]
		local cor = corRamo(h.ramo)
		-- brilho pulsando atrás (quando dá para aprender)
		local brilho = novo("Frame", col, {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, CAB + (h.linha - 1) * LINHA - 4),
			Size = UDim2.fromOffset(NO + 8, NO + 8),
			BackgroundColor3 = COR.ouro,
			BackgroundTransparency = 0.5,
			Visible = false,
		})
		canto(brilho, 16)
		TweenService:Create(
			brilho,
			TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ BackgroundTransparency = 0.85, Size = UDim2.fromOffset(NO + 14, NO + 14) }
		):Play()
		local b = novo("TextButton", col, {
			Name = "No_" .. h.id,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, CAB + (h.linha - 1) * LINHA),
			Size = UDim2.fromOffset(NO, NO),
			BackgroundColor3 = cor,
			Text = "",
			AutoButtonColor = true,
			ZIndex = 2,
		})
		canto(b, h.tipo == "passiva" and NO / 2 or 12) -- passivas redondas, ativas quadradas
		local borda = contorno(b, h.tipo == "suprema" and COR.ouro or cor:Lerp(Color3.new(0, 0, 0), 0.3), 2.5)
		local grad = degrade(b, Color3.new(1, 1, 1), Color3.fromRGB(110, 100, 100))
		local ic = rotulo(b, { Size = UDim2.fromScale(1, 1), Text = h.icone, TextSize = 28, ZIndex = 3 })
		local nv = rotulo(b, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 1, -1),
			Size = UDim2.fromOffset(40, 16),
			BackgroundTransparency = 0,
			BackgroundColor3 = COR.painel,
			Text = "0/" .. h.max,
			TextSize = 11,
			ZIndex = 4,
		})
		canto(nv, 8)
		local cadeado = rotulo(b, {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 2, 0, -4),
			Size = UDim2.fromOffset(20, 20),
			Text = "🔒",
			TextSize = 14,
			ZIndex = 5,
		})
		local estrela = h.tipo == "suprema"
				and rotulo(b, {
					Position = UDim2.fromOffset(-6, -6),
					Size = UDim2.fromOffset(20, 20),
					Text = "★",
					TextSize = 18,
					TextColor3 = COR.ouro,
					ZIndex = 5,
				})
			or nil
		b.Activated:Connect(function()
			selecionar(h.id)
		end)
		nos[h.id] = {
			hab = h,
			botao = b,
			borda = borda,
			grad = grad,
			icone = ic,
			nv = nv,
			cadeado = cadeado,
			brilho = brilho,
			estrela = estrela,
		}
	end
	construida = arvore.classe
	selecionada = selecionada and nos[selecionada] and selecionada or arvore.lista[1].id
end

local function motivoBloqueio(h)
	local niveis = estado.habilidades or {}
	if h.requer > 0 and Dados.gastos(niveis, h.ramo) < h.requer then
		return string.format("🔒 Gaste %d pontos em %s (tem %d)", h.requer, h.ramo, Dados.gastos(niveis, h.ramo))
	end
	if h.requerTotal and Dados.gastos(niveis) < h.requerTotal then
		return string.format("🔒 Gaste %d pontos na árvore (tem %d)", h.requerTotal, Dados.gastos(niveis))
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
		semArvore.Text = "✨ As habilidades do "
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
	txtPontos.Text = "✨ Pontos: " .. pontos
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
		cabecalhos[ramo.id].Text = ramo.icone .. " " .. ramo.nome .. (g > 0 and ("  " .. g) or "")
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
		if bloqueio then
			no.botao.BackgroundColor3 = COR.cinza
			no.icone.TextTransparency = 0.6
		elseif n == 0 then
			no.botao.BackgroundColor3 = cor:Lerp(COR.cinza, 0.55)
			no.icone.TextTransparency = 0.15
		else
			no.botao.BackgroundColor3 = cor
			no.icone.TextTransparency = 0
		end
		if id == selecionada then
			no.borda.Color = Color3.new(1, 1, 1)
			no.borda.Thickness = 3.5
		else
			no.borda.Color = h.tipo == "suprema" and COR.ouro or cor:Lerp(Color3.new(0, 0, 0), 0.3)
			no.borda.Thickness = 2.5
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
			lig.BackgroundColor3 = liberado and ramo.cor or COR.cinza
		end
	end
	-- mini barra
	local lista = estado.barraHab or {}
	for i, b in ipairs(miniBarra) do
		local h = lista[i] and Dados.PorId[lista[i]]
		b.Text = h and h.icone or "·"
		b.BackgroundColor3 = h and corRamo(h.ramo):Lerp(COR.painel, 0.35) or COR.painel2
	end

	-- detalhes
	local h = Dados.PorId[selecionada]
	if not h then
		return
	end
	local n = niveis[h.id] or 0
	local cor = corRamo(h.ramo)
	detalhe.icone.Text = h.icone
	detalhe.iconeFundo.BackgroundColor3 = cor
	detalhe.iconeBorda.Color = h.tipo == "suprema" and COR.ouro or Color3.new(1, 1, 1)
	detalhe.nome.Text = h.nome
	local nomeTipo = h.tipo == "suprema" and "★ SUPREMA" or (h.tipo == "ativa" and "ATIVA" or "PASSIVA")
	detalhe.tipo.Text = nomeTipo .. " · " .. (Dados.Elementos[h.ramo] and Dados.Elementos[h.ramo].nome or "")
	detalhe.tipo.TextColor3 = cor:Lerp(Color3.new(1, 1, 1), 0.25)
	detalhe.nivel.Text = "Nível " .. n .. " / " .. h.max
	detalhe.desc.Text = Dados.descricao(h, math.max(1, n))
	if n > 0 and n < h.max then
		detalhe.prox.Text = "Próximo nível: " .. Dados.descricao(h, n + 1)
	elseif n >= h.max then
		detalhe.prox.Text = "⭐ Nível máximo!"
	else
		detalhe.prox.Text = ""
	end
	local info = {}
	if h.recarga then
		local textoRecarga = string.format("⏱ Recarga: %.1fs", Dados.valor(h, "recarga", math.max(1, n)))
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
		or (
			motivo == "Nível máximo" and "⭐ Máximo"
			or (motivo == "Sem pontos" and "Sem pontos" or "🔒 Bloqueada")
		)
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
		evHab:FireServer("aprender", selecionada)
		local no = nos[selecionada]
		if
			no
			and estado
			and Dados.podeAprender(estado.habilidades, estado.pontosHabilidade, estado.classe, selecionada)
		then
			-- pulinho no nó
			local esc = no.botao:FindFirstChildOfClass("UIScale") or novo("UIScale", no.botao)
			esc.Scale = 1.35
			TweenService:Create(esc, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		end
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
-- Números de dano coloridos por elemento
------------------------------------------------------------------------
local pastaFx, tw = EfeitosMagia.pasta, EfeitosMagia.tw
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

local ICONE_NUM = { gelo = "❄", raio = "⚡", fogo = "🔥", queima = "" }

evDano.OnClientEvent:Connect(function(tipo, a, b, c, d)
	if tipo == "magia" then
		if not EfeitosMagia.tocar(a, b) and a == "eco" and type(b) == "table" then
			numero(b.pos + Vector3.new(0, 3, 0), "✨ ECO! " .. tostring(b.nome), Dados.Elementos.arcano.cor, 26)
		end
		piscarSlot(a)
	elseif tipo == "recarga" then
		fimRecarga[a] = os.clock() + b
		duracaoRecarga[a] = b
	elseif tipo == "danoElem" then
		local el = Dados.Elementos[d] or Dados.Elementos.arcano
		local icone = ICONE_NUM[d] or ""
		local txt = abreviar(b)
		if c then
			numero(a, icone .. " " .. txt .. "!", el.cor:Lerp(COR.ouro, 0.35), 38)
		elseif d == "queima" then
			numero(a, txt, el.cor, 17)
		else
			numero(a, (icone ~= "" and (icone .. " ") or "") .. txt, el.cor, 26)
		end
	end
end)

EfeitosMagia.iniciarStatus()

-- pede o estado de novo caso tenha chegado antes deste script
local evPedir = remotes:FindFirstChild("PedirEstado")
if evPedir then
	evPedir:FireServer()
end
