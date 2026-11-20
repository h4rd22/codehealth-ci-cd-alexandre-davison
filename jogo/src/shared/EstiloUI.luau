--[[
	EstiloUI — a linguagem visual do jogo. TODA tela usa isto.

	A ideia: "caderno de desenho de anime". Painéis de tinta azul-noite com um
	traço escuro grosso por fora (como o contorno de um mangá) e um filete
	dourado fino por dentro. Nada de arco-íris, listras ou brilhinhos soltos:
	a cor forte só aparece onde importa (botão principal, aba ativa, raridade).

	Paleta (6 cores, mais nada):
	  tinta  — contorno e fundo mais escuro         (azul quase preto)
	  painel — fundo dos painéis                    (azul-noite)
	  papel  — texto e partes claras                (creme)
	  ouro   — destaque principal, moldura, ouro     (amarelo-mel)
	  sakura — vida, aba ativa, perigo               (rosa-avermelhado)
	  ceu    — XP, mana, informação                  (azul-céu)
	(verde só como estado "ligado/pronto"; as raridades usam as cores do Config.)

	Fontes: título = Fredoka One (redonda, fofa, legível); texto = Builder Sans Bold.

	Medidas: canto 10 (painel) / 8 (botão) / 6 (slot). Traço de fora 3, filete 1.
	Ícones: imagens grátis da Creator Store num só estilo (cartoon com contorno
	escuro). Use E.icone(pai, "mochila"). Emoji na tela é proibido.

	Movimento: hover 0.12s, aperto 0.06s, pop de janela 0.25s (Back), troca de aba 0.18s.
]]

local TweenService = game:GetService("TweenService")

local E = {}

E.cor = {
	tinta = Color3.fromRGB(20, 18, 32),
	painel = Color3.fromRGB(34, 32, 54),
	papel = Color3.fromRGB(250, 241, 222),
	ouro = Color3.fromRGB(246, 196, 82),
	sakura = Color3.fromRGB(238, 92, 120),
	ceu = Color3.fromRGB(96, 196, 246),
	-- derivadas (não são cores novas: são as de cima mais claras/escuras)
	painelClaro = Color3.fromRGB(58, 54, 96),
	painelTopo = Color3.fromRGB(60, 52, 112), -- topo do degradê dos painéis (índigo)
	painelFundo = Color3.fromRGB(26, 24, 42),
	papelFraco = Color3.fromRGB(184, 176, 204),
	ouroEscuro = Color3.fromRGB(150, 104, 30),
	verde = Color3.fromRGB(110, 210, 120),
	desligado = Color3.fromRGB(74, 72, 92),
}
local C = E.cor

E.fonteTitulo = Enum.Font.FredokaOne
E.fonteTexto = Enum.Font.BuilderSansBold

E.tw = {
	rapido = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	aperto = TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	pop = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	aba = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	suave = TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
}

-- Ícones (todos grátis da Creator Store, mesmo estilo: cartoon com contorno escuro)
E.ICONES = {
	mochila = "rbxassetid://127211318200556", -- ForgeGUI
	ficha = "rbxassetid://15403009775",
	portal = "rbxassetid://17368164592",
	config = "rbxassetid://17368089841",
	pergaminho = "rbxassetid://17368118782",
	presente = "rbxassetid://17368068524",
	lixo = "rbxassetid://17368204793",
	moeda = "rbxassetid://17368060122",
	moedas = "rbxassetid://15402844695",
	joia = "rbxassetid://17368064384",
	forca = "rbxassetid://15403007921",
	espada = "rbxassetid://17368210998",
	velocidade = "rbxassetid://17368052918",
	vida = "rbxassetid://17368075795",
	caveira = "rbxassetid://17368093079",
	energia = "rbxassetid://17368078790",
	cadeado = "rbxassetid://17368080973",
	aberto = "rbxassetid://17368081924",
	ok = "rbxassetid://17368190066",
	nao = "rbxassetid://17368208554",
	estrela = "rbxassetid://15403116835",
	chave = "rbxassetid://17368155868",
	fogo = "rbxassetid://15403144723",
	alerta = "rbxassetid://15402956142",
	pocao = "rbxassetid://15403265114",
	pocaoAzul = "rbxassetid://15403275152",
	repetir = "rbxassetid://17368214873",
	subir = "rbxassetid://17368045028",
	ampulheta = "rbxassetid://15937828418",
	bigorna = "rbxassetid://106612138886569",
	martelo = "rbxassetid://84285634186652",
	livroMagico = "rbxassetid://131578039274785",
	livro = "rbxassetid://127110909372919",
	pena = "rbxassetid://127175218024648",
	ovo = "rbxassetid://15498677766",
	treino = "rbxassetid://83584387545687",
	arco = "rbxassetid://293032928",
	coroa = "rbxassetid://16912465495",
	tinta = "rbxassetid://17368490346",
	olho = "rbxassetid://15403401665",
	casa = "rbxassetid://15403180857",
	-- magias (grátis, Creator Store)
	magiaGelo = "rbxassetid://125884111771213",
	magiaRaio = "rbxassetid://81061308210160",
	magiaFogo = "rbxassetid://15207511801",
	magiaArcano = "rbxassetid://2624609025",
}

-- Número com separador de milhar (1.234.567) — fica fácil de ler no celular
function E.numero(n: number): string
	local inteiro = tostring(math.floor(math.abs(n) + 0.5))
	local com = inteiro:reverse():gsub("(%d%d%d)", "%1."):reverse()
	if com:sub(1, 1) == "." then
		com = com:sub(2)
	end
	return (n < 0 and "-" or "") .. com
end

-- Magias: um ícone por elemento (alguns golpes têm o seu)
E.ICONE_ELEMENTO = { gelo = "magiaGelo", raio = "magiaRaio", fogo = "magiaFogo", arcano = "magiaArcano" }
E.ICONE_MAGIA = { meteoro = "fogo", tempestade = "energia", furiaTrovao = "energia", explosaoMorte = "caveira" }
function E.iconeMagia(h: any): string
	local nome = (h and (E.ICONE_MAGIA[h.id] or E.ICONE_ELEMENTO[h.ramo])) or "estrela"
	return E.ICONES[nome] or E.ICONES.estrela
end
function E.iconeElemento(ramo: string?): string
	return E.ICONES[E.ICONE_ELEMENTO[ramo or ""] or ""] or E.ICONES.estrela
end

-- Emblema de cada magia: um kanji próprio, branco com contorno de tinta, em cima
-- do quadrado na cor do elemento (estilo selo de técnica de anime).
E.KANJI_MAGIA = {
	lancaGelo = "槍", -- lança
	frioCortante = "刃", -- lâmina
	novaGelo = "凍", -- congelar
	nevasca = "雪", -- neve
	correnteRaio = "鎖", -- corrente
	sobrecarga = "電", -- eletricidade
	furiaTrovao = "雷", -- trovão
	tempestade = "嵐", -- tempestade
	bolaFogo = "火", -- fogo
	combustao = "燃", -- queimar
	anelChamas = "輪", -- anel
	meteoro = "星", -- estrela cadente
	poderArcano = "力", -- poder
	menteRapida = "速", -- rapidez
	ecoArcano = "響", -- eco
	maestria = "極", -- maestria
	afinidadeGelo = "氷", -- gelo
	afinidadeRaio = "雷", -- raio
	afinidadeFogo = "炎", -- chama
	harmonia = "和", -- harmonia
}
E.KANJI_ELEMENTO = { gelo = "氷", raio = "雷", fogo = "炎", arcano = "魔" }

-- Símbolo desenhado de cada magia (anel de runas na cor do elemento, pedra escura).
-- frioCortante e novaGelo vieram do ForgeGUI; os outros foram feitos no mesmo estilo.
E.SIMBOLO_MAGIA = {
	lancaGelo = "rbxassetid://138764210013256",
	frioCortante = "rbxassetid://137626917713851",
	novaGelo = "rbxassetid://79706450554064",
	nevasca = "rbxassetid://114409299875987",
	correnteRaio = "rbxassetid://99724607443871",
	sobrecarga = "rbxassetid://86537908508502",
	furiaTrovao = "rbxassetid://102198519836370",
	tempestade = "rbxassetid://117105414969101",
	bolaFogo = "rbxassetid://140156806790754",
	combustao = "rbxassetid://125392034109782",
	anelChamas = "rbxassetid://73688980593153",
	meteoro = "rbxassetid://84958894894832",
	poderArcano = "rbxassetid://140440413955507",
	menteRapida = "rbxassetid://71205398645703",
	ecoArcano = "rbxassetid://105131636169846",
	maestria = "rbxassetid://114662440526044",
	afinidadeGelo = "rbxassetid://128954620955365",
	afinidadeRaio = "rbxassetid://81116373469207",
	afinidadeFogo = "rbxassetid://122650059885875",
	harmonia = "rbxassetid://111470479070882",
}

function E.kanjiDe(h: any): string
	if not h then
		return ""
	end
	return E.KANJI_MAGIA[h.id] or E.KANJI_ELEMENTO[h.ramo] or "魔"
end

-- Troca o conteúdo de um TextLabel pelo kanji da magia (h = nil limpa)
function E.kanjiMagia(t: TextLabel | TextButton, h: any)
	local img = t:FindFirstChild("Img")
	if img then
		(img :: ImageLabel).Visible = false
	end
	-- com símbolo desenhado: mostra a imagem inteira (cantos arredondados) e nada de texto
	local simbolo = h and E.SIMBOLO_MAGIA[h.id]
	local sImg = t:FindFirstChild("Simbolo") :: ImageLabel?
	if simbolo then
		if not sImg then
			local novaS = E.novo("ImageLabel", t, {
				Name = "Simbolo",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				ScaleType = Enum.ScaleType.Crop,
				ZIndex = t.ZIndex,
			})
			E.canto(novaS, 10)
			t:GetPropertyChangedSignal("TextTransparency"):Connect(function()
				novaS.ImageTransparency = t.TextTransparency
			end)
			sImg = novaS
		end
		local si = sImg :: ImageLabel
		si.Image = simbolo
		si.Visible = true
		si.ImageTransparency = t.TextTransparency
		local pad = t:FindFirstChild("PadKanji")
		if pad then
			pad:Destroy()
		end
		t.Text = ""
		return
	elseif sImg then
		sImg.Visible = false
	end
	t.Text = E.kanjiDe(h)
	t.Font = E.fonteTitulo
	t.TextScaled = true
	t.TextColor3 = (h and h.tipo == "suprema") and Color3.fromRGB(255, 236, 170) or C.papel
	if not t:FindFirstChild("PadKanji") then
		E.novo("UIPadding", t, {
			Name = "PadKanji",
			PaddingTop = UDim.new(0.16, 0),
			PaddingBottom = UDim.new(0.16, 0),
			PaddingLeft = UDim.new(0.16, 0),
			PaddingRight = UDim.new(0.16, 0),
		})
	end
	local s = E.tracoTexto(t, 2.5)
	s.Enabled = true
end

-- Põe uma imagem no meio de um TextLabel que antes mostrava um emoji.
-- imagem = nil esconde. A transparência do texto passa para a imagem.
function E.imagemNoTexto(t: TextLabel | TextButton, imagem: string?, escala: number?)
	t.Text = ""
	local img = t:FindFirstChild("Img") :: ImageLabel?
	if not img then
		local novaImg = E.novo("ImageLabel", t, {
			Name = "Img",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(escala or 0.78, escala or 0.78),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = t.ZIndex,
		})
		t:GetPropertyChangedSignal("TextTransparency"):Connect(function()
			novaImg.ImageTransparency = t.TextTransparency
		end)
		novaImg.ImageTransparency = t.TextTransparency
		img = novaImg
	end
	local i = img :: ImageLabel
	i.Image = imagem or ""
	i.Visible = imagem ~= nil
	return i
end

-- Ícone de cada coisa do Config (classes, treinos, atributos) pelo id
E.ICONE_DE = {
	guerreiro = "espada",
	cacador = "arco",
	mago = "livroMagico",
	forca = "forca",
	vitalidade = "vida",
	precisao = "estrela",
	ganancia = "moedas",
	dano = "espada",
	vida = "vida",
	critico = "estrela",
	ouro = "moedas",
	velocidade = "velocidade",
}
function E.iconeDe(id: string?): string
	return E.ICONES[E.ICONE_DE[id or ""] or ""] or E.ICONES.estrela
end

local function novo(classe: string, pai: Instance?, props: { [string]: any }?): any
	local o = Instance.new(classe)
	for k, v in pairs(props or {}) do
		(o :: any)[k] = v
	end
	o.Parent = pai
	return o
end
E.novo = novo

function E.canto(o: Instance, r: number?)
	return novo("UICorner", o, { CornerRadius = UDim.new(0, r or 10) })
end

function E.traco(o: Instance, cor: Color3?, esp: number?)
	return novo("UIStroke", o, {
		Color = cor or C.tinta,
		Thickness = esp or 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
	})
end

-- Contorno do texto: escuro e fino (só nos textos claros)
function E.tracoTexto(t: TextLabel | TextButton, esp: number?)
	local s = t:FindFirstChild("ContornoTexto")
	if not s then
		s = novo("UIStroke", t, {
			Name = "ContornoTexto",
			ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
			Color = C.tinta,
		})
	end
	s.Thickness = esp or ((t.TextScaled or t.TextSize >= 18) and 2 or 1.2)
	t.TextStrokeTransparency = 1
	return s
end

-- Gradiente bem leve de cima para baixo (dá volume sem chamar atenção)
function E.volume(o: Instance, forca: number?)
	local f = forca or 0.18
	return novo("UIGradient", o, {
		Name = "Volume",
		Rotation = 90,
		Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1 - f, 1 - f, 1 - f)),
	})
end

-- "Bala": degradê com brilho em cima e uma borda escura embaixo (o botão parece
-- ter espessura, como um botão de verdade). Respeita os cantos arredondados.
function E.bala(o: Instance)
	local velho = o:FindFirstChild("Volume")
	if velho then
		velho:Destroy()
	end
	return novo("UIGradient", o, {
		Name = "Volume",
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(0.45, Color3.fromRGB(236, 236, 236)),
			ColorSequenceKeypoint.new(0.8, Color3.fromRGB(214, 214, 214)),
			ColorSequenceKeypoint.new(0.83, Color3.fromRGB(150, 150, 150)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 140, 140)),
		}),
	})
end

-- Sombra dura (estilo adesivo/anime): cópia escura do contorno, um pouco para baixo
function E.sombra(o: GuiObject, dist: number?, raio: number?)
	if o.ZIndex <= 0 or o:FindFirstChild("Sombra") then
		return nil
	end
	local d = dist or 4
	local sb = novo("Frame", o, {
		Name = "Sombra",
		Position = UDim2.fromOffset(d - 3, d - 1),
		Size = UDim2.new(1, 6, 1, 4),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
		ZIndex = o.ZIndex - 1,
	})
	local c = o:FindFirstChildOfClass("UICorner")
	E.canto(sb, raio or (c and c.CornerRadius.Offset + 2) or 12)
	return sb
end

-- Faixa de título dourada que sai do canto de cima à esquerda (janelas)
function E.faixaTitulo(pai: Instance, texto: string, largura: number?): (Frame, TextLabel)
	local fita = novo("Frame", pai, {
		Name = "FaixaTitulo",
		Position = UDim2.fromOffset(-10, -14),
		Size = UDim2.fromOffset(largura or 230, 44),
		Rotation = -2,
		BackgroundColor3 = C.ouro,
		BorderSizePixel = 0,
		ZIndex = 8,
	})
	E.canto(fita, 8)
	E.traco(fita, C.tinta, 3)
	novo("UIGradient", fita, {
		Name = "Volume",
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 244, 196)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 214, 110)),
			ColorSequenceKeypoint.new(0.8, Color3.fromRGB(240, 176, 60)),
			ColorSequenceKeypoint.new(0.83, Color3.fromRGB(190, 124, 36)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 116, 32)),
		}),
	})
	E.sombra(fita, 4)
	local t = E.titulo(fita, {
		Position = UDim2.fromOffset(14, -2),
		Size = UDim2.new(1, -24, 1, 0),
		Text = texto,
		TextSize = 24,
		TextColor3 = C.papel,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 9,
	})
	E.tracoTexto(t, 2.5)
	return fita, t
end

-- Ícone: ImageLabel de um dos ícones acima (ou de uma imagem qualquer)
function E.icone(pai: Instance, nome: string, props: { [string]: any }?): ImageLabel
	local img = novo("ImageLabel", pai, {
		Name = "Icone",
		BackgroundTransparency = 1,
		Image = E.ICONES[nome] or nome,
		ScaleType = Enum.ScaleType.Fit,
		Size = UDim2.fromOffset(24, 24),
	})
	for k, v in pairs(props or {}) do
		(img :: any)[k] = v
	end
	return img
end

-- Texto
function E.texto(pai: Instance, props: { [string]: any }?): TextLabel
	local t = novo("TextLabel", pai, {
		BackgroundTransparency = 1,
		Font = E.fonteTexto,
		TextColor3 = C.papel,
		TextSize = 14,
	})
	for k, v in pairs(props or {}) do
		(t :: any)[k] = v
	end
	E.tracoTexto(t)
	return t
end

function E.titulo(pai: Instance, props: { [string]: any }?): TextLabel
	local t = E.texto(pai, { Font = E.fonteTitulo, TextSize = 22 })
	for k, v in pairs(props or {}) do
		(t :: any)[k] = v
	end
	E.tracoTexto(t)
	return t
end

-- Painel: fundo azul-noite, traço de tinta grosso por fora, filete dourado por dentro
function E.painel(pai: Instance, props: { [string]: any }?, semFilete: boolean?): Frame
	local f = novo("Frame", pai, {
		BackgroundColor3 = C.painel,
		BorderSizePixel = 0,
	})
	for k, v in pairs(props or {}) do
		(f :: any)[k] = v
	end
	E.canto(f, 10)
	E.traco(f, C.tinta, 3)
	novo("UIGradient", f, {
		Name = "Volume",
		Rotation = 90,
		Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(150, 150, 165)),
	})
	if f.BackgroundColor3 == C.painel then
		f.BackgroundColor3 = C.painelTopo
	end
	E.sombra(f, 5)
	if not semFilete then
		local fil = novo("Frame", f, {
			Name = "Filete",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, -6, 1, -6),
			BackgroundTransparency = 1,
			ZIndex = f.ZIndex,
		})
		E.canto(fil, 8)
		local s = E.traco(fil, C.ouro, 1)
		s.Transparency = 0.45
	end
	return f
end

-- Botão com estados (normal / passar o mouse / apertado / desligado).
-- tipo: "principal" (ouro), "normal" (azul-noite claro), "perigo" (sakura), "info" (céu)
local CORES_BOTAO = {
	principal = { fundo = C.ouro, texto = C.tinta },
	normal = { fundo = C.painelClaro, texto = C.papel },
	perigo = { fundo = C.sakura, texto = C.papel },
	info = { fundo = C.ceu, texto = C.tinta },
	verde = { fundo = C.verde, texto = C.tinta },
}
E.CORES_BOTAO = CORES_BOTAO

-- muda a cor de fundo do botão e ajusta a cor/contorno do texto para ficar legível
function E.pintarBotao(b: GuiButton, fundo: Color3, textoCor: Color3?)
	b.BackgroundColor3 = fundo
	b:SetAttribute("CorBase", fundo)
	if b:IsA("TextButton") then
		local claro = (fundo.R * 0.3 + fundo.G * 0.59 + fundo.B * 0.11) > 0.55
		b.TextColor3 = textoCor or (claro and C.tinta or C.papel)
		local s = b:FindFirstChild("ContornoTexto")
		if s then
			(s :: UIStroke).Enabled = not claro
		end
	end
end

function E.ligarEstados(b: GuiButton)
	if b:GetAttribute("EstadosUI") then
		return
	end
	b:SetAttribute("EstadosUI", true)
	b.AutoButtonColor = false
	local esc = b:FindFirstChild("Escala") or novo("UIScale", b, { Name = "Escala" })
	local dentro = false
	local function base(): Color3
		return b:GetAttribute("CorBase") or b.BackgroundColor3
	end
	local function ativo()
		return b.Active and not b:GetAttribute("Desligado")
	end
	local tw: Tween? = nil
	local function cor(info: TweenInfo, alvo: Color3)
		local t = TweenService:Create(b, info, { BackgroundColor3 = alvo })
		tw = t
		t:Play()
	end
	local function claro()
		return base():Lerp(Color3.new(1, 1, 1), 0.14)
	end
	b.MouseEnter:Connect(function()
		dentro = true
		if ativo() then
			cor(E.tw.rapido, claro())
			TweenService:Create(esc, E.tw.rapido, { Scale = 1.04 }):Play()
		end
	end)
	b.MouseLeave:Connect(function()
		dentro = false
		cor(E.tw.rapido, base())
		TweenService:Create(esc, E.tw.rapido, { Scale = 1 }):Play()
	end)
	b.MouseButton1Down:Connect(function()
		if ativo() then
			cor(E.tw.aperto, base():Lerp(Color3.new(0, 0, 0), 0.18))
			TweenService:Create(esc, E.tw.aperto, { Scale = 0.94 }):Play()
		end
	end)
	b.MouseButton1Up:Connect(function()
		cor(E.tw.rapido, (dentro and ativo()) and claro() or base())
		TweenService:Create(esc, E.tw.pop, { Scale = dentro and 1.04 or 1 }):Play()
	end)
	-- se alguém trocar a cor do botão por fora, ela vira a nova cor base
	b:GetPropertyChangedSignal("BackgroundColor3"):Connect(function()
		if tw and tw.PlaybackState == Enum.PlaybackState.Playing then
			return
		end
		if not dentro then
			b:SetAttribute("CorBase", b.BackgroundColor3)
		end
	end)
end

function E.desligar(b: GuiButton, desligado: boolean)
	b:SetAttribute("Desligado", desligado)
	local base = b:GetAttribute("CorBase") or b.BackgroundColor3
	if desligado then
		b:SetAttribute("CorAntes", base)
		E.pintarBotao(b, C.desligado, C.papelFraco)
	elseif b:GetAttribute("CorAntes") then
		E.pintarBotao(b, b:GetAttribute("CorAntes"))
		b:SetAttribute("CorAntes", nil)
	end
end

function E.botao(pai: Instance, props: { [string]: any }?, tipo: string?): TextButton
	local cores = CORES_BOTAO[tipo or "normal"] or CORES_BOTAO.normal
	local b = novo("TextButton", pai, {
		Font = E.fonteTitulo,
		TextSize = 16,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
	})
	for k, v in pairs(props or {}) do
		(b :: any)[k] = v
	end
	E.canto(b, 8)
	E.traco(b, C.tinta, 2.5)
	E.bala(b)
	E.tracoTexto(b, 1.5)
	E.pintarBotao(b, props and props.BackgroundColor3 or cores.fundo, cores.texto)
	E.ligarEstados(b)
	return b
end

-- Põe um ícone à esquerda do texto de um botão (o texto anda para a direita)
function E.iconeNoBotao(b: TextButton, nome: string, tam: number?): ImageLabel
	local velho = b:FindFirstChild("IconeBotao")
	if velho then
		(velho :: ImageLabel).Image = E.ICONES[nome] or nome
		return velho :: ImageLabel
	end
	local t = tam or 22
	local img = E.icone(b, nome, {
		Name = "IconeBotao",
		-- (fica no espaço do UIPadding, por isso a posição é negativa)
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, -(t + 4), 0.5, 0),
		Size = UDim2.fromOffset(t, t),
		ZIndex = b.ZIndex + 1,
	})
	local pad = b:FindFirstChildOfClass("UIPadding") or novo("UIPadding", b)
	pad.PaddingLeft = UDim.new(0, t + 10)
	return img
end

-- Caixinha de marcar (no lugar de ✅/⬜): fica à esquerda do botão
function E.marcar(b: TextButton, ligado: boolean)
	local cx = b:FindFirstChild("Caixinha")
	if not cx then
		cx = novo("Frame", b, {
			Name = "Caixinha",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, -28, 0.5, 0),
			Size = UDim2.fromOffset(20, 20),
			BackgroundColor3 = C.painelFundo,
			ZIndex = b.ZIndex + 1,
		})
		E.canto(cx, 5)
		E.traco(cx, C.ouro, 1.5)
		E.icone(cx, "ok", {
			Name = "Visto",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1.15, 1.15),
			ZIndex = b.ZIndex + 2,
		})
		local pad = b:FindFirstChildOfClass("UIPadding") or novo("UIPadding", b)
		pad.PaddingLeft = UDim.new(0, 34)
		b.TextXAlignment = Enum.TextXAlignment.Left
	end
	(cx :: any).Visto.Visible = ligado
	return cx
end

-- Aba: apagada = só texto claro; ativa = pílula creme com texto escuro
function E.aba(pai: Instance, props: { [string]: any }?, icone: string?): TextButton
	local b = novo("TextButton", pai, {
		Font = E.fonteTitulo,
		TextSize = 15,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		BackgroundColor3 = C.painelFundo,
		TextColor3 = C.papelFraco,
		Text = "",
	})
	for k, v in pairs(props or {}) do
		(b :: any)[k] = v
	end
	E.canto(b, 8)
	local s = E.traco(b, C.tinta, 2)
	s.Name = "TracoAba"
	E.tracoTexto(b, 1.2)
	if icone then
		E.iconeNoBotao(b, icone, 20)
	end
	E.ligarEstados(b)
	return b
end

function E.marcarAba(b: GuiButton, ativa: boolean)
	local fundo = ativa and C.papel or C.painelFundo
	b:SetAttribute("CorBase", fundo)
	TweenService:Create(b, E.tw.aba, { BackgroundColor3 = fundo }):Play()
	if b:IsA("TextButton") then
		b.TextColor3 = ativa and C.tinta or C.papelFraco
		local s = b:FindFirstChild("ContornoTexto")
		if s then
			(s :: UIStroke).Enabled = not ativa
		end
	end
	local s = b:FindFirstChild("TracoAba")
	if s then
		(s :: UIStroke).Color = ativa and C.ouro or C.tinta
	end
	local risco = b:FindFirstChild("RiscoAtivo")
	if ativa and not risco then
		risco = novo("Frame", b, {
			Name = "RiscoAtivo",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 1, 3),
			Size = UDim2.new(0.5, 0, 0, 3),
			BackgroundColor3 = C.ouro,
			BorderSizePixel = 0,
		})
		E.canto(risco, 2)
	elseif not ativa and risco then
		risco:Destroy()
	end
end

-- Barra (vida, XP, progresso): fundo de tinta, enchimento colorido, texto no meio
function E.barra(pai: Instance, props: { [string]: any }?, cor: Color3?): (Frame, Frame, TextLabel)
	local fundo = novo("Frame", pai, { BackgroundColor3 = C.painelFundo, BorderSizePixel = 0 })
	for k, v in pairs(props or {}) do
		(fundo :: any)[k] = v
	end
	E.canto(fundo, 6)
	E.traco(fundo, C.tinta, 2)
	local cheio = novo("Frame", fundo, {
		Name = "Cheio",
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = cor or C.ceu,
		BorderSizePixel = 0,
	})
	E.canto(cheio, 6)
	E.volume(cheio, 0.3)
	-- risco claro em cima (brilho de tinta, não de vidro)
	local brilho = novo("Frame", cheio, {
		Position = UDim2.fromOffset(3, 2),
		Size = UDim2.new(1, -6, 0, 2),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
	})
	E.canto(brilho, 1)
	local txt = E.texto(fundo, { Size = UDim2.fromScale(1, 1), Text = "", TextSize = 12, ZIndex = 3 })
	return fundo, cheio, txt
end

-- Slot (espaço de item/equipamento)
function E.slot(pai: Instance, props: { [string]: any }?, corBorda: Color3?): Frame
	local f = novo("Frame", pai, { BackgroundColor3 = C.painelFundo, BorderSizePixel = 0 })
	for k, v in pairs(props or {}) do
		(f :: any)[k] = v
	end
	E.canto(f, 6)
	E.traco(f, corBorda or C.painelClaro, 2)
	return f
end

-- Botão de fechar: círculo sakura com um X desenhado (dois traços)
function E.fechar(pai: Instance, props: { [string]: any }?): TextButton
	local b = novo("TextButton", pai, {
		Name = "Fechar",
		Size = UDim2.fromOffset(34, 34),
		Text = "",
		AutoButtonColor = false,
		BorderSizePixel = 0,
	})
	for k, v in pairs(props or {}) do
		(b :: any)[k] = v
	end
	E.canto(b, 999)
	E.traco(b, C.tinta, 2.5)
	E.bala(b)
	E.pintarBotao(b, C.sakura)
	for _, rot in ipairs({ 45, -45 }) do
		local r = novo("Frame", b, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(0.5, 0, 0, 4),
			Rotation = rot,
			BackgroundColor3 = C.papel,
			BorderSizePixel = 0,
			ZIndex = b.ZIndex + 1,
		})
		E.canto(r, 2)
	end
	E.ligarEstados(b)
	return b
end

-- Abre um painel com "pop" (cresce de 0.85 a 1 com um quique pequeno)
function E.pop(o: GuiObject)
	local esc = o:FindFirstChild("EscalaPop") or novo("UIScale", o, { Name = "EscalaPop" })
	esc.Scale = 0.85
	TweenService:Create(esc, E.tw.pop, { Scale = 1 }):Play()
end

-- Deixa um elemento do tamanho certo em qualquer tela (mantém a proporção)
function E.proporcao(o: GuiObject, razao: number)
	return novo("UIAspectRatioConstraint", o, { AspectRatio = razao })
end

function E.limiteTexto(t: Instance, max: number, min: number?)
	return novo("UITextSizeConstraint", t, { MaxTextSize = max, MinTextSize = min or 8 })
end

return E
