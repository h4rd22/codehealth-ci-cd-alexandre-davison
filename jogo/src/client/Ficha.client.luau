-- Ficha: painel com todos os atributos do herói (estilo ficha de RPG).
-- Abre pelo botão ao lado do cartão do herói (clicar no boneco não abre: atrapalhava jogar).
-- Os números vêm do servidor (estado.stats, calculado em calcularStats no GameServer);
-- os bônus das magias do Mago são somados aqui a partir de estado.habilidades.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Hab = require(Shared:WaitForChild("Habilidades"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local evEstado = remotes:WaitForChild("Estado")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local estado = nil

------------------------------------------------------------------------
-- Cores e ajudantes (estilo do Hud)
------------------------------------------------------------------------
-- (cores e fontes vêm do EstiloUI, a linguagem visual do jogo)
local E = require(Shared:WaitForChild("EstiloUI"))
local COR = {
	painel = E.cor.painel,
	painel2 = E.cor.painelClaro,
	borda = E.cor.tinta,
	dourado = E.cor.ouro,
	texto = E.cor.papel,
	fraco = E.cor.papelFraco,
	faixa = E.cor.painelFundo,
	vermelho = E.cor.sakura,
	madeira = E.cor.painelClaro,
	ouro = E.cor.ouro,
}
local FONTE = E.fonteTitulo
local FONTE_TEXTO = E.fonteTexto

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
local function degrade(o, claro, escuro)
	return novo("UIGradient", o, {
		Rotation = 90,
		Color = ColorSequence.new(claro or Color3.new(1, 1, 1), escuro or Color3.fromRGB(150, 140, 130)),
	})
end

local function pct(v, casas)
	local f = casas == 1 and "%.1f%%" or "%d%%"
	if casas == 1 then
		return (string.gsub(string.format(f, v * 100), "%.0%%", "%%"))
	end
	return string.format(f, math.floor(v * 100 + 0.5))
end
local function numero(v)
	v = math.floor(v + 0.5)
	if v >= 1e6 then
		return string.format("%.2fM", v / 1e6)
	elseif v >= 1e4 then
		return string.format("%.1fK", v / 1e3)
	end
	-- separa milhar com ponto
	local s = tostring(v)
	return (string.reverse(string.gsub(string.reverse(s), "(%d%d%d)(%d)", "%1.%2")))
end

------------------------------------------------------------------------
-- Janela
------------------------------------------------------------------------
local gui = novo("ScreenGui", playerGui, {
	Name = "Ficha",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 6,
	Enabled = false,
})
local fundo = novo("TextButton", gui, {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0.45,
	Text = "",
	AutoButtonColor = false,
})
local janela = novo("Frame", gui, {
	Name = "Janela",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.52),
	Size = UDim2.fromScale(0.94, 0.84),
	BackgroundColor3 = COR.painel,
})
novo("UISizeConstraint", janela, { MaxSize = Vector2.new(700, 500) })
canto(janela, 14)
contorno(janela, COR.dourado, 3)
degrade(janela, Color3.new(1, 1, 1), Color3.fromRGB(170, 160, 150))
local escalaJanela = novo("UIScale", janela)

-- faixa do topo: retrato, nome, classe e nível
local topo = novo("Frame", janela, {
	Size = UDim2.new(1, 0, 0, 58),
	BackgroundColor3 = COR.faixa,
	BorderSizePixel = 0,
})
canto(topo, 14)
degrade(topo, Color3.fromRGB(255, 190, 170), Color3.fromRGB(160, 120, 110))
novo("Frame", topo, {
	Position = UDim2.fromScale(0, 1),
	Size = UDim2.new(1, 0, 0, 2),
	BackgroundColor3 = COR.dourado,
	BorderSizePixel = 0,
})
local retrato = novo("ImageLabel", topo, {
	Position = UDim2.fromOffset(10, 5),
	Size = UDim2.fromOffset(48, 48),
	BackgroundColor3 = COR.painel2,
	Image = "",
})
canto(retrato, 24)
contorno(retrato, COR.dourado, 2)
task.spawn(function()
	local ok, img = pcall(function()
		return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
	end)
	if ok then
		retrato.Image = img
	end
end)
local titulo = rotulo(topo, {
	Position = UDim2.fromOffset(68, 6),
	Size = UDim2.new(1, -130, 0, 26),
	Text = "Ficha do Herói",
	TextSize = 22,
	TextColor3 = Color3.fromRGB(255, 225, 140),
	TextXAlignment = Enum.TextXAlignment.Left,
})
local subtitulo = rotulo(topo, {
	Position = UDim2.fromOffset(68, 32),
	Size = UDim2.new(1, -130, 0, 20),
	Text = "",
	TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Left,
})
local fechar = novo("TextButton", topo, {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -10, 0.5, 0),
	Size = UDim2.fromOffset(34, 34),
	Text = "X",
	Font = FONTE,
	TextSize = 18,
	TextColor3 = COR.texto,
	BackgroundColor3 = COR.vermelho,
})
canto(fechar, 8)
contorno(fechar, COR.dourado, 1.5)

-- Seções da ficha. Podem ser desenhadas em dois lugares: na janela (popup)
-- e dentro da mochila (Frame "LugarFicha" da mochila da Jessica).
local linhas = {} -- linhas[chave] = { TextLabel de valor, ... } (um por lugar desenhado)
local function coluna(corpo, x, largura)
	local c = novo("ScrollingFrame", corpo, {
		Position = UDim2.new(x, x > 0 and 6 or 0, 0, 0),
		Size = UDim2.new(largura, largura < 1 and -6 or 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 5,
		ScrollBarImageColor3 = COR.dourado,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
	})
	novo("UIListLayout", c, { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
	return c
end

-- Seção: caixa com título colorido e linhas "ícone  nome ........ valor"
local function secao(pai, ordem, icone, nomeSecao, cor, itens)
	local caixa = novo("Frame", pai, {
		LayoutOrder = ordem,
		Size = UDim2.new(1, -8, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = COR.painel2,
		BackgroundTransparency = 0.1,
	})
	canto(caixa, 10)
	contorno(caixa, cor:Lerp(COR.borda, 0.4), 1.5)
	novo("UIListLayout", caixa, { SortOrder = Enum.SortOrder.LayoutOrder })
	novo("UIPadding", caixa, { PaddingBottom = UDim.new(0, 6) })
	local cab = novo("Frame", caixa, {
		LayoutOrder = 0,
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundColor3 = cor,
		BackgroundTransparency = 0.25,
	})
	canto(cab, 10)
	degrade(cab, Color3.new(1, 1, 1), Color3.fromRGB(140, 130, 130))
	E.icone(cab, icone, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 6, 0.5, 0),
		Size = UDim2.fromOffset(26, 26),
	})
	rotulo(cab, {
		Position = UDim2.fromOffset(38, 0),
		Size = UDim2.new(1, -46, 1, 0),
		Text = nomeSecao,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextStrokeTransparency = 0,
	})
	for i, it in ipairs(itens) do
		local l = novo("Frame", caixa, {
			LayoutOrder = i,
			Size = UDim2.new(1, 0, 0, 22),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = i % 2 == 0 and 0.85 or 1,
		})
		local marca = novo("Frame", l, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(19, 11),
			Size = UDim2.fromOffset(8, 8),
			Rotation = 45,
			BackgroundColor3 = it.cor or COR.fraco,
			BorderSizePixel = 0,
		})
		contorno(marca, E.cor.tinta, 1)
		rotulo(l, {
			Position = UDim2.fromOffset(32, 0),
			Size = UDim2.new(0.62, -32, 1, 0),
			Text = it.nome,
			TextSize = 13,
			Font = FONTE_TEXTO,
			TextColor3 = COR.fraco,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
		local valor = rotulo(l, {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -10, 0, 0),
			Size = UDim2.fromScale(0.38, 1),
			Text = "-",
			TextSize = 15,
			TextColor3 = it.cor or COR.texto,
			TextXAlignment = Enum.TextXAlignment.Right,
		})
		linhas[it.id] = linhas[it.id] or {}
		table.insert(linhas[it.id], valor)
	end
	return caixa
end

local EL = Hab.Elementos
-- umaColuna = true quando o lugar é estreito (tudo numa coluna só, com rolagem)
local function desenharSecoes(corpo, umaColuna)
	local colEsq = coluna(corpo, 0, umaColuna and 1 or 0.5)
	local colDir = umaColuna and colEsq or coluna(corpo, 0.5, 0.5)
	secao(colEsq, 1, "espada", "Ataque", Color3.fromRGB(215, 80, 60), {
		{ id = "dano", icone = "", nome = "Dano", cor = Color3.fromRGB(255, 150, 120) },
		{ id = "danoPct", icone = "", nome = "Bônus de dano", cor = Color3.fromRGB(255, 150, 120) },
		{ id = "danoBasico", icone = "", nome = "Dano do ataque básico" },
		{ id = "aps", icone = "", nome = "Ataques por segundo" },
		{ id = "velAtaque", icone = "", nome = "Velocidade de ataque bônus" },
		{ id = "critico", icone = "", nome = "Chance de crítico", cor = COR.ouro },
		{ id = "multCritico", icone = "", nome = "Dano crítico", cor = COR.ouro },
		{ id = "dps", icone = "", nome = "Dano por segundo (básico)", cor = Color3.fromRGB(255, 200, 120) },
		{ id = "alcance", icone = "", nome = "Alcance" },
		{ id = "danoChefe", icone = "", nome = "Dano contra chefes", cor = Color3.fromRGB(220, 130, 255) },
	})
	secao(colEsq, 2, "vida", "Defesa", Color3.fromRGB(80, 140, 220), {
		{ id = "vida", icone = "", nome = "Vida máxima", cor = Color3.fromRGB(255, 110, 110) },
		{ id = "regen", icone = "", nome = "Regeneração (fora de combate)", cor = Color3.fromRGB(120, 230, 140) },
		{ id = "armadura", icone = "", nome = "Armadura", cor = Color3.fromRGB(150, 200, 255) },
		{ id = "reducao", icone = "", nome = "Dano reduzido (fase atual)", cor = Color3.fromRGB(150, 200, 255) },
		{ id = "resFogo", icone = "", nome = "Resistência a fogo", cor = EL.fogo.cor },
		{ id = "resGelo", icone = "", nome = "Resistência a gelo", cor = EL.gelo.cor },
		{ id = "resRaio", icone = "", nome = "Resistência a raio", cor = EL.raio.cor },
		{ id = "resVeneno", icone = "", nome = "Resistência a veneno", cor = Color3.fromRGB(150, 230, 90) },
	})
	secao(colDir, umaColuna and 3 or 1, "livroMagico", "Magia", EL.arcano.cor, {
		{ id = "poder", icone = "", nome = "Poder mágico", cor = EL.arcano.cor },
		{ id = "elemFogo", icone = "", nome = "Dano de fogo", cor = EL.fogo.cor },
		{ id = "elemGelo", icone = "", nome = "Dano de gelo", cor = EL.gelo.cor },
		{ id = "elemRaio", icone = "", nome = "Dano de raio", cor = EL.raio.cor },
		{ id = "recarga", icone = "", nome = "Recarga das magias", cor = Color3.fromRGB(170, 230, 255) },
		{ id = "critMagia", icone = "", nome = "Crítico das magias", cor = COR.ouro },
		{ id = "eco", icone = "", nome = "Chance de eco", cor = EL.arcano.cor },
		{ id = "pontos", icone = "", nome = "Pontos de habilidade livres", cor = COR.ouro },
	})
	secao(colDir, umaColuna and 4 or 2, "moedas", "Aventura", Color3.fromRGB(200, 160, 60), {
		{ id = "velocidade", icone = "", nome = "Velocidade de movimento" },
		{ id = "ouro", icone = "", nome = "Ouro extra", cor = COR.ouro },
		{ id = "xp", icone = "", nome = "XP extra", cor = Color3.fromRGB(90, 210, 255) },
		{ id = "nivel", icone = "", nome = "Nível", cor = COR.ouro },
		{ id = "fase", icone = "", nome = "Fase atual" },
	})
end

-- desenho na janela (popup)
local corpo = novo("Frame", janela, {
	Position = UDim2.fromOffset(12, 68),
	Size = UDim2.new(1, -24, 1, -80),
	BackgroundTransparency = 1,
})
desenharSecoes(corpo, false)

local function definir(id, texto, apagado)
	for _, valor in ipairs(linhas[id] or {}) do
		if valor.Parent then
			valor.Text = texto
			valor.TextTransparency = apagado and 0.5 or 0
		end
	end
end

------------------------------------------------------------------------
-- Preenche os números
------------------------------------------------------------------------
local function valorPassiva(id, campo)
	local n = estado.habilidades and estado.habilidades[id] or 0
	if n <= 0 then
		return 0
	end
	return Hab.valor(Hab.PorId[id], campo, n)
end

local function atualizar()
	if not estado or not estado.stats then
		return
	end
	local s = estado.stats
	local classe = Config.ClassePorId(estado.classe)
	local nomeClasse = classe and classe.nome or "Sem classe"
	titulo.Text = player.DisplayName
	subtitulo.Text = nomeClasse .. "  ·  Nível " .. (estado.nivel or 1)

	-- Ataque
	local intervalo = s.intervalo or Config.Heroi.Intervalo
	local aps = s.golpesPorSegundo or 1 / math.max(0.05, intervalo)
	local critico = s.critico or 0
	local multCrit = s.multCritico or Config.Heroi.MultCritico
	local basico = (s.dano or 0) * (classe and classe.danoBasico or 1)
	definir("dano", numero(s.dano or 0))
	definir("danoPct", "+" .. pct(s.danoPct or 0), (s.danoPct or 0) <= 0)
	definir("danoBasico", numero(basico) .. (classe and classe.danoBasico and " (fraco)" or ""))
	definir("aps", string.format("%.2f", aps))
	definir("velAtaque", "+" .. pct(s.velAtaque or 0), (s.velAtaque or 0) <= 0)
	definir("critico", pct(critico, 1))
	definir("multCritico", string.format("x%.1f", multCrit))
	definir("dps", numero(basico * aps * (1 + critico * (multCrit - 1))))
	definir("danoChefe", "+" .. pct(s.danoChefe or 0), (s.danoChefe or 0) <= 0)
	definir("alcance", tostring(s.alcance or 0) .. " m")

	-- Defesa
	local regen = s.regen or (classe and classe.regeneracao) or Config.Heroi.Regeneracao
	local fase = Config.Fases[estado.faseIdx or 1]
	local reducao = s.reducao
	if not reducao then
		reducao = Config.ReducaoArmadura and Config.ReducaoArmadura(s.armadura or 0, fase and fase.nivel or 1) or 0
	end
	definir("vida", numero(s.vidaMax or 0))
	definir("regen", pct(regen, 1) .. "/s")
	definir("armadura", numero(s.armadura or 0), (s.armadura or 0) <= 0)
	definir("reducao", pct(reducao, 1), reducao <= 0)
	local resist = s.resist or {}
	local geral = s.resistencia or 0
	for id, el in pairs({ resFogo = "fogo", resGelo = "gelo", resRaio = "raio", resVeneno = "veneno" }) do
		local r = s[id] or resist[el] or geral -- stats.resFogo etc. vêm do servidor
		definir(id, pct(r), r <= 0)
	end

	-- Magia (só quem tem árvore de magias)
	local temArvore = Hab.arvoreDe(estado.classe) ~= nil
	local arcano = valorPassiva("poderArcano", "poder")
	if temArvore then
		definir("poder", numero(s.dano or 0))
		definir("elemFogo", "+" .. pct(arcano + Hab.bonusElemento(estado.habilidades, "fogo")))
		definir("elemGelo", "+" .. pct(arcano + Hab.bonusElemento(estado.habilidades, "gelo")))
		definir("elemRaio", "+" .. pct(arcano + Hab.bonusElemento(estado.habilidades, "raio")))
		local red = math.min(valorPassiva("menteRapida", "reducao"), Hab.ReducaoRecargaMax)
		definir("recarga", red > 0 and ("-" .. pct(red)) or "0%", red <= 0)
		definir("critMagia", pct(math.min(critico + valorPassiva("maestria", "critMagia"), 0.9), 1))
		definir("eco", pct(valorPassiva("ecoArcano", "eco")), valorPassiva("ecoArcano", "eco") <= 0)
		definir("pontos", tostring(estado.pontosHabilidade or 0))
	else
		for _, id in ipairs({ "poder", "elemFogo", "elemGelo", "elemRaio", "recarga", "critMagia", "eco", "pontos" }) do
			definir(id, "—", true)
		end
	end

	-- Aventura
	definir("velocidade", string.format("%.0f", s.velocidade or Config.Heroi.Velocidade))
	definir("ouro", "+" .. pct((s.ouro or 1) - 1), (s.ouro or 1) <= 1)
	definir("xp", "+" .. pct((s.xp or 1) - 1), (s.xp or 1) <= 1)
	definir("nivel", tostring(estado.nivel or 1))
	definir("fase", fase and (fase.nome or "?") or "?")
end

local function abrir()
	if not estado or not estado.classe then
		return
	end
	atualizar()
	gui.Enabled = true
	escalaJanela.Scale = 0.85
	TweenService:Create(escalaJanela, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end
local function fecharFicha()
	gui.Enabled = false
end
fechar.Activated:Connect(fecharFicha)
fundo.Activated:Connect(fecharFicha)

------------------------------------------------------------------------
-- Ficha dentro da mochila: a mochila (Hud, Jessica) tem um Frame "LugarFicha".
-- Desenhamos as seções lá; se a mochila for refeita, desenhamos de novo.
------------------------------------------------------------------------
local lugarAtual = nil
local function encaixar(lugar)
	if lugarAtual == lugar then
		return
	end
	lugarAtual = lugar
	-- largura 0 = ainda não foi medido: trata como largo
	local function largo()
		local x = lugar.AbsoluteSize.X
		return x == 0 or x >= 420
	end
	local function desenhar()
		local velho = lugar:FindFirstChild("FichaAtributos")
		if velho then
			velho:Destroy()
		end
		local corpoMochila = novo("Frame", lugar, {
			Name = "FichaAtributos",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
		})
		desenharSecoes(corpoMochila, not largo())
		atualizar()
	end
	desenhar()
	-- se mudar de largura (uma ou duas colunas), redesenha
	local largaAntes = largo()
	lugar:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		local larga = largo()
		if larga ~= largaAntes and lugar.AbsoluteSize.X > 0 then
			largaAntes = larga
			desenhar()
		end
	end)
end
task.spawn(function()
	local janelas = playerGui:WaitForChild("Janelas")
	local achado = janelas:FindFirstChild("LugarFicha", true)
	if achado and achado:IsA("GuiObject") then
		encaixar(achado)
	end
	janelas.DescendantAdded:Connect(function(d)
		if d.Name == "LugarFicha" and d:IsA("GuiObject") then
			encaixar(d)
		end
	end)
end)

-- Abre a mochila (se ela já tem a ficha) ou a janela da ficha
local function abrirFichaOuMochila()
	local hud = playerGui:FindFirstChild("Hud")
	if lugarAtual and lugarAtual.Parent and hud then
		hud:SetAttribute("AbrirAba", "mochila:atributos")
		task.defer(function()
			hud:SetAttribute("AbrirAba", nil)
		end)
	else
		abrir()
	end
end

evEstado.OnClientEvent:Connect(function(e)
	estado = e
	if gui.Enabled or (lugarAtual and lugarAtual.Parent) then
		atualizar()
	end
end)

------------------------------------------------------------------------
-- Abrir: botão 📊 ao lado do cartão do herói (Hud)
------------------------------------------------------------------------
task.spawn(function()
	local hud = playerGui:WaitForChild("Hud")
	local cartao = hud:WaitForChild("CartaoHeroi", 30)
	if not cartao then
		return
	end
	local b = novo("TextButton", cartao, {
		Name = "BotaoFicha",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(1, 10, 0.5, -4),
		Size = UDim2.fromOffset(48, 48),
		BackgroundColor3 = E.cor.ceu,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 5,
	})
	canto(b, 12)
	contorno(b, E.cor.tinta, 3)
	E.bala(b)
	E.sombra(b, 4)
	E.ligarEstados(b)
	E.icone(b, "ficha", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.4),
		Size = UDim2.fromOffset(38, 38),
		ZIndex = 6,
	})
	local placa = novo("Frame", b, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 1, -3),
		Size = UDim2.fromOffset(50, 16),
		BackgroundColor3 = E.cor.tinta,
		BorderSizePixel = 0,
		ZIndex = 7,
	})
	canto(placa, 999)
	E.titulo(placa, {
		Size = UDim2.fromScale(1, 1),
		Text = "Ficha",
		TextSize = 12,
		ZIndex = 8,
	}).ContornoTexto.Enabled =
		false
	b.Activated:Connect(function()
		if gui.Enabled then
			fecharFicha()
		else
			abrirFichaOuMochila()
		end
	end)
end)

local evPedir = remotes:FindFirstChild("PedirEstado")
if evPedir then
	evPedir:FireServer()
end
