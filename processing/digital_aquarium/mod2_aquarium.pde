import processing.serial.*;

// ============================================================
// MODULE 2 - DIGITAL AQUARIUM
//
// Joystick      -> moves glowing food / attractor
// Potentiometer -> calm <-> turbulent water
// Button        -> creates expanding water shockwave
// ============================================================


// ============================================================
// SERIAL
// ============================================================

Serial myPort;

int joystickX = 2048;
int joystickY = 2048;
int potValue = 0;
int buttonState = 1;
int previousButtonState = 1;


// ============================================================
// ENVIRONMENT
// ============================================================

// 0.0 = calm
// 1.0 = turbulent
float chaos = 0;


// ============================================================
// ATTRACTOR
// ============================================================

float attractorX;
float attractorY;

float targetX;
float targetY;


// ============================================================
// FISH
// ============================================================

final int NUM_FISH = 75;

Fish[] fish = new Fish[NUM_FISH];


// ============================================================
// BUBBLES
// ============================================================

final int NUM_BUBBLES = 45;

Bubble[] bubbles = new Bubble[NUM_BUBBLES];


// ============================================================
// RIPPLE
// ============================================================

boolean rippleActive = false;

float rippleX;
float rippleY;

float rippleRadius = 0;

// Strength is captured when the ripple begins
float rippleStrength = 1;

// Unique number for each ripple
int rippleID = 0;


// ============================================================
// SETUP
// ============================================================

void setup() {

  size(900, 600);

  smooth(8);


  // ----------------------------------------------------------
  // ATTRACTOR
  // ----------------------------------------------------------

  attractorX = width / 2;
  attractorY = height / 2;

  targetX = attractorX;
  targetY = attractorY;


  // ----------------------------------------------------------
  // CREATE FISH
  // ----------------------------------------------------------

  for (int i = 0; i < NUM_FISH; i++) {

    fish[i] = new Fish(
      random(width),
      random(height)
    );
  }


  // ----------------------------------------------------------
  // CREATE BUBBLES
  // ----------------------------------------------------------

  for (int i = 0; i < NUM_BUBBLES; i++) {

    bubbles[i] = new Bubble();
  }


  // ----------------------------------------------------------
  // SERIAL
  // ----------------------------------------------------------

  printArray(Serial.list());

  myPort = new Serial(
    this,
    "/dev/cu.usbserial-5C491317361",
    115200
  );

  myPort.bufferUntil('\n');


  // Initial ocean background
  background(5, 25, 55);
}


// ============================================================
// MAIN DRAW LOOP
// ============================================================

void draw() {

  updateEnvironment();

  drawWater();

  updateAttractor();

  drawCurrentLines();

  updateBubbles();

  updateFish();

  drawRipple();

  drawAttractor();

  drawInterface();
}


// ============================================================
// UPDATE ENVIRONMENT
// ============================================================

void updateEnvironment() {

  chaos = map(
    potValue,
    0,
    4095,
    0,
    1
  );

  chaos = constrain(
    chaos,
    0,
    1
  );
}


// ============================================================
// WATER BACKGROUND
// ============================================================

void drawWater() {

  // ----------------------------------------------------------
  // IMPORTANT:
  //
  // We do NOT completely erase the previous frame.
  //
  // Instead, we draw a translucent rectangle over it.
  //
  // This produces subtle motion trails that make the fish
  // movement feel much more fluid.
  // ----------------------------------------------------------

  float r = lerp(3, 24, chaos);
  float g = lerp(28, 12, chaos);
  float b = lerp(65, 85, chaos);


  // Calm water holds trails longer.
  // Turbulent water clears slightly faster.

  float trailAlpha =
    lerp(
      28,
      48,
      chaos
    );


  noStroke();

  fill(
    r,
    g,
    b,
    trailAlpha
  );

  rect(
    0,
    0,
    width,
    height
  );


  // ----------------------------------------------------------
  // SUBTLE LIGHT FROM ABOVE
  // ----------------------------------------------------------

  for (int y = 0; y < height; y += 30) {

    float depth =
      map(
        y,
        0,
        height,
        1,
        0
      );


    fill(
      30,
      130,
      170,
      depth * 4
    );

    rect(
      0,
      y,
      width,
      30
    );
  }
}


// ============================================================
// WATER CURRENT VISUALS
// ============================================================

void drawCurrentLines() {

  // These faint curved lines make the water feel alive.

  int numberOfCurrents =
    int(
      lerp(
        4,
        10,
        chaos
      )
    );


  for (int i = 0; i < numberOfCurrents; i++) {

    noFill();

    strokeWeight(
      lerp(
        1,
        2.5,
        chaos
      )
    );


    stroke(
      80,
      180,
      220,
      lerp(
        12,
        32,
        chaos
      )
    );


    beginShape();


    for (int x = -50; x <= width + 50; x += 20) {

      float waveSpeed =
        lerp(
          0.008,
          0.035,
          chaos
        );


      float amplitude =
        lerp(
          8,
          35,
          chaos
        );


      float y =
        (height / (float)(numberOfCurrents + 1))
        * (i + 1);


      y +=
        sin(
          x * 0.012
          + frameCount * waveSpeed
          + i
        )
        * amplitude;


      vertex(
        x,
        y
      );
    }


    endShape();
  }
}


// ============================================================
// ATTRACTOR POSITION
// ============================================================

void updateAttractor() {

  targetX = map(
    joystickX,
    0,
    4095,
    45,
    width - 45
  );


  targetY = map(
    joystickY,
    0,
    4095,
    45,
    height - 45
  );


  // Smooth joystick movement.
  //
  // Notice that we DON'T add random jitter anymore.
  //
  // Even in turbulent water, the attractor itself remains
  // precise and meaningful.

  attractorX =
    lerp(
      attractorX,
      targetX,
      0.18
    );


  attractorY =
    lerp(
      attractorY,
      targetY,
      0.18
    );
}


// ============================================================
// UPDATE BUBBLES
// ============================================================

void updateBubbles() {

  for (int i = 0; i < NUM_BUBBLES; i++) {

    bubbles[i].update(chaos);

    bubbles[i].display(chaos);
  }
}


// ============================================================
// UPDATE FISH
// ============================================================

void updateFish() {

  for (int i = 0; i < NUM_FISH; i++) {

    // --------------------------------------------------------
    // 1. SCHOOLING
    // --------------------------------------------------------

    fish[i].flock(
      fish,
      chaos
    );


    // --------------------------------------------------------
    // 2. FOOD ATTRACTION
    //
    // IMPORTANT:
    // Attraction gets STRONGER as chaos increases.
    //
    // This ensures the joystick is still meaningful even
    // during TURBULENT mode.
    // --------------------------------------------------------

    fish[i].seekAttractor(
      attractorX,
      attractorY,
      chaos
    );


    // --------------------------------------------------------
    // 3. WATER CURRENT
    // --------------------------------------------------------

    fish[i].applyCurrent(
      chaos
    );


    // --------------------------------------------------------
    // 4. NATURAL WANDERING
    // --------------------------------------------------------

    fish[i].wander(
      chaos
    );


    // --------------------------------------------------------
    // 5. RIPPLE
    // --------------------------------------------------------

    if (rippleActive) {

      fish[i].reactToRipple(
        rippleX,
        rippleY,
        rippleRadius,
        rippleStrength,
        rippleID,
        chaos
      );
    }


    // --------------------------------------------------------
    // UPDATE + DRAW
    // --------------------------------------------------------

    fish[i].update(
      chaos
    );

    fish[i].edges();

    fish[i].display(
      chaos
    );
  }
}


// ============================================================
// ATTRACTOR VISUAL
// ============================================================

void drawAttractor() {

  // Slowly pulse the food source.

  float pulse =
    sin(
      frameCount * 0.08
    );


  float glowSize =
    65 + pulse * 8;


  noStroke();


  // Large outer glow

  fill(
    90,
    225,
    255,
    22
  );

  ellipse(
    attractorX,
    attractorY,
    glowSize * 1.7,
    glowSize * 1.7
  );


  // Medium glow

  fill(
    100,
    235,
    255,
    55
  );

  ellipse(
    attractorX,
    attractorY,
    glowSize,
    glowSize
  );


  // Inner glow

  fill(
    160,
    245,
    255,
    130
  );

  ellipse(
    attractorX,
    attractorY,
    30,
    30
  );


  // Core

  fill(
    245,
    255,
    255
  );

  ellipse(
    attractorX,
    attractorY,
    11,
    11
  );
}


// ============================================================
// CREATE RIPPLE
// ============================================================

void triggerRipple() {

  rippleActive = true;

  rippleRadius = 0;

  rippleX = attractorX;
  rippleY = attractorY;

  // MUCH stronger than before.
  //
  // Calm       ≈ 4.5
  // Active     ≈ 7.5
  // Turbulent  ≈ 10.5
  rippleStrength =
    lerp(
      4.5,
      10.5,
      chaos
    );

  rippleID++;
}

// ============================================================
// DRAW RIPPLE
// ============================================================

void drawRipple() {

  if (!rippleActive) {
    return;
  }


  // Ripple travels faster in turbulent water.

  float rippleSpeed =
    lerp(
      6,
      11,
      chaos
    );


  rippleRadius +=
    rippleSpeed;


  // Fade as the wave travels outward.

  float fade =
    map(
      rippleRadius,
      0,
      width * 0.8,
      220,
      0
    );

  fade =
    constrain(
      fade,
      0,
      220
    );


  noFill();


  // ----------------------------------------------------------
  // MAIN WAVE FRONT
  // ----------------------------------------------------------

  strokeWeight(
    lerp(
      2,
      4,
      chaos
    )
  );

  stroke(
    170,
    240,
    255,
    fade
  );

  ellipse(
    rippleX,
    rippleY,
    rippleRadius * 2,
    rippleRadius * 2
  );


  // ----------------------------------------------------------
  // SECONDARY RIPPLE
  // ----------------------------------------------------------

  if (rippleRadius > 22) {

    strokeWeight(2);

    stroke(
      120,
      210,
      255,
      fade * 0.60
    );

    ellipse(
      rippleX,
      rippleY,
      (rippleRadius - 22) * 2,
      (rippleRadius - 22) * 2
    );
  }


  // ----------------------------------------------------------
  // THIRD RIPPLE
  // ----------------------------------------------------------

  if (rippleRadius > 45) {

    strokeWeight(1);

    stroke(
      100,
      190,
      240,
      fade * 0.35
    );

    ellipse(
      rippleX,
      rippleY,
      (rippleRadius - 45) * 2,
      (rippleRadius - 45) * 2
    );
  }


  // ----------------------------------------------------------
  // SMALL CENTER FLASH
  // ----------------------------------------------------------

  if (rippleRadius < 80) {

    float flashAlpha =
      map(
        rippleRadius,
        0,
        80,
        100,
        0
      );


    noStroke();

    fill(
      170,
      240,
      255,
      flashAlpha
    );

    ellipse(
      rippleX,
      rippleY,
      35,
      35
    );
  }


  // Stop once wave has left screen.

  if (rippleRadius > width * 0.85) {

    rippleActive = false;
  }
}


// ============================================================
// INTERFACE
// ============================================================

void drawInterface() {

  fill(
    255,
    220
  );

  textSize(15);


  text(
    "Environment Energy: "
    + int(chaos * 100)
    + "%",
    20,
    28
  );


  if (chaos < 0.33) {

    text(
      "CALM",
      20,
      49
    );

  } else if (chaos < 0.66) {

    text(
      "ACTIVE",
      20,
      49
    );

  } else {

    text(
      "TURBULENT",
      20,
      49
    );
  }
}


// ============================================================
// SERIAL INPUT
// ============================================================

void serialEvent(Serial port) {

  String data =
    port.readStringUntil('\n');


  if (data != null) {

    data =
      trim(data);


    String[] values =
      split(
        data,
        ','
      );


    if (values.length == 4) {

      joystickX =
        int(values[0]);

      joystickY =
        int(values[1]);

      potValue =
        int(values[2]);

      buttonState =
        int(values[3]);


      // Button transition:
      //
      // 1 -> 0
      //
      // means NEW press.

      if (
        buttonState == 0
        &&
        previousButtonState == 1
      ) {

        triggerRipple();
      }


      previousButtonState =
        buttonState;
    }
  }
}


// ============================================================
// FISH CLASS
// ============================================================

class Fish {

  PVector position;
  PVector velocity;
  PVector acceleration;


  float baseSize;

  float depth;

  float noiseOffset;

  float colorOffset;


  // Used so one ripple hits each fish only once.

  int lastRippleID =
    -1;
  // How long this fish remains in a "startled" state
  // after being hit by a ripple
  int ripplePanicFrames = 0;

  // ----------------------------------------------------------
  // CONSTRUCTOR
  // ----------------------------------------------------------

  Fish(
    float x,
    float y
  ) {

    position =
      new PVector(
        x,
        y
      );


    velocity =
      PVector.random2D();


    velocity.mult(
      random(
        0.5,
        1.5
      )
    );


    acceleration =
      new PVector(
        0,
        0
      );


    // --------------------------------------------------------
    // DEPTH
    //
    // Far fish:
    //   smaller
    //   dimmer
    //
    // Near fish:
    //   larger
    //   brighter
    // --------------------------------------------------------

    depth =
      random(
        0.55,
        1.25
      );


    baseSize =
      random(
        7,
        12
      )
      * depth;


    noiseOffset =
      random(
        1000
      );


    colorOffset =
      random(
        -25,
        25
      );
  }


  // ==========================================================
  // APPLY FORCE
  // ==========================================================

  void applyForce(
    PVector force
  ) {

    acceleration.add(
      force
    );
  }


  // ==========================================================
  // ATTRACTOR
  // ==========================================================

  void seekAttractor(
    float x,
    float y,
    float chaos
  ) {

    PVector target =
      new PVector(
        x,
        y
      );


    PVector desired =
      PVector.sub(
        target,
        position
      );


    float d =
      desired.mag();


    if (d < 1) {
      return;
    }


    desired.normalize();


    // --------------------------------------------------------
    // IMPORTANT CHANGE:
    //
    // Fish have a HIGHER desired speed toward food when
    // the water becomes turbulent.
    //
    // Turbulence makes their path messy, but they still
    // clearly pursue the attractor.
    // --------------------------------------------------------

    float desiredSpeed =
      lerp(
        2.2,
        5.3,
        chaos
      );
      
    // After a ripple, fish temporarily stop caring as much
    // about the food source.
    //
    // This gives them time to visibly scatter before regrouping.
    if (ripplePanicFrames > 0) {
       desiredSpeed *= 0.12;
    }


    // Slow down near food.

    if (d < 80) {

      desiredSpeed *=
        map(
          d,
          0,
          80,
          0.15,
          1
        );
    }


    desired.mult(
      desiredSpeed
    );


    // Steering =
    // where we WANT to go
    // minus
    // where we ARE going

    PVector steering =
      PVector.sub(
        desired,
        velocity
      );


    // Stronger steering in turbulence.

    float maxSteering =
      lerp(
        0.055,
        0.15,
        chaos
      );
      
    if (ripplePanicFrames > 0) {
      maxSteering *= 0.15;
    }


    steering.limit(
      maxSteering
    );


    applyForce(
      steering
    );
  }


  // ==========================================================
  // FLOCKING
  // ==========================================================

  void flock(
    Fish[] allFish,
    float chaos
  ) {

    PVector separation =
      separate(
        allFish
      );


    PVector alignment =
      align(
        allFish
      );


    PVector cohesion =
      cohesion(
        allFish
      );


    // --------------------------------------------------------
    // CALM:
    // strong schooling
    //
    // TURBULENT:
    // still schooling, but less organized
    // --------------------------------------------------------

    float schoolStrength =
      lerp(
        1.0,
        0.42,
        chaos
      );


    separation.mult(
      1.45
    );


    alignment.mult(
      schoolStrength
    );


    cohesion.mult(
      schoolStrength * 0.85
    );


    applyForce(
      separation
    );

    applyForce(
      alignment
    );

    applyForce(
      cohesion
    );
  }


  // ==========================================================
  // SEPARATION
  // ==========================================================

  PVector separate(
    Fish[] allFish
  ) {

    float desiredDistance =
      25 * depth;


    PVector steer =
      new PVector();


    int count = 0;


    for (Fish other : allFish) {

      if (other == this) {
        continue;
      }


      float d =
        PVector.dist(
          position,
          other.position
        );


      if (
        d > 0
        &&
        d < desiredDistance
      ) {

        PVector difference =
          PVector.sub(
            position,
            other.position
          );


        difference.normalize();

        difference.div(
          max(
            d,
            1
          )
        );


        steer.add(
          difference
        );


        count++;
      }
    }


    if (count > 0) {

      steer.div(
        count
      );
    }


    if (steer.mag() > 0) {

      steer.normalize();

      steer.mult(
        2.5
      );

      steer.sub(
        velocity
      );

      steer.limit(
        0.07
      );
    }


    return steer;
  }


  // ==========================================================
  // ALIGNMENT
  // ==========================================================

  PVector align(
    Fish[] allFish
  ) {

    float neighborDistance =
      65;


    PVector averageVelocity =
      new PVector();


    int count = 0;


    for (Fish other : allFish) {

      if (other == this) {
        continue;
      }


      float d =
        PVector.dist(
          position,
          other.position
        );


      if (d < neighborDistance) {

        averageVelocity.add(
          other.velocity
        );

        count++;
      }
    }


    if (count > 0) {

      averageVelocity.div(
        count
      );

      averageVelocity.normalize();

      averageVelocity.mult(
        2
      );


      PVector steer =
        PVector.sub(
          averageVelocity,
          velocity
        );


      steer.limit(
        0.045
      );


      return steer;
    }


    return new PVector();
  }


  // ==========================================================
  // COHESION
  // ==========================================================

  PVector cohesion(
    Fish[] allFish
  ) {

    float neighborDistance =
      75;


    PVector center =
      new PVector();


    int count = 0;


    for (Fish other : allFish) {

      if (other == this) {
        continue;
      }


      float d =
        PVector.dist(
          position,
          other.position
        );


      if (d < neighborDistance) {

        center.add(
          other.position
        );

        count++;
      }
    }


    if (count > 0) {

      center.div(
        count
      );


      PVector desired =
        PVector.sub(
          center,
          position
        );


      if (desired.mag() > 0) {

        desired.normalize();

        desired.mult(
          1.7
        );


        PVector steer =
          PVector.sub(
            desired,
            velocity
          );


        steer.limit(
          0.035
        );


        return steer;
      }
    }


    return new PVector();
  }


  // ==========================================================
  // WATER CURRENT
  // ==========================================================

  void applyCurrent(
    float chaos
  ) {

    // Noise field means neighboring moments are related,
    // producing flowing motion instead of random shaking.

    float n =
      noise(
        position.x * 0.003,
        position.y * 0.003,
        frameCount
        * lerp(
          0.001,
          0.008,
          chaos
        )
      );


    float angle =
      n
      * TWO_PI
      * 2;


    PVector current =
      new PVector(
        cos(angle),
        sin(angle)
      );


    current.mult(
      lerp(
        0.006,
        0.085,
        chaos
      )
    );


    applyForce(
      current
    );
  }


  // ==========================================================
  // WANDERING
  // ==========================================================

  void wander(
    float chaos
  ) {

    float angle =
      noise(
        noiseOffset
      )
      * TWO_PI
      * 2;


    PVector force =
      new PVector(
        cos(angle),
        sin(angle)
      );


    // Still chaotic, but weaker than the attractor force.

    force.mult(
      lerp(
        0.006,
        0.055,
        chaos
      )
    );


    applyForce(
      force
    );


    noiseOffset +=
      lerp(
        0.004,
        0.025,
        chaos
      );
  }


  // ==========================================================
  // RIPPLE RESPONSE
  // ==========================================================

  void reactToRipple(
    float centerX,
    float centerY,
    float radius,
    float strength,
    int currentRippleID,
    float chaos
  ) {
  
    // Each fish should only be hit once per ripple.
    if (lastRippleID == currentRippleID) {
      return;
    }
  
    float d =
      dist(
        position.x,
        position.y,
        centerX,
        centerY
      );
  
    // Wider shockwave in turbulent water.
    float waveWidth =
      lerp(
        25,
        42,
        chaos
      );
  
    // Check whether the expanding wavefront has reached this fish.
    if (abs(d - radius) < waveWidth) {
  
      PVector push =
        PVector.sub(
          position,
          new PVector(centerX, centerY)
        );
  
      if (push.mag() > 0) {
  
        push.normalize();
  
        // Fish near the center of the wavefront get the
        // strongest push.
        float distanceFromWave =
          abs(d - radius);
  
        float impact =
          map(
            distanceFromWave,
            0,
            waveWidth,
            1.25,
            0.75
          );
  
        push.mult(
          strength * impact
        );
  
        // Reduce the fish's previous swimming momentum.
        // This makes the ripple direction dominate.
        velocity.mult(0.30);
  
        // HUGE outward impulse.
        velocity.add(push);
  
        // Add some sideways variation so the fish don't form
        // a perfectly symmetrical circle.
        PVector sideways =
          new PVector(
            -push.y,
            push.x
          );
  
        sideways.normalize();
  
        sideways.mult(
          random(-1.3, 1.3)
          * lerp(0.3, 1.0, chaos)
        );
  
        velocity.add(sideways);
  
        // Fish remain startled for longer in turbulent water.
        ripplePanicFrames =
          int(
            lerp(
              22,
              45,
              chaos
            )
          );
  
        lastRippleID =
          currentRippleID;
      }
    }
  }


  // ==========================================================
  // UPDATE
  // ==========================================================

  void update(float chaos) {
  
    velocity.add(acceleration);
  
    // Normal swimming speed.
    float normalMaxSpeed =
      lerp(
        2.0,
        5.5,
        chaos
      );
  
    float maxSpeed =
      normalMaxSpeed;
  
  
    // --------------------------------------------------------
    // RIPPLE BURST SPEED
    // --------------------------------------------------------
  
    if (ripplePanicFrames > 0) {
  
      // Ripple-hit fish are temporarily allowed to travel
      // MUCH faster than ordinary swimming speed.
      //
      // Calm      -> max ~7
      // Active    -> max ~10
      // Turbulent -> max ~13
      maxSpeed =
        lerp(
          7.0,
          13.0,
          chaos
        );
  
      ripplePanicFrames--;
    }
  
  
    velocity.limit(maxSpeed);
  
    position.add(velocity);
  
    acceleration.mult(0);
  }


  // ==========================================================
  // EDGES
  // ==========================================================

  void edges() {

    if (
      position.x
      < -20
    ) {

      position.x =
        width + 20;
    }


    if (
      position.x
      > width + 20
    ) {

      position.x =
        -20;
    }


    if (
      position.y
      < -20
    ) {

      position.y =
        height + 20;
    }


    if (
      position.y
      > height + 20
    ) {

      position.y =
        -20;
    }
  }


  // ==========================================================
  // DISPLAY
  // ==========================================================

  void display(
    float chaos
  ) {

    pushMatrix();


    translate(
      position.x,
      position.y
    );


    float angle =
      atan2(
        velocity.y,
        velocity.x
      );


    rotate(
      angle
    );


    // --------------------------------------------------------
    // COLOR
    //
    // Calm:
    // blue / cyan
    //
    // Turbulent:
    // coral / orange
    // --------------------------------------------------------

    float r =
      lerp(
        40,
        245,
        chaos
      )
      + colorOffset;


    float g =
      lerp(
        205,
        120,
        chaos
      );


    float b =
      lerp(
        250,
        90,
        chaos
      );


    r =
      constrain(
        r,
        0,
        255
      );


    // Farther fish are more transparent.

    float alpha =
      map(
        depth,
        0.55,
        1.25,
        100,
        235
      );


    float s =
      baseSize;


    // --------------------------------------------------------
    // TAIL
    // --------------------------------------------------------

    noStroke();

    fill(
      r,
      g,
      b,
      alpha * 0.70
    );


    triangle(
      -s * 0.7,
      0,
      -s * 1.6,
      -s * 0.55,
      -s * 1.6,
      s * 0.55
    );


    // --------------------------------------------------------
    // BODY
    // --------------------------------------------------------

    fill(
      r,
      g,
      b,
      alpha
    );


    ellipse(
      0,
      0,
      s * 1.9,
      s
    );


    // --------------------------------------------------------
    // EYE / HIGHLIGHT
    // --------------------------------------------------------

    fill(
      245,
      255,
      255,
      alpha
    );


    ellipse(
      s * 0.5,
      -s * 0.10,
      max(
        1.5,
        s * 0.18
      ),
      max(
        1.5,
        s * 0.18
      )
    );


    popMatrix();
  }
}


// ============================================================
// BUBBLE CLASS
// ============================================================

class Bubble {

  float x;
  float y;

  float radius;

  float speed;

  float phase;

  float depth;


  Bubble() {

    reset(
      true
    );
  }


  // ==========================================================
  // RESET
  // ==========================================================

  void reset(
    boolean randomY
  ) {

    x =
      random(
        width
      );


    if (randomY) {

      y =
        random(
          height
        );

    } else {

      y =
        height
        + random(
          10,
          80
        );
    }


    depth =
      random(
        0.4,
        1.2
      );


    radius =
      random(
        2,
        6
      )
      * depth;


    speed =
      random(
        0.3,
        1.1
      )
      * depth;


    phase =
      random(
        TWO_PI
      );
  }


  // ==========================================================
  // UPDATE
  // ==========================================================

  void update(
    float chaos
  ) {

    // Bubbles rise.

    y -=
      speed
      * lerp(
        0.8,
        1.7,
        chaos
      );


    // Water makes them sway.

    x +=
      sin(
        frameCount * 0.02
        + phase
      )
      * lerp(
        0.15,
        1.1,
        chaos
      );


    if (
      y < -20
    ) {

      reset(
        false
      );
    }
  }


  // ==========================================================
  // DISPLAY
  // ==========================================================

  void display(
    float chaos
  ) {

    noFill();


    float alpha =
      map(
        depth,
        0.4,
        1.2,
        25,
        100
      );


    stroke(
      170,
      230,
      255,
      alpha
    );


    strokeWeight(
      max(
        0.6,
        depth
      )
    );


    ellipse(
      x,
      y,
      radius * 2,
      radius * 2
    );
  }
}
