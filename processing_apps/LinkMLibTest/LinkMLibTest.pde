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

LinkM linkm;

int addr = 0;

void setup() 
{
  size(255,200);
  frameRate(10);
  linkm = new LinkM();  
  try { 
    linkm.open();
  } catch(IOException ioe) { 
    println("Could not find LinkM \n"+ioe);
  }
}

void draw()
{
  background(100);
  
}

void keyPressed() { 
  try { 
  if( key  == CODED ) {
    if( keyCode == LEFT ) { 
    }
    else if( keyCode == RIGHT ) {
    }
  }
  else if( key == '0' ) {
    println("turning off");
    linkm.off( addr );
  }
  else if( key == 'r' ) {
    println("random color");
    int r = (int)random(255);
    int g = (int)random(255);
    int b = (int)random(255);
    linkm.cmd(  9, 'n', r,g,b );
    linkm.cmd( 10, 'n', r,g,b );
    linkm.cmd( 12, 'n', r,g,b );
  }
  } catch(IOException ioe) { println(ioe); }
}


