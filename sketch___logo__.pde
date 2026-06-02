// Fast Procedural Kaleidoscope Logo
// Vector remake of the original pixel-sampled version.
// Big procedural pattern -> moving camera -> 30° fold -> mirror -> 6 repeats
// White background / black pattern only / hexagon logo crop
// Processing Java Mode

float t = 0;
float speed = 0.002;

int OUT = 900;

// 摄像机参数
float camX, camY, camRot, camZoom;

// logo 外轮廓大小
// 这是以最终 900x900 画面坐标计算的半径
float logoR = 250;

// 外轮廓类型
// true = 正六边形；false = 圆形
boolean useHexCrop = true;

void setup() {
  size(900, 900, JAVA2D);
  pixelDensity(1);
  smooth(4);
}

void draw() {
  t = frameCount * speed;

  // 摄像机在“无限大图案世界”上游走
  camX = sin(t * 0.47) * 520 + cos(t * 0.19) * 340;
  camY = cos(t * 0.41) * 480 + sin(t * 0.23) * 360;
  camRot = t * 0.22 + sin(t * 0.37) * 0.55;
  camZoom = 0.85 + sin(t * 0.31) * 0.18;

  background(255);

  pushMatrix();
  translate(width / 2.0, height / 2.0);
  drawVectorKaleidoscope();
  drawWhiteOutsideLogo();
  popMatrix();
}

// ------------------------------------------------------------
// 矢量万花筒
// 只画原来 0~30° 的半扇区，再旋转 / 镜像成 6 组
// ------------------------------------------------------------

void drawVectorKaleidoscope() {
  noStroke();
  fill(0);

  float sector = PI / 3.0;

  for (int i = 0; i < 6; i++) {
    pushMatrix();
    rotate(i * sector);
    drawVectorWorldPattern();
    scale(1, -1);
    drawVectorWorldPattern();
    popMatrix();
  }
}

// ------------------------------------------------------------
// 把“无限大图案世界”中的格子形状反算回 0~30° 扇区
// ------------------------------------------------------------

void drawVectorWorldPattern() {
  float cell = 115.0;

  // Keep a stable candidate grid around the camera cell.
  // This avoids visible popping when min/max ranges cross integer cell boundaries.
  int centerGX = floor(camX / cell);
  int centerGY = floor(camY / cell);
  int range = 8;
  int minGX = centerGX - range;
  int maxGX = centerGX + range;
  int minGY = centerGY - range;
  int maxGY = centerGY + range;

  for (int gy = minGY; gy <= maxGY; gy++) {
    for (int gx = minGX; gx <= maxGX; gx++) {
      drawCellShapes(gx, gy, cell);
    }
  }
}

void drawCellShapes(int gx, int gy, float cell) {
  float h1 = hash(gx, gy, 1.0);
  float h2 = hash(gx, gy, 2.0);
  float h3 = hash(gx, gy, 3.0);
  float h4 = hash(gx, gy, 4.0);

  float centerX = (gx + 0.5) * cell + map(h1, 0, 1, -28, 28);
  float centerY = (gy + 0.5) * cell + map(h2, 0, 1, -28, 28);

  float rot = h3 * TWO_PI + t * (0.35 + h4 * 0.35);

  float size = 42 + h4 * 75;
  size *= 0.9 + sin(t * 0.8 + h1 * 10.0) * 0.14;
  size *= 0.52;

  drawIceWingVector(centerX, centerY, rot, size, h1, h2);

  float ox = map(hash(gx, gy, 5.0), 0, 1, -48, 48);
  float oy = map(hash(gx, gy, 6.0), 0, 1, -48, 48);
  drawDiamondVector(centerX, centerY, rot, ox, oy, size * 0.28, 0);
}

// ------------------------------------------------------------
// 原版 iceWingShape() 的矢量近似
// ------------------------------------------------------------

void drawIceWingVector(float cx, float cy, float rot, float s, float h1, float h2) {
  float len = s * (1.65 + h1 * 0.55);
  float w = s * (0.30 + h2 * 0.16);

  // 主冰晶 / 翅膀
  float[][] main = {
    {-len * 0.30, 0},
    {0, -w},
    {len, 0},
    {0, w}
  };
  drawLocalPolygon(cx, cy, rot, main);

  // 尖端
  float[][] tip = {
    {len * 0.25, -w * 0.62},
    {len * 1.15, 0},
    {len * 0.25, w * 0.62}
  };
  drawLocalPolygon(cx, cy, rot, tip);

  // 上下小菱形
  drawDiamondVector(cx, cy, rot, -len * 0.10, -w * 0.56, s * 0.42, -0.35);
  drawDiamondVector(cx, cy, rot, -len * 0.06, w * 0.54, s * 0.34, 0.35);
}

void drawDiamondVector(float cx, float cy, float baseRot, float ox, float oy, float s, float rot) {
  float len = s * 1.45;
  float w = s * 0.42;

  float[][] pts = {
    {-len, 0},
    {0, -w},
    {len, 0},
    {0, w}
  };

  float c = cos(rot);
  float ss = sin(rot);

  for (int i = 0; i < pts.length; i++) {
    float x = pts[i][0];
    float y = pts[i][1];
    pts[i][0] = ox + x * c - y * ss;
    pts[i][1] = oy + x * ss + y * c;
  }

  drawLocalPolygon(cx, cy, baseRot, pts);
}

// ------------------------------------------------------------
// cell 局部坐标 -> world 坐标 -> camera 反变换 -> 半扇区坐标
// ------------------------------------------------------------

void drawLocalPolygon(float cx, float cy, float cellRot, float[][] pts) {
  PVector[] sectorPts = new PVector[pts.length];
  boolean anyVisible = false;
  float sumX = 0;
  float sumY = 0;

  for (int i = 0; i < pts.length; i++) {
    sectorPts[i] = cellLocalToSector(cx, cy, cellRot, pts[i][0], pts[i][1]);
    PVector p = sectorPts[i];
    sumX += p.x;
    sumY += p.y;
    if (insideExpandedLogoRadius(p.x, p.y, logoR + 170)) {
      anyVisible = true;
    }
  }

  for (int i = 0; i < sectorPts.length; i++) {
    PVector a = sectorPts[i];
    PVector b = sectorPts[(i + 1) % sectorPts.length];
    float mx = (a.x + b.x) * 0.5;
    float my = (a.y + b.y) * 0.5;
    if (insideExpandedLogoRadius(mx, my, logoR + 170)) {
      anyVisible = true;
    }
  }

  if (insideExpandedLogoRadius(sumX / pts.length, sumY / pts.length, logoR + 170)) {
    anyVisible = true;
  }

  if (!anyVisible) return;

  beginShape();
  for (int i = 0; i < sectorPts.length; i++) {
    vertex(sectorPts[i].x, sectorPts[i].y);
  }
  endShape(CLOSE);
}

PVector cellLocalToSector(float cx, float cy, float cellRot, float x, float y) {
  float wc = cos(cellRot);
  float ws = sin(cellRot);

  float worldX = cx + x * wc - y * ws;
  float worldY = cy + x * ws + y * wc;

  float rx = (worldX - camX) * camZoom;
  float ry = (worldY - camY) * camZoom;

  // 原版中 rx/ry = R(camRot) * local，所以这里反向旋转
  float c = cos(-camRot);
  float s = sin(-camRot);
  float localX = rx * c - ry * s;
  float localY = rx * s + ry * c;

  return new PVector(localX, localY);
}

boolean insideExpandedLogoRadius(float x, float y, float r) {
  float d = sqrt(x * x + y * y);
  return d <= r;
}

// ------------------------------------------------------------
// logo 外部遮罩：保持原版“裁切后白底”的视觉
// ------------------------------------------------------------

void drawWhiteOutsideLogo() {
  noStroke();
  fill(255);

  float m = width;
  beginShape();
  vertex(-m, -m);
  vertex(m, -m);
  vertex(m, m);
  vertex(-m, m);

  beginContour();
  if (useHexCrop) {
    for (int i = 5; i >= 0; i--) {
      float a = TWO_PI * i / 6.0;
      vertex(cos(a) * logoR, sin(a) * logoR);
    }
  } else {
    for (int i = 95; i >= 0; i--) {
      float a = TWO_PI * i / 96.0;
      vertex(cos(a) * logoR, sin(a) * logoR);
    }
  }
  endContour();

  endShape(CLOSE);
}

// ------------------------------------------------------------
// hash / 工具函数
// ------------------------------------------------------------

float hash(int x, int y, float seed) {
  float n = sin(x * 127.1 + y * 311.7 + seed * 91.3) * 43758.5453;
  return fract(n);
}

float fract(float x) {
  return x - floor(x);
}

// ------------------------------------------------------------
// 操作
// S：保存当前帧
// H：切换六边形 / 圆形裁切
// ------------------------------------------------------------

void keyPressed() {
  if (key == 's' || key == 'S') {
    saveFrame("kaleidoscope_logo_####.png");
  }

  if (key == 'h' || key == 'H') {
    useHexCrop = !useHexCrop;
  }
}
