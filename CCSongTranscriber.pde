import java.util.Iterator;
import processing.sound.*;

PitchDetector pitchDetector;
AudioIn in;

//midi variables:
int format = 0;
int tracksNum = 1;
int quarterNoteLength = 192;
int trackLength = 108;//86//8+3+6+4+(6*2*4)+3
int trackLengthCalc = 0;
int totalBytes = 0;
byte[] header = {byte('M'), byte('T'), byte('h'), byte('d'), byte(0), byte(0), byte(0), byte(6), byte(0), byte(format), byte(0), byte(1), byte(0), byte(quarterNoteLength)};
byte[] track = {};
byte[] trackStart = {byte('M'), byte('T'), byte('r'), byte('k'), byte(0), byte(0), byte(0)};
byte[] trackLengthArr = {byte(0)};
byte[] timeSignature = {byte(0), byte(unhex("FF")), byte(unhex("58")), byte(unhex("4")), byte(unhex("4")), byte(unhex("2")), byte(24), byte(8)};
byte[] tempo = {byte(0), byte(unhex("FF")), byte(unhex("51")), byte(unhex("03")), byte(unhex("07")), byte(unhex("A1")), byte(unhex("20"))};
byte[] channelChange = {byte(0), byte(unhex("C0")), byte(0)};
byte[] endTrack = {byte(0), byte(unhex("FF")), byte(unhex("2F")), byte(unhex("00"))};
byte[] noteOn = {byte(0), byte(90), byte(48), byte(96)}; //delta time, event code, note, pressure
byte[] trackName = {byte(0), byte(unhex("FF")), byte(unhex("03")), byte(unhex("0E")), byte('E'), byte('l'), byte('e'), byte('c'), byte('t'), byte('r'), byte('i'), byte('c'), byte(' '), byte('P'), byte('i'), byte('a'), byte('n'), byte('o')};
//don't know why the 0E
//end of midi variables


int windowWidth = 500;
int windowHeight = 500;
int measureVertSpacing = 150;
float startHeight = 0.75; //coefficient for determining initial height of first line (of notes)
float noteVertSpacing = 0.25; //coefficient for determining vertical space between notes
float noteSize = 10;

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

String[] noteNames = {"A2", "A2#", "B2", "C3", "C3#", "D3", "D3#", "E3", "F3", "F3#", "G3", "G3#", "A3", "A3#", "B3", "C4", "B3#", "D4", "D4#", "E4", "F4", "F4#", "G4", "G4#"};
float[] noteValues = {110.0000, 116.5409, 123.4708, 130.8128, 138.5913, 146.8324, 155.5635, 164.8138, 174.6141, 184.9972, 195.9977, 207.6523, 220.0000, 233.0819, 246.9417, 261.6256, 277.1826, 293.6648, 311.1270, 329.6276, 349.2282, 369.9944, 391.9954, 415.3047};
FloatDict notePitchesDict;
ArrayList<Float> noteValuesList = new ArrayList<Float>();

//StringDict noteNamesDict;

//these need to be declared here I guess or there's an error
float total = 0f;
float max = 0f;
float min = 0f;

float beatLength = 200f; //beat length in milliseconds

int noteNum = 0;
boolean createMidi = false;
boolean createdMidi = false;

void settings() {
  size(windowWidth, windowHeight);
}

void setup() {
  //pitchArray = new float[];
  for (int i = 0; i < noteValues.length; i++){
    noteValuesList.add(noteValues[i]);
  }

  notePitchesDict = new FloatDict(noteNames, noteValues); //11/18/2025 last thing done: made initial dictionary of notes and their pitches, also before that got notes to wrap around to a new line after reaching the edge of the screen
  //noteNamesDict = new StringDict(noteValues, noteNames);
  background(255);

  pitchDetector = new PitchDetector(this, 0.7);
  in = new AudioIn(this, 0);
  in.start();
  pitchDetector.input(in);
  line(0, windowHeight-((windowHeight*startHeight) + notePitchesDict.get("G4#")*noteVertSpacing), windowWidth, windowHeight-((windowHeight*startHeight) + notePitchesDict.get("G4#")*noteVertSpacing));
  for (int i = 1; i < noteNames.length-1; i+=4) {
    line(0, windowHeight-((windowHeight*startHeight) + notePitchesDict.get(noteNames[i])*noteVertSpacing), windowWidth, windowHeight-((windowHeight*startHeight) + notePitchesDict.get(noteNames[i])*noteVertSpacing)); //12/1/2025: noticed problem with how I currently determine note yPos - it's based off the pitch, which is not linear, unlike sheet music which is
  }
  line(0, windowHeight-((windowHeight*startHeight) + notePitchesDict.get("A2")*noteVertSpacing), windowWidth, windowHeight-((windowHeight*startHeight) + notePitchesDict.get("A2")*noteVertSpacing));

  
}

void draw() {
  fill(0, 0, 0);
  pitch = pitchDetector.analyze();
  //println(pitch);
  //println("millis - lastNote: " + (millis() - lastNote));
  if (pitch > 50) {
    if (noteDrawn == true) {
      noteDrawn = false;
      noteStart = millis();
    }
    timeBetweenNotes = millis() - lastNote;
    if (millis() - noteStart > 70) {
      lastNote = millis();
    }
    pitchArray.add(pitch);
  } else if (noteDrawn == false && lastNote != 0) { //if there's no longer a pitch being detected (and we haven't drawn a note since the last note?) //timeBetweenNotes > 30 &&
    noteLength = millis() - noteStart;
    //println("noteLength: " + noteLength);
    //println("time between notes: " + timeBetweenNotes); //why is this so low? A: I think because the "ghost notes" that I'm filtering out by the following line are not being filtered out in the first if case so are still counting as notes for "lastNote"
    if (noteLength > 70) {
      println("before removing outliers:");
      printArray(pitchArray);
      removeOutliers(pitchArray);
      println("after removing outliers");
      printArray(pitchArray);
      avg = getAverage(pitchArray);
      println("average pitch:" + avg);
      //println(50+millis()*0.02);
      println();//

      float closestNote = getClosestVal(noteValues, avg);
      println(closestNote);

      float xPos = 50+(20*noteNum)%(windowWidth-50);
      float yPos = windowHeight-(windowHeight*startHeight + closestNote*noteVertSpacing) + measureVertSpacing*floor((50 + (noteNum*20))/windowWidth);




      println(noteLength + "ms");
      if (noteLength > beatLength*1 && noteLength < beatLength*4) {
        circle(xPos, yPos, noteSize);
        fill(255, 255, 255);
        circle(xPos, yPos, 8);
        fill(0, 0, 0);
        addNote(noteValuesList.indexOf(closestNote), noteNum, 2);
      } else if (noteLength > beatLength*4) {
        strokeWeight(4);
        fill(255, 255, 255);
        ellipse(xPos, yPos, noteSize*1.3, noteSize);
        strokeWeight(1); //default
        fill(0, 0, 0);
        addNote(noteValuesList.indexOf(closestNote), noteNum, 4);
      } else {
        circle(xPos, yPos, noteSize);//timeBetweenNotes
        line(xPos + noteSize/2, yPos, xPos + noteSize/2, yPos-20);
        addNote(noteValuesList.indexOf(closestNote), noteNum, 1);
      }
      noteNum++;

      //rect(50+(millis()*0.02), (500-(avg*0.5)), timeBetweenNotes, 10);
      noteDrawn = true;
      pitchArray.clear();
    }
  } else {
    circle((50+(20*noteNum)%(windowWidth-50)), (windowHeight-(windowHeight*0.75) + measureVertSpacing*floor((50 + (noteNum*20))/windowWidth)), 5);
    noteNum = int(floor(millis()/beatLength));
  }
  
  if (millis() > 10000) {
    createMidi = true;
  }
  if (createMidi == true && createdMidi == false){
    println("outputting MIDI");
    //MIDI setup:
    trackLengthCalc+=8;
    trackLengthCalc+=28;
    trackLengthCalc += 4;
    trackLengthArr[0] = byte(trackLengthCalc);
    trackStart = concat(trackStart, trackLengthArr);
    trackStart = concat(trackStart, timeSignature);
    trackStart = concat(trackStart, tempo);
    trackStart = concat(trackStart, trackName);
    trackStart = concat(trackStart, channelChange);
    track = concat(trackStart, track);
    track = concat(track, endTrack);
    totalBytes = track.length;
    println("trackLength is " + trackLengthCalc + " which should be equal to " + (totalBytes-8));
    byte[] file = concat(header, track);
    saveBytes("output.midi", file);
    
    
    createdMidi = true;
  }
}

void printArray(ArrayList<Float> array) {
  print("Array" + "[");
  array.forEach(val -> {
    print(val + ", ");
  }
  );
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
  }
  );
  average = total/array.size();
  return average;
}

float getLargestElement(ArrayList<Float> array) {
  array.forEach(val -> {
    if (val > max) {
      max = val;
    }
  }
  );
  return max;
}

float getSmallestElement(ArrayList<Float> array) {
  array.forEach(val -> {
    if (val < min) {
      min = val;
    }
  }
  );
  return min;
}

float getClosestVal(float[] array, float input) {
  float distance = Math.abs(array[0] - input);
  float localDist = 1000;
  int outputIndex = 0;
  for (int i = 1; i < array.length; i++) {
    localDist = Math.abs(array[i] - input);
    if (localDist < distance) {
      outputIndex = i;
      distance = localDist;
    }
  }

  return(array[outputIndex]);
}

void addNote(int pitch, int start, int newNoteLength) { //start is the notes noteNum
  String timeStart = varLengthRep(start*quarterNoteLength);
  int timeA = unbinary(timeStart.substring(0, 8));
  int timeB = unbinary(timeStart.substring(8, 16));
  byte[] newNoteOn = {byte(timeA), byte(timeB), byte(unhex("90")), byte(pitch+33), byte(70)};
  String timeEnd = varLengthRep((start*quarterNoteLength)+(newNoteLength*10));//quarterNoteLength
  int timeC = unbinary(timeEnd.substring(0, 8));
  int timeD = unbinary(timeEnd.substring(8, 16));
  byte[] newNoteOff = {byte(timeC), byte(timeD), byte(unhex("80")), byte(pitch+33), byte(70)};
  track = concat(track, newNoteOn);
  trackLengthCalc+=5;
  track = concat(track, newNoteOff);
  trackLengthCalc+=5;
}

String varLengthRep(int n) {
  if (n < 128) //7 bits
    return "00000000" + binary(n, 8);
  else if (n < 16383) { //14 bits
    println(n);
    String v1 = binary(n, 14);
    v1 = v1.substring(0, 7);
    String v2 = binary(n, 7);
    //v2 = v2.substring(0, 7);
    String v = "1" + v1 + "0" + v2;
    return v;
  } else {
    return "0";
  }
}
