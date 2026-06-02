// Sugar^n Formula Sketch 02
// Fourier Sugar Threads
// SPACE pause/play, S save screenshot

float animFrame = 0;
boolean paused = false;
boolean solidMode = false;

void setup() {
  size(1000, 1000, P2D);
  smooth(8);
}

void draw() {
  background(255);
  if (!paused) animFrame++;

  float t = animFrame * 0.014;
  translate(width / 2, height / 2);
  if (solidMode) fill(252, 38);
  else noFill();
  stroke(0);
  strokeWeight(1.0);

  int curves = 42;
  int steps = 950;

  for (int c = 0; c < curves; c++) {
    float layer = map(c, 0, curves - 1, -1, 1);
    float scale = 0.72 + 0.26 * cos(layer * PI * 0.5);
    beginShape();
    for (int i = 0; i <= steps; i++) {
      float u = map(i, 0, steps, 0, TWO_PI);
      PVector p = fourierPoint(u, t, layer);
      vertex(p.x * scale, p.y * scale);
    }
    endShape();
  }

  drawOverlay(
    "02 Fourier Sugar Threads    mode=" + (solidMode ? "volume" : "line"),
    "x(u)=sum cos(freq[i]*u+phase[i])*amp[i], y(u)=sum sin(freq[i]*u-phase[i])*amp[i]",
    "integer frequency ratios close into sugar-thread loops; phases drift with t"
  );
}

PVector fourierPoint(float u, float t, float layer) {
  int[] fx = {2, 3, 5, 8, 13};
  int[] fy = {3, 4, 7, 9, 15};
  float[] amp = {190, 92, 58, 34, 20};
  float x = 0;
  float y = 0;
  for (int i = 0; i < fx.length; i++) {
    float ph = t * (0.35 + i * 0.13) + layer * (i + 1) * 0.42;
    x += cos(fx[i] * u + ph) * amp[i];
    y += sin(fy[i] * u - ph * 0.8) * amp[i];
  }
  float bend = sin(u * 6 + t * 2.0 + layer * 4.0) * 18;
  return new PVector(x + cos(u) * bend, y + sin(u) * bend);
}

void keyPressed() {
  if (key == ' ') paused = !paused;
  if (key == 'v' || key == 'V') solidMode = !solidMode;
  if (key == 's' || key == 'S') saveFrame("fourier_sugar_threads_####.png");
}

void drawOverlay(String title, String formula, String params) {
  resetMatrix();
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
