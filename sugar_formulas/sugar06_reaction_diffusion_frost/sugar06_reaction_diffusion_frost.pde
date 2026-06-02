// Sugar^n Formula Sketch 06
// Reaction Diffusion Frost
// SPACE pause/play, S save screenshot

int W = 260;
int H = 260;
float[][] u = new float[W][H];
float[][] v = new float[W][H];
float[][] nu = new float[W][H];
float[][] nv = new float[W][H];
float animFrame = 0;
boolean paused = false;
boolean solidMode = true;

void setup() {
  size(1000, 1000, P2D);
  smooth(0);
  for (int x = 0; x < W; x++) {
    for (int y = 0; y < H; y++) {
      u[x][y] = 1;
      v[x][y] = 0;
    }
  }
  for (int i = 0; i < 34; i++) {
    int cx = int(random(30, W - 30));
    int cy = int(random(30, H - 30));
    seedPatch(cx, cy, int(random(4, 12)));
  }
}

void draw() {
  background(255);
  if (!paused) {
    animFrame++;
    for (int i = 0; i < 8; i++) stepRD(animFrame * 0.01);
  }

  loadPixels();
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      int gx = int(map(x, 0, width, 0, W - 1));
      int gy = int(map(y, 0, height, 0, H - 1));
      float val = v[gx][gy];
      boolean ink = solidMode
        ? val > 0.18 && val < 0.47
        : abs(val - 0.25) < 0.018 || abs(val - 0.42) < 0.018;
      pixels[y * width + x] = ink ? color(0) : color(255);
    }
  }
  updatePixels();

  drawOverlay(
    "06 Reaction Diffusion Frost    mode=" + (solidMode ? "volume" : "line"),
    "u'=Du*lap(u)-u*v*v+F*(1-u), v'=Dv*lap(v)+u*v*v-(F+K)*v",
    "Gray-Scott sugar-frost field; F and K breathe slowly with t"
  );
}

void stepRD(float t) {
  float Du = 1.0;
  float Dv = 0.48;
  float F = 0.034 + 0.006 * sin(t * 0.37);
  float K = 0.059 + 0.006 * cos(t * 0.29);

  for (int x = 1; x < W - 1; x++) {
    for (int y = 1; y < H - 1; y++) {
      float a = u[x][y];
      float b = v[x][y];
      float reaction = a * b * b;
      nu[x][y] = a + (Du * lap(u, x, y) - reaction + F * (1 - a));
      nv[x][y] = b + (Dv * lap(v, x, y) + reaction - (F + K) * b);
      nu[x][y] = constrain(nu[x][y], 0, 1);
      nv[x][y] = constrain(nv[x][y], 0, 1);
    }
  }

  for (int x = 1; x < W - 1; x++) {
    for (int y = 1; y < H - 1; y++) {
      u[x][y] = nu[x][y];
      v[x][y] = nv[x][y];
    }
  }
}

float lap(float[][] a, int x, int y) {
  return -a[x][y]
    + 0.2 * (a[x - 1][y] + a[x + 1][y] + a[x][y - 1] + a[x][y + 1])
    + 0.05 * (a[x - 1][y - 1] + a[x + 1][y - 1] + a[x - 1][y + 1] + a[x + 1][y + 1]);
}

void seedPatch(int cx, int cy, int r) {
  for (int x = max(1, cx - r); x < min(W - 1, cx + r); x++) {
    for (int y = max(1, cy - r); y < min(H - 1, cy + r); y++) {
      if (dist(x, y, cx, cy) < r) {
        v[x][y] = 1;
        u[x][y] = 0;
      }
    }
  }
}

void keyPressed() {
  if (key == ' ') paused = !paused;
  if (key == 'v' || key == 'V') solidMode = !solidMode;
  if (key == 's' || key == 'S') saveFrame("reaction_diffusion_frost_####.png");
}

void drawOverlay(String title, String formula, String params) {
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
}
