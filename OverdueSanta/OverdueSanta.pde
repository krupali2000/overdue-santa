float angle = 0;
float len = 200;
PVector anchor;
PVector position;
float size = 40;

float changeInAngle = 0.02;
float diffY = 0;
float diffX = 0;

float acc = 0.0005;
float dec = 0.0005;

final float MAX_ANGLE = PI/2.1;
final float ERROR_ANGLE = PI/100;

class Obstacle {
  float topLeftX, topLeftY, width, height;
  Obstacle() {
  }
  void render() {
    fill(100);
    rect(topLeftX, topLeftY, width, height);
    
  }
}

class Player {
  float x, y, width = 88, height = 100;
  float hookX, hookY, hookLength;
  boolean movingLeft;
  PImage image;
  Player() {
    image = loadImage("data/Santa.png");
  }
  void render() {
    float santaAngle = angle;
    
    pushMatrix(); // remember current drawing matrix)
    imageMode(CENTER);
    
    // Render the player and the hook
    translate(position.x, position.y);
    rotate(-santaAngle);
    image(image, 0, 0, width, height);
    popMatrix();
    imageMode(CORNER);
  }
}

ArrayList<Obstacle> obstacles = new ArrayList<Obstacle>();
Player player;
PShader backgroundShader;

// We will adjust world offset at the end
float worldOffsetY = 0;

float leftWallX, rightWallX;

void setup() {
  size(1000, 800, P2D);
  frameRate(30);
  leftWallX = width * (1./5.);
  rightWallX = width * (4./5.);
  backgroundShader = loadShader("data/bg.glsl");
  backgroundShader.set("u_resolution", float(width), float(height));
  player = new Player();
  player.x = width / 2. - player.width / 2.;
  player.y = height - player.height;
  float obstaclesGap = 300;
  int obstacleStartY = height - 300;
  for (int i = obstacleStartY; i > 0; i -= obstaclesGap) {
    Obstacle newObstacle = new Obstacle();
    float obstacleWidth = 300;
    if (((obstacleStartY - i) / obstaclesGap) % 2 == 0) {
      // Obstacle attached to left wall
      newObstacle.topLeftX = leftWallX;
      newObstacle.topLeftY = i;
      newObstacle.width = obstacleWidth;
      newObstacle.height = 50;
    }
    else {
      // Obstacle attached to right wall
      newObstacle.topLeftX = rightWallX - obstacleWidth;
      newObstacle.topLeftY = i;
      newObstacle.width = obstacleWidth;
      newObstacle.height = 50;
    }
    
    obstacles.add(newObstacle);
  }
  anchor = new PVector(width/2,height/2 + 140);
  position = new PVector(0,0);
}

boolean isPressingS = false, isPressingW = false;

void keyPressed(){
  if (key == 's'){
    isPressingS = true;
  }
  if (key == 'w'){
    isPressingW = true;
  }
}

void keyReleased() {
  if (key == 's'){
    isPressingS = false;
  }
  if (key == 'w'){
    isPressingW = false;
  }
}

void draw() {
  if (isPressingS) {
    len = len + 2;
  }
  if (isPressingW) {
    len = len - 2;
  }
  
  backgroundShader.set("u_offset_y", worldOffsetY);
  shader(backgroundShader);
  rect(0, 0, width, height); 
  resetShader();
  
  float wallWidth = width/5;
  
  for (Obstacle obstacle: obstacles) {
    obstacle.render();
  }
  
  
  recalcAngle();
  recalcPosition(angle);
  drawLine(position, anchor);
  player.x = position.x;
  player.y = position.y;
  player.render();
  
  PVector anchorToCenterPoint = new PVector(-14, +20);
  anchorToCenterPoint.rotate(-angle);
  PVector centerPoint = new PVector(position.x, position.y);
  centerPoint.add(anchorToCenterPoint);
  
  PVector topLeftRotated = new PVector(centerPoint.x, centerPoint.y);
  PVector topLeftRotatedAdj = new PVector(-24, -40);
  topLeftRotatedAdj.rotate(-angle);
  topLeftRotated.add(topLeftRotatedAdj);
  
  PVector topRightRotated = new PVector(centerPoint.x, centerPoint.y);
  PVector topRightRotatedAdj = new PVector(20, -40);
  topRightRotatedAdj.rotate(-angle);
  topRightRotated.add(topRightRotatedAdj);
  
  PVector bottomRightRotated = new PVector(centerPoint.x, centerPoint.y);
  PVector bottomRightRotatedAdj = new PVector(20, 26);
  bottomRightRotatedAdj.rotate(-angle);
  bottomRightRotated.add(bottomRightRotatedAdj);
  
  PVector bottomLeftRotated = new PVector(centerPoint.x, centerPoint.y);
  PVector bottomLeftRotatedAdj = new PVector(-24, 26);
  bottomLeftRotatedAdj.rotate(-angle);
  bottomLeftRotated.add(bottomLeftRotatedAdj);
  
  
  
  line(topLeftRotated.x, topLeftRotated.y, topRightRotated.x, topRightRotated.y);
  line(topRightRotated.x, topRightRotated.y, bottomRightRotated.x, bottomRightRotated.y);
  line(bottomRightRotated.x, bottomRightRotated.y, bottomLeftRotated.x, bottomLeftRotated.y);
  line(bottomLeftRotated.x, bottomLeftRotated.y, topLeftRotated.x, topLeftRotated.y);
  
  circle(centerPoint.x, centerPoint.y, 10.0);
  fill(0);
}

void mousePressed() {
  // accelerate();
  anchor = new PVector(mouseX, mouseY);
  len = dist(anchor.x, anchor.y, position.x, position.y);
  angle = asin((position.x - anchor.x) / (len));
}

void movePlayer(){
  
}

void recalcAngle()
{
  calcPhysics();
  if(abs(angle) > MAX_ANGLE)
  {
    changeInAngle = changeInAngle*-1;
    println("Hit");
  }
  changeInAngle += acc;
  println(angle, acc);
  angle = angle + changeInAngle;
}

void calcPhysics()
{
    if (angle < -ERROR_ANGLE){
      acc = abs(acc);
    }
    else if(angle > ERROR_ANGLE ){
      acc = -abs(acc);
    }
  
}

void delayed()
{
  if (angle < -ERROR_ANGLE){
    changeInAngle += 0.001;
    acc -= 0.000001;
   }
   else if (angle > ERROR_ANGLE) {
     changeInAngle -= 0.001;
     acc += 0.000001;
   }
}

void recalcPosition(float angle)
{
  position.x = anchor.x+len*sin(angle);
  position.y = anchor.y+len*cos(angle);
}

void drawBall(PVector pos)
{
  fill(255,255,255);
  ellipse(pos.x,pos.y,size,size);
}

void drawLine(PVector pos, PVector anchor)
{
  stroke(200);
  line(pos.x,pos.y,anchor.x,anchor.y); 
}

void accelerate()
{
  calcPhysics();
  if (angle < -ERROR_ANGLE ){
    if (abs(acc) < 0.0025){
      acc += 0.0005;
    }
   }
   else if (angle > ERROR_ANGLE){
     if(abs(acc) < 0.0025){
       acc -= 0.0005;
     }
   }
   calcPhysics();
}

//void decelerate()
//{
//  calcPhysics();
//  if (angle < -ERROR_ANGLE ){
//    if (abs(acc) > 0.0005){
//      acc -= 0.0005;
//    }
//   }
//   else if (angle > ERROR_ANGLE){
//     if(abs(acc) > 0.0005){
//       acc += 0.0005;
//     }
//   }
//   calcPhysics();
// }
