// Sugar^n Formula Sketch 09
// Metaball Sugar Mass
// SPACE pause/play, V line/volume, S save screenshot

float animFrame = 0;
boolean paused = false;
boolean solidMode = true;
int LOW = 420;
PImage fieldImage;
int ballCount = 9;

void setup() {
  size(1000, 1000, P2D);
  smooth(4);
  fieldImage = createImage(LOW, LOW, RGB);
}

void draw() {
  background(255);
  if (!paused) animFrame++;

  float t = animFrame * 0.016;
  fieldImage.loadPixels();

  for (int y = 0; y < LOW; y++) {
    for (int x = 0; x < LOW; x++) {
      float px = map(x, 0, LOW - 1, -1, 1);
      float py = map(y, 0, LOW - 1, -1, 1);
      float f = sugarField(px, py, t);
      boolean ink = solidMode
        ? f > 1.0
        : abs(f - 1.0) < 0.035 || abs(f - 1.35) < 0.025;
      fieldImage.pixels[y * LOW + x] = ink ? color(0) : color(255);
    }
  }

  fieldImage.updatePixels();
  image(fieldImage, 0, 0, width, height);

  drawOverlay(
    "09 Metaball Sugar Mass    mode=" + (solidMode ? "volume" : "line"),
    "F(p,t)=sum_i radius_i^2 / distance(p, center_i(t))^2",
    "volume: F>1; line: contour(F=1). Blobs merge like melted sugar."
  );
}

float sugarField(float x, float y, float t) {
  float f = 0;
  for (int i = 0; i < ballCount; i++) {
    float a = TWO_PI * i / ballCount;
    float orbit = 0.42 + 0.16 * sin(t * 0.7 + i);
    float cx = cos(a + t * (0.18 + i * 0.01)) * orbit + sin(t * 0.9 + i * 1.7) * 0.11;
    float cy = sin(a - t * (0.15 + i * 0.015)) * orbit + cos(t * 0.8 + i * 1.3) * 0.11;
    float r = 0.16 + 0.055 * sin(t * 1.3 + i * 2.1);
    float dx = x - cx;
    float dy = y - cy;
    f += (r * r) / max(0.0008, dx * dx + dy * dy);
  }
  float core = 0.24 + 0.03 * sin(t);
  f += (core * core) / max(0.0008, x * x + y * y);
  return f;
}

void keyPressed() {
  if (key == ' ') paused = !paused;
  if (key == 'v' || key == 'V') solidMode = !solidMode;
  if (key == 's' || key == 'S') saveFrame("metaball_sugar_mass_####.png");
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
