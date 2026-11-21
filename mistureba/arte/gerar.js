// Gera a arte original do Mistureba (ícone, capas, passes, produtos) em PNG.
const { chromium } = require('playwright');
const path = require('path');
const D = __dirname;
const OUT = path.join(D, 'out');
require('fs').mkdirSync(OUT, { recursive: true });

let uid = 0;
const id = (p) => `${p}${++uid}`;
const OUT_STROKE = '#2a1440';

// ---------- peças ----------
function sparkle(x, y, s, c = '#fff') {
  return `<path transform="translate(${x} ${y}) scale(${s})" d="M0,-10 C1.5,-2 2,-1.5 10,0 C2,1.5 1.5,2 0,10 C-1.5,2 -2,1.5 -10,0 C-2,-1.5 -1.5,-2 0,-10Z" fill="${c}"/>`;
}

function egg(x, y, s, c1, c2, spot = '#ffffff', rot = 0, glow = null) {
  const g = id('eg');
  return `<g transform="translate(${x} ${y}) rotate(${rot}) scale(${s})">
  <defs><radialGradient id="${g}" cx="35%" cy="30%" r="80%"><stop offset="0" stop-color="${c1}"/><stop offset="1" stop-color="${c2}"/></radialGradient></defs>
  ${glow ? `<ellipse cx="0" cy="6" rx="70" ry="84" fill="${glow}" opacity=".35" filter="url(#blur)"/>` : ''}
  <ellipse cx="0" cy="62" rx="40" ry="9" fill="#000" opacity=".18"/>
  <path d="M0,-60 C32,-60 50,-10 50,18 C50,48 28,62 0,62 C-28,62 -50,48 -50,18 C-50,-10 -32,-60 0,-60Z" fill="url(#${g})" stroke="${OUT_STROKE}" stroke-width="5"/>
  <ellipse cx="-18" cy="-6" rx="9" ry="12" fill="${spot}" opacity=".85"/>
  <ellipse cx="20" cy="20" rx="12" ry="9" fill="${spot}" opacity=".85"/>
  <ellipse cx="-8" cy="36" rx="6" ry="5" fill="${spot}" opacity=".85"/>
  <ellipse cx="14" cy="-30" rx="6" ry="7" fill="${spot}" opacity=".85"/>
  <path d="M-28,-24 C-24,-40 -14,-50 -4,-52" stroke="#fff" stroke-width="8" stroke-linecap="round" fill="none" opacity=".75"/>
  </g>`;
}

// Bichinho original: corpo redondo + detalhe por tipo
function critter(x, y, s, body, belly, tipo = 'basico', extra = {}) {
  const g = id('cb');
  const dark = OUT_STROKE;
  let top = '';
  if (tipo === 'coelho')
    top = `<path d="M-30,-48 C-44,-120 -14,-124 -12,-58Z" fill="${body}" stroke="${dark}" stroke-width="5"/><path d="M30,-48 C44,-120 14,-124 12,-58Z" fill="${body}" stroke="${dark}" stroke-width="5"/><path d="M-26,-60 C-34,-100 -20,-104 -18,-64Z" fill="${belly}"/><path d="M26,-60 C34,-100 20,-104 18,-64Z" fill="${belly}"/>`;
  if (tipo === 'tubarao') top = `<path d="M-10,-58 C0,-110 30,-110 34,-104 C20,-90 22,-70 26,-52Z" fill="${body}" stroke="${dark}" stroke-width="5"/>`;
  if (tipo === 'dragao')
    top = `<path d="M-34,-44 L-50,-92 L-16,-58Z" fill="#ffe27a" stroke="${dark}" stroke-width="5" stroke-linejoin="round"/><path d="M34,-44 L50,-92 L16,-58Z" fill="#ffe27a" stroke="${dark}" stroke-width="5" stroke-linejoin="round"/>
    <path d="M-62,0 C-120,-40 -120,30 -80,40 C-90,20 -76,10 -62,20Z" fill="${belly}" stroke="${dark}" stroke-width="5"/><path d="M62,0 C120,-40 120,30 80,40 C90,20 76,10 62,20Z" fill="${belly}" stroke="${dark}" stroke-width="5"/>`;
  if (tipo === 'gato')
    top = `<path d="M-50,-30 L-46,-92 L-8,-60Z" fill="${body}" stroke="${dark}" stroke-width="5" stroke-linejoin="round"/><path d="M50,-30 L46,-92 L8,-60Z" fill="${body}" stroke="${dark}" stroke-width="5" stroke-linejoin="round"/><path d="M-40,-46 L-40,-76 L-20,-58Z" fill="#ff9ec4"/><path d="M40,-46 L40,-76 L20,-58Z" fill="#ff9ec4"/>`;
  if (tipo === 'chifre')
    top = `<path d="M-8,-60 L0,-120 L8,-60Z" fill="url(#ouro)" stroke="${dark}" stroke-width="5" stroke-linejoin="round"/>`;
  if (tipo === 'antena')
    top = `<path d="M-14,-60 C-20,-90 -30,-96 -36,-100" stroke="${dark}" stroke-width="5" fill="none"/><circle cx="-38" cy="-102" r="10" fill="#fff36b" stroke="${dark}" stroke-width="4"/><path d="M14,-60 C20,-90 30,-96 36,-100" stroke="${dark}" stroke-width="5" fill="none"/><circle cx="38" cy="-102" r="10" fill="#fff36b" stroke="${dark}" stroke-width="4"/>`;
  const crown = extra.coroa
    ? `<g transform="translate(0 -70)"><path d="M-40,10 L-46,-34 L-22,-12 L0,-44 L22,-12 L46,-34 L40,10Z" fill="url(#ouro)" stroke="${dark}" stroke-width="5" stroke-linejoin="round"/><circle cx="0" cy="-8" r="7" fill="#ff4f7b" stroke="${dark}" stroke-width="3"/></g>`
    : '';
  const flip = extra.flip ? -1 : 1;
  const olhoX = extra.olhar || 0;
  return `<g transform="translate(${x} ${y}) scale(${s * flip} ${s})">
  <defs><radialGradient id="${g}" cx="35%" cy="28%" r="85%"><stop offset="0" stop-color="#ffffff" stop-opacity=".55"/><stop offset=".35" stop-color="${body}" stop-opacity="0"/></radialGradient></defs>
  <ellipse cx="0" cy="72" rx="62" ry="12" fill="#000" opacity=".18"/>
  ${top}
  <ellipse cx="-30" cy="60" rx="20" ry="13" fill="${body}" stroke="${dark}" stroke-width="5"/>
  <ellipse cx="30" cy="60" rx="20" ry="13" fill="${body}" stroke="${dark}" stroke-width="5"/>
  <path d="M0,-66 C50,-66 70,-30 70,8 C70,48 42,66 0,66 C-42,66 -70,48 -70,8 C-70,-30 -50,-66 0,-66Z" fill="${body}" stroke="${dark}" stroke-width="5"/>
  <path d="M0,-66 C50,-66 70,-30 70,8 C70,48 42,66 0,66 C-42,66 -70,48 -70,8 C-70,-30 -50,-66 0,-66Z" fill="url(#${g})"/>
  <ellipse cx="0" cy="30" rx="40" ry="28" fill="${belly}"/>
  <g transform="translate(${olhoX} 0)">
  <ellipse cx="-24" cy="-12" rx="17" ry="20" fill="#fff" stroke="${dark}" stroke-width="4"/>
  <ellipse cx="24" cy="-12" rx="17" ry="20" fill="#fff" stroke="${dark}" stroke-width="4"/>
  <ellipse cx="-21" cy="-9" rx="10" ry="13" fill="${dark}"/><ellipse cx="27" cy="-9" rx="10" ry="13" fill="${dark}"/>
  <circle cx="-17" cy="-15" r="4.5" fill="#fff"/><circle cx="31" cy="-15" r="4.5" fill="#fff"/>
  </g>
  <ellipse cx="-44" cy="12" rx="10" ry="6" fill="#ff6fa3" opacity=".6"/><ellipse cx="44" cy="12" rx="10" ry="6" fill="#ff6fa3" opacity=".6"/>
  <path d="M-14,14 C-8,26 8,26 14,14" stroke="${dark}" stroke-width="5" fill="#ff7a8a" stroke-linecap="round"/>
  ${extra.faixa ? `<path d="M-68,-36 C-30,-48 30,-48 68,-36 L66,-22 C30,-32 -30,-32 -66,-22Z" fill="${extra.faixa}" stroke="${dark}" stroke-width="4"/>` : ''}
  ${crown}
  </g>`;
}

const DEFS = `<defs>
<filter id="blur" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="14"/></filter>
<filter id="sombra" x="-20%" y="-20%" width="140%" height="140%"><feDropShadow dx="0" dy="8" stdDeviation="6" flood-color="#000" flood-opacity=".35"/></filter>
<linearGradient id="ouro" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff6a8"/><stop offset=".5" stop-color="#ffcc2e"/><stop offset="1" stop-color="#f08a00"/></linearGradient>
<linearGradient id="arco" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#ff5b8a"/><stop offset=".25" stop-color="#ffb13b"/><stop offset=".5" stop-color="#fff35c"/><stop offset=".75" stop-color="#4fe39a"/><stop offset="1" stop-color="#5aa8ff"/></linearGradient>
<linearGradient id="diamante" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#e9fdff"/><stop offset=".5" stop-color="#7fe3ff"/><stop offset="1" stop-color="#3f8cff"/></linearGradient>
</defs>`;

function raios(w, h, cx, cy, c1, c2, n = 24) {
  let s = `<rect width="${w}" height="${h}" fill="${c1}"/>`;
  const R = Math.max(w, h) * 1.5;
  for (let i = 0; i < n; i += 2) {
    const a1 = (i / n) * Math.PI * 2, a2 = ((i + 1) / n) * Math.PI * 2;
    s += `<path d="M${cx},${cy} L${cx + R * Math.cos(a1)},${cy + R * Math.sin(a1)} L${cx + R * Math.cos(a2)},${cy + R * Math.sin(a2)}Z" fill="${c2}"/>`;
  }
  return s;
}

function nuvem(x, y, s) {
  return `<g transform="translate(${x} ${y}) scale(${s})" fill="#fff" opacity=".9"><circle cx="0" cy="0" r="40"/><circle cx="45" cy="-15" r="50"/><circle cx="95" cy="0" r="38"/><rect x="0" y="0" width="95" height="38"/></g>`;
}

function texto(x, y, size, str, fill = '#fff', stroke = OUT_STROKE, rot = 0, font = 'Luckiest Guy') {
  const sw = Math.max(6, size * 0.16);
  return `<g transform="translate(${x} ${y}) rotate(${rot})" filter="url(#sombra)"><text x="0" y="0" text-anchor="middle" font-family="${font}" font-size="${size}" fill="${fill}" stroke="${stroke}" stroke-width="${sw}" stroke-linejoin="round" paint-order="stroke" letter-spacing="2">${str}</text></g>`;
}

function arcoIris(cx, cy, r, w) {
  const cores = ['#ff5b6e', '#ff9f3b', '#ffe14d', '#57e389', '#4fb6ff', '#a77bff'];
  return cores.map((c, i) => `<path d="M${cx - (r - i * w)},${cy} A${r - i * w},${r - i * w} 0 0 1 ${cx + (r - i * w)},${cy}" stroke="${c}" stroke-width="${w + 1}" fill="none"/>`).join('');
}

function moeda(x, y, s) {
  return `<g transform="translate(${x} ${y}) scale(${s})"><circle r="30" fill="url(#ouro)" stroke="${OUT_STROKE}" stroke-width="5"/><circle r="19" fill="none" stroke="#e08a00" stroke-width="4"/><text y="11" text-anchor="middle" font-family="Luckiest Guy" font-size="30" fill="#c06a00">M</text></g>`;
}

function svg(w, h, conteudo) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">${DEFS}${conteudo}</svg>`;
}

// ---------- cores dos bichos ----------
const C = {
  verde: ['#6fe07a', '#d8ffc9'], azul: ['#5ab8ff', '#d6efff'], rosa: ['#ff8fc7', '#ffe0f0'],
  roxo: ['#b07bff', '#eadcff'], laranja: ['#ffa94d', '#ffe6c7'], amarelo: ['#ffd93b', '#fff6c4'],
  ciano: ['#4fe3d0', '#d4fff8'], vermelho: ['#ff6b6b', '#ffe0e0'],
};

// ---------- imagens ----------
const imgs = {};

imgs.icone = [512, 512, () => svg(512, 512, `
  ${raios(512, 512, 256, 270, '#ffb52e', '#ffd25a', 28)}
  <circle cx="256" cy="280" r="190" fill="#fff6a8" opacity=".55" filter="url(#blur)"/>
  ${egg(256, 300, 2.7, '#fff6a8', '#ffb300', '#ffffff', 0, '#fff')}
  <path d="M120,260 L160,230 L190,262 L226,228 L256,262 L290,226 L322,262 L356,230 L392,262 L392,420 L120,420Z" fill="#fff" opacity="0"/>
  ${critter(256, 220, 1.35, ...C.rosa, 'coelho')}
  <path d="M128,300 L162,272 L196,302 L228,270 L260,302 L292,268 L324,302 L356,272 L388,300 C388,400 330,456 256,456 C182,456 128,400 128,300Z" fill="url(#ouro)" stroke="${OUT_STROKE}" stroke-width="12" stroke-linejoin="round"/>
  <ellipse cx="200" cy="370" rx="20" ry="16" fill="#fff" opacity=".8"/><ellipse cx="310" cy="400" rx="16" ry="12" fill="#fff" opacity=".8"/>
  ${sparkle(90, 110, 3)}${sparkle(430, 140, 2.4)}${sparkle(420, 380, 1.8, '#fff6a8')}${sparkle(80, 400, 2)}
  ${texto(256, 492, 64, 'MISTUREBA', '#fff')}
`)];

function capa(fundo, conteudo) {
  return () => svg(1920, 1080, fundo + conteudo);
}

const ceu = (c1, c2) => `${raios(1920, 1080, 960, 1300, c1, c2, 40)}
  ${nuvem(120, 160, 1.4)}${nuvem(1550, 120, 1.6)}${nuvem(1300, 330, 0.9)}${nuvem(380, 380, 0.8)}
  <path d="M0,820 C400,740 700,800 960,780 C1300,750 1600,720 1920,800 L1920,1080 L0,1080Z" fill="#6ad35f"/>
  <path d="M0,880 C500,820 900,880 1200,860 C1500,840 1700,830 1920,870 L1920,1080 L0,1080Z" fill="#4dbb4a"/>`;

imgs.capa1 = [1920, 1080, capa(ceu('#7fd4ff', '#a3e3ff'), `
  ${arcoIris(960, 900, 760, 34)}
  ${egg(330, 760, 1.6, '#e0f4ff', '#5ab8ff')}${egg(1590, 770, 1.7, '#ffe0f0', '#ff6fb0')}${egg(1180, 820, 1.1, '#fff6a8', '#ffb300')}${egg(700, 840, 1.0, '#eadcff', '#a06bff')}
  ${critter(520, 800, 1.6, ...C.verde, 'dragao')}
  ${critter(960, 790, 1.9, ...C.rosa, 'coelho', { coroa: true })}
  ${critter(1400, 800, 1.6, ...C.azul, 'tubarao', { flip: true })}
  ${critter(190, 900, 1.1, ...C.laranja, 'gato')}
  ${critter(1760, 910, 1.1, ...C.roxo, 'antena', { flip: true })}
  ${texto(960, 300, 230, 'MISTUREBA', 'url(#arco)')}
  ${texto(960, 450, 120, 'ROUBE E FUNDA!', '#fff36b')}
  ${sparkle(300, 330, 4)}${sparkle(1640, 360, 4.5)}${sparkle(1120, 560, 2.5)}${sparkle(780, 600, 2)}
`)];

imgs.capa2 = [1920, 1080, capa(ceu('#c49bff', '#d8bcff'), `
  ${critter(360, 620, 2.1, ...C.azul, 'tubarao')}
  ${texto(640, 650, 220, '+', '#fff')}
  ${critter(900, 620, 2.1, ...C.laranja, 'gato', { flip: true })}
  ${texto(1170, 650, 200, '=', '#fff')}
  <circle cx="1530" cy="600" r="300" fill="#fff36b" opacity=".6" filter="url(#blur)"/>
  ${critter(1530, 640, 3.0, '#ffd93b', '#fff6c4', 'chifre', { coroa: true })}
  ${sparkle(1300, 340, 4)}${sparkle(1780, 380, 3.5)}${sparkle(1760, 820, 2.5)}${sparkle(1290, 820, 2.2)}
  ${texto(960, 200, 150, 'FUNDA E CRIE', '#fff')}
  ${texto(960, 340, 130, 'MISTUREBAS RARAS!', '#fff36b')}
`)];

imgs.capa3 = [1920, 1080, capa(ceu('#ff9ec4', '#ffbedb'), `
  <circle cx="420" cy="640" r="230" fill="#ffd93b" opacity=".5" filter="url(#blur)"/>
  <circle cx="960" cy="640" r="230" fill="#7fe3ff" opacity=".5" filter="url(#blur)"/>
  <circle cx="1500" cy="640" r="250" fill="#ff7bd5" opacity=".5" filter="url(#blur)"/>
  ${critter(420, 680, 2.2, '#ffcc2e', '#fff3a6', 'gato')}
  ${critter(960, 680, 2.2, '#7fe3ff', '#e9fdff', 'chifre')}
  ${critter(1500, 680, 2.4, '#ff7bd5', '#fff36b', 'dragao', { flip: true })}
  ${texto(400, 960, 66, 'DOURADA x2', '#fff36b')}
  ${texto(960, 960, 66, 'DIAMANTE x3', '#bff6ff')}
  ${texto(1530, 960, 66, 'ARCO-ÍRIS x5', 'url(#arco)')}
  ${texto(960, 250, 170, 'MUTAÇÕES!', 'url(#arco)')}
  ${sparkle(250, 420, 3)}${sparkle(1120, 430, 3)}${sparkle(1700, 400, 3.5)}${sparkle(760, 470, 2)}
`)];

imgs.capa4 = [1920, 1080, capa(ceu('#6fe0b0', '#9cefcb'), `
  ${egg(380, 640, 2.4, '#e0f4ff', '#5ab8ff', '#fff', -12)}
  ${egg(1540, 640, 2.4, '#fff6a8', '#ffb300', '#fff', 12)}
  <g transform="translate(960 640)">
    <rect x="-300" y="-230" width="600" height="440" rx="40" fill="#fff" stroke="${OUT_STROKE}" stroke-width="12"/>
    ${[0, 1, 2].map((i) => `<rect x="-250" y="${-170 + i * 130}" width="80" height="80" rx="16" fill="#57e389" stroke="${OUT_STROKE}" stroke-width="8"/><path d="M-232,${-130 + i * 130} L-214,${-110 + i * 130} L-184,${-150 + i * 130}" stroke="#fff" stroke-width="14" fill="none" stroke-linecap="round" stroke-linejoin="round"/><rect x="-140" y="${-150 + i * 130}" width="${360 - i * 60}" height="40" rx="20" fill="#e6dcff"/>`).join('')}
  </g>
  ${critter(1230, 860, 1.4, ...C.verde, 'coelho', { flip: true })}
  ${critter(700, 880, 1.2, ...C.vermelho, 'antena')}
  ${texto(960, 230, 150, 'MISSÕES DIÁRIAS', '#fff')}
  ${texto(960, 1030, 100, 'OVO GRÁTIS A CADA 5 MIN!', '#fff36b')}
  ${sparkle(240, 330, 3)}${sparkle(1700, 330, 3)}
`)];

// ---------- passes e produtos (512) ----------
function cartao(c1, c2, conteudo, rotulo, corRotulo = '#fff') {
  return () => svg(512, 512, `${raios(512, 512, 256, 256, c1, c2, 24)}
  <circle cx="256" cy="240" r="170" fill="#fff" opacity=".35" filter="url(#blur)"/>
  ${conteudo}
  ${rotulo ? texto(256, 480, rotulo.length > 9 ? 62 : 80, rotulo, corRotulo) : ''}`);
}

imgs.passe_vip = [512, 512, cartao('#ffb52e', '#ffd25a', `${critter(256, 250, 1.9, '#ffd93b', '#fff6c4', 'gato', { coroa: true })}${moeda(90, 120, 1.4)}${moeda(420, 140, 1.2)}${moeda(410, 330, 1)}${sparkle(100, 330, 2.5)}`, 'VIP 2x', '#fff36b')];
imgs.passe_sortedupla = [512, 512, cartao('#57d36b', '#86e692', `
  <g transform="translate(256 220)" stroke="${OUT_STROKE}" stroke-width="8">
    <circle cx="-50" cy="-50" r="62" fill="#3ccf5a"/><circle cx="50" cy="-50" r="62" fill="#3ccf5a"/><circle cx="-50" cy="50" r="62" fill="#3ccf5a"/><circle cx="50" cy="50" r="62" fill="#3ccf5a"/>
    <path d="M0,60 C10,120 30,150 40,170" fill="none" stroke-width="14" stroke-linecap="round"/>
  </g>
  <circle cx="256" cy="220" r="40" fill="#7af08c"/>
  ${egg(120, 380, 0.9, '#fff6a8', '#ffb300')}${egg(400, 380, 0.9, '#ffe0f0', '#ff6fb0')}
  ${sparkle(110, 110, 2.5)}${sparkle(410, 100, 2.2)}
  ${texto(256, 250, 110, '2x', '#fff36b')}`, 'SORTE DUPLA', '#fff')];
imgs.passe_mochila = [512, 512, cartao('#4fa8ff', '#7fc0ff', `
  <g transform="translate(256 250)" stroke="${OUT_STROKE}" stroke-width="8" stroke-linejoin="round">
    <path d="M-60,-120 C-60,-170 60,-170 60,-120" fill="none" stroke-width="14"/>
    <rect x="-120" y="-130" width="240" height="270" rx="60" fill="#ff8a3d"/>
    <rect x="-80" y="10" width="160" height="100" rx="30" fill="#ffb26b"/>
    <path d="M-120,-40 L120,-40" stroke-width="8"/>
  </g>
  ${egg(170, 130, 0.95, '#e0f4ff', '#5ab8ff', '#fff', -18)}${egg(340, 125, 0.95, '#eadcff', '#a06bff', '#fff', 16)}
  ${sparkle(80, 300, 2)}${sparkle(440, 320, 2)}`, 'MOCHILA x2', '#fff')];
imgs.passe_rapido = [512, 512, cartao('#ff5b6e', '#ff8a96', `
  ${[0, 1, 2, 3].map((i) => `<path d="M30,${170 + i * 55} L${180 - i * 20},${170 + i * 55}" stroke="#fff" stroke-width="16" stroke-linecap="round" opacity=".85"/>`).join('')}
  ${critter(300, 250, 1.75, ...C.azul, 'tubarao', { olhar: 8 })}
  <path d="M330,330 L380,250 L350,250 L400,170 L320,270 L350,270Z" fill="#fff36b" stroke="${OUT_STROKE}" stroke-width="7" stroke-linejoin="round" transform="translate(40 -150)"/>`, 'VELOCIDADE', '#fff')];
imgs.passe_cadeado = [512, 512, cartao('#7a5cff', '#9c84ff', `
  <g transform="translate(256 260)" stroke="${OUT_STROKE}" stroke-width="10" stroke-linejoin="round">
    <path d="M-80,-40 L-80,-100 C-80,-200 80,-200 80,-100 L80,-40" fill="none" stroke-width="40" stroke="${OUT_STROKE}"/>
    <path d="M-80,-40 L-80,-100 C-80,-200 80,-200 80,-100 L80,-40" fill="none" stroke-width="24" stroke="#c9d3e6"/>
    <rect x="-130" y="-50" width="260" height="210" rx="40" fill="url(#ouro)"/>
    <circle cx="0" cy="40" r="26" fill="${OUT_STROKE}"/><rect x="-10" y="40" width="20" height="60" rx="8" fill="${OUT_STROKE}"/>
  </g>
  ${sparkle(90, 120, 2.5)}${sparkle(420, 110, 2)}`, '90 SEG', '#fff36b')];
imgs.passe_basegrande = [512, 512, cartao('#3fc9a8', '#6fdcc0', `
  <g transform="translate(256 270)" stroke="${OUT_STROKE}" stroke-width="9" stroke-linejoin="round">
    <path d="M-170,-20 L0,-170 L170,-20Z" fill="#ff6b8a"/>
    <rect x="-140" y="-25" width="280" height="190" fill="#fff4d6"/>
    <rect x="-40" y="60" width="80" height="105" rx="10" fill="#b0763e"/>
    <rect x="-115" y="10" width="60" height="55" rx="8" fill="#9fe3ff"/><rect x="55" y="10" width="60" height="55" rx="8" fill="#9fe3ff"/>
  </g>
  ${texto(410, 140, 110, '+4', '#fff36b')}${sparkle(90, 110, 2.2)}`, 'BASE GRANDE', '#fff')];

imgs.prod_sorte = [512, 512, cartao('#57d36b', '#86e692', `${critter(256, 260, 1.7, ...C.verde, 'antena')}${egg(100, 150, 0.8, '#fff6a8', '#ffb300')}${egg(410, 150, 0.8, '#eadcff', '#a06bff')}${sparkle(256, 80, 3)}${sparkle(90, 330, 2)}${sparkle(430, 330, 2)}`, 'SORTE 2x', '#fff36b')];
imgs.prod_ovoarcoiris = [512, 512, cartao('#ff7bd5', '#ffa3e3', `<circle cx="256" cy="250" r="190" fill="#fff" opacity=".5" filter="url(#blur)"/>${egg(256, 250, 2.6, '#ffffff', '#ff7bd5', '#fff36b', 0)}<path d="M256,92 C326,92 356,200 356,256" stroke="url(#arco)" stroke-width="0"/>${egg(256, 250, 2.6, '#fffbe0', '#a77bff', 'url(#arco)')}${sparkle(90, 110, 3)}${sparkle(420, 120, 2.5)}${sparkle(420, 380, 2)}`, 'ARCO-ÍRIS', 'url(#arco)')];
imgs.prod_moedas = [512, 512, cartao('#ffb52e', '#ffd25a', `
  <g transform="translate(256 270)" stroke="${OUT_STROKE}" stroke-width="9" stroke-linejoin="round">
    <path d="M-40,-130 L40,-130 L20,-90 C120,-70 150,40 130,100 C110,160 -110,160 -130,100 C-150,40 -120,-70 -20,-90Z" fill="#c98b4a"/>
    <path d="M-50,-92 L50,-92" stroke-width="14"/>
  </g>
  ${texto(256, 330, 120, 'M', '#fff36b')}
  ${moeda(110, 380, 1.3)}${moeda(400, 390, 1.2)}${moeda(420, 120, 1)}${sparkle(90, 140, 2.2)}`, 'MOEDAS', '#fff36b')];
imgs.prod_presente = [512, 512, cartao('#ff5b6e', '#ff8a96', `
  <g transform="translate(256 270)" stroke="${OUT_STROKE}" stroke-width="9" stroke-linejoin="round">
    <rect x="-140" y="-60" width="280" height="200" rx="20" fill="#5ab8ff"/>
    <rect x="-160" y="-110" width="320" height="70" rx="18" fill="#7fc8ff"/>
    <rect x="-25" y="-110" width="50" height="250" fill="#fff36b"/>
    <path d="M0,-110 C-60,-200 -140,-150 -70,-110Z M0,-110 C60,-200 140,-150 70,-110Z" fill="#fff36b"/>
  </g>
  ${sparkle(90, 110, 2.5)}${sparkle(430, 120, 2.5)}`, 'AGORA!', '#fff36b')];

(async () => {
  const b64 = require('fs').readFileSync(path.join(D, 'fonts/_gP_1RrxsjcxVyin9l9n_j2RSg.ttf')).toString('base64');
  const fontCss = `@font-face{font-family:'Luckiest Guy';src:url(data:font/ttf;base64,${b64}) format('truetype')}`;
  const browser = await chromium.launch();
  const page = await browser.newPage({ deviceScaleFactor: 1 });
  const so = process.argv[2];
  for (const [nome, [w, h, f]] of Object.entries(imgs)) {
    if (so && nome !== so) continue;
    await page.setViewportSize({ width: w, height: h });
    await page.setContent(`<html><head><style>${fontCss} html,body{margin:0;padding:0;overflow:hidden}</style></head><body>${f()}</body></html>`);
    await page.evaluate(() => document.fonts.ready);
    await page.waitForTimeout(150);
    await page.screenshot({ path: path.join(OUT, nome + '.png') });
    console.log('ok', nome);
  }
  await browser.close();
})();
