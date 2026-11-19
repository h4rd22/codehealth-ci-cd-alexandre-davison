# Katana realista (família Comum = ferro simples) feita no Blender:
# lâmina com shinogi (chanfro), sori (curva), kissaki (ponta), habaki, tsuba vazada,
# fuchi/kashira e tsuka com ito (trama de seda) modelada por cima da samegawa.
# Texturas PBR (cor, normal, aspereza, metal) feitas por nós procedurais e assadas em imagem.
# Uso: blender --background --python katana_realista.py -- <saida_dir> [previa.png]
import bpy, bmesh, math, os, sys
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
SAIDA = args[0] if args else r"D:\Claude\jogo-roblox\modelos\prontos"
PREVIA = args[1] if len(args) > 1 else os.path.join(SAIDA, "katana_previa.png")
TEX = 512
os.makedirs(os.path.join(SAIDA, "tex"), exist_ok=True)

bpy.ops.wm.read_factory_settings(use_empty=True)
cena = bpy.context.scene
cena.render.engine = "CYCLES"
cena.cycles.device = "CPU"
cena.cycles.samples = 16


# ------------------------------------------------------------------ geometria
def malha(nome, bm):
    me = bpy.data.meshes.new(nome)
    bm.normal_update()
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(nome, me)
    cena.collection.objects.link(ob)
    return ob


def loft(secoes, fechar_ini=True, fechar_fim=True):
    bm = bmesh.new()
    aneis = [[bm.verts.new(p) for p in s] for s in secoes]
    n = len(secoes[0])
    for a, b in zip(aneis, aneis[1:]):
        for i in range(n):
            j = (i + 1) % n
            bm.faces.new((a[i], a[j], b[j], b[i]))
    if fechar_ini:
        bm.faces.new(list(reversed(aneis[0])))
    if fechar_fim:
        bm.faces.new(aneis[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bm


L = 3.7          # comprimento da lâmina (Z+)
W = 0.26         # largura na base
T = 0.05         # espessura no shinogi
SORI = 0.22      # curva (a ponta vai para as costas, -X)
KISS = 0.13      # fração final que é a ponta


def lamina():
    secoes = []
    N = 48
    for i in range(N + 1):
        t = i / N
        z = L * t
        xc = -SORI * t * t
        w = W * (1 - 0.3 * t)
        if t > 1 - KISS:  # kissaki: o fio sobe em arco até encontrar as costas
            k = (t - (1 - KISS)) / KISS
            fio = w / 2 - w * (1 - math.sqrt(max(0.0, 1 - k * k)))
        else:
            fio = w / 2
        costas = -w / 2
        largura = fio - costas
        if largura < 0.004:
            largura = 0.004
        shin = costas + largura * 0.3  # linha do shinogi perto das costas
        esp = T * (1 - 0.35 * t) * (1 if t < 1 - KISS else max(0.15, 1 - (t - (1 - KISS)) / KISS))
        secoes.append([
            Vector((xc + costas + largura, 0, z)),          # fio (ha)
            Vector((xc + shin, esp / 2, z)),                 # shinogi +
            Vector((xc + costas + 0.012, esp * 0.32, z)),    # mune +
            Vector((xc + costas - 0.006, 0, z)),             # cume do mune (iori)
            Vector((xc + costas + 0.012, -esp * 0.32, z)),   # mune -
            Vector((xc + shin, -esp / 2, z)),                # shinogi -
        ])
    secoes[-1] = [Vector((secoes[-1][3].x + 0.01, 0, L + 0.02))] * 6
    return malha("katana_lamina", loft(secoes, True, False))


def habaki():
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1)
    bmesh.ops.scale(bm, vec=(W * 1.04, T * 1.45, 0.11), verts=bm.verts)
    bmesh.ops.translate(bm, verts=bm.verts, vec=(0, 0, 0.055))
    bmesh.ops.bevel(bm, geom=list(bm.edges), offset=0.006, segments=2, affect="EDGES")
    return malha("katana_habaki", bm)


def tsuba():
    # desenho próprio: contorno de 4 lóbulos (mokko), borda alta (mimi),
    # lua crescente vazada de um lado e três furinhos de nuvem do outro
    def raio(a):
        return 0.33 * (1 + 0.075 * math.cos(4 * a))
    ext = [Vector((1.06 * raio(a) * math.cos(a), raio(a) * math.sin(a), 0)) for a in [2 * math.pi * i / 96 for i in range(96)]]
    bm = bmesh.new()
    vs_b = [bm.verts.new(p + Vector((0, 0, -0.022))) for p in ext]
    vs_t = [bm.verts.new(p + Vector((0, 0, 0.022))) for p in ext]
    n = len(ext)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((vs_b[i], vs_b[j], vs_t[j], vs_t[i]))
    bm.faces.new(list(reversed(vs_b)))
    bm.faces.new(vs_t)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    ob = malha("katana_tsuba", bm)
    # borda alta: tubo achatado seguindo o contorno
    aro = bmesh.new()
    prev = None
    primeiro = None
    for i in range(n + 1):
        p = ext[i % n]
        rad = Vector((p.x, p.y, 0)).normalized()
        q = [aro.verts.new(p + rad * d + Vector((0, 0, z))) for d, z in ((-0.03, -0.032), (0.004, -0.032), (0.004, 0.032), (-0.03, 0.032))]
        if i == n:
            q = primeiro
        if prev:
            for k in range(4):
                aro.faces.new((prev[k], prev[(k + 1) % 4], q[(k + 1) % 4], q[k]))
        if primeiro is None:
            primeiro = q
        prev = q
    bmesh.ops.recalc_face_normals(aro, faces=aro.faces)
    aro_ob = malha("tmp_aro", aro)

    def cortar(alvo, ferramenta):
        mod = alvo.modifiers.new("corte", "BOOLEAN")
        mod.operation = "DIFFERENCE"
        mod.object = ferramenta
        bpy.context.view_layer.objects.active = alvo
        bpy.ops.object.modifier_apply(modifier=mod.name)
        bpy.data.objects.remove(ferramenta)

    def cilindro(r, x, y):
        bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=r, depth=0.2, location=(x, y, 0))
        return bpy.context.active_object

    # lua crescente: círculo grande menos um deslocado
    lua = cilindro(0.085, 0.0, 0.17)
    cortar(lua, cilindro(0.075, 0.04, 0.19))
    cortar(ob, lua)
    for x, y, r in ((-0.05, -0.15, 0.028), (0.02, -0.19, 0.022), (0.065, -0.135, 0.017)):
        cortar(ob, cilindro(r, x, y))
    # furo da lâmina (nakago-ana)
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0))
    furo = bpy.context.active_object
    furo.scale = (W * 0.9, T * 1.6, 0.3)
    cortar(ob, furo)
    # junta a borda na tsuba
    bpy.ops.object.select_all(action="DESELECT")
    aro_ob.select_set(True)
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.join()
    return ob


TSUKA = 1.3
def tsuka():
    # núcleo (samegawa) oval com leve cintura
    secoes = []
    for i in range(25):
        t = i / 24
        z = -0.04 - TSUKA * t
        cint = 1 - 0.07 * math.sin(t * math.pi)
        rx, ry = 0.135 * cint, 0.105 * cint
        secoes.append([Vector((rx * math.cos(a), ry * math.sin(a), z)) for a in [2 * math.pi * k / 16 for k in range(16)]])
    nucleo = malha("katana_same", loft(secoes))
    # ito: duas fitas em hélice cruzada (forma os losangos clássicos)
    bm = bmesh.new()
    voltas = 4
    for sentido in (1, -1):
        pontos = 140
        prev = None
        for i in range(pontos + 1):
            t = i / pontos
            z = -0.08 - (TSUKA - 0.1) * t
            a = sentido * t * voltas * 2 * math.pi
            cint = 1 - 0.07 * math.sin(t * math.pi)
            extra = 0.0 if sentido > 0 else 0.008
            rx, ry = (0.142 + extra) * cint, (0.112 + extra) * cint
            c = Vector((rx * math.cos(a), ry * math.sin(a), z))
            n = Vector((math.cos(a), math.sin(a), 0)).normalized()
            tang = Vector((-math.sin(a) * sentido * rx, math.cos(a) * sentido * ry, -(TSUKA - 0.1) / (voltas * 2 * math.pi))).normalized()
            lado = n.cross(tang).normalized() * 0.06
            esp = n * 0.016
            quad = [bm.verts.new(c + lado), bm.verts.new(c + lado + esp), bm.verts.new(c - lado + esp), bm.verts.new(c - lado)]
            if prev:
                for k in range(4):
                    bm.faces.new((prev[k], prev[(k + 1) % 4], quad[(k + 1) % 4], quad[k]))
            prev = quad
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    ito = malha("katana_ito", bm)
    # fuchi (anel junto à tsuba) e kashira (tampa do cabo)
    def anel(nome, z0, z1, rx, ry, tampa=False):
        secs = []
        for zz, esc in ((z0, 1.0), (z1, 1.0)):
            secs.append([Vector((rx * esc * math.cos(a), ry * esc * math.sin(a), zz)) for a in [2 * math.pi * k / 20 for k in range(20)]])
        if tampa:
            secs.append([Vector((rx * 0.7 * math.cos(a), ry * 0.7 * math.sin(a), z1 - 0.05)) for a in [2 * math.pi * k / 20 for k in range(20)]])
        bm = loft(secs)
        bmesh.ops.bevel(bm, geom=list(bm.edges), offset=0.008, segments=1, affect="EDGES", clamp_overlap=True)
        return malha(nome, bm)
    anel("katana_fuchi", -0.03, -0.12, 0.15, 0.12)
    anel("katana_kashira", -TSUKA - 0.02, -TSUKA - 0.12, 0.15, 0.12, tampa=True)
    return nucleo, ito


partes = [lamina(), habaki(), tsuba(), *tsuka()]
for ob in cena.objects:
    if ob.type == "MESH":
        bpy.ops.object.select_all(action="DESELECT")
        ob.select_set(True)
        bpy.context.view_layer.objects.active = ob
        # arestas vivas (fio, shinogi) ficam duras; superfícies curvas ficam lisas
        bpy.ops.object.shade_smooth_by_angle(angle=math.radians(35))


# ------------------------------------------------------------------ materiais procedurais
def no(nt, tipo, **kw):
    n = nt.nodes.new(tipo)
    for k, v in kw.items():
        setattr(n, k, v)
    return n


def material(nome, cor_fn):
    mat = bpy.data.materials.new(nome)
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    cor_fn(nt, bsdf)
    return mat


def ruido(nt, escala, detalhe=8):
    tc = no(nt, "ShaderNodeTexCoord")
    nz = no(nt, "ShaderNodeTexNoise")
    nz.inputs["Scale"].default_value = escala
    nz.inputs["Detail"].default_value = detalhe
    nt.links.new(tc.outputs["Object"], nz.inputs["Vector"])
    return nz


def rampa(nt, entrada, pares):
    r = no(nt, "ShaderNodeValToRGB")
    els = r.color_ramp.elements
    els[0].position, els[0].color = pares[0]
    els[1].position, els[1].color = pares[-1]
    for pos, cor in pares[1:-1]:
        e = els.new(pos)
        e.color = cor
    nt.links.new(entrada, r.inputs["Fac"])
    return r


def bump(nt, bsdf, altura_out, forca):
    b = no(nt, "ShaderNodeBump")
    b.inputs["Strength"].default_value = forca
    nt.links.new(altura_out, b.inputs["Height"])
    nt.links.new(b.outputs["Normal"], bsdf.inputs["Normal"])


def mat_lamina(nt, bsdf):
    # aço polido com hamon (linha ondulada da têmpera perto do fio) e riscos finos
    tc = no(nt, "ShaderNodeTexCoord")
    sep = no(nt, "ShaderNodeSeparateXYZ")
    nt.links.new(tc.outputs["Object"], sep.inputs["Vector"])
    onda = no(nt, "ShaderNodeTexWave")
    onda.inputs["Scale"].default_value = 3.5
    onda.inputs["Distortion"].default_value = 4.0
    nt.links.new(tc.outputs["Object"], onda.inputs["Vector"])
    zn = no(nt, "ShaderNodeMath", operation="DIVIDE")
    nt.links.new(sep.outputs["Z"], zn.inputs[0])
    zn.inputs[1].default_value = L
    z2 = no(nt, "ShaderNodeMath", operation="POWER")
    nt.links.new(zn.outputs["Value"], z2.inputs[0])
    z2.inputs[1].default_value = 2.0
    curva = no(nt, "ShaderNodeMath", operation="MULTIPLY_ADD")
    nt.links.new(z2.outputs["Value"], curva.inputs[0])
    curva.inputs[1].default_value = SORI
    nt.links.new(sep.outputs["X"], curva.inputs[2])
    soma = no(nt, "ShaderNodeMath", operation="MULTIPLY_ADD")
    nt.links.new(onda.outputs["Fac"], soma.inputs[0])
    soma.inputs[1].default_value = 0.03
    nt.links.new(curva.outputs["Value"], soma.inputs[2])
    # x relativo ao centro da lâmina → hamon onde x > ~0.03
    hamon = rampa(nt, soma.outputs["Value"], [(0.0, (0.3, 0.32, 0.35, 1)), (0.49, (0.36, 0.38, 0.42, 1)), (0.555, (0.95, 0.95, 0.97, 1)), (0.6, (0.82, 0.84, 0.87, 1)), (1.0, (0.9, 0.91, 0.93, 1))])
    hamon.color_ramp.interpolation = "EASE"
    # o rampa de entrada precisa de faixa 0..1: desloca o X (lâmina vai de -0.13 a +0.13)
    mapa = no(nt, "ShaderNodeMapRange")
    mapa.inputs["From Min"].default_value = -0.16
    mapa.inputs["From Max"].default_value = 0.16
    nt.links.new(soma.outputs["Value"], mapa.inputs["Value"])
    nt.links.new(mapa.outputs["Result"], hamon.inputs["Fac"])
    riscos = no(nt, "ShaderNodeTexNoise")
    riscos.inputs["Scale"].default_value = 180
    riscos.inputs["Detail"].default_value = 2
    mapr = no(nt, "ShaderNodeMapping")
    mapr.inputs["Scale"].default_value = (0.05, 1, 1)
    nt.links.new(tc.outputs["Object"], mapr.inputs["Vector"])
    nt.links.new(mapr.outputs["Vector"], riscos.inputs["Vector"])
    nt.links.new(hamon.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Metallic"].default_value = 1.0
    rough = rampa(nt, mapa.outputs["Result"], [(0.0, (0.12, 0.12, 0.12, 1)), (0.49, (0.15, 0.15, 0.15, 1)), (0.57, (0.48, 0.48, 0.48, 1)), (1.0, (0.4, 0.4, 0.4, 1))])
    nt.links.new(rough.outputs["Color"], bsdf.inputs["Roughness"])


def mat_ferro_escuro(nt, bsdf):
    # ferro forjado escuro com pontos de ferrugem e desgaste nas bordas
    nz = ruido(nt, 22, 10)
    cor = rampa(nt, nz.outputs["Fac"], [(0.0, (0.06, 0.06, 0.065, 1)), (0.55, (0.12, 0.115, 0.11, 1)), (0.72, (0.24, 0.12, 0.06, 1)), (1.0, (0.3, 0.16, 0.08, 1))])
    nt.links.new(cor.outputs["Color"], bsdf.inputs["Base Color"])
    met = rampa(nt, nz.outputs["Fac"], [(0.0, (1, 1, 1, 1)), (0.65, (0.85, 0.85, 0.85, 1)), (0.75, (0.1, 0.1, 0.1, 1)), (1.0, (0.0, 0.0, 0.0, 1))])
    nt.links.new(met.outputs["Color"], bsdf.inputs["Metallic"])
    rgh = rampa(nt, nz.outputs["Fac"], [(0.0, (0.45, 0.45, 0.45, 1)), (1.0, (0.85, 0.85, 0.85, 1))])
    nt.links.new(rgh.outputs["Color"], bsdf.inputs["Roughness"])
    bump(nt, bsdf, nz.outputs["Fac"], 0.35)


def mat_latao(nt, bsdf):
    nz = ruido(nt, 40, 6)
    cor = rampa(nt, nz.outputs["Fac"], [(0.0, (0.55, 0.38, 0.12, 1)), (1.0, (0.78, 0.6, 0.25, 1))])
    nt.links.new(cor.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Metallic"].default_value = 1.0
    bsdf.inputs["Roughness"].default_value = 0.32
    bump(nt, bsdf, nz.outputs["Fac"], 0.1)


def mat_seda(nt, bsdf):
    # ito: seda trançada azul-marinho com fios finos
    tc = no(nt, "ShaderNodeTexCoord")
    onda = no(nt, "ShaderNodeTexWave")
    onda.inputs["Scale"].default_value = 90
    onda.inputs["Distortion"].default_value = 1.5
    nt.links.new(tc.outputs["Object"], onda.inputs["Vector"])
    cor = rampa(nt, onda.outputs["Fac"], [(0.0, (0.015, 0.02, 0.05, 1)), (1.0, (0.05, 0.06, 0.13, 1))])
    nt.links.new(cor.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Metallic"].default_value = 0.0
    bsdf.inputs["Roughness"].default_value = 0.6
    bump(nt, bsdf, onda.outputs["Fac"], 0.4)


def mat_same(nt, bsdf):
    # samegawa: pele de arraia clara com nódulos
    tc = no(nt, "ShaderNodeTexCoord")
    vor = no(nt, "ShaderNodeTexVoronoi")
    vor.inputs["Scale"].default_value = 120
    nt.links.new(tc.outputs["Object"], vor.inputs["Vector"])
    cor = rampa(nt, vor.outputs["Distance"], [(0.0, (0.9, 0.88, 0.8, 1)), (1.0, (0.62, 0.58, 0.5, 1))])
    nt.links.new(cor.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Metallic"].default_value = 0.0
    bsdf.inputs["Roughness"].default_value = 0.55
    bump(nt, bsdf, vor.outputs["Distance"], 0.5)


MATS = {
    "katana_lamina": mat_lamina,
    "katana_habaki": mat_latao,
    "katana_tsuba": mat_ferro_escuro,
    "katana_fuchi": mat_ferro_escuro,
    "katana_kashira": mat_ferro_escuro,
    "katana_ito": mat_seda,
    "katana_same": mat_same,
}

# ------------------------------------------------------------------ UV + bake das texturas PBR
def ligar_imagem(nt, img, saida_para, nao_cor=False):
    t = nt.nodes.new("ShaderNodeTexImage")
    t.image = img
    if nao_cor:
        img.colorspace_settings.name = "Non-Color"
    nt.nodes.active = t
    return t


for ob in list(cena.objects):
    if ob.type != "MESH":
        continue
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.02)
    bpy.ops.object.mode_set(mode="OBJECT")
    mat = material(ob.name + "_mat", MATS[ob.name])
    ob.data.materials.clear()
    ob.data.materials.append(mat)

imagens = {}
for ob in [o for o in cena.objects if o.type == "MESH"]:
    nt = ob.data.materials[0].node_tree
    bsdf = nt.nodes["Principled BSDF"]
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    res = {}
    for passo, tipo in (("cor", "EMIT"), ("rough", "ROUGHNESS"), ("normal", "NORMAL"), ("metal", "EMIT")):
        img = bpy.data.images.new(f"{ob.name}_{passo}", TEX, TEX, alpha=False)
        t = ligar_imagem(nt, img, None, passo != "cor")
        ligacao_emit = None
        if tipo == "EMIT":
            # cor e metal: liga a entrada do BSDF numa emissão e assa a emissão
            # (assar "diffuse" de metal dá preto)
            emi = nt.nodes.new("ShaderNodeEmission")
            entrada = bsdf.inputs["Base Color" if passo == "cor" else "Metallic"]
            if entrada.is_linked:
                nt.links.new(entrada.links[0].from_socket, emi.inputs["Color"])
            else:
                v = entrada.default_value
                emi.inputs["Color"].default_value = tuple(v) if passo == "cor" else (v, v, v, 1)
            saida = nt.nodes["Material Output"]
            antigo = saida.inputs["Surface"].links[0].from_socket
            nt.links.new(emi.outputs["Emission"], saida.inputs["Surface"])
            ligacao_emit = (antigo, emi)
        bpy.ops.object.bake(type=tipo, margin=4)
        img.filepath_raw = os.path.join(SAIDA, "tex", f"{ob.name}_{passo}.png")
        img.file_format = "PNG"
        img.save()
        if ligacao_emit:
            antigo, emi = ligacao_emit
            nt.links.new(antigo, nt.nodes["Material Output"].inputs["Surface"])
            nt.nodes.remove(emi)
        nt.nodes.remove(t)
        res[passo] = img
    imagens[ob.name] = res

# troca os materiais procedurais pelos mapas assados (é isso que vai no GLB)
for ob in [o for o in cena.objects if o.type == "MESH"]:
    res = imagens[ob.name]
    mat = bpy.data.materials.new(ob.name + "_pbr")
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    def tex(img, nao_cor):
        t = nt.nodes.new("ShaderNodeTexImage")
        t.image = img
        img.colorspace_settings.name = "Non-Color" if nao_cor else "sRGB"
        return t
    nt.links.new(tex(res["cor"], False).outputs["Color"], bsdf.inputs["Base Color"])
    nt.links.new(tex(res["rough"], True).outputs["Color"], bsdf.inputs["Roughness"])
    nt.links.new(tex(res["metal"], True).outputs["Color"], bsdf.inputs["Metallic"])
    nm = nt.nodes.new("ShaderNodeNormalMap")
    nt.links.new(tex(res["normal"], True).outputs["Color"], nm.inputs["Color"])
    nt.links.new(nm.outputs["Normal"], bsdf.inputs["Normal"])
    ob.data.materials.clear()
    ob.data.materials.append(mat)

tris = sum(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in cena.objects if o.type == "MESH")
bpy.ops.export_scene.gltf(filepath=os.path.join(SAIDA, "katana_comum.glb"), export_format="GLB", export_image_format="AUTO", export_yup=True)
print("TRIS", tris)

# ------------------------------------------------------------------ prévias
def luz_area(nome, loc, energia, tam):
    l = bpy.data.objects.new(nome, bpy.data.lights.new(nome, "AREA"))
    l.data.energy = energia
    l.data.size = tam
    l.location = loc
    tr = l.constraints.new("TRACK_TO")
    tr.target = alvo
    tr.track_axis = "TRACK_NEGATIVE_Z"
    tr.up_axis = "UP_Y"
    cena.collection.objects.link(l)

alvo = bpy.data.objects.new("alvo", None)
alvo.location = (0, 0, 1.15)
cena.collection.objects.link(alvo)
luz_area("chave", (-3, -4, 4), 900, 3)
luz_area("preench", (4, -3, 1), 250, 4)
luz_area("recorte", (0.5, 4, 3), 700, 2)
mundo = bpy.data.worlds.new("mundo")
mundo.use_nodes = True
mundo.node_tree.nodes["Background"].inputs["Color"].default_value = (0.012, 0.012, 0.016, 1)
cena.world = mundo
cena.cycles.samples = 64
cena.render.resolution_x = 900
cena.render.resolution_y = 900
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
cena.collection.objects.link(cam)
cena.camera = cam
trc = cam.constraints.new("TRACK_TO")
trc.target = alvo
trc.track_axis = "TRACK_NEGATIVE_Z"
trc.up_axis = "UP_Y"
# de lado (mostra o lado largo, o hamon e o chanfro)
cam.data.lens = 55
cam.location = (0.2, -9.0, 1.15)
cena.render.filepath = PREVIA
bpy.ops.render.render(write_still=True)
# detalhe do cabo e da tsuba em 3/4
alvo.location = (0, 0, -0.35)
cam.data.lens = 85
cam.location = (2.2, -2.6, 1.3)
cena.render.filepath = PREVIA.replace(".png", "_detalhe.png")
bpy.ops.render.render(write_still=True)
print("PREVIA", PREVIA)
