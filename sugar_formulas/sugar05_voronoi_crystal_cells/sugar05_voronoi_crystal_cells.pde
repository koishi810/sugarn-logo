// Sugar^n Formula Sketch 05
// Voronoi Crystal Cells
// SPACE pause/play, S save screenshot

float animFrame = 0;
boolean paused = false;
boolean solidMode = false;
int seedCount = 76;
PVector[] seeds = new PVector[seedCount];
int LOW = 360;
PImage field;

void setup() {
  size(1000, 1000, P2D);
  smooth(4);
  field = createImage(LOW, LOW, RGB);
  for (int i = 0; i < seedCount; i++) {
    float a = random(TWO_PI);
    float r = sqrt(random(1)) * 390;
    seeds[i] = new PVector(cos(a) * r, sin(a) * r, random(1000));
  }
}

void draw() {
  background(255);
  if (!paused) animFrame++;

  float t = animFrame * 0.015;
  field.loadPixels();
  float cx = LOW * 0.5;
  float cy = LOW * 0.54;
  float scaleToCanvas = width / float(LOW);

  for (int y = 0; y < LOW; y++) {
    for (int x = 0; x < LOW; x++) {
      float px = (x - cx) * scaleToCanvas;
      float py = (y - cy) * scaleToCanvas;
      float r = sqrt(px * px + py * py);
      if (r > 390) {
        field.pixels[y * LOW + x] = color(255);
        continue;
      }
      float d1 = 1e9;
      float d2 = 1e9;
      int nearest = 0;
      for (int i = 0; i < seedCount; i++) {
        PVector s = driftedSeed(i, t);
        float d = dist(px, py, s.x, s.y);
        if (d < d1) {
          d2 = d1;
          d1 = d;
          nearest = i;
        } else if (d < d2) {
          d2 = d;
        }
      }
      float edge = d2 - d1;
      float ring = abs(sin(r * 0.055 + t * 2.0));
      boolean cellFill = ((nearest * 37 + int(t * 10)) % 5) < 2;
      boolean ink = solidMode
        ? cellFill || edge < 4.8
        : edge < 5.2 || (edge < 11.0 && ring > 0.91);
      field.pixels[y * LOW + x] = ink ? color(0) : color(255);
    }
  }
  field.updatePixels();
  image(field, 0, 0, width, height);

  drawOverlay(
    "05 Voronoi Crystal Cells    mode=" + (solidMode ? "volume" : "line"),
    "cell(p)=argmin_i distance(p, seed_i); edge(p)=d2(p)-d1(p)",
    "draw black where edge<epsilon; seed_i(t)=seed_i+sin/cos drift"
  );
}

PVector driftedSeed(int i, float t) {
  PVector s = seeds[i];
  float dx = sin(t * 0.7 + s.z) * 25 + cos(t * 0.33 + i) * 16;
  float dy = cos(t * 0.61 + s.z * 1.7) * 25 + sin(t * 0.29 + i * 2.0) * 16;
  return new PVector(s.x + dx, s.y + dy);
}

void keyPressed() {
  if (key == ' ') paused = !paused;
  if (key == 'v' || key == 'V') solidMode = !solidMode;
  if (key == 's' || key == 'S') saveFrame("voronoi_crystal_cells_####.png");
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
