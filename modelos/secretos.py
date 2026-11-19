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


# ------------------------------------------------------------------ LEQUE (Z para cima, face em -Y)
def leque():
    # placa: contorno de gota larga (gunbai), espessa no centro
    pts = []
    for i in range(72):
        a = 2 * math.pi * i / 72
        r = 1.0 + 0.12 * math.cos(a) - 0.05 * math.cos(2 * a)
        pts.append((1.05 * r * math.sin(a), 1.15 * r * math.cos(a) + 1.45))
    sec_f = [Vector((x, -0.035, z)) for x, z in pts]
    sec_t = [Vector((x, 0.035, z)) for x, z in pts]
    bm = loft([sec_f, sec_t])
    bmesh.ops.bevel(bm, geom=[e for e in bm.edges if abs(e.verts[0].co.y - e.verts[1].co.y) < 1e-4], offset=0.02, segments=2, affect="EDGES", clamp_overlap=True)
    obj = malha("leque_placa", bm)
    # aro de ferro em volta
    aro = [Vector((x * 1.02, 0, z * 1.0 + (1 - 1.0) * 1.45)) for x, z in pts] + [Vector((pts[0][0] * 1.02, 0, pts[0][1]))]
    malha("leque_aro", tubo(aro, 0.055, 8))
    # cabo com empunhadura e pomo com argola
    cabo = [Vector((0, 0, 0.45 - 1.7 * i / 20)) for i in range(21)]
    malha("leque_cabo", tubo(cabo, lambda t: 0.09 * (1 - 0.1 * math.sin(t * 9 * math.pi)), 10))
    pomo = bmesh.new()
    bmesh.ops.create_uvsphere(pomo, u_segments=12, v_segments=8, radius=0.14)
    bmesh.ops.translate(pomo, verts=pomo.verts, vec=(0, 0, -1.3))
    argola = [Vector((0.16 * math.sin(a), 0, -1.55 - 0.16 * math.cos(a) + 0.0)) for a in [2 * math.pi * i / 24 for i in range(25)]]
    malha("leque_pomo", juntar([pomo, tubo(argola, 0.03, 6)]))
    # costelas (varetas) douradas saindo do cabo, por cima da face
    bms = []
    for k in range(-3, 4):
        a = math.radians(k * 17)
        ini = Vector((0, -0.045, 0.6))
        fim = Vector((math.sin(a) * 1.3, -0.045, 0.6 + math.cos(a) * 1.3))
        bms.append(tubo([ini + (fim - ini) * t for t in (0, 0.5, 1)], 0.022, 6))
    malha("leque_costelas", juntar(bms))
    return obj


# ------------------------------------------------------------------ MÃOS DE ARGILA (par, dedos para -Z, palma em +Y)
def mao(lado):
    x0 = 0.95 * lado
    bms = []
    # palma arredondada
    palma = bmesh.new()
    bmesh.ops.create_uvsphere(palma, u_segments=14, v_segments=10, radius=0.5)
    bmesh.ops.scale(palma, vec=(0.95, 0.62, 0.95), verts=palma.verts)
    bmesh.ops.translate(palma, verts=palma.verts, vec=(x0, 0, 0))
    bms.append(palma)
    # dedos (4) e polegar, com articulação leve
    for f in range(4):
        base = Vector((x0 - 0.3 + f * 0.2, 0.02, -0.38))
        comp = 0.5 + 0.08 * (1 - abs(f - 1.5) / 1.5)
        cam = [base + Vector((0, -0.05 * t * t, -comp * t)) for t in (0, 0.33, 0.66, 1)]
        bms.append(tubo(cam, lambda t: 0.085 * (1 - 0.3 * t), 8))
    pol = Vector((x0 + 0.42 * lado, -0.05, -0.05))
    bms.append(tubo([pol + Vector((0.18 * lado * t, -0.06 * t, -0.35 * t)) for t in (0, 0.5, 1)], lambda t: 0.1 * (1 - 0.3 * t), 8))
    # punho largo de argila
    punho = [Vector((x0, 0, 0.3 + 0.38 * t)) for t in (0, 0.5, 1)]
    bms.append(tubo(punho, lambda t: 0.4 + 0.07 * t, 14))
    ob = malha("maos_argila" + ("D" if lado > 0 else "E"), juntar(bms))
    # funde palma, dedos e punho numa peça só de argila (remesh em voxel + suavizar + reduzir)
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    r = ob.modifiers.new("remesh", "REMESH")
    r.mode = "VOXEL"
    r.voxel_size = 0.035
    sm = ob.modifiers.new("suave", "SMOOTH")
    sm.factor = 0.8
    sm.iterations = 6
    dec = ob.modifiers.new("reduz", "DECIMATE")
    dec.ratio = 0.18
    for mod in list(ob.modifiers):
        bpy.ops.object.modifier_apply(modifier=mod.name)
    # boca na palma: lábios (anel) + interior escuro + dentes
    labio = [Vector((x0 + 0.2 * math.cos(a), -0.31, -0.02 + 0.09 * math.sin(a))) for a in [2 * math.pi * i / 24 for i in range(25)]]
    malha("maos_labios" + ("D" if lado > 0 else "E"), tubo(labio, 0.045, 6))
    boca = bmesh.new()
    bmesh.ops.create_uvsphere(boca, u_segments=12, v_segments=6, radius=0.18)
    bmesh.ops.scale(boca, vec=(1.1, 0.25, 0.45), verts=boca.verts)
    bmesh.ops.translate(boca, verts=boca.verts, vec=(x0, -0.29, -0.02))
    malha("maos_boca" + ("D" if lado > 0 else "E"), boca)
    dentes = []
    for k in range(-2, 3):
        for s in (-1, 1):
            d = bmesh.new()
            bmesh.ops.create_cone(d, cap_ends=True, segments=4, radius1=0.035, radius2=0.0, depth=0.07)
            bmesh.ops.rotate(d, verts=d.verts, cent=(0, 0, 0), matrix=__import__("mathutils").Matrix.Rotation(math.pi if s > 0 else 0, 3, "X"))
            bmesh.ops.translate(d, verts=d.verts, vec=(x0 + k * 0.07, -0.33, -0.02 + s * 0.06))
            dentes.append(d)
    malha("maos_dentes" + ("D" if lado > 0 else "E"), juntar(dentes))


# ------------------------------------------------------------------ OLHO (globo, pupila em -Y)
def olho():
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=32, v_segments=20, radius=0.9)
    malha("olho_globo", bm)


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
    tc = no(nt, "ShaderNodeTexCoord")
    return tc.outputs["Object"]


def mat_placa(nt, bsdf):
    # laca preta com sol vermelho e 3 vírgulas (tomoe) brancas: desenho próprio
    co = coord(nt)
    sep = no(nt, "ShaderNodeSeparateXYZ")
    nt.links.new(co, sep.inputs["Vector"])
    # distância ao centro do sol (x, z-1.55)
    centro = no(nt, "ShaderNodeVectorMath", operation="SUBTRACT")
    nt.links.new(co, centro.inputs[0])
    centro.inputs[1].default_value = (0, 0, 1.55)
    xz = no(nt, "ShaderNodeVectorMath", operation="MULTIPLY")
    nt.links.new(centro.outputs["Vector"], xz.inputs[0])
    xz.inputs[1].default_value = (1, 0, 1)
    dist = no(nt, "ShaderNodeVectorMath", operation="LENGTH")
    nt.links.new(xz.outputs["Vector"], dist.inputs[0])
    sol = rampa(nt, dist.outputs["Value"], [(0.0, (0.55, 0.03, 0.04, 1)), (0.62, (0.6, 0.05, 0.05, 1)), (0.64, (0.9, 0.75, 0.35, 1)), (0.67, (0.9, 0.75, 0.35, 1)), (0.69, (0.02, 0.02, 0.025, 1)), (1.0, (0.02, 0.02, 0.025, 1))], "CONSTANT")
    # 3 vírgulas: ondas em espiral (ângulo + distância) recortadas perto do centro
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
    seno = no(nt, "ShaderNodeMath", operation="SINE")
    tres = no(nt, "ShaderNodeMath", operation="MULTIPLY")
    nt.links.new(giro.outputs["Value"], tres.inputs[0])
    tres.inputs[1].default_value = 3.0
    nt.links.new(tres.outputs["Value"], seno.inputs[0])
    virg = rampa(nt, seno.outputs["Value"], [(0.0, (0, 0, 0, 1)), (0.86, (0, 0, 0, 1)), (0.9, (1, 1, 1, 1)), (1.0, (1, 1, 1, 1))], "CONSTANT")
    perto = rampa(nt, dist.outputs["Value"], [(0.0, (0, 0, 0, 1)), (0.12, (1, 1, 1, 1)), (0.5, (1, 1, 1, 1)), (0.55, (0, 0, 0, 1)), (1.0, (0, 0, 0, 1))], "CONSTANT")
    mascara = no(nt, "ShaderNodeMix", data_type="RGBA", blend_type="MULTIPLY")
    mascara.inputs["Factor"].default_value = 1.0
    nt.links.new(virg.outputs["Color"], mascara.inputs["A"])
    nt.links.new(perto.outputs["Color"], mascara.inputs["B"])
    cor = no(nt, "ShaderNodeMix", data_type="RGBA", blend_type="MIX")
    nt.links.new(mascara.outputs["Result"], cor.inputs["Factor"])
    nt.links.new(sol.outputs["Color"], cor.inputs["A"])
    cor.inputs["B"].default_value = (0.92, 0.9, 0.85, 1)
    nt.links.new(cor.outputs["Result"], bsdf.inputs["Base Color"])
    bsdf.inputs["Metallic"].default_value = 0.0
    bsdf.inputs["Roughness"].default_value = 0.25
    nz = no(nt, "ShaderNodeTexNoise")
    nz.inputs["Scale"].default_value = 60
    nt.links.new(co, nz.inputs["Vector"])
    b = no(nt, "ShaderNodeBump")
    b.inputs["Strength"].default_value = 0.05
    nt.links.new(nz.outputs["Fac"], b.inputs["Height"])
    nt.links.new(b.outputs["Normal"], bsdf.inputs["Normal"])


def mat_ferro(nt, bsdf, cor1=(0.05, 0.05, 0.06, 1), cor2=(0.16, 0.15, 0.15, 1), metal=1.0, rough=(0.35, 0.7)):
    nz = no(nt, "ShaderNodeTexNoise")
    nz.inputs["Scale"].default_value = 30
    nz.inputs["Detail"].default_value = 8
    nt.links.new(coord(nt), nz.inputs["Vector"])
    c = rampa(nt, nz.outputs["Fac"], [(0.0, cor1), (1.0, cor2)])
    nt.links.new(c.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Metallic"].default_value = metal
    r = rampa(nt, nz.outputs["Fac"], [(0.0, (rough[0],) * 3 + (1,)), (1.0, (rough[1],) * 3 + (1,))])
    nt.links.new(r.outputs["Color"], bsdf.inputs["Roughness"])
    b = no(nt, "ShaderNodeBump")
    b.inputs["Strength"].default_value = 0.25
    nt.links.new(nz.outputs["Fac"], b.inputs["Height"])
    nt.links.new(b.outputs["Normal"], bsdf.inputs["Normal"])


def mat_ouro(nt, bsdf):
    mat_ferro(nt, bsdf, (0.55, 0.38, 0.1, 1), (0.85, 0.65, 0.25, 1), 1.0, (0.2, 0.35))


def mat_couro(nt, bsdf):
    mat_ferro(nt, bsdf, (0.08, 0.03, 0.03, 1), (0.18, 0.06, 0.05, 1), 0.0, (0.55, 0.8))


def mat_argila(nt, bsdf):
    # argila clara com rachaduras (voronoi) e marcas de dedo
    co = coord(nt)
    vor = no(nt, "ShaderNodeTexVoronoi", feature="DISTANCE_TO_EDGE")
    vor.inputs["Scale"].default_value = 18
    nt.links.new(co, vor.inputs["Vector"])
    rach = rampa(nt, vor.outputs["Distance"], [(0.0, (0.42, 0.33, 0.26, 1)), (0.02, (0.5, 0.41, 0.33, 1)), (0.05, (0.78, 0.68, 0.56, 1)), (1.0, (0.84, 0.75, 0.62, 1))])
    nz = no(nt, "ShaderNodeTexNoise")
    nz.inputs["Scale"].default_value = 14
    nt.links.new(co, nz.inputs["Vector"])
    mix = no(nt, "ShaderNodeMix", data_type="RGBA", blend_type="MULTIPLY")
    mix.inputs["Factor"].default_value = 0.25
    nt.links.new(rach.outputs["Color"], mix.inputs["A"])
    nt.links.new(nz.outputs["Fac"], mix.inputs["B"])
    nt.links.new(mix.outputs["Result"], bsdf.inputs["Base Color"])
    bsdf.inputs["Metallic"].default_value = 0.0
    bsdf.inputs["Roughness"].default_value = 0.85
    alt = rampa(nt, vor.outputs["Distance"], [(0.0, (0, 0, 0, 1)), (0.04, (1, 1, 1, 1)), (1.0, (1, 1, 1, 1))])
    b = no(nt, "ShaderNodeBump")
    b.inputs["Strength"].default_value = 0.6
    nt.links.new(alt.outputs["Color"], b.inputs["Height"])
    nt.links.new(b.outputs["Normal"], bsdf.inputs["Normal"])


def mat_simples(cor, rough=0.5, metal=0.0):
    def f(nt, bsdf):
        bsdf.inputs["Base Color"].default_value = cor
        bsdf.inputs["Roughness"].default_value = rough
        bsdf.inputs["Metallic"].default_value = metal
    return f


def mat_olho(nt, bsdf):
    # esclera lilás clara com anéis concêntricos (ondulação) e pupila escura na frente (-Y)
    co = coord(nt)
    sep = no(nt, "ShaderNodeSeparateXYZ")
    nt.links.new(co, sep.inputs["Vector"])
    xz = no(nt, "ShaderNodeCombineXYZ")
    nt.links.new(sep.outputs["X"], xz.inputs["X"])
    nt.links.new(sep.outputs["Z"], xz.inputs["Z"])
    dist = no(nt, "ShaderNodeVectorMath", operation="LENGTH")
    nt.links.new(xz.outputs["Vector"], dist.inputs[0])
    aneis = no(nt, "ShaderNodeMath", operation="SINE")
    escala = no(nt, "ShaderNodeMath", operation="MULTIPLY")
    nt.links.new(dist.outputs["Value"], escala.inputs[0])
    escala.inputs[1].default_value = 42.0
    nt.links.new(escala.outputs["Value"], aneis.inputs[0])
    cor_aneis = rampa(nt, aneis.outputs["Value"], [(0.0, (0.66, 0.56, 0.88, 1)), (0.86, (0.66, 0.56, 0.88, 1)), (0.9, (0.1, 0.05, 0.18, 1)), (1.0, (0.1, 0.05, 0.18, 1))], "CONSTANT")
    pupila = rampa(nt, dist.outputs["Value"], [(0.0, (0.05, 0.02, 0.08, 1)), (0.13, (0.05, 0.02, 0.08, 1)), (0.14, (1, 1, 1, 1)), (1.0, (1, 1, 1, 1))], "CONSTANT")
    frente = rampa(nt, sep.outputs["Y"], [(0.0, (1, 1, 1, 1)), (0.45, (1, 1, 1, 1)), (0.5, (0, 0, 0, 1)), (1.0, (0, 0, 0, 1))], "CONSTANT")
    # só a metade da frente (y < 0) tem o desenho; atrás é branco
    m1 = no(nt, "ShaderNodeMix", data_type="RGBA", blend_type="MULTIPLY")
    m1.inputs["Factor"].default_value = 1.0
    nt.links.new(cor_aneis.outputs["Color"], m1.inputs["A"])
    nt.links.new(pupila.outputs["Color"], m1.inputs["B"])
    m2 = no(nt, "ShaderNodeMix", data_type="RGBA", blend_type="MIX")
    nt.links.new(frente.outputs["Color"], m2.inputs["Factor"])
    m2.inputs["A"].default_value = (0.93, 0.92, 0.95, 1)
    nt.links.new(m1.outputs["Result"], m2.inputs["B"])
    nt.links.new(m2.outputs["Result"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.08
    bsdf.inputs["Metallic"].default_value = 0.0


leque()
mao(1)
mao(-1)
olho()

MATS = {
    "leque_placa": mat_placa, "leque_aro": mat_ferro, "leque_cabo": mat_couro, "leque_pomo": mat_ouro,
    "leque_costelas": mat_ouro, "olho_globo": mat_olho,
}
for lado in "DE":
    MATS["maos_argila" + lado] = mat_argila
    MATS["maos_labios" + lado] = mat_simples((0.55, 0.32, 0.28, 1), 0.6)
    MATS["maos_boca" + lado] = mat_simples((0.12, 0.02, 0.03, 1), 0.4)
    MATS["maos_dentes" + lado] = mat_simples((0.92, 0.9, 0.82, 1), 0.3)

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

# prévia: os três lado a lado, de frente (câmera em -Y)
for ob in cena.objects:
    if ob.name.startswith("maos"):
        ob.location = (3.2, 0, 1.2)
    elif ob.name.startswith("olho"):
        ob.location = (6.4, 0, 1.4)
alvo = bpy.data.objects.new("alvo", None)
alvo.location = (3.2, 0, 1.3)
cena.collection.objects.link(alvo)
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
cam.data.lens = 40
cam.location = (3.6, -10.5, 2.6)
cena.collection.objects.link(cam)
cena.camera = cam
tr = cam.constraints.new("TRACK_TO")
tr.target = alvo
tr.track_axis = "TRACK_NEGATIVE_Z"
tr.up_axis = "UP_Y"
for nome, loc, en in (("chave", (-2, -6, 6), 1400), ("preench", (9, -5, 2), 500), ("recorte", (3, 6, 4), 900)):
    l = bpy.data.objects.new(nome, bpy.data.lights.new(nome, "AREA"))
    l.data.energy = en
    l.data.size = 4
    l.location = loc
    t = l.constraints.new("TRACK_TO")
    t.target = alvo
    t.track_axis = "TRACK_NEGATIVE_Z"
    t.up_axis = "UP_Y"
    cena.collection.objects.link(l)
mundo = bpy.data.worlds.new("mundo")
mundo.use_nodes = True
mundo.node_tree.nodes["Background"].inputs["Color"].default_value = (0.012, 0.012, 0.016, 1)
cena.world = mundo
cena.cycles.samples = 48
cena.render.resolution_x = 1200
cena.render.resolution_y = 700
cena.render.filepath = PREVIA
bpy.ops.render.render(write_still=True)
print("PREVIA", PREVIA)
