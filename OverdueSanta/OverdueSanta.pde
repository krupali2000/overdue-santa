float angle = 0;
float len = 90;
float changeInAngle = 0.03;
float acc = 0.0005;

PVector anchor;
PVector position;

float movement = 3;
float worldAcc = 2;
float worldSize = 0;

float speed = 0.02;
float wallWidth = 0;
boolean collision = false;
boolean isPlaying = false;

final float MAX_ACC = 10;
final float MIN_DEC = 3;

final float MAX_ANGLE = PI/3;
final float ERROR_ANGLE = PI/100;

class Obstacle {
  float topLeftX, topLeftY, obstacleWidth, obstacleHeight;
  Obstacle() {
  }
  void render() {
    fill(100);
    rect(topLeftX, topLeftY, obstacleWidth, obstacleHeight);
    
  }
  boolean xInObstacle(float x)
  {
    return ((topLeftX <= x) && (x <= topLeftX + obstacleWidth));
  }
  boolean yInObstacle(float y)
  {
    return ((topLeftY <= y) && (y <= topLeftY + obstacleHeight));
  }
}

class Player {
  float x, y, playerWidth = 50, playerHeight = 70;
  float hookX, hookY, hookLength;
  boolean movingLeft;
  PImage image;
  
  Player() {
    image = loadImage("data/Santa.png");
  }
  
  void render() {
    
    pushMatrix(); // remember current drawing matrix)
    imageMode(CENTER);
    
    // Render the player and the hook
    translate(x, y);
    image(image, playerWidth/2, playerHeight/2, playerWidth, playerHeight);
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
  worldSize = width;
  frameRate(30);
  leftWallX = width * (1./5.);
  rightWallX = width * (4./5.);
  backgroundShader = loadShader("data/bg.glsl");
  backgroundShader.set("u_resolution", float(width), float(height));
  
  player = new Player();

  reset();
  
  wallWidth = width/5;
}

boolean isPressingA = false, isPressingD = false, isPressingW = false, isPressingS = false;

boolean isPressingE = false, isPressingQ = false, isPressingZ = false, isPressingX = false; 

void keyPressed(){
  if (!isPlaying  && key == ' '){
    isPlaying = true;
    reset();
  }
  if (key == 'a'){
    isPressingA = true;
  }
  if (key == 'd'){
    isPressingD = true;
  }
  if (key == 'w'){
    isPressingW = true;
  }
  if (key == 's'){
    isPressingS = true;
  }
  if (key == 'e'){
    isPressingE = true;
  }
  if (key == 'q'){
    isPressingQ = true;
  }
  if (key == 'z'){
    isPressingZ = true;
  }
  if (key == 'x'){
    isPressingX = true;
  }
}

void keyReleased() {
  if (key == 'a'){
    isPressingA = false;
  }
  if (key == 'd'){
    isPressingD = false;
  }
  if (key == 'w'){
    isPressingW = false;
  }
  if (key == 's'){
    isPressingS = false;
  }
  if (key == 'e'){
    isPressingE = false;
  }
  if (key == 'q'){
    isPressingQ = false;
  }
  if (key == 'z'){
    isPressingZ = false;
  }
  if (key == 'x'){
    isPressingX = false;
  }
}

int movementMultiplier = 1;

int hash(int hashCode) {
    hashCode ^= (hashCode >>> 20) ^ (hashCode >>> 12);
    return hashCode ^ (hashCode >>> 7) ^ (hashCode >>> 4);
  }

void draw() {
  showGameStartMessage();
  //println(isPlaying);
  if (isPlaying){
    boolean shouldGlitch = (int(millis() / 3000.0) + "").hashCode() % 3 == 0;
    println(shouldGlitch);
    if (shouldGlitch) {
      movementMultiplier = -1;
    }
    else {
      movementMultiplier = 1;
    }
    worldOffsetY += worldAcc * 2;
    if (isPressingA) {
      anchor.x -= movement * movementMultiplier;
      //angle = angle - movement/30;
    }
    if (isPressingD) {
      anchor.x += movement * movementMultiplier;
      //angle = angle + movement/30;
    }
    if (isPressingW) {
      anchor.y -= movement * movementMultiplier;
      if (anchor.y < height/3){
        anchor.y = height/3;
      }
    }
    if (isPressingS) {
      anchor.y += movement * movementMultiplier;
      if (anchor.y > 2*height/3){
        anchor.y = 2*height/3;
      }
    }
    if (isPressingQ) {
      accelerate();
    }
    if (isPressingE) {
      decelerate();
    }
    if (isPressingZ) {
      worldAcc += 0.5;
      worldAcc = min(11, worldAcc);
    }
    if (isPressingX) {
      worldAcc -= 0.5;
      worldAcc = max(2, worldAcc);
    }
    //println(worldAcc);
    
    backgroundShader.set("u_offset_y", worldOffsetY);
    shader(backgroundShader);
    rect(0, 0, width, height); 
    resetShader();
 
    for (Obstacle obstacle: obstacles) {
      obstacle.render();
    }
  
    recalcAngle();
    recalcPosition(angle);
    drawLine(position, anchor);
    drawShip();
    player.x = position.x - 4*player.playerWidth/5;
    player.y = position.y - 1*player.playerHeight/10;
    player.render();
  
    moveObstacles();
    checkCollision();
    
    if(shouldGlitch)
    {
       glitch(); 
    }
  
  }
  if(collision) {
   //  showGameOverMessage();
  }
}

void moveObstacles(){
  for(Obstacle obs : obstacles) {
    obs.topLeftY += worldAcc;
    
    if(obs.topLeftY > height){
      obs.topLeftY = -obs.obstacleHeight;
    }
  }
}

void checkCollision(){
  if (position.x + player.playerWidth > width - wallWidth) {
    collision = true;
    
    //println("hit");
    
  }
  else if (position.x < wallWidth) {
    collision = true;
    
    //println("hit");
  }
  else{
     for(Obstacle obs : obstacles){
       if(overlap(obs))
       {
         collision = true;
         
      //   println("hit");
       }
     }
  }
}

boolean overlap(Obstacle obstacle)
{
  float checkPositionX = position.x - player.playerWidth;
  boolean doubled = false;
  if((obstacle.xInObstacle(checkPositionX + player.playerWidth)) && (obstacle.yInObstacle(position.y + player.playerHeight)))
    doubled = true;
  if((obstacle.xInObstacle(checkPositionX)) && (obstacle.yInObstacle(position.y + player.playerHeight)))
    doubled = true;
  if((obstacle.xInObstacle(checkPositionX + player.playerWidth)) && (obstacle.yInObstacle(position.y)))
    doubled = true;
  if((obstacle.xInObstacle(checkPositionX)) && (obstacle.yInObstacle(position.y)))
    doubled = true;
  return doubled;
}

void accelerate()
{
    movement++;
    if(movement > MAX_ACC){
      movement = MAX_ACC;
    }
}

void decelerate()
{
    movement--; 
    if(movement < MIN_DEC){
      movement = MIN_DEC;
    }
}

void showGameOverMessage(){
  background(0);
  isPlaying = false;
  fill(225);
  textSize(100);
  textAlign(CENTER,CENTER);
  text("Game Over!",width/2,height/2 - 115);
  textSize(75);
  text("Hit Space Bar to restart", width/2, height/2);  
}

void showGameStartMessage(){
  background(0);
  fill(225);
  textSize(100);
  textAlign(CENTER,CENTER);
  text("Game Start!",width/2,height/2 - 115);
  textSize(75);
  text("Hit Space Bar to start", width/2, height/2);  
}

void reset(){  
  anchor = new PVector(width/2, height/2);
  position = new PVector(0,0);
  collision = false;
  obstacles = new ArrayList<Obstacle>();
  
  angle = 0;
  changeInAngle = 0.03;
  acc = 0.00055;

  float obstaclesGap = 200;
  int obstacleStartY = height;
  setObstacles(obstaclesGap, obstacleStartY);
}

void setObstacles(float obstaclesGap,  int obstacleStartY){
  for (int i = obstacleStartY; i > 0; i -= obstaclesGap) {
    Obstacle newObstacle = new Obstacle();
    float obstacleWideness = 200;
    if (((obstacleStartY - i) / obstaclesGap) % 2 == 0) {
      // Obstacle attached to left wall
      newObstacle.topLeftX = leftWallX;
      newObstacle.topLeftY = i;
      newObstacle.obstacleWidth = obstacleWideness;
      newObstacle.obstacleHeight = 50;
    }
    else {
      // Obstacle attached to right wall
      newObstacle.topLeftX = rightWallX - obstacleWideness;
      newObstacle.topLeftY = i;
      newObstacle.obstacleWidth = obstacleWideness;
      newObstacle.obstacleHeight = 50;
    }   
    obstacles.add(newObstacle);
  }
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
 // println(angle, acc);
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

void recalcPosition(float angle)
{
  position.x = anchor.x + len*sin(angle);
  position.y = anchor.y+len*cos(angle);
}

void drawLine(PVector pos, PVector anchor)
{
  fill(255);
  stroke(200);
  line(pos.x,pos.y,anchor.x,anchor.y); 
}

float xCenter;                  
float yCenter;                  
float noseX;                    
float noseY;                    
float ear1X;                    
float ear1Y;                    
float ear2X;                    
float ear2Y;     
float size = 5;
final float DISTANCE_1 = 7*size;    
final float DISTANCE_2 = 4*size;    
final float THETA = 2.3;  

void drawShip() {
  fill(255);
  xCenter = anchor.x;
  yCenter = anchor.y;
  calcMovingPoints();
  quad(xCenter,yCenter,
  ear1X,ear1Y,noseX,noseY,ear2X,ear2Y);
}

void calcMovingPoints() {
   noseY = yCenter-DISTANCE_1*cos(angle);
   ear1Y = yCenter-DISTANCE_2*cos(THETA-angle);
   ear2Y = yCenter-DISTANCE_2*cos(2*PI-(THETA+angle));
   noseX = xCenter-DISTANCE_1*sin(angle);
   ear1X = xCenter-DISTANCE_2*sin(THETA-angle);
   ear2X = xCenter-DISTANCE_2*sin(2*PI-(THETA+angle));
}

void glitch(){
  //float n = random(200);
  for (int i = 0; i < 100; i++){
    stroke(random(255),random(255),random(255));
    float r = random(width/5, 4*width/5);
    line(r, 0, r, height);
  }
  stroke(255);
}
