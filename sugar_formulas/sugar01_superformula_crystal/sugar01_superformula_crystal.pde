// Sugar^n Formula Sketch 01
// Superformula Crystal
// SPACE pause/play, S save screenshot

float animFrame = 0;
boolean paused = false;
boolean solidMode = true;

void setup() {
  size(1000, 1000, P3D);
  smooth(8);
}

void draw() {
  background(255);
  if (!paused) animFrame++;

  float t = animFrame * 0.018;
  lights();
  translate(width * 0.5, height * 0.54, 0);
  rotateX(-0.7 + sin(t * 0.37) * 0.18);
  rotateY(t * 0.34);
  rotateZ(sin(t * 0.21) * 0.25);

  if (solidMode) fill(252);
  else noFill();
  stroke(0);
  strokeWeight(0.8);

  int layers = 52;
  int steps = 180;
  float heightSpan = 470;

  for (int k = 0; k < layers - 1; k++) {
    beginShape(QUAD_STRIP);
    for (int i = 0; i <= steps; i++) {
      float a = map(i, 0, steps, 0, TWO_PI);
      PVector p1 = crystalPoint(k, a, layers, heightSpan, t);
      PVector p2 = crystalPoint(k + 1, a, layers, heightSpan, t);
      vertex(p1.x, p1.y, p1.z);
      vertex(p2.x, p2.y, p2.z);
    }
    endShape();
  }

  drawOverlay(
    "01 Superformula Crystal    mode=" + (solidMode ? "volume" : "line"),
    "r(theta)=(|cos(m*theta/4)/a|^n2+|sin(m*theta/4)/b|^n3)^(-1/n1)",
    "m=6+2*sin(t*.23), n1/n2/n3 morph over stacked z-layers"
  );
}

PVector crystalPoint(int k, float a, int layers, float heightSpan, float t) {
  float v = map(k, 0, layers - 1, -1, 1);
  float layerPhase = t + k * 0.08;
  float m = 6.0 + 2.0 * sin(t * 0.23);
  float n1 = 0.32 + 0.18 * sin(layerPhase * 0.7);
  float n2 = 1.25 + 0.45 * cos(t * 0.4 + v * 3.0);
  float n3 = 1.25 + 0.45 * sin(t * 0.31 - v * 2.0);
  float layerScale = 1.0 - abs(v) * 0.48 + 0.08 * sin(t * 1.2 + k);
  float r = superR(a, m, 1.0, 1.0, n1, n2, n3);
  float twist = v * 1.7 + t * 0.4;
  float rr = 165 * r * layerScale;
  float z = v * heightSpan * 0.5;
  return new PVector(cos(a + twist) * rr, sin(a + twist) * rr, z);
}

float superR(float theta, float m, float a, float b, float n1, float n2, float n3) {
  float p1 = pow(abs(cos(m * theta / 4.0) / a), n2);
  float p2 = pow(abs(sin(m * theta / 4.0) / b), n3);
  float p = pow(p1 + p2, -1.0 / n1);
  if (Float.isNaN(p) || Float.isInfinite(p)) return 0;
  return p;
}

void keyPressed() {
  if (key == ' ') paused = !paused;
  if (key == 'v' || key == 'V') solidMode = !solidMode;
  if (key == 's' || key == 'S') saveFrame("superformula_crystal_####.png");
}

void drawOverlay(String title, String formula, String params) {
  hint(DISABLE_DEPTH_TEST);
  camera();
  noLights();
  fill(255, 235);
  noStroke();
  rect(28, 28, 944, 96);
  fill(0);
  textAlign(LEFT, TOP);
  textSize(18);
  text(title + "    SPACE pause/play    V line/volume    S screenshot", 44, 42);
  textSize(13);
  text(formula, 44, 70);
  text(params, 44, 94);
  hint(ENABLE_DEPTH_TEST);
}
