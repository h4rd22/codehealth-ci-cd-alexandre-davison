# Gera as peças anime dos itens (katana, cajado, arco, armadura, elmo) em 3 formatos:
# A = tiers baixos, B = tiers médios, C = tiers altos. Cada peça é um objeto separado
# (o Roblox pinta cada uma na cor da raridade). Exporta um FBX único e uma prévia PNG.
import bpy, bmesh, math, sys, os
from mathutils import Vector, Matrix

SAIDA = r"D:\Claude\jogo-roblox\modelos\prontos"
PREVIA = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else os.path.join(SAIDA, "previa.png")

bpy.ops.wm.read_factory_settings(use_empty=True)
cena = bpy.context.scene


def obj_de_bm(nome, bm, cor=(0.8, 0.8, 0.8, 1), deslocar=(0, 0, 0)):
    me = bpy.data.meshes.new(nome)
    bm.normal_update()
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = False
    ob = bpy.data.objects.new(nome, me)
    ob.location = deslocar
    mat = bpy.data.materials.new(nome + "_m")
    mat.diffuse_color = cor
    me.materials.append(mat)
    cena.collection.objects.link(ob)
    return ob


def loft(secoes, fechar_inicio=True, fechar_fim=True):
    """secoes: lista de listas de Vector (mesmo nº de pontos), forma um tubo/lâmina."""
    bm = bmesh.new()
    aneis = [[bm.verts.new(p) for p in s] for s in secoes]
    n = len(secoes[0])
    for a, b in zip(aneis, aneis[1:]):
        for i in range(n):
            j = (i + 1) % n
            bm.faces.new((a[i], a[j], b[j], b[i]))
    if fechar_inicio:
        bm.faces.new(list(reversed(aneis[0])))
    if fechar_fim:
        bm.faces.new(aneis[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bm


def contorno_extrudado(pontos2d, espessura, plano="XY", z0=0.0):
    """polígono 2D (x, y) extrudado na espessura; plano XY = normal Z."""
    sec_a, sec_b = [], []
    for x, y in pontos2d:
        if plano == "XY":
            sec_a.append(Vector((x, y, z0 - espessura / 2)))
            sec_b.append(Vector((x, y, z0 + espessura / 2)))
        else:  # XZ: normal Y
            sec_a.append(Vector((x, -espessura / 2, y + z0)))
            sec_b.append(Vector((x, espessura / 2, y + z0)))
    return loft([sec_a, sec_b])


def tubo(caminho, raio_fn, lados=8, fechar=True):
    secoes = []
    for i, p in enumerate(caminho):
        t = i / (len(caminho) - 1)
        a = caminho[max(i - 1, 0)]
        b = caminho[min(i + 1, len(caminho) - 1)]
        d = (b - a).normalized()
        ref = Vector((0, 0, 1)) if abs(d.z) < 0.9 else Vector((1, 0, 0))
        u = d.cross(ref).normalized()
        v = d.cross(u).normalized()
        r = raio_fn(t)
        secoes.append([p + (u * math.cos(k / lados * 2 * math.pi) + v * math.sin(k / lados * 2 * math.pi)) * r for k in range(lados)])
    return loft(secoes, fechar, fechar)


def chanfrar(bm, largura=0.02):
    bmesh.ops.bevel(bm, geom=list(bm.edges), offset=largura, segments=1, affect="EDGES", clamp_overlap=True)
    return bm


def referencia(nome):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=0.05)
    return obj_de_bm(nome + "_ref", bm, (1, 0, 1, 1))


# ---------------------------------------------------------------- KATANA
# lâmina em Z+ (fio em +X, costas em -X), guarda em z=0, cabo em Z-
def lamina(nome, L, w0, w1, curva, serrilha=0, larga_ponta=0.0):
    secoes, fio = [], []
    N = 24
    for i in range(N + 1):
        t = i / N
        z = L * t
        w = w0 + (w1 - w0) * t + larga_ponta * math.sin(t * math.pi) * 0.5
        xc = -curva * t * t
        esp = 0.09 * (1 - 0.5 * t)
        costas = -w / 2
        if serrilha and 0.15 < t < 0.8 and i % 2 == 0:
            costas -= serrilha
        if i == N:  # ponta inclinada (kissaki)
            secoes.append([Vector((xc - w * 0.1, 0, z + 0.25))] * 4)
            break
        secoes.append([
            Vector((xc + w / 2, 0, z)),
            Vector((xc + w * 0.05, esp, z)),
            Vector((xc + costas, esp * 0.6, z)),
            Vector((xc + costas, -esp * 0.6, z)),
        ][:2] + [Vector((xc + costas, 0, z))] + [Vector((xc + w * 0.05, -esp, z))])
        fio.append((xc + w / 2, z, w))
    bm = loft(secoes, True, False)
    obj_de_bm(nome + "_lamina", bm, (0.85, 0.88, 0.95, 1))
    # fio (tira de luz no lado de corte)
    s1, s2, s3, s4 = [], [], [], []
    tiras = []
    for (x, z, w) in fio:
        tiras.append([Vector((x + 0.015, 0, z)), Vector((x - 0.07, 0.03, z)), Vector((x - 0.07, -0.03, z))])
    tiras.append([Vector((fio[-1][0] - 0.05, 0, L + 0.2))] * 3)
    obj_de_bm(nome + "_fio", loft(tiras, True, False), (0.3, 0.9, 1, 1))


def cabo(nome, comprimento=1.35, raio=0.12):
    caminho = [Vector((0, 0, -comprimento * i / 20)) for i in range(21)]
    obj_de_bm(nome + "_cabo", tubo(caminho, lambda t: raio * (1.0 if int(t * 20) % 2 == 0 else 0.86), 8), (0.15, 0.1, 0.1, 1))
    # pomo
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=10, v_segments=6, radius=raio * 1.35)
    bmesh.ops.translate(bm, verts=bm.verts, vec=(0, 0, -comprimento - 0.08))
    obj_de_bm(nome + "_pomo", bm, (1, 0.8, 0.2, 1))


def guarda(nome, forma):
    pts = []
    for k in range(48):
        a = k / 48 * 2 * math.pi
        if forma == "A":
            r = 0.42
        elif forma == "B":
            r = 0.36 + 0.12 * abs(math.cos(2 * a)) ** 0.6
        else:
            r = 0.32 + 0.55 * abs(math.cos(a)) ** 6 + 0.08 * abs(math.sin(3 * a))
        pts.append((r * math.cos(a), r * math.sin(a)))
    bm = contorno_extrudado(pts, 0.12)
    chanfrar(bm, 0.015)
    obj_de_bm(nome + "_guarda", bm, (0.9, 0.7, 0.2, 1))


def katana(nome, forma):
    referencia(nome)
    if forma == "A":
        lamina(nome, 3.6, 0.32, 0.26, 0.25)
    elif forma == "B":
        lamina(nome, 3.9, 0.4, 0.3, 0.35, serrilha=0.0, larga_ponta=0.1)
    else:
        lamina(nome, 4.2, 0.5, 0.34, 0.45, serrilha=0.1, larga_ponta=0.18)
    guarda(nome, forma)
    cabo(nome, 1.35 if forma != "C" else 1.5)


# ---------------------------------------------------------------- CAJADO
def cajado(nome, forma):
    referencia(nome)
    altura = 5.4
    caminho = [Vector((0, 0, -1.2 + altura * i / 30)) for i in range(31)]
    torcido = lambda t: 0.11 * (1.0 + 0.18 * math.sin(t * 60))
    obj_de_bm(nome + "_haste", tubo(caminho, torcido, 6), (0.35, 0.22, 0.12, 1))
    topo = Vector((0, 0, altura - 1.2 + 0.55))
    # cristal (bipirâmide hexagonal)
    bm = bmesh.new()
    alto, raio = 0.75 if forma != "C" else 1.0, 0.3 if forma != "C" else 0.38
    meio = [bm.verts.new(topo + Vector((raio * math.cos(k / 6 * 2 * math.pi), raio * math.sin(k / 6 * 2 * math.pi), 0))) for k in range(6)]
    cima = bm.verts.new(topo + Vector((0, 0, alto)))
    baixo = bm.verts.new(topo + Vector((0, 0, -alto * 0.6)))
    for k in range(6):
        bm.faces.new((meio[k], meio[(k + 1) % 6], cima))
        bm.faces.new((meio[(k + 1) % 6], meio[k], baixo))
    obj_de_bm(nome + "_cristal", bm, (0.5, 0.9, 1, 1))
    # cabeça: A = meia-lua, B = garras, C = asas + auréola
    if forma == "A":
        arco_pts = [topo + Vector((0.62 * math.cos(a), 0, 0.62 * math.sin(a))) for a in [math.radians(-200 + 220 * i / 20) for i in range(21)]]
        obj_de_bm(nome + "_cabeca", tubo(arco_pts, lambda t: 0.07 + 0.04 * math.sin(t * math.pi), 6), (0.9, 0.7, 0.2, 1))
    elif forma == "B":
        bm_total = bmesh.new()
        for k in range(3):
            a = k / 3 * 2 * math.pi
            pts = [topo + Vector((0, 0, -0.45)) + Vector((math.cos(a) * 0.55 * math.sin(t * 2.4), math.sin(a) * 0.55 * math.sin(t * 2.4), 1.25 * t)) for t in [i / 12 for i in range(13)]]
            parte = tubo(pts, lambda t: 0.08 * (1 - t) + 0.01, 6)
            me = bpy.data.meshes.new("tmp")
            parte.to_mesh(me)
            bm_total.from_mesh(me)
            bpy.data.meshes.remove(me)
        obj_de_bm(nome + "_cabeca", bm_total, (0.9, 0.7, 0.2, 1))
    else:
        asa = []
        for k in range(30):
            t = k / 29
            asa.append((0.25 + 1.1 * t, 0.15 + 0.7 * math.sin(t * math.pi * 0.8) - 0.35 * t * t))
        for k in range(29, -1, -1):
            t = k / 29
            asa.append((0.25 + 1.1 * t, 0.15 + 0.7 * math.sin(t * math.pi * 0.8) - 0.35 * t * t - (0.28 - 0.18 * t) - 0.12 * (k % 6 == 0)))
        for lado, sufixo in ((1, "asaD"), (-1, "asaE")):
            pts = [(x * lado, y) for x, y in asa]
            if lado < 0:
                pts.reverse()
            obj_de_bm(nome + "_" + sufixo, contorno_extrudado(pts, 0.06, "XZ", topo.z - 0.3), (1, 1, 1, 1))
        anel_pts = [topo + Vector((0, 0.0, 0.25)) + Vector((0.85 * math.cos(a), 0.25, 0.85 * math.sin(a))) for a in [2 * math.pi * i / 32 for i in range(33)]]
        obj_de_bm(nome + "_cabeca", tubo(anel_pts, lambda t: 0.05, 6), (0.9, 0.7, 0.2, 1))
    # anel na haste
    bm = tubo([Vector((0, 0, topo.z - 0.65)), Vector((0, 0, topo.z - 0.45))], lambda t: 0.17, 10)
    obj_de_bm(nome + "_anel", bm, (0.9, 0.7, 0.2, 1))


# ---------------------------------------------------------------- ARCO
def arco(nome, forma):
    referencia(nome)
    H = 2.8
    def ponto(t):  # t de -1 (ponta de baixo) a 1 (ponta de cima)
        z = H * t
        x = -0.55 * (1 - t * t) + 0.22 * abs(t) ** 6  # curva com recurva nas pontas
        return Vector((x, 0, z))
    pts = [ponto(-1 + 2 * i / 40) for i in range(41)]
    larg = lambda t: 0.09 + 0.07 * math.sin(t * math.pi)
    obj_de_bm(nome + "_corpo", tubo(pts, larg, 6), (0.4, 0.25, 0.12, 1))
    # corda
    obj_de_bm(nome + "_corda", tubo([ponto(-0.985), ponto(0.985)], lambda t: 0.015, 4), (1, 1, 1, 1))
    # pegada
    obj_de_bm(nome + "_pegada", tubo([ponto(-0.12) + Vector((-0.02, 0, 0)), ponto(0.12) + Vector((-0.02, 0, 0))], lambda t: 0.16, 8), (0.15, 0.1, 0.1, 1))
    # lâminas nas costas (B) e penas/asas (C)
    if forma in ("B", "C"):
        bm_total = bmesh.new()
        for s in (-1, 1):
            for k in range(2 if forma == "B" else 4):
                t = s * (0.3 + 0.18 * k)
                p = ponto(t)
                tam = 0.55 if forma == "B" else 0.75 - 0.08 * k
                tri = [(p.x - 0.05, p.z), (p.x - 0.05 - tam, p.z + s * tam * 0.6), (p.x - 0.05, p.z + s * 0.28)]
                parte = contorno_extrudado(tri if s > 0 else list(reversed(tri)), 0.05, "XZ")
                me = bpy.data.meshes.new("tmp")
                parte.to_mesh(me)
                bm_total.from_mesh(me)
                bpy.data.meshes.remove(me)
        obj_de_bm(nome + "_laminas", bm_total, (0.9, 0.7, 0.2, 1))
    # gemas nas pontas
    bm = bmesh.new()
    for t in (-1, 1):
        g = bmesh.new()
        bmesh.ops.create_icosphere(g, subdivisions=1, radius=0.13)
        bmesh.ops.translate(g, verts=g.verts, vec=ponto(t * 0.99))
        me = bpy.data.meshes.new("tmp")
        g.to_mesh(me)
        bm.from_mesh(me)
        bpy.data.meshes.remove(me)
        g.free()
    obj_de_bm(nome + "_gemas", bm, (0.5, 0.9, 1, 1))


# ---------------------------------------------------------------- ARMADURA (peitoral + ombreiras)
def armadura(nome, forma):
    referencia(nome)
    # peitoral: casco chanfrado um pouco maior que o tronco (2 x 2 x 1)
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1)
    bmesh.ops.scale(bm, vec=(2.2, 1.25, 1.55), verts=bm.verts)
    bmesh.ops.translate(bm, verts=bm.verts, vec=(0, 0, 0.2))
    chanfrar(bm, 0.18)
    obj_de_bm(nome + "_peito", bm, (0.6, 0.6, 0.7, 1))
    # placas do peito (2 em ângulo) e abdômen em faixas
    bm = bmesh.new()
    for s in (-1, 1):
        pl = bmesh.new()
        bmesh.ops.create_cube(pl, size=1)
        bmesh.ops.scale(pl, vec=(0.95, 0.12, 0.7), verts=pl.verts)
        bmesh.ops.rotate(pl, verts=pl.verts, cent=(0, 0, 0), matrix=Matrix.Rotation(math.radians(-12 * s), 3, "Z"))
        bmesh.ops.translate(pl, verts=pl.verts, vec=(0.5 * s, -0.66, 0.45))
        chanfrar(pl, 0.05)
        me = bpy.data.meshes.new("tmp"); pl.to_mesh(me); bm.from_mesh(me); bpy.data.meshes.remove(me); pl.free()
    for k in range(3):
        pl = bmesh.new()
        bmesh.ops.create_cube(pl, size=1)
        bmesh.ops.scale(pl, vec=(1.5 - k * 0.12, 0.1, 0.2), verts=pl.verts)
        bmesh.ops.translate(pl, verts=pl.verts, vec=(0, -0.64, -0.12 - k * 0.24))
        chanfrar(pl, 0.03)
        me = bpy.data.meshes.new("tmp"); pl.to_mesh(me); bm.from_mesh(me); bpy.data.meshes.remove(me); pl.free()
    obj_de_bm(nome + "_placas", bm, (0.9, 0.7, 0.2, 1))
    # gola
    gola = [Vector((0.6 * math.cos(a), 0.45 * math.sin(a), 1.0)) for a in [math.radians(200 + 140 * i / 16) for i in range(17)]]
    obj_de_bm(nome + "_gola", tubo(gola, lambda t: 0.12, 6), (0.9, 0.7, 0.2, 1))
    # joia do peito
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=1, radius=0.2 if forma == "A" else 0.27)
    bmesh.ops.translate(bm, verts=bm.verts, vec=(0, -0.72, 0.6))
    obj_de_bm(nome + "_joia", bm, (0.5, 0.9, 1, 1))
    # ombreira direita (o Roblox espelha para a esquerda)
    bm = bmesh.new()
    camadas = 2 if forma == "A" else (3 if forma == "B" else 4)
    for k in range(camadas):
        c = bmesh.new()
        bmesh.ops.create_uvsphere(c, u_segments=12, v_segments=6, radius=0.62 - k * 0.08)
        bmesh.ops.delete(c, geom=[v for v in c.verts if v.co.z < -0.05], context="VERTS")
        bmesh.ops.scale(c, vec=(1.15, 1.0, 0.75), verts=c.verts)
        bmesh.ops.translate(c, verts=c.verts, vec=(1.35 + k * 0.05, 0, 0.75 - k * 0.22))
        me = bpy.data.meshes.new("tmp"); c.to_mesh(me); bm.from_mesh(me); bpy.data.meshes.remove(me); c.free()
    obj_de_bm(nome + "_ombro", bm, (0.6, 0.6, 0.7, 1))
    if forma != "A":
        # espinhos/chifres na ombreira
        bm = bmesh.new()
        for k in range(2 if forma == "B" else 3):
            e = bmesh.new()
            bmesh.ops.create_cone(e, cap_ends=True, segments=5, radius1=0.13, radius2=0.0, depth=0.6 + 0.15 * k)
            bmesh.ops.rotate(e, verts=e.verts, cent=(0, 0, 0), matrix=Matrix.Rotation(math.radians(-35), 3, "Y"))
            bmesh.ops.translate(e, verts=e.verts, vec=(1.45 + k * 0.12, -0.2 + k * 0.2, 1.15))
            me = bpy.data.meshes.new("tmp"); e.to_mesh(me); bm.from_mesh(me); bpy.data.meshes.remove(me); e.free()
        obj_de_bm(nome + "_espinhos", bm, (0.9, 0.7, 0.2, 1))


# ---------------------------------------------------------------- ELMO (cabeça ~ cubo de 1.2)
def elmo(nome, forma):
    referencia(nome)
    if forma == "A":
        # bandana ninja: faixa em volta da testa com placa de metal e duas pontas soltas atrás
        faixa = [Vector((0.66 * math.cos(a), 0.66 * math.sin(a), 0.32)) for a in [2 * math.pi * i / 24 for i in range(25)]]
        obj_de_bm(nome + "_faixa", tubo(faixa, lambda t: 0.1, 4), (0.15, 0.15, 0.3, 1))
        bm = bmesh.new()
        bmesh.ops.create_cube(bm, size=1)
        bmesh.ops.scale(bm, vec=(0.75, 0.08, 0.32), verts=bm.verts)
        bmesh.ops.translate(bm, verts=bm.verts, vec=(0, -0.68, 0.32))
        chanfrar(bm, 0.04)
        obj_de_bm(nome + "_placa", bm, (0.75, 0.78, 0.85, 1))
        bm = bmesh.new()
        for s in (-1, 1):
            fita = [(0.1 * s, 0.32), (0.25 * s + 0.05, -0.4), (0.35 * s, -0.75), (0.22 * s, -0.72), (0.0, 0.25)]
            parte = contorno_extrudado(fita if s > 0 else list(reversed(fita)), 0.03, "XZ")
            bmesh.ops.translate(parte, verts=parte.verts, vec=(0, 0.68, 0))
            me = bpy.data.meshes.new("tmp"); parte.to_mesh(me); bm.from_mesh(me); bpy.data.meshes.remove(me); parte.free()
        obj_de_bm(nome + "_fitas", bm, (0.15, 0.15, 0.3, 1))
        return
    # B/C: elmo samurai aberto na frente (kabuto) com crista
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=16, v_segments=8, radius=0.78)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.z < 0.0], context="VERTS")
    bmesh.ops.translate(bm, verts=bm.verts, vec=(0, 0.05, 0.2))
    obj_de_bm(nome + "_casco", bm, (0.6, 0.6, 0.7, 1))
    # aba / protetor de nuca em lâminas
    bm = bmesh.new()
    for k in range(3):
        aba = [Vector(((0.85 + k * 0.08) * math.cos(a), (0.85 + k * 0.08) * math.sin(a) + 0.05, 0.15 - k * 0.15)) for a in [math.radians(-20 + 220 * i / 16) for i in range(17)]]
        parte = tubo(aba, lambda t: 0.06, 4)
        me = bpy.data.meshes.new("tmp"); parte.to_mesh(me); bm.from_mesh(me); bpy.data.meshes.remove(me); parte.free()
    obj_de_bm(nome + "_abas", bm, (0.9, 0.7, 0.2, 1))
    # crista: meia-lua (B) ou coroa de chifres longos (C)
    if forma == "B":
        pts = [Vector((1.0 * math.cos(a), -0.72, 0.85 + 0.9 * math.sin(a))) for a in [math.radians(15 + 150 * i / 20) for i in range(21)]]
        obj_de_bm(nome + "_crista", tubo(pts, lambda t: 0.04 + 0.06 * math.sin(t * math.pi), 6), (1, 0.85, 0.3, 1))
    else:
        bm = bmesh.new()
        for s in (-1, 1):
            pts = [Vector((s * (0.35 + 0.9 * t), -0.5 + 0.1 * t, 0.7 + 1.3 * t - 0.5 * t * t)) for t in [i / 14 for i in range(15)]]
            parte = tubo(pts, lambda t: 0.12 * (1 - t) + 0.01, 6)
            me = bpy.data.meshes.new("tmp"); parte.to_mesh(me); bm.from_mesh(me); bpy.data.meshes.remove(me); parte.free()
        obj_de_bm(nome + "_crista", bm, (1, 0.85, 0.3, 1))
    # joia da testa
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=1, radius=0.16)
    bmesh.ops.translate(bm, verts=bm.verts, vec=(0, -0.78, 0.6))
    obj_de_bm(nome + "_joia", bm, (0.5, 0.9, 1, 1))


for forma in ("A", "B", "C"):
    katana("katana" + forma, forma)
    cajado("cajado" + forma, forma)
    arco("arco" + forma, forma)
    armadura("armadura" + forma, forma)
    elmo("elmo" + forma, forma)

# ---------------------------------------------------------------- exporta
os.makedirs(SAIDA, exist_ok=True)
tris = 0
for ob in cena.objects:
    if ob.type == "MESH":
        tris += sum(len(p.vertices) - 2 for p in ob.data.polygons)
bpy.ops.export_scene.fbx(filepath=os.path.join(SAIDA, "itens_anime.fbx"), use_selection=False, axis_forward="-Z", axis_up="Y", apply_unit_scale=True, object_types={"MESH"}, mesh_smooth_type="FACE")
print("OBJETOS", len([o for o in cena.objects if o.type == "MESH"]), "TRIS", tris)

# ---------------------------------------------------------------- prévia: grade 5 tipos x 3 formas
grupos = ["katana", "cajado", "arco", "armadura", "elmo"]
for ob in cena.objects:
    for gi, g in enumerate(grupos):
        if ob.name.startswith(g):
            forma = ob.name[len(g)]
            fi = "ABC".index(forma)
            ob.location = (gi * 4.5, 0, -fi * 6.5)
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
cam.data.type = "ORTHO"
cam.data.ortho_scale = 24
cam.location = (9, -30, -6.5)
cam.rotation_euler = (math.radians(90), 0, 0)
cena.collection.objects.link(cam)
cena.camera = cam
luz = bpy.data.objects.new("sol", bpy.data.lights.new("sol", "SUN"))
luz.rotation_euler = (math.radians(50), math.radians(10), math.radians(-30))
cena.collection.objects.link(luz)
cena.render.engine = "BLENDER_WORKBENCH"
cena.display.shading.light = "STUDIO"
cena.display.shading.color_type = "MATERIAL"
cena.display.shading.show_cavity = True
cena.display.shading.show_object_outline = True
cena.render.resolution_x = 1100
cena.render.resolution_y = 1100
cena.render.filepath = PREVIA
bpy.ops.render.render(write_still=True)
print("PREVIA", PREVIA)
