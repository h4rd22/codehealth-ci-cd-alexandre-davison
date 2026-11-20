#!/usr/bin/env python3
"""Teste de balanceamento do Mistureba.

Le os numeros direto de src/shared/Config.luau e simula jogadores (gratis e VIP)
jogando de forma ativa. Mostra moedas por segundo ao longo do tempo, quando chega
cada raridade, quando renasce, e falha (codigo 1) se alguma regra da economia for
quebrada. Rode antes de publicar:

    python3 tools/balanceamento.py

Sem dependencias: so a biblioteca padrao do Python.
"""

from __future__ import annotations

import random
import re
import statistics
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
CONFIG = (RAIZ / "src" / "shared" / "Config.luau").read_text(encoding="utf-8")

# ---------------------------------------------------------------------------
# Leitor pequeno de tabelas Lua (so o que o Config usa)
# ---------------------------------------------------------------------------
TOKEN = re.compile(
    r'\s*(?:(--\[\[.*?\]\])|(--[^\n]*)|("(?:[^"\\]|\\.)*")|([A-Za-z_][\w.]*)|'
    r"(-?\d+(?:\.\d+)?)|(::)|(.))",
    re.S,
)


def tokens(texto: str):
    for m in TOKEN.finditer(texto):
        bloco, linha, texto_, nome, numero, tipo, simbolo = m.groups()
        if bloco or linha:
            continue
        if texto_ is not None:
            yield ("s", texto_[1:-1])
        elif nome is not None:
            yield ("n", nome)
        elif numero is not None:
            yield ("#", float(numero))
        elif tipo is not None:
            yield ("::", tipo)
        elif simbolo is not None and simbolo.strip():
            yield ("p", simbolo)


class Leitor:
    def __init__(self, texto: str):
        self.t = list(tokens(texto))
        self.i = 0

    def olhar(self, k=0):
        return self.t[self.i + k] if self.i + k < len(self.t) else (None, None)

    def pegar(self):
        tok = self.olhar()
        self.i += 1
        return tok

    def valor(self):
        v = self._valor()
        if self.olhar()[0] == "::":  # "x :: { Tipo }": pula o tipo
            self.pegar()
            prof = 0
            while True:
                t, s = self.olhar()
                if t is None or (prof == 0 and s in (",", "}", ";")):
                    break
                if s in ("{", "("):
                    prof += 1
                elif s in ("}", ")"):
                    prof -= 1
                self.pegar()
        return v

    def _valor(self):
        tipo, v = self.pegar()
        if tipo == "p" and v == "{":
            return self.tabela()
        if tipo in ("s", "#"):
            return v
        if tipo == "n":
            if v in ("true", "false"):
                return v == "true"
            if v == "nil":
                return None
            # chamada tipo c(1, 2, 3) ou Vector3.new(...): ignora o conteudo
            if self.olhar() == ("p", "("):
                prof = 0
                while True:
                    _, s = self.pegar()
                    if s == "(":
                        prof += 1
                    elif s == ")":
                        prof -= 1
                        if prof == 0:
                            break
            return None
        raise ValueError(f"token inesperado {tipo} {v}")

    def tabela(self):
        lista, mapa = [], {}
        while True:
            if self.olhar() == ("p", "}"):
                self.pegar()
                break
            if self.olhar()[0] == "n" and self.olhar(1) == ("p", "="):
                chave = self.pegar()[1]
                self.pegar()
                mapa[chave] = self.valor()
            else:
                lista.append(self.valor())
            if self.olhar() in (("p", ","), ("p", ";")):
                self.pegar()
        return mapa if mapa else lista


def config(nome: str):
    m = re.search(r"^Config\." + re.escape(nome) + r"\s*=\s*", CONFIG, re.M)
    if not m:
        raise KeyError(nome)
    leitor = Leitor(CONFIG[m.end() :])
    return leitor.valor()


ORDEM = config("OrdemRaridades")
CRIATURAS = [c for c in config("Criaturas")]
POR_RARIDADE: dict[str, list[dict]] = {r: [] for r in ORDEM}
for c in CRIATURAS:
    POR_RARIDADE[c["raridade"]].append(c)
MUTACOES = config("Mutacoes")
OVOS = {o["id"]: o for o in config("OvosLoja")}
CHUVA = config("Chuva")
CUSTO_FUSAO = config("CustoFusao")
BASE = config("Base")
RENASCER = config("Renascer")
MARCOS = config("MarcosDex")
MISSOES = config("Missoes")
PRESENTE = config("PresenteTempo")
VENDA_SEG = config("VendaSegundos")
ROLETA = config("Roleta")
VIP_MULT = config("VipMultiplicador")
UPGRADES = {u["id"]: u for u in config("Upgrades")}
CLIMAS = config("Climas")
CLIMA_POR_ID = {c["id"]: c for c in CLIMAS["lista"]}


def preco_upgrade(u: dict, nivel: int) -> float:
    return int(u["precoBase"] * u["crescimento"] ** nivel)


def bonus_dex(achadas: int) -> float:
    b = 0.0
    for m in MARCOS:
        if achadas >= m["achadas"]:
            b = m["bonus"]
    return b


def sortear_peso(rng: random.Random, pesos: dict) -> str:
    ordem = [r for r in ORDEM if pesos.get(r, 0) > 0]
    alvo = rng.random() * sum(pesos[r] for r in ordem)
    for r in ordem:
        alvo -= pesos[r]
        if alvo <= 0:
            return r
    return ordem[-1]


def sortear_mut(rng: random.Random, mult: float = 1.0, clima: str | None = None) -> float:
    x = rng.random() * 100
    soma = 0.0
    extras = (CLIMA_POR_ID[clima].get("mutacao") or {}) if clima else {}
    for m in MUTACOES:  # mesma ordem do Util.sortearMutacao
        if m.get("soClima") and m["soClima"] != clima:
            continue
        soma += m["chance"] * mult * extras.get(m["id"], 1)
        if x < soma:
            return m["multiplicador"]
    return 1.0


def renda_media(raridade: str) -> float:
    lista = POR_RARIDADE[raridade]
    return sum(c["renda"] for c in lista) / len(lista)


MUT_MEDIA = 1 + sum(m["chance"] / 100 * (m["multiplicador"] - 1) for m in MUTACOES if not m.get("soClima"))


def renda_esperada_ovo(pesos: dict) -> float:
    total = sum(pesos.values())
    return sum(p / total * renda_media(r) for r, p in pesos.items()) * MUT_MEDIA


# ---------------------------------------------------------------------------
# Simulacao de um jogador ativo
# ---------------------------------------------------------------------------
class Jogador:
    def __init__(self, rng: random.Random, vip: bool):
        self.rng = rng
        self.vip = vip
        self.moedas = 0.0
        self.base: list[tuple[str, float, str]] = [("comum", 1.0, "chaleiruga")]
        self.melhorias = 0
        self.renasc = 0
        self.dex = {"chaleiruga"}
        self.ganho_extra = 0.0  # moedas que vieram de premios (missao, roleta...)
        self.ganho_total = 0.0
        self.primeira: dict[str, float] = {}
        self.renasceu_em: list[float] = []
        self.upgrades = {k: 0 for k in UPGRADES}  # nao somem ao renascer
        self.gasto_upgrades = 0.0
        self.clima: str | None = None

    def vagas(self) -> int:
        return BASE["vagasIniciais"] + self.melhorias * BASE["vagasPorMelhoria"]

    def renda(self) -> float:
        total = sum(r for _, r, _ in self.base)
        if self.vip:
            total *= VIP_MULT
        total *= 1 + self.renasc * RENASCER["bonusPorRenascimento"]
        total *= 1 + bonus_dex(len(self.dex))
        total *= 1 + self.upgrades["renda"] * UPGRADES["renda"]["porNivel"]
        return total

    def ganhar(self, raridade: str, t: float):
        c = self.rng.choice(POR_RARIDADE[raridade])
        r = c["renda"] * sortear_mut(self.rng, 1 + self.upgrades["sorte"] * UPGRADES["sorte"]["porNivel"], self.clima)
        self.dex.add(c["id"])
        self.primeira.setdefault(raridade, t)
        if len(self.base) < self.vagas():
            self.base.append((raridade, r, c["id"]))
        else:
            # base cheia: troca pela mais fraca se for melhor (vende a fraca)
            fraca = min(range(len(self.base)), key=lambda i: self.base[i][1])
            if r > self.base[fraca][1]:
                self.moedas += self.base[fraca][1] * VENDA_SEG
                self.base[fraca] = (raridade, r, c["id"])

    def premio(self, valor: float):
        self.moedas += valor
        self.ganho_extra += valor
        self.ganho_total += valor

    def fundir(self, t: float):
        # funde o par mais fraco da mesma raridade quando a base esta cheia
        if len(self.base) < self.vagas():
            return
        for raridade in ORDEM[:-2]:
            iguais = sorted((i for i, b in enumerate(self.base) if b[0] == raridade), key=lambda i: self.base[i][1])
            custo = CUSTO_FUSAO.get(raridade, 0)
            if len(iguais) >= 2 and self.moedas >= custo * 2:
                self.moedas -= custo
                a, b = iguais[0], iguais[1]
                for i in sorted((a, b), reverse=True):
                    self.base.pop(i)
                prox = ORDEM[ORDEM.index(raridade) + 1]
                c = self.rng.choice(POR_RARIDADE[prox])
                self.dex.add(c["id"])
                self.primeira.setdefault(prox, t)
                self.base.append((prox, c["renda"], c["id"]))
                return

    def comprar(self, t: float):
        # melhora a base se custar menos que 3 minutos de renda
        precos = BASE["melhorias"]
        if self.melhorias < len(precos) and self.moedas >= precos[self.melhorias] and precos[self.melhorias] < self.renda() * 180 + 2000:
            self.moedas -= precos[self.melhorias]
            self.melhorias += 1
        # renasce assim que der
        preco_r = RENASCER["precoBase"] * RENASCER["crescimento"] ** self.renasc
        if self.moedas >= preco_r:
            self.moedas = 0
            self.base = [("comum", 1.0, "chaleiruga")]
            self.melhorias = 0
            self.renasc += 1
            self.renasceu_em.append(t)
            return
        # melhorias permanentes: jogador guloso compra quando custa menos que 4 min de renda
        for uid in ("renda", "sorte"):
            u = UPGRADES[uid]
            nivel = self.upgrades[uid]
            if nivel < u["max"]:
                preco = preco_upgrade(u, nivel)
                if self.moedas >= preco and preco < self.renda() * 240:
                    self.moedas -= preco
                    self.gasto_upgrades += preco
                    self.upgrades[uid] += 1
                    return
        # compra o ovo mais caro que valer a pena (renda esperada > a mais fraca da base)
        fraca = min(b[1] for b in self.base) if len(self.base) >= self.vagas() else 0
        for ovo in sorted(OVOS.values(), key=lambda o: -o["preco"]):
            if self.moedas >= ovo["preco"] and renda_esperada_ovo(ovo["pesos"]) > fraca * 1.2:
                self.moedas -= ovo["preco"]
                self.ganhar(sortear_peso(self.rng, ovo["pesos"]), t)
                return
        self.fundir(t)


def simular(seed: int, vip: bool, horas: float, marcos: list[int]):
    rng = random.Random(seed)
    j = Jogador(rng, vip)
    fotos = {}
    presentes = 0
    missoes_feitas = 0
    segundos = int(horas * 3600)
    ciclo = CLIMAS["intervalo"] + CLIMAS["duracao"]
    total_peso = sum(c["peso"] for c in CLIMAS["lista"])
    proxima_chuva = 30.0
    for t in range(1, segundos + 1):
        # clima: comeca 15 min depois de entrar e dura 3 min, sorteado por peso
        fase = t % ciclo
        if fase == CLIMAS["intervalo"]:
            alvo = rng.random() * total_peso
            for c in CLIMAS["lista"]:
                alvo -= c["peso"]
                if alvo <= 0:
                    j.clima = c["id"]
                    break
        elif fase == 0:
            j.clima = None
        ganho = j.renda()
        j.moedas += ganho
        j.ganho_total += ganho
        # chuva: um ovo pego e levado para a base a cada 30 s
        if t >= proxima_chuva:
            clima = CLIMA_POR_ID.get(j.clima) if j.clima else None
            proxima_chuva = t + 30 / (clima["chuvaMais"] if clima else 1)
            pesos = dict(CHUVA["pesos"])
            if clima:
                pesos = {r: p * (clima["raros"] if r != "comum" else 1) for r, p in pesos.items()}
            j.ganhar(sortear_peso(rng, pesos), t)
        if t % PRESENTE["intervalo"] == 0:
            presentes += 1
            ovo = PRESENTE["ovoEspecial"] if presentes % PRESENTE["especialACada"] == 0 else PRESENTE["ovo"]
            j.ganhar(sortear_peso(rng, OVOS[ovo]["pesos"]), t)
        # roleta gratis
        if t == 1 or t % ROLETA["intervalo"] == 0:
            premio = ROLETA["premios"][0]
            alvo = rng.random() * sum(p["peso"] for p in ROLETA["premios"])
            for p in ROLETA["premios"]:
                alvo -= p["peso"]
                if alvo <= 0:
                    premio = p
                    break
            if premio.get("segundos"):
                j.premio(max(premio.get("minimo", 0), j.renda() * premio["segundos"]))
            elif premio.get("ovo"):
                j.ganhar(sortear_peso(rng, OVOS[premio["ovo"]]["pesos"]), t)
        # missoes: uma a cada 15 min na primeira hora (3 por dia)
        if missoes_feitas < MISSOES["porDia"] and t % 900 == 0:
            missoes_feitas += 1
            j.premio(max(MISSOES["premioMinimo"], j.renda() * MISSOES["premioSegundos"]))
            if missoes_feitas == MISSOES["porDia"]:
                j.ganhar(sortear_peso(rng, OVOS[MISSOES["ovoFinal"]]["pesos"]), t)
        if t % 2 == 0:
            j.comprar(t)
        if t in marcos:
            fotos[t] = (j.renda(), len(j.dex), j.renasc)
    return j, fotos


def minutos(s: float | None) -> str:
    if s is None:
        return "  nunca"
    return f"{s / 60:6.1f}m"


def main() -> int:
    marcos = [300, 900, 1800, 3600, 7200, 4 * 3600]
    horas = 4
    rodadas = 40
    falhas: list[str] = []

    print("== Mistureba: teste de balanceamento ==")
    print(f"{len(CRIATURAS)} Misturebas, {len(OVOS)} ovos na loja, {rodadas} jogadores simulados por tipo, {horas}h cada\n")

    # 1) Vender nunca pode dar lucro em relacao ao preco do ovo (senao vira maquina de moedas)
    print("Ovo            preco   renda esperada/s   venda esperada   paga em")
    for ovo in OVOS.values():
        r = renda_esperada_ovo(ovo["pesos"])
        venda = r * VENDA_SEG
        print(f"{ovo['nome']:<14}{ovo['preco']:>7.0f}   {r:>14.1f}   {venda:>14.1f}   {ovo['preco'] / r:>6.0f}s")
        if venda > ovo["preco"] * 0.6:
            falhas.append(f"vender {ovo['nome']} devolve {venda:.0f} de {ovo['preco']:.0f} (mais de 60%): compra e venda vira lucro")
    print()

    resultados = {}
    for vip in (False, True):
        rendas = {m: [] for m in marcos}
        dexs = {m: [] for m in marcos}
        prim = {r: [] for r in ORDEM}
        renasc = []
        nrenasc = []
        extra = []
        niveis = {k: [] for k in UPGRADES}
        for seed in range(rodadas):
            j, fotos = simular(seed, vip, horas, marcos)
            for m in marcos:
                rendas[m].append(fotos[m][0])
                dexs[m].append(fotos[m][1])
            for r in ORDEM:
                prim[r].append(j.primeira.get(r))
            renasc.append(j.renasceu_em[0] if j.renasceu_em else None)
            nrenasc.append(len(j.renasceu_em))
            extra.append(j.ganho_extra / max(1, j.ganho_total))
            for k in UPGRADES:
                niveis[k].append(j.upgrades[k])
        nome = "VIP" if vip else "Gratis"
        print(f"-- Jogador {nome} --")
        print("tempo    renda/s (mediana)   Dex")
        for m in marcos:
            print(f"{m / 60:5.0f}m  {statistics.median(rendas[m]):>14,.0f}   {statistics.median(dexs[m]):>4.0f}")

        def mediana_tempo(lista):
            ok = sorted(x for x in lista if x is not None)
            if len(ok) * 2 < len(lista):
                return None
            return ok[len(lista) // 2] if len(lista) // 2 < len(ok) else ok[-1]

        for r in ORDEM[1:]:
            print(f"primeira {r:<9} {minutos(mediana_tempo(prim[r]))}")
        print(f"1o renascimento    {minutos(mediana_tempo(renasc))}")
        print(f"renascimentos em {horas}h: {statistics.median(nrenasc):.0f}")
        print(f"premios (missao/roleta) = {statistics.mean(extra) * 100:.1f}% de todas as moedas")
        print("melhorias em " + str(horas) + "h: " + ", ".join(f"{k} {statistics.median(v):.0f}/{UPGRADES[k]['max']}" for k, v in niveis.items()) + "\n")
        resultados[nome] = {
            "renda": {m: statistics.median(rendas[m]) for m in marcos},
            "prim": {r: mediana_tempo(prim[r]) for r in ORDEM},
            "renasc": mediana_tempo(renasc),
            "extra": statistics.mean(extra),
            "niveis": {k: statistics.median(v) for k, v in niveis.items()},
        }

    g, v = resultados["Gratis"], resultados["VIP"]

    # 2) Curva de progressao: coisa boa logo no comeco, mas sem acabar o jogo rapido
    def antes(rotulo, valor, limite):
        if valor is None or valor > limite:
            falhas.append(f"{rotulo}: {minutos(valor).strip()} (deveria ser antes de {limite / 60:.0f}m)")

    def depois(rotulo, valor, limite):
        if valor is not None and valor < limite:
            falhas.append(f"{rotulo}: {minutos(valor).strip()} (cedo demais, minimo {limite / 60:.0f}m)")

    antes("primeira Epica (gratis)", g["prim"]["epico"], 10 * 60)
    antes("primeira Lendaria (gratis)", g["prim"]["lendario"], 60 * 60)
    depois("primeira Lendaria (gratis)", g["prim"]["lendario"], 5 * 60)
    depois("primeira Mitica (gratis)", g["prim"]["mitico"], 12 * 60)
    depois("1o renascimento (gratis)", g["renasc"], 40 * 60)
    antes("1o renascimento (gratis)", g["renasc"], 4 * 3600)
    depois("1o renascimento (VIP)", v["renasc"], 20 * 60)

    # 3) Premios gratis ajudam mas nao viram a fonte principal de moedas
    if g["extra"] > 0.2:
        falhas.append(f"premios dao {g['extra'] * 100:.0f}% das moedas (maximo 20%)")

    # 4) VIP ajuda, mas nao deixa o jogo injusto para quem nao paga:
    #    o VIP pode chegar no renascimento no maximo 2,5x mais rapido
    if g["renasc"] and v["renasc"] and g["renasc"] / v["renasc"] > 2.5:
        falhas.append(f"VIP renasce {g['renasc'] / v['renasc']:.1f}x mais rapido que gratis (maximo 2,5x)")

    # 5) Melhorias sao um objetivo longo: ninguem fecha Renda Turbo ou Trevo em 4h
    for k in ("renda", "sorte"):
        for nome, r in (("gratis", g), ("VIP", v)):
            if r["niveis"][k] >= UPGRADES[k]["max"]:
                falhas.append(f"{UPGRADES[k]['nome']} chega no maximo em {horas}h ({nome}): fica sem objetivo")

    if falhas:
        print("FALHOU o balanceamento:")
        for f in falhas:
            print(" -", f)
        return 1
    print("OK: economia balanceada.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
