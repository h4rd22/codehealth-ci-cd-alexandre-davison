--!strict
-- Tela do jogador: moedas, botões, painéis (Ovos, Fusão, Base, Loja),
-- avisos, anúncios e o cartão de "Você ganhou!".

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Util = require(ReplicatedStorage.Shared:WaitForChild("Util"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local jogador = Players.LocalPlayer
local camera = workspace.CurrentCamera

local function ev(nome: string): RemoteEvent
	return Remotes:WaitForChild(nome) :: RemoteEvent
end

------------------------------------------------------------------------
-- Estilo
------------------------------------------------------------------------
local FONTE = Enum.Font.FredokaOne
local COR_FUNDO = Color3.fromRGB(35, 30, 60)
local COR_CARTAO = Color3.fromRGB(55, 48, 90)
local COR_VERDE = Color3.fromRGB(80, 210, 110)
local COR_AMARELO = Color3.fromRGB(255, 205, 60)
local COR_VERMELHO = Color3.fromRGB(235, 80, 80)
local COR_AZUL = Color3.fromRGB(80, 160, 255)
local COR_ROXO = Color3.fromRGB(170, 100, 255)

local function cantos(obj: GuiObject, raio: number?)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, raio or 12)
	c.Parent = obj
end

local function borda(obj: GuiObject, cor: Color3?, grossura: number?)
	local b = Instance.new("UIStroke")
	b.Color = cor or Color3.new(0, 0, 0)
	b.Thickness = grossura or 3
	b.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	b.Parent = obj
end

local function rotulo(pai: Instance, props: { [string]: any }): TextLabel
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Font = FONTE
	t.TextColor3 = Color3.new(1, 1, 1)
	t.TextScaled = true
	t.TextStrokeTransparency = 0.4
	for k, v in props do
		(t :: any)[k] = v
	end
	t.Parent = pai
	return t
end

local function botao(pai: Instance, texto: string, cor: Color3, props: { [string]: any }?): TextButton
	local b = Instance.new("TextButton")
	b.Font = FONTE
	b.Text = texto
	b.TextScaled = true
	b.TextColor3 = Color3.new(1, 1, 1)
	b.TextStrokeTransparency = 0.3
	b.BackgroundColor3 = cor
	b.AutoButtonColor = true
	cantos(b)
	borda(b, cor:Lerp(Color3.new(0, 0, 0), 0.5), 3)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 4)
	pad.PaddingBottom = UDim.new(0, 4)
	pad.PaddingLeft = UDim.new(0, 6)
	pad.PaddingRight = UDim.new(0, 6)
	pad.Parent = b
	for k, v in props or {} do
		(b :: any)[k] = v
	end
	-- pulinho ao clicar
	b.MouseButton1Down:Connect(function()
		local escala = b:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
		escala.Parent = b
		escala.Scale = 0.9
		TweenService:Create(escala, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end)
	b.Parent = pai
	return b
end

------------------------------------------------------------------------
-- Tela base
------------------------------------------------------------------------
local tela = Instance.new("ScreenGui")
tela.Name = "Mistureba"
tela.ResetOnSpawn = false
tela.IgnoreGuiInset = false
tela.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
tela.Parent = jogador:WaitForChild("PlayerGui")

-- tudo fica menor em celular
local escalaTela = Instance.new("UIScale")
escalaTela.Parent = tela
local function ajustarEscala()
	local menor = math.min(camera.ViewportSize.X, camera.ViewportSize.Y)
	escalaTela.Scale = math.clamp(menor / 800, 0.55, 1.2)
end
camera:GetPropertyChangedSignal("ViewportSize"):Connect(ajustarEscala)
ajustarEscala()

-- Moedas no topo
local barraMoedas = Instance.new("Frame")
barraMoedas.AnchorPoint = Vector2.new(0.5, 0)
barraMoedas.Position = UDim2.new(0.5, 0, 0, 8)
barraMoedas.Size = UDim2.fromOffset(320, 70)
barraMoedas.BackgroundColor3 = COR_FUNDO
barraMoedas.BackgroundTransparency = 0.15
cantos(barraMoedas, 16)
borda(barraMoedas, COR_AMARELO, 3)
barraMoedas.Parent = tela
local textoMoedas = rotulo(barraMoedas, {
	Size = UDim2.new(1, -16, 0, 40),
	Position = UDim2.fromOffset(8, 4),
	Text = "0 moedas",
	TextColor3 = COR_AMARELO,
})
local textoRenda = rotulo(barraMoedas, {
	Size = UDim2.new(1, -16, 0, 22),
	Position = UDim2.fromOffset(8, 44),
	Text = "+0/s",
	TextColor3 = COR_VERDE,
})

-- Linha de status (carregando, cadeado, sorte, proteção)
local textoStatus = rotulo(tela, {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 84),
	Size = UDim2.fromOffset(560, 26),
	Text = "",
	RichText = true,
})

-- Botões da esquerda
local menu = Instance.new("Frame")
menu.BackgroundTransparency = 1
menu.AnchorPoint = Vector2.new(0, 0.5)
menu.Position = UDim2.new(0, 10, 0.5, 0)
menu.Size = UDim2.fromOffset(120, 370)
menu.Parent = tela
local listaMenu = Instance.new("UIListLayout")
listaMenu.Padding = UDim.new(0, 10)
listaMenu.Parent = menu

local botaoOvos = botao(menu, "OVOS", COR_AMARELO, { Size = UDim2.fromOffset(120, 62), LayoutOrder = 1 })
local botaoFusao = botao(menu, "FUSÃO", COR_ROXO, { Size = UDim2.fromOffset(120, 62), LayoutOrder = 2 })
local botaoBase = botao(menu, "BASE", COR_AZUL, { Size = UDim2.fromOffset(120, 62), LayoutOrder = 3 })
local botaoLoja = botao(menu, "LOJA", COR_VERDE, { Size = UDim2.fromOffset(120, 62), LayoutOrder = 4 })
local botaoDex = botao(menu, "DEX", Color3.fromRGB(60, 200, 190), { Size = UDim2.fromOffset(120, 62), LayoutOrder = 5 })

-- Botões de ação (direita embaixo)
local acoes = Instance.new("Frame")
acoes.BackgroundTransparency = 1
acoes.AnchorPoint = Vector2.new(1, 1)
acoes.Position = UDim2.new(1, -12, 1, -110)
acoes.Size = UDim2.fromOffset(150, 230)
acoes.Parent = tela
local listaAcoes = Instance.new("UIListLayout")
listaAcoes.Padding = UDim.new(0, 10)
listaAcoes.HorizontalAlignment = Enum.HorizontalAlignment.Right
listaAcoes.Parent = acoes
local botaoTapa = botao(acoes, "TAPA (F)", COR_VERMELHO, { Size = UDim2.fromOffset(150, 64), LayoutOrder = 1 })
local botaoTrancar = botao(acoes, "TRANCAR (T)", COR_VERDE, { Size = UDim2.fromOffset(150, 64), LayoutOrder = 2 })
local botaoSoltar = botao(acoes, "SOLTAR (G)", Color3.fromRGB(120, 120, 140), {
	Size = UDim2.fromOffset(150, 64),
	LayoutOrder = 3,
	Visible = false,
})

------------------------------------------------------------------------
-- Estado vindo do servidor
------------------------------------------------------------------------
type EstadoTela = {
	moedas: number,
	renda: number,
	criaturas: { [string]: string },
	guardadas: number,
	vagas: number,
	precoMelhoria: number?,
	descobertas: { [string]: boolean },
	renascimentos: number,
	precoRenascer: number,
	cadeadoAte: number,
	cadeadoLivreEm: number,
	sorteAte: number,
	passes: { [string]: boolean },
	ovos: { string },
	roubo: string?,
	protegidoAte: number,
	presenteEm: number,
	proximoPresenteEspecial: boolean,
	baseIndice: number,
}

local estado: EstadoTela? = nil
local aoMudarEstado: { () -> () } = {}

------------------------------------------------------------------------
-- Painéis
------------------------------------------------------------------------
local painelAberto: Frame? = nil

local function novoPainel(titulo: string, cor: Color3): (Frame, ScrollingFrame)
	local painel = Instance.new("Frame")
	painel.AnchorPoint = Vector2.new(0.5, 0.5)
	painel.Position = UDim2.fromScale(0.5, 0.52)
	painel.Size = UDim2.fromOffset(620, 460)
	painel.BackgroundColor3 = COR_FUNDO
	painel.Visible = false
	cantos(painel, 18)
	borda(painel, cor, 4)
	painel.Parent = tela

	rotulo(painel, {
		Size = UDim2.new(1, -80, 0, 44),
		Position = UDim2.fromOffset(16, 8),
		Text = titulo,
		TextColor3 = cor,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local fechar = botao(painel, "X", COR_VERMELHO, {
		Size = UDim2.fromOffset(44, 44),
		Position = UDim2.new(1, -54, 0, 8),
	})
	fechar.MouseButton1Click:Connect(function()
		painel.Visible = false
		painelAberto = nil
	end)

	local rolagem = Instance.new("ScrollingFrame")
	rolagem.Position = UDim2.fromOffset(12, 60)
	rolagem.Size = UDim2.new(1, -24, 1, -72)
	rolagem.BackgroundTransparency = 1
	rolagem.BorderSizePixel = 0
	rolagem.ScrollBarThickness = 8
	rolagem.AutomaticCanvasSize = Enum.AutomaticSize.Y
	rolagem.CanvasSize = UDim2.new()
	rolagem.Parent = painel
	return painel, rolagem
end

local function abrir(painel: Frame)
	if painelAberto and painelAberto ~= painel then
		painelAberto.Visible = false
	end
	painel.Visible = not painel.Visible
	painelAberto = if painel.Visible then painel else nil
	if painel.Visible then
		local escala = painel:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
		escala.Parent = painel
		escala.Scale = 0.8
		TweenService:Create(escala, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
end

local function limpar(container: Instance)
	for _, filho in container:GetChildren() do
		if not filho:IsA("UILayout") and not filho:IsA("UIPadding") then
			filho:Destroy()
		end
	end
end

local function lista(pai: Instance, espaco: number?): UIListLayout
	local l = Instance.new("UIListLayout")
	l.Padding = UDim.new(0, espaco or 8)
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.Parent = pai
	return l
end

-- Linha de chances, ex.: "Comum 75% · Raro 22% · Épico 3%"
local function textoChances(pesos: { [string]: number }): string
	local partes = {}
	for _, ch in Util.chances(pesos) do
		local info = Config.Raridades[ch.raridade]
		local cor = "#" .. info.cor:ToHex()
		local numero = if ch.porcento < 1
			then string.format("%.1f", ch.porcento)
			else string.format("%d", math.floor(ch.porcento + 0.5))
		table.insert(partes, string.format('<font color="%s">%s %s%%</font>', cor, info.nome, numero))
	end
	return table.concat(partes, "  ·  ")
end

-- "Dourada 6% (x2) · Diamante 2% (x3) · Arco-íris 0,5% (x5)"
local function textoMutacoes(): string
	local partes = {}
	for _, m in Config.Mutacoes do
		local numero = string.gsub(tostring(m.chance), "%.", ",")
		table.insert(
			partes,
			string.format('<font color="#%s">%s %s%% (x%d)</font>', m.cor:ToHex(), m.nome, numero, m.multiplicador)
		)
	end
	return table.concat(partes, "  ·  ")
end

local function cartao(pai: Instance, altura: number, ordem: number): Frame
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, -12, 0, altura)
	f.BackgroundColor3 = COR_CARTAO
	f.LayoutOrder = ordem
	cantos(f, 12)
	f.Parent = pai
	return f
end

------------------------------------------------------------------------
-- Painel: Ovos (loja de moedas)
------------------------------------------------------------------------
local painelOvos, rolagemOvos = novoPainel("Ovos", COR_AMARELO)
lista(rolagemOvos)
for i, ovo in Config.OvosLoja do
	local c = cartao(rolagemOvos, 110, i)
	rotulo(c, {
		Size = UDim2.new(0.6, 0, 0, 36),
		Position = UDim2.fromOffset(14, 8),
		Text = ovo.nome,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	rotulo(c, {
		Size = UDim2.new(1, -28, 0, 26),
		Position = UDim2.fromOffset(14, 48),
		Text = "Chances: " .. textoChances(ovo.pesos),
		RichText = true,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local comprar = botao(c, Util.numero(ovo.preco) .. " moedas", COR_VERDE, {
		Size = UDim2.fromOffset(170, 40),
		Position = UDim2.new(1, -184, 0, 8),
	})
	comprar.MouseButton1Click:Connect(function()
		ev("ComprarOvo"):FireServer(ovo.id)
	end)
	table.insert(aoMudarEstado, function()
		local pode = estado ~= nil and estado.moedas >= ovo.preco
		comprar.BackgroundColor3 = if pode then COR_VERDE else Color3.fromRGB(110, 110, 120)
	end)
end
rotulo(rolagemOvos, {
	Size = UDim2.new(1, -12, 0, 24),
	LayoutOrder = 98,
	Text = "Mutações (qualquer ovo): " .. textoMutacoes(),
	RichText = true,
})
rotulo(rolagemOvos, {
	Size = UDim2.new(1, -12, 0, 24),
	LayoutOrder = 99,
	Text = "Dica: ovos da chuva no meio do mapa são de graça!",
	TextColor3 = Color3.fromRGB(200, 200, 230),
})

------------------------------------------------------------------------
-- Painel: Fusão
------------------------------------------------------------------------
local painelFusao, rolagemFusao = novoPainel("Fusão", COR_ROXO)
local escolhidas: { string } = {}
local topoFusao = Instance.new("Frame")
topoFusao.Size = UDim2.new(1, -12, 0, 96)
topoFusao.BackgroundTransparency = 1
topoFusao.LayoutOrder = 0
topoFusao.Parent = rolagemFusao
lista(rolagemFusao)
local textoFusao = rotulo(topoFusao, {
	Size = UDim2.new(1, -190, 0, 60),
	Position = UDim2.fromOffset(4, 0),
	Text = "Escolha 2 Misturebas da mesma raridade.",
	TextXAlignment = Enum.TextXAlignment.Left,
	TextWrapped = true,
})
rotulo(topoFusao, {
	Size = UDim2.new(1, -190, 0, 24),
	Position = UDim2.fromOffset(4, 64),
	Text = "Psiu: algumas duplas têm receitas secretas...",
	TextColor3 = Color3.fromRGB(150, 255, 220),
	TextXAlignment = Enum.TextXAlignment.Left,
})
local botaoFundir = botao(topoFusao, "FUNDIR!", COR_ROXO, {
	Size = UDim2.fromOffset(170, 60),
	Position = UDim2.new(1, -174, 0, 10),
})
local grade = Instance.new("Frame")
grade.Size = UDim2.new(1, -12, 0, 0)
grade.AutomaticSize = Enum.AutomaticSize.Y
grade.BackgroundTransparency = 1
grade.LayoutOrder = 1
grade.Parent = rolagemFusao
local layoutGrade = Instance.new("UIGridLayout")
layoutGrade.CellSize = UDim2.fromOffset(136, 92)
layoutGrade.CellPadding = UDim2.fromOffset(8, 8)
layoutGrade.SortOrder = Enum.SortOrder.LayoutOrder
layoutGrade.Parent = grade

local function previaFusao(): (string, boolean)
	if not estado or #escolhidas < 2 then
		return "Escolha 2 Misturebas da mesma raridade.", false
	end
	local idA, idB = estado.criaturas[escolhidas[1]], estado.criaturas[escolhidas[2]]
	if not idA or not idB then
		return "Escolha 2 Misturebas.", false
	end
	local a, b = Config.PorId[idA], Config.PorId[idB]
	local custo = Config.CustoFusao[a.raridade] or 0
	if Util.receita(idA, idB) then
		return "RECEITA SECRETA! Custa " .. Util.numero(custo) .. " moedas.", true
	end
	if a.raridade ~= b.raridade then
		return "As duas precisam ser da mesma raridade.", false
	end
	local proxima = Util.proximaRaridade(a.raridade)
	if not proxima or proxima == "secreto" then
		return "Essa dupla não tem receita... ainda!", false
	end
	return "Vira uma Mistureba "
		.. Config.Raridades[proxima].nome
		.. " aleatória. Custa "
		.. Util.numero(custo)
		.. " moedas.",
		true
end

local function desenharFusao()
	limpar(grade)
	if not estado then
		return
	end
	-- remove escolhas que não existem mais
	for i = #escolhidas, 1, -1 do
		if not estado.criaturas[escolhidas[i]] then
			table.remove(escolhidas, i)
		end
	end
	local vagas = {}
	for vaga in estado.criaturas do
		table.insert(vagas, vaga)
	end
	table.sort(vagas, function(x, y)
		local a, b = Config.PorId[estado.criaturas[x]], Config.PorId[estado.criaturas[y]]
		local ra = table.find(Config.OrdemRaridades, a.raridade) or 0
		local rb = table.find(Config.OrdemRaridades, b.raridade) or 0
		if ra ~= rb then
			return ra > rb
		end
		return a.nome < b.nome
	end)
	for ordem, vaga in vagas do
		local def = Config.PorId[estado.criaturas[vaga]]
		local info = Config.Raridades[def.raridade]
		local selecionada = table.find(escolhidas, vaga) ~= nil
		local b =
			botao(grade, "", if selecionada then Color3.fromRGB(110, 90, 170) else COR_CARTAO, { LayoutOrder = ordem })
		borda(b, if selecionada then Color3.new(1, 1, 1) else info.cor, if selecionada then 4 else 2)
		rotulo(b, { Size = UDim2.fromScale(1, 0.55), Text = def.nome })
		rotulo(b, {
			Size = UDim2.fromScale(1, 0.4),
			Position = UDim2.fromScale(0, 0.58),
			Text = info.nome,
			TextColor3 = info.cor,
		})
		b.MouseButton1Click:Connect(function()
			local i = table.find(escolhidas, vaga)
			if i then
				table.remove(escolhidas, i)
			else
				table.insert(escolhidas, vaga)
				if #escolhidas > 2 then
					table.remove(escolhidas, 1)
				end
			end
			desenharFusao()
		end)
	end
	local texto, pode = previaFusao()
	textoFusao.Text = texto
	botaoFundir.BackgroundColor3 = if pode then COR_ROXO else Color3.fromRGB(110, 110, 120)
end

botaoFundir.MouseButton1Click:Connect(function()
	if #escolhidas == 2 then
		ev("Fundir"):FireServer(escolhidas[1], escolhidas[2])
		escolhidas = {}
	end
end)

------------------------------------------------------------------------
-- Painel: Base (vender e aumentar)
------------------------------------------------------------------------
local painelBase, rolagemBase = novoPainel("Minha base", COR_AZUL)
lista(rolagemBase)

local function desenharBasePainel()
	limpar(rolagemBase)
	if not estado then
		return
	end
	local n = 0
	for _ in estado.criaturas do
		n += 1
	end
	local topo = cartao(rolagemBase, 70, 0)
	local textoVagas = string.format("Vagas: %d / %d", n, estado.vagas)
	if estado.guardadas > 0 then
		textoVagas ..= string.format("  (%d guardadas)", estado.guardadas)
	end
	rotulo(topo, {
		Size = UDim2.new(0.55, 0, 1, -16),
		Position = UDim2.fromOffset(14, 8),
		Text = textoVagas,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local preco = estado.precoMelhoria
	local aumentar = botao(
		topo,
		if preco then "+2 vagas: " .. Util.numero(preco) else "Base no máximo",
		if preco and estado.moedas >= preco then COR_VERDE else Color3.fromRGB(110, 110, 120),
		{ Size = UDim2.fromOffset(220, 50), Position = UDim2.new(1, -230, 0, 10) }
	)
	aumentar.MouseButton1Click:Connect(function()
		ev("MelhorarBase"):FireServer()
	end)

	-- Renascer
	local cartaoRenascer = cartao(rolagemBase, 76, 1)
	local bonusAtual = math.floor(estado.renascimentos * Config.Renascer.bonusPorRenascimento * 100)
	local bonusNovo = math.floor((estado.renascimentos + 1) * Config.Renascer.bonusPorRenascimento * 100)
	rotulo(cartaoRenascer, {
		Size = UDim2.new(1, -250, 0, 30),
		Position = UDim2.fromOffset(14, 6),
		Text = string.format("Renascer (bônus atual: +%d%%)", bonusAtual),
		TextColor3 = Color3.fromRGB(255, 140, 255),
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	rotulo(cartaoRenascer, {
		Size = UDim2.new(1, -250, 0, 34),
		Position = UDim2.fromOffset(14, 38),
		Text = string.format("Começa do zero, mas ganha +%d%% de moedas para sempre.", bonusNovo),
		TextWrapped = true,
		TextColor3 = Color3.fromRGB(210, 210, 235),
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local podeRenascer = estado.moedas >= estado.precoRenascer
	local renascer = botao(
		cartaoRenascer,
		Util.numero(estado.precoRenascer),
		if podeRenascer then Color3.fromRGB(200, 90, 230) else Color3.fromRGB(110, 110, 120),
		{ Size = UDim2.fromOffset(220, 56), Position = UDim2.new(1, -230, 0, 10) }
	)
	local confirmarRenascer = false
	renascer.MouseButton1Click:Connect(function()
		if not confirmarRenascer then
			confirmarRenascer = true
			renascer.Text = "Tem certeza?"
			task.delay(3, function()
				if renascer.Parent then
					confirmarRenascer = false
					renascer.Text = Util.numero(estado and estado.precoRenascer or 0)
				end
			end)
			return
		end
		ev("Renascer"):FireServer()
	end)

	local vagas = {}
	for vaga in estado.criaturas do
		table.insert(vagas, vaga)
	end
	table.sort(vagas, function(a, b)
		return (tonumber(a) or 0) < (tonumber(b) or 0)
	end)
	for ordem, vaga in vagas do
		local def = Config.PorId[estado.criaturas[vaga]]
		local info = Config.Raridades[def.raridade]
		local c = cartao(rolagemBase, 56, ordem)
		rotulo(c, {
			Size = UDim2.new(0.6, 0, 0, 30),
			Position = UDim2.fromOffset(14, 4),
			Text = def.nome .. "  (" .. info.nome .. ")",
			TextColor3 = info.cor,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		rotulo(c, {
			Size = UDim2.new(0.6, 0, 0, 18),
			Position = UDim2.fromOffset(14, 34),
			Text = "+" .. Util.numero(def.renda) .. " moedas/s",
			TextColor3 = COR_VERDE,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		local vender = botao(c, "Vender: " .. Util.numero(def.renda * 60), COR_VERMELHO, {
			Size = UDim2.fromOffset(190, 40),
			Position = UDim2.new(1, -200, 0, 8),
		})
		local confirmar = false
		vender.MouseButton1Click:Connect(function()
			if not confirmar then
				confirmar = true
				vender.Text = "Tem certeza?"
				task.delay(2.5, function()
					if vender.Parent then
						confirmar = false
						vender.Text = "Vender: " .. Util.numero(def.renda * 60)
					end
				end)
				return
			end
			ev("Vender"):FireServer(vaga)
		end)
	end
end

------------------------------------------------------------------------
-- Painel: Misturedex (coleção)
------------------------------------------------------------------------
local painelDex, rolagemDex = novoPainel("Misturedex", Color3.fromRGB(60, 200, 190))
local layoutDex = Instance.new("UIGridLayout")
layoutDex.CellSize = UDim2.fromOffset(136, 110)
layoutDex.CellPadding = UDim2.fromOffset(8, 8)
layoutDex.SortOrder = Enum.SortOrder.LayoutOrder
layoutDex.Parent = rolagemDex

local function desenharDex()
	limpar(rolagemDex)
	if not estado then
		return
	end
	local achadas = 0
	for i, def in Config.Criaturas do
		local info = Config.Raridades[def.raridade]
		local tem = estado.descobertas[def.id] == true
		if tem then
			achadas += 1
		end
		local c = Instance.new("Frame")
		c.LayoutOrder = i
		c.BackgroundColor3 = if tem then COR_CARTAO else Color3.fromRGB(30, 28, 45)
		cantos(c, 12)
		borda(c, if tem then info.cor else Color3.fromRGB(70, 70, 90), 2)
		c.Parent = rolagemDex
		rotulo(c, {
			Size = UDim2.new(1, -8, 0, 44),
			Position = UDim2.fromOffset(4, 6),
			Text = if tem then def.nome else "???",
			TextWrapped = true,
		})
		rotulo(c, {
			Size = UDim2.new(1, -8, 0, 24),
			Position = UDim2.fromOffset(4, 52),
			Text = info.nome,
			TextColor3 = info.cor,
		})
		rotulo(c, {
			Size = UDim2.new(1, -8, 0, 22),
			Position = UDim2.fromOffset(4, 80),
			Text = if tem then "+" .. Util.numero(def.renda) .. "/s" else "",
			TextColor3 = COR_VERDE,
		})
	end
	local titulo = painelDex:FindFirstChildOfClass("TextLabel")
	if titulo then
		titulo.Text = string.format("Misturedex  %d/%d", achadas, #Config.Criaturas)
	end
end

------------------------------------------------------------------------
-- Painel: Loja (Robux)
------------------------------------------------------------------------
local painelLoja, rolagemLoja = novoPainel("Loja", COR_VERDE)
lista(rolagemLoja)

local function itemLoja(
	ordem: number,
	nome: string,
	descricao: string,
	preco: number,
	id: number,
	ehPasse: boolean,
	chave: string,
	extra: string?
)
	local c = cartao(rolagemLoja, if extra then 136 else 86, ordem)
	rotulo(c, {
		Size = UDim2.new(1, -230, 0, 34),
		Position = UDim2.fromOffset(14, 6),
		Text = nome,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	rotulo(c, {
		Size = UDim2.new(1, -230, 0, 40),
		Position = UDim2.fromOffset(14, 40),
		Text = descricao,
		TextWrapped = true,
		TextColor3 = Color3.fromRGB(210, 210, 235),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	})
	if extra then
		rotulo(c, {
			Size = UDim2.new(1, -28, 0, 44),
			Position = UDim2.fromOffset(14, 84),
			Text = extra,
			RichText = true,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
	end
	local b = botao(c, preco .. " Robux", COR_VERDE, {
		Size = UDim2.fromOffset(190, 50),
		Position = UDim2.new(1, -200, 0, 16),
	})
	local function atualizar()
		if id == 0 then
			b.Text = "Em breve"
			b.BackgroundColor3 = Color3.fromRGB(110, 110, 120)
		elseif ehPasse and estado and estado.passes[chave] then
			b.Text = "Você tem!"
			b.BackgroundColor3 = COR_AZUL
		else
			b.Text = preco .. " Robux"
			b.BackgroundColor3 = COR_VERDE
		end
	end
	table.insert(aoMudarEstado, atualizar)
	atualizar()
	b.MouseButton1Click:Connect(function()
		if id == 0 or (ehPasse and estado and estado.passes[chave]) then
			return
		end
		if ehPasse then
			MarketplaceService:PromptGamePassPurchase(jogador, id)
		else
			MarketplaceService:PromptProductPurchase(jogador, id)
		end
	end)
end

rotulo(rolagemLoja, {
	Size = UDim2.new(1, -12, 0, 26),
	LayoutOrder = 0,
	Text = "Peça permissão a um adulto antes de comprar com Robux.",
	TextColor3 = COR_AMARELO,
})
local ordemLoja = 1
for _, chave in { "vip", "mochila", "cadeado", "basegrande" } do
	local p = Config.Gamepasses[chave]
	itemLoja(ordemLoja, p.nome, p.descricao, p.preco, p.id, true, chave, nil)
	ordemLoja += 1
end
for _, chave in { "sorte", "ovoarcoiris", "moedas" } do
	local p = Config.Produtos[chave]
	local extra = if chave == "ovoarcoiris"
		then "Chances: " .. textoChances(Config.OvoArcoIrisPesos) .. "\nMutações: " .. textoMutacoes()
		else nil
	itemLoja(ordemLoja, p.nome, p.descricao, p.preco, p.id, false, chave, extra)
	ordemLoja += 1
end

------------------------------------------------------------------------
-- Avisos (canto) e anúncios (faixa grande)
------------------------------------------------------------------------
local pilhaAvisos = Instance.new("Frame")
pilhaAvisos.BackgroundTransparency = 1
pilhaAvisos.AnchorPoint = Vector2.new(0.5, 1)
pilhaAvisos.Position = UDim2.new(0.5, 0, 1, -20)
pilhaAvisos.Size = UDim2.fromOffset(560, 160)
pilhaAvisos.Parent = tela
local listaAvisos = lista(pilhaAvisos, 6)
listaAvisos.VerticalAlignment = Enum.VerticalAlignment.Bottom
listaAvisos.HorizontalAlignment = Enum.HorizontalAlignment.Center

local contadorAviso = 0
ev("Aviso").OnClientEvent:Connect(function(texto: string, cor: Color3)
	contadorAviso += 1
	local f = Instance.new("Frame")
	f.Size = UDim2.fromOffset(540, 40)
	f.BackgroundColor3 = COR_FUNDO
	f.BackgroundTransparency = 0.15
	f.LayoutOrder = contadorAviso
	cantos(f, 10)
	borda(f, cor, 2)
	rotulo(f, { Size = UDim2.new(1, -16, 1, -8), Position = UDim2.fromOffset(8, 4), Text = texto, TextColor3 = cor })
	f.Parent = pilhaAvisos
	local filhos = pilhaAvisos:GetChildren()
	if #filhos > 5 then
		for _, filho in filhos do
			if filho:IsA("Frame") then
				filho:Destroy()
				break
			end
		end
	end
	task.delay(4, function()
		f:Destroy()
	end)
end)

local faixa = rotulo(tela, {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 120),
	Size = UDim2.fromOffset(760, 52),
	Text = "",
	Visible = false,
	TextStrokeTransparency = 0,
})
local idFaixa = 0
ev("Anuncio").OnClientEvent:Connect(function(texto: string, cor: Color3)
	idFaixa += 1
	local meu = idFaixa
	faixa.Text = texto
	faixa.TextColor3 = cor
	faixa.Visible = true
	faixa.TextTransparency = 1
	TweenService:Create(faixa, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()
	task.delay(5, function()
		if meu == idFaixa then
			faixa.Visible = false
		end
	end)
end)

------------------------------------------------------------------------
-- Cartão "Você ganhou!"
------------------------------------------------------------------------
local cartaoGanhou = Instance.new("Frame")
cartaoGanhou.AnchorPoint = Vector2.new(0.5, 0.5)
cartaoGanhou.Position = UDim2.fromScale(0.5, 0.45)
cartaoGanhou.Size = UDim2.fromOffset(420, 230)
cartaoGanhou.BackgroundColor3 = COR_FUNDO
cartaoGanhou.Visible = false
cantos(cartaoGanhou, 20)
local bordaGanhou = Instance.new("UIStroke")
bordaGanhou.Thickness = 5
bordaGanhou.Parent = cartaoGanhou
cartaoGanhou.Parent = tela
rotulo(cartaoGanhou, { Size = UDim2.new(1, -20, 0, 34), Position = UDim2.fromOffset(10, 10), Text = "VOCÊ GANHOU!" })
local ganhouNome = rotulo(cartaoGanhou, { Size = UDim2.new(1, -20, 0, 52), Position = UDim2.fromOffset(10, 48) })
local ganhouRaridade = rotulo(cartaoGanhou, { Size = UDim2.new(1, -20, 0, 30), Position = UDim2.fromOffset(10, 102) })
local ganhouDescricao = rotulo(cartaoGanhou, {
	Size = UDim2.new(1, -30, 0, 54),
	Position = UDim2.fromOffset(15, 136),
	TextWrapped = true,
	TextColor3 = Color3.fromRGB(210, 210, 235),
})
local ganhouRenda = rotulo(
	cartaoGanhou,
	{ Size = UDim2.new(1, -20, 0, 28), Position = UDim2.fromOffset(10, 194), TextColor3 = COR_VERDE }
)
local idGanhou = 0
ev("Chocou").OnClientEvent:Connect(function(id: string)
	local def = Config.PorId[id]
	if not def then
		return
	end
	local info = Config.Raridades[def.raridade]
	idGanhou += 1
	local meu = idGanhou
	ganhouNome.Text = def.nome
	local mut = def.mutacao and Config.MutacaoPorId[def.mutacao]
	ganhouRaridade.Text = if mut then info.nome .. " · MUTAÇÃO " .. string.upper(mut.nome) else info.nome
	ganhouRaridade.TextColor3 = if mut then mut.cor else info.cor
	ganhouDescricao.Text = def.descricao
	ganhouRenda.Text = "+" .. Util.numero(def.renda) .. " moedas por segundo"
	bordaGanhou.Color = info.cor
	cartaoGanhou.Visible = true
	local escala = cartaoGanhou:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	escala.Parent = cartaoGanhou
	escala.Scale = 0.3
	TweenService:Create(escala, TweenInfo.new(0.45, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	task.delay(3.2, function()
		if meu == idGanhou then
			cartaoGanhou.Visible = false
		end
	end)
end)

------------------------------------------------------------------------
-- Botões e teclas
------------------------------------------------------------------------
botaoOvos.MouseButton1Click:Connect(function()
	abrir(painelOvos)
end)
botaoFusao.MouseButton1Click:Connect(function()
	escolhidas = {}
	desenharFusao()
	abrir(painelFusao)
end)
botaoBase.MouseButton1Click:Connect(function()
	desenharBasePainel()
	abrir(painelBase)
end)
botaoDex.MouseButton1Click:Connect(function()
	desenharDex()
	abrir(painelDex)
end)
botaoLoja.MouseButton1Click:Connect(function()
	abrir(painelLoja)
end)

local function tapa()
	ev("Tapa"):FireServer()
	local personagem = jogador.Character
	local hum = personagem and personagem:FindFirstChildOfClass("Humanoid")
	if hum then
		-- giradinha rápida como "tapa"
		local raiz = personagem:FindFirstChild("HumanoidRootPart") :: BasePart?
		if raiz then
			raiz.AssemblyAngularVelocity = Vector3.new(0, 25, 0)
		end
	end
end
botaoTapa.MouseButton1Click:Connect(tapa)
botaoTrancar.MouseButton1Click:Connect(function()
	ev("Trancar"):FireServer()
end)
botaoSoltar.MouseButton1Click:Connect(function()
	ev("Soltar"):FireServer()
end)

UserInputService.InputBegan:Connect(function(entrada, processado)
	if processado then
		return
	end
	if entrada.KeyCode == Enum.KeyCode.F then
		tapa()
	elseif entrada.KeyCode == Enum.KeyCode.T then
		ev("Trancar"):FireServer()
	elseif entrada.KeyCode == Enum.KeyCode.G then
		ev("Soltar"):FireServer()
	end
end)

ev("Empurrao").OnClientEvent:Connect(function(direcao: Vector3)
	local personagem = jogador.Character
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart") :: BasePart?
	if raiz then
		raiz.AssemblyLinearVelocity = direcao * 55 + Vector3.new(0, 30, 0)
	end
end)

------------------------------------------------------------------------
-- Atualização da tela
------------------------------------------------------------------------
local function atualizarStatus()
	if not estado then
		return
	end
	local t = workspace:GetServerTimeNow()
	local partes = {}
	if estado.roubo then
		table.insert(
			partes,
			'<font color="#FF7070">Carregando ' .. Config.PorId[estado.roubo].nome .. "! Corra para sua base!</font>"
		)
	elseif #estado.ovos > 0 then
		table.insert(
			partes,
			'<font color="#FFE070">Carregando ' .. #estado.ovos .. " ovo(s). Leve para sua base!</font>"
		)
	end
	if t < estado.cadeadoAte then
		table.insert(
			partes,
			string.format('<font color="#80FF90">Trancada: %d s</font>', math.ceil(estado.cadeadoAte - t))
		)
	end
	if t < estado.protegidoAte then
		table.insert(
			partes,
			string.format('<font color="#90D0FF">Proteção de novato: %d s</font>', math.ceil(estado.protegidoAte - t))
		)
	end
	if t < estado.sorteAte then
		table.insert(
			partes,
			string.format('<font color="#80FFB0">Sorte 2x: %d min</font>', math.ceil((estado.sorteAte - t) / 60))
		)
	end
	if estado.presenteEm and estado.presenteEm > t then
		local falta = math.ceil(estado.presenteEm - t)
		table.insert(
			partes,
			string.format(
				'<font color="#FFD070">%s grátis em %d:%02d</font>',
				if estado.proximoPresenteEspecial then "Ovo Brilhante" else "Ovo",
				falta // 60,
				falta % 60
			)
		)
	end
	textoStatus.Text = table.concat(partes, "   ")

	if t < estado.cadeadoAte then
		botaoTrancar.Text = string.format("TRANCADA %d", math.ceil(estado.cadeadoAte - t))
		botaoTrancar.BackgroundColor3 = COR_AZUL
	elseif t < estado.cadeadoLivreEm then
		botaoTrancar.Text = string.format("RECARGA %d", math.ceil(estado.cadeadoLivreEm - t))
		botaoTrancar.BackgroundColor3 = Color3.fromRGB(110, 110, 120)
	else
		botaoTrancar.Text = "TRANCAR (T)"
		botaoTrancar.BackgroundColor3 = COR_VERDE
	end
	botaoSoltar.Visible = estado.roubo ~= nil or #estado.ovos > 0
end

ev("Estado").OnClientEvent:Connect(function(novo: EstadoTela)
	local mudouCriaturas = true
	if estado then
		mudouCriaturas = false
		for vaga, id in novo.criaturas do
			if estado.criaturas[vaga] ~= id then
				mudouCriaturas = true
			end
		end
		for vaga in estado.criaturas do
			if novo.criaturas[vaga] == nil then
				mudouCriaturas = true
			end
		end
		mudouCriaturas = mudouCriaturas
			or estado.vagas ~= novo.vagas
			or estado.precoMelhoria ~= novo.precoMelhoria
			or estado.renascimentos ~= novo.renascimentos
	end
	estado = novo
	textoMoedas.Text = Util.numero(novo.moedas) .. " moedas"
	textoRenda.Text = "+" .. Util.numero(novo.renda) .. "/s"
	for _, f in aoMudarEstado do
		f()
	end
	atualizarStatus()
	if mudouCriaturas then
		if painelFusao.Visible then
			desenharFusao()
		end
		if painelBase.Visible then
			desenharBasePainel()
		end
		if painelDex.Visible then
			desenharDex()
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(0.25)
		atualizarStatus()
	end
end)
