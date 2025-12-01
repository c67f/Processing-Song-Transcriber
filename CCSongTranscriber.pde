import java.util.Iterator;
import processing.sound.*;

PitchDetector pitchDetector;
AudioIn in;

int windowWidth = 500;
int windowHeight = 500;
int measureVertSpacing = 150;

float pitch;
float lastNote = 0;
float timeBetweenNotes = 0;
float noteStart = 0;
float noteLength = 0;
ArrayList<Float> pitchArray = new ArrayList<Float>(); //array of pitches recorded from when a note is detected to when it stops being detected 
float averagePitch = 0;
float outlierThreshold = 1.2; //how many times larger than the median a value can be before it is considered an outlier
boolean noteDrawn = false;
float avg = 0;

String[] noteNames = {"A3", "A3#", "B3", "C4", "B3#", "D4", "D4#", "E4", "F4", "F4#", "G4", "G4#"};
float[] noteValues = {220.0000, 233.0819, 246.9417, 261.6256, 277.1826, 293.6648, 311.1270, 329.6276, 349.2282, 369.9944, 391.9954, 415.3047};
FloatDict notePitchesDict;
//StringDict noteNamesDict;

//these need to be declared here I guess or there's an error
float total = 0f;
float max = 0f;
float min = 0f;

float beatLength = 200f; //beat length in milliseconds

int noteNum = 0;

void settings(){
  size(windowWidth, windowHeight); 
}

void setup() {
  //pitchArray = new float[];
  
  notePitchesDict = new FloatDict(noteNames, noteValues); //11/18/2025 last thing done: made initial dictionary of notes and their pitches, also before that got notes to wrap around to a new line after reaching the edge of the screen
  //noteNamesDict = new StringDict(noteValues, noteNames);
  background(255);
  
  pitchDetector = new PitchDetector(this, 0.7);
  in = new AudioIn(this, 0);
  in.start();
  pitchDetector.input(in);
}

void draw() {
  fill(0,0,0);
  pitch = pitchDetector.analyze();
  //println(pitch);
  println("millis - lastNote: " + (millis() - lastNote));
  if (pitch > 50){
    if (noteDrawn == true){
      noteDrawn = false;
      noteStart = millis();
    }
    timeBetweenNotes = millis() - lastNote;
    if (millis() - noteStart > 70){
      lastNote = millis();
    }
    pitchArray.add(pitch);
  } else if (noteDrawn == false && lastNote != 0) { //if there's no longer a pitch being detected (and we haven't drawn a note since the last note?) //timeBetweenNotes > 30 && 
    noteLength = millis() - noteStart;
    println("noteLength: " + noteLength);
    println("time between notes: " + timeBetweenNotes); //why is this so low? A: I think because the "ghost notes" that I'm filtering out by the following line are not being filtered out in the first if case so are still counting as notes for "lastNote"
    if (noteLength > 70) {
      println("before removing outliers:");
      printArray(pitchArray);
      removeOutliers(pitchArray);
      println("after removing outliers");
      printArray(pitchArray);
      avg = getAverage(pitchArray);
      println(avg);
      //println(50+millis()*0.02);
      println();//
      
      float closestNote = getClosestVal(noteValues, avg);
      println(closestNote);
      
      circle((50+(20*noteNum)%(windowWidth-50)), (windowHeight-(windowHeight/2 + closestNote*0.5) + measureVertSpacing*floor((50 + (noteNum*20))/windowWidth)), 10);//timeBetweenNotes 
  
      
      println(noteLength + "ms");
      if (noteLength > beatLength*2 && noteLength < beatLength*30){
        fill(255,255,255);
        circle((50+(20*noteNum)%(windowWidth-50)), (windowHeight-(windowHeight/2 + closestNote*0.5) + measureVertSpacing*floor((50 + (noteNum*20))/windowWidth)), 8);
        fill(0,0,0);
      }
      noteNum++;
      
      //rect(50+(millis()*0.02), (500-(avg*0.5)), timeBetweenNotes, 10);
      noteDrawn = true;
      pitchArray.clear();
    }
  } else {
    circle((50+(20*noteNum)%(windowWidth-50)), (windowHeight-(windowHeight/2) + measureVertSpacing*floor((50 + (noteNum*20))/windowWidth)), 5);
    noteNum = int(floor(millis()/beatLength));
  }
  
  
}

void printArray(ArrayList<Float> array){
  print("Array" + "[");
  array.forEach(val ->{
    print(val + ", ");
  });
  println("]");
    
}

void removeOutliers(ArrayList<Float> pitches) {
  float max = getLargestElement(pitches);
  float min = getSmallestElement(pitches);
  println(pitches.size());
  float median = pitches.get(floor(pitches.size()/2));
  float val = 0;
  Iterator<Float> i = pitches.iterator();
  while (i.hasNext()) {
    val = i.next();
    if (val > median*outlierThreshold) {
      i.remove();
      //pitches.remove(val);
    }
  };
}

float getAverage(ArrayList<Float> array) {
  total = 0;
  float average = 0;
  array.forEach(val -> {
    total = total + val;
  });
  average = total/array.size();
  return average;
}

float getLargestElement(ArrayList<Float> array) {
  array.forEach(val -> {
    if (val > max) {
      max = val;
    }
  });
  return max;
}

float getSmallestElement(ArrayList<Float> array) {
  array.forEach(val -> {
    if (val < min) {
      min = val;
    }
  });
  return min;
}

float getClosestVal(float[] array, float input) {
  float distance = Math.abs(array[0] - input);
  float localDist = 1000;
  int outputIndex = 0;
  for (int i = 1; i < array.length; i++){
    localDist = Math.abs(array[i] - input);
    if (localDist < distance){
      outputIndex = i;
      distance = localDist;
    }
  }
  
  return(array[outputIndex]);
}
