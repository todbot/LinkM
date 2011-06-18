// Copyright (c) 2007-2009, ThingM Corporation
//
// MultiBlinkMSequencerLinkM --  Multi track sequencer for BlinkM using LinkM
// =========================
// 
// A. Use case for LinkM connect + disconnect:
// 1. on startup, scan for linkm.
// 2. if linkm found, 
//    a. connect 
//    b. no dialog
//    c. change connect button to "disconnect"  // ("connected to linkm")
// 3. if linkm NOT found, change button to "connect" 
// 4. if linkm error occurs while in use,
//    a. set connectFailed=true
//    b. change button to "connect failed"
//    c. pop up dialog box on script stop, offering to reconnect
//
// B. Use case for Arduino connect + disconnect:
// 1. on startup, scan for linkm as before, follow steps A1,2,3
// 2. on connect button press, show connect dialog
// 3. connect dialog contains two radio buttons: linkm & arduino w/blinkmcommuni
//    a. arduino select has combobox of serial ports 
// 4. on arduino select
//    a. verify connect
//    b. close dialog
//    c. change connect button to "disconnect" // ("connected to arduino")
// 
// 
// 
// To-do:
// - tune fade time for both real blinkm & preview
// - tune & test other two loop durations 
// - research why timers on windows are slower (maybe use runnable)
// - need to deal with case of *no* serial ports available
//


import java.awt.*;
import java.awt.event.*;

import javax.swing.*;
import javax.swing.event.*;
import javax.swing.colorchooser.*;
import javax.swing.plaf.metal.*;
import java.util.jar.*;

import thingm.linkm.*;


String VERSION = "004";
String versionInfo="version "+VERSION+" \u00a9 ThingM Corporation";
int debugLevel = 1;

Log l = new Log();

LinkM linkm = new LinkM();  // linkm obj only used in this file
BlinkMComm2 blinkmComm = new BlinkMComm2();

boolean connected = false;   // FIXME: verify semantics correct on this
boolean blinkmConnected = false;
boolean arduinoMode = false;  // using Arduino+BlinkMComm instead of LinkM

boolean ctrlmMode = false;
int ctrlmAddr = 9;
int freemAddr = 0;
boolean reconnectMode = false;

long lastConnectCheck;

//String romScriptsDir;  // set to dataPath(".");
//File   romScripts[];   // list of ROM scripts that can fill a track
String silkfontPath = "slkscrb.ttf";  // in "data" directory
String textfontPath = "HelveticaNeue-CondensedBold.ttf";
Font silk8font;
Font textBigfont;
Font textSmallfont;
File lastFile;  // last file (if any) used to save or load

JFrame mf;  // the main holder of the app
JColorChooser colorChooser;
MultiTrackView multitrack;
ButtonPanel buttonPanel;
JPanel connectPanel;
JFileChooser fc;
JLabel statusLabel;
JLabel heartbeatLabel;
JLabel currChanIdLabel;
JLabel currChanLabel;

MenuItem connectItem;

SetChannelDialog setChannelDialog;

final int maxScriptLength = 48;

// number of slices in the timeline == number of script lines written to BlinkM
int numSlices = maxScriptLength;  
int numTracks = 8;    // number of different blinkms

int blinkmStartAddr = 9;

// overall dimensions
int mainWidth  = 900; // 955; //950; //860;
int mainHeight = 490; //630;  // was 455
int mainHeightAdjForWindows = 30; // fudge factor for Windows layout variation
int mainWidthAdjForWindows = 10; // fudge factor for Windows layout variation


// maps loop duration in seconds to per-slice duration and fadespeed,
// both in BlinkM ticks (1/30th of a second, 33.33 msecs)
// 48 slices in a loop, thus each slice is "(duration/48)" secs long
// e.g. 100 sec duration =>  2.0833 secs/slice
// FIXME: something is wrong here.  is tick res really 1/30th sec?
// fadespeed should be chosen so color hits middle of slice
public static class Timing  {
  public int  duration;     // seconds for entire loop
  public byte durTicks;     // per cell duration in ticks (1/30th of a second) 
  public byte fadeSpeed;    // fadespeed between cell in ticks
  public Timing(int d,byte t,byte f) { duration=d; durTicks=t; fadeSpeed=f; }
}

// the supported track durations
// FIXME: some firmwares (maxm) have slightly different timing at the low end
public static Timing[] timings = new Timing [] {
    new Timing(   3, (byte)  2, (byte) 100 ),
    new Timing(  30, (byte) 18, (byte)  25 ),
    new Timing( 100, (byte) 25, (byte)   5 ),
    new Timing( 300, (byte) 75, (byte)   2 ),
    new Timing( 600, (byte)150, (byte)   1 ),
 };

int durationCurrent = timings[0].duration;


PApplet p;
Util util = new Util();  // can't be a static class because of getClass() in it

Color cBlack       = new Color(0,0,0);               // black like my soul
Color cFgLightGray = new Color(230, 230, 230);
Color cBgLightGray = new Color(200, 200, 200); //new Color(0xD1, 0xD3, 0xD4); 
Color cBgMidGray   = new Color(140, 140, 140);
Color cBgDarkGray  = new Color(100, 100, 100);
Color cDarkGray    = new Color( 90,  90,  90);
Color tlDarkGray   = new Color(55,   55,  55);       // dark color for timeline
Color cHighLight   = new Color(255,   0,   0);       // used for selections
Color cBriOrange   = new Color(0xFB,0xC0,0x80);      // bright yellow/orange
Color cMuteOrange  = new Color(0xBC,0x83,0x45);
Color cMuteOrange2 = new Color(0xF1,0x9E,0x34);

Color cEmpty   = tlDarkGray;
// colors for SetChannelDialog
Color[] setChannelColors = new Color [] {
  new Color( 0xff,0x00,0x00 ),
  new Color( 0x00,0xff,0x00 ),
  new Color( 0x00,0x00,0xff ),
  new Color( 0xff,0xff,0x00 ),
  new Color( 0xff,0x00,0xff ),
  new Color( 0x00,0xff,0xff ),
  new Color( 0x80,0xff,0xff ),
  new Color( 0xff,0xff,0xff ),
};

//
// FIXME: no, should let you adjust timeadj & repeats too
// 
String[] startupScriptNames = new String [] {
  "Script 0: Editable script",
  "Script 1: Red->Green->Blue",
  "Script 2: White flash",
  "Script 3: Red flash",
  "Script 4: Green flash",
  "Script 5: Blue flash",
  "Script 6: Cyan flash",
  "Script 7: Magenta flash",
  "Script 8: Yellow flash",
  "Script 9: Black (off)",
  "Script 10: Hue Cycle",
  "Script 11: Mood Light",
  "Script 12: Virtual Candle",
  "Script 13: Water Reflections",
  "Script 14: Old Neon",
  "Script 15: The Seasons",
  "Script 16: Thunderstorm",
  "Script 17: Stop Light",
  "Script 18: SOS",
};

/**
 * Processing's setup()
 */
void setup() {
  size(5, 5);   // Processing's frame, we'll turn off in a bit, must be 1st line
  frameRate(25);   // each frame we can potentially redraw timelines

  l.setLevel( debugLevel );

  try { 
    // load up the lovely silkscreen font
    InputStream in = getClass().getResourceAsStream(silkfontPath);
    Font dynamicFont = Font.createFont(Font.TRUETYPE_FONT, in);
    silk8font = dynamicFont.deriveFont( 8f );

    in = getClass().getResourceAsStream(textfontPath);
    dynamicFont = Font.createFont(Font.TRUETYPE_FONT, in);
    textBigfont = dynamicFont.deriveFont( 16f );
    textSmallfont = dynamicFont.deriveFont( 13f );

    // use a Swing look-and-feel that's the same across all OSs
    MetalLookAndFeel.setCurrentTheme(new DefaultMetalTheme());
    UIManager.setLookAndFeel( new MetalLookAndFeel() );
  } 
  catch(Exception e) { 
    l.error("drat: "+e);
  }

  String osname = System.getProperty("os.name");
  if( !osname.toLowerCase().startsWith("mac") ) {
    mainHeight += mainHeightAdjForWindows;
    mainWidth  += mainWidthAdjForWindows;
  }
  
  p = this;
  
  setupGUI();

  bindKeys();

}

/**
 * Processing's draw()
 */
void draw() {
  if( frameCount < 9 ) {
    super.frame.setVisible(false);  // turn off Processing's frame
    super.frame.toBack();
    mf.setVisible(true);
    mf.toFront();                   // bring ours forward  
  }
  long millis = System.currentTimeMillis();

  if( frameCount > 10 && ((millis-lastConnectCheck) > 1500) ) {
    if( arduinoMode ) {
      heartbeat();
    } 
    else {
      if( verifyLinkM() ) {
        heartbeat();
      }
    }
    lastConnectCheck = millis;
  }

  float millisPerTick = (1/frameRate) * 1000;
  // tick tock
  multitrack.tick( millisPerTick );
  // not exactly 1/frameRate, but good enough for now

  setStatus();

}


/*
 * hmm, maybe can override PApplet.handleDisplay() to get around 
 * Processing startup weirdness
 *
synchronized public void handleDisplay() {
  if( frameCount==0 ) {
    setup();
  }
  else {
    draw();
  }
}
*/

// ----------------------------------------------------------------------------

/**
 *
 */
public void setStatus()
{
  if( arduinoMode ) { 
    if( connected ) {
      setStatus("Connected to Arduino");
      buttonPanel.enableButtons(true);
    } 
    return;
  }
  
  if( connected ) {
    if( blinkmConnected ) {
      setStatus("LinkM connected, BlinkM found");
      buttonPanel.enableButtons(true);
    }
    else {
      setStatus("LinkM connected, no BlinkM found");
      buttonPanel.enableButtons(false);
    }
  } else {
    setStatus( "Disconnected. Plug in LinkM or choose File->Connect for Arduino" );
    buttonPanel.enableButtons(false);
  }
}

/**
 *
 */
public void showHelp() {
    String helpstr = "<html>"+
      "<table border=0 cellpadding=10 cellspacing=10><tr><td>"+
      "<h2> BlinkMSequencer Help </h2>"+
      "<h3> Edit Menu </h3>"+
      "<ul>"+
      "<li>Make Gradient <br/>"+
      "-- create a smooth gradient between start & and colors of a selection"+
      "<li>Edit Channel IDs <br/>"+
      "-- Edit the label and I2C address a channel sends on"+
      "</ul>"+
      "<h3> Tools Menu </h3>"+
      "<ul>"+
      "<li>BlinkM Factory Reset <br/> "+
      "-- Reset BlinkM(s) on selected channels to factory condition"+
      "<li>Set BlinkM Startup Script to... <br/>"+
      "-- Set BlinkM to play a built-in ROM script instead of the programmable one"+
      "<li>Scan I2C Bus <br/> "+
      "-- Scan I2C bus on all I2C addresses, looking for devices"+
      "<li>Change BlinkM I2C Address <br/>"+
      "-- Change the I2C address of the currently selected BlinkM"+
      "<li>Display Versions <br/>"+
      "-- Show LinkM version and BlinKM version for the selected channel"+
      "<li>Reset LinkM <br/>"+
      "-- Perform complete reset of LinkM"+
      "</ul>"+
      "</ul>"+
      "</td></tr></table>"+
      "</html>\n";

    JDialog dialog = new JDialog(mf, "BlinkMSequencer Help", false);
    
    JPanel panel = new JPanel(new BorderLayout());
    panel.setBackground(cBgLightGray); //sigh, gotta do this on every panel
    panel.setBorder( BorderFactory.createMatteBorder(10,10,10,10, cBgDarkGray));
    JLabel help = new JLabel(helpstr);
    panel.add( new JLabel(helpstr) );

    dialog.getContentPane().add(panel);

    dialog.setPreferredSize( new Dimension(600,450));
    dialog.setResizable(false);
    dialog.setLocationRelativeTo(mf); // center it on the BlinkMSequencer
    dialog.pack();
    dialog.setVisible(true);

}

/**
 *
 */
public void displayVersions() {
  //if( !connected ) return;
  String msg = "Versions:\n";

  Track t = multitrack.getCurrTrack();
  int addr = t.blinkmaddr;
  try { 
    msg += "LinkM : ";
    byte[] linkmver  = linkm.getLinkMVersion();
    if( linkmver != null ) {
      msg += "0x"+ hex(linkmver[0]) + ", 0x"+ hex(linkmver[1]);
    } else {
      msg += "-could not be read-";
    }
    msg += "\n";
  } catch( IOException ioe ) {
    msg += "-No BlinkM-\n";
  }
   
  try {
    msg += "BlinkM : ";
    if( addr != -1 ) {
      byte[] blinkmver = linkm.getVersion( addr );
      if( blinkmver != null ) { 
        msg += (char)blinkmver[0]+","+(char)blinkmver[1];
      } else {
        msg += "-could not be read-\n";
      }
    }
    msg += "   (trk:"+(multitrack.currTrack+1)+", addr:"+addr +")\n";
  } catch( IOException ioe ) {
    msg += "-No BlinkM-\n";
  }

  if( arduinoMode ) {
    msg = "Display Versions only supported with LinkM.";
  }
  JOptionPane.showMessageDialog(mf, msg, "LinkM / BlinkM Versions",
                                JOptionPane.INFORMATION_MESSAGE);
}

/**
 *
 */
public void upgradeLinkMFirmware() {
  l.debug("upgradeLinkMFirmware");
  String msg = "-disabled. please use command-line tool-";
  /*
  linkm.goBootload();
  linkm.delay(2000);
  linkm.bootload("link.hex",true);
  */
  JOptionPane.showMessageDialog(mf, msg, "Upgrade LinkM Firmware",
                                JOptionPane.INFORMATION_MESSAGE);
}

/**
 *
 */
public void resetLinkM() {
  l.debug("resetLinkM");
  if( multitrack.playing ) multitrack.reset();
  if( connected ) linkm.close();

  String msg = "Reset LinkM...";
  try { 
    linkm.open();
  } catch( IOException ioe ) {
    msg += "\ncouldn't open LinkM";
    linkm = null;
  }
  try { 
    if( linkm!=null ) linkm.goBootload();
  } catch( IOException ioe ) {
    msg += "\ncouldn't switch to LinkMBoot mode\n";
  }

  linkm.pause(3000);
  try { 
    if( linkm!=null ) linkm.bootloadReset();
  } catch(IOException ioe ) {
    println("oops " +ioe);
    msg += "\ncouldn't switch back to LinkM mode\n";
  }

  connect(true);

  msg += "done";
  JOptionPane.showMessageDialog(mf, msg, "Reset LinkM",
                                JOptionPane.INFORMATION_MESSAGE);
}

/**
 *
 */
public void doI2CScan() {
  l.debug("doI2CScan");
  int start_addr = 1;
  int end_addr = 113;
  //String msg = "no devices found";
  HashSet addrset = new HashSet();
  byte[] addrs  = null;
  try {
    if( arduinoMode ) {
      addrs = blinkmComm.i2cScan( start_addr, end_addr );
    } else { 
      addrs = linkm.i2cScan( start_addr, end_addr);
    }

    int cnt = addrs.length;
    if( cnt>0 ) {
      //msg = "Found "+cnt+" devices:\n";
      for( int i=0; i<cnt; i++) {
        byte a = addrs[i];
        addrset.add( new Integer(a) );
        //msg += "addr: "+a;
      }
      //msg += "\nDone.";
    }
  } catch( IOException ioe) {
    JOptionPane.showMessageDialog(mf,
                                  "No LinkM found.\nI2C Scan cancelled.\n"+
                                  "Plug LinkM in at any time and try again.",
                                  "LinkM Not Found",
                                  JOptionPane.WARNING_MESSAGE);
    return;
  }

  // ugh, surely there's a better way to do this
  int stride = (end_addr-start_addr)/4;
  JPanel panel = new JPanel();
  panel.setLayout( new GridLayout( 2+stride, 8, 5,5) );
  panel.setBackground(cBgDarkGray); //sigh, gotta do this on every panel
  panel.setBorder( BorderFactory.createEmptyBorder(20,20,20,20) );
  JLabel lh1a = new JLabel("addr");  //lh1a.setFont(silk8font);
  JLabel lh1b = new JLabel("dev");   //lh1b.setFont(silk8font);
  JLabel lh2a = new JLabel("addr");  //lh2a.setFont(silk8font);
  JLabel lh2b = new JLabel("dev");   //lh2b.setFont(silk8font);
  JLabel lh3a = new JLabel("addr");  //lh3a.setFont(silk8font);
  JLabel lh3b = new JLabel("dev");   //lh3b.setFont(silk8font);
  JLabel lh4a = new JLabel("addr");  //lh4a.setFont(silk8font);
  JLabel lh4b = new JLabel("dev");   //lh4b.setFont(silk8font);
  panel.add( lh1a );  panel.add( lh1b );
  panel.add( lh2a );  panel.add( lh2b );
  panel.add( lh3a );  panel.add( lh3b );
  panel.add( lh4a );  panel.add( lh4b );
  int i = 0;
  do { 
    Integer a1 = start_addr+(stride*0) + i;
    Integer a2 = start_addr+(stride*1) + i;
    Integer a3 = start_addr+(stride*2) + i;
    Integer a4 = start_addr+(stride*3) + i;
    String r1 = (addrset.contains(a1)) ? "x" : ".";
    String r2 = (addrset.contains(a2)) ? "x" : ".";
    String r3 = (addrset.contains(a3)) ? "x" : ".";
    String r4 = (addrset.contains(a4)) ? "x" : ".";

    JLabel l1a = new JLabel(""+a1);    //l1a.setFont(silk8font) ;
    JLabel l1b = new JLabel(r1);       //l1b.setFont(silk8font) ;
    JLabel l2a = new JLabel(""+a2);    //l2a.setFont(silk8font) ;
    JLabel l2b = new JLabel(r2);       //l2b.setFont(silk8font) ;
    JLabel l3a = new JLabel(""+a3);    //l3a.setFont(silk8font) ;
    JLabel l3b = new JLabel(r3);       //l3b.setFont(silk8font) ;
    JLabel l4a = new JLabel(""+a4);    //l4a.setFont(silk8font) ;
    JLabel l4b = new JLabel(r4);       //l4b.setFont(silk8font) ;
    panel.add( l1a );  panel.add( l1b );
    panel.add( l2a );  panel.add( l2b );
    panel.add( l3a );  panel.add( l3b );
    panel.add( l4a );  panel.add( l4b );
    i++;
  } while( i < stride );


  JDialog dialog = new JDialog(mf, "I2C Bus Scan Results", false);
  dialog.getContentPane().add(panel);
  //dialog.setPreferredSize( new Dimension(200,400));
  dialog.setResizable(false);
  dialog.setLocationRelativeTo(null); // center it on the BlinkMSequencer
  dialog.pack();
  dialog.setVisible(true);
  
} // doI2Cscan

/**
 *
 */
public void doFactoryReset() { 
  l.debug("doFactoryReset");
  Track t = multitrack.getCurrTrack();
  int addr = t.blinkmaddr;
  String msg = "No BlinkM selected!";
  if( addr != -1 ) {
    try { 
      if( arduinoMode ) {
        blinkmComm.doFactoryReset(addr);
        blinkmComm.playScript(addr);
      } else {
        linkm.doFactoryReset(addr);
        linkm.playScript(addr);
      }
      msg = "BlinkM reset to factory defaults";
    } catch(IOException ioe ) {
      msg = "Error talking to BlinkM";
    }
  }
  JOptionPane.showMessageDialog(mf, msg, "LinkM Factory Reset",
                                JOptionPane.INFORMATION_MESSAGE);
  try {
    if( arduinoMode ) {
      blinkmComm.off(addr);
    } else { 
      linkm.off(addr);
    }
  } catch(IOException ioe) {}

}

/**
 *
 */
public void setBootScript( int scriptnum ) {
  int fadespeed = 8; // default in blinkm_nonvol.h
  if( !connected ) return;

  int addr = multitrack.getCurrTrack().blinkmaddr;
  String msg = "No BlinkM selected!";
  if( addr != -1 ) {
    try { 
      if( arduinoMode ) { 
        blinkmComm.setStartupParams( addr, 1, scriptnum, 0, fadespeed, 0);
        blinkmComm.setFadeSpeed( addr, fadespeed);
        blinkmComm.playScript( addr, scriptnum, 0,0 );
      }
      else { 
        // set boot params   addr, mode,script_id,reps,fadespeed,timeadj
        linkm.setStartupParams( addr, 1, scriptnum, 0, fadespeed, 0 );
        linkm.setFadeSpeed( addr, fadespeed);
        linkm.playScript( addr, scriptnum, 0,0 );
      }

      msg = "BlinkM at addr#"+addr+" set to light script #"+scriptnum;

    } catch(IOException ioe ) {
      msg = "Error talking to BlinkM";
    }
  } // good addr

  JOptionPane.showMessageDialog(mf, msg, "BlinkM Script Set",
                                JOptionPane.INFORMATION_MESSAGE);

  try {
    if( arduinoMode ) {
      blinkmComm.off(addr);
    } else { 
      linkm.off(addr);
    }
  } catch(IOException ioe) {}

  
}

static int verifyCount = 0;
/**
 * Verify a LinkM is present
 * @return true if LinkM is present, regardless of 'connected' status
 */
public boolean verifyLinkM() {
  //if( multitrack.playing ) return true;  // punt if playing
  if( multitrack.playing && reconnectMode == false ) return true;
  //l.debug("verifyLinkM:"+verifyCount++);
  if( connected ) {
    try {
      linkm.getLinkMVersion();
      l.debug("verifyLinkM: connected");
      return true;  // if above completes, we're truly connected
    } catch(IOException ioe) {
      l.debug("verifyLinkM:closing and connected");
      connected = false;
      //linkm.close();  // FIXME FIXME FIXME: this causes dump for i2cScan()
    }
  }
  else {  // else, we're not connected, so try a quick open and close
    try {
      l.debug("verifyLinkM: not connected, trying open");
      linkm.open();
      linkm.getLinkMVersion();
    } catch( IOException ioe ) {
      return false;
    }

    l.debug("verifyLinkM:connecting");
    connect(false);
  }
  return true;
}

/**
 * Open up the LinkM and set it up if it hasn't been
 * Sets and uses the global variable 'connected'
 */
public boolean connect(boolean openlinkm) {
  l.debug("connect");
  try { 
    if( openlinkm ) linkm.open();
    linkm.i2cEnable(true);
    byte[] addrs = linkm.i2cScan(1,113);
    int cnt = addrs.length;
    if( cnt>0 ) {
      /*
      multitrack.disableAllTracks();   // enable tracks for blinkms found
      for( int i=0; i<cnt; i++) {
        byte a = addrs[i];
        if( a >= blinkmStartAddr && a < blinkmStartAddr + numTracks ) {
          multitrack.toggleTrackEnable( a - blinkmStartAddr);
        }
      }

      // FIXME: should dialog popup saying blinkms found but not in right addr?
      if( addrs[0] > blinkmStartAddr ) { // FIXME: hack
        int trknum = (addrs[0] - blinkmStartAddr);  // select 1st used trk
        multitrack.currTrack = trknum;
        multitrack.selectSlice( trknum, 0, true );
        multitrack.repaint();
      }
      */
      linkm.pause(1500);

      ctrlmAddr = 9;
      freemAddr = 0;

      linkm.ctrlmSetSendAddress( ctrlmAddr, freemAddr, 0 );

      linkm.stopScript( 0 ); // stop all scripts
      linkm.fadeToRGB(0, 0,0,0);
     
      blinkmConnected = true;
    }
    else {
      l.debug("no blinkm found!"); 
      blinkmConnected = false;
    }
  } catch(IOException ioe) {
    l.debug("connect: no linkm?  "+ioe);
    /*
    JOptionPane.showMessageDialog(mf,
                                  "No LinkM found.\n"+
                                  "Plug LinkM in at any time and "+
                                  "it will auto-connect.",
                                  "LinkM Not Found",
                                  JOptionPane.WARNING_MESSAGE);
    */
    //disconnectedMode = true;
    connected = false;
    return false;
  }
  connected = true;
  return true; // connect successful
}



/**
 * Sends a single color to a single BlinkM, using the "Fade to RGB" function
 * Used during live playback and making blinkm match preview
 * @param blinkmAddr  i2c address of a blinkm
 * @param c color to send
 */
public void sendBlinkMColor( int blinkmAddr, Color c ) {
  //l.debug("sendBlinkMColor: "+blinkmAddr+" - "+c);
  if( c == cEmpty ) c = Color.BLACK;  // empty is off
  if( !connected ) return;

  try { 
    if( arduinoMode ) {
      blinkmComm.fadeToRGB( blinkmAddr, c );
    } else { 
      if( ctrlmMode ) { 
        linkm.ctrlmSetSendAddress( ctrlmAddr, freemAddr, blinkmAddr );
        linkm.fadeToRGB( ctrlmAddr, c );
      } else { 
        linkm.fadeToRGB( blinkmAddr, c);  // FIXME:  which track 
      }
    }
  } catch( IOException ioe) {        // hmm, what to do here
    connected = false;
  }
  return;
}

/**
 *
 */
public void sendBlinkMColors( int addrs[], Color colors[], int send_count ) {
  //l.debug("sendBlinkMColors "+send_count);
  if( !connected ) return;
  long st = System.currentTimeMillis();

  try { 
    for( int i=0; i<send_count; i++) {
      if( addrs[i]!=-1 ) {
        if( arduinoMode ) { 
          blinkmComm.fadeToRGB( addrs[i], colors[i] );
        } else { 
          if( ctrlmMode ) {
            linkm.ctrlmSetSendAddress( ctrlmAddr, freemAddr, addrs[i] );
            linkm.fadeToRGB( ctrlmAddr, colors[i] );
          } else { 
            linkm.fadeToRGB( addrs[i], colors[i] );
          }
        }
      }
    }
    //linkm.fadeToRGB( addrs, colors, send_count );
  } catch( IOException ioe ) {
    connected = false;
    return;
  }
  long et = System.currentTimeMillis();
  if( debugLevel>2) l.debug("time to SendBlinkMColors: "+(et-st)+" millisecs");
  // FIXME: bad debug logic here
  return;
}

/**
 *
 */
public void prepareForPreview() {
  prepareForPreview(durationCurrent);
}

/**
 * Prepare blinkm for playing preview scripts
 * @param loopduration duration of loop in milli
 */
public void prepareForPreview(int loopduration) {
  byte fadespeed = getFadeSpeed(loopduration);
  l.debug("prepareForPreview: fadespeed:"+fadespeed);
  if( !connected ) return;
  //if( !connected ) connect(); // no, fails for case of unplug
  //if( checkForLinkM() ) connect(); // hmm gives weird no-playing failure modes

  int blinkmAddr = 0x00;  // FIXME: ????
  try { 
    if( arduinoMode ) { 
      blinkmComm.stopScript( blinkmAddr );
      blinkmComm.setFadeSpeed( blinkmAddr, fadespeed );
    } else { 
      linkm.stopScript( blinkmAddr );
      linkm.setFadeSpeed( blinkmAddr, fadespeed );
    }
  } catch(IOException ioe ) {
    // FIXME: hmm, what to do here
    l.debug("prepareForPreview: "+ioe);
    connected = false;
  }
}

/**
 * What happens when "download" button is pressed
 */
public boolean doDownload() {
  BlinkMScript script;
  BlinkMScriptLine scriptLine;
  Color c;
  int blinkmAddr;
  for( int j=0; j< numTracks; j++ ) {
    boolean active = multitrack.tracks[j].active;
    if( !active ) continue; 
    blinkmAddr = multitrack.tracks[j].blinkmaddr;
    try { 
      if( arduinoMode ) {
        script = blinkmComm.readScript( blinkmAddr, 0, true );
      } else {
        script = linkm.readScript( blinkmAddr, 0, true );  // read all
      }
      int len = (script.length() < numSlices) ? script.length() : numSlices;
      for( int i=0; i< len; i++) {
        scriptLine = script.get(i);
        // FIXME: maybe move this into BlinkMScriptLine
        if( scriptLine.cmd == 'c' ) {  // only pay attention to color cmds
          c = new Color( scriptLine.arg1,scriptLine.arg2,scriptLine.arg3 );
          //println("c:"+c+","+Color.BLACK); // FIXME: why isn't this equal?
          if( c == Color.BLACK ) { c = cEmpty; println("BLACK!"); }
          multitrack.tracks[j].slices[i] = c;
        }
      }
      multitrack.repaint();
    } catch( IOException ioe ) {
      l.error("doDownload: on track #"+j+",addr:"+blinkmAddr+"  "+ioe);
      connected = false;
    }
  }
  return true;
}

/**
 * What happens when "upload" button is pressed
 */
public boolean doUpload(JProgressBar progressbar) {
  if( !connected ) return false;
  multitrack.stop();
  boolean rc = false;

  int durticks = getDurTicks();
  int fadespeed = getFadeSpeed();
  int reps = (byte)((multitrack.looping) ? 0 : 1);  

  BlinkMScriptLine scriptLine;
  Color c;
  int blinkmAddr;

  for( int j=0; j<numTracks; j++ ) {
    if( ! multitrack.tracks[j].active ) continue;  // skip disabled tracks
    blinkmAddr = multitrack.tracks[j].blinkmaddr; // get track i2c addr
    
    try { 
      for( int i=0; i<numSlices; i++) {
        c =  multitrack.tracks[j].slices[i];         
        if( c == cEmpty )
          c = cBlack;
        
        scriptLine = new BlinkMScriptLine( durticks, 'c', c.getRed(),
                                           c.getGreen(),c.getBlue());
        if( arduinoMode ) {
          blinkmComm.writeScriptLine( blinkmAddr, i, scriptLine);
        } else { 
          if( ctrlmMode ) { 
            linkm.ctrlmSetSendAddress( ctrlmAddr, freemAddr, blinkmAddr );
            linkm.writeScriptLine( ctrlmAddr, i, scriptLine);
          } else { 
            linkm.writeScriptLine( blinkmAddr, i, scriptLine);
          }
        }
        if( progressbar !=null) progressbar.setValue(i);  // hack
      }
      
      if( arduinoMode ) { 
        blinkmComm.setScriptLengthRepeats( blinkmAddr, numSlices, reps );
        blinkmComm.setStartupParams( blinkmAddr, 1, 0, 0, fadespeed, 0 );
        blinkmComm.setFadeSpeed( blinkmAddr, fadespeed);
      }
      else { 
        if( ctrlmMode ) {
          linkm.ctrlmSetSendAddress( ctrlmAddr, freemAddr, blinkmAddr );
          linkm.setScriptLengthRepeats( ctrlmAddr, numSlices, reps);
          linkm.setStartupParams( ctrlmAddr, 1, 0, 0, fadespeed, 0 );
          linkm.setFadeSpeed( ctrlmAddr, fadespeed);
        } else { 
          // set script length     cmd   id         length         reps
          linkm.setScriptLengthRepeats( blinkmAddr, numSlices, reps);
          // set boot params   addr, mode,id,reps,fadespeed,timeadj
          linkm.setStartupParams( blinkmAddr, 1, 0, 0, fadespeed, 0 );
          // set playback fadespeed
          linkm.setFadeSpeed( blinkmAddr, fadespeed);
        }
      }
    } catch( IOException ioe ) { 
      l.error("upload error for blinkm addr "+blinkmAddr+ " : "+ioe);
    }
    
  } // for numTracks
  
  try { 
    // and play the script on all blinkms
    if( arduinoMode ) {
      blinkmComm.playScript( 0 );
    } else { 
      linkm.playScript( 0 );  // FIXME:  use LinkM to syncM
    }
    rc = true;
  } catch( IOException ioe ) { 
    l.error("upload error: "+ioe);
    rc = false;
    connected = false;
  }

  return rc;
}


/**
 * Open the edit chanel id and label dialog
 */
public void doTrackDialog(int track) {
  multitrack.reset(); // stop preview script
  
  setChannelDialog.setVisible(true);
  
  multitrack.reset();
  multitrack.repaint();

}


/**
 * Change the I2C address of the currently selected BlinkM
 */
public void doAddressChange() {
  int curraddr = multitrack.getCurrTrack().blinkmaddr;

  String question = 
    "Change address of current BlinkM \n"+
    "from address '"+curraddr+"' to :";
  String s = (String)JOptionPane.showInputDialog(mf, 
                                                 question, 
                                                 "BlinkM Readdressing",
                                                 JOptionPane.PLAIN_MESSAGE,
                                                 null,
                                                 null, new Integer(curraddr));
  if( s == null || s.length()==0 ) {  // no selection
    return;
  }
  int newaddr = Integer.parseInt(s);
  if( newaddr <= 0 && newaddr > 113 ) {  // bad value
    return;
  }

  try { 
    if( arduinoMode ) { 
      //blinkmComm.setAddress( curraddr, newaddr );
    } else {
      linkm.setAddress( curraddr, newaddr ); 
    }
    //multitrack.getCurrTrack().blinkmaddr = newaddr;  
  } catch( IOException ioe ) {
    JOptionPane.showMessageDialog(mf,
                                  "Could not set BlinkM addres.\n"+ioe,
                                  "BlinkM Readdress failure",
                                  JOptionPane.WARNING_MESSAGE);
  }
  
}





// ----------------------------------------------------------------------------

/**
 * Load current track from a file.
 * Opens up a OpenDialog
 */
void loadTrack() { 
  loadTrack( multitrack.currTrack );
}

/**
 * Loads specified file (if possible) into current track
 */
void loadTrack(File file) {
  loadTrackWithFile( multitrack.currTrack, file );
}

/**
 * Load a text file containing a light script, turn it into BlinkMScriptLines
 * Opens up a OpenDialog then loads into track tracknum
 */
void loadTrack(int tracknum) {
  int returnVal = fc.showOpenDialog(mf);  // this does most of the work
  if (returnVal != JFileChooser.APPROVE_OPTION) {
    return;
  }
  File file = fc.getSelectedFile();
  lastFile = file;
  loadTrackWithFile( tracknum, file );
}

/**
 *
 */
void loadTrackWithFile(int tracknum, File file) {
  l.debug("loadTrackWithFile:"+tracknum+","+file);
  if( file != null ) {
    String[] lines = LinkM.loadFile( file );
    BlinkMScript script = LinkM.parseScript( lines );
    if( script == null ) {
      l.error("loadTrack: bad format in file");
      return;
    }
    script = script.trimComments(); 
    int len = script.length();
    if( len > numSlices ) {      // danger!
      len = numSlices;           // cut off so we don't overrun
    }
    int j=0;
    for( int i=0; i<len; i++ ) { 
      BlinkMScriptLine sl = script.get(i);
      if( sl.cmd == 'c' ) { // if color command
        Color c = new Color( sl.arg1, sl.arg2, sl.arg3 );
        multitrack.tracks[tracknum].slices[j++] = c;
      }
    }
    multitrack.repaint();  // hmm
  }
}

/**
 * Load all tracks from a file
 */
void loadAllTracks() {
  multitrack.deselectAllTracks();
  fc.setSelectedFile(lastFile);
  int returnVal = fc.showOpenDialog(mf); 
  if (returnVal != JFileChooser.APPROVE_OPTION) {
    return;
  }
  File file = fc.getSelectedFile();
  lastFile = file;
  if( file != null ) {
    //LinkM.debug = 1;
    String[] lines = LinkM.loadFile( file );
    if( lines == null ) println(" null lines? ");
    BlinkMScript scripts[] = LinkM.parseScripts( lines );
    if( scripts == null ) {
      System.err.println("loadAllTracks: bad format in file");
      return;
    }

    for( int k=0; k<scripts.length; k++) { 
      BlinkMScript script = scripts[k];
      //println(i+":\n"+scripts[i].toString());
      script = script.trimComments(); 
      int len = script.length();
      if( len > numSlices ) {      // danger!
        len = numSlices;           // cut off so we don't overrun
      }
      int j=0;
      for( int i=0; i<len; i++ ) { 
        BlinkMScriptLine sl = script.get(i);
        if( sl.cmd == 'c' ) { // if color command
          Color c = new Color( sl.arg1, sl.arg2, sl.arg3 );
          multitrack.tracks[k].slices[j++] = c;
        }
      }
    }

  } //if(file!=null)
  multitrack.repaint();
}

/**
 * Save the current track to a file
 */
void saveTrack() {
  saveTrack( multitrack.currTrack );
}

/**
 * Save a track to a file
 */
void saveTrack(int tracknum) {
  if( lastFile!=null ) fc.setSelectedFile(lastFile);
  int returnVal = fc.showSaveDialog(mf);  // this does most of the work
  if( returnVal != JFileChooser.APPROVE_OPTION) {
    return;  // FIXME: need to deal with no .txt name no file saving
  }
  File file = fc.getSelectedFile();
  lastFile = file;
  if (file.getName().endsWith("txt") ||
      file.getName().endsWith("TXT")) {
    BlinkMScript script = new BlinkMScript();
    Color[] slices = multitrack.tracks[tracknum].slices;
    int durTicks = getDurTicks();
    for( int i=0; i< slices.length; i++) {
      Color c = slices[i];
      int r = c.getRed()  ;
      int g = c.getGreen();
      int b = c.getBlue() ;
      script.add( new BlinkMScriptLine( durTicks, 'c', r,g,b) );
    }    
    LinkM.saveFile( file, script.toString() );
  }
}

/**
 *
 */
void saveAllTracks() {
  if( lastFile!=null ) fc.setSelectedFile(lastFile);
  int returnVal = fc.showSaveDialog(mf);  // this does most of the work
  if( returnVal != JFileChooser.APPROVE_OPTION) {
    return;  // FIXME: need to deal with no .txt name no file saving
  }
  File file = fc.getSelectedFile();
  // hack to make sure file always ends in .txt
  String fnameabs = file.getAbsolutePath();
  if( !(fnameabs.endsWith("txt") || fnameabs.endsWith("TXT")) ) {
    fnameabs = fnameabs + ".txt";
    file = new File( fnameabs );
  }

  lastFile = file;
  if (file.getName().endsWith("txt") ||
      file.getName().endsWith("TXT")) {

    StringBuffer sb = new StringBuffer();
    
    for( int k=0; k<numTracks; k++ ) {
      BlinkMScript script = new BlinkMScript();
      Color[] slices = multitrack.tracks[k].slices;
      int durTicks = getDurTicks();
      for( int i=0; i< slices.length; i++) {
        Color c = slices[i];
        int r = c.getRed()  ;
        int g = c.getGreen();
        int b = c.getBlue() ;
        script.add( new BlinkMScriptLine( durTicks, 'c', r,g,b) );
      }
      sb.append("{\n");
      sb.append( script.toString() );  // render track to string
      sb.append("}\n");
    }

    LinkM.saveFile( file, sb.toString() );  
  }
}

// ---------------------------------------------------------------------------

/**
 * Sets status label at bottom of mainframe
 */
void setStatus(String status) {
    statusLabel.setText( status );
}
/**
 * Toggle a little dot on the bottom bar to indicate aliveness
 */
void heartbeat() {
  String s = heartbeatLabel.getText();
  s = (s.equals(".")) ? " " : "."; // toggle
  heartbeatLabel.setText(s);
}

/**
 * Updates the current channel info at top of mainframe
 */
void updateInfo() {
  //for( int i=0;
  Track trk = multitrack.tracks[multitrack.currTrack];
  currChanIdLabel.setText( String.valueOf(trk.blinkmaddr) );
  currChanLabel.setText( trk.label );
  multitrack.repaint();
  repaint();
}

/**
 * Creates all the GUI elements
 */
void setupGUI() {

  setupMainframe();  // creates 'mf'

  Container mainpane = mf.getContentPane();
  BoxLayout layout = new BoxLayout( mainpane, BoxLayout.Y_AXIS);
  mainpane.setLayout(layout);

  JPanel chtop     = makeChannelsTopPanel();

  multitrack       = new MultiTrackView( mainWidth,300 );

  // controlsPanel contains colorpicker and all buttons
  JPanel controlsPanel = makeControlsPanel();
  JPanel bottomPanel = makeBottomPanel();

  // add everything to the main pane, in order
  mainpane.add( chtop );
  mainpane.add( multitrack );
  mainpane.add( controlsPanel );
  mainpane.add( bottomPanel );

  //mf.setVisible(true);
  mf.setResizable(false);

  fc = new JFileChooser( System.getProperty("user.home")  ); 
  fc.setFileFilter( new javax.swing.filechooser.FileFilter() {
      public boolean accept(File f) {
        if(f.isDirectory()) return true;
        if (f.getName().toLowerCase().endsWith("txt") ) return true;
        return false;
      }
      public String getDescription() { return "TXT files";  }
    }
    );
  
  setChannelDialog = new SetChannelDialog(); // defaults to invisible
  updateInfo();
}

/**
 * Make the panel that contains "CHANNELS" and the current channel info
 */
JPanel makeChannelsTopPanel() {
  JPanel p = new JPanel();
  p.setBackground(cBgLightGray);  
  p.setLayout( new BoxLayout(p, BoxLayout.X_AXIS) );
  p.setBorder(BorderFactory.createEmptyBorder(2, 2, 2, 2));

  ImageIcon chText = util.createImageIcon("blinkm_text_channels_fixed.gif",
                                          "CHANNELS");
  JLabel chLabel = new JLabel(chText);
  JLabel currChanIdText = new JLabel("CURRENT CHANNEL ID:");
  currChanIdText.setFont( textBigfont );
  currChanIdLabel = new JLabel("--");
  currChanIdLabel.setFont(textBigfont);
  JLabel currChanLabelText = new JLabel("LABEL:");
  currChanLabelText.setFont(textBigfont);
  currChanLabel = new JLabel("-nuh-");
  currChanLabel.setFont(textBigfont);

  p.addMouseListener(new MouseAdapter() {
      public void mouseClicked(MouseEvent me) {
        doTrackDialog(0);  // open up change track functionality
      }
    });

  p.add( Box.createRigidArea(new Dimension(25,0) ) );
  p.add(chLabel);
  p.add(Box.createHorizontalStrut(10));
  p.add(currChanIdText);
  p.add(Box.createHorizontalStrut(5));
  p.add(currChanIdLabel);
  p.add(Box.createHorizontalStrut(10));
  p.add(currChanLabelText);
  p.add(Box.createHorizontalStrut(5));
  p.add(currChanLabel);
  p.add(Box.createHorizontalGlue());  // boing

  return p;
}

/**
 * Make the controlsPanel that contains colorpicker and all buttons
 */
JPanel makeControlsPanel() {
  JPanel colorChooserPanel = makeColorChooserPanel();
  buttonPanel       = new ButtonPanel(); //380, 280);

  JPanel controlsPanel = new JPanel();
  controlsPanel.setBackground(cBgDarkGray); //sigh, gotta do this on every panel
  //controlsPanel.setBorder(BorderFactory.createMatteBorder(10,0,0,0,cBgDarkGray));
  //controlsPanel.setBorder(BorderFactory.createCompoundBorder(  // debug
  //                 BorderFactory.createLineBorder(Color.blue),
  //                 controlsPanel.getBorder()));
  controlsPanel.setLayout(new BoxLayout(controlsPanel, BoxLayout.X_AXIS));
  controlsPanel.add( colorChooserPanel );
  controlsPanel.add( buttonPanel );
  controlsPanel.add( Box.createHorizontalGlue() );
  return controlsPanel;
}

/**
 * Makes and sets up the colorChooserPanel
 */
JPanel makeColorChooserPanel() { 
  FixedColorSelectionModel fixedModel = new FixedColorSelectionModel();

  colorChooser = new JColorChooser(fixedModel);

  colorChooser.setBackground(cBgDarkGray);
  colorChooser.getSelectionModel().addChangeListener( new ChangeListener() {
      public void stateChanged(ChangeEvent e) {
        Color c = colorChooser.getColor();
        multitrack.setSelectedColor(c);
      }
    });

  colorChooser.setPreviewPanel( new JPanel() ); // we have our custom preview
  colorChooser.setColor( cEmpty );

  JPanel colorChooserPanel = new JPanel();   // put it in its own panel for why?
  colorChooserPanel.setBackground(cBgDarkGray);  
  colorChooserPanel.add( Box.createVerticalStrut(5) );
  colorChooserPanel.add( colorChooser );

  colorChooser.addMouseListener( new MouseAdapter() {
      public void mouseClicked(MouseEvent e) {
        println("CLICKY");
      }
    });
  return colorChooserPanel;
}

/**
 * Make the bottom panel, it contains version & copyright info and status line
 */
JPanel makeBottomPanel() {
  JLabel versionLabel = new JLabel(versionInfo, JLabel.LEFT);
  statusLabel = new JLabel("status");
  heartbeatLabel = new JLabel(" ");
  versionLabel.setHorizontalAlignment(JLabel.LEFT);
  JPanel bp = new JPanel();
  bp.setBackground(cBgMidGray);
  bp.setLayout( new BoxLayout( bp, BoxLayout.X_AXIS) );
  bp.add( Box.createHorizontalStrut(10) );
  bp.add( versionLabel );
  bp.add( Box.createHorizontalGlue() );
  bp.add( heartbeatLabel );
  bp.add( Box.createHorizontalStrut(5) );
  bp.add( statusLabel );
  bp.add( Box.createHorizontalStrut(25) );
  return bp;
}

/**
 * Create the containing frame (or JDialog in this case) 
 */
void setupMainframe() {
  mf = new JFrame( "BlinkM Sequencer" );
  mf.setBackground(cBgDarkGray);
  mf.setFocusable(true);
  mf.setSize( mainWidth, mainHeight);
  Frame f = mf;

  Toolkit tk = Toolkit.getDefaultToolkit();
  // FIXME: why doesn't either of these seem to work
  //ImageIcon i = new Util().createImageIcon("blinkm_thingm_logo.gif","title");
  //f.setIconImage(i.getImage());
  f.setIconImage(tk.getImage("blinkm_thingm_logo.gif"));

  // handle window close events
  mf.addWindowListener(new WindowAdapter() {
      public void windowClosing(WindowEvent e) {
        mf.dispose();          // close mainframe
        p.destroy();           // close processing window as well
        p.frame.setVisible(false); // hmm, seems out of order
        System.exit(0);
      }
    });
  
  // center MainFrame on the screen and show it
  Dimension scrnSize = tk.getScreenSize();
  mf.setLocation(scrnSize.width/2 - mf.getWidth()/2, 
                 scrnSize.height/2 - mf.getHeight()/2);
  setupMenus(f);
}


/**
 * The main menu and hotkey listener
 */
ActionListener menual = new ActionListener() { 
    void actionPerformed(ActionEvent e) {
      String cmd = e.getActionCommand();
      l.debug("action listener: "+cmd);
      if(        cmd.equals("Quit") )  {
        System.exit(0);
      } else if( cmd.equals("Connect to Arduino") ) {
        blinkmComm.connectDialog();
        connectItem.setLabel("Disconnect from Arduino");        
      } else if( cmd.equals("Disconnect from Arduino") ) {
        blinkmComm.disconnectDialog();
        connectItem.setLabel("Connect to Arduino");
      } else if( cmd.equals("Load Set") ) {  // FIXME: such a hack
        loadAllTracks();
      } else if( cmd.equals("Save Set") ) { 
        saveAllTracks();
      } else if( cmd.equals("Load One Track") ) {
        loadTrack();
      } else if( cmd.equals("Save One Track") ) {
        saveTrack();
      } else if( cmd.equals("Cut") ) {
        multitrack.cut();
      } else if( cmd.equals("Copy") ) {
        multitrack.copy();
      } else if( cmd.equals("Paste") ) {
        multitrack.paste();
      } else if( cmd.equals("Delete") ) {
        multitrack.delete();
      } else if( cmd.equals("Select All in Track") ) {
        multitrack.selectAllinTrack();
      } else if( cmd.equals("Make Gradient") ) {
        multitrack.makeGradient();
      } else if( cmd.equals("Edit Channel IDs") ) {
        doTrackDialog(0);
      } else if( cmd.equals("Display LinkM/BlinkM Versions") ) {
        displayVersions();
      } else if( cmd.equals("Upgrade LinkM Firmware") ) {
        upgradeLinkMFirmware();
      } else if( cmd.equals("Reset LinkM") ) {
        resetLinkM();
      } else if( cmd.equals("BlinkM Factory Reset") ) {
        doFactoryReset();
      } else if( cmd.equals("Scan I2C Bus") ) {
        doI2CScan();
      } else if( cmd.equals("Change BlinkM I2C Address") ) {
        doAddressChange();
      } else if( cmd.equals("Help") ) {
        showHelp();
      } else if( cmd.equals("Quick Start Guide") ) {
        p.link("http://blog.thingm.com/2010/05/blinkm-hello-video-guides-example-code/", "_blank"); 
      } else if( cmd.startsWith("Script ") ) { // predef script
        int scriptnum = 0;
        String snum = cmd.substring("Script ".length(),cmd.indexOf(':'));
        scriptnum = Integer.parseInt(snum);
        setBootScript( scriptnum );
      } else {

      }
      multitrack.repaint();
    } // actionPerformed
  };

ItemListener menuil = new ItemListener() { 
    void itemStateChanged(ItemEvent e) {
      String s = (String)e.getItem();
      if( s.equals("CtrlM Mode") ) {
        ctrlmMode = ( e.getStateChange() == ItemEvent.SELECTED);
        l.debug("ctrlmMode: "+ctrlmMode);
        if( ctrlmMode == false ) { // turn off ctrlmMode
          try { 
            linkm.ctrlmSetSendAddress( ctrlmAddr, 0,9 );
          } catch(IOException ioe) { 
            l.debug("ctrlmMode err: "+ioe);
          }
        }
      } 
      else if( s.equals("Reconnect on Disconnect") ) {
        l.debug("reconnectModeItem");
        reconnectMode = (e.getStateChange() == ItemEvent.SELECTED);
      }
    }
  };


/**
 * Create all the application menus
 */
void setupMenus(Frame f) {
  MenuBar menubar = new MenuBar();
  
  //create all the Menu Items and add the menuListener to check their state.
  Menu fileMenu = new Menu("File");
  Menu editMenu = new Menu("Edit");
  Menu toolMenu = new Menu("Tools");
  Menu helpMenu = new Menu("Help");

  MenuItem itemf1 = new MenuItem("Load Set", new MenuShortcut(KeyEvent.VK_O));
  MenuItem itemf2 = new MenuItem("Save Set", new MenuShortcut(KeyEvent.VK_S));
  MenuItem itemf2a= new MenuItem("-");
  MenuItem itemf3 = new MenuItem("Load One Track",
                                 new MenuShortcut(KeyEvent.VK_O, true));
  MenuItem itemf4 = new MenuItem("Save One Track",
                                 new MenuShortcut(KeyEvent.VK_S, true));
  MenuItem itemf4a= new MenuItem("-");

  connectItem     = new MenuItem("Connect to Arduino", 
                                 new MenuShortcut(KeyEvent.VK_C,true));

  MenuItem itemf4b= new MenuItem("-");
  CheckboxMenuItem itemf5 = new CheckboxMenuItem("CtrlM Mode");

  MenuItem itemf5a= new MenuItem("-");
  MenuItem itemf6 = new MenuItem("Quit", new MenuShortcut(KeyEvent.VK_Q));

  MenuItem iteme1= new MenuItem("Cut",  new MenuShortcut(KeyEvent.VK_X));
  MenuItem iteme2= new MenuItem("Copy", new MenuShortcut(KeyEvent.VK_C));
  MenuItem iteme3= new MenuItem("Paste",new MenuShortcut(KeyEvent.VK_V));
  MenuItem iteme4= new MenuItem("Delete",new MenuShortcut(KeyEvent.VK_D));
  MenuItem iteme4a=new MenuItem("-");
  MenuItem iteme5= new MenuItem("Select All in Track", new MenuShortcut(KeyEvent.VK_A));
  MenuItem iteme5a=new MenuItem("-");
  MenuItem iteme6= new MenuItem("Make Gradient", new MenuShortcut(KeyEvent.VK_G));
  MenuItem iteme6a=new MenuItem("-");
  MenuItem iteme7= new MenuItem("Edit Channel IDs");

  //MenuItem itemt2 = new MenuItem("Upgrade LinkM Firmware");
  MenuItem itemt1 = new MenuItem("BlinkM Factory Reset");
  Menu startupMenu = new Menu("Set BlinkM Startup Script to...");
  for( int i=0; i< startupScriptNames.length; i++) {
    MenuItem mi = new MenuItem(startupScriptNames[i]);
    mi.addActionListener(menual);
    startupMenu.add( mi );
  }
  MenuItem itemt1a = new MenuItem("-");
  MenuItem itemt3  = new MenuItem("Scan I2C Bus");
  MenuItem itemt4  = new MenuItem("Change BlinkM I2C Address");
  MenuItem itemt4a = new MenuItem("-");

  MenuItem itemt5  = new MenuItem("Display LinkM/BlinkM Versions");

  MenuItem itemt5a = new MenuItem("-");
  MenuItem itemt6  = new MenuItem("Reset LinkM");
  CheckboxMenuItem itemt7 = new CheckboxMenuItem("Reconnect on Disconnect");

  MenuItem itemh1  = new MenuItem("Help");
  MenuItem itemh2  = new MenuItem("Quick Start Guide");


  itemf1.addActionListener(menual);
  itemf2.addActionListener(menual);
  itemf3.addActionListener(menual);
  itemf4.addActionListener(menual);
  connectItem.addActionListener(menual);
  itemf5.addItemListener(menuil);
  itemf6.addActionListener(menual);
  iteme1.addActionListener(menual);
  iteme2.addActionListener(menual);
  iteme3.addActionListener(menual);
  iteme4.addActionListener(menual);
  iteme5.addActionListener(menual);
  iteme6.addActionListener(menual);
  iteme7.addActionListener(menual);
  itemt1.addActionListener(menual);
  //itemt2.addActionListener(menual);
  itemt3.addActionListener(menual);
  itemt4.addActionListener(menual);
  itemt5.addActionListener(menual);
  itemt6.addActionListener(menual);
  itemt7.addItemListener(menuil);
  itemh1.addActionListener(menual);
  itemh2.addActionListener(menual);
  
  fileMenu.add(itemf1);
  fileMenu.add(itemf2);
  fileMenu.add(itemf2a);
  fileMenu.add(itemf3);
  fileMenu.add(itemf4);
  fileMenu.add(itemf4a);
  fileMenu.add(connectItem);
  fileMenu.add(itemf5);
  fileMenu.add(itemf5a);
  fileMenu.add(itemf6);
  
  editMenu.add(iteme1);
  editMenu.add(iteme2);
  editMenu.add(iteme3);
  editMenu.add(iteme4);
  editMenu.add(iteme4a);
  editMenu.add(iteme5);
  editMenu.add(iteme5a);
  editMenu.add(iteme6);
  editMenu.add(iteme6a);
  editMenu.add(iteme7);


  toolMenu.add(itemt1);
  toolMenu.add(startupMenu);
  toolMenu.add(itemt1a);
  toolMenu.add(itemt3);
  toolMenu.add(itemt4);
  toolMenu.add(itemt4a);
  toolMenu.add(itemt5);
  toolMenu.add(itemt5a);
  toolMenu.add(itemt6);
  toolMenu.add(itemt7);

  helpMenu.add(itemh1);
  helpMenu.add(itemh2);

  menubar.add(fileMenu);
  menubar.add(editMenu);
  menubar.add(toolMenu);
  menubar.add(helpMenu);
  
  f.setMenuBar(menubar);   //add the menu to the frame
}

public byte getDurTicks() { 
  return getDurTicks(durationCurrent);
}

// uses global var 'durations'
public byte getDurTicks(int loopduration) {
  for( int i=0; i< timings.length; i++ ) {
    if( timings[i].duration == loopduration )
      return timings[i].durTicks;
  }
  return timings[0].durTicks; // failsafe
}

public byte getFadeSpeed() { 
  return getFadeSpeed(durationCurrent);
}

// this is so lame
public byte getFadeSpeed(int loopduration) {
  for( int i=0; i< timings.length; i++ ) {
    if( timings[i].duration == loopduration )
      return timings[i].fadeSpeed;
  }
  return timings[0].fadeSpeed; // failsafe
}

public void setDurationByIndex( int idx) {
  durationCurrent = timings[idx].duration;
}


/**
 * Bind keys to actions using a custom KeyEventPostProcessor
 * (fixme: why can't this go in the panel?)
 */
void bindKeys() {
  // ahh, the succinctness of java
  KeyboardFocusManager kfm = 
    KeyboardFocusManager.getCurrentKeyboardFocusManager();
  
  kfm.addKeyEventDispatcher( new KeyEventDispatcher() {
      public boolean dispatchKeyEvent(KeyEvent e) {
        boolean rc = false;
        if( !mf.hasFocus() ) { 
          if( !multitrack.hasFocus() ) {
            return false;
          }
        }
        if(e.getID() != KeyEvent.KEY_PRESSED) 
          return false;
        int mod = e.getModifiers();
        //if(e.getModifiers() != 0)  // FIXME?
        //  return false;

        switch(e.getKeyCode()) {
        case KeyEvent.VK_UP:
          multitrack.prevTrack();  rc = true;
          break;
        case KeyEvent.VK_DOWN:
          multitrack.nextTrack();  rc = true;
          break;
        case KeyEvent.VK_LEFT:
          multitrack.prevSlice(mod);  rc = true;
          break;
        case KeyEvent.VK_RIGHT:
          multitrack.nextSlice(mod);  rc = true;
          break;
        case KeyEvent.VK_SPACE:
          if( multitrack.playing ) { 
            multitrack.stop();
          } else { 
            //verifyLinkM();  
            multitrack.play();
          }
          rc = true;
          break;
        case KeyEvent.VK_1:
          multitrack.changeTrack(1);  rc = true;
         break;
        case KeyEvent.VK_2:
          multitrack.changeTrack(2);  rc = true;
          break;
        case KeyEvent.VK_3:
          multitrack.changeTrack(3);  rc = true;
          break;
        case KeyEvent.VK_4:
          multitrack.changeTrack(4);  rc = true;
          break;
        case KeyEvent.VK_5:
          multitrack.changeTrack(5);  rc = true;
          break;
        case KeyEvent.VK_6:
          multitrack.changeTrack(6);  rc = true;
          break;
        case KeyEvent.VK_7:
          multitrack.changeTrack(7);  rc = true;
          break;
        case KeyEvent.VK_8:
          multitrack.changeTrack(8);  rc = true;
          break;
        }
        /*
          if(action!=null)
          getCurrentTab().actionPerformed(new ActionEvent(this,0,action));
        */
        return rc;
      }
    });
}



/**
 *
 */
/*
public boolean checkForLinkM() {  
  l.debug("checkForLinkM");
  if( connected ) {
    try { 
      linkm.getLinkMVersion();
    } catch(IOException ioe) {
      connected = false;
      linkm.close();
    }
    return true;
  }
  
  try { 
    linkm.open();
  } catch( IOException ioe ) {
    return false;
  }
  linkm.close();
  
  return true;
}
*/

/**
 * FIXME: this is unused.  superceded by checkForLinkM()/connect() interaction
 * Verifies connetion to LinkM and at least one BlinkM
 * Also clears out any I2C bus errors that may be present
 */
/*
public boolean verifyConnection() {
  try { 
    // FIXME: what to do here
    // 0. do i2c bus reset ?
    // 1. verify linkm connection          (need new cmd?)
    // 2. verify connection to 1st blinkm  (get version?)
    // 3. verify all blinkms?
    linkm.getVersion(0);
  } catch( IOException ioe ) {
  }
  return true;
}
*/

/* from processing/arduino

static public File getContentFile(String name) {
  String path = System.getProperty("user.dir");
  
  // Get a path to somewhere inside the .app folder
  if (isMacOS()) {
    //      <key>javaroot</key>
    //      <string>$JAVAROOT</string>
    String javaroot = System.getProperty("javaroot");
    if (javaroot != null) {
      path = javaroot;
    }
  }
  File working = new File(path);
  return new File(working, name);
}

**
 * returns true if Processing is running on a Mac OS X machine.
 *
static public boolean isMacOS() {
  return System.getProperty("os.name").indexOf("Mac") != -1;
}

**
 * returns true if running on windows.
 *
static public boolean isWindows() {
  return System.getProperty("os.name").indexOf("Windows") != -1;
}

**
 * true if running on linux.
 *
static public boolean isLinux() {
  return System.getProperty("os.name").indexOf("Linux") != -1;
}
*/

/*
--  OLD doTrackDialog --
    int blinkmAddr = tracks[track].blinkmaddr;
    String s = (String)
      JOptionPane.showInputDialog(
                                  this,
                                  "Enter a new BlinkM address for this track",
                                  "Set track address",
                                  JOptionPane.PLAIN_MESSAGE,
                                  null,
                                  null,
                                  ""+blinkmAddr);
    
    //If a string was returned, say so.
    if ((s != null) && (s.length() > 0)) {
      l.debug("s="+s);
      try { 
        blinkmAddr = Integer.parseInt(s);
        if( blinkmAddr >=0 && blinkmAddr < 127 ) { // i2c limits
          tracks[track].blinkmaddr = blinkmAddr;
        }
      } catch(Exception e) {}
      
    } 
    */

