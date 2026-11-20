--!strict
-- Salvamento dos jogadores (DataStore).
-- Cuidados: tenta de novo quando o Roblox falha, trava o save para não ser
-- usado por dois servidores ao mesmo tempo, salva a cada minuto e ao fechar.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local VERSAO = 1
local NOME_STORE = "Mistureba_v1"
local TRAVA_VALIDA_SEGUNDOS = 180 -- trava de outro servidor mais velha que isso é considerada abandonada
local AUTOSAVE_SEGUNDOS = 60
local MAX_RECIBOS = 60

export type Perfil = {
	versao: number,
	moedas: number,
	criaturas: { [string]: string }, -- vaga ("1", "2"...) -> id da criatura
	guardadas: { string }, -- Misturebas esperando vaga livre (ex.: compradas com a base cheia)
	melhorias: number, -- quantas melhorias de vaga comprou com moedas
	recibos: { string }, -- últimas compras com Robux já entregues (evita entregar duas vezes)
	estatisticas: { roubos: number, fusoes: number, ovos: number },
	descobertas: { [string]: boolean }, -- Misturedex: quais já teve
	renascimentos: number,
	ultimaSaida: number, -- os.time() da última vez salvo (para ganhos offline)
	diaPremio: number, -- último dia (os.time()//86400) em que pegou o prêmio diário
	sequencia: number, -- dias seguidos pegando o prêmio
	trava: { servidor: string, hora: number }?,
}

local Dados = {}

local store: DataStore? = nil
local ok, erro = pcall(function()
	store = DataStoreService:GetDataStore(NOME_STORE)
end)
if not ok then
	warn("[Dados] DataStore indisponível (no Studio, ligue 'Enable Studio Access to API Services'):", erro)
end

local perfis: { [Player]: Perfil } = {}
local carregando: { [Player]: boolean } = {}
local servidorId = if RunService:IsStudio() then "studio-" .. tostring(math.random(1, 1e9)) else game.JobId

local function perfilNovo(): Perfil
	return {
		versao = VERSAO,
		moedas = 0,
		criaturas = { ["1"] = "chaleiruga" }, -- todo mundo começa com uma Mistureba
		guardadas = {},
		melhorias = 0,
		recibos = {},
		estatisticas = { roubos = 0, fusoes = 0, ovos = 0 },
		descobertas = { chaleiruga = true },
		renascimentos = 0,
		ultimaSaida = 0,
		diaPremio = 0,
		sequencia = 0,
		trava = nil,
	}
end

-- Garante que um save antigo ou estranho tenha todos os campos.
local function corrigir(dado: any): Perfil
	local p = perfilNovo()
	if type(dado) ~= "table" then
		return p
	end
	if type(dado.moedas) == "number" and dado.moedas >= 0 and dado.moedas == dado.moedas then
		p.moedas = math.floor(dado.moedas)
	end
	if type(dado.criaturas) == "table" then
		p.criaturas = {}
		for vaga, id in dado.criaturas do
			if type(vaga) == "string" and type(id) == "string" and Config.PorId[id] then
				p.criaturas[vaga] = id
			end
		end
	end
	if type(dado.guardadas) == "table" then
		for _, id in dado.guardadas do
			if type(id) == "string" and Config.PorId[id] then
				table.insert(p.guardadas, id)
			end
		end
	end
	if type(dado.melhorias) == "number" then
		p.melhorias = math.clamp(math.floor(dado.melhorias), 0, #Config.Base.melhorias)
	end
	if type(dado.recibos) == "table" then
		for _, r in dado.recibos do
			if type(r) == "string" then
				table.insert(p.recibos, r)
			end
		end
	end
	if type(dado.estatisticas) == "table" then
		for chave, valor in dado.estatisticas do
			if type(valor) == "number" and (p.estatisticas :: any)[chave] ~= nil then
				(p.estatisticas :: any)[chave] = valor
			end
		end
	end
	if type(dado.descobertas) == "table" then
		for id, sim in dado.descobertas do
			if type(id) == "string" and sim == true and Config.PorId[id] then
				p.descobertas[id] = true
			end
		end
	end
	for _, campo in { "renascimentos", "ultimaSaida", "diaPremio", "sequencia" } do
		local v = dado[campo]
		if type(v) == "number" and v == v and v >= 0 then
			(p :: any)[campo] = math.floor(v)
		end
	end
	p.trava = dado.trava
	return p
end

local function tentar<T>(nome: string, funcao: () -> T): (boolean, T?)
	for tentativa = 1, 5 do
		local sucesso, resultado = pcall(funcao)
		if sucesso then
			return true, resultado
		end
		warn(string.format("[Dados] %s falhou (tentativa %d): %s", nome, tentativa, tostring(resultado)))
		task.wait(2 ^ tentativa)
	end
	return false, nil
end

local function chave(jogador: Player): string
	return "jogador_" .. jogador.UserId
end

-- Carrega o perfil e trava ele para este servidor.
function Dados.carregar(jogador: Player): Perfil?
	if perfis[jogador] then
		return perfis[jogador]
	end
	if carregando[jogador] then
		repeat
			task.wait(0.2)
		until not carregando[jogador]
		return perfis[jogador]
	end
	carregando[jogador] = true

	local perfil: Perfil? = nil
	if not store then
		perfil = perfilNovo()
	else
		for vez = 1, 6 do
			local travadoPorOutro = false
			local forcar = vez == 6 -- depois de ~30 s esperando, assume que o outro servidor caiu
			local sucesso, resultado = tentar("carregar", function()
				return (store :: DataStore):UpdateAsync(chave(jogador), function(antigo)
					local p = corrigir(antigo)
					local trava = p.trava
					local recente = trava and os.time() - trava.hora < TRAVA_VALIDA_SEGUNDOS
					if trava and trava.servidor ~= servidorId and recente and not forcar then
						travadoPorOutro = true
						return nil -- não mexe no save
					end
					p.trava = { servidor = servidorId, hora = os.time() }
					return p
				end)
			end)
			if not sucesso then
				break
			end
			if not travadoPorOutro then
				perfil = corrigir(resultado)
				break
			end
			-- o outro servidor provavelmente está salvando a saída; espera um pouco
			task.wait(6)
		end
	end

	carregando[jogador] = nil
	if perfil and jogador.Parent == Players then
		perfis[jogador] = perfil
		return perfil
	end
	return nil
end

function Dados.obter(jogador: Player): Perfil?
	return perfis[jogador]
end

-- Salva o perfil. soltar = true libera a trava (jogador saiu).
function Dados.salvar(jogador: Player, soltar: boolean?): boolean
	local perfil = perfis[jogador]
	if not perfil or not store then
		return perfil ~= nil
	end
	local sucesso = tentar("salvar", function()
		return (store :: DataStore):UpdateAsync(chave(jogador), function(antigo)
			local atual = corrigir(antigo)
			if atual.trava and atual.trava.servidor ~= servidorId then
				return nil -- outro servidor pegou o save; não sobrescreve
			end
			local copia = table.clone(perfil)
			copia.ultimaSaida = os.time()
			copia.trava = if soltar then nil else { servidor = servidorId, hora = os.time() }
			return copia
		end)
	end)
	return sucesso
end

function Dados.registrarRecibo(perfil: Perfil, idCompra: string): boolean
	if table.find(perfil.recibos, idCompra) then
		return false
	end
	table.insert(perfil.recibos, idCompra)
	while #perfil.recibos > MAX_RECIBOS do
		table.remove(perfil.recibos, 1)
	end
	return true
end

function Dados.jaRecebido(perfil: Perfil, idCompra: string): boolean
	return table.find(perfil.recibos, idCompra) ~= nil
end

function Dados.sair(jogador: Player)
	-- espera o carregamento terminar antes de salvar a saída
	while carregando[jogador] do
		task.wait(0.2)
	end
	if perfis[jogador] then
		Dados.salvar(jogador, true)
		perfis[jogador] = nil
	end
end

task.spawn(function()
	while true do
		task.wait(AUTOSAVE_SEGUNDOS)
		for jogador in perfis do
			task.spawn(Dados.salvar, jogador, false)
		end
	end
end)

game:BindToClose(function()
	local pendentes = 0
	for jogador in perfis do
		pendentes += 1
		task.spawn(function()
			Dados.salvar(jogador, true)
			pendentes -= 1
		end)
	end
	local inicio = os.clock()
	while pendentes > 0 and os.clock() - inicio < 25 do
		task.wait(0.2)
	end
end)

return Dados
