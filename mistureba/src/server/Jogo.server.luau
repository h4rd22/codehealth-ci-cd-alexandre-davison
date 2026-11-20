--!strict
-- Coração do Mistureba no servidor: bases, chuva de ovos, carregar,
-- roubar, bolha, cadeado, fusão, loja de moedas e renda.
-- O servidor decide tudo; a tela só pede e mostra.

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Util = require(ReplicatedStorage.Shared.Util)
local Dados = require(script.Parent.Dados)
local Mapa = require(script.Parent.Mapa)
local Criaturas = require(script.Parent.Criaturas)
local Loja = require(script.Parent.Loja)
local Troca = require(script.Parent.Troca)

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
local evRenascer = remote("Renascer")
local evPegarMissao = remote("PegarMissao")
local evGirarRoleta = remote("GirarRoleta")
local evComprarUpgrade = remote("ComprarUpgrade")
local evRastro = remote("Rastro")
-- servidor -> tela
local evEstado = remote("Estado")
local evAviso = remote("Aviso")
local evAnuncio = remote("Anuncio")
local evClima = remote("Clima")
local evAjustes = remote("Ajustes")
local evChocou = remote("Chocou")
local evRoleta = remote("Roleta") -- qual prêmio saiu, para a tela girar até ele

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
	presenteEm: number, -- quando sai o próximo presente por tempo jogando
	presentes: number,
	roletaEm: number, -- quando libera o próximo giro grátis
	girando: boolean,
	segundosJogados: number,
	ultimoTapa: number, -- última bolha lançada
	presoAte: number, -- preso numa bolha até este os.clock()
	imuneAte: number, -- depois da bolha fica livre de outra por um tempinho
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

-- Clima do servidor (evento com hora marcada)
local climaAtual: string? = nil
local climaAte = 0
-- no Studio o primeiro clima vem logo, para dar para testar
local proximoClima = agora() + (if RunService:IsStudio() then 25 else Config.Climas.intervalo)

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

local function contarDescobertas(perfil: Dados.Perfil): number
	local n = 0
	for _ in perfil.descobertas do
		n += 1
	end
	return n
end

-- Tudo que multiplica a renda: VIP, renascimentos, Misturedex e a melhoria Renda Turbo
local function multiplicadorRenda(jogador: Player, perfil: Dados.Perfil): number
	local m = 1
	if Loja.tem(jogador, "vip") then
		m *= Config.VipMultiplicador
	end
	m *= 1 + perfil.renascimentos * Config.Renascer.bonusPorRenascimento
	m *= 1 + Util.bonusDex(contarDescobertas(perfil))
	m *= 1 + Util.efeitoUpgrade(perfil.upgrades, "renda")
	return m
end

local function velocidadeDe(jogador: Player, base: number): number
	local v = if Loja.tem(jogador, "rapido") then base * Config.RapidoMultiplicador else base
	local perfil = Dados.obter(jogador)
	return v * (1 + Util.efeitoUpgrade(perfil and perfil.upgrades, "velocidade"))
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
	return total * multiplicadorRenda(jogador, perfil)
end

local function precoRenascer(perfil: Dados.Perfil): number
	return Config.Renascer.precoBase * Config.Renascer.crescimento ^ perfil.renascimentos
end

-- Misturedex: primeira vez com uma Mistureba dá um prêmio.
local function descobrir(jogador: Player, perfil: Dados.Perfil, idCompleto: string)
	local id = Util.idBase(idCompleto)
	-- coleção de mutações: a primeira de cada tipo dá prêmio
	local mutId = Config.PorId[idCompleto] and Config.PorId[idCompleto].mutacao
	if mutId and not perfil.mutacoes[mutId] then
		perfil.mutacoes[mutId] = true
		local m = Config.MutacaoPorId[mutId]
		local premioMut = math.floor(math.max(Config.PremioMutacaoMinimo, Config.PorId[idCompleto].renda * 300))
		perfil.moedas += premioMut
		evAviso:FireClient(
			jogador,
			"Coleção de mutações: " .. m.nome .. " achada! +" .. Util.numero(premioMut) .. " moedas",
			m.cor
		)
	end
	if perfil.descobertas[id] then
		return
	end
	perfil.descobertas[id] = true
	local premio = Config.PorId[id].renda * Config.PremioDescobertaSegundos
	perfil.moedas += premio
	evAviso:FireClient(
		jogador,
		"NOVA na Misturedex: " .. Config.PorId[id].nome .. "! +" .. Util.numero(premio) .. " moedas",
		Color3.fromRGB(120, 255, 220)
	)
	local achadas = contarDescobertas(perfil)
	for _, marco in Config.MarcosDex do
		if marco.achadas == achadas then
			evAnuncio:FireAllClients(
				string.format(
					"%s achou %d Misturebas! Agora ganha +%d%% de moedas para sempre!",
					jogador.DisplayName,
					achadas,
					math.floor(marco.bonus * 100)
				),
				Color3.fromRGB(120, 255, 220),
				"jogadores"
			)
		end
	end
end

------------------------------------------------------------------------
-- Missões diárias
------------------------------------------------------------------------
local function missoesDoDia(perfil: Dados.Perfil): Dados.Missoes
	local hoje = os.time() // 86400
	local m = perfil.missoes
	if m.dia ~= hoje or #m.ids ~= Config.Missoes.porDia then
		-- mesmas missões para todo mundo no mesmo dia
		local sorteio = Random.new(hoje)
		local indices = {}
		for i = 1, #Config.Missoes.lista do
			table.insert(indices, i)
		end
		local ids, progresso, pegas = {}, {}, {}
		for i = 1, Config.Missoes.porDia do
			local j = sorteio:NextInteger(i, #indices)
			indices[i], indices[j] = indices[j], indices[i]
			ids[i] = indices[i]
			progresso[i] = 0
			pegas[i] = false
		end
		m = { dia = hoje, ids = ids, progresso = progresso, pegas = pegas, final = false }
		perfil.missoes = m
	end
	return m
end

local function progredir(jogador: Player, tipo: string, quanto: number)
	local perfil = Dados.obter(jogador)
	if not perfil then
		return
	end
	local m = missoesDoDia(perfil)
	for i, idx in m.ids do
		local def = Config.Missoes.lista[idx]
		if def.tipo == tipo and m.progresso[i] < def.meta then
			m.progresso[i] = math.min(def.meta, m.progresso[i] + quanto)
			if m.progresso[i] >= def.meta then
				aviso(
					jogador,
					"MISSÃO COMPLETA: " .. string.format(def.texto, def.meta) .. "! Pegue o prêmio em MISSÕES.",
					Color3.fromRGB(255, 200, 80)
				)
			end
			local estado = estados[jogador]
			if estado then
				estado.sujo = true
			end
		end
	end
end

local function premioMissao(jogador: Player, perfil: Dados.Perfil): number
	return math.max(
		Config.Missoes.premioMinimo,
		math.floor(rendaPorSegundo(jogador, perfil) * Config.Missoes.premioSegundos)
	)
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
	-- a base mudou: se o jogador estava oferecendo algo numa troca, confere de novo
	Troca.conferir(jogador)
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
	descobrir(jogador, perfil, id)
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
	local mut = Config.PorId[id].mutacao
	if mut then
		local m = Config.MutacaoPorId[mut]
		aviso(jogador, "MUTAÇÃO " .. string.upper(m.nome) .. "! Rende " .. m.multiplicador .. "x mais!", m.cor)
	end
	-- anúncio para o servidor: só Lendária para cima (cada jogador escolhe o que esconder)
	local ordemRaridade = table.find(Config.OrdemRaridades, raridade) or 1
	if ordemRaridade >= (table.find(Config.OrdemRaridades, "lendario") or 4) then
		local info = Config.Raridades[raridade]
		evAnuncio:FireAllClients(
			jogador.DisplayName
				.. " conseguiu "
				.. Config.PorId[id].nome
				.. " ("
				.. info.nome
				.. ", "
				.. Util.textoUmEm(id)
				.. ")!",
			info.cor,
			raridade
		)
	end
	return true
end

-- comMutacao: ovos chocados podem nascer Dourada, Diamante ou Arco-íris.
local function sortearCriatura(raridade: string, comMutacao: boolean?, dono: Player?): string
	local lista = Util.criaturasDaRaridade(raridade)
	local id = lista[rng:NextInteger(1, #lista)].id
	if comMutacao then
		local mult = if dono and Loja.tem(dono, "sortedupla") then Config.SorteDuplaMutacao else 1
		local perfilDono = dono and Dados.obter(dono)
		mult *= 1 + Util.efeitoUpgrade(perfilDono and perfilDono.upgrades, "sorte")
		if perfilDono and perfilDono.pocoes > 0 and dono then
			perfilDono.pocoes -= 1
			mult *= Config.PocaoMultiplicador
			local estadoDono = estados[dono]
			if estadoDono then
				estadoDono.sujo = true
			end
		end
		local mut = Util.sortearMutacao(rng, mult, climaAtual)
		if mut then
			id ..= "*" .. mut
		end
	end
	return id
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
		local preso = os.clock() < estado.presoAte
		hum.JumpHeight = if preso then 0 else 7.2
		if preso then
			hum.WalkSpeed = 0
		else
			local base = if carregando then Config.Jogador.velocidadeCarregando else Config.Jogador.velocidade
			hum.WalkSpeed = velocidadeDe(jogador, base)
		end
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
			Criaturas.moverOvo(principal, alvo)
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
		for _, peca in ovo:GetDescendants() do
			if peca:IsA("BasePart") then
				soltinha(peca)
			end
		end
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
	Criaturas.moverOvo(ovo, CFrame.new(posicao + Vector3.new(0, ovo.Size.Y / 2 + 0.3 + (if caindo then 60 else 0), 0)))
	if caindo then
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
	local clima = Util.clima(climaAtual)
	if clima and clima.raros ~= 1 then
		for raridade, peso in pesos do
			if raridade ~= "comum" then
				pesos[raridade] = peso * clima.raros
			end
		end
	end
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
			evAnuncio:FireAllClients(
				"Um OVO " .. string.upper(info.nome) .. " caiu na chuva! Corre!",
				info.cor,
				raridade
			)
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
		ladrao.DisplayName .. " está levando sua " .. Config.PorId[id].nome .. "! Jogue uma bolha (F) para recuperar!",
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
	descobrir(ladrao, perfil, roubo.id)
	perfil.estatisticas.roubos += 1
	progredir(ladrao, "roubos", 1)
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
		darCriatura(jogador, sortearCriatura(raridade, true, jogador), true)
	end
	progredir(jogador, "ovos", #ovos)
	progredir(jogador, "chuva", #ovos)
end

-- Solta tudo no chão (bolha, morte ou botão Soltar).
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
	local perfilCadeado = Dados.obter(jogador)
	local duracao = (
		if Loja.tem(jogador, "cadeado") then Config.CadeadoReforcadoSegundos else Config.Base.cadeadoSegundos
	) + Util.efeitoUpgrade(perfilCadeado and perfilCadeado.upgrades, "cadeado")
	estado.cadeadoAte = t + duracao
	estado.cadeadoLivreEm = estado.cadeadoAte + Config.Base.cadeadoEsperaSegundos
	desenharPorta(estado)
	estado.sujo = true
	aviso(jogador, string.format("Base trancada por %d segundos!", duracao), Color3.fromRGB(120, 255, 120))
	progredir(jogador, "trancar", 1)
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
	-- a Mistureba mais difícil que o jogador tem (chance real "1 em X")
	local rara = Instance.new("StringValue")
	rara.Name = "Mais rara"
	rara.Parent = pasta
	pasta.Parent = jogador
end

local function maisRara(perfil: Dados.Perfil): string
	local melhor, melhorId = 0, nil
	local function olhar(id: string)
		local def = Config.PorId[id]
		if not def then
			return
		end
		-- secreta de receita conta como muito rara
		local x = Util.umEm(id) or (if def.raridade == "secreto" then 1e7 else 0)
		if x > melhor then
			melhor, melhorId = x, id
		end
	end
	for _, id in perfil.criaturas do
		olhar(id)
	end
	for _, id in perfil.guardadas do
		olhar(id)
	end
	if not melhorId then
		return "-"
	end
	return Util.textoUmEm(melhorId)
end

local colocarRastro: (Player) -> ()

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
	hum.WalkSpeed = velocidadeDe(jogador, Config.Jogador.velocidade)
	hum.Died:Connect(function()
		soltarTudo(jogador)
	end)
	task.defer(function()
		personagem:WaitForChild("HumanoidRootPart", 5)
		colocarRastro(jogador)
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

-- Ganhos offline e prêmio diário, logo depois de entrar.
local function boasVindas(jogador: Player, perfil: Dados.Perfil)
	if perfil.ultimaSaida > 0 then
		local segundos = math.clamp(os.time() - perfil.ultimaSaida, 0, Config.Offline.maxHoras * 3600)
		local ganho = math.floor(rendaPorSegundo(jogador, perfil) * segundos * Config.Offline.porcento)
		if ganho > 0 then
			perfil.moedas += ganho
			aviso(
				jogador,
				"Suas Misturebas trabalharam enquanto você estava fora: +" .. Util.numero(ganho) .. " moedas!",
				Color3.fromRGB(255, 220, 80)
			)
		end
	end
	local hoje = os.time() // 86400
	if hoje > perfil.diaPremio then
		perfil.sequencia = if hoje == perfil.diaPremio + 1 then perfil.sequencia + 1 else 1
		perfil.diaPremio = hoje
		local dia = (perfil.sequencia - 1) % #Config.PremioDiario + 1
		local premio = Config.PremioDiario[dia]
		if premio.moedas then
			perfil.moedas += premio.moedas
			aviso(
				jogador,
				string.format("Prêmio do dia %d: +%s moedas! Volte amanhã!", dia, Util.numero(premio.moedas)),
				Color3.fromRGB(120, 255, 160)
			)
		elseif premio.ovo then
			for _, ovo in Config.OvosLoja do
				if ovo.id == premio.ovo then
					aviso(
						jogador,
						string.format("Prêmio do dia %d: um %s grátis!", dia, ovo.nome),
						Color3.fromRGB(120, 255, 160)
					)
					darCriatura(jogador, sortearCriatura(Util.sortearPeso(ovo.pesos, rng), true, jogador), true)
				end
			end
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
		presenteEm = agora() + Config.PresenteTempo.intervalo,
		presentes = 0,
		roletaEm = agora(), -- o primeiro giro já vem liberado
		girando = false,
		segundosJogados = 0,
		ultimoTapa = 0,
		presoAte = 0,
		imuneAte = 0,
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
	task.delay(4, function()
		if estados[jogador] then
			boasVindas(jogador, perfil)
		end
	end)
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
	darCriatura(jogador, sortearCriatura(Util.sortearPeso(ovo.pesos, rng), true, jogador), true)
	progredir(jogador, "ovos", 1)
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
	-- mutação na fusão: cada mutação das duas tem chance de passar;
	-- se nenhuma passar, ainda pode nascer uma mutação nova (como um ovo)
	local herdada: string? = nil
	local chanceHerdar = if Loja.tem(jogador, "sortedupla")
		then Config.FusaoHerdarMutacaoSorte
		else Config.FusaoHerdarMutacao
	local candidatas = {}
	for _, d in { a, b } do
		if d.mutacao then
			table.insert(candidatas, rng:NextInteger(1, #candidatas + 1), d.mutacao)
		end
	end
	for _, m in candidatas do
		if rng:NextNumber() < chanceHerdar then
			herdada = m
			break
		end
	end
	local baseResultado = Config.PorId[resultado :: string].base or resultado :: string
	if herdada then
		resultado = baseResultado .. "*" .. herdada
	else
		resultado = sortearCriatura(Config.PorId[baseResultado].raridade, true, jogador)
		if Util.receita(idA, idB) then
			-- receita sempre dá a Mistureba da receita; só a mutação é sorteada
			local mutNova = Config.PorId[resultado :: string].mutacao
			resultado = if mutNova then baseResultado .. "*" .. mutNova else baseResultado
		end
	end
	local custo = Config.CustoFusao[raridadeCusto] or 0
	if perfil.moedas < custo then
		aviso(jogador, "A fusão custa " .. Util.numero(custo) .. " moedas.")
		return
	end
	perfil.moedas -= custo
	perfil.criaturas[vagaB] = nil
	perfil.criaturas[vagaA] = resultado
	descobrir(jogador, perfil, resultado :: string)
	perfil.estatisticas.fusoes += 1
	progredir(jogador, "fusoes", 1)
	arrumarGuardadas(jogador, perfil)
	desenharBase(jogador)
	evChocou:FireClient(jogador, resultado)
	if herdada then
		aviso(
			jogador,
			"A mutação " .. Config.MutacaoPorId[herdada].nome .. " passou na fusão!",
			Config.MutacaoPorId[herdada].cor
		)
	end
	local raridade = Config.PorId[resultado :: string].raridade
	if (table.find(Config.OrdemRaridades, raridade) or 1) >= (table.find(Config.OrdemRaridades, "lendario") or 4) then
		local info = Config.Raridades[raridade]
		evAnuncio:FireAllClients(
			jogador.DisplayName .. " fundiu um(a) " .. Config.PorId[resultado :: string].nome .. "!",
			info.cor,
			raridade
		)
	end
end)

-- Tela de Configurações do jogador (anúncios escondidos, som, modo leve)
evAjustes.OnServerEvent:Connect(function(jogador, novos)
	local estado, perfil = estados[jogador], Dados.obter(jogador)
	if not estado or not perfil or type(novos) ~= "table" or not liberado(estado, "ajustes", 0.2) then
		return
	end
	local ocultar = {}
	if type(novos.ocultar) == "table" then
		for _, chave in { "lendario", "mitico", "secreto", "jogadores" } do
			if novos.ocultar[chave] == true then
				ocultar[chave] = true
			end
		end
	end
	perfil.ajustes = { ocultar = ocultar, som = novos.som ~= false, leve = novos.leve == true }
	estado.sujo = true
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
	local valor = Config.PorId[id].renda * Config.VendaSegundos
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

evRenascer.OnServerEvent:Connect(function(jogador)
	local estado, perfil = estados[jogador], Dados.obter(jogador)
	if not estado or not perfil or not liberado(estado, "renascer", 2) then
		return
	end
	local preco = precoRenascer(perfil)
	if perfil.moedas < preco then
		aviso(jogador, "Renascer custa " .. Util.numero(preco) .. " moedas.")
		return
	end
	-- devolve o que alguém estava roubando dele e solta o que ele carrega
	for outro, e in estados do
		if e.roubo and e.roubo.dono == jogador then
			e.roubo = nil
			atualizarCarga(outro)
		end
	end
	soltarTudo(jogador)
	perfil.moedas = 0
	perfil.criaturas = { ["1"] = "chaleiruga" }
	perfil.guardadas = {}
	perfil.melhorias = 0
	perfil.renascimentos += 1
	desenharBase(jogador)
	local bonus = math.floor(perfil.renascimentos * Config.Renascer.bonusPorRenascimento * 100)
	evAnuncio:FireAllClients(
		jogador.DisplayName .. " RENASCEU! Agora ganha +" .. bonus .. "% de moedas para sempre!",
		Color3.fromRGB(255, 120, 255),
		"jogadores"
	)
end)

evSoltar.OnServerEvent:Connect(function(jogador)
	local estado = estados[jogador]
	if estado and liberado(estado, "soltar", 0.5) then
		soltarTudo(jogador)
	end
end)

-- Onda de bolha que sai de quem apertou F (todo mundo vê, mesmo sem acertar ninguém)
local function ondaBolha(centro: Vector3)
	local onda = Instance.new("Part")
	onda.Name = "OndaBolha"
	onda.Shape = Enum.PartType.Ball
	onda.Size = Vector3.new(2, 2, 2)
	onda.Material = Enum.Material.Glass
	onda.Color = Color3.fromRGB(150, 210, 255)
	onda.Transparency = 0.5
	onda.Anchored = true
	onda.CanCollide = false
	onda.CanQuery = false
	onda.CanTouch = false
	onda.CastShadow = false
	onda.CFrame = CFrame.new(centro)
	onda.Parent = workspace
	local alcance = Config.Jogador.alcanceTapa * 2
	TweenService:Create(onda, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(alcance, alcance, alcance),
		Transparency = 1,
	}):Play()
	Debris:AddItem(onda, 0.4)
end

evTapa.OnServerEvent:Connect(function(jogador)
	local estado = estados[jogador]
	local r = raiz(jogador)
	if not estado or not r then
		return
	end
	local t = os.clock()
	if t - estado.ultimoTapa < Config.Jogador.esperaTapa or t < estado.presoAte then
		return
	end
	estado.ultimoTapa = t
	ondaBolha(r.Position)
	-- acha o jogador mais perto (quem acabou de sair de uma bolha fica livre por um tempinho)
	local alvo: Player? = nil
	local melhor = Config.Jogador.alcanceTapa
	for outro, estadoOutro in estados do
		local ro = raiz(outro)
		if outro ~= jogador and ro and t >= estadoOutro.imuneAte then
			local d = (ro.Position - r.Position).Magnitude
			if d < melhor then
				melhor = d
				alvo = outro
			end
		end
	end
	if not alvo then
		aviso(jogador, "Ninguém perto o bastante para prender na bolha.", Color3.fromRGB(150, 210, 255))
		return
	end
	-- bolha: prende o alvo por um instante (sem empurrar nem machucar)
	local estadoAlvo = estados[alvo]
	local ra = raiz(alvo)
	if estadoAlvo and ra then
		estadoAlvo.presoAte = t + Config.Jogador.tempoNaBolha
		estadoAlvo.imuneAte = estadoAlvo.presoAte + Config.Jogador.imuneDepoisDaBolha
		local bolha = Instance.new("Part")
		bolha.Name = "Bolha"
		bolha.Shape = Enum.PartType.Ball
		bolha.Size = Vector3.new(8, 8, 8)
		bolha.Material = Enum.Material.Glass
		bolha.Color = Color3.fromRGB(150, 210, 255)
		bolha.Transparency = 0.55
		bolha.Reflectance = 0.3
		bolha.CanCollide = false
		bolha.CanQuery = false
		bolha.CanTouch = false
		bolha.CastShadow = false
		bolha.Massless = true
		bolha.CFrame = ra.CFrame
		local solda = Instance.new("WeldConstraint")
		solda.Part0 = ra
		solda.Part1 = bolha
		solda.Parent = bolha
		bolha.Parent = alvo.Character
		Debris:AddItem(bolha, Config.Jogador.tempoNaBolha)
		atualizarCarga(alvo)
		task.delay(Config.Jogador.tempoNaBolha + 0.05, function()
			if estados[alvo] then
				atualizarCarga(alvo)
			end
		end)
	end
	if estadoAlvo and (#estadoAlvo.ovos > 0 or estadoAlvo.roubo) then
		soltarTudo(alvo)
		aviso(alvo, jogador.DisplayName .. " te prendeu numa bolha e você soltou tudo!", Color3.fromRGB(150, 210, 255))
		aviso(jogador, "BOLHA! " .. alvo.DisplayName .. " soltou o que carregava.", Color3.fromRGB(120, 255, 120))
		progredir(jogador, "bolhas", 1)
	else
		aviso(alvo, jogador.DisplayName .. " te prendeu numa bolha!", Color3.fromRGB(150, 210, 255))
		aviso(jogador, "Você prendeu " .. alvo.DisplayName .. " numa bolha!", Color3.fromRGB(150, 210, 255))
	end
end)

-- Melhorias permanentes compradas com moedas
evComprarUpgrade.OnServerEvent:Connect(function(jogador, id)
	local estado, perfil = estados[jogador], Dados.obter(jogador)
	if not estado or not perfil or type(id) ~= "string" or not liberado(estado, "upgrade", 0.25) then
		return
	end
	local u = Util.upgrade(id)
	if not u then
		return
	end
	local nivel = perfil.upgrades[id] or 0
	if nivel >= u.max then
		aviso(jogador, u.nome .. " já está no máximo!")
		return
	end
	local preco = Util.precoUpgrade(u, nivel)
	if perfil.moedas < preco then
		aviso(jogador, "Moedas insuficientes.")
		return
	end
	perfil.moedas -= preco
	perfil.upgrades[id] = nivel + 1
	aviso(jogador, u.nome .. " nível " .. (nivel + 1) .. "!", u.cor)
	if id == "velocidade" then
		atualizarCarga(jogador)
	end
	estado.sujo = true
end)

-- Rastro atrás do personagem (só enfeite)
colocarRastro = function(jogador: Player)
	local perfil = Dados.obter(jogador)
	local personagem = jogador.Character
	local raizP = personagem and personagem:FindFirstChild("HumanoidRootPart")
	if not perfil or not raizP then
		return
	end
	for _, nome in { "RastroMistureba", "RastroA", "RastroB" } do
		local velho = raizP:FindFirstChild(nome)
		if velho then
			velho:Destroy()
		end
	end
	local def: Config.Rastro? = nil
	for _, r in Config.Rastros do
		if r.id == perfil.rastro then
			def = r
		end
	end
	if not def then
		return
	end
	local a = Instance.new("Attachment")
	a.Name = "RastroA"
	a.Position = Vector3.new(0, 0.9, 0)
	a.Parent = raizP
	local b = Instance.new("Attachment")
	b.Name = "RastroB"
	b.Position = Vector3.new(0, -0.9, 0)
	b.Parent = raizP
	local pontos = {}
	for i, cor in def.cores do
		table.insert(pontos, ColorSequenceKeypoint.new((i - 1) / math.max(1, #def.cores - 1), cor))
	end
	if #pontos == 1 then
		table.insert(pontos, ColorSequenceKeypoint.new(1, def.cores[1]))
	end
	local rastro = Instance.new("Trail")
	rastro.Name = "RastroMistureba"
	rastro.Attachment0 = a
	rastro.Attachment1 = b
	rastro.Color = ColorSequence.new(pontos)
	rastro.Transparency = NumberSequence.new(0, 1)
	rastro.WidthScale = NumberSequence.new(1, 0.2)
	rastro.MinLength = 0.05
	rastro.Lifetime = 0.9
	rastro.LightEmission = 0.6
	rastro.FaceCamera = true
	rastro.Parent = raizP
end

evRastro.OnServerEvent:Connect(function(jogador, id)
	local estado, perfil = estados[jogador], Dados.obter(jogador)
	if not estado or not perfil or type(id) ~= "string" or not liberado(estado, "rastro", 0.4) then
		return
	end
	local def: Config.Rastro? = nil
	for _, r in Config.Rastros do
		if r.id == id then
			def = r
		end
	end
	if not def then
		return
	end
	if not perfil.rastros[id] then
		if perfil.moedas < def.preco then
			aviso(jogador, "Moedas insuficientes.")
			return
		end
		perfil.moedas -= def.preco
		perfil.rastros[id] = true
		perfil.rastro = id
		aviso(jogador, "Rastro " .. def.nome .. " comprado!", def.cores[1])
	else
		-- já tem: clicar de novo equipa ou tira
		perfil.rastro = if perfil.rastro == id then nil else id
	end
	colocarRastro(jogador)
	estado.sujo = true
end)

-- Roleta grátis: o servidor sorteia, a tela gira até o prêmio e só então ele é entregue
local DURACAO_GIRO = 4.2
evGirarRoleta.OnServerEvent:Connect(function(jogador)
	local estado = estados[jogador]
	if not estado or estado.girando or agora() < estado.roletaEm or not liberado(estado, "roleta", 1) then
		return
	end
	local total = 0
	for _, p in Config.Roleta.premios do
		total += p.peso
	end
	local alvo = rng:NextNumber() * total
	local escolhido = #Config.Roleta.premios
	for i, p in Config.Roleta.premios do
		alvo -= p.peso
		if alvo <= 0 then
			escolhido = i
			break
		end
	end
	estado.girando = true
	estado.roletaEm = agora() + Config.Roleta.intervalo
	estado.sujo = true
	evRoleta:FireClient(jogador, escolhido)
	task.delay(DURACAO_GIRO, function()
		estado.girando = false
		local perfil = Dados.obter(jogador)
		if not perfil or estados[jogador] ~= estado then
			return
		end
		local premio = Config.Roleta.premios[escolhido]
		if premio.segundos then
			local valor = math.floor(math.max(premio.minimo or 0, rendaPorSegundo(jogador, perfil) * premio.segundos))
			perfil.moedas += valor
			aviso(jogador, "ROLETA: +" .. Util.numero(valor) .. " moedas!", premio.cor)
		elseif premio.ovo then
			for _, ovo in Config.OvosLoja do
				if ovo.id == premio.ovo then
					aviso(jogador, "ROLETA: " .. ovo.nome .. " de graça!", premio.cor)
					darCriatura(jogador, sortearCriatura(Util.sortearPeso(ovo.pesos, rng), true, jogador), true)
					progredir(jogador, "ovos", 1)
				end
			end
		end
		estado.sujo = true
	end)
end)

evPegarMissao.OnServerEvent:Connect(function(jogador, i)
	local estado = estados[jogador]
	local perfil = Dados.obter(jogador)
	if not estado or not perfil or not liberado(estado, "missao", 0.3) or type(i) ~= "number" then
		return
	end
	local m = missoesDoDia(perfil)
	local idx = m.ids[i]
	if not idx or m.pegas[i] then
		return
	end
	local def = Config.Missoes.lista[idx]
	if m.progresso[i] < def.meta then
		return
	end
	m.pegas[i] = true
	local premio = premioMissao(jogador, perfil)
	perfil.moedas += premio
	aviso(jogador, "Prêmio da missão: +" .. Util.numero(premio) .. " moedas!", Color3.fromRGB(255, 220, 80))
	local todas = true
	for j = 1, #m.ids do
		if not m.pegas[j] then
			todas = false
		end
	end
	if todas and not m.final then
		m.final = true
		for _, ovo in Config.OvosLoja do
			if ovo.id == Config.Missoes.ovoFinal then
				evAnuncio:FireAllClients(
					jogador.DisplayName .. " completou todas as missões do dia e ganhou um " .. ovo.nome .. "!",
					Color3.fromRGB(255, 200, 80),
					"jogadores"
				)
				darCriatura(jogador, sortearCriatura(Util.sortearPeso(ovo.pesos, rng), true, jogador), true)
			end
		end
	end
	estado.sujo = true
end)

------------------------------------------------------------------------
-- Compras com Robux
------------------------------------------------------------------------
Troca.iniciar({
	remotes = pastaRemotes,
	aviso = aviso,
	sendoRoubada = function(dono: Player, vaga: string): boolean
		for _, outro in estados do
			local r = outro.roubo
			if r and r.dono == dono and r.vaga == vaga then
				return true
			end
		end
		return false
	end,
	vagaLivre = vagaLivre,
	descobrir = descobrir,
	depois = function(jogador: Player)
		desenharBase(jogador)
		local estado = estados[jogador]
		if estado then
			estado.sujo = true
		end
	end,
})

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
			return darCriatura(
				jogador,
				sortearCriatura(Util.sortearPeso(Config.OvoArcoIrisPesos, rng), true, jogador),
				true
			)
		elseif chave == "moedas" then
			local valor =
				math.max(Config.SacoMoedasMinimo, rendaPorSegundo(jogador, perfil) * Config.SacoMoedasMinutos * 60)
			perfil.moedas += math.floor(valor)
			aviso(jogador, "+" .. Util.numero(valor) .. " moedas!", Color3.fromRGB(255, 220, 80))
			return true
		elseif chave == "pocao" then
			perfil.pocoes += Config.PocaoOvos
			aviso(
				jogador,
				"Poção ativa! Seus próximos " .. perfil.pocoes .. " ovos têm 4x mais chance de mutação.",
				Color3.fromRGB(200, 140, 255)
			)
			local estado = estados[jogador]
			if estado then
				estado.sujo = true
			end
			return true
		elseif chave == "presente" then
			local estado = estados[jogador]
			if not estado then
				return false
			end
			estado.presenteEm = agora() -- o laço de 1 segundo entrega o presente
			estado.sujo = true
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
		descobertas = perfil.descobertas,
		renascimentos = perfil.renascimentos,
		precoRenascer = precoRenascer(perfil),
		cadeadoAte = estado.cadeadoAte,
		cadeadoLivreEm = estado.cadeadoLivreEm,
		sorteAte = sorteAte,
		passes = Loja.passes(jogador),
		ovos = carregando,
		roubo = if estado.roubo then estado.roubo.id else nil,
		protegidoAte = estado.entrouEm + Config.Base.protecaoNovatoSegundos,
		presenteEm = estado.presenteEm,
		roletaEm = estado.roletaEm,
		pocoes = perfil.pocoes,
		mutacoes = perfil.mutacoes,
		ajustes = perfil.ajustes,
		clima = climaAtual,
		climaAte = climaAte,
		proximoClima = proximoClima,
		upgrades = perfil.upgrades,
		rastros = perfil.rastros,
		rastro = perfil.rastro,
		multiplicador = multiplicadorRenda(jogador, perfil),
		proximoPresenteEspecial = (estado.presentes + 1) % Config.PresenteTempo.especialACada == 0,
		missoes = (function()
			local m = missoesDoDia(perfil)
			local lista = {}
			for i, idx in m.ids do
				local def = Config.Missoes.lista[idx]
				lista[i] = {
					texto = string.format(def.texto, def.meta),
					meta = def.meta,
					progresso = m.progresso[i],
					pega = m.pegas[i],
				}
			end
			return lista
		end)(),
		missoesFinal = perfil.missoes.final,
		premioMissao = premioMissao(jogador, perfil),
		bonusDex = Util.bonusDex(contarDescobertas(perfil)),
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
		local clima = Util.clima(climaAtual)
		proximaOnda = agora() + Config.Chuva.intervalo / (if clima then clima.chuvaMais else 1)
		ondaDeOvos()
	end

	if climaAtual and agora() >= climaAte then
		local fim = Util.clima(climaAtual)
		climaAtual = nil
		proximoClima = agora() + Config.Climas.intervalo
		evClima:FireAllClients(nil, 0, proximoClima)
		if fim then
			evAnuncio:FireAllClients(fim.nome .. " acabou! O próximo clima vem em 15 minutos.", fim.cor)
		end
	elseif not climaAtual and agora() >= proximoClima then
		local total = 0
		for _, c in Config.Climas.lista do
			total += c.peso
		end
		local alvo = rng:NextNumber() * total
		local cl = Config.Climas.lista[1]
		for _, c in Config.Climas.lista do
			alvo -= c.peso
			if alvo <= 0 then
				cl = c
				break
			end
		end
		if cl then
			climaAtual = cl.id
			climaAte = agora() + Config.Climas.duracao
			proximoClima = climaAte + Config.Climas.intervalo
			evClima:FireAllClients(cl.id, climaAte, proximoClima)
			evAnuncio:FireAllClients(string.upper(cl.nome) .. "! " .. cl.descricao, cl.cor)
		end
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
			estado.segundosJogados += 1
			if estado.segundosJogados % 60 == 0 then
				progredir(jogador, "minutos", 1)
			end
			if agora() >= estado.presenteEm then
				estado.presentes += 1
				estado.presenteEm = agora() + Config.PresenteTempo.intervalo
				local especial = estado.presentes % Config.PresenteTempo.especialACada == 0
				local idOvo = if especial then Config.PresenteTempo.ovoEspecial else Config.PresenteTempo.ovo
				for _, ovo in Config.OvosLoja do
					if ovo.id == idOvo then
						aviso(
							jogador,
							"PRESENTE por jogar: " .. ovo.nome .. " de graça!",
							Color3.fromRGB(255, 220, 120)
						)
						darCriatura(jogador, sortearCriatura(Util.sortearPeso(ovo.pesos, rng), true, jogador), true)
						progredir(jogador, "ovos", 1)
					end
				end
			end
			local stats = jogador:FindFirstChild("leaderstats")
			if stats then
				(stats :: any).Moedas.Value = Util.numero(perfil.moedas);
				(stats :: any)["Renda/s"].Value = Util.numero(rendaPorSegundo(jogador, perfil));
				(stats :: any)["Mais rara"].Value = maisRara(perfil)
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
