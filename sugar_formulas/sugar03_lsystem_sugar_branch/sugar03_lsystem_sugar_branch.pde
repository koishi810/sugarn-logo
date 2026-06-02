// Sugar^n Formula Sketch 03
// L-system Sugar Branch
// SPACE pause/play, S save screenshot

float animFrame = 0;
boolean paused = false;
boolean solidMode = false;

void setup() {
  size(1000, 1000, P3D);
  smooth(8);
}

void draw() {
  background(255);
  if (!paused) animFrame++;

  float t = animFrame * 0.017;
  translate(width / 2, height * 0.56, 0);
  rotateX(-0.55 + sin(t * 0.4) * 0.16);
  rotateY(t * 0.25);

  noFill();
  stroke(0);
  strokeWeight(solidMode ? 5.0 : 1.05);

  int trunks = 8;
  for (int i = 0; i < trunks; i++) {
    pushMatrix();
    rotateY(TWO_PI * i / trunks + sin(t * 0.3) * 0.2);
    rotateZ(-HALF_PI + sin(t + i) * 0.12);
    branch(185, 6, t, i * 19.7);
    popMatrix();
  }

  drawOverlay(
    "03 L-system Sugar Branch    mode=" + (solidMode ? "volume" : "line"),
    "F(d)->line(len); if d>0: F(d-1)[+a][-a][^b][&b], len*=0.64",
    "a=0.42+0.22*sin(t+depth), b=0.34+0.2*cos(t+seed); recursive crystal growth"
  );
}

void branch(float len, int depth, float t, float seed) {
  if (depth <= 0 || len < 5) return;

  float grow = constrain(0.62 + 0.38 * sin(t * 1.4 - depth * 0.52 + seed), 0.05, 1.0);
  float current = len * grow;

  beginShape();
  for (int i = 0; i <= 12; i++) {
    float p = i / 12.0;
    float wobble = sin(p * PI + t * 2.0 + seed) * len * 0.045;
    vertex(p * current, wobble, cos(p * TWO_PI + seed) * wobble);
  }
  endShape();

  translate(current, 0, 0);

  float a = 0.42 + 0.22 * sin(t + depth + seed);
  float b = 0.34 + 0.20 * cos(t * 1.1 + seed);
  float child = len * 0.64;

  for (int i = 0; i < 4; i++) {
    pushMatrix();
    rotateX((i < 2 ? a : -a) + sin(seed + i) * 0.08);
    rotateZ((i % 2 == 0 ? b : -b) + i * HALF_PI);
    branch(child, depth - 1, t, seed + i * 3.17 + depth);
    popMatrix();
  }
}

void keyPressed() {
  if (key == ' ') paused = !paused;
  if (key == 'v' || key == 'V') solidMode = !solidMode;
  if (key == 's' || key == 'S') saveFrame("lsystem_sugar_branch_####.png");
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
