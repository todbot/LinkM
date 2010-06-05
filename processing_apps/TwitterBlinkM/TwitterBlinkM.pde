/**
 * TwitterBlinkM -- Tweet colors to a BlinkM
 *
 * Twitter commands accepted
 * - "blinkm <colorname>"
 * - "blinkm <hexcolor>"
 *
 *
 *
 * Check Twitter Rate Limiting:
 * curl http://blinkmlive:redgreenblue@api.twitter.com/1/account/rate_limit_status.json
 *
 */

import java.awt.*;
import java.awt.geom.*;
import java.awt.event.*;
import javax.swing.*;
import javax.swing.plaf.metal.*;

import thingm.linkm.*;

static final boolean debug = true;

String username = "";
String password = "";

String colorfile = "rgb.txt";
HashMap colormap;  // stores String -> Color mappings of rgb.txt file

TwitterStream twitterStream ;
boolean twitterSetupDone = false;

String mentionString1 = "blinkm";
String mentionString2 = "makerfaire";
String[] trackStrings = new String[] { mentionString1, mentionString2 }; 
int mentionCount=255;

long lastMillis;
Color lastColor = Color.gray;

LinkM linkm = new LinkM(); 
int blinkm1addr = 10;
int blinkm2addr = 9;

PFont font;
String lastMsg = "TwitterBlinkM!";

void setup() {
  size(600,600);
  frameRate(10);

  font = loadFont("HelveticaNeue-CondensedBold-18.vlw"); 
  textFont( font  );
  colormap = parseColorFile(colorfile);


  if( username != null && !username.equals("") &&
      password != null && !password.equals("") ) {
    setupTwitter();  // don't need to pop dialog box if pre-set
  }

  lastMillis = millis();
}

//
void setupTwitter() {
  println("setupTwitter with username:"+username+",password:"+password);
  if( username != null && !username.equals("") &&
      password != null && !password.equals("") ) {

    connectLinkM();

    twitterStream = new TwitterStreamFactory().getInstance(username,password); 
    twitterStream.setStatusListener(listener);
    try { 
      twitterStream.filter( new FilterQuery(0, null, trackStrings ) );
    } catch( TwitterException twe ) {
      println("filter fail: "+twe);
    }
    
  
    twitterSetupDone = true;
    updateMsg("TwitterBlinkM Listening!");
  }
  else {
    println("TwitterBlinkM: no username or password");
    System.exit(0);
  }
}

void draw() {
  background(0);
  color lc = lastColor.getRGB();

  // make circle last tweeted color, as nice radial alpha gradient
  createGradient(width/2, width/2, width*3/4,  lc, color(0,0,0,10)  ); 

  noStroke();
  fill(0,0,0,50);
  roundrect( 30,height-80, width-80,60, 30); // draw text background

  if( mentionCount>0 ) { 
    textAlign(CENTER);
    fill(255,255,255,mentionCount);
    mentionCount -= 5; // fade out
    text(lastMsg, 9, height-80, width-40,70 );  // draw text
  }
  
  long t = millis();
  if( (t-lastMillis) > 10000 ) {  // just a heartbeat
    lastMillis = t;
    println("listening to twitter for "+mentionString1+" & "+mentionString2); 
  }

  //
  if( frameCount==1 && !twitterSetupDone ) {
    showTwitterSetupDialog();
  }

}

// update the status message at bottom of screen
void updateMsg(String s) {
  mentionCount = 255;
  lastMsg = s;
}

// let you trigger random colors just to see what's what
void keyPressed() {
  int r = int(random(255));
  int g = int(random(255));
  int b = int(random(255));
  lastColor = new Color(r,g,b);
  println("keyPressed: "+lastColor);
  try { 
    linkm.fadeToRGB( 0, r,g,b );
  } catch( IOException ioe ) {
    println("no linkm?");
    connectLinkM();
  }
}

/**
 * For streaming mode, this is what will do most all the work
 */
StatusListener listener = new StatusListener(){
    public void onStatus(Status status) {
      debug(status.getUser().getName() + " : " + status.getText());
      String text = status.getText();
      String lctext = text.toLowerCase();
      
      updateMsg( "@"+status.getUser().getScreenName()+": "+text );

      // flash blinkm to show we received status
      try { 
          linkm.playScript( blinkm2addr, 5, 2, 0); // play #5 (blue) twice
      } catch( IOException ioe ) {
          println("no linkm? reconnecting to LinkM");
          connectLinkM();
      }
     
      // turn first blinkm color of tweet (if applicable)
      boolean rc = parseColors( lctext );
      if( rc ) {
        try { 
          linkm.fadeToRGB( blinkm1addr, lastColor);
        } catch(IOException ioe) {
          println("no linkm");
        }
      }
    }
    public void onDeletionNotice(StatusDeletionNotice statusDeletionNotice) {
      println("********** DELETION **************");
      updateMsg("** DELETION **");
    }
    public void onTrackLimitationNotice(int numberOfLimitedStatuses) {
      println("********** LIMITED **************");
      updateMsg("** LIMITED **");
    }
    public void onException(Exception ex) {
      println("** EXCEPTION **"); ex.printStackTrace();
      updateMsg("** EXCEPTION **");
    }
  };


boolean parseColorsNew(String text) { 
  // do something with just array of substrs
  return true;
}

/**
 * Attempt to determine what color has been tweeted to us
 */
boolean parseColors(String text) {
  //println("text='"+text+"'");
  text = text.replaceAll("#",""); // in case they do #ff00ff
  Color c = null;
  String linepat = mentionString1 + "\\s+(.+?)\\b";
  Pattern p = Pattern.compile(linepat);
  Matcher m = p.matcher( text );
  if(  m.find() && m.groupCount() == 1 ) { // matched 
    String colorstr = m.group(1);
    debug(" match: "+colorstr );
    c = (Color) colormap.get( colorstr );
    if( c !=null ) { 
      debug("  color! "+c);
      lastColor = c;
      return true;
    }

    //colorstr = colorstr.replaceAll("#","");
    try {
      int hexint = Integer.parseInt( colorstr, 16 ); // try hex
      c = new Color( hexint );
      debug("  color! "+c);
      lastColor = c;
      return true;
    } catch( NumberFormatException nfe ) { 
    }
  }

  return false;
}



/**
 * Parse the standard X11 rgb.txt file into a hashmap of name String -> Color
 * This is called only once on setup()
 */
HashMap parseColorFile(String filename) {
  HashMap colormap = new HashMap();
  String lines[] = loadStrings(filename);

  String linepat = "^\\s*(.+?)\\s+(.+?)\\s+(.+?)\\s+(.+)$";
  Pattern p = Pattern.compile(linepat);
  for( int i=0; i< lines.length; i++) { 
    String l = lines[i];
    Matcher m = p.matcher( l );
    if(  m.find() && m.groupCount() == 4 ) { // matched everything
      int r = Integer.parseInt( m.group(1) );
      int g = Integer.parseInt( m.group(2) );
      int b = Integer.parseInt( m.group(3) );
      String name = m.group(4);
      name = name.replaceAll("\\s+","").toLowerCase();
      Color c = new Color(r,g,b);
      colormap.put( name, c );
    }
  }

  if( debug ) {
    Set keys = colormap.keySet();
    Iterator it = keys.iterator();
    while (it.hasNext()) {
      String cname = (String)(it.next());
      debug(cname + " - " + colormap.get(cname));
    }
  }

  return colormap;
}

/*
 *
 */
void connectLinkM() {
  try { 
    linkm.open();
    linkm.i2cEnable(true);
    linkm.pause(50);
    linkm.setFadeSpeed(0,8);
    debug("connectLinkM");
    for( int i=0;i<2; i++ ) {
      linkm.setRGB(0, 0x22,0x22,0x22);
      linkm.pause(100);
      linkm.fadeToRGB(0, 0x00,0x00,0x00);
      linkm.pause(100);
    }

  } catch(IOException ioe) {
    debug("connect: no linkm?", ioe);
    return;
  }
  debug("linkm connected.");
}

//
void debug(String s) {
  debug( s,null);
}
//
void debug(String s1, Object s2) {
  String s = s1;
  if( s2!=null ) s = s1 + " : " + s2;
  if(debug) println(s);
  //lastMsg = s1;
}


//
// stolen from: http://processing.org/learning/basics/radialgradient.html
//
void createGradient (float x, float y, float radius, color c1, color c2) {
  float px = 0, py = 0, angle = 0;

  // calculate differences between color components 
  float deltaR = red(c2)-red(c1);
  float deltaG = green(c2)-green(c1);
  float deltaB = blue(c2)-blue(c1);
  // hack to ensure there are no holes in gradient
  // needs to be increased, as radius increases
  float gapFiller = 8.0;

  for (int i=0; i< radius; i++){
    for (float j=0; j<360; j+=1.0/gapFiller){
      px = x+cos(radians(angle))*i;
      py = y+sin(radians(angle))*i;
      angle+=1.0/gapFiller;
      color c = color(
      (red(c1)+(i)*(deltaR/radius)),
      (green(c1)+(i)*(deltaG/radius)),
      (blue(c1)+(i)*(deltaB/radius)) 
        );
      set(int(px), int(py), c);      
    }
  }
  // adds smooth edge 
  // hack anti-aliasing
  noFill();
  strokeWeight(3);
  ellipse(x, y, radius*2, radius*2);
}

//
// stolen from: http://processing.org/discourse/yabb2/YaBB.pl?num=1213696787/1
//
void roundrect(int x, int y, int  w, int h, int r) {
 noStroke();
 rectMode(CORNER);

 int  ax, ay, hr;

 ax=x+w-1;
 ay=y+h-1;
 hr = r/2;

 rect(x, y, w, h);
 arc(x, y, r, r, radians(180.0), radians(270.0));
 arc(ax, y, r,r, radians(270.0), radians(360.0));
 arc(x, ay, r,r, radians(90.0), radians(180.0));
 arc(ax, ay, r,r, radians(0.0), radians(90.0));
 rect(x, y-hr, w, hr);
 rect(x-hr, y, hr, h);
 rect(x, y+h, w, hr);
 rect(x+w,y,hr, h);

}


//
void showTwitterSetupDialog()
{
  println("showTwitterSetupDialog");
  javax.swing.SwingUtilities.invokeLater(new Runnable() {
      public void run() {
        try{ Thread.sleep(500); } catch(Exception e){}  // wait to avoid assert
        new TwitterSetupDialog();
      }
    } );

}

//
public class TwitterSetupDialog extends JDialog { //implements ActionListener {

  JTextField userfield,passfield;
  JTextField mention1field,mention2field;

  public TwitterSetupDialog() {
    super();

    try {  // use a Swing look-and-feel that's the same across all OSs
      MetalLookAndFeel.setCurrentTheme(new DefaultMetalTheme());
      UIManager.setLookAndFeel( new MetalLookAndFeel() );
    } catch(Exception e) { }  // don't really care if it doesn't work

    JLabel l1 = new JLabel("Twitter username:");
    userfield = new JTextField( username,20 );
    JLabel l2 = new JLabel("Twitter password:");
    passfield = new JTextField( password,20 );

    JLabel l3 = new JLabel("keyword one:");
    mention1field = new JTextField( mentionString1,15 );
    JLabel l4 = new JLabel("keyword two:");
    mention2field = new JTextField( mentionString2,15 );

    JButton cancelbut = new JButton("CANCEL");
    JButton okbut     = new JButton("OK");

    JPanel p = new JPanel(new GridLayout( 5,2, 5,5 ) );
    p.setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 10));

    p.add(l1); p.add(userfield);
    p.add(l2); p.add(passfield);
    p.add(l3); p.add(mention1field);
    p.add(l4); p.add(mention2field);
    p.add(cancelbut); p.add(okbut);

    getContentPane().add(p);

    pack();
    setResizable(false);
    setLocationRelativeTo(frame); // center it on screen
    setTitle("TwitterBlinkM Setup");
    setVisible(true);

    cancelbut.addActionListener(new ActionListener() {
        public void actionPerformed(ActionEvent ae) {
          setVisible(false);  // do nothing but go away
          //setupTwitter();
          System.exit(0);
        }
      });
    okbut.addActionListener(new ActionListener() {
        public void actionPerformed(ActionEvent ae) {
          setVisible(false);
          username = userfield.getText();
          password = passfield.getText();
          mentionString1 = mention1field.getText();
          mentionString2 = mention2field.getText();
          trackStrings = new String[] { mentionString1, mentionString2 }; 
          setupTwitter();
        }
      });
  }

}

