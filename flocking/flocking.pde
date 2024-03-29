
Boid barry;
ArrayList<Boid> boids;
ArrayList<Avoid> avoids;

float globalScale = 1;
float eraseRadius = 20;
String tool = "boids";

// boid control
float maxSpeed;
float friendRadius;
float crowdRadius;
float avoidRadius;
float coheseRadius;

boolean option_friend = true;
boolean option_crowd = true;
boolean option_avoid = true;
boolean option_noise = true;
boolean option_cohese = true;

// gui crap
int messageTimer = 0;
String messageText = "";

void setup () {
  size(1300, 720, P3D);
  //fullScreen();

  recalculateConstants();
  boids = new ArrayList<Boid>();
  avoids = new ArrayList<Avoid>();
  for (int x = 120; x < width/4 - 100; x+= 120) {
    for (int y = 110; y < height/2 - 100; y+= 110) {
        for (int z = 100; z < depth - 100; z+= 100) {
          boids.add(new Boid(x + random(10), y + random(10),z + random(10)));
          boids.add(new Boid(x + random(10), y + random(10),z + random(10)));
          boids.add(new Boid(x + random(10), y + random(10),z + random(10)));
          boids.add(new Boid(x + random(10), y + random(10),z + random(10)));
          boids.add(new Boid(x + random(10), y + random(10),z + random(10)));
          boids.add(new Boid(x + random(10), y + random(10),z + random(10)));
          boids.add(new Boid(x + random(10), y + random(10),z + random(10))); 
          boids.add(new Boid(x + random(10), y + random(10),z + random(10)));
          boids.add(new Boid(x + random(10), y + random(10),z + random(10))); 
        }
    }
  }
  

  setupWalls();
}

// haha
void recalculateConstants () {
  maxSpeed = 2.1 * globalScale;
  friendRadius = 80 * globalScale;
  crowdRadius = (friendRadius / 1.3);
  avoidRadius = 40* globalScale;
  coheseRadius = friendRadius;
}



class Avoid {
   PVector pos;
   
   Avoid (float xx, float yy, float zz) {
     pos = new PVector(xx,yy,zz);
   }

   void draw () {
     //fill(0, 0, 255);
     //rect(pos.x, pos.y, 15, 5);
     stroke(0);
     rect(pos.x,pos.y,.5,.5);

   }
}
class Boid {
  // main fields
  PVector pos;
  PVector move;
  float shade;
  ArrayList<Boid> friends;

  // timers
  int thinkTimer = 0;


  Boid (float xx, float yy, float zz) {
    move = new PVector(0, 0, 0);
    pos = new PVector(0, 0, 0);
    pos.x = xx;
    pos.y = yy;
    pos.z = zz;
    thinkTimer = int(random(10));
    shade = random(255);
    friends = new ArrayList<Boid>();
  }

  void go () {
    increment();
    wrap();

    if (thinkTimer ==0 ) {
      // update our friend array (lots of square roots)
      getFriends();
    }
    //PVector noise = new PVector(0, 0, random(2) -1);
    //noise.mult(.1);
    //move.add(noise);
    
    flock();
    pos.add(move);
  }

  void flock () {
    PVector allign = getAverageDir();
    PVector avoidDir = getAvoidDir(); 
    PVector avoidObjects = getAvoidAvoids();
    PVector noise = new PVector(random(2) - 1, random(2) -1, random(2) -1);
    PVector cohese = getCohesion();

    allign.mult(1);
    if (!option_friend) allign.mult(0);
    
    avoidDir.mult(-0.5);
    if (!option_crowd) avoidDir.mult(0);
    
    avoidObjects.mult(3.3);
    if (!option_avoid) avoidObjects.mult(0);

    noise.mult(0.2);
    if (!option_noise)
    noise.mult(0);

    cohese.mult(1.0);
    if (!option_cohese) cohese.mult(0);
    
    stroke(0, 255, 160);

    move.add(allign);
    move.add(avoidDir);
    move.add(avoidObjects);
    move.add(noise);
    move.add(cohese);

    move.limit(1.2*maxSpeed);
    
    //shade += getAverageColor() * 0.03;
    //shade += (random(2) - 1) ;
    //shade = (shade + 255) % 255; //max(0, min(255, shade));
  }

  void getFriends () {
    ArrayList<Boid> nearby = new ArrayList<Boid>();
    for (int i =0; i < boids.size(); i++) {
      Boid test = boids.get(i);
      if (test == this) continue;
      if (dist(test.pos.x, test.pos.y, test.pos.z, this.pos.x, this.pos.y, this.pos.z)
 < friendRadius){
        nearby.add(test);
      }
    }
    friends = nearby;
  }

  float getAverageColor () {
    float total = 0;
    float count = 0;
    for (Boid other : friends) {
      if (other.shade - shade < -128) {
        total += other.shade + 255 - shade;
      } else if (other.shade - shade > 128) {
        total += other.shade - 255 - shade;
      } else {
        total += other.shade - shade; 
      }
      count++;
    }
    if (count == 0) return 0;
    return total / (float) count;
  }

  PVector getAverageDir () {
    PVector sum = new PVector(0, 0, 0);
    int count = 0;

    for (Boid other : friends) {
      float d = PVector.dist(pos, other.pos);
      // If the distance is greater than 0 and less than an arbitrary amount (0 when you are yourself)
      if ((d > 0) && (d < friendRadius)) {
        PVector copy = other.move.copy();
        copy.normalize();
        //copy.div(d); 
        sum.add(copy);
        count++;
      }

    }
    
      if (count > 0) {
        sum.div((float)count);
        return sum;
      }
      
     else {
      return new PVector(0.1, 0.1, 0.1);
    }
    
  }

  PVector getAvoidDir() {
    PVector steer = new PVector(0, 0, 0);
    int count = 0;

    for (Boid other : friends) {
      float d = PVector.dist(pos, other.pos);
      // If the distance is greater than 0 and less than an arbitrary amount (0 when you are yourself)
      if ((d > 0) && (d < crowdRadius)) {
        // Calculate vector pointing away from neighbor
        PVector diff = PVector.sub(pos, other.pos);
        diff.normalize();
        diff.div(-1*d);        // Weight by distance
        steer.add(diff);
        count++;            // Keep track of how many
      }
    }
    if (count > 0) {
      //steer.div((float) count);
    }
    return steer;
  }

  PVector getAvoidAvoids() {
    PVector steer = new PVector(0, 0, 0);
    int count = 0;

    for (Avoid other : avoids) {
      float d = PVector.dist(pos, other.pos);
      // If the distance is greater than 0 and less than an arbitrary amount (0 when you are yourself)
      if ((d > 0) && (d < avoidRadius)) {
        // Calculate vector pointing away from neighbor
        PVector diff = PVector.sub(pos, other.pos);
        diff.normalize();
        diff.div(d);        // Weight by distance
        steer.add(diff);
        count++;            // Keep track of how many
      }
    }
    return steer;
  }
  
  PVector getCohesion () {
   float neighbordist =coheseRadius/4;
    PVector sum = new PVector(0, 0, 0);   // Start with empty vector to accumulate all locations
    int count = 0;
    for (Boid other : friends) {
      float d = PVector.dist(pos, other.pos);
      if ((d > neighbordist) && (d < coheseRadius)) {
        sum.add(other.pos); // Add location
        count++;
      }
    }
    if (count > 0) {
      sum.div(count);
      
      PVector desired = PVector.sub(sum, pos);  
     // println(desired.x);
      desired.div(coheseRadius);
      //println(desired.x);
      return desired;
      //return desired.setMag(0.05);
    } 
    else {
      return new PVector(0, 0, 0);
    }
  }

  void draw () {
    for ( int i = 0; i < friends.size(); i++) {
      Boid f = friends.get(i);
      stroke(90);
      //line(this.pos.x, this.pos.y, f.pos.x, f.pos.y);
    }
    noStroke();
    stroke(0);
    fill(shade, 90, 200);
    float fc=random(5,15);
    pushMatrix();
    translate(pos.x, pos.y, pos.z);
    rotate(move.heading());
    beginShape();
    vertex(6 * globalScale, 0, 0);
    vertex(-2* globalScale, 2* globalScale, 0);
    vertex(0,0,0);
    vertex(-2* globalScale, -2* globalScale, 0);
    endShape(CLOSE);
    beginShape();
    vertex(0, 0, 0);
    vertex(0,0,-2* globalScale);
    vertex(6 * globalScale, 0, 0);
    //vertex(-7* globalScale, -7* globalScale, 0);
    endShape(CLOSE);
   // beginShape(TRIANGLES);
   //ellipse(-1/2*2, 2*2.2,12,2);
   // ellipse(-0.2*2, 2*2,2,fc);
   ////ellipse(r, r*2,15,3);
   // endShape();
    popMatrix();
  }

  // update all those timers!
  void increment () {
    thinkTimer = (thinkTimer + 1) % 5;
  }

  void wrap () {
    pos.x = ((pos.x + (width/4)) % (width/4));
    pos.y = ((pos.y + (height/2)) % (height/2));
    pos.z = ((pos.z + 250.0) % 250.0);
    
  }
}

void setupWalls() {
  avoids = new ArrayList<Avoid>();
   for (int x = 0; x <= (width/4); x+= 10) {
    for(int y=0; y<=height/2; y+=10)
    {
      avoids.add(new Avoid(x,y,0));
      avoids.add(new Avoid(x,y,250));
    }
  } 
  for (int y = 0; y<= (height/2); y+= 10) {
    for(int z=0; z<=250; z+=10)
    {
      avoids.add(new Avoid(0,y,z));
      avoids.add(new Avoid(width/4,y,z));
    }
  } 
  for (int x = 0; x <= (width/4); x+= 10) {
    for(int z=0; z<=250; z+=10)
    {
      avoids.add(new Avoid(x,0,z));
      avoids.add(new Avoid(x,height/2,z));
    }
  } 
  
  //avoids.add(new Avoid(0,0,0));
}

void setupCircle() {
  avoids = new ArrayList<Avoid>();
   for (int x = 0; x < 50; x+= 1) {
     float dir = (x / 50.0) * TWO_PI;
    avoids.add(new Avoid(width * 0.5 + cos(dir) * height*.4, height * 0.5 + sin(dir)*height*.4,0));
  } 
}
float depth=1000.0;

void draw () {
  noStroke();
  //colorMode(HSB);
  fill(35, 120,250);
  rect(-500*width, -500*height, 1000*width, 1000*height);
  stroke(255);
  
  if(key=='n')
  {
    depth=1.1*depth;
    key='c';
  }
  if(key=='m')
  {
    depth=.9*depth;
    key='c';
  }
    
  camera(mouseX,mouseY,depth,width/2,height/2,0,0,1,0);
  translate(width/2,height/4,0);
  //translate(width/2,0,0);
  rotateX(PI/4);
  rotateZ(PI/4);
  fill(35,120,250);
  rect(0,0,width/4,height/2);

  line(0.0,0.0,0.0,0.0,0.0,250.0);
  line(width/4,0.0,0.0,width/4,0.0,250.0);
  line(0.0,height/2,0.0,0.0,height/2,250.0);
  line(width/4,height/2,0.0,width/4,height/2,250.0);
  line(0.0,0.0,250.0,width/4,0.0,250.0);
  line(0.0,0.0,250.0,0.0,height/2,250.0);
  line(0.0,height/2,250.0,width/4,height/2,250.0);
  line(width/4,height/2,250.0,width/4,0.0,250.0);

  if (tool == "erase") {
    noFill();
    stroke(0, 100, 260);
    rect(mouseX - eraseRadius, mouseY - eraseRadius, eraseRadius * 2, eraseRadius *2);
    if (mousePressed) {
      erase();
    }
  } else if (tool == "avoids") {
    noStroke();
    fill(0, 200, 200);
    ellipse(mouseX, mouseY, 15, 15);
  }
  for (int i = 0; i <boids.size(); i++) {
    Boid current = boids.get(i);
    current.go();
    current.draw();
  }

  //for (int i = 0; i <avoids.size(); i++) {
  //  Avoid current = avoids.get(i);
  //  //current.go();
  //  current.draw();
  //}

  if (messageTimer > 0) {
    messageTimer -= 1; 
  }
  drawGUI();
}

void keyPressed () {
  if (key == 'q') {
    tool = "boids";
    message("Add boids");
  }  else if (key == '-') {
    message("Decreased scale");
    globalScale *= 0.8;
  } else if (key == '=') {
      message("Increased Scale");
    globalScale /= 0.8;
  } else if (key == '1') {
     option_friend = option_friend ? false : true;
     message("Turned friend allignment " + on(option_friend));
  } else if (key == '2') {
     option_crowd = option_crowd ? false : true;
     message("Turned crowding avoidance " + on(option_crowd));
  } else if (key == '3') {
     option_avoid = option_avoid ? false : true;
     message("Turned obstacle avoidance " + on(option_avoid));
  }else if (key == '4') {
     option_cohese = option_cohese ? false : true;
     message("Turned cohesion " + on(option_cohese));
  }else if (key == '5') {
     option_noise = option_noise ? false : true;
     message("Turned noise " + on(option_noise));
  } else if (key == ',') {
     setupWalls(); 
  } else if (key == '.') {
     setupCircle(); 
  }
  recalculateConstants();

}

void drawGUI() {
   if(messageTimer > 0) {
     fill((min(30, messageTimer) / 30.0) * 255.0);
    textSize(32);
    fill(255);
    text(messageText, 0, 32, 250); 
   }
}

String s(int count) {
  return (count != 1) ? "s" : "";
}

String on(boolean in) {
  return in ? "on" : "off"; 
}

void mousePressed () {
  //translate(250,250,0);
  //rotateZ(PI/4);
  //rotateY(.955);
  //rotateY(-0.01);
  
  switch (tool) {
  case "boids":
    boids.add(new Boid(((mouseX-(width/4))/sqrt(3)+(mouseY-(height/2))),(mouseY-(height/2))-((mouseX-(width/4))/sqrt(3)) ,125));
    message(boids.size() + " Total Boid" + s(boids.size()));
    
    break;
  case "avoids":
    //avoids.add(new Avoid(((mouseX-(width/4))/sqrt(3)+(mouseY-(height/2))),(mouseY-(height/2))-((mouseX-(width/4))/sqrt(3)) ,0));
    stroke(255);
    line(((mouseX-(width/4))/sqrt(3)+(mouseY-(height/2))),(mouseY-(height/2))-((mouseX-(width/4))/sqrt(3)) ,0,((mouseX-(width/4))/sqrt(3)+(mouseY-(height/2))),(mouseY-(height/2))-((mouseX-(width/4))/sqrt(3)) ,250);
    break;
  }
}

void erase () {
  for (int i = boids.size()-1; i > -1; i--) {
    Boid b = boids.get(i);
    if (abs(b.pos.x - mouseX) < eraseRadius && abs(b.pos.y - mouseY) < eraseRadius) {
      boids.remove(i);
    }
  }

  for (int i = avoids.size()-1; i > -1; i--) {
    Avoid b = avoids.get(i);
    if (abs(b.pos.x - mouseX) < eraseRadius && abs(b.pos.y - mouseY) < eraseRadius) {
      avoids.remove(i);
    }
  }
}

void drawText (String s, float x, float y) {
  fill(0);
  text(s, x, y);
  fill(200);
  text(s, x-1, y-1);
}


void message (String in) {
   messageText = in;
   messageTimer = (int) frameRate * 3;
}
