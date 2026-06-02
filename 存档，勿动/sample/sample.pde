// S^n Debris Logo Prototype
// 固定相机 + 固定 30 度扇区 + 几何碎片流动层。
// 噪波曲线版本：在 rose 网格上加入连续 noise 扭曲。
// SPACE 暂停/播放，S 保存截图，H 切换六边形/圆形，R 重新生成碎片。

import java.awt.Shape;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.geom.Path2D;
import processing.awt.PGraphicsJava2D;

// 存放所有正在画面中飞行的几何碎片。
// 想让画面更满，可以增加 resetDebris() 里的数量；想更轻，就减少。
ArrayList<Debris> debris = new ArrayList<Debris>();

// logoR 控制最终标章的外轮廓大小。
// 你现在调成 150。这个值越大，六边形越大，碎片活动范围也会跟着变大。
float logoR = 150;

// t 是全局动画时间。draw() 里每帧增加 0.01，影响噪波和波形的流动速度。
float t = 0;
boolean paused = false;
boolean useHexCrop = true;

// 用 seed 固定随机结果；按 R 会换一个 seed，生成另一版 logo。
int seedValue = 2026;

void setup() {
  size(900, 900, JAVA2D);
  pixelDensity(1);

  // 关掉抗锯齿，让黑白边缘变硬。
  // 如果你想要柔和边缘，可以改回 smooth(4)，并删掉 disableAntialias()。
  noSmooth();
  disableAntialias();
  resetDebris();
}

void draw() {
  // 有些 Java2D 状态可能被后续绘制改掉，所以每帧再关一次抗锯齿。
  disableAntialias();

  if (!paused) {
    // 动画速度入口。0.01 越大，噪波/碎片流动越快。
    t += 0.01;
    for (Debris d : debris) {
      d.update();
    }
  }

  background(255);
  translate(width / 2.0, height / 2.0);

  drawKaleidoscopeDebris();
  drawOuterMask();
}

void disableAntialias() {
  PGraphicsJava2D pg = (PGraphicsJava2D)g;
  Graphics2D g2 = pg.g2;
  g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_OFF);
  g2.setRenderingHint(RenderingHints.KEY_STROKE_CONTROL, RenderingHints.VALUE_STROKE_PURE);
}

void resetDebris() {
  randomSeed(seedValue);
  debris.clear();

  // 碎片数量。数量越大越密，但也越卡。
  // 现在 36 是比较满的版本；如果掉帧，可以试 24 或 30。
  for (int i = 0; i < 36; i++) {
    debris.add(new Debris());
  }
}

void drawKaleidoscopeDebris() {
  // 6 次旋转，每次再镜像一次，合起来是 12 个半扇区。
  // 如果想减少复杂度，可以先只改碎片数量，不建议先改这里。
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
  // Java2D clip 把绘制限制在 30 度半扇区里。
  // 后面旋转和镜像时，所有内容就会组成万花筒。
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

  // 当前方案的关键：先把扇区铺黑，再只画白色单元。
  // 这样不会出现黑色单元之间拼接导致的小白线。
  drawBlackSectorBase();
  for (Debris d : debris) {
    d.draw();
  }
  g2.setClip(oldClip);
}

void drawBlackSectorBase() {
  // 这里只铺当前 clipped 扇区。外面的六边形裁切仍由 drawOuterMask() 控制。
  noStroke();
  fill(0);
  rect(0, -width, width * 1.5, width * 2);
}

class Debris {
  // x/y: 碎片位置；vx/vy: 速度。
  float x, y;
  float vx, vy;

  // rot/vr: 碎片自身旋转和旋转速度。
  float rot, vr;

  // size: 单个碎片的图案尺寸。
  // type: 控制白色单元出现位置和 rose 波形频率。
  // noiseSeed: 每个碎片独立的噪波种子，避免所有碎片同步变形。
  float size;
  int type;
  float noiseSeed;

  Debris() {
    respawn(random(-logoR * 1.2, logoR * 1.2));
    x += random(-logoR, logoR);
    y += random(-logoR, logoR);
  }

  void respawn(float startX) {
    // 速度越大，碎片流动越明显。这里的数值很小，是为了保持缓慢漂移。
    float direction = random(TWO_PI);
    float speed = random(0.045, 0.22);

    x = startX;
    y = random(-logoR * 1.15, logoR * 1.15);
    vx = cos(direction) * speed;
    vy = sin(direction) * speed;

    if (abs(vx) < 0.035) vx += vx < 0 ? -0.055 : 0.055;
    if (abs(vy) < 0.018) vy += vy < 0 ? -0.032 : 0.032;

    rot = random(TWO_PI);
    vr = random(-0.004, 0.004);

    // 图案尺寸范围。logoR=150 时，这里偏大，所以会形成大块切片感。
    // 想更碎：降低到 random(80, 180)。想更大块：提高上限。
    size = random(130, 310);

    // 0,1,2 三种 type。现在只用于让白色单元位置错开，并改变 k。
    type = int(random(3));
    noiseSeed = random(1000);
  }

  void update() {
    x += vx;
    y += vy;
    rot += vr;

    // 包裹范围。之前按 width 包裹会导致白色纹理跑出 logo，最后只剩黑底。
    // 现在按 logoR 控制，让碎片一直在标章附近循环。
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

    // k = 3,5,7，对应三种 rose 波形密度。
    // 改这里可以快速测试整体线性：比如固定 drawRoseGrid(5)。
    drawRoseGrid(3 + type * 2);
    popMatrix();
  }

  void drawRoseGrid(float k) {
    // radialSteps 控制半径方向分几圈。
    // angleSteps 控制圆周方向分几瓣。
    // 两者越大，白色单元越细密，也越卡。
    int radialSteps = 3;
    int angleSteps = 14;

    // phase 把全局时间和碎片自身旋转混合，让每块碎片波动不同。
    float phase = t + rot;

    for (int rr = 0; rr < radialSteps; rr++) {
      float p0 = rr / float(radialSteps);
      float p1 = (rr + 1) / float(radialSteps);

      for (int aa = 0; aa < angleSteps; aa++) {
        float a0 = TWO_PI * aa / angleSteps;
        float a1 = TWO_PI * (aa + 1) / angleSteps;

        // 白色单元选择规则。
        // % 3 表示大约三分之一单元变白；改成 % 2 会更密、更白。
        // 加 type 是为了不同碎片的白色位置错开。
        if ((rr + aa + type) % 3 != 0) continue;

        noStroke();
        fill(255);
        beginShape();
        noiseCurveVertex(a0, p0, k, phase);
        noiseCurveVertex(a1, p0, k, phase);
        noiseCurveVertex(a1, p1, k, phase);
        noiseCurveVertex(a0, p1, k, phase);
        endShape(CLOSE);
      }
    }
  }

  float roseRadius(float a, float k, float phase) {
    // rose 基础半径。k 越大，花瓣/波峰越多。
    // 0.28 是最小半径，0.72 是波动量；两者相加最好接近 1。
    float wave = abs(cos(k * a + phase));
    return (0.28 + wave * 0.72) * size * 0.42;
  }

  void roseVertex(float a, float p, float k, float phase) {
    float r = roseRadius(a, k, phase) * p;
    vertex(cos(a) * r, sin(a) * r);
  }

  float noiseBend(float a, float p) {
    // 噪波采样。
    // 1.2 控制角度方向噪波尺度，1.8 控制半径方向噪波尺度。
    // t * 0.25 控制噪波流动速度；越小越稳，越大越活。
    return noise(noiseSeed + cos(a) * 1.2, noiseSeed + sin(a) * 1.2, p * 1.8 + t * 0.25);
  }

  float noiseCurveAngle(float a, float p, float k, float phase, float bend) {
    // 把噪波转换成角度扭曲。
    // jitter 是慢变化的偏移，ripple 是正弦波纹。
    // 如果边缘太疯，先减小 -0.18/0.18 和 0.08。
    float jitter = map(bend, 0, 1, -0.18, 0.18);
    float ripple = sin(a * (k + 2.0) + phase + bend * TWO_PI) * 0.08;
    return a + jitter * (0.35 + p) + ripple;
  }

  float noiseCurveRadius(float a, float p, float k, float phase, float bend) {
    // 把噪波转换成半径变化。
    // 0.96 是基础缩放，0.18 是噪波带来的伸缩幅度。
    float r = roseRadius(a, k, phase) * p;
    return r * (0.96 + bend * 0.18);
  }

  void noiseCurveVertex(float a, float p, float k, float phase) {
    // 所有白色形状最终都通过这个函数落点。
    // 想换线型，一般优先改 noiseCurveAngle() / noiseCurveRadius()，
    // 或者在 drawRoseGrid() 里换成不同的 drawXXXCell()。
    float bend = noiseBend(a, p);
    float aa = noiseCurveAngle(a, p, k, phase, bend);
    float rr = noiseCurveRadius(a, p, k, phase, bend);
    vertex(cos(aa) * rr, sin(aa) * rr);
  }
}

void drawOuterMask() {
  // 最后用白色反向遮罩裁出外轮廓。
  // useHexCrop=true 是六边形；按 H 可以切换圆形。
  noStroke();
  fill(255);

  if (!useHexCrop) {
    drawCircleOutsideMask();
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
}

void drawCircleOutsideMask() {
  noFill();
  stroke(255);
  strokeWeight(width);
  ellipse(0, 0, logoR * 2 + width, logoR * 2 + width);
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
