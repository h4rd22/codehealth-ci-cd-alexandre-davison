--!strict
-- Todos os números do Mistureba ficam aqui. Mude aqui para balancear o jogo.

local Config = {}

------------------------------------------------------------------------
-- Raridades, da mais comum para a mais rara
------------------------------------------------------------------------
Config.OrdemRaridades = { "comum", "raro", "epico", "lendario", "mitico", "secreto" }

Config.Raridades = {
	comum = { nome = "Comum", cor = Color3.fromRGB(200, 200, 200), tamanho = 1.0 },
	raro = { nome = "Raro", cor = Color3.fromRGB(80, 170, 255), tamanho = 1.15 },
	epico = { nome = "Épico", cor = Color3.fromRGB(190, 90, 255), tamanho = 1.3 },
	lendario = { nome = "Lendário", cor = Color3.fromRGB(255, 190, 40), tamanho = 1.5 },
	mitico = { nome = "Mítico", cor = Color3.fromRGB(255, 70, 110), tamanho = 1.7 },
	secreto = { nome = "Secreto", cor = Color3.fromRGB(40, 255, 200), tamanho = 2.0 },
}

------------------------------------------------------------------------
-- As Misturebas: cada uma é a fusão de dois objetos do dia a dia.
-- renda = moedas por segundo enquanto ela está na sua base.
-- corpo/extra = peças simples usadas para montar o modelo (ver Criaturas.luau).
------------------------------------------------------------------------
export type Peca = {
	forma: string, -- "bola", "bloco", "cilindro", "cunha"
	cor: Color3,
	tamanho: Vector3,
	posicao: Vector3?, -- em relação ao centro do corpo
	material: string?,
}

export type Criatura = {
	id: string,
	nome: string,
	raridade: string,
	renda: number,
	descricao: string,
	corpo: Peca,
	extras: { Peca },
}

local function c(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

Config.Criaturas = {
	-- Comuns
	{
		id = "chaleiruga",
		nome = "Chaleiruga",
		raridade = "comum",
		renda = 1,
		descricao = "Metade chaleira, metade tartaruga. Apita quando está feliz.",
		corpo = { forma = "bola", cor = c(90, 160, 90), tamanho = Vector3.new(3, 2, 3) },
		extras = {
			{
				forma = "cilindro",
				cor = c(190, 190, 200),
				tamanho = Vector3.new(1.4, 2.2, 2.2),
				posicao = Vector3.new(0, 1.3, 0),
				material = "Metal",
			},
			{
				forma = "cilindro",
				cor = c(190, 190, 200),
				tamanho = Vector3.new(1.6, 0.4, 0.4),
				posicao = Vector3.new(1.4, 1.4, 0),
				material = "Metal",
			},
		},
	},
	{
		id = "tubarone",
		nome = "Tubarone",
		raridade = "comum",
		renda = 2,
		descricao = "Um tubarão que virou tênis de corrida. Muito rápido, pouco nadador.",
		corpo = { forma = "bloco", cor = c(240, 240, 240), tamanho = Vector3.new(3.2, 1.2, 1.6) },
		extras = {
			{
				forma = "cunha",
				cor = c(110, 130, 160),
				tamanho = Vector3.new(0.4, 1.4, 1.2),
				posicao = Vector3.new(0, 1.2, 0),
			},
			{
				forma = "bloco",
				cor = c(255, 60, 60),
				tamanho = Vector3.new(3.3, 0.3, 1.7),
				posicao = Vector3.new(0, -0.7, 0),
			},
		},
	},
	{
		id = "meiaranha",
		nome = "Meiaranha",
		raridade = "comum",
		renda = 2,
		descricao = "Uma meia listrada com oito pernas. Some sempre que você precisa dela.",
		corpo = { forma = "cilindro", cor = c(255, 120, 170), tamanho = Vector3.new(2.6, 1.4, 1.4) },
		extras = {
			{
				forma = "bloco",
				cor = c(40, 40, 40),
				tamanho = Vector3.new(0.2, 0.2, 3.6),
				posicao = Vector3.new(0.6, -0.6, 0),
			},
			{
				forma = "bloco",
				cor = c(40, 40, 40),
				tamanho = Vector3.new(0.2, 0.2, 3.6),
				posicao = Vector3.new(-0.6, -0.6, 0),
			},
		},
	},
	{
		id = "pastelossauro",
		nome = "Pastelossauro",
		raridade = "comum",
		renda = 3,
		descricao = "Um dinossauro crocante recheado de queijo.",
		corpo = { forma = "cunha", cor = c(230, 180, 90), tamanho = Vector3.new(2, 1.4, 3) },
		extras = {
			{
				forma = "bloco",
				cor = c(230, 180, 90),
				tamanho = Vector3.new(0.8, 1.6, 0.8),
				posicao = Vector3.new(0, 1.2, 1.2),
			},
		},
	},
	{
		id = "torracoelho",
		nome = "Torracoelho",
		raridade = "comum",
		renda = 4,
		descricao = "Uma torradeira com orelhas. Pula junto com o pão.",
		corpo = { forma = "bloco", cor = c(200, 200, 210), tamanho = Vector3.new(2.4, 2, 1.6), material = "Metal" },
		extras = {
			{
				forma = "bloco",
				cor = c(255, 230, 240),
				tamanho = Vector3.new(0.4, 1.6, 0.3),
				posicao = Vector3.new(0.5, 1.8, 0),
			},
			{
				forma = "bloco",
				cor = c(255, 230, 240),
				tamanho = Vector3.new(0.4, 1.6, 0.3),
				posicao = Vector3.new(-0.5, 1.8, 0),
			},
		},
	},
	-- Raras
	{
		id = "abacataoninja",
		nome = "Abacatão Ninja",
		raridade = "raro",
		renda = 12,
		descricao = "Treinou a vida toda para nunca virar guacamole.",
		corpo = { forma = "bola", cor = c(80, 140, 40), tamanho = Vector3.new(2.2, 3, 2.2) },
		extras = {
			{
				forma = "bola",
				cor = c(120, 70, 30),
				tamanho = Vector3.new(1.2, 1.2, 1.2),
				posicao = Vector3.new(0, -0.2, -0.7),
			},
			{
				forma = "bloco",
				cor = c(20, 20, 20),
				tamanho = Vector3.new(2.3, 0.4, 2.3),
				posicao = Vector3.new(0, 0.7, 0),
			},
		},
	},
	{
		id = "geladeirapirata",
		nome = "Geladeira Pirata",
		raridade = "raro",
		renda = 15,
		descricao = "Guarda tesouros gelados e nunca devolve o pudim.",
		corpo = { forma = "bloco", cor = c(235, 245, 255), tamanho = Vector3.new(2, 3.4, 1.8) },
		extras = {
			{
				forma = "cunha",
				cor = c(30, 30, 30),
				tamanho = Vector3.new(2.6, 0.8, 1.2),
				posicao = Vector3.new(0, 2.1, 0),
			},
			{
				forma = "bola",
				cor = c(30, 30, 30),
				tamanho = Vector3.new(0.6, 0.6, 0.2),
				posicao = Vector3.new(0.4, 0.8, -0.95),
			},
		},
	},
	{
		id = "polvonete",
		nome = "Polvonete",
		raridade = "raro",
		renda = 18,
		descricao = "Um polvo que é também um patinete. Oito rodinhas!",
		corpo = { forma = "bola", cor = c(200, 80, 200), tamanho = Vector3.new(2.4, 2.2, 2.4) },
		extras = {
			{
				forma = "bloco",
				cor = c(60, 60, 60),
				tamanho = Vector3.new(3.4, 0.3, 1),
				posicao = Vector3.new(0, -1.3, 0),
			},
			{
				forma = "cilindro",
				cor = c(60, 60, 60),
				tamanho = Vector3.new(0.3, 2.4, 0.3),
				posicao = Vector3.new(1.5, 0, 0),
			},
		},
	},
	{
		id = "escovadragao",
		nome = "Escovadragão",
		raridade = "raro",
		renda = 20,
		descricao = "Cospe pasta de dente em vez de fogo. Hálito de menta garantido.",
		corpo = { forma = "bloco", cor = c(60, 180, 255), tamanho = Vector3.new(3.6, 0.8, 0.8) },
		extras = {
			{
				forma = "bloco",
				cor = c(255, 255, 255),
				tamanho = Vector3.new(1.2, 1, 0.9),
				posicao = Vector3.new(1.4, 0.8, 0),
			},
			{
				forma = "cunha",
				cor = c(40, 120, 220),
				tamanho = Vector3.new(0.3, 1.4, 1.6),
				posicao = Vector3.new(-0.6, 0.9, 0),
			},
		},
	},
	-- Épicas
	{
		id = "sofassauro",
		nome = "Sofássauro",
		raridade = "epico",
		renda = 60,
		descricao = "Um T-rex em forma de sofá. Confortável, mas morde se você sentar errado.",
		corpo = { forma = "bloco", cor = c(170, 60, 50), tamanho = Vector3.new(3.4, 1.2, 1.8), material = "Fabric" },
		extras = {
			{
				forma = "bloco",
				cor = c(170, 60, 50),
				tamanho = Vector3.new(3.4, 1.6, 0.5),
				posicao = Vector3.new(0, 1.2, 0.7),
				material = "Fabric",
			},
			{
				forma = "cunha",
				cor = c(80, 160, 70),
				tamanho = Vector3.new(1, 1.2, 1.4),
				posicao = Vector3.new(1.9, 1.4, 0),
			},
		},
	},
	{
		id = "pianoceronte",
		nome = "Pianoceronte",
		raridade = "epico",
		renda = 75,
		descricao = "Toca uma nota grave a cada passo. O chão treme no ritmo.",
		corpo = { forma = "bloco", cor = c(25, 25, 30), tamanho = Vector3.new(3.4, 2, 2), material = "SmoothPlastic" },
		extras = {
			{
				forma = "bloco",
				cor = c(250, 250, 250),
				tamanho = Vector3.new(3, 0.3, 0.6),
				posicao = Vector3.new(0, 0.4, -1.2),
			},
			{
				forma = "cunha",
				cor = c(220, 220, 200),
				tamanho = Vector3.new(0.5, 1.2, 0.8),
				posicao = Vector3.new(0, 1.4, -1.1),
			},
		},
	},
	{
		id = "guardachuvalo",
		nome = "Guarda-Chuvalo",
		raridade = "epico",
		renda = 80,
		descricao = "Um cavalo que abre quando chove. Ótimo para passeios molhados.",
		corpo = { forma = "bloco", cor = c(150, 100, 60), tamanho = Vector3.new(3, 1.6, 1.2) },
		extras = {
			{
				forma = "cilindro",
				cor = c(80, 80, 255),
				tamanho = Vector3.new(0.4, 4, 4),
				posicao = Vector3.new(0, 2.4, 0),
			},
			{
				forma = "cilindro",
				cor = c(60, 60, 60),
				tamanho = Vector3.new(2, 0.2, 0.2),
				posicao = Vector3.new(0, 1.4, 0),
			},
		},
	},
	{
		id = "liquidificorvo",
		nome = "Liquidificorvo",
		raridade = "epico",
		renda = 90,
		descricao = "Bate vitamina e dá conselhos misteriosos. Croc-croc-vrrrum!",
		corpo = { forma = "cilindro", cor = c(180, 230, 255), tamanho = Vector3.new(2.8, 1.8, 1.8), material = "Glass" },
		extras = {
			{
				forma = "bola",
				cor = c(30, 30, 40),
				tamanho = Vector3.new(1.6, 1.6, 1.6),
				posicao = Vector3.new(0, 1.9, 0),
			},
			{
				forma = "cunha",
				cor = c(255, 200, 40),
				tamanho = Vector3.new(0.4, 0.5, 0.9),
				posicao = Vector3.new(0, 1.9, -1.1),
			},
		},
	},
	-- Lendárias
	{
		id = "microleao",
		nome = "Micro-Leão",
		raridade = "lendario",
		renda = 300,
		descricao = "Um leão-micro-ondas. Esquenta a comida com um rugido de 30 segundos.",
		corpo = { forma = "bloco", cor = c(220, 220, 230), tamanho = Vector3.new(3, 2, 2), material = "Metal" },
		extras = {
			{
				forma = "bola",
				cor = c(230, 140, 30),
				tamanho = Vector3.new(3.4, 3.4, 1),
				posicao = Vector3.new(0, 0.6, -1),
			},
			{
				forma = "bloco",
				cor = c(40, 40, 40),
				tamanho = Vector3.new(1.6, 1.2, 0.2),
				posicao = Vector3.new(0, 0, -1.6),
				material = "Glass",
			},
		},
	},
	{
		id = "baleiastelo",
		nome = "Baleiastelo",
		raridade = "lendario",
		renda = 400,
		descricao = "Uma baleia que carrega um castelo de areia nas costas. A maré nunca o derruba.",
		corpo = { forma = "bola", cor = c(60, 100, 200), tamanho = Vector3.new(4, 2.2, 2.4) },
		extras = {
			{
				forma = "bloco",
				cor = c(240, 210, 140),
				tamanho = Vector3.new(1.6, 1.8, 1.6),
				posicao = Vector3.new(0, 1.8, 0),
				material = "Sand",
			},
			{
				forma = "cunha",
				cor = c(240, 210, 140),
				tamanho = Vector3.new(1.6, 0.8, 1.6),
				posicao = Vector3.new(0, 3.1, 0),
				material = "Sand",
			},
		},
	},
	{
		id = "girafatrem",
		nome = "Girafatrem",
		raridade = "lendario",
		renda = 500,
		descricao = "Pescoço de girafa, corpo de trem. Sempre chega na hora, e vê tudo de cima.",
		corpo = { forma = "bloco", cor = c(240, 200, 60), tamanho = Vector3.new(3.6, 1.6, 1.6) },
		extras = {
			{
				forma = "bloco",
				cor = c(240, 200, 60),
				tamanho = Vector3.new(0.6, 3.4, 0.6),
				posicao = Vector3.new(1.4, 2.4, 0),
			},
			{
				forma = "cilindro",
				cor = c(30, 30, 30),
				tamanho = Vector3.new(0.4, 1.2, 1.2),
				posicao = Vector3.new(-1, -0.8, 0.85),
			},
		},
	},
	-- Míticas
	{
		id = "pinguivulcao",
		nome = "Pinguivulcão",
		raridade = "mitico",
		renda = 2000,
		descricao = "Um pinguim com um vulcão na cabeça. Gelado por fora, fervendo por dentro.",
		corpo = { forma = "bola", cor = c(30, 30, 40), tamanho = Vector3.new(2.4, 3.2, 2.4) },
		extras = {
			{
				forma = "bola",
				cor = c(250, 250, 250),
				tamanho = Vector3.new(1.8, 2.4, 0.8),
				posicao = Vector3.new(0, -0.2, -0.9),
			},
			{
				forma = "cunha",
				cor = c(255, 90, 20),
				tamanho = Vector3.new(1.6, 1.4, 1.6),
				posicao = Vector3.new(0, 2.2, 0),
				material = "Neon",
			},
		},
	},
	{
		id = "nuvemcornio",
		nome = "Nuvemcórnio",
		raridade = "mitico",
		renda = 2500,
		descricao = "Uma nuvem de chifre brilhante. Chove purpurina onde passa.",
		corpo = { forma = "bola", cor = c(250, 250, 255), tamanho = Vector3.new(4, 2.4, 2.6) },
		extras = {
			{
				forma = "cunha",
				cor = c(255, 120, 220),
				tamanho = Vector3.new(0.5, 1.8, 0.5),
				posicao = Vector3.new(0, 1.8, -0.8),
				material = "Neon",
			},
			{
				forma = "bola",
				cor = c(220, 230, 255),
				tamanho = Vector3.new(2, 1.6, 2),
				posicao = Vector3.new(1.4, 0.4, 0),
			},
		},
	},
	-- Secretas (só por receita de fusão)
	{
		id = "reimistureba",
		nome = "Rei Mistureba",
		raridade = "secreto",
		renda = 10000,
		descricao = "O rei de todas as misturas. Ninguém sabe do que ele é feito.",
		corpo = { forma = "bola", cor = c(255, 210, 40), tamanho = Vector3.new(3.2, 3.2, 3.2), material = "Neon" },
		extras = {
			{
				forma = "cilindro",
				cor = c(255, 230, 80),
				tamanho = Vector3.new(1, 2.6, 2.6),
				posicao = Vector3.new(0, 2.2, 0),
				material = "Metal",
			},
			{
				forma = "bola",
				cor = c(255, 40, 80),
				tamanho = Vector3.new(0.6, 0.6, 0.6),
				posicao = Vector3.new(0, 2.8, -1),
				material = "Neon",
			},
		},
	},
	{
		id = "bugigangacosmica",
		nome = "Bugiganga Cósmica",
		raridade = "secreto",
		renda = 15000,
		descricao = "Uma caixinha de peças que brilha como uma galáxia. Ainda está se montando.",
		corpo = { forma = "bloco", cor = c(40, 20, 90), tamanho = Vector3.new(3, 3, 3), material = "Neon" },
		extras = {
			{
				forma = "bola",
				cor = c(120, 220, 255),
				tamanho = Vector3.new(1.2, 1.2, 1.2),
				posicao = Vector3.new(1.8, 1.8, 0),
				material = "Neon",
			},
			{
				forma = "cunha",
				cor = c(255, 120, 255),
				tamanho = Vector3.new(1, 1, 1),
				posicao = Vector3.new(-1.8, 1.8, 0),
				material = "Neon",
			},
		},
	},
} :: { Criatura }

-- Atalho: Config.PorId["chaleiruga"]
Config.PorId = {} :: { [string]: Criatura }
for _, criatura in Config.Criaturas do
	Config.PorId[criatura.id] = criatura
end

------------------------------------------------------------------------
-- Chuva de ovos no centro do mapa
------------------------------------------------------------------------
Config.Chuva = {
	intervalo = 25, -- segundos entre uma onda e outra
	ovosPorOnda = 6,
	maxOvosNoChao = 14,
	tempoNoChao = 60, -- segundos até o ovo sumir se ninguém pegar
	pesos = { comum = 70, raro = 22, epico = 6.5, lendario = 1.3, mitico = 0.2 },
	anunciarAPartirDe = "lendario", -- ovos desta raridade em diante viram ovo dourado com anúncio
}

------------------------------------------------------------------------
-- Ovos da loja de moedas. As chances aparecem na tela antes de comprar.
------------------------------------------------------------------------
export type OvoLoja = {
	id: string,
	nome: string,
	preco: number,
	pesos: { [string]: number },
}

Config.OvosLoja = {
	{ id = "basico", nome = "Ovo Básico", preco = 100, pesos = { comum = 75, raro = 22, epico = 3 } },
	{ id = "brilhante", nome = "Ovo Brilhante", preco = 2500, pesos = { raro = 60, epico = 35, lendario = 5 } },
	{ id = "estelar", nome = "Ovo Estelar", preco = 50000, pesos = { epico = 60, lendario = 35, mitico = 5 } },
} :: { OvoLoja }

------------------------------------------------------------------------
-- Fusão: duas Misturebas da mesma raridade viram uma da raridade seguinte.
-- As secretas só saem por receita.
------------------------------------------------------------------------
Config.CustoFusao = { comum = 50, raro = 1000, epico = 15000, lendario = 120000, mitico = 1000000 }

Config.Receitas = {
	{ a = "pinguivulcao", b = "nuvemcornio", resultado = "reimistureba" },
	{ a = "baleiastelo", b = "girafatrem", resultado = "bugigangacosmica" },
}

------------------------------------------------------------------------
-- Base, cadeado e roubo
------------------------------------------------------------------------
Config.Base = {
	vagasIniciais = 8,
	vagasMaximo = 16, -- sem contar o gamepass
	melhorias = { 1000, 5000, 25000, 100000 }, -- cada uma dá +2 vagas
	vagasPorMelhoria = 2,
	cadeadoSegundos = 60,
	cadeadoEsperaSegundos = 45, -- depois que abre, quanto tempo até poder trancar de novo
	protecaoNovatoSegundos = 120, -- quem acabou de entrar não pode ser roubado
	minimoParaSerRoubado = 3, -- quem tem menos que isso não pode ser roubado
}

Config.Jogador = {
	velocidade = 18,
	velocidadeCarregando = 12,
	alcanceTapa = 9,
	esperaTapa = 1.2,
	tempoParaRoubar = 1.5, -- segurar o botão
}

------------------------------------------------------------------------
-- Robux. Os IDs ficam 0 até serem criados no Creator Hub (é grátis criar).
-- Com ID 0 o botão aparece como "em breve".
------------------------------------------------------------------------
Config.Gamepasses = {
	vip = {
		id = 0,
		nome = "VIP",
		preco = 299,
		descricao = "Dobro de moedas para sempre e nome dourado.",
	},
	cadeado = {
		id = 0,
		nome = "Cadeado Reforçado",
		preco = 149,
		descricao = "Sua porta fica trancada 90 segundos em vez de 60.",
	},
	mochila = {
		id = 0,
		nome = "Mochila Dupla",
		preco = 199,
		descricao = "Carregue 2 ovos da chuva de uma vez.",
	},
	basegrande = {
		id = 0,
		nome = "Base Grande",
		preco = 149,
		descricao = "+4 vagas na sua base.",
	},
}

Config.VipMultiplicador = 2
Config.CadeadoReforcadoSegundos = 90
Config.BaseGrandeVagas = 4

Config.Produtos = {
	sorte = {
		id = 0,
		nome = "Sorte do Servidor",
		preco = 79,
		descricao = "Ovos raros caem 2x mais para TODO o servidor por 15 minutos.",
	},
	ovoarcoiris = {
		id = 0,
		nome = "Ovo Arco-íris",
		preco = 49,
		descricao = "Um ovo pago. As chances estão logo abaixo.",
	},
	moedas = {
		id = 0,
		nome = "Saco de Moedas",
		preco = 25,
		descricao = "Ganha 10 minutos da sua renda atual (mínimo 500 moedas).",
	},
}

Config.SorteMinutos = 15
Config.SorteMultiplicadorRaros = 2
Config.OvoArcoIrisPesos = { epico = 55, lendario = 38, mitico = 7 }
Config.SacoMoedasMinutos = 10
Config.SacoMoedasMinimo = 500

return Config
