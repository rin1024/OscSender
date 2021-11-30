import java.awt.*;
import java.awt.event.*;
import java.util.Date;
import java.util.StringJoiner ; 
import java.util.Arrays ;
import javax.swing.*;
import javax.swing.event.*;
import netP5.*;
import oscP5.*;
import processing.awt.*;

static int MY_OSC_PORT = -1;

static int W_WIDTH = 800;
static int W_HEIGHT = 350;

OscP5 oscP5;
JSONObject config;
int bgColor;

String DEFAULT_TARGET_IP_ADDRESS = "192.168.0.111";
String DEFAULT_TARGET_PORT = "9999";
String DEFAULT_OSC_ADDR = "/test";
String DEFAULT_OSC_FORMAT = "ssiiss";
String DEFAULT_OSC_PARAMS = "TEST test 1234 5678 ABCD EFGH";

JTextField targetIpField;
JTextField targetPortField;
JTextField oscAddrField;
JTextField oscFormatField;
JTextField oscParamsField;
JButton sendButton;
JTextArea logText;

long sendTimer = 0;

void settings() {
  System.setProperty("logging.dir", dataPath("../log/"));
  PropertyConfigurator.configure(dataPath("log4j.properties"));

  loadConfig();
  size(W_WIDTH, W_HEIGHT);
}

void setup() {
  GuiListener listener = new GuiListener(this);

  Canvas canvas = (Canvas)surface.getNative();
  JLayeredPane pane = (JLayeredPane)canvas.getParent().getParent();

  // 送信先のIPアドレス
  targetIpField = new JTextField();
  targetIpField.addKeyListener(listener);
  targetIpField.setText(DEFAULT_TARGET_IP_ADDRESS);
  targetIpField.setBounds(
    20, 10, 150, 30);
  pane.add(targetIpField);

  {
    JLabel l = new JLabel("Target IP Address");
    l.setBounds(
        20 + 5, 10 + 30, 150, 30);
    pane.add(l);
  }

  // 送信先のポート
  targetPortField = new JTextField();
  targetPortField.addKeyListener(listener);
  targetPortField.setText(DEFAULT_TARGET_PORT);
  targetPortField.setBounds(
    200, 10, 50, 30);
  pane.add(targetPortField);

  {
    JLabel l = new JLabel("Target Port");
    l.setBounds(
        200 + 5, 10 + 30, 150, 30);
    pane.add(l);
  }

  // OSCアドレス
  oscAddrField = new JTextField();
  oscAddrField.addKeyListener(listener);
  oscAddrField.setText(DEFAULT_OSC_ADDR);
  oscAddrField.setBounds(
    20, 80, 150, 30);
  pane.add(oscAddrField);

  {
    JLabel l = new JLabel("OSC Address");
    l.setBounds(
        20 + 5, 80 + 30, 150, 30);
    pane.add(l);
  }

  // OSCフォーマット
  oscFormatField = new JTextField();
  oscFormatField.addKeyListener(listener);
  oscFormatField.setText(DEFAULT_OSC_FORMAT);
  oscFormatField.setBounds(
    200, 80, 100, 30);
  pane.add(oscFormatField);

  {
    JLabel l = new JLabel("OSC Format");
    l.setBounds(
        200 + 5, 80 + 30, 100, 30);
    pane.add(l);
  }

  // OSCパラメータ
  oscParamsField = new JTextField();
  oscParamsField.addKeyListener(listener);
  oscParamsField.setText(DEFAULT_OSC_PARAMS);
  oscParamsField.setBounds(
    360, 80, 400, 30);
  pane.add(oscParamsField);

  {
    JLabel l = new JLabel("OSC Params");
    l.setBounds(
        360 + 5, 80 + 30, 400, 30);
    pane.add(l);
  }

  // 送信ボタン
  sendButton = new JButton("Send");
  sendButton.addActionListener(listener);
  sendButton.setBounds(
    20, 160, 80, 30);
  pane.add(sendButton);

  // デバッグ表示用エリア
  logText = new JTextArea();
  logText.setLineWrap(true);
  logText.setPreferredSize(new Dimension(450, 400));
  logText.setBounds(
      205, 165, 550, 120);
  pane.add(logText);

  // set background color
  bgColor = canvas.getBackground().getRGB();
  background(bgColor);

  // OSCの接続開始
  oscP5 = new OscP5(this, MY_OSC_PORT);
}

void draw() {
  background(bgColor);
  if (sendTimer > 0 && millis() - sendTimer > 10000) {
    logText.setText("");
    sendTimer = 0;
  }
}

public void send() {
  String debugText = "";
  String targetIp = targetIpField.getText();
  String targetPort = targetPortField.getText();
  String oscAddr = oscAddrField.getText();
  String oscFormat = oscFormatField.getText();
  String oscParamsAsString = oscParamsField.getText();
  String[] oscParams = oscParamsAsString.split(" ");

  if (targetIp.equals("")) {
    debugText = "targetIp is null. send failed.";
  }
  else if (targetPort.equals("")) {
    debugText = "targetPort is null. send failed.";
  }
  else if (oscAddr.equals("")) {
    debugText = "oscAddr is null. send failed.";
  }
  else if (oscFormat.equals("")) {
    debugText = "oscFormat is null. send failed.";
  }
  else if (oscParamsAsString.equals("")) {
    debugText = "oscParams is null. send failed.";
  }
  // formatの文字数とparamsのlengthがマッチするか
  else if (oscFormat.length() != oscParams.length) {
    debugText = "oscFormat size and oscParams size. send failed.";
  }
  else {
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
        // float
        else if (f == 'f') {
          myMessage.add(Float.parseFloat(oscParams[i]));
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

    // 最後の送信ログを次回利用するために記録
    {
      JSONObject lastQuery = new JSONObject();
      lastQuery.setString("targetIpAddress", targetIp);
      lastQuery.setString("targetPort", targetPort);
      lastQuery.setString("oscAddr", oscAddr);
      lastQuery.setString("oscFormat", oscFormat);
      lastQuery.setString("oscParams", oscParamsAsString);

      config.setJSONObject("lastQuery", lastQuery);
      saveJSONObject(config, dataPath("config.json"));
    }
  }

  logText.setText(String.join("\n", debugText.split(",")));
  sendTimer = millis();
}

void loadConfig() {
  config = loadJSONObject(dataPath("config.json"));

  // 自分のポートを指定
  MY_OSC_PORT = config.getInt("myOscPort");

  // 最後に送った記録がある場合
  JSONObject lastQuery = config.getJSONObject("lastQuery");
  if (lastQuery != null) {
    DEFAULT_TARGET_IP_ADDRESS = lastQuery.getString("targetIpAddress");
    DEFAULT_TARGET_PORT = lastQuery.getString("targetPort");
    DEFAULT_OSC_ADDR = lastQuery.getString("oscAddr");
    DEFAULT_OSC_FORMAT = lastQuery.getString("oscFormat");
    DEFAULT_OSC_PARAMS = lastQuery.getString("oscParams");
  }
}

void oscEvent(OscMessage _msg) {
  println("[oscEvent]" + _msg.toString());
}
