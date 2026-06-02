// Sugar^n Formula Sketch 07
// Gyroid Sugar Lattice
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

  float t = animFrame * 0.016;
  translate(width / 2, height * 0.55, 0);
  rotateX(-0.75 + sin(t * 0.31) * 0.2);
  rotateY(t * 0.28);

  stroke(0);
  strokeWeight(1.0);

  int count = 30;
  float span = 460;
  float step = span / count;
  float iso = 0.08 * sin(t * 0.7);

  if (solidMode) drawGyroidVoxels(count, span, step, iso, t);
  else drawGyroidLines(count, span, step, iso, t);

  drawOverlay(
    "07 Gyroid Sugar Lattice    mode=" + (solidMode ? "volume" : "line"),
    "G=sin(x)cos(y)+sin(y)cos(z)+sin(z)cos(x); draw where |G-iso|<epsilon",
    "periodic minimal-surface lattice sampled as black contour threads"
  );
}

void drawGyroidVoxels(int count, float span, float step, float iso, float t) {
  fill(252);
  for (int x = 0; x <= count; x += 2) {
    float xx = -span / 2 + x * step;
    for (int y = 0; y <= count; y += 2) {
      float yy = -span / 2 + y * step;
      for (int z = 0; z <= count; z += 2) {
        float zz = -span / 2 + z * step;
        float g = gyroid(xx, yy, zz, t);
        if (abs(g - iso) < 0.16) {
          pushMatrix();
          translate(xx, yy, zz);
          box(step * 0.82);
          popMatrix();
        }
      }
    }
  }
}

void drawGyroidLines(int count, float span, float step, float iso, float t) {
  noFill();
  for (int z = 0; z <= count; z += 2) {
    float zz = -span / 2 + z * step;
    for (int y = 0; y <= count; y++) {
      boolean drawing = false;
      for (int x = 0; x <= count; x++) {
        float xx = -span / 2 + x * step;
        float yy = -span / 2 + y * step;
        float g = gyroid(xx, yy, zz, t);
        if (abs(g - iso) < 0.13) {
          if (!drawing) {
            beginShape();
            drawing = true;
          }
          vertex(xx, yy, zz);
        } else if (drawing) {
          endShape();
          drawing = false;
        }
      }
      if (drawing) endShape();
    }
  }

  for (int x = 0; x <= count; x += 2) {
    float xx = -span / 2 + x * step;
    for (int y = 0; y <= count; y++) {
      boolean drawing = false;
      for (int z = 0; z <= count; z++) {
        float zz = -span / 2 + z * step;
        float yy = -span / 2 + y * step;
        float g = gyroid(xx, yy, zz, t);
        if (abs(g - iso) < 0.13) {
          if (!drawing) {
            beginShape();
            drawing = true;
          }
          vertex(xx, yy, zz);
        } else if (drawing) {
          endShape();
          drawing = false;
        }
      }
      if (drawing) endShape();
    }
  }
}

float gyroid(float x, float y, float z, float t) {
  float s = 0.035;
  float xx = x * s + t * 0.6;
  float yy = y * s + sin(t * 0.3);
  float zz = z * s + cos(t * 0.25);
  return sin(xx) * cos(yy) + sin(yy) * cos(zz) + sin(zz) * cos(xx);
}

void keyPressed() {
  if (key == ' ') paused = !paused;
  if (key == 'v' || key == 'V') solidMode = !solidMode;
  if (key == 's' || key == 'S') saveFrame("gyroid_sugar_lattice_####.png");
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
