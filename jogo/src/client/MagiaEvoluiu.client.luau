-- MagiaEvoluiu: quando o herói aprende ou sobe uma magia na árvore, aparece no alto
-- da tela um cartão com o selo (kanji) da magia, o nome e o nível novo.
-- Só visual: lê estado.habilidades que o servidor já manda no evento "Estado".

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local E = require(Shared:WaitForChild("EstiloUI"))
local Dados = require(Shared:WaitForChild("Habilidades"))
local evEstado = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Estado")

local player = Players.LocalPlayer
local gui = E.novo("ScreenGui", player:WaitForChild("PlayerGui"), {
	Name = "MagiaEvoluiu",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 15,
})

local fila = {}
local mostrando = false

local function corDe(h)
	local el = Dados.Elementos[h.ramo]
	return el and el.cor or E.cor.ouro
end

local function mostrar(h, nivel)
	local cor = corDe(h)
	local suprema = h.tipo == "suprema"
	local cartao = E.painel(gui, {
		Name = "Cartao",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, -140),
		Size = UDim2.fromOffset(360, 96),
		ZIndex = 2,
	})
	E.novo("UIScale", cartao, {
		Scale = math.clamp(
			(workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y or 720) / 720,
			0.72,
			1.3
		),
	})
	-- faixa na cor do elemento à esquerda
	local faixa = E.novo("Frame", cartao, {
		Size = UDim2.new(0, 8, 1, -12),
		Position = UDim2.fromOffset(6, 6),
		BackgroundColor3 = cor,
		BorderSizePixel = 0,
		ZIndex = 3,
	})
	E.canto(faixa, 4)
	-- selo da magia: quadrado na cor do elemento com o kanji
	local selo = E.novo("Frame", cartao, {
		Position = UDim2.fromOffset(22, 10),
		Size = UDim2.fromOffset(76, 76),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 3,
	})
	E.canto(selo, 14)
	E.traco(selo, suprema and E.cor.ouro or E.cor.tinta, 3)
	E.novo("UIGradient", selo, {
		Rotation = 50,
		Color = ColorSequence.new(cor:Lerp(Color3.new(1, 1, 1), 0.4), cor:Lerp(Color3.new(0, 0, 0), 0.45)),
	})
	local kanji = E.novo("TextLabel", selo, {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 4,
	})
	E.kanjiMagia(kanji, h)
	-- textos
	E.texto(cartao, {
		Position = UDim2.fromOffset(110, 10),
		Size = UDim2.new(1, -120, 0, 16),
		-- o visual da magia muda de estágio no Nv 3 e no Nv 5 (efeitos do Henrique)
		Text = nivel <= 1 and "NOVA MAGIA!"
			or (nivel == 3 and "EVOLUIU: ESTÁGIO 2!")
			or (nivel == 5 and "EVOLUIU: ESTÁGIO 3!")
			or "MAGIA SUBIU!",
		TextSize = 13,
		TextColor3 = E.cor.ouro,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
	})
	local nome = E.titulo(cartao, {
		Position = UDim2.fromOffset(110, 26),
		Size = UDim2.new(1, -120, 0, 28),
		Text = h.nome,
		TextScaled = true,
		TextColor3 = E.cor.papel,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
	})
	E.limiteTexto(nome, 24, 12)
	-- pontinhos de nível (cheios até o nível atual; o novo acende por último)
	local pontos = E.novo("Frame", cartao, {
		Position = UDim2.fromOffset(110, 60),
		Size = UDim2.new(1, -120, 0, 22),
		BackgroundTransparency = 1,
		ZIndex = 3,
	})
	E.novo("UIListLayout", pontos, {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 4),
	})
	local max = math.max(1, h.max or 10)
	local ultimo
	for i = 1, max do
		local p = E.novo("Frame", pontos, {
			LayoutOrder = i,
			Size = UDim2.fromOffset(11, 11),
			Rotation = 45,
			BackgroundColor3 = i <= nivel - 1 and cor or E.cor.painelFundo,
			BorderSizePixel = 0,
			ZIndex = 4,
		})
		E.traco(p, E.cor.tinta, 1.5)
		if i == nivel then
			ultimo = p
		end
	end
	E.texto(pontos, {
		LayoutOrder = max + 1,
		Size = UDim2.fromOffset(60, 22),
		Text = "Nv " .. nivel,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 4,
	})

	-- entra descendo com quique, acende o ponto novo, espera e sobe
	TweenService:Create(cartao, E.tw.pop, { Position = UDim2.new(0.5, 0, 0, 70) }):Play()
	task.wait(0.35)
	if ultimo then
		ultimo.BackgroundColor3 = Color3.new(1, 1, 1)
		local esc = E.novo("UIScale", ultimo, { Scale = 1.8 })
		TweenService:Create(esc, E.tw.pop, { Scale = 1 }):Play()
		TweenService:Create(ultimo, E.tw.suave, { BackgroundColor3 = cor }):Play()
	end
	local estagio = nivel == 3 or nivel == 5
	if estagio then
		-- mudou de estágio: clarão na cor do elemento atrás do selo
		local clarao = E.novo("Frame", cartao, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(60, 48),
			Size = UDim2.fromOffset(76, 76),
			BackgroundColor3 = cor:Lerp(Color3.new(1, 1, 1), 0.5),
			BackgroundTransparency = 0.2,
			ZIndex = 2,
		})
		E.canto(clarao, 999)
		TweenService:Create(clarao, E.tw.suave, {
			Size = UDim2.fromOffset(170, 170),
			BackgroundTransparency = 1,
		}):Play()
		game:GetService("Debris"):AddItem(clarao, 0.4)
	end
	local selEsc = E.novo("UIScale", selo, { Scale = estagio and 1.5 or 1.25 })
	TweenService:Create(selEsc, E.tw.pop, { Scale = 1 }):Play()
	task.wait(1.9)
	local sai = TweenService:Create(cartao, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, 0, 0, -140),
	})
	sai:Play()
	sai.Completed:Wait()
	cartao:Destroy()
end

local function proximo()
	if mostrando then
		return
	end
	mostrando = true
	task.spawn(function()
		while #fila > 0 do
			local item = table.remove(fila, 1)
			local ok, erro = pcall(mostrar, item[1], item[2])
			if not ok then
				warn("[MagiaEvoluiu] " .. tostring(erro))
			end
		end
		mostrando = false
	end)
end

local antes = nil -- níveis das magias na última atualização (nil = primeira vez, não avisa)
evEstado.OnClientEvent:Connect(function(estado)
	local agora = (estado and estado.habilidades) or {}
	if antes then
		for id, nv in pairs(agora) do
			local h = Dados.PorId[id]
			if h and type(nv) == "number" and nv > (antes[id] or 0) then
				-- no máximo 3 na fila (resetar e redistribuir pontos não vira enxurrada)
				if #fila < 3 then
					table.insert(fila, { h, nv })
				end
			end
		end
		proximo()
	end
	antes = table.clone(agora)
end)
