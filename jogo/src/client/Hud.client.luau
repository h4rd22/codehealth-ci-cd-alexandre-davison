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
local evJoia = R("Joia")

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
-- Toda a aparência vem do EstiloUI (paleta, fontes, molduras, botões). Os nomes
-- antigos de COR continuam valendo, mas apontam para a paleta nova.
local E = require(ReplicatedStorage.Shared:WaitForChild("EstiloUI"))
local COR = {
	painel = E.cor.painel,
	painel2 = E.cor.painelClaro,
	borda = E.cor.tinta,
	dourado = E.cor.ouro,
	roxo = E.cor.sakura, -- acento (aba ativa, destaques)
	ouro = E.cor.ouro,
	xp = E.cor.ceu,
	texto = E.cor.papel,
	fraco = E.cor.papelFraco,
	verde = E.cor.verde,
	cinza = E.cor.desligado,
	vermelho = E.cor.sakura,
	madeira = E.cor.painelClaro, -- botão padrão
	faixa = E.cor.painelFundo,
}
local contornoTexto, cintilar -- definidas mais abaixo
local FONTE = E.fonteTitulo
local FONTE_TEXTO = E.fonteTexto

local novo = E.novo
local function canto(o, r)
	return E.canto(o, r)
end
local function contorno(o, cor, esp)
	return E.traco(o, cor, esp)
end
local function caixa(pai, props)
	return E.painel(pai, props, true)
end
contornoTexto = function(t)
	E.tracoTexto(t)
end
local function rotulo(pai, props)
	local t = E.texto(pai, { Font = FONTE })
	for k, v in pairs(props or {}) do
		t[k] = v
	end
	t.TextStrokeTransparency = 1
	contornoTexto(t)
	return t
end
local function botao(pai, props)
	local b = E.botao(pai, props, "normal")
	b.TextStrokeTransparency = 1
	return b
end
local function barra(pai, props, cor)
	return E.barra(pai, props, cor)
end
local function bolinha(pai)
	local b = novo("Frame", pai, {
		Name = "Aviso",
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.new(1, -12, 0, -2),
		BackgroundColor3 = E.cor.sakura,
		Visible = false,
		ZIndex = 5,
	})
	canto(b, 7)
	contorno(b, E.cor.tinta, 2)
	return b
end

-- (os brilhinhos soltos e as quinas saíram: deixavam a tela poluída)
cintilar = function(_f, _n) end
-- Borda que pulsa devagar: só nos cartões de item de raridade alta
local function bordaViva(traco, cor1, cor2, tempo)
	traco.Color = cor1
	TweenService:Create(
		traco,
		TweenInfo.new(tempo or 1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Color = cor2 }
	):Play()
end

-- Joia desenhada na tela: losango lapidado com faceta, reflexo e brilho nos níveis altos.
-- cor = nil desenha um encaixe vazio.
local function iconeJoia(pai, cor, nivel, tam, props)
	nivel = nivel or 1
	local caixaJ = novo("Frame", pai, { Size = UDim2.fromOffset(tam, tam), BackgroundTransparency = 1 })
	for k, v in pairs(props or {}) do
		caixaJ[k] = v
	end
	local centro = { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) }
	if not cor then
		local vazio = novo("Frame", caixaJ, {
			AnchorPoint = centro.AnchorPoint,
			Position = centro.Position,
			Size = UDim2.fromScale(0.6, 0.6),
			Rotation = 45,
			BackgroundColor3 = Color3.fromRGB(26, 20, 18),
		})
		contorno(vazio, COR.borda, 1)
		return caixaJ
	end
	if nivel >= 4 then
		-- halo pulsando atrás da joia
		local halo = novo("Frame", caixaJ, {
			AnchorPoint = centro.AnchorPoint,
			Position = centro.Position,
			Size = UDim2.fromScale(1.25, 1.25),
			BackgroundColor3 = cor,
			BackgroundTransparency = 0.6,
		})
		canto(halo, 999)
		TweenService:Create(
			halo,
			TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ BackgroundTransparency = 0.88, Size = UDim2.fromScale(1.45, 1.45) }
		):Play()
	end
	local pedra = novo("Frame", caixaJ, {
		AnchorPoint = centro.AnchorPoint,
		Position = centro.Position,
		Size = UDim2.fromScale(0.7, 0.7),
		Rotation = 45,
		BackgroundColor3 = Color3.new(1, 1, 1),
	})
	novo("UIGradient", pedra, {
		Rotation = 0,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, cor:Lerp(Color3.new(1, 1, 1), 0.6)),
			ColorSequenceKeypoint.new(0.45, cor),
			ColorSequenceKeypoint.new(1, cor:Lerp(Color3.new(0, 0, 0), 0.55)),
		}),
	})
	contorno(pedra, cor:Lerp(Color3.new(1, 1, 1), 0.65), nivel >= 3 and 1.5 or 1)
	-- faceta do meio e reflexo
	novo("Frame", pedra, {
		AnchorPoint = centro.AnchorPoint,
		Position = centro.Position,
		Size = UDim2.fromScale(0.46, 0.46),
		BackgroundColor3 = cor:Lerp(Color3.new(1, 1, 1), 0.35),
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
	})
	novo("Frame", pedra, {
		Position = UDim2.fromScale(0.1, 0.1),
		Size = UDim2.fromScale(0.26, 0.26),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
	})
	if nivel >= 3 then
		local estrela = novo("Frame", caixaJ, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.85, 0.15),
			Size = UDim2.fromScale(0.22, 0.22),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Rotation = 45,
		})
		if nivel >= 5 then
			TweenService:Create(
				estrela,
				TweenInfo.new(1.2, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1),
				{ Rotation = 360 }
			):Play()
		end
	end
	return caixaJ
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
	elseif atributo == "vida" then
		return string.format("+%d de vida", v)
	elseif atributo == "danoPct" then
		return string.format("+%.1f%% de dano", v * 100)
	elseif atributo == "vidaPct" then
		return string.format("+%.1f%% de vida", v * 100)
	elseif atributo == "critDano" then
		return string.format("+%.0f%% de dano crítico", v * 100)
	elseif atributo == "velAtaque" then
		return string.format("+%.1f%% vel. de ataque", v * 100)
	elseif atributo == "resistencia" then
		return string.format("+%.1f%% de resistência", v * 100)
	elseif atributo == "armadura" then
		return string.format("+%d de armadura", v)
	elseif atributo == "armaduraPct" then
		return string.format("+%.0f%% de armadura", v * 100)
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
	local tracoCartao = contorno(b, r.corBorda or r.cor:Lerp(Color3.new(1, 1, 1), 0.3), ri >= 4 and 2.5 or 1.5)
	if ri >= 5 then
		local base = r.corBorda or r.cor:Lerp(Color3.new(1, 1, 1), 0.3)
		tracoCartao.Thickness = ri >= 7 and 3.5 or 3
		bordaViva(tracoCartao, base, Color3.new(1, 1, 1), ri >= 7 and 0.6 or 0.9)
	end
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
	ItemArte.mostrar(vp, s.id, ri, r.cor, item.conjunto, item.classe)
	-- ícone da classe (itens de arma, elmo e armadura são de uma classe só)
	local classeItem = item.classe and Config.ClassePorId(item.classe)
	if classeItem then
		local minhaClasse = player:GetAttribute("Classe")
		E.icone(b, E.iconeDe(classeItem.id), {
			Position = UDim2.new(0, item.conjunto and 14 or 2, 1, -17),
			Size = UDim2.fromOffset(16, 16),
			ZIndex = 4,
		})
		if minhaClasse and item.classe ~= minhaClasse then
			-- item de outra classe: fica avermelhado (não dá para vestir, mas serve na síntese)
			local veu = novo("Frame", b, {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Color3.fromRGB(120, 10, 20),
				BackgroundTransparency = 0.55,
				ZIndex = 3,
			})
			canto(veu, 10)
		end
	end
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
	-- brilho passando pelo cartão do Épico para cima (mais rápido nos tiers altos)
	if ri >= 4 then
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
			TweenInfo.new(
				ri >= 8 and 1.1 or ri >= 6 and 1.6 or 2.2,
				Enum.EasingStyle.Sine,
				Enum.EasingDirection.InOut,
				-1,
				false,
				ri >= 6 and 0.6 or 1.6
			),
			{ Offset = Vector2.new(1, 0) }
		):Play()
	end
	-- joias encaixadas: ícones lapidados embaixo e um brilho na cor da primeira joia
	if item.joias and next(item.joias) then
		local fila = novo("Frame", b, {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -13),
			Size = UDim2.fromOffset(60, 12),
			BackgroundTransparency = 1,
			ZIndex = 6,
		})
		novo("UIListLayout", fila, {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 1),
		})
		local primeira
		for k = 1, item.encaixes or 0 do
			local jJ, nJ = Config.LerJoia(item.joias[k] or "")
			if jJ then
				primeira = primeira or jJ.cor
				iconeJoia(fila, jJ.cor, nJ, 12, { LayoutOrder = k, ZIndex = 6 })
			end
		end
		if primeira then
			local brilhoJ = novo(
				"UIStroke",
				novo("Frame", b, {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.new(1, -6, 1, -6),
					BackgroundTransparency = 1,
					ZIndex = 5,
				}),
				{ Color = primeira, Thickness = 2, Transparency = 0.2 }
			)
			canto(brilhoJ.Parent, 8)
			TweenService:Create(
				brilhoJ,
				TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{ Transparency = 0.8 }
			):Play()
		end
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

------------------------------------------------------------------------
-- "Suco" dos botões: todo botão da HUD cresce ao passar o mouse, afunda ao
-- apertar e dá um pop com brilho, estrelinhas e som ao clicar
------------------------------------------------------------------------
do
	local guiSuco = novo(
		"ScreenGui",
		player.PlayerGui,
		{ Name = "SucoHud", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 20 }
	)
	local somClique = novo("Sound", guiSuco, { SoundId = "rbxasset://sounds/volume_slider.ogg", Volume = 0.6 })
	local SoundService = game:GetService("SoundService")
	local function tocarClique(tom)
		somClique.PlaybackSpeed = tom
		SoundService:PlayLocalSound(somClique)
	end

	-- Todo botão: som curto ao clicar. Os botões do EstiloUI já crescem/afundam sozinhos;
	-- os outros (cartões de item etc.) ganham um crescer/afundar discreto aqui.
	local function suco(b)
		if b:GetAttribute("SemSuco") or b:FindFirstChild("SucoEscala") then
			return
		end
		local esc = not b:GetAttribute("EstadosUI") and novo("UIScale", b, { Name = "SucoEscala" }) or nil
		local dentro = false
		local function ir(alvo, info)
			if esc then
				TweenService:Create(esc, info, { Scale = alvo }):Play()
			end
		end
		local function forca()
			local lado = math.max(b.AbsoluteSize.X, b.AbsoluteSize.Y)
			return lado > 500 and 0 or (lado > 200 and 0.4 or 1)
		end
		b.MouseEnter:Connect(function()
			dentro = true
			ir(1 + 0.05 * forca(), E.tw.rapido)
		end)
		b.MouseLeave:Connect(function()
			dentro = false
			ir(1, E.tw.rapido)
		end)
		b.MouseButton1Down:Connect(function()
			ir(1 - 0.06 * forca(), E.tw.aperto)
		end)
		b.MouseButton1Up:Connect(function()
			ir(dentro and 1 + 0.05 * forca() or 1, E.tw.pop)
		end)
		b.Activated:Connect(function()
			if forca() > 0 then
				tocarClique(1.1 + math.random() * 0.15)
			end
		end)
	end
	local function ligarSuco(raiz)
		for _, d in ipairs(raiz:GetDescendants()) do
			if d:IsA("GuiButton") then
				suco(d)
			end
		end
		raiz.DescendantAdded:Connect(function(d)
			if d:IsA("GuiButton") then
				task.defer(suco, d)
			end
		end)
	end
	ligarSuco(gui)
	ligarSuco(guiJanelas)
end

local estado = nil

-- Chips com os drops do chefe de uma fase. O Secreto mostra "???" até o jogador dropar.
local function preencherDrops(lista, faseIdx, tamanho)
	for _, c in ipairs(lista:GetChildren()) do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local ordem = 0
	local function chip(texto, cor)
		ordem += 1
		local c = rotulo(lista, {
			LayoutOrder = ordem,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, tamanho + 8),
			Text = " " .. texto .. " ",
			TextSize = tamanho,
			TextColor3 = cor,
			BackgroundTransparency = 0.2,
			BackgroundColor3 = Color3.fromRGB(14, 10, 18),
		})
		canto(c, 6)
		contorno(c, cor, 1)
	end
	local d = Config.DropsChefe
	chip(d.Ouro .. " ouro", COR.ouro)
	for _, par in ipairs(d.Equipamento) do
		local r = raridade(par[1])
		chip(r.nome .. " " .. math.floor(par[2] * 100 + 0.5) .. "%", r.corBorda or r.cor)
	end
	if not faseIdx then
		return
	end
	local vistos = estado and estado.secretos or {}
	for _, esp in ipairs(Config.EspeciaisDaFase(faseIdx)) do
		local r = raridade(esp.raridade)
		local nome = (esp.raridade == "secreto" and not vistos[esp.nome]) and "???" or esp.nome
		chip(nome .. " " .. (esp.chance * 100) .. "%", r.corBorda or r.cor)
	end
end
local autoFarm = true
player:SetAttribute("AutoFarm", true)

------------------------------------------------------------------------
-- Tela principal (estilo barra de tarefas): cartão do herói e ouro em cima à
-- esquerda, fase em cima à direita, botões das janelas embaixo à esquerda e
-- AUTO embaixo à direita. O meio de baixo fica livre para a barra de magias.
------------------------------------------------------------------------
-- Tudo foi desenhado para uma tela de 720 px de altura; em telas menores
-- (celular) ou maiores, cada bloco cresce/encolhe junto (UIScale).
local function escalaTela(o)
	local esc = novo("UIScale", o, { Name = "EscalaTela" })
	local function ajustar()
		local cam = workspace.CurrentCamera
		local h = cam and cam.ViewportSize.Y or 720
		esc.Scale = math.clamp(h / 720, 0.72, 1.3)
	end
	ajustar()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(ajustar)
	end
	return esc
end

local cartao = E.painel(gui, {
	Name = "CartaoHeroi", -- a Ficha de Atributos (Ficha.client.luau) põe um botão aqui
	Position = UDim2.fromOffset(14, 62), -- abaixo dos botões do Roblox (menu e chat)
	Size = UDim2.fromOffset(280, 78),
})
local escCartao = escalaTela(cartao)

-- Retrato do herói (foto do avatar do Roblox) com o nível num selo de ouro
local retratoHeroi = novo("ImageLabel", cartao, {
	Name = "Retrato",
	Position = UDim2.fromOffset(9, 9),
	Size = UDim2.fromOffset(60, 60),
	BackgroundColor3 = E.cor.painelClaro,
	Image = "",
	ScaleType = Enum.ScaleType.Crop,
	ZIndex = 2,
})
canto(retratoHeroi, 8)
contorno(retratoHeroi, E.cor.ouro, 2)
task.spawn(function()
	local ok, img = pcall(function()
		return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
	end)
	if ok and img then
		retratoHeroi.Image = img
	end
end)
local nivelBola = novo("Frame", cartao, {
	Name = "SeloNivel",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromOffset(16, 66),
	Size = UDim2.fromOffset(28, 28),
	BackgroundColor3 = E.cor.ouro,
	ZIndex = 3,
})
canto(nivelBola, 999)
contorno(nivelBola, E.cor.tinta, 2.5)
local lblNivel = E.titulo(nivelBola, {
	Size = UDim2.fromScale(1, 1),
	Text = "1",
	TextSize = 15,
	TextColor3 = E.cor.tinta,
	ZIndex = 4,
})
lblNivel.ContornoTexto.Enabled = false

E.titulo(cartao, {
	Name = "NomeHeroi",
	Position = UDim2.fromOffset(78, 7),
	Size = UDim2.new(1, -88, 0, 20),
	Text = player.DisplayName,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextSize = 17,
	TextTruncate = Enum.TextTruncate.AtEnd,
})
local _, vidaCheio, vidaTxt = barra(
	cartao,
	{ Name = "BarraVida", Position = UDim2.fromOffset(78, 30), Size = UDim2.new(1, -88, 0, 18) },
	E.cor.sakura
)
local _, xpCheio, xpTxt =
	barra(cartao, { Name = "BarraXP", Position = UDim2.fromOffset(78, 51), Size = UDim2.new(1, -88, 0, 12) }, E.cor.ceu)
xpTxt.TextSize = 10
vidaTxt.TextSize = 12
local lblPoder = E.texto(cartao, {
	Name = "Poder",
	Position = UDim2.fromOffset(80, 63),
	Size = UDim2.new(1, -90, 0, 13),
	Text = "",
	TextSize = 11,
	TextColor3 = E.cor.papelFraco,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextTruncate = Enum.TextTruncate.AtEnd,
})

-- Ouro: pílula embaixo do cartão, moeda grande saindo pela esquerda
local caixaOuro = novo("Frame", gui, {
	Name = "Ouro",
	Position = UDim2.fromOffset(30, 100),
	Size = UDim2.fromOffset(150, 34),
	BackgroundColor3 = E.cor.painelFundo,
	BorderSizePixel = 0,
})
canto(caixaOuro, 999)
contorno(caixaOuro, E.cor.tinta, 3)
local moeda = E.icone(caixaOuro, "moeda", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromOffset(4, 17),
	Size = UDim2.fromOffset(38, 38),
	ZIndex = 3,
})
local lblOuro = E.titulo(caixaOuro, {
	Position = UDim2.fromOffset(28, 0),
	Size = UDim2.new(1, -38, 1, 0),
	Text = "0",
	TextSize = 19,
	TextColor3 = E.cor.ouro,
	TextXAlignment = Enum.TextXAlignment.Left,
})
-- o ouro anda e cresce junto com o cartão quando a tela muda de tamanho
do
	local escOuro = novo("UIScale", caixaOuro, { Name = "EscalaTela" })
	local function seguir()
		escOuro.Scale = escCartao.Scale
		caixaOuro.Position = UDim2.fromOffset(14 + 16 * escCartao.Scale, 62 + 86 * escCartao.Scale)
	end
	seguir()
	escCartao:GetPropertyChangedSignal("Scale"):Connect(seguir)
end
-- O ouro sobe contando (e mostra "+N" subindo quando ganha)
local ouroMostrado = novo("NumberValue", caixaOuro, { Value = 0 })
ouroMostrado.Changed:Connect(function(v)
	lblOuro.Text = tostring(math.floor(v + 0.5))
end)
local ultimoOuro = nil
local function contarOuro(valor)
	if ultimoOuro == valor then
		return
	end
	local ganho = ultimoOuro and valor - ultimoOuro or 0
	ultimoOuro = valor
	TweenService:Create(ouroMostrado, TweenInfo.new(ganho > 0 and 0.5 or 0, Enum.EasingStyle.Quad), { Value = valor })
		:Play()
	if ganho > 0 then
		local mais = E.titulo(caixaOuro, {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(1, 6, 0.5, 0),
			Size = UDim2.fromOffset(80, 20),
			Text = "+" .. ganho,
			TextSize = 16,
			TextColor3 = E.cor.ouro,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		TweenService:Create(mais, TweenInfo.new(0.8, Enum.EasingStyle.Quad), {
			Position = UDim2.new(1, 6, 0.5, -20),
			TextTransparency = 1,
		}):Play()
		TweenService:Create(mais.ContornoTexto, TweenInfo.new(0.8), { Transparency = 1 }):Play()
		game:GetService("Debris"):AddItem(mais, 0.85)
	end
end

------------------------------------------------------------------------
-- Fase (canto direito de cima): toque para abrir o portal
------------------------------------------------------------------------
local btnRepetir -- criado logo depois do painel da fase
local painelFase = novo("TextButton", gui, {
	Name = "PainelFase",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -14, 0, 14),
	Size = UDim2.fromOffset(280, 70),
	BackgroundColor3 = E.cor.painel,
	BorderSizePixel = 0,
	Text = "",
	AutoButtonColor = false,
})
canto(painelFase, 10)
contorno(painelFase, E.cor.tinta, 3)
E.volume(painelFase, 0.22)
E.ligarEstados(painelFase)
local escFase = escalaTela(painelFase)

E.icone(painelFase, "portal", {
	Name = "IconePortal",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 6, 0.5, 0),
	Size = UDim2.fromOffset(56, 56),
})
local lblMundo = E.texto(painelFase, {
	Position = UDim2.fromOffset(68, 6),
	Size = UDim2.new(1, -78, 0, 14),
	TextSize = 12,
	TextColor3 = E.cor.papelFraco,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextTruncate = Enum.TextTruncate.AtEnd,
	Text = "Mundo 1",
})
local lblFase = E.titulo(painelFase, {
	Position = UDim2.fromOffset(68, 20),
	Size = UDim2.new(1, -78, 0, 22),
	TextSize = 20,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "Fase 1-1",
})
local _, killCheio, killTxt =
	barra(painelFase, { Position = UDim2.fromOffset(68, 46), Size = UDim2.new(1, -80, 0, 16) }, E.cor.ouro)
killTxt.TextSize = 11

-- Repetir a mesma fase (para farmar): não avança sozinho, mas libera a próxima no portal
btnRepetir = E.botao(gui, {
	Name = "Repetir",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -14, 0, 92),
	Size = UDim2.fromOffset(150, 32),
	Text = "Repetir: não",
	TextSize = 14,
})
E.iconeNoBotao(btnRepetir, "repetir", 22)
do
	local escRep = novo("UIScale", btnRepetir, { Name = "EscalaTela" })
	local function seguir()
		escRep.Scale = escFase.Scale
		btnRepetir.Position = UDim2.new(1, -14, 0, 14 + 78 * escFase.Scale)
	end
	seguir()
	escFase:GetPropertyChangedSignal("Scale"):Connect(seguir)
end
btnRepetir.Activated:Connect(function()
	if estado then
		evRepetir:FireServer(not estado.repetir)
	end
end)

------------------------------------------------------------------------
-- Botões das janelas (embaixo à esquerda, em grade 3x2): um ícone grande por janela.
-- Em grade para não encostar na barra de magias que fica no meio de baixo.
------------------------------------------------------------------------
local menu = novo("Frame", gui, {
	Name = "MenuLateral",
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 14, 1, -14),
	Size = UDim2.fromOffset(3 * 66 - 6, 2 * 68 - 6),
	BackgroundTransparency = 1,
})
escalaTela(menu)
novo("UIGridLayout", menu, {
	CellSize = UDim2.fromOffset(60, 60),
	CellPadding = UDim2.fromOffset(6, 8),
	SortOrder = Enum.SortOrder.LayoutOrder,
})

local botoesMenu, bolinhas = {}, {}
local function botaoMenu(ordem, id, icone, nome)
	local b = novo("TextButton", menu, {
		Name = "Menu_" .. id,
		LayoutOrder = ordem,
		Size = UDim2.fromOffset(60, 60),
		BackgroundColor3 = E.cor.painel,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
	})
	canto(b, 12)
	contorno(b, E.cor.tinta, 3)
	E.volume(b, 0.25)
	E.ligarEstados(b)
	E.icone(b, icone, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromOffset(44, 44),
		ZIndex = 2,
	})
	-- nome numa plaquinha de tinta presa na borda de baixo
	local placa = novo("Frame", b, {
		Name = "Placa",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 1, -2),
		Size = UDim2.fromOffset(58, 16),
		BackgroundColor3 = E.cor.tinta,
		BorderSizePixel = 0,
		ZIndex = 3,
	})
	canto(placa, 999)
	local t = E.titulo(placa, {
		Size = UDim2.fromScale(1, 1),
		Text = nome,
		TextSize = 12,
		TextColor3 = E.cor.papel,
		ZIndex = 4,
	})
	t.ContornoTexto.Enabled = false
	bolinhas[id] = bolinha(b)
	botoesMenu[id] = b
	return b
end
botaoMenu(1, "mochila", "mochila", "Mochila")
botaoMenu(2, "forja", "bigorna", "Forja")
botaoMenu(3, "habilidades", "livroMagico", "Magias")
botaoMenu(4, "ovos", "ovo", "Ovos")
botaoMenu(5, "treino", "treino", "Treino")
botaoMenu(6, "avatar", "tinta", "Avatar")

------------------------------------------------------------------------
-- Botão AUTO (embaixo à direita)
------------------------------------------------------------------------
do
	local btnAuto = E.botao(gui, {
		Name = "AutoFarm",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -14, 1, -14),
		Size = UDim2.fromOffset(150, 56),
		TextSize = 22,
		Text = "AUTO",
		TextXAlignment = Enum.TextXAlignment.Left,
	}, "principal")
	escalaTela(btnAuto)
	local raio = E.iconeNoBotao(btnAuto, "energia", 34)
	local pad = btnAuto:FindFirstChildOfClass("UIPadding")
	pad.PaddingBottom = UDim.new(0, 14)
	raio.Position = UDim2.new(0, -38, 0.5, 7)
	local sub = E.texto(btnAuto, {
		Name = "Estado",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 8),
		Size = UDim2.new(1, -8, 0, 14),
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	-- quando está ligado, o raio balança devagar (mostra que está trabalhando)
	local balanco = TweenService:Create(
		raio,
		TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Rotation = 12 }
	)
	local function pintarAuto()
		E.pintarBotao(btnAuto, autoFarm and E.cor.ouro or E.cor.desligado)
		sub.Text = autoFarm and "lutando sozinho" or "desligado"
		sub.TextColor3 = autoFarm and E.cor.tinta or E.cor.papelFraco
		sub.ContornoTexto.Enabled = not autoFarm
		raio.ImageTransparency = autoFarm and 0 or 0.5
		if autoFarm then
			balanco:Play()
		else
			balanco:Cancel()
			raio.Rotation = 0
		end
	end
	pintarAuto()
	btnAuto.Activated:Connect(function()
		autoFarm = not autoFarm
		player:SetAttribute("AutoFarm", autoFarm)
		evAutoFarm:FireServer(autoFarm)
		pintarAuto()
	end)
end

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
	-- mesma moldura em todas as janelas: painel de tinta, filete de ouro, cabeçalho
	-- com título à esquerda e o botão de fechar redondo saindo pelo canto
	local j = E.painel(guiJanelas, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.fromScale(0.94, 0.8),
		Visible = false,
	})
	novo("UISizeConstraint", j, { MaxSize = Vector2.new(760, 480) })
	local topo = novo("Frame", j, {
		Name = "Topo",
		Size = UDim2.new(1, 0, 0, 50),
		BackgroundTransparency = 1,
	})
	-- risco de tinta separando o cabeçalho do corpo
	novo("Frame", topo, {
		Name = "Risco",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.new(1, -24, 0, 2),
		BackgroundColor3 = E.cor.ouro,
		BackgroundTransparency = 0.6,
		BorderSizePixel = 0,
	})
	local lbl = E.titulo(topo, {
		Position = UDim2.fromOffset(18, 0),
		Size = UDim2.new(1, -80, 1, 0),
		Text = titulo,
		TextSize = 24,
		TextColor3 = E.cor.papel,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local fechar = E.fechar(j, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -8, 0, 8),
		Size = UDim2.fromOffset(38, 38),
		ZIndex = 10,
	})
	local corpo = novo(
		"Frame",
		j,
		{ Position = UDim2.fromOffset(12, 58), Size = UDim2.new(1, -24, 1, -70), BackgroundTransparency = 1 }
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
	E.pop(j)
	fundoEscuro.BackgroundTransparency = 1
	TweenService:Create(fundoEscuro, E.tw.rapido, { BackgroundTransparency = 0.45 }):Play()
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
	{ Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -56, 0, 34), BackgroundTransparency = 1 }
)
novo(
	"UIListLayout",
	abas,
	{ FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }
)

local paginas, botoesAba = {}, {}
local abaAtual = "mochila"
local function criarAba(ordem, id, texto, icone)
	local b = E.aba(abas, {
		Name = "Aba_" .. id,
		LayoutOrder = ordem,
		Size = UDim2.new(1 / 6, -6, 1, 0),
		Text = texto,
		TextSize = 15,
	}, icone)
	E.limiteTexto(b, 15, 9)
	b.TextScaled = true
	botoesAba[id] = b
	local p = novo("Frame", corpoMenu, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false })
	paginas[id] = p
	return p
end
local pgMochila = criarAba(1, "mochila", "Mochila", "mochila")
local pgForja = criarAba(2, "forja", "Forja", "bigorna")
local pgHab = criarAba(3, "habilidades", "Magias", "livroMagico")
pgHab.Name = "PaginaHabilidades" -- a árvore de magias é desenhada por Habilidades.client.luau
local pgOvos = criarAba(4, "ovos", "Ovos", "ovo")
local pgTreino = criarAba(5, "treino", "Treino", "treino")
local pgAvatar = criarAba(6, "avatar", "Avatar", "tinta")

local desenhar -- definida mais abaixo
local function mostrarAba(id)
	abaAtual = id
	for k, p in pairs(paginas) do
		if k == id and not p.Visible then
			p.Position = UDim2.fromOffset(0, 12)
			TweenService:Create(p, E.tw.aba, { Position = UDim2.fromOffset(0, 0) }):Play()
		end
		p.Visible = (k == id)
	end
	for k, b in pairs(botoesAba) do
		E.marcarAba(b, k == id)
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
-- (tudo dentro de um bloco do...end: o script já tem muitas variáveis no topo)
local pgEquip, slotUI, lblStats, mostrarSub, pintarBoneco, atualizarBoneco, temBoneco
do
	-- Sub-abas da mochila: "Equipamento" (boneco 3D no meio dos espaços) e "Atributos" (ficha)
	local subAbas = novo("Frame", pgMochila, {
		Name = "SubAbas",
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
	})
	novo("UIListLayout", subAbas, {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	pgEquip = novo("Frame", pgMochila, {
		Name = "Equipamento",
		Position = UDim2.fromOffset(0, 32),
		Size = UDim2.new(1, 0, 1, -32),
		BackgroundTransparency = 1,
	})
	local pgAtributos = novo("Frame", pgMochila, {
		Name = "Atributos",
		Position = UDim2.fromOffset(0, 32),
		Size = UDim2.new(1, 0, 1, -32),
		BackgroundColor3 = COR.painel2,
		Visible = false,
	})
	canto(pgAtributos, 12)
	contorno(pgAtributos, COR.dourado, 2)
	-- a Ficha de atributos (Ficha.client.luau) desenha dentro deste frame
	local lugarFicha = novo("Frame", pgAtributos, {
		Name = "LugarFicha",
		Position = UDim2.fromOffset(8, 8),
		Size = UDim2.new(1, -16, 1, -16),
		BackgroundTransparency = 1,
	})
	rotulo(lugarFicha, {
		Name = "Carregando",
		Size = UDim2.fromScale(1, 1),
		Text = "Atributos do herói",
		TextSize = 16,
		TextColor3 = COR.fraco,
		ZIndex = 0,
	})
	lugarFicha.ChildAdded:Connect(function(c)
		-- quando a ficha chega, o texto de espera some
		if c.Name ~= "Carregando" and lugarFicha:FindFirstChild("Carregando") then
			lugarFicha.Carregando:Destroy()
		end
	end)

	local botoesSub = {}
	mostrarSub = function(id)
		pgEquip.Visible = id == "equip"
		pgAtributos.Visible = id == "atributos"
		for k, b in pairs(botoesSub) do
			local ativa = k == id
			b.BackgroundColor3 = ativa and COR.roxo or COR.painel
			b.TextColor3 = ativa and Color3.fromRGB(255, 255, 235) or COR.fraco
			local traco = b:FindFirstChildOfClass("UIStroke")
			if traco then
				traco.Color = ativa and Color3.fromRGB(255, 236, 150) or COR.dourado
				traco.Thickness = ativa and 2.5 or 1.5
			end
		end
		local alvo = id == "equip" and pgEquip or pgAtributos
		alvo.Position = UDim2.fromOffset(0, 46)
		TweenService:Create(alvo, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { Position = UDim2.fromOffset(0, 32) })
			:Play()
	end
	for i, par in ipairs({ { "equip", "Equipamento" }, { "atributos", "Atributos" } }) do
		local b = botao(subAbas, {
			Name = "Sub_" .. par[1],
			LayoutOrder = i,
			Size = UDim2.fromOffset(150, 26),
			Text = par[2],
			TextSize = 14,
		})
		botoesSub[par[1]] = b
		b.Activated:Connect(function()
			mostrarSub(par[1])
		end)
	end

	------------------------------------------------------------------------
	-- Boneco (estilo TBH): o herói 3D vestido no meio e os espaços em volta
	------------------------------------------------------------------------
	local colEquip = novo("Frame", pgEquip, {
		Name = "Boneco",
		Size = UDim2.new(0.5, -6, 1, 0),
		BackgroundColor3 = Color3.fromRGB(26, 18, 34),
		BorderSizePixel = 0,
		ClipsDescendants = true,
	})
	canto(colEquip, 14)
	contorno(colEquip, COR.dourado, 2.5)
	novo("UIGradient", colEquip, {
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(90, 60, 140)),
			ColorSequenceKeypoint.new(0.55, Color3.fromRGB(46, 30, 70)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 14, 26)),
		}),
	})
	-- raios de luz girando atrás do herói (cor do item mais raro vestido)
	local raiosBoneco = novo("Frame", colEquip, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.48),
		Size = UDim2.fromScale(1.3, 1.3),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		BackgroundTransparency = 1,
	})
	local corRaios = COR.dourado
	local feixes = {}
	for i = 1, 10 do
		local f = novo("Frame", raiosBoneco, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(0, 22, 1, 0),
			Rotation = i * 18,
			BackgroundColor3 = corRaios,
			BackgroundTransparency = 0.86,
			BorderSizePixel = 0,
		})
		novo("UIGradient", f, {
			Rotation = 90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.5, 0),
				NumberSequenceKeypoint.new(1, 1),
			}),
		})
		table.insert(feixes, f)
	end
	-- brilho redondo e pedestal embaixo dos pés
	local auraBoneco = novo("Frame", colEquip, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.48),
		Size = UDim2.fromScale(0.62, 0.62),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		BackgroundColor3 = corRaios,
		BackgroundTransparency = 0.8,
	})
	canto(auraBoneco, 999)
	local pedestal = novo("Frame", colEquip, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.79),
		Size = UDim2.fromScale(0.5, 0.08),
		BackgroundColor3 = Color3.fromRGB(10, 6, 16),
		BackgroundTransparency = 0.25,
	})
	canto(pedestal, 999)
	local tracoPedestal = contorno(pedestal, corRaios, 2.5)

	local vpBoneco = novo("ViewportFrame", colEquip, {
		Name = "Heroi3D",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.66, 0.74),
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(170, 160, 180),
		LightColor = Color3.fromRGB(255, 245, 230),
		LightDirection = Vector3.new(-0.4, -1, -0.6),
		ZIndex = 2,
	})
	local mundoBoneco = novo("WorldModel", vpBoneco)
	local camBoneco = novo("Camera", vpBoneco, { FieldOfView = 32 })
	vpBoneco.CurrentCamera = camBoneco
	-- arrastar para girar o herói
	local arrastaBoneco = novo("TextButton", colEquip, {
		Name = "GirarBoneco",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.56, 0.62),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 3,
	})
	arrastaBoneco:SetAttribute("SemSuco", true)

	local LUGAR_SLOT = {
		brinco = { 0.3, 0.09 },
		elmo = { 0.5, 0.09 },
		colar = { 0.7, 0.09 },
		olho = { 0.9, 0.09 },
		arma = { 0.1, 0.32 },
		armadura = { 0.1, 0.52 },
		luvas = { 0.1, 0.72 },
		armaSec = { 0.9, 0.32 },
		bracelete = { 0.9, 0.52 },
		anel = { 0.9, 0.72 },
		cinto = { 0.22, 0.91 },
		calca = { 0.41, 0.91 },
		botas = { 0.59, 0.91 },
		broche = { 0.78, 0.91 },
	}
	slotUI = {}
	local slotsSemLugar = 0
	for i, s in ipairs(Config.Slots) do
		local lugar = LUGAR_SLOT[s.id]
		if not lugar then
			-- espaço novo que ainda não tem lugar: vai para o canto de cima à esquerda
			slotsSemLugar += 1
			lugar = { 0.1, 0.09 + (slotsSemLugar - 1) * 0.16 }
		end
		local linha = novo("TextButton", colEquip, {
			Name = "Slot_" .. s.id,
			LayoutOrder = i,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(lugar[1], lugar[2]),
			Size = UDim2.fromOffset(52, 52),
			BackgroundColor3 = Color3.fromRGB(34, 26, 44),
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = true,
			ZIndex = 4,
		})
		novo("UISizeConstraint", linha, { MinSize = Vector2.new(38, 38) })
		canto(linha, 10)
		local ic = novo("Frame", linha, {
			Position = UDim2.fromOffset(3, 3),
			Size = UDim2.new(1, -6, 1, -6),
			BackgroundColor3 = Color3.fromRGB(50, 42, 70),
			ZIndex = 4,
		})
		canto(ic, 8)
		novo("UIGradient", ic, {
			Rotation = 90,
			Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(120, 110, 130)),
		})
		local icStroke = contorno(ic, COR.cinza, 2.5)
		local icEmoji = E.texto(ic, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.92, 0.5),
			Text = s.nome,
			TextScaled = true,
			TextColor3 = E.cor.papelFraco,
			TextTransparency = 0.25,
			ZIndex = 5,
		})
		E.limiteTexto(icEmoji, 11, 7)
		-- nome do espaço numa faixinha embaixo
		local nome = rotulo(linha, {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 1, -9),
			Size = UDim2.fromOffset(60, 12),
			TextSize = 9,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = s.nome,
			TextColor3 = COR.fraco,
			TextStrokeTransparency = 0,
			ZIndex = 6,
		})
		local stat = rotulo(linha, { Size = UDim2.fromScale(0, 0), Visible = false, Text = "" })
		local bolinhasJoia = novo("Frame", linha, {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, -5),
			Size = UDim2.fromOffset(46, 11),
			BackgroundTransparency = 1,
			ZIndex = 7,
		})
		novo("UIListLayout", bolinhasJoia, {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 2),
		})
		slotUI[s.id] = {
			linha = linha,
			stroke = icStroke,
			nome = nome,
			stat = stat,
			ic = ic,
			emoji = icEmoji,
			bolinhas = bolinhasJoia,
		}
	end

	-- faixa de poder embaixo do herói
	lblStats = rotulo(colEquip, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.8),
		Size = UDim2.fromScale(0.6, 0.07),
		TextScaled = true,
		Font = FONTE,
		TextColor3 = Color3.fromRGB(255, 236, 160),
		RichText = true,
		Text = "",
		ZIndex = 5,
	})
	novo("UITextSizeConstraint", lblStats, { MaxTextSize = 13, MinTextSize = 8 })

	-- copia o personagem (com os equipamentos) para dentro do boneco
	local giroBoneco, arrastando, ultimoX = 0, false, 0
	local heroiCopia
	atualizarBoneco = function()
		local char = player.Character
		if not char or not char:FindFirstChild("HumanoidRootPart") then
			return
		end
		if heroiCopia then
			heroiCopia:Destroy()
			heroiCopia = nil
		end
		local antes = char.Archivable
		char.Archivable = true
		local ok, copia = pcall(function()
			return char:Clone()
		end)
		char.Archivable = antes
		if not ok or not copia then
			return
		end
		for _, d in ipairs(copia:GetDescendants()) do
			local lixo = d:IsA("BaseScript") or d:IsA("Sound") or d:IsA("ParticleEmitter") or d:IsA("Trail")
			if lixo or d:IsA("Highlight") or d:IsA("Beam") or d:IsA("BillboardGui") then
				d:Destroy()
			end
		end
		local hum = copia:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end
		local raiz = copia:FindFirstChild("HumanoidRootPart")
		for _, p in ipairs(copia:GetDescendants()) do
			if p:IsA("BasePart") then
				p.Anchored = p == raiz
			end
		end
		-- pose parada (sem a corrida do momento)
		for _, j in ipairs(copia:GetDescendants()) do
			if j:IsA("Motor6D") then
				j.Transform = CFrame.new()
			end
		end
		copia:PivotTo(CFrame.new(0, 0, 0))
		copia.Parent = mundoBoneco
		heroiCopia = copia
		-- enquadra o corpo inteiro com folga para as armas
		local _, tam = copia:GetBoundingBox()
		local altura = math.max(tam.Y, 5.5)
		local dist = (altura * 0.62) / math.tan(math.rad(camBoneco.FieldOfView / 2))
		camBoneco.CFrame = CFrame.lookAt(Vector3.new(0, 0.2, -dist), Vector3.new(0, 0, 0))
	end
	arrastaBoneco.MouseButton1Down:Connect(function(x)
		arrastando, ultimoX = true, x
	end)
	arrastaBoneco.MouseButton1Up:Connect(function()
		arrastando = false
	end)
	arrastaBoneco.MouseLeave:Connect(function()
		arrastando = false
	end)
	arrastaBoneco.MouseMoved:Connect(function(x)
		if arrastando then
			giroBoneco += (x - ultimoX) * 0.02
			ultimoX = x
		end
	end)
	local tBoneco = os.clock()
	RunService.RenderStepped:Connect(function(dt)
		if not colEquip.Visible or not pgEquip.Visible or not colEquip:IsDescendantOf(guiJanelas) then
			return
		end
		if not jMenu.Visible then
			return
		end
		local t = os.clock() - tBoneco
		raiosBoneco.Rotation = (t * 12) % 360
		auraBoneco.BackgroundTransparency = 0.78 + 0.08 * math.sin(t * 2.5)
		if not arrastando then
			giroBoneco += dt * 0.35
		end
		if heroiCopia and heroiCopia.Parent then
			heroiCopia:PivotTo(CFrame.Angles(0, giroBoneco, 0))
		end
	end)
	-- recria o boneco quando o equipamento do herói muda
	local function ligarPersonagem(char)
		char.ChildAdded:Connect(function(c)
			if c.Name == "Equipamento" then
				task.delay(0.3, function()
					if jMenu.Visible then
						atualizarBoneco()
					end
				end)
			end
		end)
	end
	if player.Character then
		ligarPersonagem(player.Character)
	end
	player.CharacterAdded:Connect(ligarPersonagem)
	-- pinta raios, brilho e pedestal com a cor do item mais raro vestido
	pintarBoneco = function(cor)
		for _, f in ipairs(feixes) do
			f.BackgroundColor3 = cor
		end
		auraBoneco.BackgroundColor3 = cor
		tracoPedestal.Color = cor
	end
	temBoneco = function()
		return heroiCopia ~= nil and heroiCopia.Parent ~= nil
	end
end

local colInv = novo(
	"Frame",
	pgEquip,
	{ Position = UDim2.new(0.5, 6, 0, 0), Size = UDim2.new(0.5, -6, 1, 0), BackgroundTransparency = 1 }
)
local NOMES_AUTOVENDA = { nada = "Desligada", comum = "até Comum", incomum = "até Incomum", raro = "até Raro" }
local btnAutoVenda = botao(colInv, {
	Name = "AutoVenda",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, 0, 0, -2),
	Size = UDim2.fromOffset(170, 22),
	Text = "Venda auto: Desligada",
	TextSize = 11,
})
E.iconeNoBotao(btnAutoVenda, "moedas", 16)
btnAutoVenda.Activated:Connect(function()
	if not estado then
		return
	end
	local ops = Config.AutoVendaOpcoes
	local i = table.find(ops, estado.autoVenda or "nada") or 1
	evAutoVenda:FireServer(ops[i % #ops + 1])
end)
-- Bolsa de joias: ver as joias e fundir 3 iguais em 1 melhor
local btnBolsa = botao(colInv, {
	Name = "BolsaJoias",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -176, 0, -2),
	Size = UDim2.fromOffset(92, 22),
	Text = "Joias",
	TextSize = 11,
})
E.iconeNoBotao(btnBolsa, "joia", 16)
local bolsaAberta = false
local painelJoias = novo("Frame", colInv, {
	Name = "PainelJoias",
	Position = UDim2.fromOffset(0, 24),
	Size = UDim2.new(1, 0, 1, -24 - 104),
	BackgroundColor3 = COR.painel2,
	Visible = false,
	ZIndex = 5,
})
canto(painelJoias, 12)
contorno(painelJoias, Color3.fromRGB(170, 110, 255), 2)
rotulo(painelJoias, {
	Position = UDim2.fromOffset(10, 4),
	Size = UDim2.new(1, -20, 0, 18),
	Text = "Joias — toque numa com 3 ou mais para fundir em 1 do nível de cima",
	TextSize = 11,
	Font = FONTE_TEXTO,
	TextColor3 = COR.fraco,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 6,
})
local gradeJoias = novo("Frame", painelJoias, {
	Position = UDim2.fromOffset(8, 26),
	Size = UDim2.new(1, -16, 1, -32),
	BackgroundTransparency = 1,
	ZIndex = 6,
})
local NIVEIS_J = #Config.Joias.Niveis
novo("UIGridLayout", gradeJoias, {
	CellSize = UDim2.new(1 / (NIVEIS_J + 1), -4, 1 / (#Config.Joias.Tipos + 1), -4),
	CellPadding = UDim2.fromOffset(4, 4),
	SortOrder = Enum.SortOrder.LayoutOrder,
	FillDirectionMaxCells = NIVEIS_J + 1,
})
local celulasJoia = {}
do
	local ordemJ = 0
	local function proxJ()
		ordemJ += 1
		return ordemJ
	end
	rotulo(gradeJoias, { LayoutOrder = proxJ(), Text = "", ZIndex = 6 })
	for n = 1, NIVEIS_J do
		rotulo(gradeJoias, {
			LayoutOrder = proxJ(),
			Text = Config.Joias.Niveis[n],
			TextSize = 11,
			TextColor3 = COR.dourado,
			ZIndex = 6,
		})
	end
	for _, tipo in ipairs(Config.Joias.Tipos) do
		local nomeTipo = rotulo(gradeJoias, {
			LayoutOrder = proxJ(),
			Text = "      " .. tipo.nome,
			TextSize = 12,
			TextColor3 = tipo.cor:Lerp(Color3.new(1, 1, 1), 0.3),
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 6,
		})
		nomeTipo.TextScaled = false
		iconeJoia(nomeTipo, tipo.cor, 3, 16, {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0, 0.5),
			ZIndex = 7,
		})
		for n = 1, NIVEIS_J do
			local chave = tipo.id .. ":" .. n
			local b = novo("TextButton", gradeJoias, {
				LayoutOrder = proxJ(),
				BackgroundColor3 = tipo.cor:Lerp(Color3.new(0, 0, 0), 0.75 - n * 0.08),
				Font = FONTE,
				TextSize = 12,
				TextColor3 = Color3.new(1, 1, 1),
				Text = "0",
				AutoButtonColor = true,
				ZIndex = 6,
			})
			canto(b, 8)
			local borda = contorno(b, COR.borda, 1.5)
			b.TextXAlignment = Enum.TextXAlignment.Right
			novo("UIPadding", b, { PaddingRight = UDim.new(0, 4) })
			iconeJoia(b, tipo.cor, n, 14 + n * 2, {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 3, 0.5, 0),
				ZIndex = 7,
			})
			b.Activated:Connect(function()
				local qtd = estado and estado.joias and estado.joias[chave] or 0
				if qtd >= 3 and n < NIVEIS_J then
					evJoia:FireServer("fundir", chave)
				end
			end)
			celulasJoia[chave] = { botao = b, borda = borda, n = n, tipo = tipo }
		end
	end
end

local function desenharJoias()
	if not estado then
		return
	end
	local total = 0
	for chave, c in pairs(celulasJoia) do
		local qtd = estado.joias and estado.joias[chave] or 0
		total += qtd
		local podeFundir = qtd >= 3 and c.n < NIVEIS_J
		local custo = Config.Joias.CustoFundir[c.n] or 0
		c.botao.Text = qtd == 0 and "·" or (podeFundir and ("x" .. qtd .. "\nfundir: " .. custo) or ("x" .. qtd))
		c.borda.Color = podeFundir and COR.dourado or (qtd > 0 and c.tipo.cor or COR.borda)
		c.borda.Thickness = podeFundir and 2.5 or 1.5
		c.botao.TextTransparency = qtd == 0 and 0.6 or 0
	end
	btnBolsa.Text = "Joias (" .. total .. ")"
end

btnBolsa.Activated:Connect(function()
	bolsaAberta = not bolsaAberta
	painelJoias.Visible = bolsaAberta
	btnBolsa.BackgroundColor3 = bolsaAberta and Color3.fromRGB(170, 110, 255) or Color3.fromRGB(90, 50, 140)
	desenharJoias()
end)

local lblInv = rotulo(colInv, {
	Size = UDim2.new(1, -272, 0, 20),
	Text = "Mochila 0/" .. Config.LimiteInventario,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextSize = 14,
	Font = FONTE,
})
local grade = novo("ScrollingFrame", colInv, {
	Position = UDim2.fromOffset(0, 24),
	Size = UDim2.new(1, 0, 1, -24 - 104),
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
	Position = UDim2.new(0, 0, 1, -98),
	Size = UDim2.new(1, 0, 0, 98),
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
-- Gravação de atributos (a janela fica em Gravacao.client.luau)
local btnGravar = botao(detalhe, {
	Name = "BtnGravar",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -8, 0, 68),
	Size = UDim2.fromOffset(130, 24),
	Text = "Gravar",
	TextSize = 13,
	Visible = false,
})
E.iconeNoBotao(btnGravar, "pena", 18)

local selecionado = nil -- id do item ou "slot:<id>"

-- Encaixes de joia do item escolhido (embaixo do detalhe)
local linhaEncaixes = novo("Frame", detalhe, {
	Position = UDim2.new(0, 10, 1, -30),
	Size = UDim2.new(1, -150, 0, 26),
	BackgroundTransparency = 1,
})
novo("UIListLayout", linhaEncaixes, {
	FillDirection = Enum.FillDirection.Horizontal,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
})
-- escolher qual joia encaixar
local escolhaJoia = novo("Frame", colInv, {
	Name = "EscolhaJoia",
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 8, 1, -100),
	Size = UDim2.new(1, -16, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundColor3 = COR.painel,
	Visible = false,
	ZIndex = 20,
})
canto(escolhaJoia, 10)
contorno(escolhaJoia, COR.dourado, 2)
novo("UIPadding", escolhaJoia, {
	PaddingTop = UDim.new(0, 6),
	PaddingBottom = UDim.new(0, 6),
	PaddingLeft = UDim.new(0, 6),
	PaddingRight = UDim.new(0, 6),
})
novo("UIGridLayout", escolhaJoia, {
	CellSize = UDim2.fromOffset(118, 26),
	CellPadding = UDim2.fromOffset(4, 4),
	SortOrder = Enum.SortOrder.LayoutOrder,
})
local itemEscolhaJoia
local confirmarRemover

local function nomeJoia(chave)
	local j, n = Config.LerJoia(chave)
	if not j then
		return "?", Color3.new(1, 1, 1), 1
	end
	return j.nome .. " " .. Config.Joias.Niveis[n], j.cor, n, j
end

local function abrirEscolhaJoia(it)
	for _, c in ipairs(escolhaJoia:GetChildren()) do
		if c:IsA("GuiButton") or c:IsA("TextLabel") then
			c:Destroy()
		end
	end
	itemEscolhaJoia = it
	local chaves = {}
	for chave, n in pairs(estado and estado.joias or {}) do
		if n > 0 then
			table.insert(chaves, chave)
		end
	end
	table.sort(chaves)
	if #chaves == 0 then
		rotulo(escolhaJoia, { Text = "Sem joias. Elas caem dos inimigos (raro).", TextSize = 11, ZIndex = 21 })
	end
	for i, chave in ipairs(chaves) do
		local nome, cor, n, j = nomeJoia(chave)
		local b = botao(escolhaJoia, {
			LayoutOrder = i,
			Text = "      " .. nome .. " x" .. estado.joias[chave],
			TextSize = 11,
			BackgroundColor3 = cor:Lerp(Color3.new(0, 0, 0), 0.45),
			ZIndex = 21,
		})
		b.TextXAlignment = Enum.TextXAlignment.Left
		iconeJoia(b, cor, n, 18, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 4, 0.5, 0), ZIndex = 22 })
		if j then
			b.Text ..= "  " .. string.format(j.texto, j.valores[n] * (j.valores[n] < 1 and 100 or 1))
		end
		b.Activated:Connect(function()
			evJoia:FireServer("encaixar", it.id, chave)
			escolhaJoia.Visible = false
		end)
	end
	escolhaJoia.Visible = true
end

local function desenharEncaixes(it)
	for _, c in ipairs(linhaEncaixes:GetChildren()) do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	if not it or (it.encaixes or 0) <= 0 then
		escolhaJoia.Visible = false
		if it then
			rotulo(linhaEncaixes, {
				Size = UDim2.fromOffset(220, 22),
				Text = "Sem espaço para joia (raridade Incomum ou maior)",
				TextSize = 10,
				Font = FONTE_TEXTO,
				TextColor3 = COR.fraco,
				TextXAlignment = Enum.TextXAlignment.Left,
			})
		end
		return
	end
	rotulo(linhaEncaixes, {
		LayoutOrder = 0,
		Size = UDim2.fromOffset(46, 22),
		Text = "Joias:",
		TextSize = 11,
		TextColor3 = COR.dourado,
	})
	for i = 1, it.encaixes do
		local chave = it.joias and it.joias[i]
		local b = novo("TextButton", linhaEncaixes, {
			LayoutOrder = i,
			Size = UDim2.fromOffset(chave and 92 or 26, 24),
			BackgroundColor3 = Color3.fromRGB(30, 26, 22),
			Font = FONTE,
			TextSize = 10,
			TextColor3 = Color3.new(1, 1, 1),
			Text = "+",
			AutoButtonColor = true,
		})
		canto(b, 12)
		local borda = contorno(b, COR.borda, 2)
		if chave then
			local nome, cor, nJ = nomeJoia(chave)
			b.Text = "     " .. nome
			b.TextScaled = true
			iconeJoia(b, cor, nJ, 18, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0) })
			b.BackgroundColor3 = cor:Lerp(Color3.new(0, 0, 0), 0.35)
			borda.Color = cor
			b.Activated:Connect(function()
				-- tirar a joia quebra ela: pede um segundo toque
				if confirmarRemover == it.id .. ":" .. i then
					confirmarRemover = nil
					evJoia:FireServer("remover", it.id, i)
				else
					confirmarRemover = it.id .. ":" .. i
					b.Text = "Quebrar? toque"
					task.delay(2.5, function()
						if confirmarRemover == it.id .. ":" .. i then
							confirmarRemover = nil
							if b.Parent then
								b.Text = "     " .. nome
							end
						end
					end)
				end
			end)
		else
			borda.Color = COR.dourado
			b.Activated:Connect(function()
				if escolhaJoia.Visible and itemEscolhaJoia == it then
					escolhaJoia.Visible = false
				else
					abrirEscolhaJoia(it)
				end
			end)
		end
	end
end

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
btnGravar.Activated:Connect(function()
	if type(selecionado) == "number" then
		player:SetAttribute("ItemGravar", nil)
		player:SetAttribute("ItemGravar", selecionado)
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
		btnEquipar.Visible, btnVender.Visible, btnGravar.Visible = false, false, false
		desenharEncaixes(nil)
		return
	end
	local r = raridade(it.raridade)
	detNome.Text = it.nome
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
	-- linhas gravadas
	if it.gravacoes and #it.gravacoes > 0 then
		local partes = {}
		for _, g in ipairs(it.gravacoes) do
			local q = Config.QualidadeGravacao(g.qualidade)
			table.insert(
				partes,
				string.format(
					'<font color="#%s">%s</font>',
					(q and q.cor or COR.fraco):ToHex(),
					Config.TextoGravacao(g)
				)
			)
		end
		detStat.Text ..= "\nGravado: " .. table.concat(partes, "  ·  ")
	end
	local classeIt = it.classe and Config.ClassePorId(it.classe)
	local outraClasse = classeIt and it.classe ~= estado.classe
	if classeIt then
		detStat.Text ..= string.format(
			'\n<font color="#%s">Só %s</font>%s',
			classeIt.cor:ToHex(),
			classeIt.nome,
			outraClasse and ' <font color="#ff6b6b">(outra classe: serve só para síntese)</font>' or ""
		)
	end
	local v = vestido(it.id)
	btnEquipar.Visible = not outraClasse
	btnEquipar.Text = v and "Tirar" or "Vestir"
	btnEquipar.BackgroundColor3 = v and COR.cinza or COR.verde
	btnVender.Visible = not v
	btnGravar.Visible = select(2, raridade(it.raridade)) >= Config.Gravacao.RaridadeMinima
	btnGravar.Text = "Gravar (" .. (it.gravacoes and #it.gravacoes or 0) .. "/" .. Config.Gravacao.Linhas .. ")"
	btnVender.Text = "Vender (+" .. (Config.ValorVenda[it.raridade] or 1) .. " ouro)"
	desenharEncaixes(it)
end

-- "Assinatura" dos itens: muda só quando entra/sai/veste/seleciona item (não a cada inimigo morto)
local function assinaturaItens(extra)
	local partes = { extra or "", tostring(player:GetAttribute("Classe")) }
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
local assinaturaBoneco = nil

local function desenharMochila()
	desenharJoias()
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
				ZIndex = 5,
			})
			vp:SetAttribute("Item", it.id)
			ItemArte.mostrar(vp, it.slot, ri3, r3.cor, it.conjunto, it.classe)
		end
		for _, c in ipairs(ui.bolinhas:GetChildren()) do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		if it then
			for k = 1, it.encaixes or 0 do
				local chaveJ = it.joias and it.joias[k]
				local jJ = chaveJ and Config.LerJoia(chaveJ)
				local _, nJ = Config.LerJoia(chaveJ or "")
				iconeJoia(ui.bolinhas, jJ and jJ.cor, nJ, 11, { ZIndex = 4 })
			end
			local r = raridade(it.raridade)
			ui.nome.Text = it.nome
			ui.nome.TextColor3 = r.corBorda or r.cor
			ui.stat.Text = textoItem(it)
			ui.stroke.Color = r.cor
		else
			ui.nome.Text = s.nome
			ui.nome.TextColor3 = COR.fraco
			ui.stat.Text = ""
			ui.stroke.Color = COR.cinza
		end
	end
	local st = estado.stats
	lblStats.Text = string.format("Dano <b>%d</b>  ·  Crítico <b>%.0f%%</b>", st.dano, st.critico * 100)
	-- boneco 3D: recria quando muda o que está vestido e pinta com a cor do item mais raro
	local assinaturaEquip, maiorRi, corMaior = "", 0, COR.dourado
	for _, s in ipairs(Config.Slots) do
		local idE = estado.equipado[s.id]
		assinaturaEquip ..= s.id .. "=" .. tostring(idE) .. ";"
		local itE = idE and itemPorId(idE)
		if itE then
			local rE, riE = raridade(itE.raridade)
			if riE > maiorRi then
				maiorRi, corMaior = riE, rE.corBorda or rE.cor
			end
		end
	end
	pintarBoneco(corMaior)
	if assinaturaEquip ~= assinaturaBoneco or not temBoneco() then
		assinaturaBoneco = assinaturaEquip
		task.delay(0.4, atualizarBoneco)
	end

	lblInv.Text = string.format("Mochila %d/%d", #estado.inventario, Config.LimiteInventario)
	btnAutoVenda.Text = "Venda auto: " .. (NOMES_AUTOVENDA[estado.autoVenda or "nada"] or "Desligada")
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
			local tag = E.icone(b, "ok", {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, 2, 0, -2),
				Size = UDim2.fromOffset(18, 18),
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

-- Outros scripts abrem uma aba assim: Hud:SetAttribute("AbrirAba", "mochila" | "mochila:atributos" | "forja"...)
gui:GetAttributeChangedSignal("AbrirAba"):Connect(function()
	local valor = gui:GetAttribute("AbrirAba")
	if type(valor) ~= "string" or valor == "" then
		return
	end
	local aba, sub = string.match(valor, "^([^:]+):?(.*)$")
	if aba and paginas[aba] then
		abrirJanela(jMenu)
		mostrarAba(aba)
		if aba == "mochila" then
			mostrarSub(sub == "atributos" and "atributos" or "equip")
		end
	end
end)

------------------------------------------------------------------------
-- Aba Forja (estilo síntese): modos Forja e Alquimia, espaços para
-- preencher, preenchimento automático, nível fixo e configurações.
------------------------------------------------------------------------
-- (bloco do...end: o script tem variáveis demais no topo)
local Q, desenharForja
do
	Q = Config.Forja.Quantidade
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
		Text = "Forja",
		Font = FONTE,
	})
	E.iconeNoBotao(btnModoForja, "bigorna", 20)
	local btnModoAlq = botao(barraForja, {
		Name = "ModoAlquimia",
		LayoutOrder = 2,
		Size = UDim2.fromScale(0.26, 1),
		Text = "Alquimia",
		Font = FONTE,
	})
	E.iconeNoBotao(btnModoAlq, "pocao", 20)
	local btnFiltro = botao(
		barraForja,
		{ Name = "FiltroNivel", LayoutOrder = 3, Size = UDim2.fromScale(0.3, 1), Text = "Nível: Todos" }
	)
	local btnEngrenagem =
		botao(barraForja, { Name = "ConfigForja", LayoutOrder = 4, Size = UDim2.fromScale(0.12, 1), Text = "" })
	E.icone(btnEngrenagem, "config", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -6, 1, -6),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
	})

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
		Text = "FORJA",
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
		Text = "Configurações da Forja",
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
		lblBigorna.Text = alq and "ALQUIMIA" or "FORJA"
		btnNivelFixo.Visible = not alq
		btnNivelFixo.Text = "Nível fixo (só itens do mesmo nível)"
		E.marcar(btnNivelFixo, nivelFixo)

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
			local custo = primeiro and Config.CustoForja(primeiro.raridade, primeiro.nivel) or 0
			if primeiro then
				local _, ri = raridade(primeiro.raridade)
				local prox = Config.Raridades[ri + 1]
				local cat = slotInfo(primeiro.slot)
				lblResultado.Text = string.format(
					'%s <font color="#%s"><b>%s</b></font> · %d ouro',
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
		btnCfgAuto.Text = "Combinação automática ao farmar"
		E.marcar(btnCfgAuto, c.auto)
		btnCfgAuto.BackgroundColor3 = c.auto and Color3.fromRGB(50, 130, 70) or COR.painel2
		local rAte = raridade(c.ate)
		btnCfgGrau.Text = "Grau máximo: " .. rAte.nome .. ""
		btnCfgGrau.TextColor3 = rAte.cor
		btnCfgNivel.Text = "Apenas itens do mesmo nível"
		E.marcar(btnCfgNivel, c.mesmoNivel)
		btnCfgAgora.Text = "Combinar tudo agora (até " .. rAte.nome .. ")"
	end
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
			if cont[chave] >= Q and estado.ouro >= Config.CustoForja(it.raridade, it.nivel) then
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
	E.icone(medalha, E.iconeDe(tr.id), {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.78, 0.78),
	})
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
	novo("UIGradient", c, {
		Rotation = 90,
		Color = ColorSequence.new(Color3.fromRGB(255, 240, 220), Color3.fromRGB(150, 130, 115)),
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
	-- faixa do meio: total ganho em destaque + barra de progresso dos níveis
	local faixaTotal = novo("Frame", c, {
		Position = UDim2.fromOffset(10, 72),
		Size = UDim2.new(1, -20, 1, -126),
		BackgroundColor3 = Color3.fromRGB(24, 17, 14),
		BackgroundTransparency = 0.25,
	})
	canto(faixaTotal, 10)
	contorno(faixaTotal, Color3.fromRGB(90, 62, 38), 1.5)
	local total = rotulo(faixaTotal, {
		Position = UDim2.fromOffset(0, 2),
		Size = UDim2.new(1, 0, 1, -22),
		Text = "",
		TextScaled = true,
		TextColor3 = Color3.fromRGB(255, 214, 110),
		TextStrokeTransparency = 0.1,
	})
	novo("UITextSizeConstraint", total, { MaxTextSize = 24, MinTextSize = 12 })
	novo("UIPadding", total, { PaddingTop = UDim.new(0, 4) })
	local _, progCheio, progTxt = barra(faixaTotal, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -6),
		Size = UDim2.new(1, -16, 0, 12),
	}, Color3.fromRGB(255, 170, 60))
	progTxt.TextSize = 10
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
	linhasTreino[tr.id] =
		{ nv = nv, efeito = efeito, botao = b, tr = tr, total = total, prog = progCheio, progTxt = progTxt }
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
		l.efeito.Text = (tr.texto:gsub("%%d", tostring(tr.valor)))
		l.total.Text = total
		l.prog.Size = UDim2.fromScale(math.clamp(n / math.max(tr.max, 1), 0, 1), 1)
		l.progTxt.Text = n .. " / " .. tr.max
		local custo = Config.CustoTreino(tr, n)
		local pode = n < tr.max and estado.ouro >= custo
		l.botao.Text = n >= tr.max and "MÁXIMO" or ("Treinar · " .. custo .. " ouro")
		l.botao.BackgroundColor3 = pode and COR.verde or COR.cinza
		l.botao.AutoButtonColor = pode
	end
end

------------------------------------------------------------------------
-- Abas Habilidades e Ovos (em breve)
------------------------------------------------------------------------
local function emBreve(pagina, icone, titulo, texto, qtd)
	local centro = novo("Frame", pagina, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(520, 330),
		BackgroundTransparency = 1,
	})
	-- raios dourados girando atrás do emblema
	local raios = novo("Frame", centro, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(260, 72),
		Size = UDim2.fromOffset(230, 230),
		BackgroundTransparency = 1,
	})
	for i = 1, 8 do
		local r = novo("Frame", raios, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(0, 22, 1, 0),
			Rotation = i * 22.5,
			BackgroundColor3 = Color3.fromRGB(255, 200, 90),
			BackgroundTransparency = 0.82,
			BorderSizePixel = 0,
		})
		novo("UIGradient", r, {
			Rotation = 90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.5, 0),
				NumberSequenceKeypoint.new(1, 1),
			}),
		})
	end
	TweenService:Create(raios, TweenInfo.new(18, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), {
		Rotation = 360,
	}):Play()
	-- brilho pulsando
	local brilho = novo("Frame", centro, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(260, 72),
		Size = UDim2.fromOffset(150, 150),
		BackgroundColor3 = Color3.fromRGB(255, 190, 80),
		BackgroundTransparency = 0.8,
	})
	canto(brilho, 75)
	TweenService:Create(
		brilho,
		TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Size = UDim2.fromOffset(170, 170), BackgroundTransparency = 0.9 }
	):Play()
	-- emblema
	local emblema = novo("Frame", centro, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(260, 72),
		Size = UDim2.fromOffset(112, 112),
		BackgroundColor3 = COR.madeira,
		ZIndex = 2,
	})
	canto(emblema, 56)
	contorno(emblema, COR.dourado, 4)
	novo("UIGradient", emblema, {
		Rotation = 90,
		Color = ColorSequence.new(Color3.fromRGB(255, 225, 190), Color3.fromRGB(120, 90, 70)),
	})
	E.icone(emblema, icone, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.72, 0.72),
		ZIndex = 3,
	})
	-- fita "EM BREVE"
	local fita = rotulo(centro, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(260, 128),
		Size = UDim2.fromOffset(130, 26),
		Text = "EM BREVE",
		TextSize = 16,
		TextColor3 = Color3.fromRGB(255, 236, 170),
		BackgroundTransparency = 0,
		BackgroundColor3 = COR.faixa,
		Rotation = -4,
		ZIndex = 4,
	})
	canto(fita, 6)
	contorno(fita, COR.dourado, 2)
	rotulo(centro, {
		Position = UDim2.fromOffset(0, 156),
		Size = UDim2.new(1, 0, 0, 28),
		Text = titulo,
		TextSize = 24,
		Font = FONTE,
		TextColor3 = Color3.fromRGB(255, 220, 130),
	})
	rotulo(centro, {
		Position = UDim2.fromOffset(20, 186),
		Size = UDim2.new(1, -40, 0, 36),
		Text = texto,
		TextSize = 14,
		Font = FONTE_TEXTO,
		TextColor3 = COR.fraco,
		TextWrapped = true,
	})
	local g = novo("Frame", centro, {
		Position = UDim2.fromOffset(0, 236),
		Size = UDim2.new(1, 0, 0, 84),
		BackgroundTransparency = 1,
	})
	novo("UIListLayout", g, {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 12),
	})
	for i = 1, qtd do
		local c = novo("Frame", g, { Size = UDim2.fromOffset(74, 74), BackgroundColor3 = COR.painel2, LayoutOrder = i })
		canto(c, 14)
		contorno(c, COR.borda, 2)
		novo("UIGradient", c, {
			Rotation = 90,
			Color = ColorSequence.new(Color3.fromRGB(255, 235, 215), Color3.fromRGB(120, 100, 90)),
		})
		E.icone(c, icone, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.6, 0.6),
			ImageTransparency = 0.55,
		})
		E.icone(c, "cadeado", {
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -4, 1, -2),
			Size = UDim2.fromOffset(22, 22),
		})
	end
end
emBreve(
	pgOvos,
	"ovo",
	"Ovos de Pet — em breve",
	"Aqui você vai chocar ovos para ganhar pets que lutam junto com o herói.",
	3
)

------------------------------------------------------------------------
-- Janela do Portal: mundos (com imagem 3D) e fases (com o rosto do inimigo)
------------------------------------------------------------------------
local jPortal, corpoPortal, _, fecharPortal = criarJanela("Portal")
fecharPortal.Activated:Connect(fecharJanelas)

local retratoInimigo, desenharPortal
do
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

	retratoInimigo = function(vp, nomeModelo)
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
	local difSel = 1 -- dificuldade escolhida no portal (Normal, Pesadelo, Inferno, Tormento)
	local botoesMundo = {}
	local botoesDif = {}
	local desenharPortalRef -- definida mais abaixo

	local function faseIndice(mundo, numero)
		local idx = Config.IndiceFase(difSel, mundo, numero)
		return Config.Fases[idx] and idx or nil
	end

	-- abas das dificuldades (em cima dos atos)
	local linhaDif =
		novo("Frame", colMundos, { LayoutOrder = 0, Size = UDim2.new(1, 0, 0, 56), BackgroundTransparency = 1 })
	novo("UIGridLayout", linhaDif, {
		CellSize = UDim2.new(0.5, -3, 0, 26),
		CellPadding = UDim2.fromOffset(6, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	for d, dif in ipairs(Config.Dificuldades) do
		local b = novo("TextButton", linhaDif, {
			Name = "Dif_" .. dif.id,
			LayoutOrder = d,
			BackgroundColor3 = dif.cor:Lerp(Color3.new(0, 0, 0), 0.55),
			AutoButtonColor = true,
			Font = FONTE,
			Text = dif.trancada and (dif.nome .. " · em breve") or dif.nome,
			TextSize = dif.trancada and 11 or 13,
			TextColor3 = Color3.new(1, 1, 1),
		})
		canto(b, 8)
		local borda = contorno(b, COR.borda, 2)
		botoesDif[d] = { botao = b, borda = borda, cor = dif.cor }
		b.Activated:Connect(function()
			local primeira = Config.IndiceFase(d, 1, 1)
			if estado and not dif.trancada and primeira <= estado.faseMax then
				difSel = d
				if desenharPortalRef then
					desenharPortalRef()
				end
			end
		end)
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
			Text = "Ato " .. i,
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 3,
		})
		rotulo(b, {
			Position = UDim2.new(0, 10, 1, -24),
			Size = UDim2.new(1, -20, 0, 18),
			Text = existe and m.nome or (m.nome .. " (em breve)"),
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
	local tituloDrops = rotulo(caixaDrops, {
		Position = UDim2.fromOffset(10, 2),
		Size = UDim2.new(1, -20, 0, 18),
		Text = "Drops do chefe",
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
		Padding = UDim.new(0, 3),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	})
	local function atualizarDropsPortal()
		local idx = faseIndice(mundoSel, 10)
		local f = idx and Config.Fases[idx]
		tituloDrops.Text = f and ("Drops do chefe " .. f.monstro .. " (" .. f.nome .. ")") or "Drops do chefe"
		preencherDrops(listaDrops, idx, 10)
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
			local borda =
				contorno(b, f and f.chefe and Color3.fromRGB(190, 90, 255) or COR.borda, f and f.chefe and 3 or 2)
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
			local cadeado = E.icone(veu, "cadeado", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(34, 34),
				ZIndex = 5,
			})
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
		-- abre o portal já na dificuldade e no ato onde o herói está
		local fAtual = estado and Config.Fases[estado.faseIdx]
		if fAtual then
			difSel, mundoSel = fAtual.dificuldade, fAtual.ato
		end
		abrirJanela(jPortal)
		desenhar()
	end)

	desenharPortal = function()
		local chaveMontada = difSel .. ":" .. mundoSel
		if mundoMontado ~= chaveMontada then
			montarCartoes(mundoSel)
			mundoMontado = chaveMontada
		end
		for d, info in pairs(botoesDif) do
			local liberada = estado and Config.IndiceFase(d, 1, 1) <= estado.faseMax
			info.botao.Text = Config.Dificuldades[d].nome
			local cad = info.botao:FindFirstChild("Cadeado")
				or E.icone(info.botao, "cadeado", {
					Name = "Cadeado",
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -4, 0.5, 0),
					Size = UDim2.fromOffset(18, 18),
					ZIndex = info.botao.ZIndex + 1,
				})
			cad.Visible = not liberada
			info.borda.Color = (d == difSel) and info.cor or COR.borda
			info.borda.Thickness = (d == difSel) and 3 or 2
			info.botao.BackgroundColor3 = info.cor:Lerp(Color3.new(0, 0, 0), d == difSel and 0.2 or 0.6)
		end
		for i, info in pairs(botoesMundo) do
			info.borda.Color = (i == mundoSel) and COR.dourado or COR.borda
			info.borda.Thickness = (i == mundoSel) and 3 or 2
		end
		lblMundoSel.Text = Config.Dificuldades[difSel].nome
			.. " · Ato "
			.. mundoSel
			.. " · "
			.. Config.Mundos[mundoSel].nome
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
		atualizarDropsPortal()
	end
	desenharPortalRef = desenharPortal
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
	Text = "Usar meu visual",
	TextSize = 12,
})
E.iconeNoBotao(btnMeuVisual, "casa", 18)
btnMeuVisual.Activated:Connect(function()
	evAvatar:FireServer(0)
end)
local btnEsconder = botao(topoAvatar, {
	Name = "EsconderEquip",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.fromScale(1, 0),
	Size = UDim2.fromOffset(162, 28),
	Text = "Equipamentos: visíveis",
	TextSize = 12,
})
E.iconeNoBotao(btnEsconder, "olho", 18)
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
for idx = 1, 10 do
	local f = Config.Fases[idx]
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
	rotulo(veu, { Position = UDim2.fromScale(0, 0.15), Size = UDim2.new(1, 0, 0, 30), Text = "", ZIndex = 6 })
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
	btnEsconder.Text = estado.esconderEquip and "Equipamentos: escondidos" or "Equipamentos: visíveis"
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
	local minhaClasse = Config.ClassePorId(estado.classe)
	lblPoder.Text = string.format(
		"%sDano %d · Crítico %.0f%%",
		minhaClasse and (minhaClasse.nome .. " · ") or "",
		estado.stats.dano,
		estado.stats.critico * 100
	)
	contarOuro(estado.ouro)

	local f = Config.Fases[estado.faseIdx]
	lblMundo.Text = Config.Dificuldades[f.dificuldade].nome
		.. " · Ato "
		.. f.ato
		.. " · "
		.. Config.Mundos[f.ato].nome
	lblFase.Text = "Fase " .. f.nome
	btnRepetir.Text = estado.repetir and "Repetir: sim" or "Repetir: não"
	E.pintarBotao(btnRepetir, estado.repetir and E.cor.verde or E.cor.painelClaro)
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

-- Cerimônia ao vestir item raro: clarão na tela, coluna de luz subindo no herói, som e faixa
local cerimoniaEquipar
do
	local SoundService = game:GetService("SoundService")
	local guiCerimonia = novo(
		"ScreenGui",
		player.PlayerGui,
		{ Name = "CerimoniaEquipar", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 30 }
	)
	local somForte =
		novo("Sound", guiCerimonia, { SoundId = "rbxasset://sounds/impact_explosion_03.mp3", Volume = 0.35 })
	local somLeve = novo("Sound", guiCerimonia, { SoundId = "rbxasset://sounds/volume_slider.ogg", Volume = 0.8 })
	local function luz3D(cor, ri)
		local char = player.Character
		local raiz = char and char:FindFirstChild("HumanoidRootPart")
		if not raiz then
			return
		end
		local function peca(props)
			local p = novo("Part", workspace, {
				Anchored = true,
				CanCollide = false,
				CanQuery = false,
				CanTouch = false,
				CastShadow = false,
				Material = Enum.Material.Neon,
				Color = cor,
				Shape = Enum.PartType.Cylinder,
			})
			for k, v in pairs(props) do
				p[k] = v
			end
			game:GetService("Debris"):AddItem(p, 1.2)
			return p
		end
		local pe = raiz.Position - Vector3.new(0, 2.8, 0)
		-- coluna de luz subindo
		local largura = 2.5 + ri * 0.3
		local coluna = peca({
			Size = Vector3.new(0.5, largura, largura),
			CFrame = CFrame.new(pe) * CFrame.Angles(0, 0, math.rad(90)),
			Transparency = 0.25,
		})
		TweenService:Create(coluna, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
			Size = Vector3.new(16 + ri * 2, largura * 0.6, largura * 0.6),
			CFrame = CFrame.new(pe + Vector3.new(0, 8 + ri, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		}):Play()
		TweenService:Create(coluna, TweenInfo.new(0.9), { Transparency = 1 }):Play()
		-- anel no chão se abrindo
		local anel = peca({
			Size = Vector3.new(0.2, 2, 2),
			CFrame = CFrame.new(pe) * CFrame.Angles(0, 0, math.rad(90)),
			Transparency = 0.15,
		})
		TweenService:Create(anel, TweenInfo.new(0.7, Enum.EasingStyle.Quad), {
			Size = Vector3.new(0.2, 18 + ri * 2, 18 + ri * 2),
			Transparency = 1,
		}):Play()
		-- estouro de brilhos
		local ancora = peca({ Size = Vector3.new(0.2, 0.2, 0.2), Transparency = 1, CFrame = CFrame.new(raiz.Position) })
		local fx = novo("ParticleEmitter", ancora, {
			Texture = "rbxasset://textures/particles/sparkles_main.dds",
			Color = ColorSequence.new(Color3.new(1, 1, 1), cor),
			LightEmission = 1,
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0) }),
			Lifetime = NumberRange.new(0.5, 0.9),
			Speed = NumberRange.new(12, 22),
			SpreadAngle = Vector2.new(180, 180),
			Rate = 0,
		})
		fx:Emit(20 + ri * 6)
	end
	cerimoniaEquipar = function(item, ri)
		local r = raridade(item.raridade)
		local cor = r.corBorda or r.cor
		luz3D(cor, ri)
		if ri >= 5 then
			somForte.PlaybackSpeed = ri >= 8 and 0.8 or 1.1
			SoundService:PlayLocalSound(somForte)
		else
			somLeve.PlaybackSpeed = 0.8
			SoundService:PlayLocalSound(somLeve)
		end
		if ri < 4 then
			return
		end
		-- clarão na cor da raridade
		local clarao = novo("Frame", guiCerimonia, {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = cor,
			BackgroundTransparency = 0.55,
			BorderSizePixel = 0,
		})
		TweenService:Create(clarao, TweenInfo.new(0.45), { BackgroundTransparency = 1 }):Play()
		game:GetService("Debris"):AddItem(clarao, 0.5)
		-- faixa grande no meio da tela
		local faixa = novo("Frame", guiCerimonia, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.3),
			Size = UDim2.new(1, 0, 0, 74),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.25,
			BorderSizePixel = 0,
		})
		novo("UIGradient", faixa, {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.new(0, 0, 0)),
				ColorSequenceKeypoint.new(0.5, cor:Lerp(Color3.new(0, 0, 0), 0.35)),
				ColorSequenceKeypoint.new(1, Color3.new(0, 0, 0)),
			}),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.2, 0),
				NumberSequenceKeypoint.new(0.8, 0),
				NumberSequenceKeypoint.new(1, 1),
			}),
		})
		local escala = novo("UIScale", faixa, { Scale = 0.3 })
		local titulo = rotulo(faixa, {
			Size = UDim2.new(1, 0, 0, 44),
			Text = "VESTIU " .. string.upper(r.nome) .. "!",
			TextSize = 38,
			TextColor3 = cor:Lerp(Color3.new(1, 1, 1), 0.35),
		})
		local nomeItem = rotulo(faixa, {
			Position = UDim2.fromOffset(0, 44),
			Size = UDim2.new(1, 0, 0, 26),
			Text = item.nome,
			TextSize = 20,
		})
		cintilar(faixa, 8)
		TweenService:Create(escala, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
			:Play()
		task.delay(1.6, function()
			TweenService:Create(faixa, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(titulo, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
			TweenService:Create(nomeItem, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
			for _, c in ipairs({ titulo, nomeItem }) do
				local traco = c:FindFirstChild("ContornoTexto")
				if traco then
					TweenService:Create(traco, TweenInfo.new(0.4), { Transparency = 1 }):Play()
				end
			end
			task.wait(0.45)
			faixa:Destroy()
		end)
	end
end
local equipadoAntes = nil

evEstado.OnClientEvent:Connect(function(novoEstado)
	estado = novoEstado
	-- algo novo foi vestido? mostra a cerimônia do item mais raro que entrou
	if equipadoAntes then
		local melhor, melhorRi = nil, 0
		for slot, id in pairs(estado.equipado or {}) do
			if id ~= equipadoAntes[slot] then
				local it = itemPorId(id)
				local riIt = 0
				if it then
					_, riIt = raridade(it.raridade)
				end
				if it and riIt > melhorRi then
					melhor, melhorRi = it, riIt
				end
			end
		end
		if melhor and melhorRi >= 3 then
			cerimoniaEquipar(melhor, melhorRi)
		end
	end
	equipadoAntes = table.clone(estado.equipado or {})
	if ouroAntes and estado.ouro > ouroAntes then
		moeda.Size = UDim2.fromOffset(46, 46)
		TweenService:Create(moeda, E.tw.pop, { Size = UDim2.fromOffset(38, 38) }):Play()
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
	Size = UDim2.fromScale(0.6, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	Visible = false,
})
novo("UISizeConstraint", barraChefe, { MaxSize = Vector2.new(520, 140) })
novo("UIPadding", barraChefe, { PaddingBottom = UDim.new(0, 8) })
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
-- vida do chefe em degradê roxo para rosa (mais chamativo)
chefeCheio:FindFirstChildOfClass("UIGradient").Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 70, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 80, 190)),
})
chefeCheio:FindFirstChildOfClass("UIGradient").Rotation = 0
chefeCheio.BackgroundColor3 = Color3.new(1, 1, 1)

-- Drops do chefe embaixo da barra de vida
local function chipsDrops(pai)
	local lista = novo("Frame", pai, { BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y })
	novo("UIListLayout", lista, {
		FillDirection = Enum.FillDirection.Horizontal,
		Wraps = true, -- se não couber numa linha, quebra para a de baixo (nada cortado)
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	})
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
local chaveDrops = nil -- refaz os chips só quando muda o chefe ou um Secreto é revelado
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
			lblChefe.Text = chefe.Name
			local revelados = 0
			for _ in pairs(estado and estado.secretos or {}) do
				revelados += 1
			end
			local chave = tostring(chefe:GetAttribute("Fase")) .. ":" .. revelados
			if chave ~= chaveDrops then
				chaveDrops = chave
				preencherDrops(dropsChefe, chefe:GetAttribute("Fase"), 11)
			end
			local resta = math.max(0, (chefe:GetAttribute("Fim") or 0) - workspace:GetServerTimeNow())
			chefeTxt.Text = string.format("%d / %d   ·   %d:%02d", vida, maximo, resta // 60, resta % 60)
			chefeCheio.Size = UDim2.fromScale(math.clamp(vida / maximo, 0, 1), 1)
		end
	end
end)

evPedirEstado:FireServer()
