//
// BlinkMScriptTool.pde --  Load/Save BlinkM light scripts in text format
//
//   You can use this download the BlinkMSequencer-creatd light scripts
//   from a BlinkM.  Or to reset a BlinkM to its default light script.
//
//   Note: it only loads files with .txt extensions, so be sure to save your
//         files as that.
//
// 2008-2010, Tod E. Kurt, ThingM, http://thingm.com/
//
//

import java.awt.*;
import java.awt.event.*;
import javax.swing.*; 
import java.util.regex.*;
import javax.swing.border.*;      // for silly borders on buttons
import javax.swing.plaf.metal.*;  // for look-n-feel stuff

import thingm.linkm.*;

boolean debug = true;

int blinkmaddr = 0x09;  // we'll find the first one on the bus

String strToParse =  
  "// Edit your BlinkM light script here. \n"+
  "// Or load one up from a text file.  \n"+
  "// Or read the one stored on a BlinkM.\n"+
  "// Then save your favorite scripts to a text files\n"+
  "// Several example scripts are stored in this sketch's 'data' directory.\n"+
  "// Make sure you have BlinkMCommunicator installed on your Arduino.\n"+
  "//\n"+
  "// Here's an example light script. It's the default BlinkM script.\n\n"+
  "{  // dur, cmd,  arg1,arg2,arg3\n"+
  "    {  1, {'f',   10,0x00,0x00}},  // set color_step (fade speed) to 10\n"+
  "    {100, {'c', 0xff,0xff,0xff}},  // bright white\n"+
  "    { 50, {'c', 0xff,0x00,0x00}},  // red \n"+
  "    { 50, {'c', 0x00,0xff,0x00}},  // green\n"+
  "    { 50, {'c', 0x00,0x00,0xff}},  // blue \n"+
  "    { 50, {'c', 0x00,0x00,0x00}},  // black (off)\n"+
  "}\n\n";

int maxScriptLength = 49;  // max the EEPROM on BlinkM can hold
BlinkMScriptLine nullScriptLine = new BlinkMScriptLine( 0,(char)0x00,0,0,0);

LinkM linkm = new LinkM();

boolean isConnected = false;

ScriptToolFrame stf;
JFileChooser fc;
//JButton disconnectButton;
JTextArea editArea;  // contains the raw text of the script
JTextField posText;
JLabel statusText;

int mainWidth = 740;
int mainHeight = 480;
Font monoFont  = new Font("Monospaced", Font.PLAIN, 14); // all hail fixed width
Font monoFontSm = new Font("Monospaced", Font.PLAIN, 9); 
Color backColor = new Color(150,150,150);


//
// Processing's setup()
//
void setup() {
  size(100, 100);   // Processing's frame, we'll turn this off in a bit
  //blinkmComm = new BlinkMComm(this);
  setupGUI();

  //connectLinkM(); // we do it on demand
}

//
// Processing's draw()
// Here we're using it as a cheap way to finish setting up our other window
// and as a simple periodic loop to deal with disconnectButton state
// (could write a handler for that, but i'm lazy)
//
void draw() {
  // we can only do this after setup
  if( frameCount < 60 ) {
    super.frame.setVisible(false);  // turn off Processing's frame
    super.frame.toBack();
    stf.toFront();
  }
}

/*
 * not used
 */
void connectLinkM() {
  try { 
    linkm.open();
    linkm.i2cEnable(true);
  } catch(IOException ioe) {
    debug("connect: no linkm? "+ioe);
    return;
  }
  debug("linkm connected.");
}
//
void debug(String s) {
  println(s);
}

void status(String s) { 
  s = (isConnected) ? "connected to blinkm addr "+blinkmaddr+": "+s : s;
  println(s);
  statusText.setText(s);
}

// this class is bound to the GUI buttons below
// it triggers the four main functions
class MyActionListener implements ActionListener{
  public void actionPerformed(ActionEvent e) {
    String cmd = e.getActionCommand();
    if( cmd == null ) return;

    if( cmd.equals("stopScript")) {
      stopScript();
    }
    else if( cmd.equals("playScript")) {
      playScript();
    }
    else if( cmd.equals("saveFile") ) {
      saveFile();
    }
    else if( cmd.equals("loadFile") ) {
      loadFile();
    }
    else if( cmd.equals("sendBlinkM") ) {
      sendToBlinkM();
    }
    else if( cmd.equals("recvBlinkM") ) {
      receiveFromBlinkM();
    }
    else if( cmd.equals("inputs") ) {
      showInputs();
    }
  }
}

// open up the LinkM and set it up if it hasn't been
boolean connectIfNeeded() {
  if( !isConnected ) {
    println("connecting");
    try { 
      linkm.open();
      linkm.i2cEnable(true);
      linkm.pause(50); // wait for bus to stabilize
      byte[] addrs = linkm.i2cScan(1,100);  // FIXME: not a full scan
      int cnt = addrs.length;
      status("found "+cnt+" blinkms");
      if( cnt>0 ) {
        status("using blinkm at addr "+addrs[0]);
        blinkmaddr = addrs[0];
      }
      else {
        status("no blinkm found!");  // FIXME: pop up dialog?
      }
    } catch(IOException ioe) {
      println("connect:no linkm?\n"+ioe);
      status("no linkm found");
      return false;
    }
  }
  linkm.pause(200);
  isConnected = true;
  return true; // connect successful
}

//
void stopScript() {
  if( !connectIfNeeded() ) return;
  status("stop");
  try { 
    linkm.stopScript(blinkmaddr);
  } catch(IOException ioe) {
    isConnected = false;
    status("no linkm");
  }
}

//
void playScript() {
  if( !connectIfNeeded() ) return;
  int pos = 0;
  String s = posText.getText().trim();
  try { pos = Integer.parseInt(s);} catch(Exception nfe){}
  if( pos < 0 ) pos = 0;
  status("playing at position "+pos);
  //if( !connectIfNeeded() ) return;
  try {
    linkm.playScript(blinkmaddr, 0,0,pos);
  } catch(IOException ioe) { 
    isConnected = false;
    println("no linkm?\n"+ioe);
    status("no linkm?");
  }
}

// set a script to blinkm
void sendToBlinkM() {
  //String[] rawlines = editArea.getText().split("\n");
  //String str = linkm.scriptLinesToString(rawlines);
  String str = editArea.getText();
  BlinkMScript script = linkm.parseScript(str);
  status("script:\n"+script.toString(true));
  BlinkMScript scriptToSend = script.trimComments();
  status("scriptToSend:\n"+scriptToSend.toString(true));
  int len = scriptToSend.length();

  if(debug) 
      status("size:"+script.length()+", no comment size:"+len); //+"\n"+str );

  if( !connectIfNeeded() ) return;
  
  // update the text area with the parsed script
  str = "// Uploaded to BlinkM on "+(new Date())+"\n" + str;
  editArea.setText( str );
    
  status("sending!...");
  long st = System.currentTimeMillis();
  try { 
    linkm.writeScript( blinkmaddr, scriptToSend );
    linkm.setStartupParamsDefault(blinkmaddr);
    linkm.playScript(blinkmaddr);

    // write an empty scriptLine to indicate end of script on readback
    if( len < maxScriptLength ) {  
        linkm.writeScriptLine( blinkmaddr, len, nullScriptLine );
    }
    linkm.setScriptLengthRepeats( blinkmaddr, len, 0 );

  } catch( IOException ioe ) {
    isConnected = false;
    println("no linkm?\n"+ioe);
    status("no linkm?");
    return;
  }
  long et = System.currentTimeMillis();
  status("done sending!");
  debug("send elapsed "+(et-st)+" millis)");

}

// download a script from a blinkm
void receiveFromBlinkM() {
  if( !connectIfNeeded() ) return;
  print("receiving!...");
  String str = null;
  try { 
    str = linkm.readScriptToString( blinkmaddr, 0, false);
  } catch(IOException ioe) {
    isConnected = false;
    println("no linkm?\n"+ioe);
    status("no linkm?");
    return;
  }
  if( str != null ) {
    str = "// Downloaded from BlinkM on "+(new Date())+"\n" + str;
    editArea.setText(str); // copy it all to the edit textarea
    editArea.setCaretPosition(0);
  }
  status("done receiving!");
}

// Load a text file containing a light script and turn it into BlinkMScriptLines
// Note: uses Procesing's "loadStrings()"
void loadFile() {
  int returnVal = fc.showOpenDialog(stf);  // this does most of the work
  if (returnVal != JFileChooser.APPROVE_OPTION) {
    status("load file cancelled");
    return;
  }
  File file = fc.getSelectedFile();
  if( file != null ) {
    String[] lines = LinkM.loadFile( file );
    BlinkMScript script = LinkM.parseScript( lines );
    if( script == null ) {
      status("bad format in file");
      return;
    }
    
    editArea.setText(script.toString()); // copy it all to the edit textarea
    editArea.setCaretPosition(0);
    //scriptLines = linkm.parseScript( lines ); // and parse it
  }
  status("file "+file.getName()+" loaded");
}

// Save a text file of BlinkMScriptLines
// Note: uses Processing's "saveStrings()"
void saveFile() {
  int returnVal = fc.showSaveDialog(stf);  // this does most of the work
  if( returnVal != JFileChooser.APPROVE_OPTION) {
    status("Save file cancelled");
    return;
  }
  File file = fc.getSelectedFile();
  String fname = file.getName();
  if( ! (fname.endsWith("txt") || fname.endsWith("TXT")) ) {
    file = new File( file.getAbsolutePath() +".txt");  // add .txt if the user doesn't
  }
  String lines[] = editArea.getText().split("\n");
  saveStrings(file, lines);  // actually write the file

  status("file "+file.getName()+" saved");
}

// Utility: parse a hex or decimal integer
int parseHexDecInt(String s) {
  int n=0;
  try { 
    if( s.indexOf("0x") != -1 ) // it's hex
      n = Integer.parseInt( s.replaceAll("0x",""), 16 ); // yuck
    else 
      n = Integer.parseInt( s, 10 );
  } catch( Exception e ) {}
  return n;
}

// -------------------------------------------------------------------------

//  The nuttiness below is to do the "Inputs" dialog. Jeez what a mess.
JTextField inputText;
JDialog inputDialog;
boolean watchInput;

class InputWatcher implements Runnable {
  public void run() {
    while( watchInput && isConnected ) { 
      try { Thread.sleep(333); } catch(Exception e) {} 
      byte[] inputs = null;
      try { 
        inputs = linkm.readInputs(blinkmaddr);
      } catch(IOException ioe){
        isConnected = false;
      }
      String s = "inputs: ";
      if( inputs == null ) {
        s += "error reading";
      } else {
        for( int i=0; i<inputs.length; i++) {
          s += "0x" + Integer.toHexString( inputs[i] & 0xff) + ", ";
        }
      }
      inputText.setText(s);
      status(s);
    }
    inputDialog.hide();
  }
}

// man this seems messier than it should be
// all I want is a Dialog with a single line of text and an OK button
// where I can dynamically update the line of text
void showInputs() {
  if( !connectIfNeeded() ) return;
  status("watching inputs!...");
  inputDialog = new JDialog(stf, "Inputs", false);
  inputDialog.addWindowListener( new WindowAdapter() {
      public void windowClosing(WindowEvent e) {
        watchInput = false;
      }});
  inputDialog.setLocationRelativeTo(stf);
  Container cp = inputDialog.getContentPane();
  //cp.setLayout(new BorderLayout());
  JPanel panel = new JPanel(new BorderLayout());
  panel.setBorder(new EmptyBorder(10,10,10,10));
  cp.add(panel);
  
  inputText = new JTextField("inputs",20);
  JButton btn = new JButton("Done");
  btn.addActionListener( new ActionListener() {
      public void actionPerformed(ActionEvent ae) {
        watchInput = false;
      }});
  panel.add( inputText, BorderLayout.CENTER );
  panel.add( btn, BorderLayout.SOUTH );
  inputDialog.pack();
  inputDialog.show();

  watchInput = true;
  new Thread( new InputWatcher() ).start();
  // this exits, and thread shoud quit when Done is clikd or window closed
}

// ---------------------------------------------------------------------

//
// do all the nasty gui stuff that's all Java and not very Processingy
//
void setupGUI() {
  try {  // use a Swing look-and-feel that's the same across all OSs
    MetalLookAndFeel.setCurrentTheme(new DefaultMetalTheme());
    UIManager.setLookAndFeel( new MetalLookAndFeel() );
  } catch(Exception e) { 
    println("drat: "+e);
  }

  fc = new JFileChooser( super.sketchPath ); 
  fc.setFileFilter( new javax.swing.filechooser.FileFilter() {
      public boolean accept(File f) {
        if (f.isDirectory()) 
          return true;
        if (f.getName().endsWith("txt") ||
            f.getName().endsWith("TXT")) 
          return true;
        return false;
      }
      public String getDescription() {
        return "TXT files";
      }
    }
    );
  
  stf = new ScriptToolFrame(mainWidth, mainHeight, this);
  stf.createGUI();

  super.frame.setVisible(false);
  stf.setVisible(true);
  stf.setResizable(false);

}

//
// A new window that holds all the Swing GUI goodness
//
public class ScriptToolFrame extends JFrame {

  public Frame f = new Frame();
  private int width, height;
  private PApplet appletRef;     

  //
  public ScriptToolFrame(int w, int h, PApplet appRef) {
    super("BlinkMScriptTool");
    this.setBackground( backColor );
    this.setFocusable(true);
    this.width = w;
    this.height = h;
    this.appletRef = appRef;

    // handle window close events
    this.addWindowListener(new WindowAdapter() {
        public void windowClosing(WindowEvent e) {
          dispose();            // close mainframe
          appletRef.destroy();  // close processing window as well
          appletRef.frame.setVisible(false);
          System.exit(0);
        }
      }); 

    // center on the screen and show it
    this.setSize(this.width, this.height);
    //this.pack();
    Dimension scrnSize = Toolkit.getDefaultToolkit().getScreenSize();
    this.setLocation(scrnSize.width/2 - this.width/2, 
                     scrnSize.height/2 - this.height/2);
    this.setVisible(true);
  }

  //
  public void createGUI() {
    this.setLayout( new BorderLayout() );
    JPanel editPanel = new JPanel(new BorderLayout());
    JPanel bottPanel = new JPanel();
    JPanel ctrlPanel = new JPanel();    // contains all controls
    JPanel filePanel = new JPanel();    // contains load/save file
    JPanel blinkmPanel  = new JPanel(); // contains all blinkm ctrls
    bottPanel.setLayout( new BoxLayout(bottPanel,BoxLayout.Y_AXIS) );
    ctrlPanel.setLayout( new BoxLayout(ctrlPanel,BoxLayout.X_AXIS) );
    filePanel.setLayout( new BoxLayout(filePanel,BoxLayout.X_AXIS) );
    blinkmPanel.setLayout( new BoxLayout(blinkmPanel,BoxLayout.X_AXIS) );
    
    statusText = new JLabel("Welcome To BlinkMScriptTool");
    JPanel statusPanel = new JPanel();
    statusPanel.setLayout( new BoxLayout(statusPanel,BoxLayout.X_AXIS) );
    statusPanel.setBorder( new EmptyBorder(5,5,5,5));
    statusPanel.add( statusText );
    statusPanel.add( Box.createGlue() );

    ctrlPanel.add(filePanel);
    ctrlPanel.add(blinkmPanel);

    bottPanel.add(ctrlPanel);
    bottPanel.add(statusPanel);

    this.getContentPane().add( editPanel,   BorderLayout.NORTH);
    this.getContentPane().add( bottPanel,   BorderLayout.SOUTH);

    ctrlPanel.setBorder(new EmptyBorder(5,5,5,5));

    filePanel.setBorder( new CompoundBorder
                         (BorderFactory.createTitledBorder("file"),
                          new EmptyBorder(5,5,5,5)));
    blinkmPanel.setBorder( new CompoundBorder
                           (BorderFactory.createTitledBorder("blinkm"),
                            new EmptyBorder(5,5,5,5)));

    editArea = new JTextArea(strToParse,24,80);
    editArea.setFont( monoFont );
    editArea.setLineWrap(false);
    JScrollPane scrollPane = new JScrollPane(editArea, ScrollPaneConstants.VERTICAL_SCROLLBAR_ALWAYS, ScrollPaneConstants.HORIZONTAL_SCROLLBAR_AS_NEEDED);
    editPanel.add( scrollPane, BorderLayout.CENTER);
  
    MyActionListener mal = new MyActionListener();

    JButton loadButton = addButton("Load", "loadFile", mal, filePanel);
    JButton saveButton = addButton("Save", "saveFile", mal, filePanel);

    JButton sendButton = addButton("Send",    "sendBlinkM", mal, blinkmPanel); 
    JButton recvButton = addButton("Receive", "recvBlinkM", mal, blinkmPanel); 

    blinkmPanel.add(Box.createHorizontalStrut(15));

    //disconnectButton  = addButton("disconnect","disconnect", mal,blinkmPanel);
    //disconnectButton.setEnabled(false);
    //blinkmPanel.add(Box.createRigidArea(new Dimension(5,5)));;

    JButton stopButton = addButton("Stop", "stopScript", mal, blinkmPanel);
    JButton playButton = addButton("Play", "playScript", mal, blinkmPanel);
    
    blinkmPanel.add(Box.createHorizontalStrut(125));
    JLabel posLabel = new JLabel("<html>play <br>pos:</html>", JLabel.RIGHT);
    posText = new JTextField("0",3);
    posLabel.setFont(monoFontSm);
    posText.setFont(monoFontSm);
    blinkmPanel.add(posLabel);
    blinkmPanel.add(posText);

    JButton inputsButton = addButton("inputs", "inputs", mal, blinkmPanel);

  }

  //
  private JButton addButton( String text, String action, ActionListener al,
                            Container container ) {
    JButton button = new JButton(text);
    button.setActionCommand(action);
    button.addActionListener(al);
    button.setAlignmentX(Component.LEFT_ALIGNMENT);
    container.add(Box.createRigidArea(new Dimension(5,5)));;
    container.add(button);
    return button;
  }

} // ScriptToolFrame

