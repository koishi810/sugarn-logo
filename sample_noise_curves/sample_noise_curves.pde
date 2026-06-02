// S^nデブリ・ロゴ・プロトタイプ
// 固定カメラ + 固定30度セクター + 幾何デブリの流動レイヤー。
// ノイズ曲線バージョン: rose グリッドに連続した noise の歪みを加える。
// スペースキーで一時停止/再生、Sでスクリーンショット保存、Hで六角形/円形を切り替え、Rでデブリを再生成。

import java.awt.Shape;
import java.awt.Graphics2D;
import java.awt.geom.Path2D;
import processing.awt.PGraphicsJava2D;

// 画面内を飛んでいる幾何デブリをすべて保持する。
// 図案をより密にしたい場合は resetDebris() 内の数を増やし、軽くしたい場合は減らす。
ArrayList<Debris> debris = new ArrayList<Debris>();

// logoR は最終ロゴの外形サイズを制御する。
// 現在は 150 に調整している。この値は外形とデブリの循環範囲の両方に影響する。
float logoR = 150;

// グローバル時間。draw() が毎フレーム加算し、ノイズと波形の流れを駆動する。
float t = 0;
boolean paused = false;
boolean useHexCrop = false;

// フレーム数ではなく実時間でアニメーションを進める。
// 処理が重くなって FPS が落ちても、後半だけ動きが遅く見えるのを避ける。
int lastFrameMillis = 0;
float baseTimeStep = 0.003;
float maxFrameStep = 2.5;

// ロゴ全体の向き。PI / 6 で六角形の尖った角が上下に来る。
float logoRotation = PI / 6.0;

// 黒いピクセル量を固定するための全体スケール補正。
// 初回の黒ピクセル面積を基準にして、見た目の重量が大きく揺れないようにする。
float blackPixelScale = 1.0;
float blackPixelScaleVelocity = 0.0;
float blackPixelScaleSpring = 0.055;
float blackPixelScaleDamping = 0.72;
float blackPixelScaleMaxVelocity = 0.012;
float blackPixelScaleMin = 1;
float blackPixelScaleMax = 1;
float blackPixelThreshold = 80;
float blackPixelScaleDeadZone = 0.006;
float blackPixelTargetSmoothing = 0.08;
// 黒量が一時的に増えた時でも、目標スケールを急に小さくしすぎないための下限。
float blackPixelMaxShrinkTarget = 0.985;
float blackPixelCorrectedScaleSmooth = -1;
float targetBlackPixelArea = -1;
float targetBlackPixelW = -1;
float targetBlackPixelH = -1;
float blackPixelBoundsTolerance = 0.08;
float blackPixelBoundsWeight = 0.45;

// 白いセルの角丸量の変化範囲。時間と noise でゆっくり揺らす。
// min/max を近づけるほど安定し、離すほど角丸の変化が大きくなる。
float cellCornerRoundnessMin = 0;
float cellCornerRoundnessMax = 2;
float cellCornerRoundnessSpeed = 0.045;

// 融球感の強さ。0.0 で無効、値を上げるほど白い塊が外へ膨らんでつながりやすくなる。
float cellMeltAmountMin = 0;
float cellMeltAmountMax = 0;
float cellMeltAmountSpeed = 0.012;

// エッジのたるみ量。値を上げるほど白い塊の辺が内側へ柔らかくへこむ。
float cellEdgeSlackMin = 0;
float cellEdgeSlackMax = 0;
float cellEdgeSlackSpeed = 0.030;

// 線生成アルゴリズム自体のランダム性。周波数/角度/半径を noise でゆっくり変える。
float lineFrequencyRandomness = 0.55;
float lineAngleRandomness = 0.12;
float lineRadiusRandomness = 0.18;
float lineRandomnessSpeed = 0.010;

// 各セルごとの局所サイズ変化。min/max を離すほど同じデブリ内でも白い塊の大小差が出る。
float cellLocalScaleMin = 1;
float cellLocalScaleMax = 1.5;
float cellLocalScaleSpeed = 0.030;

// 外形境界に近いセルだけを急に大きくする。境界の形を白い塊で崩すための設定。
float cellBoundaryScaleRange = 60;
float cellBoundaryScaleMax = 4;
float cellBoundaryScaleSpeed = 0.020;
float cellBoundaryScaleSoftness = 0.68;

// 最後に少し内側の円形マスクを重ね、外周に残る小さな破片を隠す。
float finalCircleMaskInset = 20;

// 単体デブリのサイズ上下限。最小値を上げると細かい塊が減り、最大値を上げると大きい塊が増える。
float debrisSizeMin = 230;
float debrisSizeMax = 260;

// seed でランダム結果を固定する。R を押すと seed が変わり、別バージョンのロゴを生成する。
int seedValue = 2026;

void setup() {
  size(900, 900, JAVA2D);
  pixelDensity(1);

  // smooth(4) はエッジを柔らかくするが、少しグレーの縁が出る場合がある。
  // より硬い白黒エッジが必要なら noSmooth() に変更する。
  smooth(4);
  resetDebris();
  lastFrameMillis = millis();
}

void draw() {
  float frameStep = animationFrameStep();

  if (!paused) {
    // アニメーション速度。baseTimeStep を大きくすると速く、小さくすると遅くなる。
    t += baseTimeStep * frameStep;
    for (Debris d : debris) {
      d.update(frameStep);
    }
  }

  background(255);
  blendMode(BLEND);
  translate(width / 2.0, height / 2.0);

  // 黒ピクセル補正は内部の図案だけにかける。
  // 外形マスクまで一緒に縮放すると、ロゴ全体の輪郭が小さくなり補正が自己フィードバックしてしまう。
  pushMatrix();
  scale(blackPixelScale);
  rotate(logoRotation);
  drawKaleidoscopeDebris();
  popMatrix();

  // 外形は常に固定サイズで切り抜く。六角形モードでは向きだけを合わせる。
  rotate(logoRotation);
  drawOuterMask();
  updateBlackPixelScale(frameStep);
}

float animationFrameStep() {
  int now = millis();
  float step = (now - lastFrameMillis) / (1000.0 / 60.0);
  lastFrameMillis = now;

  // 一時的に固まった直後の大ジャンプを防ぐ。
  // maxFrameStep を上げると遅延を取り戻しやすく、下げると動きがより安定する。
  return constrain(step, 0.25, maxFrameStep);
}

void resetDebris() {
  randomSeed(seedValue);
  debris.clear();
  resetBlackPixelScaleTargets();

  // デブリ数。多いほど密になるが、処理負荷も上がる。
  // 重い場合はまず 24 か 30 を試す。隙間が多い場合は 42 まで上げる。
  for (int i = 0; i < 16; i++) {
    debris.add(new Debris());
  }
}

void resetBlackPixelScaleTargets() {
  // R で再生成した時に、前の図案の黒ピクセル基準を引きずらないようにする。
  targetBlackPixelArea = -1;
  targetBlackPixelW = -1;
  targetBlackPixelH = -1;
  blackPixelCorrectedScaleSmooth = -1;
  blackPixelScaleVelocity = 0;
}

void drawKaleidoscopeDebris() {
  // 6 回の回転と各回のミラー反転で、最終的に12個の半セクターからなる万華鏡を作る。
  for (int i = 0; i < 6; i++) {
    pushMatrix();
    rotate(i * PI / 3.0);
    drawClippedHalfSector();
    scale(1, -1);
    drawClippedHalfSector();
    popMatrix();
  }
}

void drawClippedHalfSector() {
  // Java2D の clip で描画範囲を制限し、30度の半セクターだけを描く。
  // 後続の rotate/scale がこのセクターを複製し、完全なロゴ形状にする。
  PGraphicsJava2D pg = (PGraphicsJava2D)g;
  Graphics2D g2 = pg.g2;
  Shape oldClip = g2.getClip();

  float r = width;
  Path2D.Float wedge = new Path2D.Float();
  wedge.moveTo(0, 0);
  wedge.lineTo(r, 0);
  wedge.lineTo(cos(PI / 6.0) * r, sin(PI / 6.0) * r);
  wedge.closePath();

  g2.clip(wedge);

  // 現在のバージョンの重要な方針:
  // 先に黒いベースを敷き、その上に白いノイズ単位だけを描くことで、黒い多角形同士の継ぎ目に白線が出るのを避ける。
  drawBlackSectorBase();
  for (Debris d : debris) {
    d.draw();
  }
  g2.setClip(oldClip);
}

void drawBlackSectorBase() {
  // 黒いベースは上の wedge clip により、現在の半セクター内だけに制限される。
  // 最終的な外形は引き続き drawOuterMask() で切り抜く。
  blendMode(BLEND);
  noStroke();
  fill(0);
  rect(0, -width, width * 1.5, width * 2);
}

void drawPatternCell(float a0, float a1, float p0, float p1, float k, float phase, float patternSize, float patternSeed, float debrisX, float debrisY, float debrisRot) {
  // 白いセル形状の入口。
  // 今後線や形を大きく変える場合は、ここ と patternVertex() を優先して変更する。
  PVector[] pts = {
    patternPoint(a0, p0, k, phase, patternSize, patternSeed),
    patternPoint(a1, p0, k, phase, patternSize, patternSeed),
    patternPoint(a1, p1, k, phase, patternSize, patternSeed),
    patternPoint(a0, p1, k, phase, patternSize, patternSeed)
  };
  scalePatternCell(pts, cellLocalScale(a0, a1, p0, p1, phase, patternSeed));
  scalePatternCell(pts, cellBoundaryScale(pts, debrisX, debrisY, debrisRot, patternSeed));
  drawRoundedPatternQuad(pts, cellRoundness(patternSeed), cellMeltAmount(patternSeed), cellEdgeSlack(patternSeed), 5, 4);
}

float cellRoundness(float patternSeed) {
  float n = loopingNoise(patternSeed * 0.017, 0.0, t * cellCornerRoundnessSpeed);
  return map(n, 0, 1, cellCornerRoundnessMin, cellCornerRoundnessMax);
}

float cellMeltAmount(float patternSeed) {
  float n = loopingNoise(80.0 + patternSeed * 0.023, 0.0, t * cellMeltAmountSpeed);
  return map(n, 0, 1, cellMeltAmountMin, cellMeltAmountMax);
}

float cellEdgeSlack(float patternSeed) {
  float n = loopingNoise(160.0 + patternSeed * 0.031, 0.0, t * cellEdgeSlackSpeed);
  return map(n, 0, 1, cellEdgeSlackMin, cellEdgeSlackMax);
}

float cellLocalScale(float a0, float a1, float p0, float p1, float phase, float patternSeed) {
  float am = (a0 + a1) * 0.5;
  float pm = (p0 + p1) * 0.5;
  float n = loopingNoise(520.0 + patternSeed * 0.019 + cos(am) * 0.8, sin(am) * 0.8 + pm * 1.7, phase * cellLocalScaleSpeed);
  return map(n, 0, 1, cellLocalScaleMin, cellLocalScaleMax);
}

void scalePatternCell(PVector[] pts, float scaleAmount) {
  PVector center = quadCenter(pts);
  for (int i = 0; i < pts.length; i++) {
    PVector rel = PVector.sub(pts[i], center);
    rel.mult(scaleAmount);
    pts[i].set(center.x + rel.x, center.y + rel.y);
  }
}

float cellBoundaryScale(PVector[] pts, float debrisX, float debrisY, float debrisRot, float patternSeed) {
  PVector localCenter = quadCenter(pts);
  float ca = cos(debrisRot);
  float sa = sin(debrisRot);
  float worldX = localCenter.x * ca - localCenter.y * sa + debrisX;
  float worldY = localCenter.x * sa + localCenter.y * ca + debrisY;
  float dist = distanceToOuterBoundary(worldX, worldY);
  float edge = constrain(1.0 - dist / cellBoundaryScaleRange, 0.0, 1.0);

  // 境界付近だけをなめらかに立ち上げる。急な変化は外形の動きとして見えやすい。
  float edgeCurve = smoothstep(0.0, cellBoundaryScaleSoftness, edge);
  float n = loopingNoise(700.0 + patternSeed * 0.027, 0.0, t * cellBoundaryScaleSpeed);
  float maxScale = cellBoundaryScaleMax * map(n, 0, 1, 0.72, 1.18);
  return lerp(1.0, maxScale, edgeCurve);
}

float loopingNoise(float x, float y, float time) {
  float radius = 0.85;
  return noise(x + cos(time) * radius, y + sin(time) * radius);
}

float loopingNoise(float x, float y, float z, float time) {
  float radius = 0.85;
  return noise(x + cos(time) * radius, y + sin(time) * radius, z);
}

float smoothstep(float edge0, float edge1, float x) {
  float u = constrain((x - edge0) / max(0.0001, edge1 - edge0), 0.0, 1.0);
  return u * u * (3.0 - 2.0 * u);
}

float distanceToOuterBoundary(float x, float y) {
  if (!useHexCrop) {
    return logoR - sqrt(x * x + y * y);
  }

  float apothem = logoR * cos(PI / 6.0);
  float maxProjection = -999999;
  for (int i = 0; i < 6; i++) {
    float a = PI / 6.0 + i * PI / 3.0;
    float projection = x * cos(a) + y * sin(a);
    maxProjection = max(maxProjection, projection);
  }
  return apothem - maxProjection;
}

void updateBlackPixelScale(float frameStep) {
  loadPixels();

  int blackArea = 0;
  int minX = width;
  int minY = height;
  int maxX = -1;
  int maxY = -1;

  for (int y = 0; y < height; y++) {
    int row = y * width;
    for (int x = 0; x < width; x++) {
      color c = pixels[row + x];
      if (red(c) < blackPixelThreshold && green(c) < blackPixelThreshold && blue(c) < blackPixelThreshold) {
        blackArea++;
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }

  if (blackArea <= 0 || maxX < minX || maxY < minY) return;

  float blackW = maxX - minX + 1;
  float blackH = maxY - minY + 1;

  if (targetBlackPixelArea < 0) {
    targetBlackPixelArea = blackArea;
    targetBlackPixelW = blackW;
    targetBlackPixelH = blackH;
    return;
  }

  // 面積はスケールの二乗で変わるので、sqrt() で必要な倍率へ戻す。
  float areaScale = sqrt(targetBlackPixelArea / max(1.0, float(blackArea)));

  // 面積だけでは外接幅/高さがずれる場合があるため、許容範囲を超えた時だけ外接サイズでも補正する。
  float boundsScale = 1.0;
  float wRatio = blackW / max(1.0, targetBlackPixelW);
  float hRatio = blackH / max(1.0, targetBlackPixelH);
  if (wRatio < 1.0 - blackPixelBoundsTolerance || hRatio < 1.0 - blackPixelBoundsTolerance) {
    boundsScale = max(targetBlackPixelW / max(1.0, blackW), targetBlackPixelH / max(1.0, blackH));
  } else if (wRatio > 1.0 + blackPixelBoundsTolerance || hRatio > 1.0 + blackPixelBoundsTolerance) {
    boundsScale = min(targetBlackPixelW / max(1.0, blackW), targetBlackPixelH / max(1.0, blackH));
  }

  float wantedScale = lerp(areaScale, boundsScale, blackPixelBoundsWeight);
  // 小さくなる方向だけを制限し、ロゴ全体が急に縮む事故を防ぐ。
  wantedScale = max(wantedScale, blackPixelMaxShrinkTarget);
  float correctedScaleRaw = blackPixelScale * wantedScale;
  correctedScaleRaw = constrain(correctedScaleRaw, blackPixelScaleMin, blackPixelScaleMax);

  // ピクセル計測は白黒の境界で毎フレーム少し揺れるため、そのまま追うと全体スケールが震える。
  // 目標値を先にならしてからスプリングへ渡し、細かすぎる誤差は無視する。
  if (blackPixelCorrectedScaleSmooth < 0) blackPixelCorrectedScaleSmooth = correctedScaleRaw;
  float smoothAmount = 1.0 - pow(1.0 - blackPixelTargetSmoothing, frameStep);
  blackPixelCorrectedScaleSmooth = lerp(blackPixelCorrectedScaleSmooth, correctedScaleRaw, smoothAmount);
  float correctedScale = blackPixelCorrectedScaleSmooth;

  // スプリング + ダンピングで追従する。固定ステップより角が立たず、lerp() より後半が鈍くなりにくい。
  float error = correctedScale - blackPixelScale;
  if (abs(error) < blackPixelScaleDeadZone) {
    error = 0;
  }
  blackPixelScaleVelocity += error * blackPixelScaleSpring * frameStep;
  blackPixelScaleVelocity *= pow(blackPixelScaleDamping, frameStep);
  blackPixelScaleVelocity = constrain(blackPixelScaleVelocity, -blackPixelScaleMaxVelocity, blackPixelScaleMaxVelocity);
  blackPixelScale = constrain(blackPixelScale + blackPixelScaleVelocity * frameStep, blackPixelScaleMin, blackPixelScaleMax);
}

void drawRoundedPatternQuad(PVector[] pts, float roundness, float meltAmount, float edgeSlack, int cornerSteps, int edgeSteps) {
  float r = constrain(roundness, 0.0, 0.48);
  float melt = constrain(meltAmount, 0.0, 0.45);
  float slack = constrain(edgeSlack, 0.0, 0.35);
  PVector center = quadCenter(pts);

  beginShape();
  for (int i = 0; i < pts.length; i++) {
    PVector prev = pts[(i + pts.length - 1) % pts.length];
    PVector curr = pts[i];
    PVector next = pts[(i + 1) % pts.length];

    float startX = lerp(curr.x, prev.x, r);
    float startY = lerp(curr.y, prev.y, r);
    float endX = lerp(curr.x, next.x, r);
    float endY = lerp(curr.y, next.y, r);
    addMeltVertex(startX, startY, center, melt, 0.25);

    for (int s = 1; s <= cornerSteps; s++) {
      float u = s / float(cornerSteps + 1);
      float q0 = (1.0 - u) * (1.0 - u);
      float q1 = 2.0 * (1.0 - u) * u;
      float q2 = u * u;
      float x = startX * q0 + curr.x * q1 + endX * q2;
      float y = startY * q0 + curr.y * q1 + endY * q2;
      addMeltVertex(x, y, center, melt, 0.45);
    }

    addMeltVertex(endX, endY, center, melt, 0.25);

    float nextEdgeEndX = lerp(next.x, curr.x, r);
    float nextEdgeEndY = lerp(next.y, curr.y, r);
    for (int e = 1; e <= edgeSteps; e++) {
      float u = e / float(edgeSteps + 1);
      float edgeX = lerp(endX, nextEdgeEndX, u);
      float edgeY = lerp(endY, nextEdgeEndY, u);
      float wave = sin(u * PI);
      float slackAmount = slack * wave;
      edgeX += (center.x - edgeX) * slackAmount;
      edgeY += (center.y - edgeY) * slackAmount;
      addMeltVertex(edgeX, edgeY, center, melt, wave);
    }
  }
  endShape(CLOSE);
}

PVector quadCenter(PVector[] pts) {
  PVector center = new PVector();
  for (PVector pt : pts) {
    center.add(pt);
  }
  center.div(pts.length);
  return center;
}

void addMeltVertex(float x, float y, PVector center, float melt, float wave) {
  float dx = x - center.x;
  float dy = y - center.y;
  float d = sqrt(dx * dx + dy * dy);
  if (d > 0.001) {
    float amount = melt * wave;
    x += dx * amount;
    y += dy * amount;
  }
  vertex(x, y);
}

float patternRadius(float a, float p, float k, float phase, float patternSize, float bend) {
  float freqNoise = lineFrequencyNoise(a, p, k, phase);
  float localK = k + map(freqNoise, 0, 1, -lineFrequencyRandomness, lineFrequencyRandomness);
  float wave = abs(cos(localK * a + phase));
  float radiusNoise = lineRadiusNoise(a, p, phase);
  float r = (0.28 + wave * 0.72) * patternSize * 0.42 * p;
  return r * (0.96 + bend * 0.18 + map(radiusNoise, 0, 1, -lineRadiusRandomness, lineRadiusRandomness));
}

float patternBend(float a, float p, float patternSeed) {
  return loopingNoise(patternSeed + cos(a) * 1.2, patternSeed + sin(a) * 1.2, p * 1.8, t * 0.11);
}

float patternAngle(float a, float p, float k, float phase, float bend) {
  float freqNoise = lineFrequencyNoise(a, p, k, phase);
  float localK = k + map(freqNoise, 0, 1, -lineFrequencyRandomness, lineFrequencyRandomness);
  float angleNoise = lineAngleNoise(a, p, phase);
  float jitter = map(bend, 0, 1, -0.18, 0.18);
  float ripple = sin(a * (localK + 2.0) + phase + bend * TWO_PI) * 0.08;
  float randomTurn = map(angleNoise, 0, 1, -lineAngleRandomness, lineAngleRandomness);
  return a + jitter * (0.35 + p) + ripple + randomTurn;
}

float lineFrequencyNoise(float a, float p, float k, float phase) {
  return loopingNoise(240.0 + cos(a) * 0.9 + k * 0.13, sin(a) * 0.9 + p * 1.7, phase * lineRandomnessSpeed);
}

float lineAngleNoise(float a, float p, float phase) {
  return loopingNoise(320.0 + cos(a * 1.7) * 1.1, sin(a * 1.7) * 1.1 + p * 1.4, phase * lineRandomnessSpeed);
}

float lineRadiusNoise(float a, float p, float phase) {
  return loopingNoise(400.0 + cos(a * 2.1) * 0.8, sin(a * 2.1) * 0.8 + p * 1.9, phase * lineRandomnessSpeed);
}

void patternVertex(float a, float p, float k, float phase, float patternSize, float patternSeed) {
  PVector pt = patternPoint(a, p, k, phase, patternSize, patternSeed);
  vertex(pt.x, pt.y);
}

PVector patternPoint(float a, float p, float k, float phase, float patternSize, float patternSeed) {
  float bend = patternBend(a, p, patternSeed);
  float aa = patternAngle(a, p, k, phase, bend);
  float rr = patternRadius(a, p, k, phase, patternSize, bend);
  return new PVector(cos(aa) * rr, sin(aa) * rr);
}

class Debris {
  // x/y はデブリの位置、vx/vy はその移動速度。
  float x, y;
  float vx, vy;

  // rot/vr はデブリ自身の回転角と回転速度。
  float rot, vr;

  // size は単体デブリの図案サイズを制御する。
  // type は白い単位の位置をずらし、rose 波形の周波数も変える。
  // noiseSeed により、各デブリのノイズ形状をそれぞれ変える。
  float size;
  int type;
  float noiseSeed;

  Debris() {
    respawn(random(-logoR * 1.2, logoR * 1.2));
    x += random(-logoR, logoR);
    y += random(-logoR, logoR);
  }

  void respawn(float startX) {
    // 速度範囲。数値が大きいほどデブリの漂いが速くなる。
    float direction = random(TWO_PI);
    float speed = random(0.025, 0.12);

    x = startX;
    y = random(-logoR * 1.15, logoR * 1.15);
    vx = cos(direction) * speed;
    vy = sin(direction) * speed;

    if (abs(vx) < 0.018) vx += vx < 0 ? -0.028 : 0.028;
    if (abs(vy) < 0.010) vy += vy < 0 ? -0.016 : 0.016;

    rot = random(TWO_PI);
    vr = random(-0.0025, 0.0025);

    // 単体デブリのサイズ範囲。上の debrisSizeMin / debrisSizeMax で調整する。
    size = random(debrisSizeMin, debrisSizeMax);

    // 現在は3種類の type。k=3/5/7 に対応し、白い単位のずれにも影響する。
    type = int(random(3));
    noiseSeed = random(1000);
  }

  void update(float frameStep) {
    x += vx * frameStep;
    y += vy * frameStep;
    rot += vr * frameStep;

    // ラップ範囲。width ではなく logoR 基準で計算し、白いテクスチャが遠くへ流れて黒い六角形だけが残るのを避ける。
    float margin = logoR * 1.25 + size * 0.45;
    if (x < -margin) x = margin;
    if (x > margin) x = -margin;
    if (y < -margin) y = margin;
    if (y > margin) y = -margin;
  }

  void draw() {
    pushMatrix();
    translate(x, y);
    rotate(rot);
    noStroke();
    // k=3/5/7。k が大きいほど rose 波形は密になる。
    drawRoseGrid(3 + type * 2);
    popMatrix();
  }

  void drawRoseGrid(float k) {
    // radialSteps は半径方向の段数、angleSteps は円周方向の分割数。
    // どちらも大きいほど形は密になるが、処理も重くなる。
    int radialSteps = 3;
    int angleSteps = 14;

    // phase はグローバル時間とデブリの回転を混ぜ、各デブリの変化が同期しないようにする。
    float phase = t + rot;

    for (int rr = 0; rr < radialSteps; rr++) {
      float p0 = rr / float(radialSteps);
      float p1 = (rr + 1) / float(radialSteps);

      for (int aa = 0; aa < angleSteps; aa++) {
        float a0 = TWO_PI * aa / angleSteps;
        float a1 = TWO_PI * (aa + 1) / angleSteps;

        // 白い単位の選択ルール。
        // % 3 は約3分の1の単位を白にする。% 2 に変えるとより白く、より密になる。
        if ((rr + aa + type) % 3 != 0) continue;

        noStroke();
        fill(255);
        drawPatternCell(a0, a1, p0, p1, k, phase, size, noiseSeed, x, y, rot);
      }
    }
  }
}

void drawOuterMask() {
  // 反転した白マスクで、最終的な外形を切り出す。
  // useHexCrop=true なら六角形。H を押すと円形に切り替えられる。
  noStroke();
  fill(255);

  if (!useHexCrop) {
    drawCircleOutsideMask();
    drawFinalCircleCleanupMask();
    return;
  }

  float m = width;
  beginShape();
  vertex(-m, -m);
  vertex(m, -m);
  vertex(m, m);
  vertex(-m, m);

  beginContour();
  for (int i = 5; i >= 0; i--) {
    float a = TWO_PI * i / 6.0;
    vertex(cos(a) * logoR, sin(a) * logoR);
  }
  endContour();

  endShape(CLOSE);
  drawFinalCircleCleanupMask();
}

void drawCircleOutsideMask() {
  noFill();
  stroke(255);
  strokeWeight(width);
  ellipse(0, 0, logoR * 2 + width, logoR * 2 + width);
  noStroke();
}

void drawFinalCircleCleanupMask() {
  noFill();
  stroke(255);
  strokeWeight(width);
  ellipse(0, 0, logoR * 2 - finalCircleMaskInset * 2 + width, logoR * 2 - finalCircleMaskInset * 2 + width);
  noStroke();
}

void keyPressed() {
  if (key == ' ') paused = !paused;
  if (key == 'h' || key == 'H') useHexCrop = !useHexCrop;
  if (key == 'r' || key == 'R') {
    seedValue = int(random(1000000));
    resetDebris();
  }
  if (key == 's' || key == 'S') saveFrame("noise_curves_logo_####.png");
}
