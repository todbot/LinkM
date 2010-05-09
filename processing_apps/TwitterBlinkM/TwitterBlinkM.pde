/**
 *
 *
 * Twitter commands accepted
 * - color names
 *
 * Check Rate Limiting:
 * curl http://blinkmlive:redgreenblue@api.twitter.com/1/account/rate_limit_status.json
 *
 */

import java.awt.Color;

static final boolean debug = true;

String username = "blinkmlive";
String password = "redgreenblue";

String colorfile = "rgb.txt";
HashMap colormap;  // stores String -> Color mappings of rgb.txt file

Twitter twitter;
TwitterStream twitterStream ;

String mentionString = "blinkn";
String[] trackStrings = new String[] { mentionString };  // for streaming mode

long lastMillis;
Color lastColor = Color.black;

void setup() {
  size(300,300);
  frameRate(5);

  colormap = parseColorFile(colorfile);

  // login if in normal, non-streaming mode
  //twitter = new Twitter(username,password); 

  // or connect this way, if streaming
  twitterStream = new TwitterStreamFactory().getInstance(username,password); 
  twitterStream.setStatusListener(listener);
  try { 
    twitterStream.filter( new FilterQuery(0, null, trackStrings ) );
  } catch( TwitterException twe ) {
    println("filter fail: "+twe);
  }

  lastMillis = millis();
}


void draw() {
  background( lastColor.getRGB() );
  long t = millis();
  if( (t-lastMillis) > 5000 ) { 
    lastMillis = t;
    println("thump");
    // if in normal logged in mode, checkMentions. 
    // if streaming, callbacks do it all
    //checkMentions();  
  }
  
}

//
// 
//
boolean parseColors(String text) {
  Color c = null;
  //println("text='"+text+"'");
  String linepat = mentionString + "\\s+(.+)\\b";
  Pattern p = Pattern.compile(linepat);
  Matcher m = p.matcher( text );
  if(  m.find() && m.groupCount() == 1 ) { // matched 
    String colorstr = m.group(1);
    println("match: "+colorstr );
    c = (Color) colormap.get( colorstr );
    if( c !=null ) { 
      println("color! "+c);
      lastColor = c;
      return true;
    }

    try {
      int hexint = Integer.parseInt( colorstr, 16 ); // try hex
      c = new Color( hexint );
      println("color! "+c);
      lastColor = c;
      return true;
    } catch( NumberFormatException nfe ) { 
    }
  }
  
  return false;
}

//
//
//
boolean parseColorMentions(String text) {
  String parts[] = text.split("\\s+");
  if( parts ==null ) return false;
  
  for(int j=0; j<parts.length; j++ ) {
    Color c = (Color) colormap.get(parts[j]);
    if( c !=null ) { 
      println("color! "+c);
      return true;
    }
  }
  return false;
}

//
// For streaming mode, this is what will do most all the work
//
StatusListener listener = new StatusListener(){
    public void onStatus(Status status) {
      println(status.getUser().getName() + " : " + status.getText());
      parseColors( status.getText() );
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


//
// Logged in mode: use this to check "@blinkm" mentions
//
void checkMentions() {
  println("getting mentions...");

  List<Status> statuses = null;
  try { 
    //statuses = twitter.getUserTimeline();
    statuses = twitter.getMentions(); //paging);    
  } 
  catch( TwitterException twe ) {
    println("error: "+twe);
  }
  
  if( statuses == null ) {
    println("no mentions");
    return;
  }

  for( int i=0; i< statuses.size(); i++ ) {
    Status status = statuses.get(i);
    String text = status.getText();
    println(status.getUser().getName() + ":" + text);
    parseColorMentions(text);
  }
  
}

//
List getTwitterMentions() {
  //paging = new Paging(20);
  List<Status> statuses = null;
  try { 
    //statuses = twitter.getUserTimeline();
    statuses = twitter.getMentions(); //paging);
    
  } 
  catch( TwitterException twe ) {
    println("error: "+twe);
  }
  return statuses;
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
      println(cname + " - " + colormap.get(cname));
    }
  }

  return colormap;
}
