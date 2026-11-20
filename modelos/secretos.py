# Os 3 Secretos (design próprio, texturas PBR assadas):
#  - leque: "Leque de Guerra Uchira" — gunbai de ferro laqueado, sol vermelho com 3 vírgulas, costelas douradas
#  - maos:  "Mãos de Argila Viva" — luvas de argila rachada com uma boca na palma (par, x = ±0.95)
#  - olho:  "Rinnegan" — globo ocular com anéis concêntricos lilás
# Uso: blender --background --python secretos.py -- <saida_dir> <previa.png>
import bpy, bmesh, math, os, sys
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
SAIDA = args[0] if args else r"D:\Claude\jogo-roblox\modelos\prontos"
PREVIA = args[1] if len(args) > 1 else os.path.join(SAIDA, "secretos_previa.png")
TEX = 512
os.makedirs(os.path.join(SAIDA, "tex"), exist_ok=True)

bpy.ops.wm.read_factory_settings(use_empty=True)
cena = bpy.context.scene
cena.render.engine = "CYCLES"
cena.cycles.device = "CPU"
cena.cycles.samples = 16


def malha(nome, bm):
    me = bpy.data.meshes.new(nome)
    bm.normal_update()
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(nome, me)
    cena.collection.objects.link(ob)
    return ob


def loft(secoes, a=True, b=True):
    bm = bmesh.new()
    aneis = [[bm.verts.new(p) for p in s] for s in secoes]
    n = len(secoes[0])
    for x, y in zip(aneis, aneis[1:]):
        for i in range(n):
            j = (i + 1) % n
            bm.faces.new((x[i], x[j], y[j], y[i]))
    if a:
        bm.faces.new(list(reversed(aneis[0])))
    if b:
        bm.faces.new(aneis[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bm


def tubo(caminho, raio, lados=10):
    secoes = []
    for i, p in enumerate(caminho):
        a = caminho[max(i - 1, 0)]
        b = caminho[min(i + 1, len(caminho) - 1)]
        d = (b - a).normalized()
        ref = Vector((0, 0, 1)) if abs(d.z) < 0.9 else Vector((1, 0, 0))
        u = d.cross(ref).normalized()
        v = d.cross(u).normalized()
        r = raio(i / (len(caminho) - 1)) if callable(raio) else raio
        secoes.append([p + (u * math.cos(k / lados * 2 * math.pi) + v * math.sin(k / lados * 2 * math.pi)) * r for k in range(lados)])
    return loft(secoes)


def juntar(bms):
    total = bmesh.new()
    for b in bms:
        me = bpy.data.meshes.new("tmp")
        b.to_mesh(me)
        total.from_mesh(me)
        bpy.data.meshes.remove(me)
        b.free()
    return total


from mathutils import Matrix


def esfera(r, centro, esc=(1, 1, 1), u=14, v=10):
    b = bmesh.new()
    bmesh.ops.create_uvsphere(b, u_segments=u, v_segments=v, radius=r)
    bmesh.ops.scale(b, vec=esc, verts=b.verts)
    bmesh.ops.translate(b, verts=b.verts, vec=centro)
    return b


def fundir(ob, voxel=0.02, suave=4, reduz=0.25):
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    r = ob.modifiers.new("remesh", "REMESH")
    r.mode = "VOXEL"
    r.voxel_size = voxel
    sm = ob.modifiers.new("suave", "SMOOTH")
    sm.factor = 0.7
    sm.iterations = suave
    dec = ob.modifiers.new("reduz", "DECIMATE")
    dec.ratio = reduz
    for mod in list(ob.modifiers):
        bpy.ops.object.modifier_apply(modifier=mod.name)


# ------------------------------------------------------------------ LEQUE (Z para cima, face em -Y)
def contorno_leque():
    pts = []
    for i in range(96):
        a = 2 * math.pi * i / 96
        r = 1.0 + 0.1 * math.cos(a) - 0.05 * math.cos(2 * a)
        pts.append((1.05 * r * math.sin(a), 1.15 * r * math.cos(a) + 1.45))
    return pts


def leque():
    pts = contorno_leque()
    bm = loft([[Vector((x, -0.035, z)) for x, z in pts], [Vector((x, 0.035, z)) for x, z in pts]])
    bmesh.ops.bevel(bm, geom=[e for e in bm.edges if abs(e.verts[0].co.y - e.verts[1].co.y) < 1e-4], offset=0.02, segments=2, affect="EDGES", clamp_overlap=True)
    malha("leque_placa", bm)
    # borda de metal gravado: perfil retangular chanfrado seguindo o contorno
    secs = []
    for x, z in pts + [pts[0]]:
        c = Vector((x, 0, z))
        rad = (c - Vector((0, 0, 1.45))).normalized()
        secs.append([c + rad * dr + Vector((0, dy, 0)) for dr, dy in ((-0.03, -0.07), (0.07, -0.05), (0.07, 0.05), (-0.03, 0.07))])
    malha("leque_aro", loft(secs, False, False))
    # miolo de ouro onde nascem as varetas
    malha("leque_miolo", esfera(0.13, (0, -0.06, 0.62), (1, 0.45, 1)))
    # varetas: lâminas finas e afiladas, rentes à face, do miolo até perto da borda
    bms = []
    for k in range(-3, 4):
        a = math.radians(k * 16)
        d = Vector((math.sin(a), 0, math.cos(a)))
        lado = Vector((math.cos(a), 0, -math.sin(a)))
        secs = []
        for i in range(9):
            t = i / 8
            c = Vector((0, -0.05, 0.62)) + d * (0.1 + 1.02 * t)
            w = 0.045 * (1 - 0.75 * t) + 0.008
            secs.append([c + lado * w, c + Vector((0, -0.018, 0)), c - lado * w, c + Vector((0, 0.01, 0))])
        bms.append(loft(secs))
    arco = [Vector((0, -0.05, 0.62)) + Vector((math.sin(a), 0, math.cos(a))) * 1.12 for a in [math.radians(-52 + 104 * i / 30) for i in range(31)]]
    bms.append(tubo(arco, 0.028, 8))
    malha("leque_costelas", juntar(bms))
    # cabo grosso com couro trançado (duas fitas em hélice) e pomo com argola
    cabo = [Vector((0, 0, 0.5 - 1.75 * i / 20)) for i in range(21)]
    malha("leque_cabo", tubo(cabo, 0.115, 12))
    tranca = []
    for sentido in (1, -1):
        cam = []
        for i in range(121):
            t = i / 120
            a = sentido * t * 9 * 2 * math.pi
            cam.append(Vector((0.13 * math.cos(a), 0.13 * math.sin(a), 0.45 - 1.6 * t)))
        tranca.append(tubo(cam, 0.03, 6))
    malha("leque_tranca", juntar(tranca))
    pomo = esfera(0.17, (0, 0, -1.33))
    argola = [Vector((0.18 * math.sin(a), 0, -1.6 - 0.18 * math.cos(a))) for a in [2 * math.pi * i / 28 for i in range(29)]]
    malha("leque_pomo", juntar([pomo, tubo(argola, 0.035, 6)]))


# ------------------------------------------------------------------ MÃOS DE ARGILA (par, dedos para -Z, palma para -Y)
def dedo(base, direcao, comps, raios, curva):
    pts, r = [base], []
    p = base.copy()
    d = direcao.normalized()
    for k, comp in enumerate(comps):
        d = (d + Vector((0, -curva, 0))).normalized()  # dobra levemente para a palma
        p = p + d * comp
        pts.append(p.copy())
    juntas = []
    for k, q in enumerate(pts):
        juntas.append(esfera(raios[min(k, len(raios) - 1)] * 1.05, q))
    ossos = []
    for k in range(len(pts) - 1):
        ossos.append(tubo([pts[k], (pts[k] + pts[k + 1]) / 2, pts[k + 1]], lambda t, a=raios[k], b=raios[min(k + 1, len(raios) - 1)]: a + (b - a) * t, 10))
    return juntas + ossos


def mao(lado):
    x0 = 0.95 * lado
    suf = "D" if lado > 0 else "E"
    bms = []
    # palma côncava: duas camadas achatadas (o centro afunda na frente)
    bms.append(esfera(0.42, (x0, 0.02, 0.0), (1.0, 0.36, 1.05), 18, 12))
    # 4 dedos longos e finos, 3 falanges cada, levemente abertos
    for f in range(4):
        abre = (f - 1.5) * 0.09
        base = Vector((x0 + (f - 1.5) * 0.19, -0.02, -0.36))
        comps = [0.26, 0.2, 0.16] if f in (1, 2) else [0.22, 0.17, 0.14]
        bms += dedo(base, Vector((abre * lado, 0, -1)), comps, [0.07, 0.062, 0.054, 0.045], 0.18)
    # polegar saindo do lado, apontando para baixo e para a frente
    bms += dedo(Vector((x0 + 0.38 * lado, -0.08, -0.05)), Vector((0.55 * lado, -0.35, -0.8)), [0.2, 0.17, 0.14], [0.085, 0.072, 0.06, 0.05], 0.1)
    # punho/manga de couro
    punho = [Vector((x0, 0, 0.28 + 0.4 * t)) for t in (0, 0.5, 1)]
    bms.append(tubo(punho, lambda t: 0.36 + 0.05 * t, 16))
    ob = malha("maos_argila" + suf, juntar(bms))
    fundir(ob, 0.022, 3, 0.22)
    # boca na palma (frente -Y): lábios grossos, interior escuro, dentes pontudos irregulares
    labio = [Vector((x0 + 0.17 * math.cos(a), -0.17, -0.02 + 0.075 * math.sin(a) * (1.1 if math.sin(a) > 0 else 1))) for a in [2 * math.pi * i / 32 for i in range(33)]]
    malha("maos_labios" + suf, tubo(labio, lambda t: 0.035 + 0.012 * math.sin(t * 2 * math.pi * 2) ** 2, 8))
    malha("maos_boca" + suf, esfera(0.15, (x0, -0.15, -0.02), (1.1, 0.35, 0.45)))
    dentes = []
    for k in range(-3, 4):
        for s in (-1, 1):
            d = bmesh.new()
            alto = 0.05 + 0.025 * ((k * 7 + s * 3) % 3) / 2
            bmesh.ops.create_cone(d, cap_ends=True, segments=5, radius1=0.022, radius2=0.0, depth=alto)
            bmesh.ops.rotate(d, verts=d.verts, cent=(0, 0, 0), matrix=Matrix.Rotation(math.pi if s > 0 else 0, 3, "X"))
            bmesh.ops.translate(d, verts=d.verts, vec=(x0 + k * 0.042, -0.19, -0.02 + s * 0.045))
            dentes.append(d)
    malha("maos_dentes" + suf, juntar(dentes))


# ------------------------------------------------------------------ OLHO (medalhão, frente em -Y)
def olho():
    # placa de fundo de metal preto gravado
    fundo = [(0.98 * math.cos(a), 0.98 * math.sin(a)) for a in [2 * math.pi * i / 64 for i in range(64)]]
    bm = loft([[Vector((x, 0.12, z)) for x, z in fundo], [Vector((x, 0.0, z)) for x, z in fundo]])
    bmesh.ops.bevel(bm, geom=list(bm.edges), offset=0.025, segments=2, affect="EDGES", clamp_overlap=True)
    malha("olho_moldura", juntar([bm, tubo([Vector((0.9 * math.cos(a), -0.02, 0.9 * math.sin(a))) for a in [2 * math.pi * i / 48 for i in range(49)]], 0.085, 10)]))
    # 4 pontas ornamentais em cruz na moldura
    pontas = []
    for k in range(4):
        a = k * math.pi / 2 + math.pi / 4
        c = bmesh.new()
        bmesh.ops.create_cone(c, cap_ends=True, segments=4, radius1=0.09, radius2=0.0, depth=0.38)
        bmesh.ops.rotate(c, verts=c.verts, cent=(0, 0, 0), matrix=Matrix.Rotation(math.pi / 2, 3, "Y"))
        bmesh.ops.rotate(c, verts=c.verts, cent=(0, 0, 0), matrix=Matrix.Rotation(-a, 3, "Y"))
        bmesh.ops.translate(c, verts=c.verts, vec=(1.12 * math.cos(a), 0.0, 1.12 * math.sin(a)))
        pontas.append(c)
    malha("olho_pontas", juntar(pontas))
    # disco do olho com anéis em relevo (degraus concêntricos)
    bm = bmesh.new()
    aneis = []
    N = 48
    raios = [0.08 + 0.1 * k for k in range(8)]
    centro = bm.verts.new((0, -0.16, 0))
    ant = None
    for k, r in enumerate(raios):
        y = -0.15 + 0.012 * k - (0.012 if k % 2 == 0 else 0.0)  # abaulado para a frente, degraus em relevo
        anel = [bm.verts.new((r * math.cos(2 * math.pi * i / N), y, r * math.sin(2 * math.pi * i / N))) for i in range(N)]
        if ant is None:
            for i in range(N):
                bm.faces.new((centro, anel[(i + 1) % N], anel[i]))
        else:
            for i in range(N):
                j = (i + 1) % N
                bm.faces.new((ant[i], ant[j], anel[j], anel[i]))
        ant = anel
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    malha("olho_iris", bm)
    # cúpula de vidro por cima
    domo = esfera(0.82, (0, 0.0, 0), (1, 0.22, 1), 32, 16)
    bmesh.ops.delete(domo, geom=[v for v in domo.verts if v.co.y > 0.001], context="VERTS")
    malha("olho_vidro", domo)


# ------------------------------------------------------------------ materiais procedurais
def no(nt, tipo, **kw):
    n = nt.nodes.new(tipo)
    for k, v in kw.items():
        setattr(n, k, v)
    return n


def rampa(nt, entrada, pares, interp="LINEAR"):
    r = no(nt, "ShaderNodeValToRGB")
    els = r.color_ramp.elements
    r.color_ramp.interpolation = interp
    els[0].position, els[0].color = pares[0]
    els[1].position, els[1].color = pares[-1]
    for pos, cor in pares[1:-1]:
        e = els.new(pos)
        e.color = cor
    nt.links.new(entrada, r.inputs["Fac"])
    return r


def coord(nt):
    return no(nt, "ShaderNodeTexCoord").outputs["Object"]


def ligar_bump(nt, bsdf, altura, forca):
    b = no(nt, "ShaderNodeBump")
    b.inputs["Strength"].default_value = forca
    nt.links.new(altura, b.inputs["Height"])
    nt.links.new(b.outputs["Normal"], bsdf.inputs["Normal"])


def mat_placa(nt, bsdf):
    # laca PRETA com sol vermelho, anel dourado fino e 3 vírgulas
    co = coord(nt)
    sep = no(nt, "ShaderNodeSeparateXYZ")
    nt.links.new(co, sep.inputs["Vector"])
    centro = no(nt, "ShaderNodeVectorMath", operation="SUBTRACT")
    nt.links.new(co, centro.inputs[0])
    centro.inputs[1].default_value = (0, 0, 1.55)
    xz = no(nt, "ShaderNodeVectorMath", operation="MULTIPLY")
    nt.links.new(centro.outputs["Vector"], xz.inputs[0])
    xz.inputs[1].default_value = (1, 0, 1)
    dist = no(nt, "ShaderNodeVectorMath", operation="LENGTH")
    nt.links.new(xz.outputs["Vector"], dist.inputs[0])
    sol = rampa(nt, dist.outputs["Value"], [(0.0, (0.5, 0.02, 0.03, 1)), (0.55, (0.58, 0.04, 0.04, 1)), (0.57, (0.85, 0.65, 0.25, 1)), (0.6, (0.85, 0.65, 0.25, 1)), (0.62, (0.012, 0.012, 0.015, 1)), (1.0, (0.012, 0.012, 0.015, 1))], "CONSTANT")
    ang = no(nt, "ShaderNodeMath", operation="ARCTAN2")
    nt.links.new(sep.outputs["X"], ang.inputs[0])
    zc = no(nt, "ShaderNodeMath", operation="SUBTRACT")
    nt.links.new(sep.outputs["Z"], zc.inputs[0])
    zc.inputs[1].default_value = 1.55
    nt.links.new(zc.outputs["Value"], ang.inputs[1])
    giro = no(nt, "ShaderNodeMath", operation="MULTIPLY_ADD")
    nt.links.new(dist.outputs["Value"], giro.inputs[0])
    giro.inputs[1].default_value = 6.0
    nt.links.new(ang.outputs["Value"], giro.inputs[2])
    tres = no(nt, "ShaderNodeMath", operation="MULTIPLY")
    nt.links.new(giro.outputs["Value"], tres.inputs[0])
    tres.inputs[1].default_value = 3.0
    seno = no(nt, "ShaderNodeMath", operation="SINE")
    nt.links.new(tres.outputs["Value"], seno.inputs[0])
    virg = rampa(nt, seno.outputs["Value"], [(0.0, (0, 0, 0, 1)), (0.86, (0, 0, 0, 1)), (0.9, (1, 1, 1, 1)), (1.0, (1, 1, 1, 1))], "CONSTANT")
    perto = rampa(nt, dist.outputs["Value"], [(0.0, (0, 0, 0, 1)), (0.12, (1, 1, 1, 1)), (0.46, (1, 1, 1, 1)), (0.5, (0, 0, 0, 1)), (1.0, (0, 0, 0, 1))], "CONSTANT")
    mascara = no(nt, "ShaderNodeMix", data_type="RGBA", blend_type="MULTIPLY")
    mascara.inputs["Factor"].default_value = 1.0
    nt.links.new(virg.outputs["Color"], mascara.inputs["A"])
    nt.links.new(perto.outputs["Color"], mascara.inputs["B"])
    cor = no(nt, "ShaderNodeMix", data_type="RGBA", blend_type="MIX")
    nt.links.new(mascara.outputs["Result"], cor.inputs["Factor"])
    nt.links.new(sol.outputs["Color"], cor.inputs["A"])
    cor.inputs["B"].default_value = (0.08, 0.02, 0.02, 1)
    nt.links.new(cor.outputs["Result"], bsdf.inputs["Base Color"])
    bsdf.inputs["Metallic"].default_value = 0.0
    bsdf.inputs["Roughness"].default_value = 0.18
    nz = no(nt, "ShaderNodeTexNoise")
    nz.inputs["Scale"].default_value = 70
    nt.links.new(co, nz.inputs["Vector"])
    ligar_bump(nt, bsdf, nz.outputs["Fac"], 0.04)


def mat_metal_gravado(nt, bsdf, base=(0.03, 0.03, 0.035, 1), gravura=(0.55, 0.42, 0.18, 1)):
    # metal preto com arabescos dourados gravados (ondas distorcidas)
    co = coord(nt)
    onda = no(nt, "ShaderNodeTexWave", wave_type="RINGS")
    onda.inputs["Scale"].default_value = 9
    onda.inputs["Distortion"].default_value = 14
    onda.inputs["Detail"].default_value = 3
    nt.links.new(co, onda.inputs["Vector"])
    gr = rampa(nt, onda.outputs["Fac"], [(0.0, (0, 0, 0, 1)), (0.47, (0, 0, 0, 1)), (0.5, (1, 1, 1, 1)), (0.53, (0, 0, 0, 1)), (1.0, (0, 0, 0, 1))])
    cor = no(nt, "ShaderNodeMix", data_type="RGBA", blend_type="MIX")
    nt.links.new(gr.outputs["Color"], cor.inputs["Factor"])
    cor.inputs["A"].default_value = base
    cor.inputs["B"].default_value = gravura
    nt.links.new(cor.outputs["Result"], bsdf.inputs["Base Color"])
    bsdf.inputs["Metallic"].default_value = 1.0
    rg = rampa(nt, gr.outputs["Color"], [(0.0, (0.38, 0.38, 0.38, 1)), (1.0, (0.22, 0.22, 0.22, 1))])
    nt.links.new(rg.outputs["Color"], bsdf.inputs["Roughness"])
    inv = no(nt, "ShaderNodeInvert")
    nt.links.new(gr.outputs["Color"], inv.inputs["Color"])
    ligar_bump(nt, bsdf, inv.outputs["Color"], 0.5)


def mat_ouro(nt, bsdf):
    nz = no(nt, "ShaderNodeTexNoise")
    nz.inputs["Scale"].default_value = 40
    nt.links.new(coord(nt), nz.inputs["Vector"])
    c = rampa(nt, nz.outputs["Fac"], [(0.0, (0.6, 0.42, 0.12, 1)), (1.0, (0.9, 0.7, 0.3, 1))])
    nt.links.new(c.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Metallic"].default_value = 1.0
    bsdf.inputs["Roughness"].default_value = 0.22
    ligar_bump(nt, bsdf, nz.outputs["Fac"], 0.08)


def mat_couro_preto(nt, bsdf):
    nz = no(nt, "ShaderNodeTexNoise")
    nz.inputs["Scale"].default_value = 80
    nz.inputs["Detail"].default_value = 10
    nt.links.new(coord(nt), nz.inputs["Vector"])
    c = rampa(nt, nz.outputs["Fac"], [(0.0, (0.015, 0.012, 0.012, 1)), (1.0, (0.05, 0.035, 0.03, 1))])
    nt.links.new(c.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Metallic"].default_value = 0.0
    bsdf.inputs["Roughness"].default_value = 0.55
    ligar_bump(nt, bsdf, nz.outputs["Fac"], 0.3)


def mat_argila_brasa(nt, bsdf):
    # couro preto embaixo, argila escura subindo dos dedos, rachaduras com brasa laranja por dentro
    co = coord(nt)
    torto = no(nt, "ShaderNodeTexNoise")
    torto.inputs["Scale"].default_value = 6
    mixv = no(nt, "ShaderNodeMix", data_type="VECTOR")
    mixv.inputs["Factor"].default_value = 0.25
    nt.links.new(co, torto.inputs["Vector"])
    nt.links.new(co, mixv.inputs["A"])
    nt.links.new(torto.outputs["Color"], mixv.inputs["B"])
    vor = no(nt, "ShaderNodeTexVoronoi", feature="DISTANCE_TO_EDGE")
    vor.inputs["Scale"].default_value = 26
    nt.links.new(mixv.outputs["Result"], vor.inputs["Vector"])
    nz = no(nt, "ShaderNodeTexNoise")
    nz.inputs["Scale"].default_value = 4
    nz.inputs["Detail"].default_value = 6
    nt.links.new(co, nz.inputs["Vector"])
    sep = no(nt, "ShaderNodeSeparateXYZ")
    nt.links.new(co, sep.inputs["Vector"])
    # máscara de argila: mais embaixo (dedos) e manchas subindo pela palma; o punho fica couro
    alt = no(nt, "ShaderNodeMath", operation="MULTIPLY_ADD")
    nt.links.new(sep.outputs["Z"], alt.inputs[0])
    alt.inputs[1].default_value = -1.2
    nt.links.new(nz.outputs["Fac"], alt.inputs[2])
    mask = rampa(nt, alt.outputs["Value"], [(0.0, (0, 0, 0, 1)), (0.45, (0, 0, 0, 1)), (0.55, (1, 1, 1, 1)), (1.0, (1, 1, 1, 1))])
    argila = rampa(nt, vor.outputs["Distance"], [(0.0, (1.0, 0.45, 0.06, 1)), (0.012, (0.85, 0.25, 0.03, 1)), (0.03, (0.03, 0.026, 0.025, 1)), (1.0, (0.06, 0.052, 0.05, 1))])
    couro = (0.008, 0.007, 0.007, 1)
    cor = no(nt, "ShaderNodeMix", data_type="RGBA", blend_type="MIX")
    nt.links.new(mask.outputs["Color"], cor.inputs["Factor"])
    cor.inputs["A"].default_value = couro
    nt.links.new(argila.outputs["Color"], cor.inputs["B"])
    nt.links.new(cor.outputs["Result"], bsdf.inputs["Base Color"])
    bsdf.inputs["Metallic"].default_value = 0.0
    rg = rampa(nt, mask.outputs["Color"], [(0.0, (0.5, 0.5, 0.5, 1)), (1.0, (0.85, 0.85, 0.85, 1))])
    nt.links.new(rg.outputs["Color"], bsdf.inputs["Roughness"])
    relevo = rampa(nt, vor.outputs["Distance"], [(0.0, (0, 0, 0, 1)), (0.05, (1, 1, 1, 1)), (1.0, (1, 1, 1, 1))])
    rel_m = no(nt, "ShaderNodeMix", data_type="RGBA", blend_type="MULTIPLY")
    rel_m.inputs["Factor"].default_value = 1.0
    nt.links.new(relevo.outputs["Color"], rel_m.inputs["A"])
    nt.links.new(mask.outputs["Color"], rel_m.inputs["B"])
    ligar_bump(nt, bsdf, rel_m.outputs["Result"], 0.6)


def mat_simples(cor, rough=0.5, metal=0.0):
    def f(nt, bsdf):
        bsdf.inputs["Base Color"].default_value = cor
        bsdf.inputs["Roughness"].default_value = rough
        bsdf.inputs["Metallic"].default_value = metal
    return f


def mat_iris(nt, bsdf):
    # íris roxa com fibras radiais, linhas escuras nos degraus e pupila preta com miolo brilhante
    co = coord(nt)
    sep = no(nt, "ShaderNodeSeparateXYZ")
    nt.links.new(co, sep.inputs["Vector"])
    xz = no(nt, "ShaderNodeCombineXYZ")
    nt.links.new(sep.outputs["X"], xz.inputs["X"])
    nt.links.new(sep.outputs["Z"], xz.inputs["Y"])
    dist0 = no(nt, "ShaderNodeVectorMath", operation="LENGTH")
    nt.links.new(xz.outputs["Vector"], dist0.inputs[0])
    dist = no(nt, "ShaderNodeMath", operation="MULTIPLY")
    nt.links.new(dist0.outputs["Value"], dist.inputs[0])
    dist.inputs[1].default_value = 0.75
    ang = no(nt, "ShaderNodeMath", operation="ARCTAN2")
    nt.links.new(sep.outputs["X"], ang.inputs[0])
    nt.links.new(sep.outputs["Z"], ang.inputs[1])
    fib = no(nt, "ShaderNodeCombineXYZ")
    nt.links.new(ang.outputs["Value"], fib.inputs["X"])
    escd = no(nt, "ShaderNodeMath", operation="MULTIPLY")
    nt.links.new(dist.outputs["Value"], escd.inputs[0])
    escd.inputs[1].default_value = 0.15
    nt.links.new(escd.outputs["Value"], fib.inputs["Y"])
    nz = no(nt, "ShaderNodeTexNoise")
    nz.inputs["Scale"].default_value = 18
    nz.inputs["Detail"].default_value = 8
    nt.links.new(fib.outputs["Vector"], nz.inputs["Vector"])
    base = rampa(nt, nz.outputs["Fac"], [(0.0, (0.2, 0.08, 0.38, 1)), (0.5, (0.45, 0.25, 0.75, 1)), (1.0, (0.78, 0.65, 0.95, 1))])
    aneis = no(nt, "ShaderNodeMath", operation="SINE")
    esc = no(nt, "ShaderNodeMath", operation="MULTIPLY")
    nt.links.new(dist.outputs["Value"], esc.inputs[0])
    esc.inputs[1].default_value = 55.0
    nt.links.new(esc.outputs["Value"], aneis.inputs[0])
    linhas = rampa(nt, aneis.outputs["Value"], [(0.0, (1, 1, 1, 1)), (0.88, (1, 1, 1, 1)), (0.92, (0.05, 0.02, 0.1, 1)), (1.0, (0.05, 0.02, 0.1, 1))], "CONSTANT")
    m1 = no(nt, "ShaderNodeMix", data_type="RGBA", blend_type="MULTIPLY")
    m1.inputs["Factor"].default_value = 1.0
    nt.links.new(base.outputs["Color"], m1.inputs["A"])
    nt.links.new(linhas.outputs["Color"], m1.inputs["B"])
    pupila = rampa(nt, dist.outputs["Value"], [(0.0, (0.85, 0.5, 1.0, 1)), (0.035, (0.6, 0.2, 0.9, 1)), (0.06, (0.02, 0.0, 0.04, 1)), (0.12, (0.02, 0.0, 0.04, 1)), (0.13, (1, 1, 1, 1)), (1.0, (1, 1, 1, 1))])
    m2 = no(nt, "ShaderNodeMix", data_type="RGBA", blend_type="MULTIPLY")
    m2.inputs["Factor"].default_value = 1.0
    nt.links.new(m1.outputs["Result"], m2.inputs["A"])
    nt.links.new(pupila.outputs["Color"], m2.inputs["B"])
    # miolo da pupila acende (soma o brilho roxo)
    brilho = rampa(nt, dist.outputs["Value"], [(0.0, (0.75, 0.35, 1.0, 1)), (0.05, (0.0, 0.0, 0.0, 1)), (1.0, (0, 0, 0, 1))])
    m3 = no(nt, "ShaderNodeMix", data_type="RGBA", blend_type="ADD")
    m3.inputs["Factor"].default_value = 1.0
    nt.links.new(m2.outputs["Result"], m3.inputs["A"])
    nt.links.new(brilho.outputs["Color"], m3.inputs["B"])
    nt.links.new(m3.outputs["Result"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.35
    bsdf.inputs["Metallic"].default_value = 0.0
    ligar_bump(nt, bsdf, nz.outputs["Fac"], 0.15)


def mat_vidro(nt, bsdf):
    bsdf.inputs["Base Color"].default_value = (0.9, 0.85, 1.0, 1)
    bsdf.inputs["Roughness"].default_value = 0.02
    bsdf.inputs["Transmission Weight"].default_value = 1.0
    bsdf.inputs["IOR"].default_value = 1.2


leque()
mao(1)
mao(-1)
olho()

MATS = {
    "leque_placa": mat_placa, "leque_aro": mat_metal_gravado, "leque_cabo": mat_couro_preto,
    "leque_tranca": mat_simples((0.07, 0.015, 0.01, 1), 0.5), "leque_pomo": mat_ouro, "leque_miolo": mat_ouro, "leque_costelas": mat_ouro,
    "olho_moldura": mat_metal_gravado, "olho_pontas": mat_metal_gravado, "olho_iris": mat_iris,
    "olho_vidro": mat_vidro,
}
for lado in "DE":
    MATS["maos_argila" + lado] = mat_argila_brasa
    MATS["maos_labios" + lado] = mat_simples((0.18, 0.04, 0.05, 1), 0.45)
    MATS["maos_boca" + lado] = mat_simples((0.03, 0.0, 0.01, 1), 0.4)
    MATS["maos_dentes" + lado] = mat_simples((0.85, 0.8, 0.7, 1), 0.3)

for ob in [o for o in cena.objects if o.type == "MESH"]:
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.shade_smooth_by_angle(angle=math.radians(40))
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.02)
    bpy.ops.object.mode_set(mode="OBJECT")
    mat = bpy.data.materials.new(ob.name + "_mat")
    mat.use_nodes = True
    MATS[ob.name](mat.node_tree, mat.node_tree.nodes["Principled BSDF"])
    ob.data.materials.clear()
    ob.data.materials.append(mat)

# bake: cor e metal por emissão, aspereza e normal direto
for ob in [o for o in cena.objects if o.type == "MESH"]:
    nt = ob.data.materials[0].node_tree
    bsdf = nt.nodes["Principled BSDF"]
    saida = nt.nodes["Material Output"]
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    imgs = {}
    for passo, tipo in (("cor", "EMIT"), ("rough", "ROUGHNESS"), ("normal", "NORMAL"), ("metal", "EMIT")):
        img = bpy.data.images.new(f"{ob.name}_{passo}", TEX, TEX, alpha=False)
        if passo != "cor":
            img.colorspace_settings.name = "Non-Color"
        t = nt.nodes.new("ShaderNodeTexImage")
        t.image = img
        nt.nodes.active = t
        antigo, emi = None, None
        if tipo == "EMIT":
            emi = nt.nodes.new("ShaderNodeEmission")
            ent = bsdf.inputs["Base Color" if passo == "cor" else "Metallic"]
            if ent.is_linked:
                nt.links.new(ent.links[0].from_socket, emi.inputs["Color"])
            else:
                v = ent.default_value
                emi.inputs["Color"].default_value = tuple(v) if passo == "cor" else (v, v, v, 1)
            antigo = saida.inputs["Surface"].links[0].from_socket
            nt.links.new(emi.outputs["Emission"], saida.inputs["Surface"])
        bpy.ops.object.bake(type=tipo, margin=4)
        img.filepath_raw = os.path.join(SAIDA, "tex", f"{ob.name}_{passo}.png")
        img.file_format = "PNG"
        img.save()
        if emi:
            nt.links.new(antigo, saida.inputs["Surface"])
            nt.nodes.remove(emi)
        nt.nodes.remove(t)
        imgs[passo] = img
    mat = bpy.data.materials.new(ob.name + "_pbr")
    mat.use_nodes = True
    n2 = mat.node_tree
    b2 = n2.nodes["Principled BSDF"]
    def tex(img):
        t = n2.nodes.new("ShaderNodeTexImage")
        t.image = img
        return t
    n2.links.new(tex(imgs["cor"]).outputs["Color"], b2.inputs["Base Color"])
    n2.links.new(tex(imgs["rough"]).outputs["Color"], b2.inputs["Roughness"])
    n2.links.new(tex(imgs["metal"]).outputs["Color"], b2.inputs["Metallic"])
    nm = n2.nodes.new("ShaderNodeNormalMap")
    n2.links.new(tex(imgs["normal"]).outputs["Color"], nm.inputs["Color"])
    n2.links.new(nm.outputs["Normal"], b2.inputs["Normal"])
    ob.data.materials.clear()
    ob.data.materials.append(mat)

tris = sum(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in cena.objects if o.type == "MESH")
bpy.ops.export_scene.gltf(filepath=os.path.join(SAIDA, "secretos.glb"), export_format="GLB", export_yup=True)
print("TRIS", tris)

# o vidro volta a ser transparente na prévia (no Roblox o código põe material Glass)
vidro = bpy.data.objects.get("olho_vidro")
if vidro:
    bv = vidro.data.materials[0].node_tree.nodes["Principled BSDF"]
    bv.inputs["Transmission Weight"].default_value = 1.0
    bv.inputs["Roughness"].default_value = 0.02
    for l in list(bv.inputs["Base Color"].links):
        vidro.data.materials[0].node_tree.links.remove(l)
    bv.inputs["Base Color"].default_value = (0.95, 0.92, 1.0, 1)

# prévias de perto: uma por item (fundo escuro, 3 luzes)
alvo = bpy.data.objects.new("alvo", None)
cena.collection.objects.link(alvo)
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
cena.collection.objects.link(cam)
cena.camera = cam
tr = cam.constraints.new("TRACK_TO")
tr.target = alvo
tr.track_axis = "TRACK_NEGATIVE_Z"
tr.up_axis = "UP_Y"
luzes = []
for nome, en in (("chave", 900), ("preench", 300), ("recorte", 700)):
    l = bpy.data.objects.new(nome, bpy.data.lights.new(nome, "AREA"))
    l.data.energy = en
    l.data.size = 2.5
    t = l.constraints.new("TRACK_TO")
    t.target = alvo
    t.track_axis = "TRACK_NEGATIVE_Z"
    t.up_axis = "UP_Y"
    cena.collection.objects.link(l)
    luzes.append(l)
mundo = bpy.data.worlds.new("mundo")
mundo.use_nodes = True
mundo.node_tree.nodes["Background"].inputs["Color"].default_value = (0.01, 0.01, 0.013, 1)
cena.world = mundo
cena.cycles.samples = 64
cena.render.resolution_x = 900
cena.render.resolution_y = 900
for nome, centro, dist in (("leque", (0, 0, 0.9), 6.5), ("maos", (0, 0, -0.1), 4.2), ("olho", (0, 0, 0), 3.4)):
    for ob in cena.objects:
        if ob.type == "MESH":
            ob.hide_render = not ob.name.startswith(nome)
    alvo.location = centro
    cam.location = (centro[0] + dist * 0.35, centro[1] - dist, centro[2] + dist * 0.18)
    c = Vector(centro)
    luzes[0].location = c + Vector((-3, -4, 3))
    luzes[1].location = c + Vector((4, -3, 0.5))
    luzes[2].location = c + Vector((1, 4, 2.5))
    cena.render.filepath = PREVIA.replace(".png", "_" + nome + ".png")
    bpy.ops.render.render(write_still=True)
print("PREVIA", PREVIA)
