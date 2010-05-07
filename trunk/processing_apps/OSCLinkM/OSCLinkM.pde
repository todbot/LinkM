/**
 *
 * OSCLinKM -- simple OSC to LinkM to BlinkM server 
 * 
 *
 * /blinkm/toAddr <int>
 * /blinkm/fadeToRGB  <R><G><B>
 * /blinkm/setRGB  <R><G><B>
 * /blinkm/fadeHSB  <H><S><B>  not implemented yet
 * 
 *
 * 2010 Tod E. Kurt, http://thingm.com/
 *
 */

import java.awt.*;

import thingm.linkm.*;

import oscP5.*;
import netP5.*;

OscP5 oscP5;

// UDP port for receiving OSC messages
int port = 12000;

LinkM linkm = new LinkM(); 

// blinkm i2c address (can be changed with "/blinkm/toAddr" OSC message
int blinkmaddr = 0;

static final boolean debug = true;

PFont font;
String lastMsg=null;

void setup() {
  size(300,150);
  frameRate(25);
  font = loadFont("HelveticaNeue-CondensedBold-18.vlw"); 

  connectLinkM();

  // start oscP5, listening for incoming messages at port 
  oscP5 = new OscP5(this,port);
  
}


void draw() {
  background(0);  
  text("OSCLinKM: listening on port "+port, 20,20);
  if( lastMsg !=null ) text("status: "+lastMsg, 20, 100);
}


/*
 * incoming osc message are forwarded to the oscEvent method. 
 */
void oscEvent(OscMessage oscmsg) {
  // print the address pattern and the typetag of the received OscMessage 
  
  if( debug ) {
    debug("osc message: "+
          " addrpattern:'"+oscmsg.addrPattern() +
          "' typetag:'"+oscmsg.typetag() +
          "' timetag:'"+oscmsg.timetag() + "'");
  }

  try { 
    
    if( oscmsg.checkAddrPattern("/blinkm/toAddr") ) {
      if( oscmsg.checkTypetag("f") ) {  // single float or int argument
        blinkmaddr = int(oscmsg.get(0).floatValue());
      } 
      else if( oscmsg.checkTypetag("i") ) {
        blinkmaddr = oscmsg.get(0).intValue();
      }
      debug("toAddr:"+blinkmaddr);
    }
    else if( oscmsg.checkAddrPattern("/blinkm/fadeToRGB") ) { 
      if( oscmsg.checkTypetag("fff") ) {  // 3 float argument
        Color c = new Color( oscmsg.get(0).floatValue(),  // ranges from 0.0-1.0
                             oscmsg.get(1).floatValue(),
                             oscmsg.get(2).floatValue() );
        debug("fadeToRGB:"+c);
        linkm.fadeToRGB( blinkmaddr, c);  // does 0-1 -> 0-255 conversion for us
      }
    }
    else if( oscmsg.checkAddrPattern("/blinkm/setRGB") ) { 
      if( oscmsg.checkTypetag("fff") ) {
        Color c = Color.getHSBColor( oscmsg.get(0).floatValue(),
                                     oscmsg.get(1).floatValue(),
                                     oscmsg.get(2).floatValue() );
        debug("setRGB:"+c);
        linkm.setRGB( blinkmaddr, c);  // does 0-1 -> 0-255 conversion for us
      }
    }
    else if( oscmsg.checkAddrPattern("/blinkm/fadeToHSB") ) { 
      if( oscmsg.checkTypetag("fff") ) {
        int h = (int)(oscmsg.get(0).floatValue() * 255);
        int s = (int)(oscmsg.get(1).floatValue() * 255);
        int b = (int)(oscmsg.get(2).floatValue() * 255);
        debug("fadeToHSB:"+h+","+s+","+b);
        linkm.fadeToHSB( blinkmaddr, h,s,b);
      }
    }
    
  } catch( IOException ioe ) { 
    debug("couldn't send",ioe);
    connectLinkM();  // try to reconnect
  }
  

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

void debug(String s) {
  debug( s,null);
}
//
void debug(String s1, Object s2) {
  String s = s1;
  if( s2!=null ) s = s1 + " : " + s2;
  if(debug) println(s);
  lastMsg = s1;
}

