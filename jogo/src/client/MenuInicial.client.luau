-- MenuInicial: tela de entrada do jogo. O jogador escolhe a classe
-- (Guerreiro, Caçador ou Mago) antes de começar a lutar.
-- Estilo: madeira escura e dourado (como a HUD), cartões grandes com a arma girando.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local ItemArte = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ItemArte"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local evEstado = remotes:WaitForChild("Estado")
local evPedirEstado = remotes:WaitForChild("PedirEstado")
local evClasse = remotes:WaitForChild("Classe")

local player = Players.LocalPlayer

local FONTE = Enum.Font.FredokaOne
local FONTE_TEXTO = Enum.Font.GothamMedium
local OURO = Color3.fromRGB(255, 205, 80)
local OURO_ESCURO = Color3.fromRGB(150, 95, 30)
local MADEIRA = Color3.fromRGB(46, 30, 22)
local TEXTO = Color3.fromRGB(255, 246, 228)
local FRACO = Color3.fromRGB(200, 178, 145)

local POP = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local RAPIDO = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function novo(classe, pai, props)
	local o = Instance.new(classe)
	for k, v in pairs(props or {}) do
		o[k] = v
	end
	o.Parent = pai
	return o
end
local function canto(o, r)
	return novo("UICorner", o, { CornerRadius = UDim.new(0, r or 12) })
end
local function contorno(o, cor, esp)
	return novo("UIStroke", o, {
		Color = cor,
		Thickness = esp or 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end
-- string.upper não conhece acentos (ç, ã...)
local function maiusculo(s)
	s = string.upper(s)
	for de, para in pairs({
		["ç"] = "Ç",
		["ã"] = "Ã",
		["á"] = "Á",
		["é"] = "É",
		["í"] = "Í",
		["ó"] = "Ó",
		["ú"] = "Ú",
	}) do
		s = string.gsub(s, de, para)
	end
	return s
end

local function texto(pai, props)
	local t = novo("TextLabel", pai, {
		BackgroundTransparency = 1,
		Font = FONTE,
		TextColor3 = TEXTO,
		TextScaled = true,
	})
	for k, v in pairs(props) do
		t[k] = v
	end
	novo("UITextSizeConstraint", t, { MaxTextSize = props.TextSize or 24, MinTextSize = 8 })
	return t
end

-- Já tem classe? Então não precisa do menu.
local escolhida = false
local gui -- criado só se precisar
local desfoque

local function fecharMenu(comEfeito)
	if not gui then
		return
	end
	local g = gui
	gui = nil
	if comEfeito then
		-- clarão branco e a tela some
		local flash = novo("Frame", g, {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0,
			ZIndex = 50,
		})
		TweenService:Create(flash, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
		local tudo = g:FindFirstChild("Tudo")
		if tudo then
			TweenService:Create(tudo, TweenInfo.new(0.45), { GroupTransparency = 1 }):Play()
		end
		if desfoque then
			TweenService:Create(desfoque, TweenInfo.new(0.6), { Size = 0 }):Play()
		end
		task.delay(0.65, function()
			g:Destroy()
			if desfoque then
				desfoque:Destroy()
			end
		end)
	else
		g:Destroy()
		if desfoque then
			desfoque:Destroy()
		end
	end
end

local function criarMenu()
	gui = novo("ScreenGui", player:WaitForChild("PlayerGui"), {
		Name = "MenuInicial",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 50,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	desfoque = novo("BlurEffect", Lighting, { Name = "DesfoqueMenu", Size = 0 })
	TweenService:Create(desfoque, TweenInfo.new(0.6), { Size = 18 }):Play()

	local tudo = novo("CanvasGroup", gui, {
		Name = "Tudo",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		GroupTransparency = 1,
	})
	-- fundo separado: um degradê direto no CanvasGroup tingiria tudo que está dentro
	local fundo = novo("Frame", tudo, {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.3,
	})
	novo("UIGradient", fundo, {
		Rotation = 90,
		Color = ColorSequence.new(Color3.fromRGB(70, 40, 110), Color3.fromRGB(10, 6, 14)),
	})
	TweenService:Create(tudo, TweenInfo.new(0.5), { GroupTransparency = 0 }):Play()

	-- pétalas de cerejeira caindo
	local petalas = novo("Frame", tudo, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 })
	task.spawn(function()
		while petalas.Parent do
			local p = novo("Frame", petalas, {
				Size = UDim2.fromOffset(math.random(6, 11), math.random(5, 8)),
				Position = UDim2.fromScale(math.random(), -0.05),
				BackgroundColor3 = Color3.fromRGB(255, math.random(150, 200), math.random(200, 230)),
				BackgroundTransparency = 0.15,
				Rotation = math.random(0, 360),
			})
			canto(p, 5)
			local tempo = 5 + math.random() * 4
			TweenService:Create(p, TweenInfo.new(tempo, Enum.EasingStyle.Linear), {
				Position = UDim2.fromScale(p.Position.X.Scale + (math.random() - 0.3) * 0.3, 1.05),
				Rotation = p.Rotation + math.random(-300, 300),
			}):Play()
			task.delay(tempo, function()
				p:Destroy()
			end)
			task.wait(0.18)
		end
	end)

	-- título
	local titulo = texto(tudo, {
		Name = "Titulo",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.04),
		Size = UDim2.fromScale(0.7, 0.09),
		Text = "ESCOLHA SUA CLASSE",
		TextSize = 56,
		TextColor3 = Color3.new(1, 1, 1),
	})
	novo("UIGradient", titulo, {
		Rotation = 90,
		Color = ColorSequence.new(Color3.fromRGB(255, 240, 160), OURO_ESCURO),
	})
	novo("UIStroke", titulo, { Color = Color3.fromRGB(40, 20, 10), Thickness = 3 })
	texto(tudo, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.13),
		Size = UDim2.fromScale(0.7, 0.035),
		Text = "Normal · Ato 1 · Vila Oculta do Bambu — a classe define suas armas e armaduras",
		Font = FONTE_TEXTO,
		TextSize = 18,
		TextColor3 = FRACO,
	})

	-- cartões das classes
	local linha = novo("Frame", tudo, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.19),
		Size = UDim2.fromScale(0.94, 0.66),
		BackgroundTransparency = 1,
	})
	novo("UIListLayout", linha, {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0.02, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local selecionada
	local cartoes = {}
	local btnComecar

	local function atualizarSelecao()
		for id, c in pairs(cartoes) do
			local sel = id == selecionada
			TweenService:Create(c.escala, POP, { Scale = sel and 1.06 or (selecionada and 0.94 or 1) }):Play()
			TweenService:Create(c.borda, RAPIDO, {
				Color = sel and Color3.new(1, 1, 1) or OURO,
				Thickness = sel and 5 or 3,
			}):Play()
			c.sombra.Visible = selecionada ~= nil and not sel
			c.selo.Visible = sel
		end
		if btnComecar then
			btnComecar.Active = selecionada ~= nil
			btnComecar.AutoButtonColor = selecionada ~= nil
			local c = selecionada and Config.ClassePorId(selecionada)
			btnComecar.Text = c and ("COMEÇAR COMO " .. maiusculo(c.nome)) or "ESCOLHA UMA CLASSE"
			TweenService:Create(btnComecar, RAPIDO, {
				BackgroundColor3 = c and Color3.fromRGB(70, 175, 70) or Color3.fromRGB(80, 70, 60),
			}):Play()
		end
	end

	for ordem, classe in ipairs(Config.Classes) do
		local b = novo("TextButton", linha, {
			Name = "Classe_" .. classe.id,
			LayoutOrder = ordem,
			Size = UDim2.fromScale(0.29, 1),
			BackgroundColor3 = Color3.new(1, 1, 1),
			AutoButtonColor = false,
			Text = "",
		})
		novo("UIAspectRatioConstraint", b, { AspectRatio = 0.66, DominantAxis = Enum.DominantAxis.Height })
		canto(b, 16)
		local escala = novo("UIScale", b, { Scale = 0.6 })
		novo("UIGradient", b, {
			Rotation = 90,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, classe.cor:Lerp(Color3.new(1, 1, 1), 0.15)),
				ColorSequenceKeypoint.new(0.45, classe.cor:Lerp(Color3.new(0, 0, 0), 0.45)),
				ColorSequenceKeypoint.new(1, MADEIRA),
			}),
		})
		local borda = contorno(b, OURO, 3)

		-- faixa com o nome da classe
		local faixa = novo("Frame", b, {
			Position = UDim2.fromScale(0.06, 0.03),
			Size = UDim2.fromScale(0.88, 0.1),
			BackgroundColor3 = Color3.fromRGB(170, 40, 35),
			ZIndex = 3,
		})
		canto(faixa, 8)
		contorno(faixa, OURO, 2)
		texto(faixa, {
			Size = UDim2.fromScale(1, 1),
			Text = maiusculo(classe.nome),
			TextSize = 30,
			ZIndex = 4,
		})

		-- arma da classe girando
		local vp = novo("ViewportFrame", b, {
			Position = UDim2.fromScale(0.08, 0.14),
			Size = UDim2.fromScale(0.84, 0.36),
			BackgroundTransparency = 1,
			ZIndex = 2,
		})
		local brilho = novo("Frame", b, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.32),
			Size = UDim2.fromScale(0.8, 0.36),
			BackgroundColor3 = classe.cor:Lerp(Color3.new(1, 1, 1), 0.6),
			BackgroundTransparency = 1,
			ZIndex = 1,
		})
		canto(brilho, 200)
		local modeloArma
		local ok = pcall(function()
			modeloArma = ItemArte.mostrar(vp, "arma", 5, classe.cor, nil, classe.id)
		end)
		if ok and modeloArma then
			local cam = vp.CurrentCamera
			local centro = modeloArma:GetBoundingBox().Position
			local dist = cam and (cam.CFrame.Position - centro).Magnitude or 6
			local inicio = os.clock() + ordem
			local giro
			giro = RunService.RenderStepped:Connect(function()
				if not vp.Parent or not cam then
					giro:Disconnect()
					return
				end
				local ang = (os.clock() - inicio) * 0.9
				local dir = Vector3.new(math.sin(ang), 0.25, math.cos(ang)).Unit
				cam.CFrame = CFrame.lookAt(centro + dir * dist, centro)
			end)
		end

		texto(b, {
			Position = UDim2.fromScale(0.06, 0.5),
			Size = UDim2.fromScale(0.88, 0.05),
			Text = classe.estilo,
			TextSize = 20,
			TextColor3 = OURO,
			ZIndex = 3,
		})

		-- estrelas dos atributos
		local atributos = {
			{ "Vida", classe.notas.vida },
			{ "Dano", classe.notas.dano },
			{ "Alcance", classe.notas.alcance },
			{ "Velocidade", classe.notas.velocidade },
		}
		for i, at in ipairs(atributos) do
			local y = 0.56 + (i - 1) * 0.052
			texto(b, {
				Position = UDim2.fromScale(0.08, y),
				Size = UDim2.fromScale(0.42, 0.042),
				Text = at[1],
				TextSize = 16,
				Font = FONTE_TEXTO,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 3,
			})
			for k = 1, 5 do
				local pip = novo("Frame", b, {
					Position = UDim2.fromScale(0.5 + (k - 1) * 0.085, y + 0.008),
					Size = UDim2.fromScale(0.07, 0.026),
					BackgroundColor3 = k <= at[2] and classe.cor:Lerp(Color3.new(1, 1, 1), 0.25)
						or Color3.fromRGB(40, 32, 28),
					ZIndex = 3,
				})
				canto(pip, 4)
				contorno(pip, k <= at[2] and OURO or Color3.fromRGB(90, 70, 50), 1)
			end
		end

		texto(b, {
			Position = UDim2.fromScale(0.07, 0.775),
			Size = UDim2.fromScale(0.86, 0.11),
			Text = classe.descricao,
			TextSize = 15,
			Font = FONTE_TEXTO,
			TextColor3 = TEXTO,
			TextWrapped = true,
			ZIndex = 3,
		})
		local nomes = Config.NomesClasse[classe.id]
		texto(b, {
			Position = UDim2.fromScale(0.07, 0.89),
			Size = UDim2.fromScale(0.86, 0.08),
			Text = "Itens: " .. nomes.arma[1] .. " → " .. nomes.arma[8],
			TextSize = 13,
			Font = FONTE_TEXTO,
			TextColor3 = FRACO,
			TextWrapped = true,
			ZIndex = 3,
		})

		-- escurece quem não foi escolhido; selo "ESCOLHIDO" em quem foi
		local sombra = novo("Frame", b, {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.45,
			Visible = false,
			ZIndex = 10,
		})
		canto(sombra, 16)
		local selo = texto(b, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 1),
			Size = UDim2.fromScale(0.6, 0.07),
			BackgroundTransparency = 0,
			BackgroundColor3 = Color3.fromRGB(70, 175, 70),
			Text = "ESCOLHIDO",
			TextSize = 18,
			Visible = false,
			ZIndex = 11,
		})
		canto(selo, 10)
		contorno(selo, Color3.new(1, 1, 1), 2)

		b.MouseEnter:Connect(function()
			if selecionada ~= classe.id then
				TweenService:Create(escala, RAPIDO, { Scale = 1.03 }):Play()
				TweenService:Create(brilho, RAPIDO, { BackgroundTransparency = 0.75 }):Play()
			end
		end)
		b.MouseLeave:Connect(function()
			if selecionada ~= classe.id then
				TweenService:Create(escala, RAPIDO, { Scale = selecionada and 0.94 or 1 }):Play()
			end
			TweenService:Create(brilho, RAPIDO, { BackgroundTransparency = 1 }):Play()
		end)
		b.Activated:Connect(function()
			selecionada = classe.id
			atualizarSelecao()
		end)

		cartoes[classe.id] = { escala = escala, borda = borda, sombra = sombra, selo = selo }
		-- entrada com pulinho, um cartão depois do outro
		task.delay(0.15 * ordem, function()
			TweenService:Create(escala, POP, { Scale = 1 }):Play()
		end)
	end

	btnComecar = novo("TextButton", tudo, {
		Name = "Comecar",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.875),
		Size = UDim2.fromScale(0.32, 0.08),
		BackgroundColor3 = Color3.fromRGB(80, 70, 60),
		Font = FONTE,
		TextScaled = true,
		TextColor3 = Color3.new(1, 1, 1),
		Text = "ESCOLHA UMA CLASSE",
		AutoButtonColor = false,
	})
	novo("UITextSizeConstraint", btnComecar, { MaxTextSize = 30 })
	novo("UIPadding", btnComecar, {
		PaddingTop = UDim.new(0.18, 0),
		PaddingBottom = UDim.new(0.18, 0),
	})
	canto(btnComecar, 14)
	contorno(btnComecar, OURO, 3)
	novo("UIGradient", btnComecar, {
		Rotation = 90,
		Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(170, 170, 170)),
	})
	btnComecar.Activated:Connect(function()
		if not selecionada or escolhida then
			return
		end
		escolhida = true
		evClasse:FireServer(selecionada)
		fecharMenu(true)
	end)
	atualizarSelecao()
end

evEstado.OnClientEvent:Connect(function(estado)
	if estado.classe then
		escolhida = true
		fecharMenu(false)
	elseif not escolhida and not gui then
		criarMenu()
	end
end)
evPedirEstado:FireServer()
