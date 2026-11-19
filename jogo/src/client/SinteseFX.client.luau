-- SinteseFX: a "cerimônia" da síntese (forja) e da fusão de joias, estilo gacha.
-- 3 itens voam para o centro, giram cada vez mais rápido, fundem num clarão,
-- a raridade nova explode em cor e o item novo aparece grande com o nome.
-- Quanto mais rara, mais barulho, raios, tremida e confete.
-- Escuta: evento Loot tipo "forja" (item novo) e aviso "joiaFundida".
-- Várias forjas seguidas (forja automática) viram uma cerimônia só, com "x N".

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local ItemArte = require(Shared:WaitForChild("ItemArte"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local evLoot = remotes:WaitForChild("Loot")
local evAviso = remotes:WaitForChild("Aviso")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local FONTE = Enum.Font.FredokaOne
local BRANCO = Color3.new(1, 1, 1)

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
local function tw(o, tempo, props, estilo, direcao)
	local t = TweenService:Create(
		o,
		TweenInfo.new(tempo, estilo or Enum.EasingStyle.Quad, direcao or Enum.EasingDirection.Out),
		props
	)
	t:Play()
	return t
end
local function raridade(id)
	for i, r in ipairs(Config.Raridades) do
		if r.id == id then
			return r, i
		end
	end
	return Config.Raridades[1], 1
end
local function corDe(r)
	-- o Secreto é preto: usa a borda clara para brilhar
	if r.id == "secreto" then
		return r.corBorda or BRANCO
	end
	return r.cor
end

------------------------------------------------------------------------
-- Sons (arquivos que já vêm com o Roblox)
------------------------------------------------------------------------
local function som(id, volume, tom)
	local s = novo("Sound", playerGui, { SoundId = id, Volume = volume or 0.5, PlaybackSpeed = tom or 1 })
	s:Play()
	Debris:AddItem(s, 4)
end
local SOM_TIQUE = "rbxasset://sounds/volume_slider.ogg"
local SOM_BOOM = "rbxasset://sounds/impact_explosion_03.mp3"

local function tremer(forca, duracao)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end
	task.spawn(function()
		local fim = os.clock() + duracao
		while os.clock() < fim do
			local f = forca * (fim - os.clock()) / duracao
			hum.CameraOffset = Vector3.new((math.random() - 0.5) * f, (math.random() - 0.5) * f, 0)
			task.wait()
		end
		hum.CameraOffset = Vector3.zero
	end)
end

------------------------------------------------------------------------
-- Tela
------------------------------------------------------------------------
local gui = novo("ScreenGui", playerGui, {
	Name = "SinteseFX",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 40,
	Enabled = false,
})
local fundo = novo("TextButton", gui, {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(8, 4, 16),
	BackgroundTransparency = 1,
	Text = "",
	AutoButtonColor = false,
})
local palco = novo("Frame", gui, {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.46),
	Size = UDim2.fromOffset(10, 10),
	BackgroundTransparency = 1,
})
local CENTRO = UDim2.fromScale(0.5, 0.5)

-- Cartão de item (ou de joia) com moldura na cor da raridade
local function cartao(pai, tamanho, cor, item, ri, joiaCor)
	local c = novo("Frame", pai, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = CENTRO,
		Size = UDim2.fromOffset(tamanho, tamanho),
		BackgroundColor3 = Color3.fromRGB(24, 18, 32),
		ZIndex = 5,
	})
	canto(c, tamanho * 0.18)
	local borda = novo("UIStroke", c, { Color = cor, Thickness = math.max(3, tamanho / 30) })
	novo("UIGradient", borda, {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, cor),
			ColorSequenceKeypoint.new(0.5, BRANCO),
			ColorSequenceKeypoint.new(1, cor),
		}),
		Rotation = math.random(0, 360),
	})
	local brilho = novo("Frame", c, {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = cor,
		BackgroundTransparency = 0.55,
		ZIndex = 5,
	})
	canto(brilho, tamanho * 0.18)
	novo("UIGradient", brilho, {
		Rotation = 90,
		Transparency = NumberSequence.new(0.9, 0.1),
	})
	if joiaCor then
		-- joia: um losango brilhante
		local gema = novo("Frame", c, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = CENTRO,
			Size = UDim2.fromScale(0.5, 0.5),
			Rotation = 45,
			BackgroundColor3 = BRANCO,
			ZIndex = 6,
		})
		canto(gema, tamanho * 0.06)
		novo("UIGradient", gema, {
			Rotation = -45,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, joiaCor:Lerp(BRANCO, 0.7)),
				ColorSequenceKeypoint.new(0.45, joiaCor),
				ColorSequenceKeypoint.new(1, joiaCor:Lerp(Color3.new(0, 0, 0), 0.5)),
			}),
		})
		novo("UIStroke", gema, { Color = joiaCor:Lerp(BRANCO, 0.5), Thickness = 2 })
	elseif item then
		local vp = novo("ViewportFrame", c, {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = 6,
		})
		pcall(ItemArte.mostrar, vp, item.slot, ri, cor, item.conjunto, item.classe)
	end
	local esc = novo("UIScale", c)
	return c, esc
end

-- Faíscas voando do centro (frames pequenos)
local function faiscas(cor, qtd, dist, estrela)
	for i = 1, qtd do
		local ang = math.random() * math.pi * 2
		local d = dist * (0.5 + math.random() * 0.7)
		local tam = estrela and math.random(16, 26) or math.random(6, 14)
		local f
		if estrela then
			f = novo("TextLabel", palco, {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = CENTRO,
				Size = UDim2.fromOffset(tam, tam),
				BackgroundTransparency = 1,
				Text = "★",
				TextColor3 = i % 3 == 0 and BRANCO or cor,
				TextScaled = true,
				Font = FONTE,
				ZIndex = 8,
			})
		else
			f = novo("Frame", palco, {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = CENTRO,
				Size = UDim2.fromOffset(tam, tam * 0.4),
				Rotation = math.deg(ang),
				BackgroundColor3 = i % 3 == 0 and BRANCO or cor,
				ZIndex = 8,
			})
			canto(f, 3)
		end
		local alvo = CENTRO + UDim2.fromOffset(math.cos(ang) * d, math.sin(ang) * d)
		local tempo = 0.5 + math.random() * 0.5
		local props = { Position = alvo, Rotation = (f.Rotation or 0) + math.random(-90, 90) }
		if estrela then
			props.TextTransparency = 1
		else
			props.BackgroundTransparency = 1
			props.Size = UDim2.fromOffset(2, 2)
		end
		tw(f, tempo, props, Enum.EasingStyle.Quart)
		Debris:AddItem(f, tempo + 0.05)
	end
end

-- Anel de choque
local function onda(cor, tamanhoFinal, tempo, espessura)
	local a = novo("Frame", palco, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = CENTRO,
		Size = UDim2.fromOffset(40, 40),
		BackgroundTransparency = 1,
		ZIndex = 4,
	})
	canto(a, 999)
	local st = novo("UIStroke", a, { Color = cor, Thickness = espessura or 8 })
	tw(a, tempo, { Size = UDim2.fromOffset(tamanhoFinal, tamanhoFinal) }, Enum.EasingStyle.Quart)
	tw(st, tempo, { Transparency = 1, Thickness = 1 })
	Debris:AddItem(a, tempo + 0.05)
end

-- Raios girando atrás do item novo
local function raiosGirando(cor, qtd, tamanho)
	local r = novo("Frame", palco, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = CENTRO,
		Size = UDim2.fromOffset(tamanho, tamanho),
		BackgroundTransparency = 1,
		ZIndex = 2,
	})
	for i = 1, qtd do
		local raio = novo("Frame", r, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = CENTRO,
			Size = UDim2.new(0, 34, 1, 0),
			Rotation = i * 180 / qtd,
			BackgroundColor3 = i % 2 == 0 and cor or cor:Lerp(BRANCO, 0.4),
			BackgroundTransparency = 0.2,
			BorderSizePixel = 0,
			ZIndex = 2,
		})
		novo("UIGradient", raio, {
			Rotation = 90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.35, 0.3),
				NumberSequenceKeypoint.new(0.5, 0),
				NumberSequenceKeypoint.new(0.65, 0.3),
				NumberSequenceKeypoint.new(1, 1),
			}),
		})
	end
	local esc = novo("UIScale", r, { Scale = 0.2 })
	tw(esc, 0.4, { Scale = 1 }, Enum.EasingStyle.Back)
	TweenService:Create(r, TweenInfo.new(9, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), {
		Rotation = 360,
	}):Play()
	return r
end

------------------------------------------------------------------------
-- A cerimônia
-- dados = { cor, corVelha, item?, riNovo, riVelho, joiaCor?, titulo, nome, vezes }
------------------------------------------------------------------------
local tocando = false
local pular = false
fundo.Activated:Connect(function()
	pular = true
end)

local function esperar(seg)
	local fim = os.clock() + seg
	while os.clock() < fim and not pular do
		task.wait()
	end
end

local function cerimonia(d)
	tocando = true
	pular = false
	for _, filho in ipairs(palco:GetChildren()) do
		filho:Destroy()
	end
	gui.Enabled = true
	-- sorte da síntese: +2 = festa máxima, 0 = murcho (sem festa), -1 = quebrou
	local salto = d.salto or 1
	local super = salto >= 2
	local quebrou = salto < 0
	local festa = salto >= 1
	local forte = super or (festa and d.riNovo >= 4) -- Épico ou mais
	local muitoForte = super or (festa and d.riNovo >= 5) -- Lendário ou mais
	fundo.BackgroundTransparency = 1
	tw(fundo, 0.3, { BackgroundTransparency = forte and 0.25 or 0.4 })

	-- 1) os itens (6 na síntese) chegam de fora, um atrás do outro, e formam um círculo
	local N = d.qtd or (d.joiaCor and 3) or ((Config.Forja and Config.Forja.Quantidade) or 6)
	local cartoes = {}
	local angulos = {}
	local RAIO0 = N > 3 and 190 or 150
	for i = 1, N do
		angulos[i] = -90 + (i - 1) * (360 / N)
		local a = math.rad(angulos[i])
		local c, esc = cartao(palco, N > 3 and 84 or 96, d.corVelha, d.item, d.riVelho, d.joiaCor)
		c.Position = CENTRO + UDim2.fromOffset(math.cos(a) * 700, math.sin(a) * 500)
		c.Rotation = math.random(-40, 40)
		esc.Scale = 0.6
		cartoes[i] = { frame = c, esc = esc }
	end
	for i, cc in ipairs(cartoes) do
		local a = math.rad(angulos[i])
		task.wait(0.06)
		som(SOM_TIQUE, 0.5, 0.7 + i * 0.08)
		tw(cc.frame, 0.45, {
			Position = CENTRO + UDim2.fromOffset(math.cos(a) * RAIO0, math.sin(a) * RAIO0),
			Rotation = 0,
		}, Enum.EasingStyle.Back)
		tw(cc.esc, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)
	end
	som(SOM_TIQUE, 0.6, 0.8)
	esperar(0.5)

	-- 2) giram cada vez mais rápido e se aproximam; o núcleo cresce
	local nucleo = novo("Frame", palco, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = CENTRO,
		Size = UDim2.fromOffset(10, 10),
		BackgroundColor3 = d.corVelha,
		BackgroundTransparency = 0.2,
		ZIndex = 3,
	})
	canto(nucleo, 999)
	novo("UIGradient", nucleo, {
		Color = ColorSequence.new(BRANCO, d.corVelha),
		Transparency = NumberSequence.new(0, 0.6),
	})
	local DUR = forte and 1.5 or 1.2
	tw(fundo, DUR, { BackgroundTransparency = forte and 0.05 or 0.15 }) -- a tela escurece durante a antecipação
	local t0 = os.clock()
	local proxTique = 0
	local ang = 0
	while not pular do
		local t = (os.clock() - t0) / DUR
		if t >= 1 then
			break
		end
		ang += (2 + t * 22) * (1 / 60)
		local raio = RAIO0 * (1 - t * t)
		for i, cc in ipairs(cartoes) do
			local a = math.rad(angulos[i]) + ang
			cc.frame.Position = CENTRO + UDim2.fromOffset(math.cos(a) * raio, math.sin(a) * raio)
			cc.frame.Rotation = math.deg(ang) * 0.5
			cc.esc.Scale = 1 - t * 0.55
		end
		local tamN = 20 + t * (forte and 200 or 150)
		nucleo.Size = UDim2.fromOffset(tamN, tamN)
		nucleo.BackgroundColor3 = d.corVelha:Lerp(d.cor, t)
		if t >= proxTique then
			som(SOM_TIQUE, 0.45, 0.8 + t * 1.6)
			proxTique += 0.12
		end
		if t > 0.25 then
			-- tremor que cresce até a explosão
			local f = (t - 0.25) / 0.75
			local amp = 4 + f * f * (forte and 22 or 14)
			palco.Position = UDim2.new(0.5, (math.random() - 0.5) * amp, 0.46, (math.random() - 0.5) * amp)
		end
		RunService.RenderStepped:Wait()
	end
	palco.Position = UDim2.fromScale(0.5, 0.46)
	for _, cc in ipairs(cartoes) do
		cc.frame:Destroy()
	end
	nucleo:Destroy()

	-- 3) clarão + explosão da cor nova (ou o "puf" murcho / a quebra vermelha)
	if not festa then
		local corRuim = quebrou and Color3.fromRGB(230, 40, 40) or Color3.fromRGB(150, 145, 160)
		local flashRuim = novo("Frame", gui, {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = corRuim,
			BackgroundTransparency = quebrou and 0.35 or 0.7,
			ZIndex = 20,
		})
		tw(flashRuim, 0.4, { BackgroundTransparency = 1 })
		Debris:AddItem(flashRuim, 0.5)
		som(SOM_BOOM, quebrou and 0.5 or 0.25, quebrou and 0.5 or 0.65)
		tremer(quebrou and 0.9 or 0.2, 0.3)
		onda(corRuim, 360, 0.5, 6)
		faiscas(corRuim, quebrou and 28 or 10, quebrou and 260 or 140)
		if quebrou then
			-- cacos vermelhos caindo
			for _ = 1, 10 do
				local caco = novo("Frame", palco, {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = CENTRO + UDim2.fromOffset(math.random(-60, 60), math.random(-60, 60)),
					Size = UDim2.fromOffset(math.random(12, 24), math.random(8, 16)),
					Rotation = math.random(0, 360),
					BackgroundColor3 = corRuim,
					ZIndex = 8,
				})
				tw(caco, 0.9, {
					Position = caco.Position + UDim2.fromOffset(math.random(-80, 80), math.random(180, 300)),
					Rotation = caco.Rotation + math.random(-180, 180),
					BackgroundTransparency = 1,
				}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				Debris:AddItem(caco, 0.95)
			end
		end
	end
	if super then
		-- "slow motion": tudo congela por 0,3 s com zoom da câmera antes de estourar
		local cam = workspace.CurrentCamera
		local fov0 = cam.FieldOfView
		tw(cam, 0.3, { FieldOfView = fov0 - 18 }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local brilho = novo("Frame", palco, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = CENTRO,
			Size = UDim2.fromOffset(60, 60),
			BackgroundColor3 = Color3.fromRGB(255, 230, 120),
			ZIndex = 9,
		})
		canto(brilho, 999)
		tw(brilho, 0.3, { Size = UDim2.fromOffset(26, 26) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		esperar(0.3)
		brilho:Destroy()
		tw(cam, 0.6, { FieldOfView = fov0 }, Enum.EasingStyle.Back)
	end
	local flash = novo("Frame", gui, {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = BRANCO,
		BackgroundTransparency = 0,
		ZIndex = 20,
	})
	flash.Visible = festa
	tw(flash, forte and 0.5 or 0.3, { BackgroundTransparency = 1 })
	Debris:AddItem(flash, 0.6)
	if festa then
		som(SOM_BOOM, forte and 0.9 or 0.5, muitoForte and 0.8 or (forte and 1 or 1.25))
		if super then
			task.delay(0.25, som, SOM_BOOM, 1, 0.7)
		end
		tremer(super and 3 or (muitoForte and 2.4 or (forte and 1.4 or 0.6)), muitoForte and 0.8 or 0.4)
		onda(d.cor, forte and 900 or 600, 0.6, 10)
		onda(BRANCO, forte and 650 or 420, 0.45, 5)
		if forte then
			task.delay(0.15, onda, d.cor:Lerp(BRANCO, 0.3), 1100, 0.8, 6)
		end
		if super then
			task.delay(0.3, onda, Color3.fromRGB(255, 215, 80), 1400, 0.9, 8)
			task.delay(0.3, faiscas, Color3.fromRGB(255, 215, 80), 40, 600)
		end
		faiscas(d.cor, forte and 46 or 26, forte and 420 or 280)
		if forte then
			faiscas(d.cor, muitoForte and 30 or 16, 520, true)
		end
		raiosGirando(d.cor, super and 14 or (forte and 10 or 6), super and 820 or (forte and 640 or 460))
	end

	-- borda da tela brilhando (Lendário ou mais)
	if muitoForte then
		local borda = novo("Frame", gui, {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = 15,
		})
		local st = novo("UIStroke", borda, { Color = d.cor, Thickness = 26, Transparency = 0.2 })
		novo("UIGradient", st, {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, d.cor),
				ColorSequenceKeypoint.new(0.5, BRANCO),
				ColorSequenceKeypoint.new(1, d.cor),
			}),
		})
		TweenService:Create(
			st,
			TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 6, true),
			{ Transparency = 0.8 }
		):Play()
		Debris:AddItem(borda, 4.5)
	end

	-- 4) o item novo aparece grande
	local tam = forte and 210 or 180
	local c, esc = cartao(palco, tam, d.cor, d.item, d.riNovo, d.joiaCor)
	esc.Scale = 0
	tw(esc, 0.55, { Scale = 1 }, Enum.EasingStyle.Back)
	TweenService
		:Create(c, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Rotation = 4 })
		:Play()
	c.Rotation = -4
	local titulo = novo("TextLabel", palco, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = CENTRO + UDim2.fromOffset(0, -tam / 2 - 42),
		Size = UDim2.fromOffset(700, 60),
		BackgroundTransparency = 1,
		Text = d.titulo,
		TextColor3 = BRANCO,
		TextSize = forte and 54 or 44,
		Font = FONTE,
		ZIndex = 10,
	})
	novo("UIStroke", titulo, { Color = d.cor:Lerp(Color3.new(0, 0, 0), 0.75), Thickness = 4 })
	local corT = d.corTitulo or d.cor
	novo("UIGradient", titulo, {
		Rotation = 90,
		Color = ColorSequence.new(corT:Lerp(BRANCO, 0.65), corT),
	})
	if not festa then
		titulo.TextSize = 36
	end
	if super then
		local fita = novo("TextLabel", palco, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = CENTRO + UDim2.fromOffset(0, -tam / 2 - 96),
			Size = UDim2.fromOffset(420, 46),
			BackgroundColor3 = Color3.fromRGB(200, 40, 60),
			Text = "⚡ SUPER SÍNTESE! +2 ⚡",
			TextColor3 = Color3.fromRGB(255, 235, 120),
			TextSize = 30,
			Font = FONTE,
			Rotation = -3,
			ZIndex = 11,
		})
		canto(fita, 12)
		novo("UIStroke", fita, { Color = Color3.fromRGB(255, 215, 80), Thickness = 3 })
		local escF = novo("UIScale", fita, { Scale = 3 })
		tw(escF, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)
	end
	local escT = novo("UIScale", titulo, { Scale = festa and 2.4 or 1.3 })
	tw(escT, 0.4, { Scale = 1 }, Enum.EasingStyle.Back)
	local nome = novo("TextLabel", palco, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = CENTRO + UDim2.fromOffset(0, tam / 2 + 34),
		Size = UDim2.fromOffset(700, 34),
		BackgroundTransparency = 1,
		Text = d.nome,
		TextColor3 = d.cor:Lerp(BRANCO, 0.35),
		TextSize = 28,
		Font = FONTE,
		TextTransparency = 1,
		ZIndex = 10,
	})
	novo("UIStroke", nome, { Color = Color3.fromRGB(20, 10, 24), Thickness = 3 })
	tw(nome, 0.4, { TextTransparency = 0 })
	if d.riVelho and d.riNovo and d.riNovo ~= d.riVelho and not d.joiaCor then
		local tier = novo("TextLabel", palco, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = CENTRO + UDim2.fromOffset(0, tam / 2 + 74),
			Size = UDim2.fromOffset(400, 40),
			BackgroundTransparency = 1,
			Text = "TIER " .. d.riVelho,
			TextColor3 = BRANCO,
			TextSize = 34,
			Font = FONTE,
			ZIndex = 10,
		})
		novo("UIStroke", tier, { Color = Color3.fromRGB(20, 10, 24), Thickness = 3 })
		local escTier = novo("UIScale", tier)
		task.spawn(function()
			local passo = d.riNovo > d.riVelho and 1 or -1
			for v = d.riVelho + passo, d.riNovo, passo do
				task.wait(0.28)
				if not tier.Parent then
					return
				end
				tier.Text = "TIER " .. v .. (passo > 0 and " ▲" or " ▼")
				tier.TextColor3 = passo > 0 and d.cor:Lerp(BRANCO, 0.3) or Color3.fromRGB(230, 80, 80)
				escTier.Scale = 1.6
				tw(escTier, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
				som(SOM_TIQUE, 0.7, passo > 0 and (1 + v * 0.12) or 0.6)
			end
		end)
	end
	if d.vezes and d.vezes > 1 then
		local vezes = novo("TextLabel", palco, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = CENTRO + UDim2.fromOffset(tam / 2 + 10, -tam / 2 + 10),
			Size = UDim2.fromOffset(90, 44),
			BackgroundColor3 = Color3.fromRGB(200, 40, 60),
			Text = "x" .. d.vezes,
			TextColor3 = BRANCO,
			TextSize = 28,
			Font = FONTE,
			Rotation = 12,
			ZIndex = 11,
		})
		canto(vezes, 14)
		novo("UIStroke", vezes, { Color = BRANCO, Thickness = 2.5 })
		local escV = novo("UIScale", vezes, { Scale = 0 })
		task.delay(0.35, function()
			tw(escV, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
		end)
	end
	local dica = novo("TextLabel", gui, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -24),
		Size = UDim2.fromOffset(400, 24),
		BackgroundTransparency = 1,
		Text = "toque para continuar",
		TextColor3 = Color3.fromRGB(220, 210, 240),
		TextSize = 16,
		Font = FONTE,
		TextTransparency = 0.3,
		ZIndex = 12,
	})
	-- confete de estrelas caindo nos raros de verdade
	if forte then
		task.spawn(function()
			for _ = 1, super and 14 or (muitoForte and 8 or 4) do
				if pular then
					break
				end
				faiscas(d.cor, 6, 380, true)
				task.wait(0.25)
			end
		end)
	end
	pular = false
	esperar(forte and 2.6 or 1.8)

	-- 5) some
	tw(fundo, 0.3, { BackgroundTransparency = 1 })
	for _, o in ipairs(palco:GetDescendants()) do
		if o:IsA("TextLabel") then
			tw(o, 0.25, { TextTransparency = 1 })
		elseif o:IsA("UIScale") then
			tw(o, 0.25, { Scale = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		end
	end
	tw(dica, 0.2, { TextTransparency = 1 })
	task.wait(0.3)
	dica:Destroy()
	for _, filho in ipairs(palco:GetChildren()) do
		filho:Destroy()
	end
	gui.Enabled = false
	tocando = false
end

------------------------------------------------------------------------
-- Síntese automática: só um efeito pequeno no topo (pode vir várias seguidas)
------------------------------------------------------------------------
local guiMini = novo("ScreenGui", playerGui, {
	Name = "SinteseMini",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 35,
})
local function miniSintese(l)
	local cor = corDe(l.r)
	local super = l.salto >= 2
	local quebrou = l.salto < 0
	local caixa = novo("Frame", guiMini, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, -90),
		Size = UDim2.fromOffset(360, 74),
		BackgroundColor3 = Color3.fromRGB(26, 18, 34),
		BackgroundTransparency = 0.05,
	})
	canto(caixa, 16)
	local st = novo("UIStroke", caixa, { Color = super and Color3.fromRGB(255, 215, 80) or cor, Thickness = 3 })
	novo("UIGradient", st, {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, cor),
			ColorSequenceKeypoint.new(0.5, BRANCO),
			ColorSequenceKeypoint.new(1, cor),
		}),
	})
	local ic = cartao(caixa, 58, cor, l.item, l.ri)
	ic.Position = UDim2.fromOffset(40, 37)
	local txt = "⚒ Síntese: " .. l.r.nome
	if super then
		txt = "⚡ SUPER SÍNTESE! " .. l.r.nome
	elseif quebrou then
		txt = "💔 Caiu para " .. l.r.nome
	elseif l.salto == 0 then
		txt = "⚒ Mesma raridade: " .. l.r.nome
	end
	if l.vezes > 1 then
		txt ..= "  x" .. l.vezes
	end
	local t = novo("TextLabel", caixa, {
		Position = UDim2.fromOffset(78, 8),
		Size = UDim2.new(1, -86, 0, 30),
		BackgroundTransparency = 1,
		Text = txt,
		TextColor3 = quebrou and Color3.fromRGB(255, 110, 110) or cor:Lerp(BRANCO, 0.3),
		TextSize = 19,
		Font = FONTE,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextScaled = true,
	})
	novo("UITextSizeConstraint", t, { MaxTextSize = 20 })
	novo("UIStroke", t, { Color = Color3.fromRGB(14, 8, 18), Thickness = 2 })
	novo("TextLabel", caixa, {
		Position = UDim2.fromOffset(78, 40),
		Size = UDim2.new(1, -86, 0, 22),
		BackgroundTransparency = 1,
		Text = l.item and l.item.nome or "",
		TextColor3 = Color3.fromRGB(220, 210, 235),
		TextSize = 15,
		Font = FONTE,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	tw(caixa, 0.35, { Position = UDim2.new(0.5, 0, 0, 96) }, Enum.EasingStyle.Back)
	-- faíscas saindo da caixa
	task.delay(0.3, function()
		for _ = 1, super and 22 or 10 do
			local ang = math.random() * math.pi * 2
			local f = novo("Frame", caixa, {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset(40, 37),
				Size = UDim2.fromOffset(8, 3),
				Rotation = math.deg(ang),
				BackgroundColor3 = math.random() < 0.3 and BRANCO or cor,
				ZIndex = 9,
			})
			local d = 50 + math.random() * (super and 90 or 50)
			tw(f, 0.5, {
				Position = UDim2.fromOffset(40 + math.cos(ang) * d, 37 + math.sin(ang) * d),
				BackgroundTransparency = 1,
			})
			Debris:AddItem(f, 0.55)
		end
	end)
	if super then
		som(SOM_BOOM, 0.4, 1.3)
	else
		som(SOM_TIQUE, 0.4, quebrou and 0.6 or 1.4)
	end
	task.delay(super and 2.6 or 1.8, function()
		tw(caixa, 0.3, { Position = UDim2.new(0.5, 0, 0, -90) }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		Debris:AddItem(caixa, 0.35)
	end)
end

------------------------------------------------------------------------
-- Fila: cerimônias uma depois da outra
------------------------------------------------------------------------
local fila = {}

local function rodarFila()
	if tocando then
		return
	end
	task.spawn(function()
		while #fila > 0 do
			local d = table.remove(fila, 1)
			local ok, erro = pcall(cerimonia, d)
			if not ok then
				warn("[SinteseFX] " .. tostring(erro))
				gui.Enabled = false
				tocando = false
			end
		end
	end)
end

local function entrarNaFila(d)
	if #fila >= 3 then
		return -- não deixa acumular demais
	end
	table.insert(fila, d)
	rodarFila()
end

local function titulos(r, salto)
	local nomeR = string.upper(r.nome)
	if salto >= 2 then
		return "✦ " .. nomeR .. "! ✦"
	elseif salto == 0 then
		return "Mesma raridade... " .. r.nome
	elseif salto < 0 then
		return "💔 Ops! Caiu para " .. r.nome
	end
	return "✦ " .. nomeR .. "! ✦"
end

-- O item chega pelo Loot "forja"; a sorte (salto) chega logo depois no aviso "sintese".
local ultimoItem = nil -- { item, quando, avisado }
local loteAuto = nil

local function cerimoniaDoItem(item, r, ri, salto)
	local riVelho = math.clamp(ri - salto, 1, #Config.Raridades)
	entrarNaFila({
		cor = corDe(r),
		corVelha = corDe(Config.Raridades[riVelho]),
		corTitulo = salto < 0 and Color3.fromRGB(255, 80, 80) or (salto == 0 and Color3.fromRGB(170, 165, 180)),
		item = item,
		riNovo = ri,
		riVelho = riVelho,
		salto = salto,
		titulo = titulos(r, salto),
		nome = item and item.nome or "",
	})
end

evLoot.OnClientEvent:Connect(function(tipo, _pos, item)
	if tipo ~= "forja" or type(item) ~= "table" then
		return
	end
	local registro = { item = item, quando = os.clock(), avisado = false }
	ultimoItem = registro
	-- servidor antigo (sem o aviso "sintese"): faz a cerimônia normal sozinho
	task.delay(0.6, function()
		if not registro.avisado then
			local r, ri = raridade(item.raridade)
			cerimoniaDoItem(item, r, ri, 1)
		end
	end)
end)

evAviso.OnClientEvent:Connect(function(tipo, a, b, c, d)
	if tipo == "sintese" then
		local nomeItem, rarId, salto, automatico = a, b, tonumber(c) or 1, d == true
		local item = nil
		if ultimoItem and os.clock() - ultimoItem.quando < 1 then
			ultimoItem.avisado = true
			if ultimoItem.item.nome == nomeItem then
				item = ultimoItem.item
			end
		end
		local r, ri = raridade(rarId)
		if automatico then
			-- junta as automáticas seguidas num aviso pequeno só
			if not loteAuto then
				loteAuto = { item = item, r = r, ri = ri, salto = salto, vezes = 0 }
				task.delay(0.5, function()
					local l = loteAuto
					loteAuto = nil
					miniSintese(l)
				end)
			end
			loteAuto.vezes += 1
			if salto > loteAuto.salto or (salto == loteAuto.salto and ri > loteAuto.ri) then
				loteAuto.item, loteAuto.r, loteAuto.ri, loteAuto.salto = item, r, ri, salto
			end
		else
			cerimoniaDoItem(item or { nome = nomeItem, raridade = rarId }, r, ri, salto)
		end
		return
	end
	if tipo ~= "joiaFundida" then
		return
	end
	local nome, cor = a, b
	cor = typeof(cor) == "Color3" and cor or Color3.fromRGB(120, 200, 255)
	-- nível da joia pelo nome (Lascada, Polida, ...): quanto maior, mais forte
	local nivel = 2
	for i, n in ipairs(Config.Joias and Config.Joias.Niveis or {}) do
		if string.find(tostring(nome), n, 1, true) then
			nivel = i
		end
	end
	entrarNaFila({
		cor = cor,
		corVelha = cor:Lerp(Color3.fromRGB(80, 80, 90), 0.4),
		joiaCor = cor,
		riNovo = nivel + 1, -- joia de nível alto ganha a cerimônia forte
		riVelho = nivel,
		titulo = "💎 FUSÃO! 💎",
		nome = tostring(nome),
	})
end)

-- Esc também pula
UserInputService.InputBegan:Connect(function(input)
	if gui.Enabled and input.KeyCode == Enum.KeyCode.Escape then
		pular = true
	end
end)
