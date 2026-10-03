// Wheel odometry with a potentiometer encoder
// Wheel (15 teeth) drives the pot gear (45 teeth), so the pot turns 1/3 as much as the wheel.
//
// Wiring: pot left pin -> 5V, right pin -> GND, middle pin -> A0
//         optional zero button between D2 and GND
//
// Serial output (9600 baud), one line every ~35 ms:
//   raw,potDeg,wheelDeg,distanceCm

// ---------- Pins ----------
const int POT_PIN         = A0;
const int ZERO_BUTTON_PIN = 2;      // press to set the current position as 0 cm

// ---------- Mechanical parameters (edit if your build changes) ----------
const float WHEEL_DIAMETER_CM = 8.0;
const int   WHEEL_GEAR_TEETH  = 15;   // gear fixed to the wheel axle
const int   POT_GEAR_TEETH    = 45;   // gear fixed to the potentiometer shaft
const float POT_MAX_DEG       = 270.0; // electrical travel of the pot
const int   ADC_MAX           = 1023;  // 10-bit ADC

// +1 if turning the wheel forward increases the reading, -1 if it decreases it
const int DIRECTION = 1;

// ---------- Derived values ----------
// Pot gear is bigger, so the wheel turns 45/15 = 3 times for every pot turn
const float GEAR_RATIO    = (float)POT_GEAR_TEETH / WHEEL_GEAR_TEETH;
const float WHEEL_CIRC_CM = PI * WHEEL_DIAMETER_CM;   // about 25.13 cm per wheel turn

float rawZero = 0;   // ADC reading at the 0 cm position

float readAveraged(int samples) {
  long sum = 0;
  for (int i = 0; i < samples; i++) {
    sum += analogRead(POT_PIN);
    delay(2);
  }
  return (float)sum / samples;
}

void setup() {
  Serial.begin(9600);
  pinMode(ZERO_BUTTON_PIN, INPUT_PULLUP);
  delay(300);
  rawZero = readAveraged(32);   // current position at power-up = 0 cm
}

void loop() {
  // Re-zero when the button is pressed
  if (digitalRead(ZERO_BUTTON_PIN) == LOW) {
    delay(30);   // simple debounce
    if (digitalRead(ZERO_BUTTON_PIN) == LOW) {
      rawZero = readAveraged(32);
      while (digitalRead(ZERO_BUTTON_PIN) == LOW) { }   // wait for release
    }
  }

  float raw = readAveraged(8);

  // ADC counts -> pot angle -> wheel angle -> distance
  float potDeg   = DIRECTION * (raw - rawZero) * POT_MAX_DEG / ADC_MAX;
  float wheelDeg = potDeg * GEAR_RATIO;
  float distCm   = wheelDeg / 360.0 * WHEEL_CIRC_CM;

  Serial.print(raw, 0);      Serial.print(",");
  Serial.print(potDeg, 2);   Serial.print(",");
  Serial.print(wheelDeg, 2); Serial.print(",");
  Serial.println(distCm, 2);

  delay(20);
}
