//PRESS 1…金平糖のような形、PRESS 2…珊瑚や綿毛のような形
//PRESS スペースキー…一時停止/再生開始、PRESS S…スクリーンショット保存
//==========================================
// Line-only Morphing Geometric Object
// Processing (P3D)
// 1 = 球モーフ
// 2 = 枝分かれ珊瑚
// S = スクリーンショット保存
// SPACE = 一時停止 / 再開
// ==========================================

//速度調整、数字が大きいほどゆっくり
float loopDuration = 350.0;
int mode = 1;

// 時間管理
float animFrame = 0;
boolean paused = false;

void setup() {
  size(1000, 1000, P3D);
  smooth(8);
}

void draw() {
  background(255);

  // 再生中だけ時間を進める
  if (!paused) {
    animFrame++;
  }

  translate(width/2, height/2, 0);

  float phase = (animFrame % loopDuration) / loopDuration;
  float t = TWO_PI * phase;

  rotateX(sin(t) * 0.6);
  rotateY(t * 2);
  rotateZ(cos(t) * 0.4);

  noFill();
  stroke(0);
  strokeWeight(1);

  if (mode == 1) {
    drawMorphSphere(240, t);
  } else if (mode == 2) {
    drawCoral(0, 0, 0, 180, 5, t);
  }
}

// ----------------------------
// モーフ球
// ----------------------------
void drawMorphSphere(float r, float t) {

  int latSteps = 15;
  int lonSteps = 30;

  for (int i = 0; i < latSteps; i++) {

    float theta1 = map(i, 0, latSteps, -HALF_PI, HALF_PI);
    float theta2 = map(i+1, 0, latSteps, -HALF_PI, HALF_PI);

    beginShape(LINES);

    for (int j = 0; j <= lonSteps; j++) {

      float phi = map(j, 0, lonSteps, 0, TWO_PI);

      drawVertexMorph(theta1, phi, r, t);
      drawVertexMorph(theta2, phi, r, t);
    }

    endShape();
  }
}

void drawVertexMorph(float theta, float phi, float r, float t) {

  float morphA = 0.5 + 0.5*sin(t);
  float morphB = 0.5 + 0.5*sin(t + PI/2);
  float morphC = 0.5 + 0.5*sin(t + PI);
  float morphD = 0.5 + 0.5*sin(t + PI*1.5);

  float spike =
    sin(phi*8 + t*4) *
    cos(theta*6 + t*3);

  float wave =
    sin(phi*3 - t*5) *
    sin(theta*4 + t*2);

  float branch =
    sin(phi*14 + theta*10 + t*6);

  float ribbon =
    cos(phi*2 + t*4) *
    sin(theta*8);

  float deform =
      spike * morphA * 0.35
    + wave * morphB * 0.25
    + branch * morphC * 0.18
    + ribbon * morphD * 0.22;

  float rr = r * (1 + deform);

  float x = rr * cos(theta) * cos(phi);
  float y = rr * sin(theta);
  float z = rr * cos(theta) * sin(phi);

  vertex(x, y, z);
}

// ----------------------------
// 成長する枝分かれ珊瑚
// ----------------------------
void drawCoral(float x, float y, float z, float len, int depth, float t) {

  if (depth <= 0) return;

  pushMatrix();
  translate(x, y, z);

  int branches = 4;

  float growth = 0.5 + 0.5 * sin(t);

  growth = constrain(
    growth - (5 - depth) * 0.12,
    0,
    1
  );

  float currentLen = len * growth;

  if (currentLen < 4) {
    popMatrix();
    return;
  }

  for (int i = 0; i < branches; i++) {

    float angleA =
      TWO_PI / branches * i
      + sin(t * 2 + depth) * 0.35;

    float angleB =
      sin(t * 3 + i + depth) * 0.7;

    float nx = cos(angleA) * cos(angleB) * currentLen;
    float ny = sin(angleB) * currentLen;
    float nz = sin(angleA) * cos(angleB) * currentLen;

    beginShape();

    for (int j = 0; j <= 12; j++) {

      float p = j / 12.0;

      float bend =
        sin(p * PI + t * 4 + i) *
        currentLen * 0.18;

      float px = nx * p + cos(angleA * 3) * bend;
      float py = ny * p + sin(t + i) * bend;
      float pz = nz * p + sin(angleA * 3) * bend;

      vertex(px, py, pz);
    }

    endShape();

    if (growth > 0.55) {
      pushMatrix();

      translate(nx, ny, nz);
      rotateY(angleA);
      rotateX(angleB);

      drawCoral(
        0, 0, 0,
        len * 0.62,
        depth - 1,
        t
      );

      popMatrix();
    }
  }

  popMatrix();
}

// ----------------------------
// キー操作
// ----------------------------
void keyPressed() {

  if (key == '1') mode = 1;
  if (key == '2') mode = 2;

  // スクリーンショット保存
  if (key == 's' || key == 'S') {
    saveFrame("capture-####.png");
    println("saved");
  }

  // 一時停止 / 再開
  if (key == ' ') {
    paused = !paused;
    println(paused ? "paused" : "playing");
  }
}
