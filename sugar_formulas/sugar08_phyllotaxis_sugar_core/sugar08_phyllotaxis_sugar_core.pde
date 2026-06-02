// Sugar^n Formula Sketch 08
// Phyllotaxis Sugar Core
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

  float t = animFrame * 0.017;
  translate(width / 2, height * 0.55, 0);
  rotateX(-0.85 + sin(t * 0.32) * 0.18);
  rotateY(t * 0.22);

  stroke(0);
  strokeWeight(0.7);

  int n = 950;
  float golden = PI * (3 - sqrt(5));

  for (int i = 1; i < n; i++) {
    PVector p = pointFor(i, golden, t);
    pushMatrix();
    translate(p.x, p.y, p.z);
    rotateY(i * golden + t);
    rotateX(sin(t + i * 0.07) * 0.8);
    float sz = 4.0 + 12.0 * pow(1.0 - i / float(n), 0.7);
    if (solidMode) {
      fill(252);
      drawSolidDiamond(sz);
    } else {
      noFill();
      drawWireDiamond(sz);
    }
    popMatrix();
  }

  drawOverlay(
    "08 Phyllotaxis Sugar Core    mode=" + (solidMode ? "volume" : "line"),
    "theta=n*goldenAngle, r=c*sqrt(n), z=A*sin(k*theta+t)+B*cos(r*s-t)",
    "each point becomes a rotating sugar diamond on a spiral seed lattice"
  );
}

PVector pointFor(int i, float golden, float t) {
  float theta = i * golden;
  float r = 11.5 * sqrt(i);
  float shell = 1.0 - i / 950.0;
  float x = r * cos(theta);
  float y = r * sin(theta);
  float z = 95 * sin(theta * 5 + t) * shell + 55 * cos(r * 0.055 - t * 1.4);
  return new PVector(x, y, z);
}

void drawSolidDiamond(float s) {
  PVector top = new PVector(0, -s * 1.8, 0);
  PVector bottom = new PVector(0, s * 1.8, 0);
  PVector front = new PVector(0, 0, s);
  PVector back = new PVector(0, 0, -s);
  PVector left = new PVector(-s, 0, 0);
  PVector right = new PVector(s, 0, 0);
  tri(top, right, front);
  tri(top, front, left);
  tri(top, left, back);
  tri(top, back, right);
  tri(bottom, front, right);
  tri(bottom, left, front);
  tri(bottom, back, left);
  tri(bottom, right, back);
}

void drawWireDiamond(float s) {
  beginShape();
  vertex(0, -s * 1.8, 0);
  vertex(s, 0, 0);
  vertex(0, s * 1.8, 0);
  vertex(-s, 0, 0);
  vertex(0, -s * 1.8, 0);
  endShape();
  line(0, -s * 1.8, 0, 0, 0, s);
  line(s, 0, 0, 0, 0, s);
  line(0, s * 1.8, 0, 0, 0, s);
  line(-s, 0, 0, 0, 0, s);
}

void tri(PVector a, PVector b, PVector c) {
  beginShape(TRIANGLES);
  vertex(a.x, a.y, a.z);
  vertex(b.x, b.y, b.z);
  vertex(c.x, c.y, c.z);
  endShape();
}

void keyPressed() {
  if (key == ' ') paused = !paused;
  if (key == 'v' || key == 'V') solidMode = !solidMode;
  if (key == 's' || key == 'S') saveFrame("phyllotaxis_sugar_core_####.png");
}

void drawOverlay(String title, String formula, String params) {
  hint(DISABLE_DEPTH_TEST);
  camera();
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
