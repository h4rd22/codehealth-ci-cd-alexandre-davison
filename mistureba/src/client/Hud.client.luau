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

-- Moedas no topo: moeda que gira, número que sobe contando, renda por segundo e multiplicador
local barraMoedas = Instance.new("Frame")
barraMoedas.AnchorPoint = Vector2.new(0.5, 0)
barraMoedas.Position = UDim2.new(0.5, 0, 0, 8)
barraMoedas.Size = UDim2.fromOffset(340, 76)
barraMoedas.BackgroundColor3 = Color3.new(1, 1, 1)
barraMoedas.BackgroundTransparency = 0.08
cantos(barraMoedas, 20)
borda(barraMoedas, COR_AMARELO, 3)
barraMoedas.Parent = tela
local fundoMoedas = Instance.new("UIGradient")
fundoMoedas.Color = ColorSequence.new(Color3.fromRGB(70, 50, 120), Color3.fromRGB(30, 26, 55))
fundoMoedas.Rotation = 90
fundoMoedas.Parent = barraMoedas

local moeda = Instance.new("Frame")
moeda.AnchorPoint = Vector2.new(0.5, 0.5)
moeda.Position = UDim2.fromOffset(40, 38)
moeda.Size = UDim2.fromOffset(54, 54)
moeda.BackgroundColor3 = Color3.new(1, 1, 1)
cantos(moeda, 27)
borda(moeda, Color3.fromRGB(190, 110, 10), 3)
moeda.Parent = barraMoedas
local corMoeda = Instance.new("UIGradient")
corMoeda.Color = ColorSequence.new(Color3.fromRGB(255, 240, 120), Color3.fromRGB(255, 160, 30))
corMoeda.Rotation = 45
corMoeda.Parent = moeda
rotulo(moeda, {
	Size = UDim2.fromScale(0.7, 0.7),
	Position = UDim2.fromScale(0.15, 0.15),
	Text = "M",
	TextColor3 = Color3.fromRGB(170, 95, 0),
	TextStrokeTransparency = 1,
})

local textoMoedas = rotulo(barraMoedas, {
	Size = UDim2.new(1, -86, 0, 42),
	Position = UDim2.fromOffset(76, 4),
	Text = "0",
	TextColor3 = COR_AMARELO,
	TextXAlignment = Enum.TextXAlignment.Left,
})
local escalaMoedas = Instance.new("UIScale")
escalaMoedas.Parent = textoMoedas
local textoRenda = rotulo(barraMoedas, {
	Size = UDim2.new(1, -170, 0, 24),
	Position = UDim2.fromOffset(78, 46),
	Text = "+0/s",
	TextColor3 = COR_VERDE,
	TextXAlignment = Enum.TextXAlignment.Left,
})
-- bônus total da renda (VIP, renascimentos, Dex e Renda Turbo juntos)
local chipMult = rotulo(barraMoedas, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -10, 0, 46),
	Size = UDim2.fromOffset(76, 24),
	BackgroundTransparency = 0,
	BackgroundColor3 = COR_ROXO,
	Text = "x1",
	Visible = false,
})
cantos(chipMult, 12)

-- a moeda dá uma girada de vez em quando
task.spawn(function()
	while true do
		task.wait(4)
		local ida = TweenService:Create(moeda, TweenInfo.new(0.18), { Size = UDim2.fromOffset(6, 54) })
		ida:Play()
		ida.Completed:Wait()
		TweenService:Create(moeda, TweenInfo.new(0.18), { Size = UDim2.fromOffset(54, 54) }):Play()
	end
end)

local moedasAlvo, moedasMostradas, ultimoTextoMoedas = 0, 0, -1
local function mostrarMoedas(novas: number, rendaAtual: number)
	local diferenca = novas - moedasAlvo
	moedasAlvo = novas
	if diferenca == 0 then
		return
	end
	escalaMoedas.Scale = if diferenca > 0 then 1.12 else 0.92
	TweenService:Create(escalaMoedas, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	textoMoedas.TextColor3 = if diferenca > 0 then COR_AMARELO else Color3.fromRGB(255, 120, 120)
	if diferenca < 0 then
		task.delay(0.35, function()
			textoMoedas.TextColor3 = COR_AMARELO
		end)
	end
	-- ganho grande (venda, prêmio, roleta...) sobe um "+N" na tela
	if math.abs(diferenca) > math.max(rendaAtual * 3, 10) then
		local voa = rotulo(tela, {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 40, 0, 70),
			Size = UDim2.fromOffset(220, 34),
			Text = (if diferenca > 0 then "+" else "-") .. Util.numero(math.abs(diferenca)),
			TextColor3 = if diferenca > 0 then COR_VERDE else COR_VERMELHO,
			ZIndex = 5,
		})
		TweenService:Create(voa, TweenInfo.new(1.2), {
			Position = UDim2.new(0.5, 40, 0, if diferenca > 0 then 20 else 110),
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		}):Play()
		task.delay(1.3, function()
			voa:Destroy()
		end)
	end
end
game:GetService("RunService").Heartbeat:Connect(function(dt)
	if moedasMostradas ~= moedasAlvo then
		moedasMostradas += (moedasAlvo - moedasMostradas) * math.min(1, dt * 8)
		if math.abs(moedasAlvo - moedasMostradas) < 1 then
			moedasMostradas = moedasAlvo
		end
		local inteiro = math.floor(moedasMostradas + 0.5)
		if inteiro ~= ultimoTextoMoedas then
			ultimoTextoMoedas = inteiro
			textoMoedas.Text = Util.numero(inteiro)
		end
	end
end)

-- Clima do servidor: faixa embaixo das moedas com o relógio
local faixaClima = Instance.new("Frame")
faixaClima.AnchorPoint = Vector2.new(0.5, 0)
faixaClima.Position = UDim2.new(0.5, 0, 0, 90)
faixaClima.Size = UDim2.fromOffset(340, 30)
faixaClima.BackgroundColor3 = COR_FUNDO
faixaClima.BackgroundTransparency = 0.25
cantos(faixaClima, 15)
local bordaClima = Instance.new("UIStroke")
bordaClima.Thickness = 2
bordaClima.Color = Color3.fromRGB(120, 120, 150)
bordaClima.Parent = faixaClima
faixaClima.Parent = tela
local textoClima = rotulo(faixaClima, {
	Size = UDim2.new(1, -16, 0, 22),
	Position = UDim2.fromOffset(8, 3),
	Text = "",
	RichText = true,
})
local descClima = rotulo(faixaClima, {
	Size = UDim2.new(1, -16, 0, 20),
	Position = UDim2.fromOffset(8, 27),
	Text = "",
	TextColor3 = Color3.fromRGB(230, 230, 250),
})

-- Linha de status (carregando, cadeado, sorte, proteção)
local textoStatus = rotulo(tela, {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 146),
	Size = UDim2.fromOffset(560, 26),
	Text = "",
	RichText = true,
})

-- Botões da esquerda
local menu = Instance.new("Frame")
menu.BackgroundTransparency = 1
menu.AnchorPoint = Vector2.new(0, 0.5)
menu.Position = UDim2.new(0, 10, 0.5, 0)
menu.Size = UDim2.fromOffset(120, 640)
menu.Parent = tela
local listaMenu = Instance.new("UIListLayout")
listaMenu.Padding = UDim.new(0, 10)
listaMenu.SortOrder = Enum.SortOrder.LayoutOrder
listaMenu.Parent = menu
-- no celular o menu vira 2 colunas lá em cima, longe do controle de andar (que fica embaixo à esquerda)
local gradeMenu = Instance.new("UIGridLayout")
gradeMenu.CellSize = UDim2.fromOffset(120, 62)
gradeMenu.CellPadding = UDim2.fromOffset(8, 8)
gradeMenu.FillDirectionMaxCells = 2
gradeMenu.SortOrder = Enum.SortOrder.LayoutOrder
local TOQUE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local function dica(tecla: string): string
	return if TOQUE then "" else " (" .. tecla .. ")"
end
local function ajustarMenu()
	local compacto = TOQUE or camera.ViewportSize.Y < 560
	if compacto then
		listaMenu.Parent = nil
		gradeMenu.Parent = menu
		menu.AnchorPoint = Vector2.new(0, 0)
		menu.Position = UDim2.fromOffset(10, 10)
		menu.Size = UDim2.fromOffset(250, 350)
	else
		gradeMenu.Parent = nil
		listaMenu.Parent = menu
		menu.AnchorPoint = Vector2.new(0, 0.5)
		menu.Position = UDim2.new(0, 10, 0.5, 0)
		menu.Size = UDim2.fromOffset(120, 640)
	end
end

local botaoOvos = botao(menu, "OVOS", COR_AMARELO, { Size = UDim2.fromOffset(120, 62), LayoutOrder = 1 })
local botaoFusao = botao(menu, "FUSÃO", COR_ROXO, { Size = UDim2.fromOffset(120, 62), LayoutOrder = 2 })
local botaoBase = botao(menu, "BASE", COR_AZUL, { Size = UDim2.fromOffset(120, 62), LayoutOrder = 3 })
local botaoLoja = botao(menu, "LOJA", COR_VERDE, { Size = UDim2.fromOffset(120, 62), LayoutOrder = 4 })
local botaoDex = botao(menu, "DEX", Color3.fromRGB(60, 200, 190), { Size = UDim2.fromOffset(120, 62), LayoutOrder = 5 })
local botaoMissoes =
	botao(menu, "MISSÕES", Color3.fromRGB(255, 150, 60), { Size = UDim2.fromOffset(120, 62), LayoutOrder = 6 })
local COR_TROCA = Color3.fromRGB(70, 200, 230)
local botaoTrocar = botao(menu, "TROCAR", COR_TROCA, { Size = UDim2.fromOffset(120, 62), LayoutOrder = 8 })
local botaoMelhorar =
	botao(menu, "MELHORAR", Color3.fromRGB(255, 160, 40), { Size = UDim2.fromOffset(120, 62), LayoutOrder = 9 })
local botaoRoleta =
	botao(menu, "ROLETA", Color3.fromRGB(255, 90, 160), { Size = UDim2.fromOffset(120, 62), LayoutOrder = 7 })
local alertaRoleta = rotulo(botaoRoleta, {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(1, -4, 0, 4),
	Size = UDim2.fromOffset(26, 26),
	BackgroundTransparency = 0,
	BackgroundColor3 = COR_VERMELHO,
	Text = "!",
	Visible = false,
})
-- bolinha "!" quando tem prêmio de missão para pegar
local alertaMissoes = rotulo(botaoMissoes, {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(1, -4, 0, 4),
	Size = UDim2.fromOffset(26, 26),
	BackgroundTransparency = 0,
	BackgroundColor3 = COR_VERMELHO,
	Text = "!",
	Visible = false,
})
cantos(alertaMissoes, 13)
ajustarMenu()
camera:GetPropertyChangedSignal("ViewportSize"):Connect(ajustarMenu)

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
local botaoTapa = botao(
	acoes,
	"BOLHA" .. dica("F"),
	Color3.fromRGB(90, 170, 255),
	{ Size = UDim2.fromOffset(150, 64), LayoutOrder = 1 }
)
local botaoTrancar =
	botao(acoes, "TRANCAR" .. dica("T"), COR_VERDE, { Size = UDim2.fromOffset(150, 64), LayoutOrder = 2 })
local botaoSoltar = botao(acoes, "SOLTAR" .. dica("G"), Color3.fromRGB(120, 120, 140), {
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
	roletaEm: number,
	proximoPresenteEspecial: boolean,
	missoes: { { texto: string, meta: number, progresso: number, pega: boolean } },
	missoesFinal: boolean,
	premioMissao: number,
	bonusDex: number,
	baseIndice: number,
	upgrades: { [string]: number },
	clima: string?,
	pocoes: number?,
	climaAte: number?,
	proximoClima: number?,
	rastros: { [string]: boolean },
	rastro: string?,
	multiplicador: number?,
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
		if m.soClima then
			continue
		end
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
topoFusao.Size = UDim2.new(1, -12, 0, 122)
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
local textoHeranca = rotulo(topoFusao, {
	Size = UDim2.new(1, -8, 0, 24),
	Position = UDim2.fromOffset(4, 92),
	Text = "",
	TextColor3 = Color3.fromRGB(255, 220, 120),
	TextXAlignment = Enum.TextXAlignment.Left,
})
local function atualizarHeranca()
	local sorte = estado ~= nil and estado.passes.sortedupla == true
	local chance = if sorte then Config.FusaoHerdarMutacaoSorte else Config.FusaoHerdarMutacao
	textoHeranca.Text = "Mutações (Dourada, Gigante, Mini...) têm "
		.. math.floor(chance * 100 + 0.5)
		.. "% de chance de passar na fusão"
		.. (if sorte then " (Sorte Dupla!)" else "")
end
atualizarHeranca()
table.insert(aoMudarEstado, atualizarHeranca)
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
		local vender = botao(c, "Vender: " .. Util.numero(def.renda * Config.VendaSegundos), COR_VERMELHO, {
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
						vender.Text = "Vender: " .. Util.numero(def.renda * Config.VendaSegundos)
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
		c.LayoutOrder = (table.find(Config.OrdemRaridades, def.raridade) or 9) * 100 + i
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
		local bonus, proximo = Util.bonusDex(achadas)
		local texto =
			string.format("Misturedex  %d/%d  ·  +%d%% renda", achadas, #Config.Criaturas, math.floor(bonus * 100))
		if proximo then
			texto ..= string.format("  (%d: +%d%%)", proximo.achadas, math.floor(proximo.bonus * 100))
		end
		titulo.Text = texto
		titulo.TextScaled = true
	end
end

------------------------------------------------------------------------
-- Painel: Missões do dia
------------------------------------------------------------------------
local painelMissoes, rolagemMissoes = novoPainel("Missões do dia", Color3.fromRGB(255, 150, 60))
lista(rolagemMissoes)

local function desenharMissoes()
	limpar(rolagemMissoes)
	if not estado or not estado.missoes then
		return
	end
	for i, m in estado.missoes do
		local c = cartao(rolagemMissoes, 92, i)
		rotulo(c, {
			Size = UDim2.new(1, -230, 0, 32),
			Position = UDim2.fromOffset(14, 6),
			Text = m.texto,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		local barra = Instance.new("Frame")
		barra.Size = UDim2.new(1, -230, 0, 20)
		barra.Position = UDim2.fromOffset(14, 46)
		barra.BackgroundColor3 = Color3.fromRGB(40, 38, 60)
		cantos(barra, 10)
		barra.Parent = c
		local cheio = Instance.new("Frame")
		cheio.Size = UDim2.fromScale(math.clamp(m.progresso / m.meta, 0, 1), 1)
		cheio.BackgroundColor3 = if m.progresso >= m.meta then COR_VERDE else Color3.fromRGB(255, 150, 60)
		cantos(cheio, 10)
		cheio.Parent = barra
		rotulo(barra, {
			Size = UDim2.fromScale(1, 1),
			Text = string.format("%d / %d", m.progresso, m.meta),
			TextStrokeTransparency = 0.3,
		})
		local pronto = m.progresso >= m.meta
		local b = botao(
			c,
			if m.pega then "Pego!" elseif pronto then "PEGAR" else "+" .. Util.numero(estado.premioMissao),
			if m.pega then COR_AZUL elseif pronto then COR_VERDE else Color3.fromRGB(110, 110, 120),
			{ Size = UDim2.fromOffset(190, 50), Position = UDim2.new(1, -200, 0, 20) }
		)
		if pronto and not m.pega then
			b.MouseButton1Click:Connect(function()
				ev("PegarMissao"):FireServer(i)
			end)
		end
	end
	local final = cartao(rolagemMissoes, 60, 10)
	local ovoFinal = Config.Missoes.ovoFinal
	for _, ovo in Config.OvosLoja do
		if ovo.id == ovoFinal then
			ovoFinal = ovo.nome
		end
	end
	rotulo(final, {
		Size = UDim2.new(1, -28, 1, -8),
		Position = UDim2.fromOffset(14, 4),
		Text = if estado.missoesFinal
			then "Você completou tudo hoje! Novas missões amanhã."
			else "Complete as 3 e ganhe um " .. ovoFinal .. " grátis!",
		TextColor3 = COR_AMARELO,
		TextWrapped = true,
	})
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

local ordemLoja = 1
for _, chave in { "vip", "sortedupla", "mochila", "rapido", "cadeado", "basegrande" } do
	local p = Config.Gamepasses[chave]
	itemLoja(ordemLoja, p.nome, p.descricao, p.preco, p.id, true, chave, nil)
	ordemLoja += 1
end
for _, chave in { "pocao", "sorte", "ovoarcoiris", "presente", "moedas" } do
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

-- Efeitos de chocar: som que sobe de tom, flash, raios girando e confete.
-- Quanto mais rara, mais festa.
local function tocar(tom: number, volume: number)
	local som = Instance.new("Sound")
	som.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	som.PlaybackSpeed = tom
	som.Volume = volume
	som.Parent = tela
	som:Play()
	som.Ended:Once(function()
		som:Destroy()
	end)
end

local camadaFesta = Instance.new("Frame")
camadaFesta.Size = UDim2.fromScale(1, 1)
camadaFesta.BackgroundTransparency = 1
camadaFesta.ZIndex = 0
camadaFesta.Parent = tela

local function festa(nivel: number, cor: Color3)
	-- som: uma nota por nível, subindo
	task.spawn(function()
		for i = 1, math.min(nivel + 1, 7) do
			tocar(0.8 + i * 0.18, 0.35 + nivel * 0.05)
			task.wait(0.09)
		end
	end)
	local centro = cartaoGanhou.Position
	-- flash da cor da raridade
	if nivel >= 3 then
		local flash = Instance.new("Frame")
		flash.Size = UDim2.fromScale(1, 1)
		flash.BackgroundColor3 = cor
		flash.BackgroundTransparency = 0.35
		flash.Parent = camadaFesta
		TweenService:Create(flash, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
		task.delay(0.7, function()
			flash:Destroy()
		end)
	end
	-- raios girando atrás do cartão
	if nivel >= 3 then
		local raios = Instance.new("Frame")
		raios.AnchorPoint = Vector2.new(0.5, 0.5)
		raios.Position = centro
		raios.Size = UDim2.fromOffset(10, 10)
		raios.BackgroundTransparency = 1
		raios.Parent = camadaFesta
		for i = 1, 8 do
			local r = Instance.new("Frame")
			r.AnchorPoint = Vector2.new(0.5, 0.5)
			r.Position = UDim2.fromScale(0.5, 0.5)
			r.Size = UDim2.fromOffset(1100, 46)
			r.Rotation = i * 22.5
			r.BackgroundColor3 = cor
			r.BackgroundTransparency = 0.6
			r.BorderSizePixel = 0
			local g = Instance.new("UIGradient")
			g.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.5, 0),
				NumberSequenceKeypoint.new(1, 1),
			})
			g.Parent = r
			r.Parent = raios
		end
		local duracao = 2.5 + nivel * 0.4
		TweenService:Create(raios, TweenInfo.new(duracao, Enum.EasingStyle.Linear), { Rotation = 120 }):Play()
		task.delay(duracao, function()
			raios:Destroy()
		end)
	end
	-- confete
	local cores =
		{ cor, COR_AMARELO, Color3.fromRGB(255, 120, 200), Color3.fromRGB(120, 220, 255), Color3.new(1, 1, 1) }
	for _ = 1, 6 + nivel * 6 do
		local p = Instance.new("Frame")
		p.AnchorPoint = Vector2.new(0.5, 0.5)
		p.Position = centro
		local lado = math.random(8, 16)
		p.Size = UDim2.fromOffset(lado, lado * 0.6)
		p.Rotation = math.random(0, 360)
		p.BackgroundColor3 = cores[math.random(1, #cores)]
		p.BorderSizePixel = 0
		p.Parent = camadaFesta
		local angulo = math.random() * math.pi * 2
		local dist = math.random(180, 300 + nivel * 60)
		local destino = centro + UDim2.fromOffset(math.cos(angulo) * dist, math.sin(angulo) * dist + 120)
		local t = 0.9 + math.random() * 0.8
		TweenService:Create(p, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = destino,
			Rotation = p.Rotation + math.random(-360, 360),
			BackgroundTransparency = 1,
		}):Play()
		task.delay(t, function()
			p:Destroy()
		end)
	end
end
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
	local nivel = (table.find(Config.OrdemRaridades, def.raridade) or 1) + (if mut then 1 else 0)
	festa(nivel, if mut then mut.cor else info.cor)
	task.delay(3 + nivel * 0.4, function()
		if meu == idGanhou then
			cartaoGanhou.Visible = false
		end
	end)
end)

------------------------------------------------------------------------
-- Painel: Roleta grátis (um giro a cada 10 minutos jogando, chances na tela)
------------------------------------------------------------------------
local COR_ROLETA = Color3.fromRGB(255, 90, 160)
local painelRoleta, rolagemRoleta = novoPainel("Roleta grátis", COR_ROLETA)
local LARGURA_CARTA, PASSO_CARTA = 120, 130
local DURACAO_GIRO = 4

local janela = Instance.new("Frame")
janela.Size = UDim2.new(1, -16, 0, 150)
janela.Position = UDim2.fromOffset(4, 4)
janela.BackgroundColor3 = Color3.fromRGB(25, 22, 45)
janela.ClipsDescendants = true
cantos(janela, 14)
borda(janela, COR_ROLETA, 3)
janela.Parent = rolagemRoleta

local fita = Instance.new("Frame")
fita.BackgroundTransparency = 1
fita.Size = UDim2.new(0, 0, 1, -20)
fita.Position = UDim2.new(0.5, -LARGURA_CARTA / 2, 0, 10)
fita.Parent = janela

-- setinha no meio que mostra o prêmio
local marcador = Instance.new("Frame")
marcador.AnchorPoint = Vector2.new(0.5, 0)
marcador.Position = UDim2.fromScale(0.5, 0)
marcador.Size = UDim2.new(0, 6, 1, 0)
marcador.BackgroundColor3 = COR_AMARELO
marcador.BorderSizePixel = 0
marcador.ZIndex = 5
marcador.Parent = janela

local function cartaPremio(i: number, premio: Config.PremioRoleta)
	local c = Instance.new("Frame")
	c.Size = UDim2.new(0, LARGURA_CARTA, 1, 0)
	c.Position = UDim2.fromOffset((i - 1) * PASSO_CARTA, 0)
	c.BackgroundColor3 = premio.cor:Lerp(Color3.new(0, 0, 0), 0.35)
	cantos(c, 12)
	borda(c, premio.cor, 3)
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	g.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(170, 170, 170))
	g.Parent = c
	rotulo(c, {
		Size = UDim2.new(1, -10, 0, 50),
		Position = UDim2.fromOffset(5, 10),
		Text = if premio.ovo then "OVO" else "$",
		TextColor3 = premio.cor,
	})
	rotulo(c, {
		Size = UDim2.new(1, -10, 0, 54),
		Position = UDim2.fromOffset(5, 62),
		Text = premio.nome,
		TextWrapped = true,
	})
	c.Parent = fita
end

local function montarFita(premios: { number })
	limpar(fita)
	for i, idx in premios do
		cartaPremio(i, Config.Roleta.premios[idx])
	end
end

local function premioAleatorio(): number
	local total = 0
	for _, p in Config.Roleta.premios do
		total += p.peso
	end
	local alvo = math.random() * total
	for i, p in Config.Roleta.premios do
		alvo -= p.peso
		if alvo <= 0 then
			return i
		end
	end
	return 1
end

-- fita parada mostrando os prêmios
do
	local inicial = {}
	for i = 1, #Config.Roleta.premios do
		inicial[i] = i
	end
	montarFita(inicial)
	fita.Position = UDim2.new(0.5, -LARGURA_CARTA / 2 - PASSO_CARTA * 2, 0, 10)
end

local botaoGirar = botao(rolagemRoleta, "GIRAR!", COR_ROLETA, {
	Size = UDim2.fromOffset(260, 64),
	Position = UDim2.new(0.5, -130, 0, 166),
})

local chancesRoleta = {}
do
	local total = 0
	for _, p in Config.Roleta.premios do
		total += p.peso
	end
	for _, p in Config.Roleta.premios do
		table.insert(
			chancesRoleta,
			string.format('<font color="#%s">%s %s%%</font>', p.cor:ToHex(), p.nome, Util.numero(p.peso / total * 100))
		)
	end
end
rotulo(rolagemRoleta, {
	Size = UDim2.new(1, -16, 0, 120),
	Position = UDim2.fromOffset(8, 244),
	Text = "Chances: " .. table.concat(chancesRoleta, " · ") .. "\nUm giro grátis a cada 10 minutos jogando.",
	RichText = true,
	TextWrapped = true,
	TextScaled = false,
	TextSize = 20,
	TextYAlignment = Enum.TextYAlignment.Top,
})

local girando = false
botaoGirar.MouseButton1Click:Connect(function()
	if girando or not estado or workspace:GetServerTimeNow() < estado.roletaEm then
		return
	end
	ev("GirarRoleta"):FireServer()
end)

ev("Roleta").OnClientEvent:Connect(function(escolhido: number)
	girando = true
	if not painelRoleta.Visible then
		abrir(painelRoleta)
	end
	local cartas = {}
	local alvo = 34
	for i = 1, alvo + 4 do
		cartas[i] = if i == alvo then escolhido else premioAleatorio()
	end
	montarFita(cartas)
	fita.Position = UDim2.new(0.5, -LARGURA_CARTA / 2, 0, 10)
	local final = -LARGURA_CARTA / 2
		- (alvo - 1) * PASSO_CARTA
		+ math.random(-LARGURA_CARTA * 0.35, LARGURA_CARTA * 0.35)
	local giro = TweenService:Create(
		fita,
		TweenInfo.new(DURACAO_GIRO, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, final, 0, 10) }
	)
	giro:Play()
	-- "tic" cada vez que uma carta passa pela setinha, ficando mais grave no fim
	local ultima = 0
	local conexao
	conexao = game:GetService("RunService").RenderStepped:Connect(function()
		local x = -fita.Position.X.Offset - LARGURA_CARTA / 2
		local atual = math.floor(x / PASSO_CARTA + 0.5)
		if atual ~= ultima then
			ultima = atual
			tocar(1.7 - math.clamp(atual / alvo, 0, 1) * 0.6, 0.25)
		end
	end)
	giro.Completed:Once(function()
		conexao:Disconnect()
		local premio = Config.Roleta.premios[escolhido]
		marcador.BackgroundColor3 = premio.cor
		TweenService:Create(marcador, TweenInfo.new(0.6), { BackgroundColor3 = COR_AMARELO }):Play()
		if premio.segundos then
			-- ovo já ganha a festa do cartão de chocar; moedas ganham a festa aqui
			festa(if premio.segundos >= 600 then 5 elseif premio.segundos >= 180 then 4 else 3, premio.cor)
		end
		task.delay(0.6, function()
			girando = false
		end)
	end)
end)

------------------------------------------------------------------------
-- Troca entre jogadores (o servidor confere tudo; aqui é só a tela)
------------------------------------------------------------------------
type TrocaTela = {
	com: string,
	minhasVagas: { string },
	minhas: { string },
	deles: { string },
	rendaMinha: number,
	rendaDeles: number,
	euAceitei: boolean,
	elesAceitaram: boolean,
	faltam: number?,
}

-- Lista de jogadores para pedir troca
local painelJogadores, rolagemJogadores = novoPainel("Trocar com quem?", COR_TROCA)
lista(rolagemJogadores)
local function desenharJogadores()
	limpar(rolagemJogadores)
	local n = 0
	for _, p in Players:GetPlayers() do
		if p ~= jogador then
			n += 1
			local c = cartao(rolagemJogadores, 70, n)
			rotulo(c, {
				Size = UDim2.new(1, -230, 0, 40),
				Position = UDim2.fromOffset(14, 15),
				Text = p.DisplayName,
				TextXAlignment = Enum.TextXAlignment.Left,
			})
			local b = botao(c, "Pedir troca", COR_TROCA, {
				Size = UDim2.fromOffset(190, 52),
				Position = UDim2.new(1, -200, 0, 9),
			})
			b.MouseButton1Click:Connect(function()
				ev("PedirTroca"):FireServer(p)
				painelJogadores.Visible = false
				painelAberto = nil
			end)
		end
	end
	if n == 0 then
		local c = cartao(rolagemJogadores, 70, 1)
		rotulo(c, {
			Size = UDim2.new(1, -28, 1, -16),
			Position = UDim2.fromOffset(14, 8),
			Text = "Ninguém mais no servidor ainda. Chame um amigo!",
			TextWrapped = true,
		})
	end
end
Players.PlayerAdded:Connect(function()
	if painelJogadores.Visible then
		desenharJogadores()
	end
end)
Players.PlayerRemoving:Connect(function()
	task.defer(function()
		if painelJogadores.Visible then
			desenharJogadores()
		end
	end)
end)

-- Pedido que chega de outro jogador
local cartaoPedido = Instance.new("Frame")
cartaoPedido.AnchorPoint = Vector2.new(0.5, 0)
cartaoPedido.Position = UDim2.new(0.5, 0, 0, 90)
cartaoPedido.Size = UDim2.fromOffset(440, 120)
cartaoPedido.BackgroundColor3 = COR_FUNDO
cartaoPedido.Visible = false
cartaoPedido.ZIndex = 20
cantos(cartaoPedido, 16)
borda(cartaoPedido, COR_TROCA, 4)
cartaoPedido.Parent = tela
local textoPedido = rotulo(cartaoPedido, {
	Size = UDim2.new(1, -20, 0, 44),
	Position = UDim2.fromOffset(10, 6),
	ZIndex = 21,
})
local aceitarPedido = botao(cartaoPedido, "Ver troca", COR_VERDE, {
	Size = UDim2.fromOffset(200, 54),
	Position = UDim2.fromOffset(12, 58),
	ZIndex = 21,
})
local recusarPedido = botao(cartaoPedido, "Agora não", COR_VERMELHO, {
	Size = UDim2.fromOffset(200, 54),
	Position = UDim2.new(1, -212, 0, 58),
	ZIndex = 21,
})
local pedidoDe: Player? = nil
local idPedido = 0
ev("PedidoTroca").OnClientEvent:Connect(function(de: Player)
	pedidoDe = de
	idPedido += 1
	local meu = idPedido
	textoPedido.Text = de.DisplayName .. " quer trocar Misturebas com você!"
	cartaoPedido.Visible = true
	tocar(1.4, 0.4)
	task.delay(20, function()
		if meu == idPedido then
			cartaoPedido.Visible = false
		end
	end)
end)
aceitarPedido.MouseButton1Click:Connect(function()
	if pedidoDe then
		ev("ResponderTroca"):FireServer(pedidoDe, true)
	end
	pedidoDe = nil
	cartaoPedido.Visible = false
end)
recusarPedido.MouseButton1Click:Connect(function()
	if pedidoDe then
		ev("ResponderTroca"):FireServer(pedidoDe, false)
	end
	pedidoDe = nil
	cartaoPedido.Visible = false
end)

-- Janela da troca
local painelTroca, rolagemTrocaVazia = novoPainel("Troca", COR_TROCA)
rolagemTrocaVazia.Visible = false
local tituloTroca = painelTroca:FindFirstChildOfClass("TextLabel") :: TextLabel
local fecharTroca = painelTroca:FindFirstChildOfClass("TextButton") :: TextButton

local function caixaLado(x: number): (Frame, TextLabel, Frame, TextLabel)
	local caixa = Instance.new("Frame")
	caixa.Position = UDim2.fromOffset(x, 56)
	caixa.Size = UDim2.fromOffset(292, 150)
	caixa.BackgroundColor3 = COR_CARTAO
	cantos(caixa, 12)
	caixa.Parent = painelTroca
	local titulo = rotulo(caixa, {
		Size = UDim2.new(1, -16, 0, 30),
		Position = UDim2.fromOffset(8, 4),
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local fila = Instance.new("Frame")
	fila.BackgroundTransparency = 1
	fila.Position = UDim2.fromOffset(6, 38)
	fila.Size = UDim2.new(1, -12, 0, 80)
	fila.Parent = caixa
	local l = Instance.new("UIListLayout")
	l.FillDirection = Enum.FillDirection.Horizontal
	l.Padding = UDim.new(0, 4)
	l.Parent = fila
	local status = rotulo(caixa, {
		Size = UDim2.new(1, -16, 0, 26),
		Position = UDim2.fromOffset(8, 120),
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	return caixa, titulo, fila, status
end
local _, tituloMeu, filaMinha, statusMeu = caixaLado(12)
local _, tituloDeles, filaDeles, statusDeles = caixaLado(316)

local function cartaMistureba(pai: Instance, id: string, largura: number, altura: number): Frame
	local def = Config.PorId[id]
	local info = Config.Raridades[def.raridade]
	local mut = def.mutacao and Config.MutacaoPorId[def.mutacao]
	local c = Instance.new("Frame")
	c.Size = UDim2.fromOffset(largura, altura)
	c.BackgroundColor3 = info.cor:Lerp(Color3.new(0, 0, 0), 0.55)
	cantos(c, 10)
	borda(c, if mut then mut.cor else info.cor, 3)
	rotulo(c, {
		Size = UDim2.new(1, -6, 0.42, 0),
		Position = UDim2.fromOffset(3, 2),
		Text = def.nome,
		TextWrapped = true,
	})
	rotulo(c, {
		Size = UDim2.new(1, -6, 0.26, 0),
		Position = UDim2.fromScale(0, 0.44) + UDim2.fromOffset(3, 0),
		Text = if mut then mut.nome else info.nome,
		TextColor3 = if mut then mut.cor else info.cor,
	})
	rotulo(c, {
		Size = UDim2.new(1, -6, 0.26, 0),
		Position = UDim2.fromScale(0, 0.72) + UDim2.fromOffset(3, 0),
		Text = "+" .. Util.numero(def.renda) .. "/s",
		TextColor3 = COR_VERDE,
	})
	c.Parent = pai
	return c
end

rotulo(painelTroca, {
	Size = UDim2.new(1, -24, 0, 24),
	Position = UDim2.fromOffset(12, 212),
	Text = "Toque nas suas Misturebas para oferecer (até 4):",
	TextXAlignment = Enum.TextXAlignment.Left,
})
local gradeSuas = Instance.new("ScrollingFrame")
gradeSuas.Position = UDim2.fromOffset(12, 240)
gradeSuas.Size = UDim2.new(1, -24, 0, 124)
gradeSuas.BackgroundTransparency = 1
gradeSuas.BorderSizePixel = 0
gradeSuas.ScrollBarThickness = 8
gradeSuas.AutomaticCanvasSize = Enum.AutomaticSize.Y
gradeSuas.CanvasSize = UDim2.new()
gradeSuas.Parent = painelTroca
local layoutSuas = Instance.new("UIGridLayout")
layoutSuas.CellSize = UDim2.fromOffset(112, 58)
layoutSuas.CellPadding = UDim2.fromOffset(6, 6)
layoutSuas.SortOrder = Enum.SortOrder.LayoutOrder
layoutSuas.Parent = gradeSuas

local avisoTroca = rotulo(painelTroca, {
	Size = UDim2.fromOffset(330, 76),
	Position = UDim2.fromOffset(12, 372),
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
})
local botaoAceitarTroca = botao(painelTroca, "ACEITAR", COR_VERDE, {
	Size = UDim2.fromOffset(140, 64),
	Position = UDim2.fromOffset(350, 380),
})
local botaoCancelarTroca = botao(painelTroca, "CANCELAR", COR_VERMELHO, {
	Size = UDim2.fromOffset(112, 64),
	Position = UDim2.fromOffset(496, 380),
})

local troca: TrocaTela? = nil
local fimContagem: number? = nil

local function desenharTroca()
	local t = troca
	if not t then
		return
	end
	tituloTroca.Text = "Troca com " .. t.com
	tituloMeu.Text = "Você dá"
	tituloDeles.Text = t.com .. " dá"
	for _, fila in { filaMinha, filaDeles } do
		for _, f in fila:GetChildren() do
			if f:IsA("Frame") then
				f:Destroy()
			end
		end
	end
	for _, id in t.minhas do
		cartaMistureba(filaMinha, id, 67, 80)
	end
	for _, id in t.deles do
		cartaMistureba(filaDeles, id, 67, 80)
	end
	statusMeu.Text = "+"
		.. Util.numero(t.rendaMinha)
		.. "/s"
		.. (if t.euAceitei then '   <font color="#80FF90">ACEITOU</font>' else "")
	statusMeu.RichText = true
	statusDeles.Text = "+"
		.. Util.numero(t.rendaDeles)
		.. "/s"
		.. (if t.elesAceitaram then '   <font color="#80FF90">ACEITOU</font>' else "")
	statusDeles.RichText = true

	-- suas Misturebas da base para escolher
	limpar(gradeSuas)
	if estado then
		local vagas = {}
		for vaga in estado.criaturas do
			table.insert(vagas, vaga)
		end
		table.sort(vagas, function(a, b)
			return (tonumber(a) or 0) < (tonumber(b) or 0)
		end)
		for i, vaga in vagas do
			local id = estado.criaturas[vaga]
			local carta = cartaMistureba(gradeSuas, id, 112, 58)
			carta.LayoutOrder = i
			local escolhida = table.find(t.minhasVagas, vaga) ~= nil
			if escolhida then
				carta.BackgroundColor3 = COR_VERDE:Lerp(Color3.new(0, 0, 0), 0.3)
			end
			local clique = Instance.new("TextButton")
			clique.BackgroundTransparency = 1
			clique.Text = ""
			clique.Size = UDim2.fromScale(1, 1)
			clique.ZIndex = 5
			clique.Parent = carta
			clique.MouseButton1Click:Connect(function()
				local nova = table.clone(t.minhasVagas)
				local pos = table.find(nova, vaga)
				if pos then
					table.remove(nova, pos)
				elseif #nova < 4 then
					table.insert(nova, vaga)
				end
				ev("OfertaTroca"):FireServer(nova)
			end)
		end
	end

	botaoAceitarTroca.Text = if t.euAceitei then "DESFAZER" else "ACEITAR"
	botaoAceitarTroca.BackgroundColor3 = if t.euAceitei then COR_AMARELO else COR_VERDE
	fimContagem = if t.faltam then os.clock() + t.faltam else nil
end

local function atualizarAvisoTroca()
	local t = troca
	if not t then
		return
	end
	if fimContagem then
		local falta = math.max(0, math.ceil(fimContagem - os.clock()))
		avisoTroca.Text = string.format("Fechando em %d... Mudou de ideia? Clique em CANCELAR.", falta)
		avisoTroca.TextColor3 = COR_AMARELO
	elseif #t.minhas > 0 and #t.deles == 0 then
		avisoTroca.Text = "Cuidado: você vai DAR sem receber nada em troca."
		avisoTroca.TextColor3 = Color3.fromRGB(255, 120, 120)
	elseif t.rendaMinha > t.rendaDeles * 1.5 and #t.deles > 0 then
		avisoTroca.Text = "Cuidado: você dá mais renda do que recebe."
		avisoTroca.TextColor3 = Color3.fromRGB(255, 170, 90)
	else
		avisoTroca.Text = "Confira tudo antes de aceitar. Se algo mudar, os dois aceitam de novo."
		avisoTroca.TextColor3 = Color3.new(1, 1, 1)
	end
end

ev("Troca").OnClientEvent:Connect(function(novo: TrocaTela?)
	local antes = troca
	troca = novo
	if not novo then
		painelTroca.Visible = false
		fimContagem = nil
		return
	end
	if not antes then
		if painelAberto then
			painelAberto.Visible = false
			painelAberto = nil
		end
		painelTroca.Visible = true
		cartaoPedido.Visible = false
		tocar(1.2, 0.4)
	elseif novo.elesAceitaram and not antes.elesAceitaram then
		tocar(1.6, 0.4)
	end
	desenharTroca()
	atualizarAvisoTroca()
end)

botaoAceitarTroca.MouseButton1Click:Connect(function()
	if troca then
		ev("AceitarTroca"):FireServer(not troca.euAceitei)
	end
end)
botaoCancelarTroca.MouseButton1Click:Connect(function()
	ev("CancelarTroca"):FireServer()
end)
-- o X da janela também cancela
fecharTroca.MouseButton1Click:Connect(function()
	if troca then
		ev("CancelarTroca"):FireServer()
	end
end)
task.spawn(function()
	while true do
		task.wait(0.25)
		if troca and painelTroca.Visible then
			atualizarAvisoTroca()
		end
	end
end)

------------------------------------------------------------------------
-- Painel: Melhorias (onde gastar moedas para sempre) e Rastros (enfeites)
------------------------------------------------------------------------
local COR_MELHORAR = Color3.fromRGB(255, 160, 40)
local painelMelhorar, rolagemMelhorar = novoPainel("Melhorias", COR_MELHORAR)
lista(rolagemMelhorar)

local function textoEfeito(u: Config.Upgrade, nivel: number): string
	local v = nivel * u.porNivel
	if u.id == "cadeado" then
		return "+" .. v .. "s"
	end
	return "+" .. math.floor(v * 100 + 0.5) .. "%"
end

local function titulo(texto: string, ordem: number, cor: Color3)
	rotulo(rolagemMelhorar, {
		Size = UDim2.new(1, -12, 0, 34),
		Text = texto,
		TextColor3 = cor,
		LayoutOrder = ordem,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
end

local atualizarMelhorias: { () -> () } = {}
titulo("Para sempre (não somem ao Renascer)", 0, COR_MELHORAR)
for i, u in Config.Upgrades do
	local c = cartao(rolagemMelhorar, 104, i)
	borda(c, u.cor, 2)
	rotulo(c, {
		Size = UDim2.new(1, -220, 0, 32),
		Position = UDim2.fromOffset(14, 6),
		Text = u.nome,
		TextColor3 = u.cor,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	rotulo(c, {
		Size = UDim2.new(1, -220, 0, 24),
		Position = UDim2.fromOffset(14, 38),
		Text = u.descricao,
		TextColor3 = Color3.fromRGB(210, 210, 235),
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	-- barrinha com um pedaço por nível
	local barra = Instance.new("Frame")
	barra.BackgroundTransparency = 1
	barra.Position = UDim2.fromOffset(14, 70)
	barra.Size = UDim2.new(1, -220, 0, 20)
	barra.Parent = c
	local gradeNiveis = Instance.new("UIListLayout")
	gradeNiveis.FillDirection = Enum.FillDirection.Horizontal
	gradeNiveis.Padding = UDim.new(0, 3)
	gradeNiveis.Parent = barra
	local pedacos = {}
	for n = 1, u.max do
		local pedaco = Instance.new("Frame")
		pedaco.Size = UDim2.new(1 / u.max, -3, 1, 0)
		pedaco.BackgroundColor3 = Color3.fromRGB(80, 75, 110)
		pedaco.LayoutOrder = n
		cantos(pedaco, 4)
		pedaco.Parent = barra
		pedacos[n] = pedaco
	end
	local efeito = rotulo(c, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 6),
		Size = UDim2.fromOffset(190, 28),
		Text = "",
		TextColor3 = COR_VERDE,
	})
	local comprar = botao(c, "", COR_VERDE, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 40),
		Size = UDim2.fromOffset(190, 52),
	})
	local nivelVisto = -1
	local function atualizar()
		if not estado then
			return
		end
		local nivel = (estado.upgrades or {})[u.id] or 0
		for n, pedaco in pedacos do
			pedaco.BackgroundColor3 = if n <= nivel then u.cor else Color3.fromRGB(80, 75, 110)
		end
		if nivelVisto >= 0 and nivel > nivelVisto and pedacos[nivel] then
			local brilho = pedacos[nivel]
			brilho.BackgroundColor3 = Color3.new(1, 1, 1)
			TweenService:Create(brilho, TweenInfo.new(0.5), { BackgroundColor3 = u.cor }):Play()
		end
		nivelVisto = nivel
		efeito.Text = "Nível " .. nivel .. "/" .. u.max .. "  " .. textoEfeito(u, nivel)
		if nivel >= u.max then
			comprar.Text = "MÁXIMO!"
			comprar.BackgroundColor3 = COR_AZUL
		else
			local preco = Util.precoUpgrade(u, nivel)
			comprar.Text = Util.numero(preco)
			comprar.BackgroundColor3 = if estado.moedas >= preco then COR_VERDE else Color3.fromRGB(110, 110, 120)
		end
	end
	comprar.MouseButton1Click:Connect(function()
		ev("ComprarUpgrade"):FireServer(u.id)
	end)
	table.insert(atualizarMelhorias, atualizar)
end

titulo("Rastros (só enfeite, seguem você)", 50, Color3.fromRGB(150, 220, 255))
for i, r in Config.Rastros do
	local c = cartao(rolagemMelhorar, 74, 50 + i)
	local amostra = Instance.new("Frame")
	amostra.Position = UDim2.fromOffset(14, 14)
	amostra.Size = UDim2.fromOffset(90, 46)
	amostra.BackgroundColor3 = Color3.new(1, 1, 1)
	cantos(amostra, 10)
	amostra.Parent = c
	local pontos = {}
	for k, cor in r.cores do
		table.insert(pontos, ColorSequenceKeypoint.new((k - 1) / math.max(1, #r.cores - 1), cor))
	end
	local degrade = Instance.new("UIGradient")
	degrade.Color = ColorSequence.new(pontos)
	degrade.Parent = amostra
	rotulo(c, {
		Size = UDim2.new(1, -330, 0, 40),
		Position = UDim2.fromOffset(116, 16),
		Text = r.nome,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local acao = botao(c, "", COR_VERDE, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(190, 52),
	})
	acao.MouseButton1Click:Connect(function()
		ev("Rastro"):FireServer(r.id)
	end)
	table.insert(atualizarMelhorias, function()
		if not estado then
			return
		end
		if (estado.rastros or {})[r.id] then
			local usando = estado.rastro == r.id
			acao.Text = if usando then "TIRAR" else "USAR"
			acao.BackgroundColor3 = if usando then COR_VERMELHO else COR_AZUL
		else
			acao.Text = Util.numero(r.preco)
			acao.BackgroundColor3 = if estado.moedas >= r.preco then COR_VERDE else Color3.fromRGB(110, 110, 120)
		end
	end)
end
table.insert(aoMudarEstado, function()
	if painelMelhorar.Visible then
		for _, f in atualizarMelhorias do
			f()
		end
	end
end)

------------------------------------------------------------------------
-- Clima: relógio na faixa, céu e partículas mudam durante o evento
------------------------------------------------------------------------
local Lighting = game:GetService("Lighting")
local climaAgora: string? = nil
local climaFim = 0
local climaProximo = 0

local corClima = Instance.new("ColorCorrectionEffect")
corClima.Name = "ClimaMistureba"
corClima.Parent = Lighting
local luzOriginal = {
	ClockTime = Lighting.ClockTime,
	Ambient = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient,
}

-- uma placa invisível em cima da câmera solta as partículas do clima
local chuvaClima = Instance.new("Part")
chuvaClima.Name = "ChuvaClima"
chuvaClima.Anchored = true
chuvaClima.CanCollide = false
chuvaClima.CanQuery = false
chuvaClima.CanTouch = false
chuvaClima.Transparency = 1
chuvaClima.Size = Vector3.new(90, 1, 90)
chuvaClima.Parent = workspace
local particulasClima = Instance.new("ParticleEmitter")
particulasClima.Texture = "rbxasset://textures/particles/sparkles_main.dds"
particulasClima.EmissionDirection = Enum.NormalId.Bottom
particulasClima.Speed = NumberRange.new(10, 16)
particulasClima.Lifetime = NumberRange.new(3, 4)
particulasClima.Size = NumberSequence.new(1.2, 0.6)
particulasClima.LightEmission = 0.8
particulasClima.RotSpeed = NumberRange.new(-90, 90)
particulasClima.Rate = 0
particulasClima.Parent = chuvaClima
game:GetService("RunService").RenderStepped:Connect(function()
	if climaAgora then
		chuvaClima.CFrame = CFrame.new(camera.CFrame.Position + Vector3.new(0, 30, 0))
	end
end)

local function aplicarClima(id: string?)
	local def = Util.clima(id)
	local info = TweenInfo.new(2)
	if not def then
		particulasClima.Rate = 0
		TweenService:Create(corClima, info, { TintColor = Color3.new(1, 1, 1), Saturation = 0, Brightness = 0 }):Play()
		TweenService:Create(Lighting, info, luzOriginal):Play()
		bordaClima.Color = Color3.fromRGB(120, 120, 150)
		return
	end
	bordaClima.Color = def.cor
	local tinta = Color3.new(1, 1, 1):Lerp(def.cor, 0.18)
	local saturacao = if def.id == "arcoiris" then 0.35 else 0.1
	TweenService:Create(corClima, info, { TintColor = tinta, Saturation = saturacao, Brightness = 0.03 }):Play()
	if def.id == "estelar" then
		-- noite, mas com luz suficiente para enxergar tudo
		TweenService:Create(Lighting, info, {
			ClockTime = 0.5,
			Ambient = Color3.fromRGB(110, 100, 170),
			OutdoorAmbient = Color3.fromRGB(140, 130, 200),
		}):Play()
	else
		TweenService:Create(Lighting, info, luzOriginal):Play()
	end
	if def.id == "arcoiris" then
		particulasClima.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
			ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 230, 80)),
			ColorSequenceKeypoint.new(0.66, Color3.fromRGB(80, 220, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 90, 255)),
		})
	else
		particulasClima.Color = ColorSequence.new(def.cor, Color3.new(1, 1, 1))
	end
	particulasClima.Rate = if def.id == "doces" then 60 else 35
end

local function mudarClima(id: string?, ate: number?, proximo: number?)
	local mudou = id ~= climaAgora
	climaAgora = id
	climaFim = ate or 0
	climaProximo = proximo or 0
	if mudou then
		aplicarClima(id)
		local escala = faixaClima:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
		escala.Parent = faixaClima
		escala.Scale = 1.3
		TweenService:Create(escala, TweenInfo.new(0.5, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
end
ev("Clima").OnClientEvent:Connect(mudarClima)
table.insert(aoMudarEstado, function()
	if estado then
		mudarClima(estado.clima, estado.climaAte, estado.proximoClima)
	end
end)

local function relogio(segundos: number): string
	segundos = math.max(0, math.ceil(segundos))
	return string.format("%d:%02d", segundos // 60, segundos % 60)
end
task.spawn(function()
	while true do
		local t = workspace:GetServerTimeNow()
		local def = Util.clima(climaAgora)
		if def then
			textoClima.Text = string.format(
				'<font color="#%s">%s</font>  %s',
				def.cor:ToHex(),
				string.upper(def.nome),
				relogio(climaFim - t)
			)
			descClima.Text = def.descricao
			faixaClima.Size = UDim2.fromOffset(380, 52)
		elseif climaProximo > 0 then
			textoClima.Text = "Próximo clima em " .. relogio(climaProximo - t)
			faixaClima.Size = UDim2.fromOffset(240, 28)
			descClima.Text = ""
		else
			textoClima.Text = ""
		end
		faixaClima.Visible = textoClima.Text ~= ""
		task.wait(0.5)
	end
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
botaoTrocar.MouseButton1Click:Connect(function()
	if troca then
		painelTroca.Visible = true
		return
	end
	desenharJogadores()
	abrir(painelJogadores)
end)
botaoRoleta.MouseButton1Click:Connect(function()
	abrir(painelRoleta)
end)
botaoMelhorar.MouseButton1Click:Connect(function()
	for _, f in atualizarMelhorias do
		f()
	end
	abrir(painelMelhorar)
end)
botaoMissoes.MouseButton1Click:Connect(function()
	desenharMissoes()
	abrir(painelMissoes)
end)

local bolhaPronta = true
local function tapa()
	if not bolhaPronta then
		return
	end
	bolhaPronta = false
	ev("Tapa"):FireServer()
	local espera = Config.Jogador.esperaTapa
	botaoTapa.BackgroundColor3 = Color3.fromRGB(110, 110, 120)
	local escala = botaoTapa:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	escala.Parent = botaoTapa
	escala.Scale = 0.85
	TweenService:Create(escala, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	task.delay(espera, function()
		bolhaPronta = true
		botaoTapa.BackgroundColor3 = Color3.fromRGB(90, 170, 255)
	end)
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
	if (estado.pocoes or 0) > 0 then
		table.insert(partes, string.format('<font color="#C890FF">Poção: %d ovo(s)</font>', estado.pocoes or 0))
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
		botaoTrancar.Text = "TRANCAR" .. dica("T")
		botaoTrancar.BackgroundColor3 = COR_VERDE
	end
	botaoSoltar.Visible = estado.roubo ~= nil or #estado.ovos > 0

	local faltaRoleta = math.ceil((estado.roletaEm or 0) - t)
	alertaRoleta.Visible = faltaRoleta <= 0
	if faltaRoleta <= 0 then
		botaoRoleta.Text = "ROLETA"
		botaoGirar.Text = if girando then "GIRANDO..." else "GIRAR!"
		botaoGirar.BackgroundColor3 = COR_ROLETA
	else
		local texto = string.format("%d:%02d", faltaRoleta // 60, faltaRoleta % 60)
		botaoRoleta.Text = "ROLETA " .. texto
		botaoGirar.Text = if girando then "GIRANDO..." else "Próximo giro em " .. texto
		botaoGirar.BackgroundColor3 = Color3.fromRGB(110, 110, 120)
	end
end

local assinaturaMissoes = ""
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
	mostrarMoedas(novo.moedas, novo.renda)
	textoRenda.Text = "+" .. Util.numero(novo.renda) .. "/s"
	local mult = novo.multiplicador or 1
	chipMult.Visible = mult > 1.001
	chipMult.Text = "x" .. string.gsub(string.format("%.1f", mult), "%.0$", "")
	for _, f in aoMudarEstado do
		f()
	end
	atualizarStatus()
	local temPremio = false
	for _, m in novo.missoes or {} do
		if m.progresso >= m.meta and not m.pega then
			temPremio = true
		end
	end
	alertaMissoes.Visible = temPremio
	local assinatura = tostring(novo.missoesFinal) .. Util.numero(novo.premioMissao)
	for _, m in novo.missoes or {} do
		assinatura ..= "|" .. m.progresso .. tostring(m.pega)
	end
	if assinatura ~= assinaturaMissoes then
		assinaturaMissoes = assinatura
		if painelMissoes.Visible then
			desenharMissoes()
		end
	end
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
		if troca and painelTroca.Visible then
			desenharTroca()
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(0.25)
		atualizarStatus()
	end
end)
