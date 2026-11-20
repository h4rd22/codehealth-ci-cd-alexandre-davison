--!strict
-- Coração do Mistureba no servidor: bases, chuva de ovos, carregar,
-- roubar, tapa, cadeado, fusão, loja de moedas e renda.
-- O servidor decide tudo; a tela só pede e mostra.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Util = require(ReplicatedStorage.Shared.Util)
local Dados = require(script.Parent.Dados)
local Mapa = require(script.Parent.Mapa)
local Criaturas = require(script.Parent.Criaturas)
local Loja = require(script.Parent.Loja)

local rng = Random.new()

------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------
local pastaRemotes = Instance.new("Folder")
pastaRemotes.Name = "Remotes"
pastaRemotes.Parent = ReplicatedStorage

local function remote(nome: string): RemoteEvent
	local r = Instance.new("RemoteEvent")
	r.Name = nome
	r.Parent = pastaRemotes
	return r
end

-- tela -> servidor
local evComprarOvo = remote("ComprarOvo")
local evFundir = remote("Fundir")
local evVender = remote("Vender")
local evMelhorar = remote("MelhorarBase")
local evTrancar = remote("Trancar")
local evTapa = remote("Tapa")
local evSoltar = remote("Soltar")
-- servidor -> tela
local evEstado = remote("Estado")
local evAviso = remote("Aviso")
local evAnuncio = remote("Anuncio")
local evChocou = remote("Chocou")
local evEmpurrao = remote("Empurrao")

------------------------------------------------------------------------
-- Estado de cada jogador enquanto está no servidor
------------------------------------------------------------------------
type Roubo = { dono: Player, vaga: string, id: string }
type Estado = {
	base: Mapa.Base,
	ovos: { string }, -- raridades dos ovos carregados
	roubo: Roubo?,
	cadeadoAte: number,
	cadeadoLivreEm: number,
	entrouEm: number,
	ultimoTapa: number,
	ultimoPedido: { [string]: number },
	modelos: { [string]: Model }, -- vaga -> modelo na base
	visual: Instance?, -- o que aparece em cima da cabeça
	sujo: boolean, -- precisa mandar o estado para a tela
}

local estados: { [Player]: Estado } = {}
local donoDaBase: { [number]: Player } = {}
local sorteAte = 0

local bases = Mapa.construir()

local pastaOvos = Instance.new("Folder")
pastaOvos.Name = "Ovos"
pastaOvos.Parent = workspace

local function agora(): number
	return workspace:GetServerTimeNow()
end

local function aviso(jogador: Player, texto: string, cor: Color3?)
	evAviso:FireClient(jogador, texto, cor or Color3.fromRGB(255, 255, 255))
end

-- Limita pedidos repetidos da tela (anti-spam)
local function liberado(estado: Estado, acao: string, espera: number): boolean
	local ultimo = estado.ultimoPedido[acao] or 0
	if os.clock() - ultimo < espera then
		return false
	end
	estado.ultimoPedido[acao] = os.clock()
	return true
end

local function raiz(jogador: Player): BasePart?
	local personagem = jogador.Character
	return personagem and personagem:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function humanoide(jogador: Player): Humanoid?
	local personagem = jogador.Character
	return personagem and personagem:FindFirstChildOfClass("Humanoid")
end

------------------------------------------------------------------------
-- Vagas e renda
------------------------------------------------------------------------
local function totalVagas(jogador: Player, perfil: Dados.Perfil): number
	local vagas = Config.Base.vagasIniciais + perfil.melhorias * Config.Base.vagasPorMelhoria
	if Loja.tem(jogador, "basegrande") then
		vagas += Config.BaseGrandeVagas
	end
	return math.min(vagas, Mapa.MAX_VAGAS)
end

local function vagaLivre(jogador: Player, perfil: Dados.Perfil): string?
	for i = 1, totalVagas(jogador, perfil) do
		if perfil.criaturas[tostring(i)] == nil then
			return tostring(i)
		end
	end
	return nil
end

local function contarCriaturas(perfil: Dados.Perfil): number
	local n = 0
	for _ in perfil.criaturas do
		n += 1
	end
	return n
end

local function rendaPorSegundo(jogador: Player, perfil: Dados.Perfil): number
	local total = 0
	for vaga, id in perfil.criaturas do
		-- quem está sendo roubada não rende
		local sendoRoubada = false
		for _, outro in estados do
			local r = outro.roubo
			if r and r.dono == jogador and r.vaga == vaga then
				sendoRoubada = true
			end
		end
		if not sendoRoubada then
			total += Config.PorId[id].renda
		end
	end
	if Loja.tem(jogador, "vip") then
		total *= Config.VipMultiplicador
	end
	return total
end

------------------------------------------------------------------------
-- Modelos das Misturebas na base
------------------------------------------------------------------------
local function prenderRoubar(modelo: Model, dono: Player, vaga: string)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Roubar"
	prompt.ActionText = "Roubar"
	prompt.ObjectText = modelo.Name
	prompt.HoldDuration = Config.Jogador.tempoParaRoubar
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt:SetAttribute("Dono", dono.UserId)
	prompt:SetAttribute("Vaga", vaga)
	prompt.Parent = modelo.PrimaryPart
end

local function posicionar(modelo: Model, cf: CFrame)
	modelo:PivotTo(cf)
	-- encosta o pé da Mistureba no pedestal
	local caixaCf, caixaTam = modelo:GetBoundingBox()
	local fundo = caixaCf.Position.Y - caixaTam.Y / 2
	modelo:PivotTo(cf + Vector3.new(0, cf.Position.Y - fundo, 0))
end

local function desenharBase(jogador: Player)
	local estado = estados[jogador]
	local perfil = Dados.obter(jogador)
	if not estado or not perfil then
		return
	end
	local base = estado.base
	local vagas = totalVagas(jogador, perfil)
	for i, pedestal in base.pedestais do
		local ativa = i <= vagas
		pedestal.Transparency = if ativa then 0 else 1
		pedestal.CanCollide = ativa
	end
	-- remove modelos que não existem mais
	for vaga, modelo in estado.modelos do
		if perfil.criaturas[vaga] ~= modelo:GetAttribute("Criatura") then
			modelo:Destroy()
			estado.modelos[vaga] = nil
		end
	end
	-- cria os que faltam
	for vaga, id in perfil.criaturas do
		if not estado.modelos[vaga] then
			local n = tonumber(vaga)
			local cf = n and base.vagas[n]
			if cf then
				local modelo = Criaturas.modelo(id)
				posicionar(modelo, cf)
				prenderRoubar(modelo, jogador, vaga)
				modelo.Parent = base.modelo
				estado.modelos[vaga] = modelo
			end
		end
	end
	-- quem está sendo carregada por um ladrão fica escondida; as outras aparecem
	for _, modelo in estado.modelos do
		modelo.Parent = base.modelo
	end
	for _, outro in estados do
		local r = outro.roubo
		if r and r.dono == jogador then
			local modelo = estado.modelos[r.vaga]
			if modelo then
				modelo.Parent = nil
			end
		end
	end
	estado.sujo = true
end

-- Coloca Misturebas guardadas nas vagas livres.
local function arrumarGuardadas(jogador: Player, perfil: Dados.Perfil)
	while #perfil.guardadas > 0 do
		local vaga = vagaLivre(jogador, perfil)
		if not vaga then
			break
		end
		perfil.criaturas[vaga] = table.remove(perfil.guardadas, 1) :: string
	end
end

-- Põe uma Mistureba nova na base (ou guarda, se a base estiver cheia).
local function darCriatura(jogador: Player, id: string, mostrar: boolean): boolean
	local perfil = Dados.obter(jogador)
	if not perfil then
		return false
	end
	local vaga = vagaLivre(jogador, perfil)
	if vaga then
		perfil.criaturas[vaga] = id
	else
		table.insert(perfil.guardadas, id)
		aviso(
			jogador,
			"Base cheia! " .. Config.PorId[id].nome .. " ficou guardada até liberar uma vaga.",
			Color3.fromRGB(255, 200, 80)
		)
	end
	desenharBase(jogador)
	if mostrar then
		evChocou:FireClient(jogador, id)
	end
	local raridade = Config.PorId[id].raridade
	if raridade == "mitico" or raridade == "secreto" then
		local info = Config.Raridades[raridade]
		evAnuncio:FireAllClients(
			jogador.DisplayName .. " conseguiu " .. Config.PorId[id].nome .. " (" .. info.nome .. ")!",
			info.cor
		)
	end
	return true
end

local function sortearCriatura(raridade: string): string
	local lista = Util.criaturasDaRaridade(raridade)
	return lista[rng:NextInteger(1, #lista)].id
end

------------------------------------------------------------------------
-- O que aparece em cima da cabeça e a velocidade
------------------------------------------------------------------------
local function atualizarCarga(jogador: Player)
	local estado = estados[jogador]
	if not estado then
		return
	end
	if estado.visual then
		estado.visual:Destroy()
		estado.visual = nil
	end
	local hum = humanoide(jogador)
	local cabeca = jogador.Character and jogador.Character:FindFirstChild("Head") :: BasePart?
	local carregando = #estado.ovos > 0 or estado.roubo ~= nil
	if hum then
		hum.WalkSpeed = if carregando then Config.Jogador.velocidadeCarregando else Config.Jogador.velocidade
	end
	if not carregando or not cabeca then
		estado.sujo = true
		return
	end

	local pasta = Instance.new("Model")
	pasta.Name = "Carga"
	local altura = 2.5
	-- coloca a peça (ou o modelo inteiro) em cima da cabeça e solda
	local function grudar(principal: BasePart, modelo: Model?)
		local alvo = cabeca.CFrame * CFrame.new(0, altura + principal.Size.Y / 2, 0)
		if modelo then
			modelo:PivotTo(alvo)
		else
			principal.CFrame = alvo
		end
		local solda = Instance.new("WeldConstraint")
		solda.Part0 = cabeca
		solda.Part1 = principal
		solda.Parent = principal
		altura += principal.Size.Y
	end
	local function soltinha(peca: BasePart)
		peca.Anchored = false
		peca.CanCollide = false
		peca.CanTouch = false
		peca.CanQuery = false
		peca.Massless = true
	end
	if estado.roubo then
		local modelo = Criaturas.modelo(estado.roubo.id)
		for _, peca in modelo:GetDescendants() do
			if peca:IsA("BasePart") then
				soltinha(peca)
			end
		end
		modelo.Parent = pasta
		grudar(modelo.PrimaryPart :: BasePart, modelo)
		-- ladrão brilha para todo mundo ver
		local destaque = Instance.new("Highlight")
		destaque.FillColor = Color3.fromRGB(255, 60, 60)
		destaque.FillTransparency = 0.7
		destaque.OutlineColor = Color3.fromRGB(255, 255, 255)
		destaque.Adornee = jogador.Character
		destaque.Parent = pasta
	end
	for _, raridade in estado.ovos do
		local ovo = Criaturas.ovo(raridade)
		soltinha(ovo)
		ovo.Parent = pasta
		grudar(ovo, nil)
	end
	pasta.Parent = jogador.Character
	estado.visual = pasta
	estado.sujo = true
end

------------------------------------------------------------------------
-- Ovos no chão (chuva)
------------------------------------------------------------------------
local function ovoNoChao(raridade: string, posicao: Vector3, caindo: boolean)
	local ovo = Criaturas.ovo(raridade)
	ovo.Anchored = true
	ovo.CanCollide = false
	ovo.CFrame = CFrame.new(posicao + Vector3.new(0, ovo.Size.Y / 2 + 0.3, 0))
	if caindo then
		ovo.CFrame += Vector3.new(0, 60, 0)
		-- defer: a animação começa depois do ovo entrar no mapa (logo abaixo)
		task.defer(function()
			local inicio = os.clock()
			local de = ovo.CFrame
			local para = CFrame.new(posicao + Vector3.new(0, ovo.Size.Y / 2 + 0.3, 0))
			while os.clock() - inicio < 1.2 and ovo.Parent do
				local t = (os.clock() - inicio) / 1.2
				ovo.CFrame = de:Lerp(para, t * t)
				RunService.Heartbeat:Wait()
			end
			if ovo.Parent then
				ovo.CFrame = para
			end
		end)
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Pegar"
	prompt.ObjectText = "Ovo " .. Config.Raridades[raridade].nome
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = ovo

	prompt.Triggered:Connect(function(jogador)
		local estado = estados[jogador]
		if not estado or not ovo.Parent then
			return
		end
		local r = raiz(jogador)
		if not r or (r.Position - ovo.Position).Magnitude > 14 then
			return
		end
		if estado.roubo then
			aviso(jogador, "Você está carregando uma Mistureba. Leve para sua base primeiro!")
			return
		end
		local capacidade = if Loja.tem(jogador, "mochila") then 2 else 1
		if #estado.ovos >= capacidade then
			aviso(jogador, "Suas mãos estão cheias! Leve o ovo para sua base.")
			return
		end
		ovo:Destroy()
		table.insert(estado.ovos, raridade)
		atualizarCarga(jogador)
	end)

	ovo.Parent = pastaOvos
	task.delay(Config.Chuva.tempoNoChao, function()
		if ovo.Parent then
			ovo:Destroy()
		end
	end)
end

local function pontoNoCampo(): Vector3
	local angulo = rng:NextNumber(0, math.pi * 2)
	local distancia = math.sqrt(rng:NextNumber()) * (Mapa.RAIO_CAMPO - 4)
	return Vector3.new(math.cos(angulo) * distancia, 0.4, math.sin(angulo) * distancia)
end

local function ondaDeOvos()
	local pesos = table.clone(Config.Chuva.pesos)
	if agora() < sorteAte then
		for raridade, peso in pesos do
			if raridade ~= "comum" then
				pesos[raridade] = peso * Config.SorteMultiplicadorRaros
			end
		end
	end
	local limiteAnuncio = table.find(Config.OrdemRaridades, Config.Chuva.anunciarAPartirDe) or 4
	for _ = 1, Config.Chuva.ovosPorOnda do
		if #pastaOvos:GetChildren() >= Config.Chuva.maxOvosNoChao then
			break
		end
		local raridade = Util.sortearPeso(pesos, rng)
		ovoNoChao(raridade, pontoNoCampo(), true)
		if (table.find(Config.OrdemRaridades, raridade) or 1) >= limiteAnuncio then
			local info = Config.Raridades[raridade]
			evAnuncio:FireAllClients("Um OVO " .. string.upper(info.nome) .. " caiu na chuva! Corre!", info.cor)
		end
	end
end

------------------------------------------------------------------------
-- Roubo
------------------------------------------------------------------------
local function cancelarRoubo(ladrao: Player)
	local estado = estados[ladrao]
	if not estado or not estado.roubo then
		return
	end
	local dono = estado.roubo.dono
	estado.roubo = nil
	atualizarCarga(ladrao)
	if estados[dono] then
		desenharBase(dono)
	end
end

local function cadeadoLigado(estado: Estado): boolean
	return agora() < estado.cadeadoAte
end

local function tentarRoubar(ladrao: Player, dono: Player, vaga: string)
	local estadoLadrao, estadoDono = estados[ladrao], estados[dono]
	local perfilDono = Dados.obter(dono)
	if not estadoLadrao or not estadoDono or not perfilDono or ladrao == dono then
		return
	end
	if estadoLadrao.roubo or #estadoLadrao.ovos > 0 then
		aviso(ladrao, "Você já está carregando algo!")
		return
	end
	if cadeadoLigado(estadoDono) then
		aviso(ladrao, "A base está trancada! Espere o cadeado abrir.")
		return
	end
	if agora() - estadoDono.entrouEm < Config.Base.protecaoNovatoSegundos then
		aviso(ladrao, dono.DisplayName .. " acabou de chegar e está protegido.")
		return
	end
	if contarCriaturas(perfilDono) < Config.Base.minimoParaSerRoubado then
		aviso(ladrao, dono.DisplayName .. " tem poucas Misturebas e está protegido.")
		return
	end
	local id = perfilDono.criaturas[vaga]
	local modelo = estadoDono.modelos[vaga]
	if not id or not modelo or not modelo.Parent then
		return
	end
	for _, outro in estados do
		local r = outro.roubo
		if r and r.dono == dono and r.vaga == vaga then
			return -- alguém já está levando essa
		end
	end
	local r = raiz(ladrao)
	if not r or (r.Position - modelo:GetPivot().Position).Magnitude > 16 then
		return
	end
	estadoLadrao.roubo = { dono = dono, vaga = vaga, id = id }
	modelo.Parent = nil
	atualizarCarga(ladrao)
	aviso(
		dono,
		ladrao.DisplayName .. " está levando sua " .. Config.PorId[id].nome .. "! Dê um tapa para recuperar!",
		Color3.fromRGB(255, 90, 90)
	)
	aviso(ladrao, "Corra para sua base!", Color3.fromRGB(120, 255, 120))
	estadoDono.sujo = true
end

-- Ladrão chegou na própria base com a Mistureba.
local function entregarRoubo(ladrao: Player)
	local estado = estados[ladrao]
	local perfil = Dados.obter(ladrao)
	if not estado or not perfil or not estado.roubo then
		return
	end
	local roubo = estado.roubo
	local perfilDono = Dados.obter(roubo.dono)
	if not perfilDono or perfilDono.criaturas[roubo.vaga] ~= roubo.id then
		cancelarRoubo(ladrao)
		return
	end
	local vaga = vagaLivre(ladrao, perfil)
	if not vaga then
		if liberado(estado, "avisoCheia", 3) then
			aviso(ladrao, "Sua base está cheia! Venda ou funda uma Mistureba para guardar esta.")
		end
		return
	end
	perfilDono.criaturas[roubo.vaga] = nil
	arrumarGuardadas(roubo.dono, perfilDono)
	perfil.criaturas[vaga] = roubo.id
	perfil.estatisticas.roubos += 1
	estado.roubo = nil
	atualizarCarga(ladrao)
	desenharBase(ladrao)
	desenharBase(roubo.dono)
	aviso(ladrao, "Você roubou " .. Config.PorId[roubo.id].nome .. "!", Color3.fromRGB(120, 255, 120))
	aviso(
		roubo.dono,
		ladrao.DisplayName .. " levou sua " .. Config.PorId[roubo.id].nome .. ". Vá buscar de volta!",
		Color3.fromRGB(255, 160, 80)
	)
end

-- Ovos levados para a base viram Misturebas.
local function entregarOvos(jogador: Player)
	local estado = estados[jogador]
	local perfil = Dados.obter(jogador)
	if not estado or not perfil or #estado.ovos == 0 then
		return
	end
	local ovos = estado.ovos
	estado.ovos = {}
	atualizarCarga(jogador)
	for _, raridade in ovos do
		perfil.estatisticas.ovos += 1
		darCriatura(jogador, sortearCriatura(raridade), true)
	end
end

-- Solta tudo no chão (tapa, morte ou botão Soltar).
local function soltarTudo(jogador: Player)
	local estado = estados[jogador]
	if not estado then
		return
	end
	local r = raiz(jogador)
	if #estado.ovos > 0 then
		for _, raridade in estado.ovos do
			if r then
				local espalhar = Vector3.new(rng:NextNumber(-4, 4), 0, rng:NextNumber(-4, 4))
				ovoNoChao(raridade, Vector3.new(r.Position.X, 0.4, r.Position.Z) + espalhar, false)
			end
		end
		estado.ovos = {}
	end
	if estado.roubo then
		local dono = estado.roubo.dono
		cancelarRoubo(jogador)
		if estados[dono] then
			aviso(dono, "Sua Mistureba voltou para a base!", Color3.fromRGB(120, 255, 120))
		end
	end
	atualizarCarga(jogador)
end

------------------------------------------------------------------------
-- Cadeado da porta
------------------------------------------------------------------------
local function desenharPorta(estado: Estado)
	local ligado = cadeadoLigado(estado)
	estado.base.porta.Transparency = if ligado then 0.35 else 1
	estado.base.porta.CanCollide = ligado
	estado.base.botao.Color = if ligado then Color3.fromRGB(60, 220, 90) else Color3.fromRGB(230, 40, 40)
end

local function trancar(jogador: Player)
	local estado = estados[jogador]
	if not estado then
		return
	end
	local t = agora()
	if t < estado.cadeadoLivreEm then
		aviso(jogador, string.format("O cadeado recarrega em %d s.", math.ceil(estado.cadeadoLivreEm - t)))
		return
	end
	local duracao = if Loja.tem(jogador, "cadeado")
		then Config.CadeadoReforcadoSegundos
		else Config.Base.cadeadoSegundos
	estado.cadeadoAte = t + duracao
	estado.cadeadoLivreEm = estado.cadeadoAte + Config.Base.cadeadoEsperaSegundos
	desenharPorta(estado)
	estado.sujo = true
	aviso(jogador, string.format("Base trancada por %d segundos!", duracao), Color3.fromRGB(120, 255, 120))
end

------------------------------------------------------------------------
-- Entrar e sair
------------------------------------------------------------------------
local function irParaBase(jogador: Player)
	local estado = estados[jogador]
	local r = raiz(jogador)
	if estado and r then
		r.CFrame = estado.base.centro * CFrame.new(0, 4, -estado.base.tamanho.Z / 2 + 8)
	end
end

local function criarLeaderstats(jogador: Player)
	local pasta = Instance.new("Folder")
	pasta.Name = "leaderstats"
	local moedas = Instance.new("StringValue")
	moedas.Name = "Moedas"
	moedas.Parent = pasta
	local renda = Instance.new("StringValue")
	renda.Name = "Renda/s"
	renda.Parent = pasta
	pasta.Parent = jogador
end

local function aoPersonagem(jogador: Player, personagem: Model)
	local estado = estados[jogador]
	if not estado then
		return
	end
	estado.visual = nil
	local hum = personagem:WaitForChild("Humanoid", 10) :: Humanoid?
	if not hum then
		return
	end
	hum.WalkSpeed = Config.Jogador.velocidade
	hum.Died:Connect(function()
		soltarTudo(jogador)
	end)
	task.defer(irParaBase, jogador)
	if Loja.tem(jogador, "vip") then
		local cabeca = personagem:WaitForChild("Head", 5)
		if cabeca then
			local tag = Instance.new("BillboardGui")
			tag.Name = "TagVip"
			tag.Size = UDim2.fromOffset(80, 24)
			tag.StudsOffset = Vector3.new(0, 3.2, 0)
			tag.LightInfluence = 0
			local rotulo = Instance.new("TextLabel")
			rotulo.Size = UDim2.fromScale(1, 1)
			rotulo.BackgroundTransparency = 1
			rotulo.Font = Enum.Font.FredokaOne
			rotulo.TextScaled = true
			rotulo.Text = "VIP"
			rotulo.TextColor3 = Color3.fromRGB(255, 210, 40)
			rotulo.TextStrokeTransparency = 0
			rotulo.Parent = tag
			tag.Parent = cabeca
		end
	end
end

local function entrar(jogador: Player)
	local indice: number? = nil
	for i = 1, #bases do
		if not donoDaBase[i] then
			indice = i
			break
		end
	end
	if not indice then
		jogador:Kick("Servidor cheio, tente outro!")
		return
	end
	donoDaBase[indice] = jogador

	local perfil = Dados.carregar(jogador)
	if not perfil then
		donoDaBase[indice] = nil
		if jogador.Parent then
			jogador:Kick("Não conseguimos carregar seu progresso. Entre de novo em alguns segundos.")
		end
		return
	end
	if jogador.Parent ~= Players then
		donoDaBase[indice] = nil
		Dados.sair(jogador)
		return
	end

	local base = bases[indice]
	base.placa.Text = "Base de " .. jogador.DisplayName
	estados[jogador] = {
		base = base,
		ovos = {},
		roubo = nil,
		cadeadoAte = 0,
		cadeadoLivreEm = 0,
		entrouEm = agora(),
		ultimoTapa = 0,
		ultimoPedido = {},
		modelos = {},
		visual = nil,
		sujo = true,
	}
	base.botao:SetAttribute("Dono", jogador.UserId)
	base.porta:SetAttribute("Dono", jogador.UserId)

	local promptCadeado = Instance.new("ProximityPrompt")
	promptCadeado.Name = "Cadeado"
	promptCadeado.ActionText = "Trancar"
	promptCadeado.ObjectText = "Cadeado"
	promptCadeado.MaxActivationDistance = 10
	promptCadeado:SetAttribute("Dono", jogador.UserId)
	promptCadeado.Triggered:Connect(function(quem)
		if quem == jogador then
			trancar(jogador)
		end
	end)
	promptCadeado.Parent = base.botao

	Loja.carregarPasses(jogador)
	arrumarGuardadas(jogador, perfil)
	desenharBase(jogador)
	desenharPorta(estados[jogador])
	criarLeaderstats(jogador)

	jogador.CharacterAdded:Connect(function(personagem)
		aoPersonagem(jogador, personagem)
	end)
	if jogador.Character then
		aoPersonagem(jogador, jogador.Character)
	end
end

local function sair(jogador: Player)
	local estado = estados[jogador]
	if estado then
		-- devolve o que estava roubando e cancela quem roubava dele
		if estado.roubo then
			cancelarRoubo(jogador)
		end
		for outro, e in estados do
			if e.roubo and e.roubo.dono == jogador then
				e.roubo = nil
				atualizarCarga(outro)
				aviso(outro, "O dono saiu do jogo e a Mistureba voltou com ele.")
			end
		end
		for _, modelo in estado.modelos do
			modelo:Destroy()
		end
		local prompt = estado.base.botao:FindFirstChild("Cadeado")
		if prompt then
			prompt:Destroy()
		end
		for _, pedestal in estado.base.pedestais do
			pedestal.Transparency = 1
			pedestal.CanCollide = false
		end
		estado.base.placa.Text = "Base livre"
		estado.base.porta.Transparency = 1
		estado.base.porta.CanCollide = false
		estado.base.botao:SetAttribute("Dono", nil)
		estado.base.porta:SetAttribute("Dono", nil)
		donoDaBase[estado.base.indice] = nil
		estados[jogador] = nil
	end
	Dados.sair(jogador)
end

Players.PlayerAdded:Connect(entrar)
Players.PlayerRemoving:Connect(sair)
for _, jogador in Players:GetPlayers() do
	task.spawn(entrar, jogador)
end

------------------------------------------------------------------------
-- Pedidos da tela (sempre conferidos aqui)
------------------------------------------------------------------------
local function promptDeRoubo(prompt: ProximityPrompt, jogador: Player)
	if prompt.Name ~= "Roubar" then
		return
	end
	local idDono = prompt:GetAttribute("Dono")
	local vaga = prompt:GetAttribute("Vaga")
	if type(idDono) ~= "number" or type(vaga) ~= "string" then
		return
	end
	local dono = Players:GetPlayerByUserId(idDono)
	if dono then
		tentarRoubar(jogador, dono, vaga)
	end
end
game:GetService("ProximityPromptService").PromptTriggered:Connect(promptDeRoubo)

evComprarOvo.OnServerEvent:Connect(function(jogador, idOvo)
	local estado, perfil = estados[jogador], Dados.obter(jogador)
	if not estado or not perfil or type(idOvo) ~= "string" or not liberado(estado, "ovo", 0.4) then
		return
	end
	local ovo: Config.OvoLoja? = nil
	for _, o in Config.OvosLoja do
		if o.id == idOvo then
			ovo = o
		end
	end
	if not ovo then
		return
	end
	if not vagaLivre(jogador, perfil) then
		aviso(jogador, "Sua base está cheia! Venda ou funda uma Mistureba antes.")
		return
	end
	if perfil.moedas < ovo.preco then
		aviso(jogador, "Moedas insuficientes.")
		return
	end
	perfil.moedas -= ovo.preco
	perfil.estatisticas.ovos += 1
	darCriatura(jogador, sortearCriatura(Util.sortearPeso(ovo.pesos, rng)), true)
end)

evFundir.OnServerEvent:Connect(function(jogador, vagaA, vagaB)
	local estado, perfil = estados[jogador], Dados.obter(jogador)
	if not estado or not perfil or not liberado(estado, "fundir", 0.5) then
		return
	end
	if type(vagaA) ~= "string" or type(vagaB) ~= "string" or vagaA == vagaB then
		return
	end
	local idA, idB = perfil.criaturas[vagaA], perfil.criaturas[vagaB]
	if not idA or not idB then
		return
	end
	for _, outro in estados do
		local r = outro.roubo
		if r and r.dono == jogador and (r.vaga == vagaA or r.vaga == vagaB) then
			aviso(jogador, "Essa Mistureba está sendo roubada! Recupere primeiro.")
			return
		end
	end
	local a, b = Config.PorId[idA], Config.PorId[idB]
	local resultado = Util.receita(idA, idB)
	local raridadeCusto = a.raridade
	if not resultado then
		if a.raridade ~= b.raridade then
			aviso(jogador, "Só dá para fundir Misturebas da mesma raridade (ou uma receita secreta).")
			return
		end
		local proxima = Util.proximaRaridade(a.raridade)
		if not proxima or proxima == "secreto" then
			aviso(jogador, "Essa dupla não tem receita... ainda. Tente outra combinação!")
			return
		end
		resultado = sortearCriatura(proxima)
	end
	local custo = Config.CustoFusao[raridadeCusto] or 0
	if perfil.moedas < custo then
		aviso(jogador, "A fusão custa " .. Util.numero(custo) .. " moedas.")
		return
	end
	perfil.moedas -= custo
	perfil.criaturas[vagaB] = nil
	perfil.criaturas[vagaA] = resultado
	perfil.estatisticas.fusoes += 1
	arrumarGuardadas(jogador, perfil)
	desenharBase(jogador)
	evChocou:FireClient(jogador, resultado)
	local raridade = Config.PorId[resultado :: string].raridade
	if raridade == "mitico" or raridade == "secreto" then
		local info = Config.Raridades[raridade]
		evAnuncio:FireAllClients(
			jogador.DisplayName .. " fundiu um(a) " .. Config.PorId[resultado :: string].nome .. "!",
			info.cor
		)
	end
end)

evVender.OnServerEvent:Connect(function(jogador, vaga)
	local estado, perfil = estados[jogador], Dados.obter(jogador)
	if not estado or not perfil or type(vaga) ~= "string" or not liberado(estado, "vender", 0.3) then
		return
	end
	local id = perfil.criaturas[vaga]
	if not id then
		return
	end
	for _, outro in estados do
		local r = outro.roubo
		if r and r.dono == jogador and r.vaga == vaga then
			return
		end
	end
	local valor = Config.PorId[id].renda * 60
	perfil.criaturas[vaga] = nil
	perfil.moedas += valor
	arrumarGuardadas(jogador, perfil)
	desenharBase(jogador)
	aviso(jogador, "Vendeu " .. Config.PorId[id].nome .. " por " .. Util.numero(valor) .. " moedas.")
end)

evMelhorar.OnServerEvent:Connect(function(jogador)
	local estado, perfil = estados[jogador], Dados.obter(jogador)
	if not estado or not perfil or not liberado(estado, "melhorar", 0.5) then
		return
	end
	local preco = Config.Base.melhorias[perfil.melhorias + 1]
	if not preco then
		aviso(jogador, "Sua base já está no tamanho máximo!")
		return
	end
	if perfil.moedas < preco then
		aviso(jogador, "Moedas insuficientes.")
		return
	end
	perfil.moedas -= preco
	perfil.melhorias += 1
	arrumarGuardadas(jogador, perfil)
	desenharBase(jogador)
	aviso(jogador, "Base maior! +" .. Config.Base.vagasPorMelhoria .. " vagas.", Color3.fromRGB(120, 255, 120))
end)

evTrancar.OnServerEvent:Connect(function(jogador)
	local estado = estados[jogador]
	if estado and liberado(estado, "trancar", 0.5) then
		trancar(jogador)
	end
end)

evSoltar.OnServerEvent:Connect(function(jogador)
	local estado = estados[jogador]
	if estado and liberado(estado, "soltar", 0.5) then
		soltarTudo(jogador)
	end
end)

evTapa.OnServerEvent:Connect(function(jogador)
	local estado = estados[jogador]
	local r = raiz(jogador)
	if not estado or not r then
		return
	end
	local t = os.clock()
	if t - estado.ultimoTapa < Config.Jogador.esperaTapa then
		return
	end
	estado.ultimoTapa = t
	-- acha o jogador mais perto na frente
	local alvo: Player? = nil
	local melhor = Config.Jogador.alcanceTapa
	for outro in estados do
		local ro = raiz(outro)
		if outro ~= jogador and ro then
			local d = (ro.Position - r.Position).Magnitude
			if d < melhor then
				melhor = d
				alvo = outro
			end
		end
	end
	if not alvo then
		return
	end
	local ra = raiz(alvo)
	if ra then
		local direcao = (ra.Position - r.Position) * Vector3.new(1, 0, 1)
		if direcao.Magnitude > 0.01 then
			evEmpurrao:FireClient(alvo, direcao.Unit)
		end
	end
	local estadoAlvo = estados[alvo]
	if estadoAlvo and (#estadoAlvo.ovos > 0 or estadoAlvo.roubo) then
		soltarTudo(alvo)
		aviso(alvo, jogador.DisplayName .. " te deu um tapa e você soltou tudo!", Color3.fromRGB(255, 160, 80))
		aviso(jogador, "TAPA! " .. alvo.DisplayName .. " soltou o que carregava.", Color3.fromRGB(120, 255, 120))
	end
end)

------------------------------------------------------------------------
-- Compras com Robux
------------------------------------------------------------------------
Loja.iniciar({
	entregar = function(jogador: Player, chave: string): boolean
		local perfil = Dados.obter(jogador)
		if not perfil then
			return false
		end
		if chave == "sorte" then
			sorteAte = math.max(sorteAte, agora()) + Config.SorteMinutos * 60
			evAnuncio:FireAllClients(
				jogador.DisplayName .. " ligou a SORTE DO SERVIDOR! Ovos raros caem 2x mais para todos!",
				Color3.fromRGB(120, 255, 160)
			)
			for _, e in estados do
				e.sujo = true
			end
			return true
		elseif chave == "ovoarcoiris" then
			return darCriatura(jogador, sortearCriatura(Util.sortearPeso(Config.OvoArcoIrisPesos, rng)), true)
		elseif chave == "moedas" then
			local valor =
				math.max(Config.SacoMoedasMinimo, rendaPorSegundo(jogador, perfil) * Config.SacoMoedasMinutos * 60)
			perfil.moedas += math.floor(valor)
			aviso(jogador, "+" .. Util.numero(valor) .. " moedas!", Color3.fromRGB(255, 220, 80))
			return true
		end
		return false
	end,
	aoMudarPasses = function(jogador: Player)
		local estado = estados[jogador]
		local perfil = Dados.obter(jogador)
		if estado and perfil then
			arrumarGuardadas(jogador, perfil)
			desenharBase(jogador)
		end
	end,
})

------------------------------------------------------------------------
-- Laços: renda, entregas, cadeado, chuva, estado para a tela
------------------------------------------------------------------------
local function montarEstado(jogador: Player, estado: Estado, perfil: Dados.Perfil)
	local carregando = {}
	for _, raridade in estado.ovos do
		table.insert(carregando, raridade)
	end
	return {
		moedas = perfil.moedas,
		renda = rendaPorSegundo(jogador, perfil),
		criaturas = perfil.criaturas,
		guardadas = #perfil.guardadas,
		vagas = totalVagas(jogador, perfil),
		precoMelhoria = Config.Base.melhorias[perfil.melhorias + 1],
		cadeadoAte = estado.cadeadoAte,
		cadeadoLivreEm = estado.cadeadoLivreEm,
		sorteAte = sorteAte,
		passes = Loja.passes(jogador),
		ovos = carregando,
		roubo = if estado.roubo then estado.roubo.id else nil,
		protegidoAte = estado.entrouEm + Config.Base.protecaoNovatoSegundos,
		baseIndice = estado.base.indice,
	}
end

local acumulado = 0
local proximaOnda = agora() + 5
RunService.Heartbeat:Connect(function(dt)
	-- entrega automática quando quem carrega entra na própria base
	for jogador, estado in estados do
		if #estado.ovos > 0 or estado.roubo then
			local r = raiz(jogador)
			if r and Mapa.dentro(estado.base, r.Position) then
				if estado.roubo then
					entregarRoubo(jogador)
				else
					entregarOvos(jogador)
				end
			end
		end
	end

	if agora() >= proximaOnda then
		proximaOnda = agora() + Config.Chuva.intervalo
		ondaDeOvos()
	end

	acumulado += dt
	if acumulado < 1 then
		return
	end
	acumulado -= 1
	for jogador, estado in estados do
		local perfil = Dados.obter(jogador)
		if perfil then
			perfil.moedas += rendaPorSegundo(jogador, perfil)
			desenharPorta(estado)
			local stats = jogador:FindFirstChild("leaderstats")
			if stats then
				(stats :: any).Moedas.Value = Util.numero(perfil.moedas);
				(stats :: any)["Renda/s"].Value = Util.numero(rendaPorSegundo(jogador, perfil))
			end
			evEstado:FireClient(jogador, montarEstado(jogador, estado, perfil))
			estado.sujo = false
		end
	end
end)

-- Manda o estado logo depois de mudanças (sem esperar o próximo segundo)
task.spawn(function()
	while true do
		task.wait(0.15)
		for jogador, estado in estados do
			if estado.sujo then
				local perfil = Dados.obter(jogador)
				if perfil then
					estado.sujo = false
					evEstado:FireClient(jogador, montarEstado(jogador, estado, perfil))
				end
			end
		end
	end
end)
