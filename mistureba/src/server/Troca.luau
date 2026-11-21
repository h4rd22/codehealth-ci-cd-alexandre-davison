--!strict
-- Troca de Misturebas entre jogadores, pensada para não ter golpe:
-- - só Misturebas da base (nada de moedas, Robux ou coisas de fora do jogo);
-- - os dois veem tudo o que entra e sai, com raridade e renda;
-- - qualquer mudança na oferta desmarca o "aceito" dos dois;
-- - depois que os dois aceitam, ainda tem 5 segundos para desistir;
-- - na hora de fechar o servidor confere tudo de novo e troca de uma vez só.
-- Trocar não cria Mistureba nenhuma, então não mexe na economia (só muda de dono).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Dados = require(script.Parent.Dados)

local Troca = {}

Troca.MAX_ITENS = 4
Troca.CONTAGEM = 5
Troca.PEDIDO_EXPIRA = 20

export type Ganchos = {
	remotes: Folder,
	aviso: (Player, string, Color3?) -> (),
	sendoRoubada: (Player, string) -> boolean, -- alguém está carregando essa vaga agora?
	vagaLivre: (Player, Dados.Perfil) -> string?,
	descobrir: (Player, Dados.Perfil, string) -> (),
	depois: (Player) -> (), -- redesenhar base, mandar estado etc.
}

type Item = { vaga: string, id: string }
type Sessao = {
	a: Player,
	b: Player,
	ofertas: { [Player]: { Item } },
	aceito: { [Player]: boolean },
	fechaEm: number?,
	versao: number,
	fechando: boolean,
}

local sessoes: { [Player]: Sessao } = {}
local pedidos: { [Player]: { de: Player, em: number } } = {} -- pedido que o jogador recebeu
local ultimoPedido: { [Player]: number } = {}

local ganchos: Ganchos
local evTroca: RemoteEvent
local evPedido: RemoteEvent

local function remote(nome: string): RemoteEvent
	local r = Instance.new("RemoteEvent")
	r.Name = nome
	r.Parent = ganchos.remotes
	return r
end

local function outro(s: Sessao, p: Player): Player
	return if s.a == p then s.b else s.a
end

local function rendaDe(itens: { Item }): number
	local total = 0
	for _, item in itens do
		local def = Config.PorId[item.id]
		total += if def then def.renda else 0
	end
	return total
end

-- Manda para cada um o que ele precisa ver (as duas ofertas com nomes e valores)
local function enviar(s: Sessao)
	local agora = workspace:GetServerTimeNow()
	for _, p in { s.a, s.b } do
		local o = outro(s, p)
		local function ids(itens: { Item }): { string }
			local lista = {}
			for _, item in itens do
				table.insert(lista, item.id)
			end
			return lista
		end
		local minhas = {}
		for _, item in s.ofertas[p] do
			table.insert(minhas, item.vaga)
		end
		evTroca:FireClient(p, {
			com = o.DisplayName,
			minhasVagas = minhas,
			minhas = ids(s.ofertas[p]),
			deles = ids(s.ofertas[o]),
			rendaMinha = rendaDe(s.ofertas[p]),
			rendaDeles = rendaDe(s.ofertas[o]),
			euAceitei = s.aceito[p] == true,
			elesAceitaram = s.aceito[o] == true,
			faltam = if s.fechaEm then math.max(0, s.fechaEm - agora) else nil,
		})
	end
end

local function encerrar(s: Sessao, motivo: string?)
	for _, p in { s.a, s.b } do
		if sessoes[p] == s then
			sessoes[p] = nil
			evTroca:FireClient(p, nil)
			if motivo then
				ganchos.aviso(p, motivo, Color3.fromRGB(255, 200, 80))
			end
		end
	end
end

local function desmarcar(s: Sessao)
	s.aceito = {}
	s.fechaEm = nil
	s.versao += 1
end

-- Confere se a oferta ainda é válida (a Mistureba ainda está na mesma vaga e ninguém está roubando)
local function ofertaValida(p: Player, itens: { Item }): boolean
	local perfil = Dados.obter(p)
	if not perfil then
		return false
	end
	for _, item in itens do
		if perfil.criaturas[item.vaga] ~= item.id or ganchos.sendoRoubada(p, item.vaga) then
			return false
		end
	end
	return true
end

local function executar(s: Sessao)
	if s.fechando then
		return
	end
	s.fechando = true
	local pa, pb = Dados.obter(s.a), Dados.obter(s.b)
	if not pa or not pb or not ofertaValida(s.a, s.ofertas[s.a]) or not ofertaValida(s.b, s.ofertas[s.b]) then
		encerrar(s, "A troca foi cancelada porque alguma Mistureba mudou.")
		return
	end
	-- tira dos dois primeiro, depois entrega (nada é criado nem duplicado)
	local paraA, paraB = {}, {}
	for _, item in s.ofertas[s.a] do
		pa.criaturas[item.vaga] = nil
		table.insert(paraB, item.id)
	end
	for _, item in s.ofertas[s.b] do
		pb.criaturas[item.vaga] = nil
		table.insert(paraA, item.id)
	end
	local function entregar(p: Player, perfil: Dados.Perfil, ids: { string })
		for _, id in ids do
			ganchos.descobrir(p, perfil, id)
			local vaga = ganchos.vagaLivre(p, perfil)
			if vaga then
				perfil.criaturas[vaga] = id
			else
				table.insert(perfil.guardadas, id)
			end
		end
	end
	entregar(s.a, pa, paraA)
	entregar(s.b, pb, paraB)
	encerrar(s, nil)
	for _, p in { s.a, s.b } do
		ganchos.aviso(p, "Troca feita! Confira sua base.", Color3.fromRGB(120, 255, 140))
		ganchos.depois(p)
		-- salva logo para a troca não se perder se o servidor cair
		task.spawn(Dados.salvar, p)
	end
end

local function aoAceitar(p: Player, valor: any)
	local s = sessoes[p]
	if not s or s.fechando then
		return
	end
	if valor ~= true then
		desmarcar(s)
		enviar(s)
		return
	end
	if #s.ofertas[s.a] == 0 and #s.ofertas[s.b] == 0 then
		return
	end
	s.aceito[p] = true
	if s.aceito[s.a] and s.aceito[s.b] then
		s.fechaEm = workspace:GetServerTimeNow() + Troca.CONTAGEM
		local versao = s.versao
		task.delay(Troca.CONTAGEM, function()
			if sessoes[s.a] == s and s.versao == versao and s.aceito[s.a] and s.aceito[s.b] then
				executar(s)
			end
		end)
	end
	enviar(s)
end

local function aoOfertar(p: Player, vagas: any)
	local s = sessoes[p]
	if not s or s.fechando or type(vagas) ~= "table" then
		return
	end
	local perfil = Dados.obter(p)
	if not perfil then
		return
	end
	local itens: { Item } = {}
	local vistas = {}
	for _, vaga in vagas do
		if type(vaga) ~= "string" or vistas[vaga] or #itens >= Troca.MAX_ITENS then
			continue
		end
		local id = perfil.criaturas[vaga]
		if id and not ganchos.sendoRoubada(p, vaga) then
			vistas[vaga] = true
			table.insert(itens, { vaga = vaga, id = id })
		end
	end
	s.ofertas[p] = itens
	desmarcar(s)
	enviar(s)
end

local function abrir(a: Player, b: Player)
	local s: Sessao = {
		a = a,
		b = b,
		ofertas = { [a] = {}, [b] = {} },
		aceito = {},
		fechaEm = nil,
		versao = 0,
		fechando = false,
	}
	sessoes[a] = s
	sessoes[b] = s
	enviar(s)
end

local function aoPedir(de: Player, alvo: any)
	if typeof(alvo) ~= "Instance" or not alvo:IsA("Player") or alvo == de or alvo.Parent ~= Players then
		return
	end
	local agora = os.clock()
	if agora - (ultimoPedido[de] or 0) < 3 then
		return
	end
	ultimoPedido[de] = agora
	if sessoes[de] or sessoes[alvo] then
		ganchos.aviso(de, alvo.DisplayName .. " já está trocando com alguém.")
		return
	end
	if not Dados.obter(de) or not Dados.obter(alvo) then
		return
	end
	-- se o outro já tinha me pedido, abre na hora
	local meu = pedidos[de]
	if meu and meu.de == alvo and agora - meu.em < Troca.PEDIDO_EXPIRA then
		pedidos[de] = nil
		abrir(alvo, de)
		return
	end
	pedidos[alvo] = { de = de, em = agora }
	evPedido:FireClient(alvo, de)
	ganchos.aviso(de, "Pedido de troca enviado para " .. alvo.DisplayName .. ".")
end

local function aoResponder(p: Player, de: any, aceitar: any)
	local pedido = pedidos[p]
	if not pedido or pedido.de ~= de then
		return
	end
	pedidos[p] = nil
	local quem = pedido.de
	if aceitar ~= true then
		if quem.Parent == Players then
			ganchos.aviso(quem, p.DisplayName .. " não quis trocar agora.")
		end
		return
	end
	if os.clock() - pedido.em > Troca.PEDIDO_EXPIRA or quem.Parent ~= Players then
		ganchos.aviso(p, "Esse pedido de troca já expirou.")
		return
	end
	if sessoes[p] or sessoes[quem] then
		return
	end
	abrir(quem, p)
end

-- Chamado quando a base de alguém muda por fora (vendeu, fundiu, foi roubado...):
-- se a oferta deixou de valer, desmarca para ninguém aceitar algo diferente do que viu.
function Troca.conferir(p: Player)
	local s = sessoes[p]
	if not s or s.fechando then
		return
	end
	if not ofertaValida(p, s.ofertas[p]) then
		local perfil = Dados.obter(p)
		local novos = {}
		for _, item in s.ofertas[p] do
			if perfil and perfil.criaturas[item.vaga] == item.id then
				table.insert(novos, item)
			end
		end
		s.ofertas[p] = novos
		desmarcar(s)
		enviar(s)
	end
end

function Troca.emTroca(p: Player): boolean
	return sessoes[p] ~= nil
end

function Troca.iniciar(g: Ganchos)
	ganchos = g
	evTroca = remote("Troca")
	evPedido = remote("PedidoTroca")
	remote("PedirTroca").OnServerEvent:Connect(aoPedir)
	remote("ResponderTroca").OnServerEvent:Connect(aoResponder)
	remote("OfertaTroca").OnServerEvent:Connect(aoOfertar)
	remote("AceitarTroca").OnServerEvent:Connect(aoAceitar)
	remote("CancelarTroca").OnServerEvent:Connect(function(p)
		local s = sessoes[p]
		if s and not s.fechando then
			encerrar(s, p.DisplayName .. " cancelou a troca.")
		end
	end)
	Players.PlayerRemoving:Connect(function(p)
		pedidos[p] = nil
		ultimoPedido[p] = nil
		for alvo, pedido in pedidos do
			if pedido.de == p then
				pedidos[alvo] = nil
			end
		end
		local s = sessoes[p]
		if s and not s.fechando then
			encerrar(s, "A outra pessoa saiu do jogo. Troca cancelada.")
		end
	end)
end

return Troca
