// Sugar^n Formula Sketch 04
// Parametric Sugar Shell
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

  float t = animFrame * 0.016;
  translate(width / 2, height * 0.55, 0);
  rotateX(-0.9 + sin(t * 0.24) * 0.18);
  rotateY(t * 0.24);

  if (solidMode) fill(252);
  else noFill();
  stroke(0);
  strokeWeight(0.75);

  int uSteps = 150;
  int vSteps = 58;

  for (int j = 0; j < vSteps; j++) {
    float v1 = map(j, 0, vSteps, -1.0, 1.0);
    float v2 = map(j + 1, 0, vSteps, -1.0, 1.0);
    beginShape(QUAD_STRIP);
    for (int i = 0; i <= uSteps; i++) {
      float u = map(i, 0, uSteps, 0, TWO_PI);
      PVector p1 = shellPoint(u, v1, t);
      PVector p2 = shellPoint(u, v2, t);
      vertex(p1.x, p1.y, p1.z);
      vertex(p2.x, p2.y, p2.z);
    }
    endShape();
  }

  drawOverlay(
    "04 Parametric Sugar Shell    mode=" + (solidMode ? "volume" : "line"),
    "x=R(u,v,t)cos(u+twist*v), y=R(u,v,t)sin(u+twist*v), z=220v+42sin(5u+t)",
    "R=150+55sin(7u+t)+38cos(4v*pi-t)+22sin(11u+3v+t)"
  );
}

PVector shellPoint(float u, float v, float t) {
  float twist = 1.35 + 0.35 * sin(t * 0.3);
  float r = 150
    + 55 * sin(7 * u + t)
    + 38 * cos(4 * v * PI - t * 1.2)
    + 22 * sin(11 * u + 3 * v + t * 0.7);
  float taper = 0.72 + 0.28 * cos(v * HALF_PI);
  float a = u + twist * v;
  float x = r * taper * cos(a);
  float y = r * taper * sin(a);
  float z = 220 * v + 42 * sin(5 * u + t);
  return new PVector(x, y, z);
}

void keyPressed() {
  if (key == ' ') paused = !paused;
  if (key == 'v' || key == 'V') solidMode = !solidMode;
  if (key == 's' || key == 'S') saveFrame("parametric_sugar_shell_####.png");
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
