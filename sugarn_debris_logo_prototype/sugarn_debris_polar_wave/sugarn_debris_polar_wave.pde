// S^n Debris Logo Prototype
// 固定相机 + 固定 30 度扇区 + 几何碎片流动层。
// 所有图形都是黑白矢量，不使用像素采样。
// SPACE 暂停/播放，S 保存截图，H 切换六边形/圆形，R 重新生成碎片。

import java.awt.Shape;
import java.awt.Graphics2D;
import java.awt.geom.Path2D;
import processing.awt.PGraphicsJava2D;

// 存放所有正在画面中飞行的几何碎片。
ArrayList<Debris> debris = new ArrayList<Debris>();

// logoR 控制最终标章的外轮廓大小。
float logoR = 285;
float t = 0;
boolean paused = false;
boolean useHexCrop = true;

// 用 seed 固定随机结果；按 R 会换一个 seed，生成另一版 logo。
int seedValue = 2026;

void setup() {
  size(900, 900, JAVA2D);
  pixelDensity(1);
  smooth(4);
  resetDebris();
}

void draw() {
  // 相机不移动。动画只来自碎片自己的运动。
  if (!paused) {
    t += 0.01;
    updateDebris();
  }

  background(255);
  translate(width / 2.0, height / 2.0);

  // 先画被万花筒复制后的碎片层，再用白色遮罩裁出外形。
  drawKaleidoscopeDebris();
  drawOuterMask();
}

void resetDebris() {
  // 使用同一个 seed 时，碎片的初始状态保持一致。
  randomSeed(seedValue);
  debris.clear();

  // 数量越大，画面越像持续流过的几何空间碎片。
  for (int i = 0; i < 140; i++) {
    debris.add(new Debris(i));
  }
}

void updateDebris() {
  for (Debris d : debris) {
    d.update();
  }
}

void drawKaleidoscopeDebris() {
  // 只绘制一个 30 度半扇区，然后镜像成 60 度，再旋转复制 6 次。
  float sector = PI / 3.0;
  for (int i = 0; i < 6; i++) {
    pushMatrix();
    rotate(i * sector);
    drawClippedHalfSector();
    scale(1, -1);
    drawClippedHalfSector();
    popMatrix();
  }
}

void drawClippedHalfSector() {
  // 用 Java2D clip 锁死 0~30 度半扇区。
  // 这样碎片可以在大空间中飞行，但每次只显示扇区里的部分。
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
  drawDebrisLayer();
  g2.setClip(oldClip);
}

void drawDebrisLayer() {
  // 在固定相机前绘制所有碎片；clip 会负责隐藏扇区外的部分。
  for (Debris d : debris) {
    d.draw();
  }
}

class Debris {
  // 位置与速度。
  float x, y;
  float vx, vy;

  // 自身旋转与旋转速度。
  float rot, vr;

  // 尺寸、类型、线宽。
  float size;
  int type;
  float weight;

  Debris(int index) {
    // 初始化时打散位置，让一开始画面里已经有碎片。
    respawn(random(-logoR * 1.2, logoR * 1.2));
    x += random(-logoR, logoR);
    y += random(-logoR, logoR);
  }

  void respawn(float startX) {
    // 碎片重生时随机方向和速度，像宇宙空间中从画面外流过。
    float direction = random(TWO_PI);
    float speed = random(0.045, 0.22);

    x = startX;
    y = random(-logoR * 1.15, logoR * 1.15);
    vx = cos(direction) * speed;
    vy = sin(direction) * speed;

    // 给速度一个最小值，避免碎片几乎停住。
    if (abs(vx) < 0.035) vx += vx < 0 ? -0.055 : 0.055;
    if (abs(vy) < 0.018) vy += vy < 0 ? -0.032 : 0.032;

    rot = random(TWO_PI);
    vr = random(-0.004, 0.004);

    // 当前版本只保留大元素：空心圆、长线、圆环。
    size = random(95, 260);
    type = int(random(3));
    weight = 2.2;
  }

  void update() {
    // 每帧更新位置和旋转。
    x += vx;
    y += vy;
    rot += vr;

    float margin = logoR * 1.45;
    if (x < -margin || x > margin || y < -margin || y > margin) {
      // 离开观察范围后从外侧重新进入，保持画面持续流动。
      float side = random(1);
      if (side < 0.5) {
        respawn(vx > 0 ? -margin : margin);
      } else {
        x = random(-logoR, logoR);
        y = vy > 0 ? -margin : margin;
      }
    }
  }

  void draw() {
    // 每个碎片先移动到自己的局部坐标，再按类型绘制。
    pushMatrix();
    translate(x, y);
    rotate(rot);
    stroke(0);
    strokeWeight(weight);
    noFill();

    if (type == 0) drawPolarWaveLoop(5);
    if (type == 1) drawPolarWaveLoop(7);
    if (type == 2) drawPolarWaveLoop(9);

    popMatrix();
  }

  void drawDot() {
    stroke(0);
    strokeWeight(weight);
    noFill();
    drawPolarWaveLoop(4);
  }

  void drawLongLine() {
    stroke(0);
    strokeWeight(weight);
    noFill();
    drawPolarWaveLoop(6);
  }

  void drawRing() {
    stroke(0);
    strokeWeight(weight);
    noFill();
    drawPolarWaveLoop(8);
  }

  void drawPolarWaveLoop(int k) {
    beginShape();
    for (int i = 0; i <= 48; i++) {
      float a = TWO_PI * i / 48.0;
      float r = size * 0.36 + sin(a * k + t * 2.2 + rot) * size * 0.09;
      vertex(cos(a) * r, sin(a) * r);
    }
    endShape(CLOSE);
  }
}

void drawOuterMask() {
  // 画完万花筒后，用白色反向遮罩裁出最终 logo 外轮廓。
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
  if (useHexCrop) {
    // 默认六边形，更接近结晶/万花筒标章。
    for (int i = 5; i >= 0; i--) {
      float a = TWO_PI * i / 6.0;
      vertex(cos(a) * logoR, sin(a) * logoR);
    }
  } else {
    // 圆形版本用于检查更柔和的标章边界。
    for (int i = 95; i >= 0; i--) {
      float a = TWO_PI * i / 48.0;
      vertex(cos(a) * logoR, sin(a) * logoR);
    }
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
  // 基础交互：暂停、切换外形、重新生成、截图。
  if (key == ' ') paused = !paused;
  if (key == 'h' || key == 'H') useHexCrop = !useHexCrop;
  if (key == 'r' || key == 'R') {
    seedValue = int(random(1000000));
    resetDebris();
  }
  if (key == 's' || key == 'S') saveFrame("sugarn_debris_logo_####.png");
}
