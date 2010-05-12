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

import thingm.linkm.*;

static final boolean debug = true;

String username = "blinkmlive";
String password = "redgreenblue";

String colorfile = "rgb.txt";
HashMap colormap;  // stores String -> Color mappings of rgb.txt file

TwitterStream twitterStream ;

String mentionString = "blinkn";
String[] trackStrings = new String[] { mentionString }; 

long lastMillis;
Color lastColor = Color.red;

LinkM linkm = new LinkM(); 
int blinkmaddr = 0;

PFont font;
String lastMsg = "TwitterBlinkM!";

void setup() {
  size(400,400);
  frameRate(5);
  //  smooth();

  font = loadFont("HelveticaNeue-CondensedBold-18.vlw"); 
  textFont( font  );
  colormap = parseColorFile(colorfile);

  twitterStream = new TwitterStreamFactory().getInstance(username,password); 
  twitterStream.setStatusListener(listener);
  try { 
    twitterStream.filter( new FilterQuery(0, null, trackStrings ) );
  } catch( TwitterException twe ) {
    println("filter fail: "+twe);
  }

  connectLinkM();

  lastMillis = millis();
}


void draw() {
  background(0);
  color lc = lastColor.getRGB();

  // make circle last tweeted color, as nice radial alpha gradient
  createGradient(width/2, width/2, width*3/4,  lc, color(0,0,0,10)  ); 

  noStroke();
  fill(0,0,0,50);
  roundrect( 30,height-60, width-60,40, 20); // draw text background

  textAlign(CENTER);
  fill(255);
  text(lastMsg, 9, height-50, width-20,50 );  // draw text

  
  long t = millis();
  if( (t-lastMillis) > 10000 ) { 
    lastMillis = t;
    println("thump "+t);  // just a heartbeat to show we're working
  }
  
}

/**
 * For streaming mode, this is what will do most all the work
 */
StatusListener listener = new StatusListener(){
    public void onStatus(Status status) {
      debug(status.getUser().getName() + " : " + status.getText());
      boolean rc = parseColors( status.getText() );
      if( rc ) {
        try { 
          lastMsg = "@"+status.getUser().getScreenName()+": "+status.getText();
          linkm.fadeToRGB( blinkmaddr, lastColor);
        } catch(IOException ioe) {
          println("no linkm");
        }
      }
    }
    public void onDeletionNotice(StatusDeletionNotice statusDeletionNotice) {
      println("********** DELETION **************");
    }
    public void onTrackLimitationNotice(int numberOfLimitedStatuses) {
      println("********** LIMITED **************");
    }
    public void onException(Exception ex) {
      println("** EXCEPTION **"); ex.printStackTrace();
    }
  };


/**
 * Attempt to determine what color has been tweeted to us
 */
boolean parseColors(String text) {
  //println("text='"+text+"'");
  text = text.replaceAll("#",""); // in case they do #ff00ff
  Color c = null;
  String linepat = mentionString + "\\s+(.+?)\\b";
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
