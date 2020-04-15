import oscP5.*;
import netP5.*;
import controlP5.*;

static int MY_OSC_PORT = -1;

ControlP5 cp5;
OscP5 oscP5;

String debugText = "";
long sendTimer = 0;

void setup() {
  size(800,300);
  loadConfig();

  oscP5 = new OscP5(this, MY_OSC_PORT);
  cp5 = new ControlP5(this);
  PFont font = createFont("arial", 20);

  cp5.addTextfield("target_ip")
    .setPosition(20,10)
    .setSize(150,30)
    .setFont(font)
    .setValue("192.168.0.100")
    .setFocus(true)
    ;
  cp5.addTextfield("target_port")
    .setPosition(200,10)
    .setSize(50,30)
    .setFont(font)
    .setValue("9999")
    ;

  cp5.addTextfield("osc_addr")
    .setPosition(20,80)
    .setSize(150,30)
    .setFont(font)
    .setValue("/test")
    ;

  cp5.addTextfield("osc_format")
    .setPosition(200,80)
    .setSize(100,30)
    .setFont(font)
    .setValue("ssiiss")
    ;

  cp5.addTextfield("osc_params")
    .setPosition(360,80)
    .setSize(400,30)
    .setFont(font)
    .setValue("test test_id 0 0 1234 5678")
    ;

  cp5.addBang("send")
    .setPosition(20,160)
    .setSize(80,30)
    .setFont(font)
    .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
    ;
    
  textFont(font);
  textAlign(LEFT, TOP);
}

void draw() {
  background(0);
  fill(255);
  noStroke();

  fill(255, 0, 0);
  textSize(12);
  text("DO NOT PRESS ENTER KEY", 20, 200);
  
  fill(200);
  text("MY OSC PORT = " + MY_OSC_PORT, 20, 220);
  
  fill(50);
  stroke(255);
  rect(200, 160, 560, 130);
  fill(255);
  text(String.join("\n", debugText.split(",")), 200+5, 160+5, 560-10, 130-10);

  if (sendTimer > 0 && millis() - sendTimer > 10000) {
    debugText = "";
    sendTimer = 0;
  }
}

public void send() {
  String targetIp = cp5.get(Textfield.class, "target_ip").getText();
  if (targetIp.equals("")) {
    debugText = "targetIp is null. send failed.";
    return;
  }

  String targetPort = cp5.get(Textfield.class, "target_port").getText();
  if (targetPort.equals("")) {
    debugText = "targetPort is null. send failed.";
    return;
  }

  String oscAddr = cp5.get(Textfield.class, "osc_addr").getText();
  if (oscAddr.equals("")) {
    debugText = "oscAddr is null. send failed.";
    return;
  }

  String oscFormat = cp5.get(Textfield.class, "osc_format").getText();
  if (oscFormat.equals("")) {
    debugText = "oscFormat is null. send failed.";
    return;
  }

  String[] oscParams = cp5.get(Textfield.class, "osc_params").getText().split(" ");
  if (cp5.get(Textfield.class, "osc_params").getText().equals("")) {
    debugText = "oscParams is null. send failed.";
    return;
  }

  // formatの文字数とparamsのlengthがマッチするか
  if (oscFormat.length() != oscParams.length) {
    debugText = "oscFormat size and oscParams size. send failed.";
    return;
  }

  // メッセージの整形をする
  OscMessage myMessage = new OscMessage(oscAddr);
  try {
    for (int i=0;i<oscParams.length;i++) {
      char f = oscFormat.charAt(i);
      // integer
      if (f == 'i') {
        myMessage.add(Integer.parseInt(oscParams[i]));
      }
      // string
      else if (f == 's') {
        myMessage.add(oscParams[i]);
      }
    }
  }
  catch (Exception e) {
    debugText = e.toString();
    return;
  }

  // 送信をする
  NetAddress targetLocation = new NetAddress(targetIp, Integer.parseInt(targetPort));
  oscP5.send(myMessage, targetLocation);

  // 送信内容メモ
  debugText = (
      "target: " + targetIp + ":" + targetPort + "," +
      "addr: " + oscAddr + " " + oscFormat + "," +
      "params: " + String.join(" ", oscParams)
  );

  sendTimer = millis();
}

void loadConfig() {
  JSONObject config = loadJSONObject(dataPath("config.json"));

  MY_OSC_PORT = config.getInt("myOscPort");
}
