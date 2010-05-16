/**
 * LinkMLibTest -- 
 *
 * Remember first to unzip "linkm.zip" into "~/Documents/Processing/libraries",
 * and closing/re-opening Processing so the library gets installed.
 * A commandline command to do this might be:
 * % unzip linkm.zip && mv linkm ~/Documents/Processing/Libraries
 *
 */
 
import thingm.linkm.*;

LinkM linkm = new LinkM();

int blinkmaddr = 0;


String helpstr = 
  "LinkMLibTest\n\n"+
  "'o' - turn blinkm off\n" +
  "'p' - play script 0\n" +
  "'r' - random color\n" +
  "'c' - reconnect to LinkM\n";

color lastColor = color(20);


void setup() 
{
  size(300,200);
  frameRate(20);

  try { 
    linkm.open();
    linkm.setFadeSpeed( blinkmaddr, 20);
  } catch(IOException ioe) { 
    println("Could not find LinkM \n"+ioe);
  }


}

void draw()
{
  background(lastColor);
  text(helpstr, 10,20, 200,100 );
}


void keyPressed() { 
  try { 
    if( key == 'o' ) {
      println("turning off");
      linkm.off( blinkmaddr );
    }
    else if( key == 'p' ) { 
      println("playing script 0");
      linkm.playScript( blinkmaddr, 0, 0,0 );
    }
    else if( key == 'r' ) {
      println("random color");
      int r = (int)random(255);
      int g = (int)random(255);
      int b = (int)random(255);
      lastColor = color(r,g,b);
      linkm.fadeToRGB(  blinkmaddr, r,g,b );
      //linkm.cmd(  blinkmaddr, 'c', r,g,b ); // equivalent
    }
    else if( key == 'c' ) { 
      println("reconnecting");
      linkm.close();
      linkm.open();
      linkm.getLinkMVersion();
    }
  } catch(IOException ioe) { 
    println("linkm error: "+ioe);
  }
}


