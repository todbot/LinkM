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

String silkfontPath = "slkscrb.ttf";  // in "data" directory
Font silkfont;


JDialog mf;  // the main holder of the app
JColorChooser colorChooser;
MultiTrackView multitrack;
TrackView trackview;
PlayButton pb;
JPanel connectPanel;
JFileChooser fc;

// number of slices in the timeline == number of script lines written to BlinkM
int numSlices = 48;  
int numTracks = 8;    // number of different blinkms

// default blinkm addresses used, can change by clicking on the addresses in UI
//int[] blinkmAddrs = {125,11,12,3, 14,15,66,17}; // numTracks big

// overall dimensions
int mainWidth  = 825;
int mainHeight = 640;  // was 455
int mainHeightAdjForWindows = 12; // fudge factor for Windows layout variation


// maps duration in seconds to duration in ticks (durTicks) and fadespeed
public static class Timing  {
   public int duration;
   public byte durTicks;
   public byte fadeSpeed;
   public Timing(int d,byte t,byte f) { duration=d; durTicks=t; fadeSpeed=f; }
}

public static Timing[] timings = new Timing [] {
    new Timing(   3, (byte)  1, (byte) 100 ),
    new Timing(  30, (byte) 18, (byte)  25 ),
    new Timing( 100, (byte) 25, (byte)   5 ),
 };

int durationCurrent = timings[0].duration;


PApplet p;
Util util = new Util();  // can't be a static class because of getClass() in it

Color cBlk        = new Color(0,0,0);               // black like my soul
Color fgLightGray = new Color(230, 230, 230);
Color bgLightGray = new Color(200, 200, 200);
Color bgMidGray   = new Color(140, 140, 140);
Color bgDarkGray  = new Color(100, 100, 100);
Color tlDarkGray  = new Color(55, 55, 55);          // dark color for timeline
Color cHighLight  = new Color(255, 0, 0);           // used for selections
Color briOrange   = new Color(0xFB,0xC0,0x80);      // bright yellow/orange
Color muteOrange  = new Color(0xBC,0x83,0x45);
 
/**
 * Processing's setup()
 */
void setup() {
  size(10, 10);   // Processing's frame, we'll turn this off in a bit
  frameRate(30);  // each frame we can potentially redraw timelines


  try { 
    // load up the lovely silkscreen font
    File f = new File( dataPath( silkfontPath ));
    FileInputStream in = new FileInputStream(f);
    Font dynamicFont = Font.createFont(Font.TRUETYPE_FONT, in);
    silkfont = dynamicFont.deriveFont( 8f );

    // use a Swing look-and-feel that's the same across all OSs
    MetalLookAndFeel.setCurrentTheme(new DefaultMetalTheme());
    UIManager.setLookAndFeel( new MetalLookAndFeel() );
  } 
  catch(Exception e) { 
    l.error("drat: "+e);
  }

  String osname = System.getProperty("os.name");
  if( osname.toLowerCase().startsWith("windows") ) 
    mainHeight += mainHeightAdjForWindows;
  
  p = this;
  
  setupGUI();
}

/**
 * Processing's draw()
 */
void draw() {
  if( frameCount < 30 ) {
    super.frame.setVisible(false);  // turn off Processing's frame
    super.frame.toBack();
    mf.toFront();                   // bring ours forward  
  }

  float millisPerTick = (1/frameRate) * 1000;
  // tick tock
  multitrack.tick( millisPerTick );
  trackview.tick( millisPerTick ); 
  // not exactly 1/frameRate, but good enough I think

  //multitrack.setSelectedColor(colorChooser.getColor());
    
}



//
void setupGUI() {

  setupMainframe();  // creates 'mf'

  Container mainpane = mf.getContentPane();
  BoxLayout layout = new BoxLayout( mainpane, BoxLayout.Y_AXIS);
  mainpane.setLayout(layout);

  ChannelsTop chtop = new ChannelsTop();
  multitrack        = new MultiTrackView( numTracks, numSlices, mainWidth,135);

  TimelineTop ttop  = new TimelineTop();
  trackview         = new TrackView( multitrack, mainWidth, 100 );

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
  mainpane.add( chtop );
  mainpane.add( multitrack );

  mainpane.add( ttop );
  mainpane.add( trackview );

  mainpane.add( controlsPanel );

  mainpane.add( lowerpanel );

  mf.setVisible(true);
  mf.setResizable(false);

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

}


// just to get this out of the way 
JPanel makeColorChooserPanel() {
  JPanel colorChooserPanel = new JPanel();   // put it in its own panel for why?
  colorChooser = new JColorChooser();
  colorChooser.setBackground(bgLightGray);

  colorChooser.getSelectionModel().addChangeListener( new ChangeListener() {
      public void stateChanged(ChangeEvent e) {
        Color c = colorChooser.getColor();
        multitrack.setSelectedColor(c);
      }
    });

  /*
  // look for javax.swing.colorchooser.DefaltSwatchChooserPanel
  AbstractColorChooserPanel[] cps = colorChooser.getChooserPanels();
  for( int i=0; i< cps.length; i++ ) {
    String s = cps[i].getClass().getCanonicalName();
    println("s:'"+s+"'");
    if( s.equals("javax.swing.colorchooser.DefaultSwatchChooserPanel") ) {
      println("woot");
      cps[i].addMouseListener( new MouseAdapter() { 
          public void mousePressed(MouseEvent e) {
            l.debug("tod click!");
            multitrack.setSelectedColor( colorChooser.getColor() );
          }
        } );
    }
  */

  colorChooser.setPreviewPanel( new JPanel() ); // we have our custom preview
  colorChooser.setBackground(bgLightGray);
  colorChooserPanel.add( colorChooser );
  colorChooser.setColor( tlDarkGray );
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

/**
 * Create the containing frame (or JDialog in this case) 
 */
void setupMainframe() {
  mf = new JDialog(new Frame(), "BlinkM Sequencer", false);
  mf.setBackground(bgDarkGray);
  mf.setFocusable(true);
  mf.setSize( mainWidth, mainHeight);
  
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
  //mf.setSize(this.width, this.height);
  Dimension scrnSize = Toolkit.getDefaultToolkit().getScreenSize();
  mf.setLocation(scrnSize.width/2 - mf.getWidth()/2, 
                 scrnSize.height/2 - mf.getHeight()/2);
  mf.setVisible(true);
  
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


// used generally to make BlinkM color match preview color
boolean sendBlinkMColor( int blinkmAddr, Color c ) {    
  l.debug("sendBlinkMColor: "+blinkmAddr+" - "+c);
  //int addr = 0;
  /*
    try { 
    linkm.fadeToRGB( addr, c);  // FIXME:  which track 
    } catch( IOException ioe) {
    // hmm, what to do here
    return false;
    }
  */
  return true;
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


/**
 *
 */
void loadTrack() { 
  loadTrack(multitrack.currTrack);
}

/**
 * Load a text file containing a light script, turn it into BlinkMScriptLines
 */
void loadTrack(int tracknum) {
  int returnVal = fc.showOpenDialog(mf);  // this does most of the work
  if (returnVal != JFileChooser.APPROVE_OPTION) {
    println("Open command cancelled by user.");
    return;
  }
  File file = fc.getSelectedFile();
  if( file != null ) {
    String[] lines = linkm.loadFile( file );
    BlinkMScript script = linkm.parseScript( lines );
    if( script == null ) {
      System.err.println("bad format in file");
      return;
    }
    script = script.trimComments(); 
    int len = script.length();
    println("script len:"+len);  // FIXME: check script len overrun
    if( len > numSlices ) { // danger!
      len = numSlices;
    }
    int j=0;
    for( int i=0; i<len; i++ ) { 
      BlinkMScriptLine sl = script.get(i);
      if( sl.cmd == 'c' ) { // color command
        Color c = new Color( sl.arg1, sl.arg2, sl.arg3 );
        multitrack.tracks[tracknum].slices[j++] = c;
      }
    }
    multitrack.repaint();
  }
}


/**
 *
 */
 void saveTrack() {
  saveTrack( multitrack.currTrack );
}
/**
 * 
 */
void saveTrack(int tracknum) {
  int returnVal = fc.showSaveDialog(mf);  // this does most of the work
  if( returnVal != JFileChooser.APPROVE_OPTION) {
    println("Save command cacelled by user.");
    return;
  }
  File file = fc.getSelectedFile();
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
    linkm.saveFile( file, script.toString() );
  }
}


// ------------------------------------------------


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

// this is so lame
public byte getFadeSpeed(int loopduration) {
  for( int i=0; i< timings.length; i++ ) {
    if( timings[i].duration == loopduration )
      return timings[i].fadeSpeed;
  }
  return timings[0].fadeSpeed; // failsafe
}

