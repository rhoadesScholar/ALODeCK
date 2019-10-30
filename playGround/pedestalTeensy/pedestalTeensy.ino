int cap1 = 0;  // wire connected to pin 1
int cap2 = 0;  // wire connected to pin 15
float baseCap1;
float baseCap2;
float THRESH = 2.05;
float avgWeight = .99;

void setup() {
  Serial.begin(9600);
  cap1 = touchRead(1);  // wire connected to pin 1
  cap2 = touchRead(15);  // wire connected to pin 15
  
  baseCap1 = cap1;
  baseCap2 = cap2;
}

void loop() {
  while (pow(2,cap1/baseCap1) < THRESH && pow(2,cap2/baseCap2) < THRESH) { 
    baseCap1 = avgWeight*baseCap1 + (1-avgWeight)*cap1;
    baseCap2 = avgWeight*baseCap2 + (1-avgWeight)*cap2;
    cap1 = touchRead(1);  // wire connected to pin 1
    cap2 = touchRead(15);  // wire connected to pin 15
    
//      Serial.print(pow(2,cap1/baseCap1));                  // print sensor output 1
//      Serial.print("\t");
//      Serial.println(pow(2,cap2/baseCap2));                // print sensor output 15
    delay(10);      
  }
  if (pow(2,cap1/baseCap1) > THRESH) {
    Serial.println("on_ped1");
  }
  if (pow(2,cap2/baseCap2) > THRESH) {
    Serial.println("on_ped2");
  }
  while (pow(2,cap1/baseCap1) >= THRESH || pow(2,cap2/baseCap2) >= THRESH) { 
    cap1 = touchRead(1);  // wire connected to pin 1
    cap2 = touchRead(15);  // wire connected to pin 15
    
//      Serial.print(pow(2,cap1/baseCap1));                  // print sensor output 1
//      Serial.print("\t");
//      Serial.println(pow(2,cap2/baseCap2));                // print sensor output 15
    delay(10);      
  }
  Serial.println("off");
  baseCap1 = cap1;
  baseCap2 = cap2;
}
