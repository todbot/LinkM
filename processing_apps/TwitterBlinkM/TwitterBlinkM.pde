/**
 * TwitterBlinkM -- Tweet colors to a BlinkM
 *
 * Twitter commands accepted
 * - color names
 *
 * Check Rate Limiting:
 * curl http://blinkmlive:redgreenblue@api.twitter.com/1/account/rate_limit_status.json
 *
 */

import java.awt.Color;

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
Color lastColor = Color.black;

LinkM linkm = new LinkM(); 
int blinkmaddr = 0;

void setup() {
  size(300,300);
  frameRate(5);

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
  background( lastColor.getRGB() );  // make background last tweeted color
  long t = millis();
  if( (t-lastMillis) > 10000 ) { 
    lastMillis = t;
    println("thump "+t);  // just a heartbeat to show we're working
  }
  
}

/**
 * Attempt to determine what color has been tweeted to us
 */
boolean parseColors(String text) {
  //println("text='"+text+"'");
  Color c = null;
  String linepat = mentionString + "\\s+(.+)\\b";
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
 * For streaming mode, this is what will do most all the work
 */
StatusListener listener = new StatusListener(){
    public void onStatus(Status status) {
      debug(status.getUser().getName() + " : " + status.getText());
      boolean rc = parseColors( status.getText() );
      if( rc ) {
        try { 
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
