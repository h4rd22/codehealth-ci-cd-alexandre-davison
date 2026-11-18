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
	painelClaro = Color3.fromRGB(52, 49, 80),
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
	mochila = "rbxassetid://15402958715",
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
}

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
	E.volume(f, 0.22)
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
	E.volume(b, 0.2)
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
	E.volume(b, 0.2)
	E.pintarBotao(b, C.sakura)
	for _, rot in ipairs({ 45, -45 }) do
		local r = novo("Frame", b, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(0.5, 0, 0, 4),
			Rotation = rot,
			BackgroundColor3 = C.papel,
			BorderSizePixel = 0,
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
