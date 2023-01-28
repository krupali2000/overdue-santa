class Obstacle {
  float topLeftX, topLeftY, width, height;
  Obstacle() {
  }
  void render() {
  }
}

class Player {
  float x, y, width, height;
  float hookX, hookY, hookLength;
  void render() {
    // Render the player and the hook
  }
}

ArrayList<Obstacle> obstacles;
Player player;

void setup() {
}

void draw() {
  for (Obstacle obstacle: obstacles) {
    obstacle.render();
  }
  player.render();
  
  // Apply physics to player
  // Aoply physics to 
}

void mousePressed() {
  
}
