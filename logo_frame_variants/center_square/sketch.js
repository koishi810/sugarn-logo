// S^n デブリ・ロゴ ウェブ版
// Processing の sample_noise_curves.pde を Canvas 2D に移植したもの。

const canvas = document.getElementById("logoCanvas");
const ctx = canvas.getContext("2d", { willReadFrequently: true });

const TWO_PI = Math.PI * 2;
const TIME_WRAP = TWO_PI * 4096;
let debris = [];

// Processing 版と同じ主要パラメータ。
let logoR = 130;
let t = 1701.6982800004732;
let defaultTime = t;
let paused = false;
let useHexCrop = false;
let sectorOverlap = 0.01;

let lastFrameTime = performance.now();
let baseTimeStep = 0.0062;
let maxFrameStep = 3.95;

let logoRotation = 0;
let logoRandomRotationAmount = 0.8;
let logoRandomRotationSpeed = 0.45;
let logoGray = 0;
let logoGrayVariation = 0;

let blackPixelScale = 1.0;
let blackPixelScaleVelocity = 0.0;
let blackPixelScaleSpring = 0.055;
let blackPixelScaleDamping = 0.72;
let blackPixelScaleMaxVelocity = 0.012;
let blackPixelScaleMin = 1;
let blackPixelScaleMax = 1;
let blackPixelThreshold = 80;
let blackPixelScaleDeadZone = 0.003;
let blackPixelTargetSmoothing = 0.08;
let blackPixelMaxShrinkTarget = 0.985;
let blackPixelCorrectedScaleSmooth = -1;
let targetBlackPixelArea = -1;
let targetBlackPixelW = -1;
let targetBlackPixelH = -1;
let blackPixelBoundsTolerance = 0.08;
let blackPixelBoundsWeight = 0.45;

let cellCornerRoundnessMin = 0;
let cellCornerRoundnessMax = 20;
let cellCornerRoundnessSpeed = 0.111;

let cellMeltAmountMin = 0;
let cellMeltAmountMax = 0;
let cellMeltAmountSpeed = 0.012;

let cellEdgeSlackMin = 0;
let cellEdgeSlackMax = 0;
let cellEdgeSlackSpeed = 0.105;

let lineFrequencyRandomness = 2;
let lineAngleRandomness = 0.605;
let lineRadiusRandomness = 0.525;
let lineRandomnessSpeed = 0.049;

let cellLocalScaleMin = 1;
let cellLocalScaleMax = 3.56;
let cellLocalScaleSpeed = 0.030;

let cellBoundaryScaleRange = 60;
let cellBoundaryScaleMax = 1;
let cellBoundaryScaleSpeed = 0.020;
let cellBoundaryScaleSoftness = 0.68;

let finalCircleMaskInset = 20;

let cropX = -450;
let cropY = -450;
let cropW = 900;
let cropH = 900;

let textRadius = 161;
let textArcAngle = Math.PI / 2;
let textYOffset = -13;
let textFontSize = 26;
let textFontWeight = 620;
let textFontWeightBreath = 0;
let textLetterSpacing = 19;
let nGap = 17.5;
let textRadiusBreath = 5.8;
let textLetterSpacingBreath = 3;
let textBreathSpeed = 0.91;
let textGray = 0;
let textIntroDelay = 0.8;
let textIntroDuration = 3.2;
let nBurstDuration = 2.4;
let nHoldDuration = 2.5;
let nBurstMinDelay = 4;
let nBurstMaxDelay = 12.5;
let nRetractStart = 0.78;
let nContentChangeSpeed = 0;
let nFormulaSettleTime = 0.7;
let nExpansionRadiusOffset = 0;
let nExpansionArc = TWO_PI;
let nFontWeight = 620;
let nFontWeightBreath = 0;
let nRingSize = 16;
let nRingLetterSpacing = 12;
let nRingCount = 25;
let nRingContentMode = 0;
const sketchStartTime = performance.now();
let nBurstStartTime = -999;
let nBurstNextTime = 0.9;
let nBurstSeed = 19.37;
let nFormulaIndex = 0;

let debrisSizeMin = 155;
let debrisSizeMax = 99;
let debrisCount = 20;
let seedValue = 136341;
let randomState = 1;
const frameVariant = "centerSquare";

let defaultCurveFormula = `(() => {
  const nt = time * 0.15;
  const n = noise(
    cos(angle) * 1.8 + cos(nt) * 1.8,
    sin(angle) * 1.8 + sin(nt) * 1.8,
    r * 0.01 + sin(nt * 0.7) * 0.5
  );
  return abs(sin(frequency * angle + time + n * TWO_PI)) * 0.65 +
    abs(sin((frequency + 3.0) * angle - time * 0.7)) * 0.25 +
    n * 0.10;
})()`;
let curveFormulaText = defaultCurveFormula;
let curveFormulaFn = null;
const savedDefaultsStorageKey = `noiseCurvesDefaults:v2:${location.pathname}`;

function seededRandomSeed(seed) {
  randomState = seed >>> 0;
}

function random(min = 1, max) {
  randomState = (randomState * 1664525 + 1013904223) >>> 0;
  const n = randomState / 4294967296;
  if (max === undefined) return n * min;
  return min + n * (max - min);
}

function constrain(v, min, max) {
  return Math.max(min, Math.min(max, v));
}

function fract(v) {
  return v - Math.floor(v);
}

function lerp(a, b, n) {
  return a + (b - a) * n;
}

function mapValue(v, a0, a1, b0, b1) {
  return b0 + ((v - a0) / (a1 - a0)) * (b1 - b0);
}

function logoFillStyle(worldX = 0, worldY = 0) {
  const centerDistance = Math.sqrt(worldX * worldX + worldY * worldY);
  const distanceFactor = constrain(centerDistance / Math.max(1, logoR), 0, 1);
  const g = Math.round(constrain(logoGray + logoGrayVariation * distanceFactor, 0, 255));
  return `rgb(${g}, ${g}, ${g})`;
}

function compileFormula(text) {
  return new Function(
    "a",
    "p",
    "k",
    "phase",
    "angle",
    "radius",
    "r",
    "frequency",
    "time",
    "patternSize",
    "bend",
    "freqNoise",
    "localK",
    "wave",
    "radiusNoise",
    "angleNoise",
    "lineFrequencyRandomness",
    "lineAngleRandomness",
    "lineRadiusRandomness",
    "TWO_PI",
    "sin",
    "cos",
    "tan",
    "abs",
    "sqrt",
    "pow",
    "min",
    "max",
    "noise",
    "map",
    `return (${text});`,
  );
}

function curveValue(values) {
  try {
    const next = curveFormulaFn(
      values.a,
      values.p,
      values.k,
      values.phase,
      values.a,
      values.p,
      values.p * values.patternSize,
      values.k,
      values.phase,
      values.patternSize,
      values.bend,
      values.freqNoise,
      values.localK,
      values.wave,
      values.radiusNoise,
      values.angleNoise,
      lineFrequencyRandomness,
      lineAngleRandomness,
      lineRadiusRandomness,
      TWO_PI,
      Math.sin,
      Math.cos,
      Math.tan,
      Math.abs,
      Math.sqrt,
      Math.pow,
      Math.min,
      Math.max,
      noise3,
      mapValue,
    );
    return Number.isFinite(next) ? constrain(next, 0, 1.5) : values.wave;
  } catch {
    return values.wave;
  }
}

function smoothstep(edge0, edge1, x) {
  const u = constrain((x - edge0) / Math.max(0.0001, edge1 - edge0), 0, 1);
  return u * u * (3 - 2 * u);
}

// 軽量な value noise。Processing の noise() と完全一致ではないが、連続した揺れを保つ。
function hash3(ix, iy, iz) {
  let h = Math.imul(ix, 374761393) ^ Math.imul(iy, 668265263) ^ Math.imul(iz, 2147483647);
  h = (h ^ (h >>> 13)) >>> 0;
  h = Math.imul(h, 1274126177) >>> 0;
  return ((h ^ (h >>> 16)) >>> 0) / 4294967295;
}

function hashNumber(n) {
  return fract(Math.sin(n * 127.1 + 311.7) * 43758.5453123);
}

function fade(n) {
  return n * n * n * (n * (n * 6 - 15) + 10);
}

function noise3(x, y, z = 0) {
  const x0 = Math.floor(x);
  const y0 = Math.floor(y);
  const z0 = Math.floor(z);
  const xf = x - x0;
  const yf = y - y0;
  const zf = z - z0;
  const u = fade(xf);
  const v = fade(yf);
  const w = fade(zf);

  const n000 = hash3(x0, y0, z0);
  const n100 = hash3(x0 + 1, y0, z0);
  const n010 = hash3(x0, y0 + 1, z0);
  const n110 = hash3(x0 + 1, y0 + 1, z0);
  const n001 = hash3(x0, y0, z0 + 1);
  const n101 = hash3(x0 + 1, y0, z0 + 1);
  const n011 = hash3(x0, y0 + 1, z0 + 1);
  const n111 = hash3(x0 + 1, y0 + 1, z0 + 1);

  const x00 = lerp(n000, n100, u);
  const x10 = lerp(n010, n110, u);
  const x01 = lerp(n001, n101, u);
  const x11 = lerp(n011, n111, u);
  return lerp(lerp(x00, x10, v), lerp(x01, x11, v), w);
}

function loopingNoise2(x, y, time) {
  const radius = 0.85;
  return noise3(x + Math.cos(time) * radius, y + Math.sin(time) * radius, 0);
}

function loopingNoise3(x, y, z, time) {
  const radius = 0.85;
  return noise3(x + Math.cos(time) * radius, y + Math.sin(time) * radius, z);
}

function animationFrameStep(now) {
  const step = (now - lastFrameTime) / (1000 / 60);
  lastFrameTime = now;
  return constrain(step, 0.25, maxFrameStep);
}

function resetDebris() {
  seededRandomSeed(seedValue);
  debris = [];
  resetBlackPixelScaleTargets();
  for (let i = 0; i < debrisCount; i++) debris.push(new Debris());
}

function resetBlackPixelScaleTargets() {
  targetBlackPixelArea = -1;
  targetBlackPixelW = -1;
  targetBlackPixelH = -1;
  blackPixelCorrectedScaleSmooth = -1;
  blackPixelScaleVelocity = 0;
}

function draw(now = performance.now()) {
  const frameStep = animationFrameStep(now);

  if (!paused) {
    t = (t + baseTimeStep * frameStep) % TIME_WRAP;
    for (const d of debris) d.update(frameStep);
  }

  ctx.setTransform(1, 0, 0, 1, 0, 0);
  ctx.globalCompositeOperation = "source-over";
  ctx.fillStyle = "#fff";
  ctx.fillRect(0, 0, canvas.width, canvas.height);

  ctx.translate(canvas.width / 2, canvas.height / 2);
  const currentLogoRotation = logoRotation + mapValue(loopingNoise2(302.4, 801.9, t * logoRandomRotationSpeed), 0, 1, -logoRandomRotationAmount, logoRandomRotationAmount);

  ctx.save();
  ctx.scale(blackPixelScale, blackPixelScale);
  ctx.rotate(currentLogoRotation);
  drawKaleidoscopeDebris();
  ctx.restore();

  ctx.rotate(currentLogoRotation);
  drawOuterMask();
  updateBlackPixelScale(frameStep);
  drawLogoFrameVariant(currentLogoRotation);

  ctx.setTransform(1, 0, 0, 1, canvas.width / 2, canvas.height / 2);
  drawLogoText();

  requestAnimationFrame(draw);
}

function drawKaleidoscopeDebris() {
  for (let i = 0; i < 6; i++) {
    ctx.save();
    ctx.rotate((i * Math.PI) / 3);
    drawClippedHalfSector();
    ctx.scale(1, -1);
    drawClippedHalfSector();
    ctx.restore();
  }
}

function drawClippedHalfSector() {
  const r = canvas.width;
  const a0 = -sectorOverlap;
  const a1 = Math.PI / 6 + sectorOverlap;
  ctx.save();
  ctx.beginPath();
  ctx.moveTo(0, 0);
  ctx.lineTo(Math.cos(a0) * r, Math.sin(a0) * r);
  ctx.lineTo(Math.cos(a1) * r, Math.sin(a1) * r);
  ctx.closePath();
  ctx.clip();

  for (const d of debris) d.draw();
  ctx.restore();
}

function drawPatternCell(a0, a1, p0, p1, k, phase, patternSize, patternSeed, debrisX, debrisY, debrisRot) {
  const pts = [
    patternPoint(a0, p0, k, phase, patternSize, patternSeed),
    patternPoint(a1, p0, k, phase, patternSize, patternSeed),
    patternPoint(a1, p1, k, phase, patternSize, patternSeed),
    patternPoint(a0, p1, k, phase, patternSize, patternSeed),
  ];
  scalePatternCell(pts, cellLocalScale(a0, a1, p0, p1, phase, patternSeed));
  scalePatternCell(pts, cellBoundaryScale(pts, debrisX, debrisY, debrisRot, patternSeed));
  const center = quadCenter(pts);
  const ca = Math.cos(debrisRot);
  const sa = Math.sin(debrisRot);
  const worldX = center.x * ca - center.y * sa + debrisX;
  const worldY = center.x * sa + center.y * ca + debrisY;
  ctx.fillStyle = logoFillStyle(worldX, worldY);
  drawRoundedPatternQuad(pts, cellRoundness(patternSeed), cellMeltAmount(patternSeed), cellEdgeSlack(patternSeed), 5, 4);
}

function cellRoundness(patternSeed) {
  const n = loopingNoise2(patternSeed * 0.017, 0, t * cellCornerRoundnessSpeed);
  return mapValue(n, 0, 1, cellCornerRoundnessMin, cellCornerRoundnessMax);
}

function cellMeltAmount(patternSeed) {
  const n = loopingNoise2(80 + patternSeed * 0.023, 0, t * cellMeltAmountSpeed);
  return mapValue(n, 0, 1, cellMeltAmountMin, cellMeltAmountMax);
}

function cellEdgeSlack(patternSeed) {
  const n = loopingNoise2(160 + patternSeed * 0.031, 0, t * cellEdgeSlackSpeed);
  return mapValue(n, 0, 1, cellEdgeSlackMin, cellEdgeSlackMax);
}

function cellLocalScale(a0, a1, p0, p1, phase, patternSeed) {
  const am = (a0 + a1) * 0.5;
  const pm = (p0 + p1) * 0.5;
  const n = loopingNoise2(520 + patternSeed * 0.019 + Math.cos(am) * 0.8, Math.sin(am) * 0.8 + pm * 1.7, phase * cellLocalScaleSpeed);
  return mapValue(n, 0, 1, cellLocalScaleMin, cellLocalScaleMax);
}

function quadCenter(pts) {
  return pts.reduce((acc, p) => ({ x: acc.x + p.x / pts.length, y: acc.y + p.y / pts.length }), { x: 0, y: 0 });
}

function scalePatternCell(pts, scaleAmount) {
  const center = quadCenter(pts);
  for (const pt of pts) {
    pt.x = center.x + (pt.x - center.x) * scaleAmount;
    pt.y = center.y + (pt.y - center.y) * scaleAmount;
  }
}

function cellBoundaryScale(pts, debrisX, debrisY, debrisRot, patternSeed) {
  const center = quadCenter(pts);
  const ca = Math.cos(debrisRot);
  const sa = Math.sin(debrisRot);
  const worldX = center.x * ca - center.y * sa + debrisX;
  const worldY = center.x * sa + center.y * ca + debrisY;
  const dist = distanceToOuterBoundary(worldX, worldY);
  const edge = constrain(1 - dist / cellBoundaryScaleRange, 0, 1);
  const edgeCurve = smoothstep(0, cellBoundaryScaleSoftness, edge);
  const n = loopingNoise2(700 + patternSeed * 0.027, 0, t * cellBoundaryScaleSpeed);
  const maxScale = cellBoundaryScaleMax * mapValue(n, 0, 1, 0.72, 1.18);
  return lerp(1, maxScale, edgeCurve);
}

function distanceToOuterBoundary(x, y) {
  if (!useHexCrop) return logoR - Math.sqrt(x * x + y * y);
  const apothem = logoR * Math.cos(Math.PI / 6);
  let maxProjection = -999999;
  for (let i = 0; i < 6; i++) {
    const a = Math.PI / 6 + (i * Math.PI) / 3;
    maxProjection = Math.max(maxProjection, x * Math.cos(a) + y * Math.sin(a));
  }
  return apothem - maxProjection;
}

function updateBlackPixelScale(frameStep) {
  const image = ctx.getImageData(0, 0, canvas.width, canvas.height);
  const data = image.data;
  let blackArea = 0;
  let minX = canvas.width;
  let minY = canvas.height;
  let maxX = -1;
  let maxY = -1;

  for (let y = 0; y < canvas.height; y++) {
    for (let x = 0; x < canvas.width; x++) {
      const i = (y * canvas.width + x) * 4;
      if (data[i] < blackPixelThreshold && data[i + 1] < blackPixelThreshold && data[i + 2] < blackPixelThreshold) {
        blackArea++;
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }

  if (blackArea <= 0 || maxX < minX || maxY < minY) return;

  const blackW = maxX - minX + 1;
  const blackH = maxY - minY + 1;
  if (targetBlackPixelArea < 0) {
    targetBlackPixelArea = blackArea;
    targetBlackPixelW = blackW;
    targetBlackPixelH = blackH;
    return;
  }

  const areaScale = Math.sqrt(targetBlackPixelArea / Math.max(1, blackArea));
  let boundsScale = 1;
  const wRatio = blackW / Math.max(1, targetBlackPixelW);
  const hRatio = blackH / Math.max(1, targetBlackPixelH);
  if (wRatio < 1 - blackPixelBoundsTolerance || hRatio < 1 - blackPixelBoundsTolerance) {
    boundsScale = Math.max(targetBlackPixelW / Math.max(1, blackW), targetBlackPixelH / Math.max(1, blackH));
  } else if (wRatio > 1 + blackPixelBoundsTolerance || hRatio > 1 + blackPixelBoundsTolerance) {
    boundsScale = Math.min(targetBlackPixelW / Math.max(1, blackW), targetBlackPixelH / Math.max(1, blackH));
  }

  let wantedScale = lerp(areaScale, boundsScale, blackPixelBoundsWeight);
  wantedScale = Math.max(wantedScale, blackPixelMaxShrinkTarget);
  let correctedScaleRaw = constrain(blackPixelScale * wantedScale, blackPixelScaleMin, blackPixelScaleMax);
  if (blackPixelCorrectedScaleSmooth < 0) blackPixelCorrectedScaleSmooth = correctedScaleRaw;
  const smoothAmount = 1 - Math.pow(1 - blackPixelTargetSmoothing, frameStep);
  blackPixelCorrectedScaleSmooth = lerp(blackPixelCorrectedScaleSmooth, correctedScaleRaw, smoothAmount);

  let error = blackPixelCorrectedScaleSmooth - blackPixelScale;
  if (Math.abs(error) < blackPixelScaleDeadZone) error = 0;
  blackPixelScaleVelocity += error * blackPixelScaleSpring * frameStep;
  blackPixelScaleVelocity *= Math.pow(blackPixelScaleDamping, frameStep);
  blackPixelScaleVelocity = constrain(blackPixelScaleVelocity, -blackPixelScaleMaxVelocity, blackPixelScaleMaxVelocity);
  blackPixelScale = constrain(blackPixelScale + blackPixelScaleVelocity * frameStep, blackPixelScaleMin, blackPixelScaleMax);
}

function drawRoundedPatternQuad(pts, roundness, meltAmount, edgeSlack, cornerSteps, edgeSteps) {
  const r = constrain(roundness, 0, 0.48);
  const melt = constrain(meltAmount, 0, 0.45);
  const slack = constrain(edgeSlack, 0, 0.35);
  const center = quadCenter(pts);

  const vertices = [];
  for (let i = 0; i < pts.length; i++) {
    const prev = pts[(i + pts.length - 1) % pts.length];
    const curr = pts[i];
    const next = pts[(i + 1) % pts.length];
    const start = { x: lerp(curr.x, prev.x, r), y: lerp(curr.y, prev.y, r) };
    const end = { x: lerp(curr.x, next.x, r), y: lerp(curr.y, next.y, r) };
    vertices.push(meltVertex(start.x, start.y, center, melt, 0.25));

    for (let s = 1; s <= cornerSteps; s++) {
      const u = s / (cornerSteps + 1);
      const q0 = (1 - u) * (1 - u);
      const q1 = 2 * (1 - u) * u;
      const q2 = u * u;
      vertices.push(meltVertex(start.x * q0 + curr.x * q1 + end.x * q2, start.y * q0 + curr.y * q1 + end.y * q2, center, melt, 0.45));
    }

    vertices.push(meltVertex(end.x, end.y, center, melt, 0.25));
    const nextEdgeEnd = { x: lerp(next.x, curr.x, r), y: lerp(next.y, curr.y, r) };
    for (let e = 1; e <= edgeSteps; e++) {
      const u = e / (edgeSteps + 1);
      const wave = Math.sin(u * Math.PI);
      const slackAmount = slack * wave;
      let x = lerp(end.x, nextEdgeEnd.x, u);
      let y = lerp(end.y, nextEdgeEnd.y, u);
      x += (center.x - x) * slackAmount;
      y += (center.y - y) * slackAmount;
      vertices.push(meltVertex(x, y, center, melt, wave));
    }
  }

  ctx.beginPath();
  ctx.moveTo(vertices[0].x, vertices[0].y);
  for (let i = 1; i < vertices.length; i++) ctx.lineTo(vertices[i].x, vertices[i].y);
  ctx.closePath();
  ctx.fill();
}

function meltVertex(x, y, center, melt, wave) {
  const dx = x - center.x;
  const dy = y - center.y;
  const d = Math.sqrt(dx * dx + dy * dy);
  if (d > 0.001) {
    const amount = melt * wave;
    x += dx * amount;
    y += dy * amount;
  }
  return { x, y };
}

function patternRadius(a, p, k, phase, patternSize, bend) {
  const freqNoise = lineFrequencyNoise(a, p, k, phase);
  const localK = k + mapValue(freqNoise, 0, 1, -lineFrequencyRandomness, lineFrequencyRandomness);
  const wave = Math.abs(Math.cos(localK * a + phase));
  const radiusNoise = lineRadiusNoise(a, p, phase);
  const angleNoise = lineAngleNoise(a, p, phase);
  const curve = curveValue({ a, p, k, phase, patternSize, bend, freqNoise, localK, wave, radiusNoise, angleNoise });
  return (0.28 + curve * 0.72) * patternSize * 0.42 * p * (0.96 + bend * 0.18 + mapValue(radiusNoise, 0, 1, -lineRadiusRandomness, lineRadiusRandomness));
}

function patternBend(a, p, patternSeed) {
  return loopingNoise3(patternSeed + Math.cos(a) * 1.2, patternSeed + Math.sin(a) * 1.2, p * 1.8, t * 0.11);
}

function patternAngle(a, p, k, phase, bend) {
  const freqNoise = lineFrequencyNoise(a, p, k, phase);
  const localK = k + mapValue(freqNoise, 0, 1, -lineFrequencyRandomness, lineFrequencyRandomness);
  const angleNoise = lineAngleNoise(a, p, phase);
  const wave = Math.abs(Math.cos(localK * a + phase));
  const radiusNoise = lineRadiusNoise(a, p, phase);
  const curve = curveValue({ a, p, k, phase, patternSize: 1, bend, freqNoise, localK, wave, radiusNoise, angleNoise });
  return a + mapValue(bend, 0, 1, -0.18, 0.18) * (0.35 + p) + Math.sin(a * (localK + 2) + phase + curve * TWO_PI) * 0.08 + mapValue(angleNoise, 0, 1, -lineAngleRandomness, lineAngleRandomness);
}

function lineFrequencyNoise(a, p, k, phase) {
  return loopingNoise2(240 + Math.cos(a) * 0.9 + k * 0.13, Math.sin(a) * 0.9 + p * 1.7, phase * lineRandomnessSpeed);
}

function lineAngleNoise(a, p, phase) {
  return loopingNoise2(320 + Math.cos(a * 1.7) * 1.1, Math.sin(a * 1.7) * 1.1 + p * 1.4, phase * lineRandomnessSpeed);
}

function lineRadiusNoise(a, p, phase) {
  return loopingNoise2(400 + Math.cos(a * 2.1) * 0.8, Math.sin(a * 2.1) * 0.8 + p * 1.9, phase * lineRandomnessSpeed);
}

function patternPoint(a, p, k, phase, patternSize, patternSeed) {
  const bend = patternBend(a, p, patternSeed);
  const aa = patternAngle(a, p, k, phase, bend);
  const rr = patternRadius(a, p, k, phase, patternSize, bend);
  return { x: Math.cos(aa) * rr, y: Math.sin(aa) * rr };
}

class Debris {
  constructor() {
    this.respawn();
  }

  respawn() {
    const anchorAngle = random(TWO_PI);
    const anchorRadius = random(0, logoR * 0.34);
    this.baseX = Math.cos(anchorAngle) * anchorRadius;
    this.baseY = Math.sin(anchorAngle) * anchorRadius;
    this.orbitX = random(logoR * 0.10, logoR * 0.28);
    this.orbitY = random(logoR * 0.08, logoR * 0.24);
    this.phaseX = random(TWO_PI);
    this.phaseY = random(TWO_PI);
    this.motionSpeed = random(0.72, 1.45);
    this.driftAmp = random(logoR * 0.035, logoR * 0.12);
    this.driftSpeed = random(0.18, 0.42);
    this.pulseAmp = random(0.16, 0.32);
    this.pulseSpeed = random(0.20, 0.48);
    this.jitterAmp = random(0.18, 0.52);
    this.jitterSpeed = random(0.28, 0.72);
    this.rotBase = random(TWO_PI);
    this.rotAmp = random(-0.45, 0.45);
    this.rotSpeed = random(0.35, 0.95);
    this.size = random(debrisSizeMin, debrisSizeMax);
    this.type = Math.floor(random(3));
    this.noiseSeed = random(1000);
    this.update();
  }

  update() {
    const driftT = t * this.driftSpeed;
    const pulse = 1 + Math.sin(t * this.pulseSpeed + this.phaseX) * this.pulseAmp;
    const jitter = Math.sin(t * this.jitterSpeed + this.noiseSeed) * this.jitterAmp;
    const motionT = t * this.motionSpeed + jitter;
    const driftX = Math.cos(driftT + this.phaseY) * this.driftAmp;
    const driftY = Math.sin(driftT * 1.31 + this.phaseX) * this.driftAmp;
    this.x = this.baseX + driftX + Math.cos(motionT + this.phaseX) * this.orbitX * pulse;
    this.y = this.baseY + driftY + Math.sin(motionT * 0.87 + this.phaseY) * this.orbitY * (2 - pulse);
    this.rot = this.rotBase + Math.sin(t * this.rotSpeed + this.phaseY) * this.rotAmp;
  }

  draw() {
    ctx.save();
    ctx.translate(this.x, this.y);
    ctx.rotate(this.rot);
    this.drawRoseGrid(3 + this.type * 2);
    ctx.restore();
  }

  drawRoseGrid(k) {
    const radialSteps = 3;
    const angleSteps = 14;
    const phase = t + this.rot;
    for (let rr = 0; rr < radialSteps; rr++) {
      const p0 = rr / radialSteps;
      const p1 = (rr + 1) / radialSteps;
      for (let aa = 0; aa < angleSteps; aa++) {
        const a0 = (TWO_PI * aa) / angleSteps;
        const a1 = (TWO_PI * (aa + 1)) / angleSteps;
        if ((rr + aa + this.type) % 3 !== 0) continue;
        drawPatternCell(a0, a1, p0, p1, k, phase, this.size, this.noiseSeed, this.x, this.y, this.rot);
      }
    }
  }
}

function drawOuterMask() {
  ctx.fillStyle = "#fff";
  if (!useHexCrop) {
    drawCircleOutsideMask();
    drawFinalCircleCleanupMask();
    return;
  }

  const m = canvas.width;
  ctx.beginPath();
  ctx.rect(-m, -m, m * 2, m * 2);
  ctx.moveTo(Math.cos((TWO_PI * 5) / 6) * logoR, Math.sin((TWO_PI * 5) / 6) * logoR);
  for (let i = 5; i >= 0; i--) {
    const a = (TWO_PI * i) / 6;
    ctx.lineTo(Math.cos(a) * logoR, Math.sin(a) * logoR);
  }
  ctx.closePath();
  ctx.fill("evenodd");
  drawFinalCircleCleanupMask();
}

function drawCircleOutsideMask() {
  ctx.save();
  ctx.strokeStyle = "#fff";
  ctx.lineWidth = canvas.width;
  ctx.beginPath();
  ctx.arc(0, 0, logoR + canvas.width / 2, 0, TWO_PI);
  ctx.stroke();
  ctx.restore();
}

function drawFinalCircleCleanupMask() {
  ctx.save();
  ctx.strokeStyle = "#fff";
  ctx.lineWidth = canvas.width;
  ctx.beginPath();
  ctx.arc(0, 0, logoR - finalCircleMaskInset + canvas.width / 2, 0, TWO_PI);
  ctx.stroke();
  ctx.restore();
}

function drawLogoFrameVariant(currentLogoRotation) {
  ctx.save();
  ctx.rotate(-currentLogoRotation);
  drawOutsideRectMask(cropX, cropY, cropW, cropH);
  ctx.restore();
}

function drawOutsideRectMask(x, y, w, h) {
  const m = canvas.width;
  ctx.save();
  ctx.fillStyle = "#fff";
  ctx.beginPath();
  ctx.rect(-m, -m, m * 2, m * 2);
  ctx.rect(x, y, w, h);
  ctx.fill("evenodd");
  ctx.restore();
}

function drawLogoText() {
  const breathPhase = t * textBreathSpeed;
  const radiusNoise = loopingNoise2(910.17, 26.4, breathPhase);
  const spacingNoise = loopingNoise2(123.8, 740.31, breathPhase * 1.37 + 1.9);
  const weightNoise = loopingNoise2(511.61, 92.7, breathPhase * 0.83 + 3.4);
  const nWeightNoise = loopingNoise2(77.2, 643.5, breathPhase * 0.91 + 5.2);
  const breathingRadius = textRadius + mapValue(radiusNoise, 0, 1, -textRadiusBreath, textRadiusBreath);
  const breathingLetterSpacing = textLetterSpacing + mapValue(spacingNoise, 0, 1, -textLetterSpacingBreath, textLetterSpacingBreath);
  const breathingFontWeight = constrain(textFontWeight + mapValue(weightNoise, 0, 1, -textFontWeightBreath, textFontWeightBreath), 100, 900);
  const breathingNFontWeight = constrain(nFontWeight + mapValue(nWeightNoise, 0, 1, -nFontWeightBreath, nFontWeightBreath), 100, 900);
  const elapsed = (performance.now() - sketchStartTime) / 1000;
  const intro = smoothstep(textIntroDelay, textIntroDelay + Math.max(0.1, textIntroDuration), elapsed);
  drawSugarTextIntro(intro, breathingRadius, breathingLetterSpacing, breathingFontWeight, breathingNFontWeight);
}

function drawSugarTextIntro(intro, radius, letterSpacing, fontWeight, nWeight) {
  ctx.save();
  setupLogoTextStyle(textFontSize, textFontWeight, textGray);
  const sWidth = ctx.measureText("s").width;
  const nWidth = measureLogoTextWidth("n", nRingSize, nFontWeight);
  setupLogoTextStyle(textFontSize, textFontWeight, textGray);
  const startAngle = Math.PI / 2;
  const startBaselineY = radius + textYOffset;
  const startS = { x: 0, y: startBaselineY, angle: startAngle };
  const startN = { x: sWidth / 2 + nWidth / 2, y: startBaselineY, angle: startAngle };
  const insertStart = { x: 0, y: startBaselineY, angle: startAngle };
  const sugarLayout = arcTextLayout("sugar", textArcAngle, radius, textYOffset, letterSpacing);
  const finalN = arcTextEndpoint("sugar", textArcAngle, radius, textYOffset, letterSpacing, nGap, nWidth);
  const nExpansionEnd = arcTextStartpoint("sugar", textArcAngle, radius, textYOffset, letterSpacing, nGap, nWidth);
  const spread = smoothstep(0.04, 0.88, intro);
  const nAnchor = {
    x: lerp(startN.x, finalN.x, spread),
    y: lerp(startN.y, finalN.y, spread),
    angle: lerpAngle(startN.angle, finalN.angle, spread),
  };

  setupLogoTextStyle(textFontSize, fontWeight, textGray);
  for (let i = 0; i < sugarLayout.length; i++) {
    const letterMove = i === 0 ? spread : smoothstep(0.14 + i * 0.075, 0.56 + i * 0.06, intro);
    const letterAlpha = i === 0 ? 1 : letterMove;
    const from = i === 0 ? startS : insertStart;
    const p = sugarLayout[i];
    drawArcLetter(sugarLayout[i].char, {
      x: lerp(from.x, p.x, letterMove),
      y: lerp(from.y, p.y, letterMove),
      angle: lerpAngle(from.angle, p.angle, letterMove),
    }, letterAlpha, i === 0 ? 1 : lerp(0.72, 1, letterMove));
  }
  ctx.restore();

  const superscript = superscriptPoint(nAnchor);
  const nExpansionActive = intro >= 1 && drawNExpansion(superscript, nExpansionEnd, radius, nWeight);

  if (!nExpansionActive) {
    ctx.save();
    setupLogoTextStyle(nRingSize, nWeight, textGray);
    drawArcLetter("n", superscript, 1);
    ctx.restore();
  }
}

function drawArcText(text, centerAngle, radius, yOffset, letterSpacing) {
  const layout = arcTextLayout(text, centerAngle, radius, yOffset, letterSpacing);
  ctx.save();
  setupLogoTextStyle(textFontSize, textFontWeight, textGray);
  for (const item of layout) drawArcLetter(item.char, item, 1);
  ctx.restore();
}

function setupLogoTextStyle(fontSize, fontWeight, gray) {
  ctx.fillStyle = `rgb(${gray}, ${gray}, ${gray})`;
  ctx.font = `${Math.round(fontWeight)} ${fontSize}px "Source Han Sans VF", "Source Han Sans SC", "Source Han Sans CN", "Source Han Sans JP", "Noto Sans CJK SC", "Noto Sans CJK JP", "思源黑体", "Hiragino Sans", sans-serif`;
  ctx.textAlign = "center";
  ctx.textBaseline = "middle";
}

function measureLogoTextWidth(text, fontSize, fontWeight) {
  ctx.save();
  setupLogoTextStyle(fontSize, fontWeight, textGray);
  const width = ctx.measureText(text).width;
  ctx.restore();
  return width;
}

function arcPoint(angle, radius, yOffset) {
  const r = Math.max(1, radius);
  return {
    x: Math.cos(angle) * r,
    y: Math.sin(angle) * r + yOffset,
    angle,
  };
}

function arcTextLayout(text, centerAngle, radius, yOffset, letterSpacing) {
  const r = Math.max(1, radius);
  const chars = Array.from(text);
  const widths = chars.map((char) => ctx.measureText(char).width);
  const spacing = letterSpacing || 0;
  const totalWidth = widths.reduce((sum, width) => sum + width, 0) + spacing * Math.max(0, chars.length - 1);
  let cursor = -totalWidth / 2;
  const layout = [];

  for (let i = 0; i < chars.length; i++) {
    const advance = widths[i] + (i < chars.length - 1 ? spacing : 0);
    const angle = centerAngle - (cursor + widths[i] / 2) / r;
    const x = Math.cos(angle) * r;
    const y = Math.sin(angle) * r + yOffset;
    layout.push({ char: chars[i], x, y, angle });
    cursor += advance;
  }

  return layout;
}

function arcTextEndpoint(text, centerAngle, radius, yOffset, letterSpacing, gap, nextWidth = 0) {
  const r = Math.max(1, radius);
  const chars = Array.from(text);
  const widths = chars.map((char) => ctx.measureText(char).width);
  const spacing = letterSpacing || 0;
  const totalWidth = widths.reduce((sum, width) => sum + width, 0) + spacing * Math.max(0, chars.length - 1);
  const angle = centerAngle - (totalWidth / 2 + gap + nextWidth / 2) / r;
  return {
    x: Math.cos(angle) * r,
    y: Math.sin(angle) * r + yOffset,
    angle,
  };
}

function arcTextStartpoint(text, centerAngle, radius, yOffset, letterSpacing, gap, prevWidth = 0) {
  const r = Math.max(1, radius);
  const chars = Array.from(text);
  const widths = chars.map((char) => ctx.measureText(char).width);
  const spacing = letterSpacing || 0;
  const totalWidth = widths.reduce((sum, width) => sum + width, 0) + spacing * Math.max(0, chars.length - 1);
  const angle = centerAngle + (totalWidth / 2 + gap + prevWidth / 2) / r;
  return {
    x: Math.cos(angle) * r,
    y: Math.sin(angle) * r + yOffset,
    angle,
  };
}

function drawArcLetter(char, item, alpha, scale = 1) {
  if (alpha <= 0.001) return;
  ctx.save();
  ctx.globalAlpha *= constrain(alpha, 0, 1);
  ctx.translate(item.x, item.y);
  ctx.rotate(item.angle - Math.PI / 2);
  ctx.scale(scale, scale);
  ctx.fillText(char, 0, 0);
  ctx.restore();
}

function superscriptPoint(anchor) {
  const superscriptOffset = textFontSize * 0.34;
  return {
    x: anchor.x - Math.cos(anchor.angle) * superscriptOffset,
    y: anchor.y - Math.sin(anchor.angle) * superscriptOffset,
    angle: anchor.angle,
  };
}

function drawNExpansion(start, end, baseRingRadius, nWeight) {
  updateNBurstTiming();
  const elapsed = (performance.now() - sketchStartTime) / 1000;
  const phaseElapsed = elapsed - nBurstStartTime;
  const totalDuration = nExpansionTotalDuration();
  if (phaseElapsed <= 0 || phaseElapsed >= totalDuration) return false;
  const animationDuration = Math.max(0.1, nBurstDuration);
  const settleTime = Math.max(0, nFormulaSettleTime);
  const holdTime = Math.max(0, nHoldDuration);
  const retractDuration = Math.max(0.001, animationDuration * (1 - nRetractStart));
  const retractElapsed = phaseElapsed - settleTime - holdTime;
  const progress = phaseElapsed <= settleTime
    ? (phaseElapsed / Math.max(0.001, settleTime)) * nRetractStart
    : retractElapsed <= 0
      ? nRetractStart
      : nRetractStart + (retractElapsed / retractDuration) * (1 - nRetractStart);
  if (progress <= 0 || progress >= 1) return false;
  drawNExpansionAtProgress(start, end, baseRingRadius, progress, phaseElapsed, nBurstSeed, nWeight);
  return true;
}

function drawNExpansionAtProgress(start, end, baseRingRadius, progress, phaseElapsed, burstSeed, nWeight) {
  const chars = nFlickerContent();
  const formulaChars = nFormulaContent();
  const count = Math.max(1, Math.min(Math.round(nRingCount), formulaChars.length));
  const ringRadius = Math.max(1, Math.hypot(start.x, start.y) + nExpansionRadiusOffset);
  const startAngle = Math.atan2(start.y, start.x);
  const endAngle = Math.atan2(end.y, end.x);
  const availableArc = clockwiseArcDistance(startAngle, endAngle);
  const naturalArc = Math.max(0, nRingSize + nRingLetterSpacing) / Math.max(1, ringRadius);
  const fittedArc = Math.min(nExpansionArc, availableArc) / Math.max(1, count - 1);
  const arcStep = Math.min(naturalArc, fittedArc);

  ctx.save();
  setupLogoTextStyle(nRingSize, nWeight, textGray);
  for (let i = 0; i < count; i++) {
    const appearWindow = Math.max(0.08, nRetractStart);
    const appearProgress = constrain(progress / appearWindow, 0, 1);
    const appear = smoothstep(0, 1, appearProgress * (count + 1) - i);
    const retractProgress = constrain((progress - nRetractStart) / Math.max(0.001, 1 - nRetractStart), 0, 1);
    const retract = 1 - smoothstep(0, 1, retractProgress * (count + 1) - (count - 1 - i));
    const alpha = appear * retract;
    if (alpha <= 0.001) continue;
    const a = startAngle - arcStep * i;
    const settleStart = nFormulaSettleTime * 0.35;
    const settleSpan = Math.max(0.001, nFormulaSettleTime * 0.65);
    const charSettleTime = settleStart + settleSpan * (i / Math.max(1, count - 1));
    const charSettled = phaseElapsed >= charSettleTime;
    const char = charSettled
      ? formulaChars[i]
      : chars[nFlickerIndex(i, phaseElapsed, burstSeed, chars.length)];
    const target = {
      x: Math.cos(a) * ringRadius,
      y: Math.sin(a) * ringRadius,
      angle: a,
    };
    drawArcLetter(char, target, alpha);
  }
  ctx.restore();
}

function updateNBurstTiming() {
  const elapsed = (performance.now() - sketchStartTime) / 1000;
  const totalDuration = nExpansionTotalDuration();
  if (elapsed < nBurstNextTime || elapsed - nBurstStartTime < totalDuration) return;
  nBurstStartTime = elapsed;
  nBurstSeed = Math.random() * 10000;
  nFormulaIndex = Math.floor(Math.random() * nFormulaList().length);
  const minDelay = Math.min(nBurstMinDelay, nBurstMaxDelay);
  const maxDelay = Math.max(nBurstMinDelay, nBurstMaxDelay);
  nBurstNextTime = elapsed + totalDuration + minDelay + Math.random() * (maxDelay - minDelay);
}

function nExpansionTotalDuration() {
  const retractDuration = Math.max(0.1, nBurstDuration) * (1 - nRetractStart);
  return Math.max(0, nFormulaSettleTime) + Math.max(0, nHoldDuration) + Math.max(0.001, retractDuration);
}

function nRingContent() {
  const mode = Math.round(nRingContentMode);
  if (mode === 1) return Array.from("n+1=n²");
  if (mode === 2) return Array.from("∴∵∞∑∫≈≠◆◇");
  return Array.from("1234567890");
}

function nFlickerContent() {
  return Array.from("0123456789+-=×÷√∑∫∞πⁿᵐᵏˣ₀₁₂₃₄₅₆₇₈₉()");
}

function nFlickerIndex(i, phaseElapsed, seed, length) {
  const speed = nContentChangeSpeed * (0.45 + hashNumber(seed + i * 17.37) * 1.3);
  const phase = hashNumber(seed * 0.13 + i * 91.9) * 1000;
  return Math.floor(phaseElapsed * speed + phase) % Math.max(1, length);
}

function nFormulaList() {
  return [
    "(a+b)²=a²+2ab+b²",
    "eⁱˣ=cosx+i·sinx",
    "sinx=x-x³/3!+x⁵/5!",
    "cosx=1-x²/2!+x⁴/4!",
    "ln(1+x)=x-x²/2+…",
    "1/(1-x)=1+x+x²+…",
    "∫xⁿdx=xⁿ⁺¹/(n+1)",
    "∑₁ⁿk=n(n+1)/2",
    "P(A∩B)=P(A)P(B|A)",
    "x=(-b±√(b²-4ac))/2a",
  ];
}

function nFormulaContent() {
  const formulas = nFormulaList();
  const index = ((nFormulaIndex % formulas.length) + formulas.length) % formulas.length;
  return Array.from(formulas[index]);
}

function lerpAngle(a, b, n) {
  let delta = ((b - a + Math.PI) % TWO_PI) - Math.PI;
  if (delta < -Math.PI) delta += TWO_PI;
  return a + delta * n;
}

function clockwiseArcDistance(fromAngle, toAngle) {
  return (fromAngle - toAngle + TWO_PI) % TWO_PI;
}

function savePng() {
  const a = document.createElement("a");
  a.download = `noise_curves_logo_${String(Math.floor(performance.now())).padStart(4, "0")}.png`;
  a.href = canvas.toDataURL("image/png");
  a.click();
}

function parameterKey(label) {
  return label
    .replace(/\s+/g, "_")
    .replace(/[^\p{Letter}\p{Number}_]+/gu, "")
    .toLowerCase();
}

function downloadTextFile(filename, text, type = "application/json") {
  const blob = new Blob([text], { type });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.download = filename;
  a.href = url;
  a.click();
  URL.revokeObjectURL(url);
}

function exportSettings() {
  saveCurrentAsDefault();
}

function currentSettingsText() {
  const data = {
    name: "S^n ノイズ曲線 設定",
    exportedAt: new Date().toISOString(),
    curveFormula: curveFormulaText,
    cropMode: useHexCrop ? "六角形" : "円形",
    cropVariant: frameVariant,
    cropRect: { x: cropX, y: cropY, width: cropW, height: cropH },
    paused,
    time: t,
    parameters: Object.fromEntries(editableParameters().map((param) => [parameterKey(param.label), param.get()])),
  };
  return JSON.stringify(data, null, 2);
}

function applySettingsData(data) {
  if (!data || typeof data !== "object") return;
  if (typeof data.curveFormula === "string") {
    curveFormulaText = data.curveFormula;
    defaultCurveFormula = data.curveFormula;
  }
  if (Number.isFinite(data.time)) {
    t = data.time;
    defaultTime = data.time;
  }
  if (typeof data.cropMode === "string") useHexCrop = data.cropMode === "六角形";
  if (typeof data.paused === "boolean") paused = data.paused;

  const values = data.parameters && typeof data.parameters === "object" ? data.parameters : {};
  for (const param of editableParameters()) {
    const key = parameterKey(param.label);
    if (!(key in values)) continue;
    const next = Number(values[key]);
    if (Number.isFinite(next)) param.set(next);
  }
}

function loadSavedDefaults() {
  try {
    const saved = localStorage.getItem(savedDefaultsStorageKey);
    if (saved) applySettingsData(JSON.parse(saved));
  } catch {
    // Local storage can be unavailable in private or restricted browser contexts.
  }
}

function saveCurrentAsDefault() {
  const text = currentSettingsText();
  try {
    localStorage.setItem(savedDefaultsStorageKey, text);
  } catch {
    downloadTextFile(`noise_curves_settings_${String(Math.floor(Date.now() / 1000))}.json`, text);
  }

  defaultCurveFormula = curveFormulaText;
  defaultTime = t;
  for (const param of editableParameters()) param.defaultValue = param.get();

  const button = document.getElementById("exportButton");
  button.textContent = "保存済み";
  window.setTimeout(() => {
    button.textContent = "保存";
  }, 900);
}

async function copySettingsData() {
  const text = currentSettingsText();
  try {
    await navigator.clipboard.writeText(text);
  } catch {
    const textarea = document.createElement("textarea");
    textarea.value = text;
    textarea.style.position = "fixed";
    textarea.style.left = "-9999px";
    document.body.append(textarea);
    textarea.select();
    document.execCommand("copy");
    textarea.remove();
  }
}

function resetSettingsToDefault() {
  curveFormulaText = defaultCurveFormula;
  const curveInput = document.getElementById("curveFormula");
  curveInput.value = curveFormulaText;
  curveFormulaFn = compileFormula(curveFormulaText);
  document.getElementById("formulaStatus").textContent = "式は有効です";
  document.getElementById("formulaStatus").style.color = "#666";

  for (const param of editableParameters()) {
    param.set(param.defaultValue);
    if (param.sync) param.sync(param.defaultValue, false);
  }
  useHexCrop = false;
  paused = false;
  t = defaultTime;
  resetDebris();
  updateButtons();
}

const parameters = [
  { label: "扇形の重なり", min: 0, max: 0.08, step: 0.001, get: () => sectorOverlap, set: (v) => { sectorOverlap = v; } },
  { label: "ロゴ半径", min: 60, max: 260, step: 1, get: () => logoR, set: (v) => { logoR = v; } },
  { label: "ロゴ回転", min: 0, max: TWO_PI, step: 0.01, get: () => logoRotation, set: (v) => { logoRotation = v; } },
  { label: "ロゴ随机回转幅度", min: 0, max: 0.8, step: 0.005, get: () => logoRandomRotationAmount, set: (v) => { logoRandomRotationAmount = v; } },
  { label: "ロゴ随机回转速度", min: 0, max: 3, step: 0.01, get: () => logoRandomRotationSpeed, set: (v) => { logoRandomRotationSpeed = v; } },
  { label: "中心灰度", min: 0, max: 255, step: 1, get: () => logoGray, set: (v) => { logoGray = v; } },
  { label: "外侧灰度增量", min: 0, max: 255, step: 1, get: () => logoGrayVariation, set: (v) => { logoGrayVariation = v; } },
  { label: "アニメ速度", min: 0, max: 0.012, step: 0.0001, get: () => baseTimeStep, set: (v) => { baseTimeStep = v; } },

  { label: "角丸 最大", min: 0, max: 20, step: 0.1, get: () => cellCornerRoundnessMax, set: (v) => { cellCornerRoundnessMax = v; } },
  { label: "周波数ゆらぎ", min: 0, max: 2, step: 0.01, get: () => lineFrequencyRandomness, set: (v) => { lineFrequencyRandomness = v; } },
  { label: "角度ゆらぎ", min: 0, max: 0.8, step: 0.005, get: () => lineAngleRandomness, set: (v) => { lineAngleRandomness = v; } },
  { label: "半径ゆらぎ", min: 0, max: 0.8, step: 0.005, get: () => lineRadiusRandomness, set: (v) => { lineRadiusRandomness = v; } },

  { label: "局所拡大 最大", min: 0.2, max: 4, step: 0.01, get: () => cellLocalScaleMax, set: (v) => { cellLocalScaleMax = v; } },
  { label: "境界拡大 最大", min: 1, max: 8, step: 0.05, get: () => cellBoundaryScaleMax, set: (v) => { cellBoundaryScaleMax = v; } },

  { label: "最終円マスク内側量", min: 0, max: 80, step: 1, get: () => finalCircleMaskInset, set: (v) => { finalCircleMaskInset = v; } },
  { label: "裁切 X", min: -450, max: 450, step: 1, get: () => cropX, set: (v) => { cropX = v; } },
  { label: "裁切 Y", min: -450, max: 450, step: 1, get: () => cropY, set: (v) => { cropY = v; } },
  { label: "裁切 幅", min: 20, max: 900, step: 1, get: () => cropW, set: (v) => { cropW = v; } },
  { label: "裁切 高", min: 20, max: 900, step: 1, get: () => cropH, set: (v) => { cropH = v; } },

  { type: "section", label: "文字" },
  { label: "文字半径", min: 120, max: 390, step: 1, get: () => textRadius, set: (v) => { textRadius = v; } },
  { label: "文字圆周位置", min: 0, max: TWO_PI, step: 0.01, get: () => textArcAngle, set: (v) => { textArcAngle = v; } },
  { label: "文字 Y", min: -160, max: 160, step: 1, get: () => textYOffset, set: (v) => { textYOffset = v; } },
  { label: "文字サイズ", min: 8, max: 96, step: 1, get: () => textFontSize, set: (v) => { textFontSize = v; } },
  { label: "文字字重", min: 100, max: 900, step: 10, get: () => textFontWeight, set: (v) => { textFontWeight = Math.round(v / 10) * 10; } },
  { label: "文字字重呼吸", min: 0, max: 220, step: 5, get: () => textFontWeightBreath, set: (v) => { textFontWeightBreath = v; } },
  { label: "文字字间距", min: -10, max: 40, step: 0.5, get: () => textLetterSpacing, set: (v) => { textLetterSpacing = v; } },
  { label: "sugar-n间距", min: -20, max: 80, step: 0.5, get: () => nGap, set: (v) => { nGap = v; } },
  { label: "文字半径呼吸", min: 0, max: 12, step: 0.1, get: () => textRadiusBreath, set: (v) => { textRadiusBreath = v; } },
  { label: "文字字距呼吸", min: 0, max: 3, step: 0.05, get: () => textLetterSpacingBreath, set: (v) => { textLetterSpacingBreath = v; } },
  { label: "文字呼吸速度", min: 0, max: 6, step: 0.01, get: () => textBreathSpeed, set: (v) => { textBreathSpeed = v; } },
  { label: "文字灰度", min: 0, max: 255, step: 1, get: () => textGray, set: (v) => { textGray = v; } },
  { label: "文字展开延迟", min: 0, max: 5, step: 0.1, get: () => textIntroDelay, set: (v) => { textIntroDelay = v; } },
  { label: "文字展开时长", min: 0.2, max: 12, step: 0.1, get: () => textIntroDuration, set: (v) => { textIntroDuration = v; } },
  { label: "n扩展时长", min: 0.2, max: 8, step: 0.1, get: () => nBurstDuration, set: (v) => { nBurstDuration = v; } },
  { label: "n停留时间", min: 0, max: 8, step: 0.1, get: () => nHoldDuration, set: (v) => { nHoldDuration = v; } },
  { label: "n回收开始", min: 0.1, max: 0.95, step: 0.01, get: () => nRetractStart, set: (v) => { nRetractStart = v; } },
  { label: "n内容变化速度", min: 0, max: 24, step: 0.1, get: () => nContentChangeSpeed, set: (v) => { nContentChangeSpeed = v; } },
  { label: "n算式固定时间", min: 0, max: 12, step: 0.1, get: () => nFormulaSettleTime, set: (v) => { nFormulaSettleTime = v; } },
  { label: "n触发最短间隔", min: 0.2, max: 20, step: 0.1, get: () => nBurstMinDelay, set: (v) => { nBurstMinDelay = v; } },
  { label: "n触发最长间隔", min: 0.2, max: 30, step: 0.1, get: () => nBurstMaxDelay, set: (v) => { nBurstMaxDelay = v; } },
  { label: "n扩展半径偏移", min: -120, max: 120, step: 1, get: () => nExpansionRadiusOffset, set: (v) => { nExpansionRadiusOffset = v; } },
  { label: "n扩展弧长", min: 0.2, max: TWO_PI, step: 0.01, get: () => nExpansionArc, set: (v) => { nExpansionArc = v; } },
  { label: "n字重", min: 100, max: 900, step: 10, get: () => nFontWeight, set: (v) => { nFontWeight = Math.round(v / 10) * 10; } },
  { label: "n字重呼吸", min: 0, max: 220, step: 5, get: () => nFontWeightBreath, set: (v) => { nFontWeightBreath = v; } },
  { label: "n字号", min: 4, max: 40, step: 1, get: () => nRingSize, set: (v) => { nRingSize = v; } },
  { label: "n扩展字间距", min: -4, max: 60, step: 0.5, get: () => nRingLetterSpacing, set: (v) => { nRingLetterSpacing = v; } },
  { label: "n扩展数量", min: 1, max: 32, step: 1, get: () => nRingCount, set: (v) => { nRingCount = Math.round(v); } },
  { label: "n扩展内容", min: 0, max: 2, step: 1, get: () => nRingContentMode, set: (v) => { nRingContentMode = Math.round(v); } },

  { label: "デブリサイズ 最小", min: 20, max: 420, step: 1, reset: true, get: () => debrisSizeMin, set: (v) => { debrisSizeMin = v; } },
  { label: "デブリサイズ 最大", min: 20, max: 520, step: 1, reset: true, get: () => debrisSizeMax, set: (v) => { debrisSizeMax = v; } },
  { label: "デブリ数", min: 1, max: 48, step: 1, reset: true, get: () => debrisCount, set: (v) => { debrisCount = Math.round(v); } },
  { label: "シード", min: 1, max: 999999, step: 1, reset: true, get: () => seedValue, set: (v) => { seedValue = Math.round(v); } },
];

function editableParameters() {
  return parameters.filter((param) => typeof param.get === "function" && typeof param.set === "function");
}

function formatParamValue(value, step) {
  if (step >= 1) return String(Math.round(value));
  if (step >= 0.01) return value.toFixed(2);
  if (step >= 0.001) return value.toFixed(3);
  return value.toFixed(4);
}

function initFormulaEditor() {
  const curveInput = document.getElementById("curveFormula");
  const status = document.getElementById("formulaStatus");

  curveInput.value = curveFormulaText;

  const compile = () => {
    try {
      curveFormulaText = curveInput.value;
      curveFormulaFn = compileFormula(curveFormulaText);
      status.textContent = "式は有効です";
      status.style.color = "#666";
    } catch (error) {
      status.textContent = error.message;
      status.style.color = "#b00020";
    }
  };

  curveInput.addEventListener("input", compile);
  compile();
}

function initParameterPanel() {
  const panel = document.getElementById("parameterPanel");
  for (const param of parameters) {
    if (param.type === "section") {
      const heading = document.createElement("h2");
      heading.className = "parameter-section";
      heading.textContent = param.label;
      panel.append(heading);
      continue;
    }

    param.defaultValue = param.get();
    const field = document.createElement("div");
    field.className = "field";

    const label = document.createElement("label");
    const name = document.createElement("span");
    const value = document.createElement("span");
    name.textContent = param.label;
    value.className = "value";
    label.append(name, value);

    const row = document.createElement("div");
    row.className = "range-row";

    const range = document.createElement("input");
    range.type = "range";
    range.min = param.min;
    range.max = param.max;
    range.step = param.step;

    const number = document.createElement("input");
    number.type = "number";
    number.min = param.min;
    number.max = param.max;
    number.step = param.step;

    const sync = (nextValue, shouldReset) => {
      const v = constrain(Number(nextValue), param.min, param.max);
      param.set(v);
      const current = param.get();
      range.value = current;
      number.value = current;
      value.textContent = formatParamValue(current, param.step);
      if (shouldReset && param.reset) resetDebris();
    };
    param.sync = sync;

    range.addEventListener("input", () => sync(range.value, false));
    range.addEventListener("change", () => sync(range.value, true));
    number.addEventListener("input", () => sync(number.value, true));
    sync(param.get(), false);

    row.append(range, number);
    field.append(label, row);
    panel.append(field);
  }
}

function updateButtons() {
  document.getElementById("pauseButton").textContent = paused ? "再生" : "一時停止";
  document.getElementById("cropButton").textContent = useHexCrop ? "六角形" : "円形";
}

document.getElementById("pauseButton").addEventListener("click", () => {
  paused = !paused;
  updateButtons();
});

document.getElementById("resetButton").addEventListener("click", () => {
  seedValue = Math.floor(Math.random() * 1000000);
  resetDebris();
});

document.getElementById("cropButton").addEventListener("click", () => {
  useHexCrop = !useHexCrop;
  updateButtons();
});

document.getElementById("saveButton").addEventListener("click", savePng);
document.getElementById("exportButton").addEventListener("click", exportSettings);
document.getElementById("initButton").addEventListener("click", resetSettingsToDefault);
document.getElementById("copyDataButton").addEventListener("click", async () => {
  await copySettingsData();
  const button = document.getElementById("copyDataButton");
  button.textContent = "コピー済み";
  window.setTimeout(() => {
    button.textContent = "データコピー";
  }, 900);
});

window.addEventListener("keydown", (event) => {
  if (event.key === " ") {
    event.preventDefault();
    paused = !paused;
    updateButtons();
  }
  if (event.key === "h" || event.key === "H") {
    useHexCrop = !useHexCrop;
    updateButtons();
  }
  if (event.key === "r" || event.key === "R") {
    seedValue = Math.floor(Math.random() * 1000000);
    resetDebris();
  }
  if (event.key === "s" || event.key === "S") savePng();
  if (event.key === "e" || event.key === "E") exportSettings();
  if (event.key === "c" || event.key === "C") copySettingsData();
});

loadSavedDefaults();
initFormulaEditor();
initParameterPanel();
resetDebris();
updateButtons();
requestAnimationFrame(draw);
