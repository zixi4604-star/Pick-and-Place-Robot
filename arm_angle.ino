// Arm joint angle with a potentiometer encoder + LED brightness display
// The pot shaft is the joint: the arm turns by X degrees, the pot turns by X degrees.
//
// Wiring: pot left pin -> 5V, right pin -> GND, middle pin -> A1
//         D9 -> 220 ohm resistor -> LED long leg (anode); LED short leg (cathode) -> GND
//
// Serial output (9600 baud), one line every ~30 ms:
//   raw,angleDeg,ledPwm

// ---------- Pins ----------
const int POT_PIN = A1;
const int LED_PIN = 9;       // must be a PWM pin (marked with ~)

// ---------- Parameters ----------
const float POT_MAX_DEG = 270.0;   // electrical travel of the pot
const int   ADC_MAX     = 1023;    // 10-bit ADC

// ADC reading when the arm is at 0 degrees (horizontal). Adjust after mounting.
const int RAW_ZERO = 0;

// Set to true if turning the arm up makes the reading go DOWN
const bool REVERSE = false;

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
  pinMode(LED_PIN, OUTPUT);
}

void loop() {
  float raw = readAveraged(8);
  if (REVERSE) raw = ADC_MAX - raw;

  // ADC counts -> joint angle (0 to 270 degrees)
  float angleDeg = (raw - RAW_ZERO) * POT_MAX_DEG / ADC_MAX;
  angleDeg = constrain(angleDeg, 0.0, POT_MAX_DEG);

  // Bigger angle -> brighter LED (0 to 255)
  int ledPwm = (int)(angleDeg / POT_MAX_DEG * 255.0 + 0.5);
  analogWrite(LED_PIN, ledPwm);

  Serial.print(raw, 0);      Serial.print(",");
  Serial.print(angleDeg, 2); Serial.print(",");
  Serial.println(ledPwm);

  delay(20);
}
