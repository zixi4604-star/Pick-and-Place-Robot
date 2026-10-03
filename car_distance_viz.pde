// Processing visualiser: a little car drives left to right, distance shown on top.
// Reads lines "raw,potDeg,wheelDeg,distanceCm" from the Arduino.
// If no serial port is found it runs a demo animation so you can test the UI.

import processing.serial.*;

// ---------- Must match the Arduino sketch ----------
final float WHEEL_D_CM    = 8.0;
final int   WHEEL_TEETH   = 15;
final int   POT_TEETH     = 45;
final float POT_MAX_DEG   = 270.0;
final int   BAUD          = 9600;
final int   PORT_INDEX    = 2;     // index in the printed port list; change if needed

final float GEAR_RATIO = (float) POT_TEETH / WHEEL_TEETH;                  // 3
final float MAX_CM     = POT_MAX_DEG * GEAR_RATIO / 360.0 * PI * WHEEL_D_CM; // about 56.5 cm

// ---------- Layout ----------
final float TRACK_X0 = 130;
final float TRACK_X1 = 770;
final float GROUND_Y = 300;
final float WHEEL_R_PX = 20;   // drawn wheel radius (cartoon size)

Serial port;
boolean demo = false;

float raw = 0, potDeg = 0, wheelDeg = 0, distCm = 0;
float shownDist = 0;     // smoothed distance used for drawing
float lastShown = 0;
float wheelAngle = 0;    // drawn wheel rotation in radians

void setup() {
  size(900, 420);
  String[] ports = Serial.list();
  println(ports);
  try {
    if (ports.length > PORT_INDEX) {
      port = new Serial(this, ports[PORT_INDEX], BAUD);
      port.bufferUntil('\n');
    } else {
      demo = true;
    }
  } catch (Exception e) {
    println("Could not open serial port: " + e);
    demo = true;
  }
}

void draw() {
  background(248, 246, 240);
  if (demo) simulate();

  float target = constrain(distCm, 0, MAX_CM);
  shownDist = lerp(shownDist, target, 0.2);

  float pxPerCm = (TRACK_X1 - TRACK_X0) / MAX_CM;
  float carX = TRACK_X0 + shownDist * pxPerCm;

  // rolling without slipping: wheel angle = pixels moved / drawn radius
  wheelAngle += (shownDist - lastShown) * pxPerCm / WHEEL_R_PX;
  lastShown = shownDist;

  drawHeader();
  drawTrack(pxPerCm, carX);
  drawCar(carX);
}

void simulate() {
  distCm   = (sin(frameCount * 0.02) + 1) / 2 * MAX_CM;
  wheelDeg = distCm / (PI * WHEEL_D_CM) * 360.0;
  potDeg   = wheelDeg / GEAR_RATIO;
  raw      = potDeg / POT_MAX_DEG * 1023;
}

void drawHeader() {
  textAlign(CENTER, CENTER);
  fill(60);
  textSize(16);
  text("DISTANCE TRAVELLED", width / 2, 28);

  textSize(60);
  fill(30);
  text(nf(shownDist, 0, 2) + " cm", width / 2, 80);

  textSize(14);
  fill(120);
  text("pot raw " + nf(int(raw), 0) + "     pot " + nf(potDeg, 0, 1)
       + "\u00B0     wheel " + nf(wheelDeg, 0, 1) + "\u00B0", width / 2, 125);

  if (shownDist >= MAX_CM - 0.5) {
    fill(200, 50, 50);
    text("Potentiometer limit reached - the wheel cannot be measured further", width / 2, 152);
  }
  if (demo) {
    fill(150);
    text("DEMO MODE (no Arduino found)", width / 2, 400);
  }
}

void drawTrack(float pxPerCm, float carX) {
  noStroke();
  fill(225);
  rect(TRACK_X0 - 40, GROUND_Y, TRACK_X1 - TRACK_X0 + 80, 12, 6);
  fill(80, 160, 220);
  rect(TRACK_X0, GROUND_Y, max(carX - TRACK_X0, 1), 12, 6);   // travelled part

  stroke(130);
  strokeWeight(1);
  fill(100);
  textSize(12);
  textAlign(CENTER, TOP);
  for (int cm = 0; cm <= MAX_CM; cm += 10) {
    float x = TRACK_X0 + cm * pxPerCm;
    line(x, GROUND_Y + 12, x, GROUND_Y + 20);
    text(cm, x, GROUND_Y + 24);
  }
  noStroke();
  textSize(13);
  text("START", TRACK_X0, GROUND_Y + 52);
  text("MAX " + nf(MAX_CM, 0, 1) + " cm", TRACK_X1, GROUND_Y + 52);
}

void drawCar(float carX) {
  pushMatrix();
  translate(carX, GROUND_Y);
  noStroke();

  drawWheel(-38, -WHEEL_R_PX);
  drawWheel(38, -WHEEL_R_PX);

  fill(235, 90, 70);
  rect(-62, -66, 124, 38, 12);          // body
  fill(245, 130, 105);
  rect(-30, -92, 62, 32, 10);           // cabin
  fill(200, 230, 245);
  rect(-22, -86, 20, 20, 4);            // windows
  rect(2, -86, 20, 20, 4);
  fill(255, 215, 80);
  ellipse(56, -50, 9, 9);               // headlight
  popMatrix();
}

void drawWheel(float cx, float cy) {
  pushMatrix();
  translate(cx, cy);
  rotate(wheelAngle);
  noStroke();
  fill(50);
  ellipse(0, 0, WHEEL_R_PX * 2, WHEEL_R_PX * 2);
  stroke(190);
  strokeWeight(2);
  for (int i = 0; i < 4; i++) {
    float a = i * HALF_PI;
    line(0, 0, cos(a) * (WHEEL_R_PX - 4), sin(a) * (WHEEL_R_PX - 4));
  }
  noStroke();
  fill(190);
  ellipse(0, 0, 6, 6);
  popMatrix();
}

void serialEvent(Serial p) {
  String s = p.readStringUntil('\n');
  if (s == null) return;
  String[] v = split(trim(s), ',');
  if (v.length == 4) {
    raw      = float(v[0]);
    potDeg   = float(v[1]);
    wheelDeg = float(v[2]);
    distCm   = float(v[3]);
  }
}
