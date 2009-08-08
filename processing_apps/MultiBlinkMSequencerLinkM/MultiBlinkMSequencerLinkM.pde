// Copyright (c) 2007-2009, ThingM Corporation

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

import thingm.linkm.*;

String VERSION = "002";

Log l = new Log();

LinkM linkm = new LinkM();

boolean isConnected = false;   // FIXME: this isn't used yet


MainFrame mf;
JColorChooser colorChooser;
//ColorPreview colorPreview;
Timeline timeline;
PlayButton pb;

JPanel connectPanel;

// number of slices in the timeline == number of script lines written to BlinkM
int numSlices = 48;
// number of different blinkms
int numTracks = 8;
// default blinkm addresses used, can change by clicking on the addresses in UI
int[] blinkmAddrs = {10,11,12,13, 14,15,16,17}; // numTracks big

// overall dimensions
int mainWidth = 851;
int mainHeight = 535;  // was 455
int mainHeightAdjForWindows = 12; // fudge factor for Windows layout variation


// the possible durations for the loop
int[] durations = { 3, 30, 120 };
int durationCurrent = durations[0];

// mapping of duration to ticks      (must be same length as 'durations')
public byte[] durTicks   = { (byte)   1, (byte) 18, (byte) 72 };
// mapping of duration to fadespeeds (must be same length as 'durations')
public byte[] fadeSpeeds = { (byte) 100, (byte) 25, (byte)  5 };


PApplet p;
Util util = new Util();

Color cBlk        = new Color(0,0,0);               // black like my soul
Color fgLightGray = new Color(230, 230, 230);
Color bgLightGray = new Color(200, 200, 200);
Color bgMidGray   = new Color(140, 140, 140);
Color bgDarkGray  = new Color(100, 100, 100);
Color tlDarkGray  = new Color(55, 55, 55);          // dark color for timeline
Color highLightC  = new Color(255, 0, 0);           // used for selections

/**
 * Processing's setup()
 */
void setup() {
  size(10, 10);   // Processing's frame, we'll turn this off in a bit

  try {  // use a Swing look-and-feel that's the same across all OSs
    MetalLookAndFeel.setCurrentTheme(new DefaultMetalTheme());
    UIManager.setLookAndFeel( new MetalLookAndFeel() );
  } catch(Exception e) { 
    l.error("drat: "+e);
  }

  String osname = System.getProperty("os.name");
  if( osname.toLowerCase().startsWith("windows") ) 
    mainHeight += mainHeightAdjForWindows;
  
  mf = new MainFrame(mainWidth, mainHeight, this);
  p = this;
  
  setupGUI();
}

/**
 * Processing's draw()
 */
void draw() {
  super.frame.setVisible(false);  // turn off Processing's frame
  super.frame.toBack();
  mf.toFront();

  if(frameCount > 30) {  // stop Processing's loooper
    noLoop(); 
  }
}

//
void setupGUI() {
  Container mainpane = mf.getContentPane();
  BoxLayout layout = new BoxLayout( mainpane, BoxLayout.Y_AXIS);
  mainpane.setLayout(layout);

  ChannelsTop chanstop = new ChannelsTop();
  //Channels chans      = new Channels( mainWidth );
  Timeline channels    = new Timeline( numSlices, numTracks, mainWidth, 170 );

  TimelineTop timetop  = new TimelineTop();
  //timeline             = new Timeline( numSlices,numTracks, 170, mainWidth );
  timeline             = new Timeline( numSlices, 1, mainWidth, 170 );

  //  FIXME: this will change when preview-per-track exists
  //colorPreview             = new ColorPreview();
  JPanel colorChooserPanel = makeColorChooserPanel();
  ButtonPanel buttonPanel  = new ButtonPanel(399, 250);  //was 310, FIXME:

  JPanel controlsPanel = new JPanel();
  controlsPanel.setBackground(bgDarkGray);  //sigh, gotta do this on every panel
  controlsPanel.setBorder(BorderFactory.createMatteBorder(10,0,0,0,bgDarkGray));
  //controlsPanel.setBorder(BorderFactory.createCompoundBorder(  // debug
  //                 BorderFactory.createLineBorder(Color.red),
  //                 controlsPanel.getBorder()));
  BoxLayout controlsLayout = new BoxLayout(controlsPanel, BoxLayout.X_AXIS);
  controlsPanel.setLayout(controlsLayout);
  controlsPanel.add( colorChooserPanel );
  //controlsPanel.add( colorPreview );
  controlsPanel.add( Box.createHorizontalGlue() );
  controlsPanel.add( buttonPanel );

  JPanel lowerpanel = makeLowerPanel();

  // add everything to the main pane, in order
  mainpane.add( chanstop );
  mainpane.add( channels );

  mainpane.add( timetop );
  mainpane.add( timeline );

  mainpane.add( controlsPanel );

  mainpane.add( lowerpanel );

  mf.setVisible(true);
  mf.setResizable(false);

}

// just to get this out of the way 
JPanel makeColorChooserPanel() {
  JPanel colorChooserPanel = new JPanel();   // put it in its own panel for why?
  colorChooser = new JColorChooser();
  colorChooser.setBackground(bgLightGray);
  colorChooser.getSelectionModel().addChangeListener( new ChangeListener() {
      public void stateChanged(ChangeEvent e) {
        Color c = colorChooser.getColor();
        timeline.setActiveColor(c);
        //colorPreview.setColor(c);          // update ColorPreview panel
      }      
    });
  colorChooser.setPreviewPanel( new JPanel() ); //colorPreview );
  colorChooser.setBackground(bgLightGray);
  colorChooserPanel.add( colorChooser );
  return colorChooserPanel;
}

//
JPanel makeLowerPanel() {
  JPanel lp = new JPanel();
  lp.setBackground(bgMidGray);
  JLabel lowLabel = new JLabel("  version "+VERSION+" \u00a9 ThingM Corporation", JLabel.LEFT);
  lowLabel.setHorizontalAlignment(JLabel.LEFT);
  lp.setPreferredSize(new Dimension(855, 30));  // FIXME: hardcoded value yo
  lp.setLayout(new BorderLayout());
  lp.add(lowLabel, BorderLayout.WEST);
  return lp;
}


// -----------------------------------------------------------------


/**
 * Open up the LinkM and set it up if it hasn't been
 * Sets and uses the global variable 'isConnected'
 */
boolean connectIfNeeded() {
  if( !isConnected ) {
    try { 
      linkm.open();
      linkm.i2cEnable(true);
      byte[] addrs = linkm.i2cScan(1,17);  // FIXME: not a full scan
      int cnt = addrs[0];
      if( cnt>0 ) {
        //bladdr = addrs[1];   // FIXME:  pick first address
      }
      else {
        println("no blinkm found!");  // FIXME: pop up dialog?
      }
    } catch(IOException ioe) {
      println("connect:no linkm?\n"+ioe);
      return false;
    }
  }
  isConnected = true;
  return true; // connect successful
}

/**
 * Burn a list of colors to a BlinkM
 * @param blinkmAddr the address of the BlinkM to write to
 * @param colorlist an ArrayList of the Colors to burn (java Color objs)
 * @param nullColor a color in the list that should be treated as nothing
 * @param duration  how long the entire list should last for, in seconds
 * @param loop      should the list be looped or not
 * @param progressbar if not-null, will update a progress bar
 */
public void burn(int blinkmAddr, ArrayList colorlist, 
                 Color nullColor, int duration, boolean loop, 
                 JProgressBar progressbar) {
  
  //byte[] cmd = new byte[8];
  byte fadespeed = getFadeSpeed(duration);
  byte durticks = getDurTicks(duration);
  byte reps = (byte)((loop) ? 0 : 1);  
  
  Color c;
  BlinkMScriptLine scriptLine;

  l.debug("burn: addr:"+blinkmAddr+" durticks:"+durticks+" fadespeed:"+fadespeed);
  
  //build up the byte array to send
  Iterator iter = colorlist.iterator();
  int i=0;
  try { 
    while( iter.hasNext() ) {
      l.debug("burn: writing script line "+i);
      c = (Color) iter.next();
      if( c == nullColor )
        c = cBlk;
      
      scriptLine = new BlinkMScriptLine( durticks, 'c', 
                                         c.getRed(),c.getGreen(),c.getBlue());
      linkm.writeScriptLine( blinkmAddr, i, scriptLine);
      
      if( progressbar !=null) progressbar.setValue(i);  // hack
      i++;
    }
    
    // set script length   cmd   id         length         reps
    linkm.setScriptLengthRepeats( blinkmAddr, colorlist.size(), reps);
    
    // set boot params   addr, mode,id,reps,fadespeed,timeadj
    linkm.setStartupParams( blinkmAddr, 1, 0, 0, fadespeed, 0 );
    
    // set playback fadespeed
    linkm.setFadeSpeed( blinkmAddr, fadespeed);
    
    // and play the script
    linkm.playScript( blinkmAddr );
    
  } catch( IOException ioe ) {
    l.error("couldn't burn: "+ioe);
  }
}


/**
 * Prepare blinkm for playing preview scripts
 */
public void prepareForPreview(int loopduration) {
  byte fadespeed = getFadeSpeed(loopduration);
  l.debug("prepareForPreview: fadespeed:"+fadespeed);

  int blinkmAddr = 0x00;  // FIXME: ????
  try { 
    linkm.stopScript( blinkmAddr );
    linkm.setFadeSpeed( blinkmAddr, fadespeed );
  } catch(IOException ioe ) {
    // FIXME: hmm, what to do here
  }
}

// uses global var 'durations'
public byte getDurTicks(int loopduration) {
  for( int i=0; i<durations.length; i++ ) {
    if( durations[i] == loopduration )
      return durTicks[i];
  }
  return durTicks[0]; // failsafe
}
// this is so lame
public byte getFadeSpeed(int loopduration) {
  for( int i=0; i<durations.length; i++ ) {
    if( durations[i] == loopduration )
      return fadeSpeeds[i];
  }
  return fadeSpeeds[0]; // failsafe
}

