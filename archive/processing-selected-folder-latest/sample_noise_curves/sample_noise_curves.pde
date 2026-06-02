// S^n Debris Logo Prototype
// 固定相机 + 固定 30 度扇区 + 几何碎片流动层。
// 噪波曲线版本：在 rose 网格上加入连续 noise 扭曲。
// SPACE 暂停/播放，S 保存截图，H 切换六边形/圆形，R 重新生成碎片。

import java.awt.Shape;
import java.awt.Graphics2D;
import java.awt.geom.Path2D;
import processing.awt.PGraphicsJava2D;

// 存放所有正在画面中飞行的几何碎片。
// 想让图案更满：增加 resetDebris() 里的数量；想更流畅：减少数量。
ArrayList<Debris> debris = new ArrayList<Debris>();

// logoR 控制最终标章的外轮廓大小。
// 你当前调成 150。这个值同时影响外轮廓和碎片循环范围。
float logoR = 150;

// 全局时间。draw() 每帧增加它，用来驱动噪波和波形流动。
float t = 0;
boolean paused = false;
boolean useHexCrop = true;

// 用 seed 固定随机结果；按 R 会换一个 seed，生成另一版 logo。
int seedValue = 2026;

void setup() {
  size(900, 900, JAVA2D);
  pixelDensity(1);

  // smooth(4) 会让边缘更柔，但可能有一点灰边。
  // 如果要更硬的黑白边，可以改成 noSmooth()。
  smooth(4);
  resetDebris();
}

void draw() {
  if (!paused) {
    // 动画速度。越大越快；觉得闪/乱可以降到 0.005。
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

void resetDebris() {
  randomSeed(seedValue);
  debris.clear();

  // 碎片数量。36 比较满，也会更耗性能。
  // 卡的话先试 24 或 30；太空则提高到 42。
  for (int i = 0; i < 70; i++) {
    debris.add(new Debris());
  }
}

void drawKaleidoscopeDebris() {
  // 6 次旋转 + 每次镜像，最终形成 12 个半扇区的万花筒。
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
  // 用 Java2D clip 限制绘制区域，只画 30 度半扇区。
  // 后续 rotate/scale 会把这个扇区复制成完整标章。
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

  // 当前版本的关键方案：
  // 先铺黑底，再只绘制白色噪波单元，避免黑色多边形之间拼接出白线。
  drawBlackSectorBase();
  for (Debris d : debris) {
    d.draw();
  }
  g2.setClip(oldClip);
}

void drawBlackSectorBase() {
  // 黑底只会被上面的 wedge clip 限制在当前半扇区里。
  // 最终外轮廓仍由 drawOuterMask() 裁切。
  noStroke();
  fill(0);
  rect(0, -width, width * 1.5, width * 2);
}

class Debris {
  // x/y 是碎片位置，vx/vy 是它的移动速度。
  float x, y;
  float vx, vy;

  // rot/vr 是碎片自身旋转角和旋转速度。
  float rot, vr;

  // size 控制单个碎片图案大小。
  // type 用来错开白色单元位置，并改变 rose 波形频率。
  // noiseSeed 让每个碎片的噪波形状都不一样。
  float size;
  int type;
  float noiseSeed;

  Debris() {
    respawn(random(-logoR * 1.2, logoR * 1.2));
    x += random(-logoR, logoR);
    y += random(-logoR, logoR);
  }

  void respawn(float startX) {
    // 速度范围。数值越大，碎片漂移越快。
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

    // 单个碎片尺寸范围。
    // 想更碎：random(80, 180)；想更大块：提高上限。
    size = random(130, 310);

    // 目前 3 种 type，对应 k=3/5/7，并影响白色单元错位。
    type = int(random(3));
    noiseSeed = random(1000);
  }

  void update() {
    x += vx;
    y += vy;
    rot += vr;

    // 包裹范围。按 logoR 而不是 width 算，避免白色纹理跑远后只剩黑六边形。
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
    // k=3/5/7。k 越大，rose 波形越密。
    drawRoseGrid(3 + type * 2);
    popMatrix();
  }

  void drawRoseGrid(float k) {
    // radialSteps 是半径方向圈数；angleSteps 是圆周分段数。
    // 两个值越大，形状越密，也越卡。
    int radialSteps = 3;
    int angleSteps = 14;

    // phase 混合全局时间和碎片旋转，使每个碎片的变化不同步。
    float phase = t + rot;

    for (int rr = 0; rr < radialSteps; rr++) {
      float p0 = rr / float(radialSteps);
      float p1 = (rr + 1) / float(radialSteps);

      for (int aa = 0; aa < angleSteps; aa++) {
        float a0 = TWO_PI * aa / angleSteps;
        float a1 = TWO_PI * (aa + 1) / angleSteps;

        // 白色单元选择规则。
        // % 3 表示约三分之一单元为白；改成 % 2 会更白更密。
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
    // rose 基础波形。k 控制波峰数量。
    // 0.28 是最小半径，0.72 是波动量。
    float wave = abs(cos(k * a + phase));
    return (0.28 + wave * 0.72) * size * 0.42;
  }

  void roseVertex(float a, float p, float k, float phase) {
    float r = roseRadius(a, k, phase) * p;
    vertex(cos(a) * r, sin(a) * r);
  }

  float noiseBend(float a, float p) {
    // 噪波采样函数。
    // 1.2/1.8 控制噪波尺度；t * 0.25 控制噪波流动速度。
    return noise(noiseSeed + cos(a) * 1.2, noiseSeed + sin(a) * 1.2, p * 1.8 + t * 0.25);
  }

  float noiseCurveAngle(float a, float p, float k, float phase, float bend) {
    // 把 noise 变成角度偏移。
    // jitter 是大方向扭曲，ripple 是细波纹。太乱就先减小 0.18 和 0.08。
    float jitter = map(bend, 0, 1, -0.18, 0.18);
    float ripple = sin(a * (k + 2.0) + phase + bend * TWO_PI) * 0.08;
    return a + jitter * (0.35 + p) + ripple;
  }

  float noiseCurveRadius(float a, float p, float k, float phase, float bend) {
    // 把 noise 变成半径伸缩。
    // 0.96 是基础缩放，0.18 是噪波伸缩幅度。
    float r = roseRadius(a, k, phase) * p;
    return r * (0.96 + bend * 0.18);
  }

  void noiseCurveVertex(float a, float p, float k, float phase) {
    // 所有白色单元的顶点最终都走这里。
    // 要换线型，可以优先改 noiseCurveAngle()/noiseCurveRadius()。
    float bend = noiseBend(a, p);
    float aa = noiseCurveAngle(a, p, k, phase, bend);
    float rr = noiseCurveRadius(a, p, k, phase, bend);
    vertex(cos(aa) * rr, sin(aa) * rr);
  }
}

void drawOuterMask() {
  // 反向白色遮罩，裁出最终外轮廓。
  // useHexCrop=true 是六边形，按 H 可以切换圆形。
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
