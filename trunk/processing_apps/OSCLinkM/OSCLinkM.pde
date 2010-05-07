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
NetAddress myRemoteLocation;

int port = 12000;

LinkM linkm = new LinkM(); 

int blinkmaddr = 0;

static final boolean debug = true;

void setup() {
  size(400,400);
  frameRate(25);

  // start oscP5, listening for incoming messages at port 
  oscP5 = new OscP5(this,port);
  
  connectLinkM();
}


void draw() {
  background(0);  
}


/*
 * incoming osc message are forwarded to the oscEvent method. 
 */
void oscEvent(OscMessage oscmsg) {
  // print the address pattern and the typetag of the received OscMessage 
  
  if( debug ) {
    debug("### received an osc message."+oscmsg);
    debug(" addrpattern:'"+oscmsg.addrPattern() +
          "' typetag:'"+oscmsg.typetag() +
          "' timetag:'"+oscmsg.timetag() + "'");
  }

  try { 
    
    if( oscmsg.checkAddrPattern("/blinkm/fadeToRGB") ) { 
      
      if( oscmsg.checkTypetag("fff") ) {
        Color c = new Color( oscmsg.get(0).floatValue(),  // ranges from 0.0-1.0
                             oscmsg.get(1).floatValue(),
                             oscmsg.get(2).floatValue() );
        debug("fadeToRGB:"+c);
        linkm.fadeToRGB( blinkmaddr, c);  // does 0-1 -> 0-255 conversion for us
      }
      
    } // fadeToRGB
    if( oscmsg.checkAddrPattern("/blinkm/setRGB") ) { 
      
      if( oscmsg.checkTypetag("fff") ) {
        Color c = new Color( oscmsg.get(0).floatValue(),  // ranges from 0.0-1.0
                             oscmsg.get(1).floatValue(),
                             oscmsg.get(2).floatValue() );
        linkm.setRGB( blinkmaddr, c);  // does 0-1 -> 0-255 conversion for us
      }
      
    } // fadeToRGB
    else if( oscmsg.checkAddrPattern("/blinkm/toAddr") ) {
      if( oscmsg.checkTypetag("f") ) {
        blinkmaddr = int(oscmsg.get(0).floatValue());
      } 
      else if( oscmsg.checkTypetag("i") ) {
        blinkmaddr = oscmsg.get(0).intValue();
      }
    }
    
  } catch( IOException ioe ) { 
    println("couldn't send: "+ioe);
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
        println("connect: no linkm?  "+ioe);
    }

}

//
void debug(String s) {
  if(debug) println(s);
}

