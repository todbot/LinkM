/**
 *
 * OSCLinKM -- simple OSC to LinkM to BlinkM server 
 * 
 *
 * /blinkm/toAddr <int>
 * /blinkm/fadeToRGB  <R><G><B>
 * /blinkm/setRGB  <R><G><B>
 * /blinkm/fadeHSB  <H><S><B> 
 * /blinkm/fadeHB   <H><B>
 *
 * /blinkm/playScript1 <1>
 *
 * 2010 Tod E. Kurt, http://thingm.com/
 *
 */

import java.awt.*;

import thingm.linkm.*;

import oscP5.*;
import netP5.*;

// UDP port for receiving OSC messages
int port = 8888; ///12000;

// blinkm i2c address (can be changed with "/blinkm/toAddr" OSC message
int blinkmaddr = 0;

OscP5 oscP5;

LinkM linkm = new LinkM(); 

static final int debug = 2;

PFont font;
String lastMsg=null;

void setup() {
  size(300,150);
  frameRate(25);
  //  font = loadFont("HelveticaNeue-CondensedBold-18.vlw"); 
  //textFont( font,12 );
  //textFont(12);

  connectLinkM();

  // start oscP5, listening for incoming messages at port 
  oscP5 = new OscP5(this,port);
  
}


void draw() {
  background(0);  
  text("OSCLinkM: listening on port "+port, 20,20);
  if( lastMsg !=null ) text("status: "+lastMsg, 20, 100, width,100);
}


/*
 * incoming osc message are forwarded to the oscEvent method. 
 */
void oscEvent(OscMessage oscmsg) {
  // print the address pattern and the typetag of the received OscMessage 

  if( debug>1 ) {
    debug("osc message: "+
          " addrpattern:'"+oscmsg.addrPattern() +
          "' typetag:'"+oscmsg.typetag() +
          "' timetag:'"+oscmsg.timetag() + "'");
  }

  String addrPattern = oscmsg.addrPattern();
  try { 
    
    if( addrPattern.equals("/blinkm/toAddr") ) {
      if( oscmsg.checkTypetag("f") ) {  // single float or int argument
        blinkmaddr = int(oscmsg.get(0).floatValue());
      } 
      else if( oscmsg.checkTypetag("i") ) {
        blinkmaddr = oscmsg.get(0).intValue();
      }
      debug("toAddr: "+blinkmaddr);
    }
    else if( addrPattern.equals("/blinkm/fadeToRGB") ) { 
      if( oscmsg.checkTypetag("fff") ) {  // 3 float argument
        Color c = new Color( oscmsg.get(0).floatValue(),  // ranges from 0.0-1.0
                             oscmsg.get(1).floatValue(),
                             oscmsg.get(2).floatValue() );
        debug("fadeToRGB: "+c);
        linkm.fadeToRGB( blinkmaddr, c);  // does 0-1 -> 0-255 conversion for us
      }
    }
    else if( addrPattern.equals("/blinkm/setRGB") ) { 
      if( oscmsg.checkTypetag("fff") ) {
        Color c = Color.getHSBColor( oscmsg.get(0).floatValue(),
                                     oscmsg.get(1).floatValue(),
                                     oscmsg.get(2).floatValue() );
        debug("setRGB: "+c);
        linkm.setRGB( blinkmaddr, c);  // does 0-1 -> 0-255 conversion for us
      }
    }
    else if( addrPattern.equals("/blinkm/fadeToHSB") ) { 
      if( oscmsg.checkTypetag("fff") ) {
        int h = (int)(oscmsg.get(0).floatValue() * 255);
        int s = (int)(oscmsg.get(1).floatValue() * 255);
        int b = (int)(oscmsg.get(2).floatValue() * 255);
        debug("fadeToHSB: "+h+","+s+","+b);
        linkm.fadeToHSB( blinkmaddr, h,s,b);
      }
    }
    else if( addrPattern.equals("/blinkm/fadeToHB") ) { 
      if( oscmsg.checkTypetag("ff") ) {
        int h = (int)(oscmsg.get(0).floatValue() * 255);
        int s = 255;
        int b = (int)(oscmsg.get(1).floatValue() * 255);
        debug("fadeToHB: "+h+","+s+","+b);
        linkm.fadeToHSB( blinkmaddr, h,s,b);
      }
    }
    else if( addrPattern.equals("/blinkm/setFadeSpeed") ) {
      if( oscmsg.checkTypetag("f") ) {
          int val = (int)(oscmsg.get(0).floatValue() * 127);  // NOTE! 127
          debug("setFadeSpeed: "+val);
          linkm.setFadeSpeed( blinkmaddr, val );
      }
    }
    else if( addrPattern.equals("/blinkm/setTimeAdj") ) {
      if( oscmsg.checkTypetag("f") ) {
          int val = -25 + (int)(oscmsg.get(0).floatValue() * 25);  // NOTE! 50
          debug("setFadeSpeed: "+val);
          linkm.setTimeAdj( blinkmaddr, val );
      }
    }
    else if( addrPattern.equals("/blinkm/stopScript") ) {
      if( oscmsg.checkTypetag("f") ) {
          float val = oscmsg.get(0).floatValue();
          if( val == 1.0 ) {
              debug("stopScript:");
              linkm.stopScript( blinkmaddr );
          }
      }
    }
    else if( addrPattern.startsWith("/blinkm/playScript") ) { 
        String nstr = addrPattern.replaceAll("/blinkm/playScript","");
        Integer n = Integer.parseInt(nstr);
        if( oscmsg.checkTypetag("f") ) {
            float val = oscmsg.get(0).floatValue();
            if( val == 1.0 ) {
                debug("playScript: "+n);
                linkm.playScript( blinkmaddr, n, 0,0);
            }
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

//
void debug(String s) {
  debug( s,null);
}
//
void debug(String s1, Object s2) {
  String s = s1;
  if( s2!=null ) s = s1 + " : " + s2;
  if(debug>0) println(s);
  lastMsg = s1;
}

