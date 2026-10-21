// ============================================================
// Module 2 - Serial Sensor Output
// Sends sensor values to Processing as CSV:
//
// joystickX,joystickY,potentiometer,button
//
// Example:
// 2048,1995,3100,1
// ============================================================

// Joystick
const int JOYSTICK_X_PIN = 39;
const int JOYSTICK_Y_PIN = 32;

// Potentiometer
const int POT_PIN = 36;

// Separate pushbutton
const int BUTTON_PIN = 2;

void setup() {
  Serial.begin(115200);

  // Button connects GPIO → GND
  // Not pressed = HIGH (1)
  // Pressed     = LOW  (0)
  pinMode(BUTTON_PIN, INPUT_PULLUP);
}

void loop() {

  // Read sensors
  int joystickX = analogRead(JOYSTICK_X_PIN);
  int joystickY = analogRead(JOYSTICK_Y_PIN);
  int potValue = analogRead(POT_PIN);
  int buttonState = digitalRead(BUTTON_PIN);

  // Send one CSV line:
  // X,Y,POT,BUTTON
  Serial.print(joystickX);
  Serial.print(",");

  Serial.print(joystickY);
  Serial.print(",");

  Serial.print(potValue);
  Serial.print(",");

  Serial.println(buttonState);

  // ~50 readings per second
  delay(20);
}
