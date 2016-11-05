import netP5.*; //<>//
import oscP5.*;

OscP5 osc;

float MIN_RADIUS = 80;
float MAX_RADIUS = 300;
float radius = 200;
float targetRadius = 200;
float radiusIncrement = 0;
float centX;
float centY;
float rotationAngle;
float rotationSpeed = 0;
//determines the "smoothness" of the circle
float angleIncrement = PI/256;
int fps = 60;
ArrayList<CutRegion> cutRegions;

void setup() {
  osc = new OscP5(this, 7771);
  cutRegions = new ArrayList<CutRegion>();
  centX = height/2;
  centY = width/2;
  rotationAngle = 0;

  size(500, 500);
  background(255);
  smooth(8);
  frameRate(fps);
}

void draw() {
  background(120);
  drawShape();
}

PShape drawShape() {
  PShape shape = createShape();
  shape.beginShape();
  shape.stroke(20, 50, 70);
  shape.fill(90);
  float x, y;
  float xoff = 0;
  float yoff = 0;
  float firstX = -1;
  float firstY = -1;

  if (radius != targetRadius) {
    radius += radiusIncrement;
  }

  for (float ang = 0; ang <= TWO_PI; ang += angleIncrement) {
    Boolean wasCut = false;
    x = 0;
    y = 0;
    for (CutRegion cutRegion : cutRegions) {
      if (ang >= cutRegion.startPos && ang <= (cutRegion.startPos + cutRegion.cutLength)) {
        wasCut = true;
        break;
      }
    }      
    if (!wasCut) {
      x = (radius * cos(ang)) + ((noise(xoff) * 10) - 5);
      y = (radius * sin(ang)) + ((noise(yoff) * 10) - 5);
    }
    if (firstX == -1) {
      firstX = x;
      firstY = y;
    }
    shape.vertex(x, y);
    xoff += 0.1;
    yoff += 0.1;
  }
  shape.vertex(firstX, firstY);
  shape.endShape();

  rotationAngle += rotationSpeed;
  if (rotationAngle >= TWO_PI) {
    rotationAngle = 0;
  }

  shape.rotate(rotationAngle);

  shape(shape, centX, centY);
  return shape;
}

void oscEvent(OscMessage theOscMessage) {
  if (theOscMessage.checkAddrPattern("/speed")) {
    float speedMessage = theOscMessage.get(0).floatValue();
    rotationSpeed = (TWO_PI/fps)/speedMessage;
  } else if (theOscMessage.checkAddrPattern("/cut")) {
    String cutMessage = theOscMessage.get(0).stringValue();
    String[] cutMessageParts = cutMessage.split(",");
    CutRegion cutRegion = new CutRegion(float(cutMessageParts[0]), float(cutMessageParts[1]));
    cutRegions.add(cutRegion);
  } else if (theOscMessage.checkAddrPattern("/amp")) {
    float ampMessage = theOscMessage.get(0).floatValue();
    targetRadius = map(ampMessage, 0, 1, MIN_RADIUS, MAX_RADIUS);
    radiusIncrement = floor((targetRadius - radius)/(fps/2));
  }
}

/** 
  Expects numbers retrieved from OSC in the range of 0 - 1.
  This class will then map them to the range of 0 - TWO_PI.
  */
class CutRegion {
  float startPos, cutLength;
  public CutRegion(float startPos, float cutLength) {
    if (startPos < 0 || startPos > 1) {
      throw new RuntimeException();
    }
    if (cutLength < 0 || cutLength > 1) {
      throw new RuntimeException();
    }
    this.startPos = map(startPos, 0, 1, 0, TWO_PI);
    this.cutLength = map(cutLength, 0, 1, 0, TWO_PI);
  }
}