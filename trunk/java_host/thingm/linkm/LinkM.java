/**
 * LinkM -- interface to LinkM USB dongle
 *
 *
 * Tasks:
 *  - Upload light script    (read text file)
 *  - Download light script  (write text file)
 *  - Send BlinkM command    (as "{'c',0xff,0xff,0xff}" ?)
 *  - Scan I2C bus           (all 127 addrs?)
 *  - Do raw I2C transaction (as linkm-tool)
 *
 * 2009, Tod E. Kurt, ThingM, http://thingm.com/
 *
 */

package thingm.linkm;

import java.io.*;
import java.util.*;
import java.util.regex.*;
import java.awt.Color;

public class LinkM 
{
  static {
    System.loadLibrary("nativeLinkM");     // Load the library
  }  
  
  static public final int maxScriptLength = 49;

  static public int debug = 0;

  // Command byte values for linkm_command()
  // !!! NOTE: THIS MUST MATCH enum in linkm-lib.h !!!
  static final int LINKM_CMD_NONE    = 0; // no command, do not use
  // I2C commands
  static final int LINKM_CMD_I2CTRANS= 1; // i2c read/wri (N args: addr + other)
  static final int LINKM_CMD_I2CWRITE= 2; // i2c write    (N args: addr + other)
  static final int LINKM_CMD_I2CREAD = 3; // i2c read     (1 args: addr)
  static final int LINKM_CMD_I2CSCAN = 4; // i2c bus scan (2 args: start,end)
  static final int LINKM_CMD_I2CCONN = 5; // i2c connect/disc (1 args: 1/0)
  static final int LINKM_CMD_I2CINIT = 6; // i2c init         (0 args: )
  //
  static final int LINKM_CMD_STATLED   = 100;  // status LED set   (1 args: 1/0)
  static final int LINKM_CMD_STATLEDGET= 101;  // status LED get   (0 args)


  //---------------------------------------------------------------------------
  // Test Functionality
  //---------------------------------------------------------------------------

  /**
   * Demonstrates library usage by creating little command-line tool
   *
   */
  public static void usage() { 
    println(""+
"Usage: LinkM <cmd> [options]\n" +
"\n"+
"where <cmd> is one of:\n" +
"  --cmd <blinkmcmd> Send a blinkm command  \n" +
"  --off             Turn off blinkm at specified address (or all) \n" +
"  --play <n>        Play light script N \n" +
"  --stop            Stop playing light script \n" +
"  --getversion      Gets BlinkM version \n" +
"  --setaddr <newa>  Set address of blinkm at address 'addr' to 'newa' \n" +
"  --random <n>      Send N random colors to blinkm\n" +
"  --i2cscan         Scan I2c bus for devices  \n" +
"  --i2enable <0|1>  Enable or disable the I2C bus (for connecting devices) \n"+
"  --upload          Upload a light script to blinkm (reqs addr & file) \n"+
"  --download <n>    Download light script n from blinkm (reqs addr & file) \n"+
"  --linkmcmd        Send a raw linkm command  \n"+
"  --statled <0|1>   Turn on or off status LED  \n"+
"Options:\n"+
"  -h, --help                   Print this help message\n"+
"  -a addr, --addr=i2caddr      I2C address for command (default 0)\n"+
"  -f file, --afile=file        Read or save to this file\n"+
"  -m ms,   --miilis=millis     Set millisecs betwen actions (default 100)\n"+
"  -v, --verbose                verbose debugging msgs\n"+
"\n"+
"Note:  blah blah blah\n"
);
    System.exit(0);
  }

  public static void main(String args[]) {

    if( args.length == 0 ) {
      usage();
    }
    int addr = 0;
    int color = -1;
    int millis = 100;
    String cmd = null;
    long arg = -1;
    String file = null;
    byte[] argbuf = null;
    
    // argument processing
    int j=0;
    while( j< args.length ) {
      //for( int i=0; i< args.length; i++ ) {
      String a = args[j];
      if( a.equals("--addr") || a.equals("-a") ) {
        addr = parseHexDecInt( getArg(args,++j,"") );
      }
      //else if( a.equals("--color") || a.equals("-c") ) {
      //  color = parseHexDecInt( getArg(args,++j,"") );
      //  cmd = "color";
      //}
      else if( a.equals("--debug") || a.equals("-d") || a.equals("-v") ) { 
        debug++;
      }
      else if( a.equals("--millis") || a.equals("-m") ) {
        millis = parseHexDecInt( getArg(args,++j,"") );
      }
      else if( a.equals("--statled") ) {
        arg = parseHexDecInt( getArg(args,++j,"") );
        cmd = "statled";
      }
      else if( a.equals("--i2cscan") ) {
        cmd = "i2cscan";
      }
      else if( a.equals("--i2cenable") ) {
        arg = parseHexDecInt( getArg(args,++j,"") );
        cmd = "i2cenable";
      }
      else if( a.equals("--cmd")) {
        argbuf = parseArgBuf( args[++j] );  // blinkm cmd, c,0xff,0x33,0xdd
        cmd = "cmd";
      }
      else if( a.equals("--off") ) { 
        addr = parseHexDecInt( getArg(args,++j,"") );
        cmd = "off";
      }
      else if( a.equals("--play")) { 
        arg = parseHexDecInt( getArg(args,++j,"") );  // script num to play
        cmd = "play";
      }
      else if( a.equals("--stop")) {
        cmd = "stop";
      }
      else if( a.equals("--random")) {
        arg = parseHexDecInt( getArg(args,++j,"") );  // number of rand colors
        cmd = "random";
      }
      else if( a.equals("--upload")) {
        file = args[++j];
        cmd = "upload";
      }
      else if( a.equals("--download")) {
        cmd = "download";
      }
      else if( a.equals("--setaddr")) { 
        arg = parseHexDecInt( getArg(args,++j,"") );  // new addr
        cmd = "setaddr";
      }
      else if( a.equals("--readinputs")) { 
        cmd = "readinputs";
      }
      else if( a.equals("--help")) { 
        cmd = "help";
      }
      else if( a.equals("--factorysettings") ) {
        cmd = "factorysettings";
      }
      else { 
        file = args[j];
      }
      j++;
    } // while
    
    if( cmd == null || cmd.equals("help") ) {
      usage();
    }

    
    // 
    LinkM linkm = new LinkM();

    if( debug>0 ) {
      println("debug mode");
      linkm.linkmdebug( debug );
    }

    try { 
      linkm.open();
      
      // command handling

      if( cmd.equals("upload") ) {
        String[] lines = linkm.loadFile( file );
        BlinkMScript script = linkm.parseScript( lines );
        if( script == null ) {
          System.err.println("bad format in file");
          return;
        }
        script = script.trimComments(); 
        int len = script.length();
        if( debug>0 ) {
          for( int i=0; i < len; i++ ) 
            println(i+": "+script.get(i) );
        }

        println("Uploading "+len+" line script to BlinkM address "+addr);
        long st = System.currentTimeMillis();
        linkm.writeScript( addr, script );
        long et = System.currentTimeMillis();
        println("time to upload: "+(et-st)+" millisecs");
      }
      else if( cmd.equals("download") ) {
        if( addr == 0 ) { 
          println("Address 0 is not allowed. Set address with --addr=<addr>");
          return;
        }
        println("Downloading script #0 from BlinkM addr "+addr+"...");
        BlinkMScriptLine line = null;

        long st = System.currentTimeMillis();
        BlinkMScript script = linkm.readScript( addr, 0, false );
        long et = System.currentTimeMillis();
        println("time to download: "+(et-st)+" millisecs");

        for(int i=0; i< script.length(); i++ ) {
          line = script.get(i);
          println(line.toString());  
        }
      }
      else if( cmd.equals("setaddr") ) {
        if( addr == 0 ) { 
          println("Address 0 is not allowed. Set old addr with --addr=<addr>");
          return;
        }
        println("Changing BlinkM I2C from "+addr+" to "+arg);
        linkm.setAddress( addr, (int)arg );
      }
      else if( cmd.equals("i2cscan") ) { 
        if( addr == 0 ) addr = 1; // don't scan general call / broadcast addr
        println("I2C scan from addresses "+addr+" - "+(addr+16));
        byte[] addrs = linkm.i2cScan(addr,addr+16);
        if( addrs == null ) {
          println("no I2C devices found");
        } 
        else {
          int cnt = addrs.length;
          for( int i=0; i<cnt; i++) 
            println("device found at address "+addrs[i]);
        }
      }
      else if( cmd.equals("i2cenable") ) { 
        println("Seting I2C enable to "+arg);
        linkm.i2cEnable( ((arg!=0)?true:false) );
      }
      else if( cmd.equals("off") ) {
        println("Turning BlinkMs off at addr "+addr);
        linkm.off( addr );
      }
      else if( cmd.equals("statled") ) {
        println("Setting LinkM status LED to "+arg);
        linkm.statusLED( (int)arg );
      }
      else if( cmd.equals("cmd") ) {
        printHexString("Sending BlinkM command: ", argbuf );
        if( argbuf.length == 4 ) {   // deal with common case
          linkm.cmd3( addr, argbuf[0],argbuf[1],argbuf[2],argbuf[3] );
        } 
        else {                       // deal with general case
          byte[] cmdbuf = new byte[ argbuf.length + 1];
          cmdbuf[0] = (byte)addr;
          for(int i=1; i<cmdbuf.length; i++) 
            cmdbuf[i] = argbuf[i-1];
          int rsize = respSizeForCommand( argbuf[0] );
          byte[] respbuf = new byte[ rsize ];
          linkm.commandi2c( cmdbuf, respbuf );
          if( rsize > 0 ) 
            printHexString( "response: ", respbuf );
        }
      }
      else if( cmd.equals("play") ) {
        println("Playing light script #"+arg+" at addr "+addr);
        linkm.playScript( addr, (int)arg, 0,0 );
      }
      else if( cmd.equals("stop") ) { 
        println("Stopping any playing light script at addr "+addr);
        linkm.stopScript( addr );
      }
      else if( cmd.equals("setlength") ) {
        println("Setting length to "+arg+" for addr "+addr);
        linkm.setScriptLengthRepeats( addr, (int)arg, 0 ); //  0 reps = inf
      }
      else if( cmd.equals("factorysettings") ) {        
        if( addr == 0 ) { 
          println("Address 0 is not allowed. Set address with --addr=<addr>");
          return;
        }
        println("Setting BlinkM to factory settings for addr "+addr);
        linkm.setFactorySettings(addr);
      }
      else if( cmd.equals("readinputs") ) {
        if( addr == 0 ) {
          println("Must read from an address. Set address with --addr=<addr>");
          return;
        }
        print("Inputs: ");
        byte inputs[] = linkm.readInputs(addr);
        printHexString("inputs: ", inputs);

      } 
      else if( cmd.equals("random") ) { 
        Random rand = new Random();
        for( int i=0; i< arg; i++ ) { 
          int r = rand.nextInt() & 0xFF;
          int g = rand.nextInt() & 0xFF;
          int b = rand.nextInt() & 0xFF;
          linkm.setRGB( addr, r,g,b );
          linkm.pause(millis);
        }
      }
      
    } catch(IOException e) {
      System.err.println("error: "+e.getMessage());
    }
    
    linkm.close();
    
  }
  
  
  //---------------------------------------------------------------------------
  // Native method declarations
  //---------------------------------------------------------------------------

  /**
   * Open LinkM dongle 
   * @param vid vendor id of device
   * @param pid product id of device
   * @param vstr vender string of device
   * @param pstr product string of device
   * Setting these to {0,0,null,null} will open first default device found
   * Currently only one LinkM is supported
   */
  native void open(int vid, int pid, String vstr, String pstr)
    throws IOException;
  
  /**
   * Do a transaction with the LinkM dongle
   * length of both byte arrays determines amount of data sent or received
   * @param buf_send is byte array of command to send
   * @param buf_recv is byte array of any receive data, may be null
   * @throws linkm_command response code, 0 == success, non-zero == fail
   */
  native void command(int cmd, byte[] buf_send, byte[] buf_recv)
    throws IOException;
  
  /**
   * Close LinkM dongle
   */
  native void close();  
 
  /**
   * Set debug level
   * @param debug level. 0 == no debug. Higher values mean more.
   */
  native void linkmdebug(int d);

  /**
   * Testing byte array passing 
   */
  native byte[] test(byte[] buff);


  //---------------------------------------------------------------------------
  // Instance methods
  //---------------------------------------------------------------------------

  /**
   * Open the first LinkM found
   */
  public void open() throws IOException {
    open( 0,0, null,null );
  }

  /**
   * Do an I2C transaction via the dongle
   * @param buf_send is byte array of command to send
   * @param buf_recv is byte array of any receive data, may be null
   * length of both byte arrays determines amount of data sent or received
   */
  public void commandi2c( byte[] buf_send, byte[] buf_recv ) 
    throws IOException { 
    command( LINKM_CMD_I2CTRANS, buf_send, buf_recv);
  }

  /**
   * Set the state of LinkM's status LED 
   */
  public void statusLED(int val) 
    throws IOException {
    byte[] cmdbuf = { (byte)val };
    command( LINKM_CMD_STATLED, cmdbuf, null);
  }
  
  /**
   * Scan the I2C bus
   * @param start_addr start address of scan
   * @param end_addr end address of scan
   */
  public byte[] i2cScan(int start_addr, int end_addr)
    throws IOException { 
    byte[] cmdbuf = { (byte)start_addr, (byte)end_addr };
    byte[] recvbuf = new byte[ (end_addr-start_addr) ];  // FIXME:
    command( LINKM_CMD_I2CSCAN, cmdbuf, recvbuf);
    int cnt = recvbuf[0];     // number of addresses
    if( cnt > 0 ) {     //  got some addresses
      byte buf[] = new byte[cnt];
      for( int i=0; i<cnt; i++) 
        buf[i] = recvbuf[1+i];
      return buf;
    }
    return null;
  }

  /**
   * Enable or disable the I2C bus buffer
   *
   */
  public void i2cEnable(boolean state) 
    throws IOException { 
    byte[] cmdbuf = { (byte)((state)?1:0) };
    command( LINKM_CMD_I2CCONN, cmdbuf, null);
  }

  /**
   *
   */
  public void i2cInit()
    throws IOException { 
    command( LINKM_CMD_I2CINIT, null, null);
  }

  /**
   * Send a common 1-cmd + 3-arg style of command, with no response.
   */
  public void cmd3(int addr, int cmd, int arg1, int arg2, int arg3 )
    throws IOException {
    byte[] cmdbuf = { (byte)addr, (byte)cmd, (byte)arg1,(byte)arg2,(byte)arg3};
    commandi2c( cmdbuf, null );     // do i2c transaction with no recv
  }

  /**
   * Turn BlinkM at address addr off.
   */
  public void off(int addr) 
    throws IOException { 
    stopScript(addr);               
    setRGB(addr, 0,0,0 );
  }

  /**
   *
   */
  public byte[] getVersion(int addr)
    throws IOException { 
    byte[] cmdbuf = { (byte)addr, 'z' };
    byte[] recvbuf = new byte[ 2 ]; 
    commandi2c( cmdbuf, recvbuf );
    return recvbuf;
  }
  
  /**
   * Sets the I2C address of a BlinkM
   */
  public void setAddress(int addr, int newaddr)
    throws IOException { 
    byte[] cmdbuf = { (byte)addr, (byte)'A', (byte)newaddr, 
                      (byte)0xD0, (byte)0x0D, (byte)newaddr };
    commandi2c( cmdbuf, null );
  }

  /**
   * Play a light script
   */
  public void playScript(int addr, int script_id, int reps, int pos) 
    throws IOException {
    byte[] cmdbuf = { (byte)addr, 'p', (byte)script_id, (byte)reps, (byte)pos};
    commandi2c( cmdbuf, null );
  }
  /**
   * Pays the eeprom script (script id 0) from start, forever
   */
  public void playScript(int addr) 
    throws IOException {
    playScript(addr, 0,0,0);
  }
  
  /**
   * Stop any playing script at address 'addr'
   */
  public void stopScript(int addr) 
    throws IOException {
    debug("stopScript");
    byte[] cmdbuf = { (byte)addr, (byte)'o' };
    commandi2c( cmdbuf, null );
  }
  
  /**
   *
   */
  public void setRGB(int addr, int r, int g, int b) 
    throws IOException { 
    byte[] cmdbuf = { (byte)addr, 'n', (byte)r, (byte)g, (byte)b };
    commandi2c( cmdbuf, null );
  }

  /**
   *
   */
  public void fadeToRGB(int addr, int r, int g, int b) 
    throws IOException { 
    byte[] cmdbuf = { (byte)addr, 'c', (byte)r, (byte)g, (byte)b };
    commandi2c( cmdbuf, null );
  }

  /**
   *
   */
  public void fadeToRGB(int addr, Color color) 
    throws IOException { 
    fadeToRGB( addr, color.getRed(), color.getGreen(), color.getBlue());
  }

  /**
   *
   */
  public void fadeToRandomRGB(int addr, int r, int g, int b) 
    throws IOException { 
    byte[] cmdbuf = { (byte)addr, 'C', (byte)r, (byte)g, (byte)b };
    commandi2c( cmdbuf, null );
  }

  /**
   *
   */
  public void fadeToHSB(int addr, int h, int s, int b)
    throws IOException {
    byte[] cmdbuf = { (byte)addr, 'h', (byte)h, (byte)s, (byte)b };
    commandi2c( cmdbuf, null );
  }

  /**
   *
   */
  public void fadeToRandomHSB(int addr, int h, int s, int b)
    throws IOException {
    byte[] cmdbuf = { (byte)addr, 'H', (byte)h, (byte)s, (byte)b };
    commandi2c( cmdbuf, null );
  }

  /**
   * Return the RGB color the BlinkM is currently at.
   */
  public Color getRGBColor( int addr )
    throws IOException { 
    byte[] cmdbuf = { (byte)addr, 'g'};
    byte[] respbuf = new byte[3]; // 3 bytes of response, r,g,b 
    commandi2c( cmdbuf, respbuf);
    Color color = new Color( respbuf[0], respbuf[1], respbuf[2] );
    return color;
  }

  /**
   *
   */
  public void setFadeSpeed(int addr, int fadespeed)
    throws IOException { 
    byte[] cmdbuf = { (byte)addr, 'f', (byte)fadespeed };
    commandi2c( cmdbuf, null );
  }

  /**
   *
   */
  public void setTimeAdj(int addr, int timeadj)
    throws IOException { 
    byte[] cmdbuf = { (byte)addr, 't', (byte)timeadj };
    commandi2c( cmdbuf, null );
  }

  /**
   * Set boot params   cmd,mode,id,reps,fadespeed,timeadj
   */
  public void setStartupParams( int addr, int mode, int script_id, int reps, 
                                int fadespeed, int timeadj )
    throws IOException {
    byte cmdbuf[] = { (byte)addr, 'B', 1, (byte)script_id, (byte)reps, 
                      (byte)fadespeed, (byte)timeadj };
    commandi2c( cmdbuf, null );
    pause(20);  // enforce wait for EEPROM write
  }

  /**
   * Default values for startup params
   */
  public void setStartupParamsDefault(int addr) throws IOException {
    setStartupParams( addr, 1, 0, 0, 8, 0 );
  }

  /**
   * Set light script default length and repeats.
   * reps == 0 means infinite repeats
   */
  public void setScriptLengthRepeats( int addr, int len, int reps)
    throws IOException {
    byte[] cmdbuf = { (byte)addr, 'L', 0, (byte)len, (byte)reps };
    commandi2c( cmdbuf, null );
    pause(10);  // enforce wait for EEPROM write
  }

  /**
   *
   */
  public byte[] readInputs( int addr ) throws IOException { 
    debug("BlinkMComm.readInputs");
    byte[] cmdbuf = { (byte)addr, 'i'};
    byte[] respbuf = new byte[4]; // 4 bytes of response
    commandi2c( cmdbuf, respbuf);
    return respbuf;
  }

  /**
   *
   */
  public void writeScript( int addr, String scriptstr ) 
    throws IOException {
    BlinkMScript script = parseScript( scriptstr );
    writeScript( addr, script );
  }

  /**
   * Write an entire BlinkM light script as a BlinkMScript
   * to blinkm at address 'addr'.
   * NOTE: for a 48-line script, this takes about 858 msecs because of 
   *       enforced 10 msec delay and HID overhead from small report size
   * FIXME: speed this up by implementing second report size 
   * @param addr blinkm addr
   * @param script BlinkMScript object of script lines
   */
  public void writeScript( int addr,  BlinkMScript script) 
    throws IOException {
    int len = script.length();
    
    for( int i=0; i< len; i++ ) {
      writeScriptLine( addr, i, script.get(i) );
    }
    
    setScriptLengthRepeats( addr, len, 0);    
  }

  /**
   * Write a single BlinkM light script line at position 'pos'.
   * FIXME: hard-coded script_id 0 (only one that can be written for now, still)
   */
  public void writeScriptLine( int addr, int pos, BlinkMScriptLine line )
    throws IOException {
    debug("writeScriptLine: addr:"+addr+" pos:"+pos+" scriptline: "+line);
    // build up the byte array to send
    byte[] cmdbuf = new byte[9];    // 
    cmdbuf[0] = (byte)addr;         // i2c address of blinkm
    cmdbuf[1] = (byte)'W';          // "Write Script Line" command
    cmdbuf[2] = (byte) 0;           // script id (0==eeprom)
    cmdbuf[3] = (byte)pos;          // script line number
    cmdbuf[4] = (byte)line.dur;     // duration in ticks
    cmdbuf[5] = (byte)line.cmd;     // command
    cmdbuf[6] = (byte)line.arg1;    // cmd arg1
    cmdbuf[7] = (byte)line.arg2;    // cmd arg2
    cmdbuf[8] = (byte)line.arg3;    // cmd arg3
    
    commandi2c( cmdbuf, null);
    pause(10); // enforce at least 4.5msec delay between EEPROM writes
  }

  /**
   * Read a BlinkMScriptLine from 'script_id' and pos 'pos', 
   * from BlinkM at 'addr'.
   */
  public BlinkMScriptLine readScriptLine( int addr, int script_id, int pos )
    throws IOException {
    debug("readScriptLine: addr: "+addr+" pos:"+pos);
    //BlinkMScriptLine line = new BlinkMScriptLine();
    byte[] cmdbuf = new byte[4];     // 
    cmdbuf[0] = (byte)addr;          // i2c address of blinkm
    cmdbuf[1] = (byte)'R';           // "Write Script Line" command
    cmdbuf[2] = (byte)script_id;     // script id (0==eeprom)
    cmdbuf[3] = (byte)pos;           // script line number
    byte[] respbuf = new byte[5];    // 5 bytes in response 

    commandi2c( cmdbuf, respbuf );
    BlinkMScriptLine line = new BlinkMScriptLine();
    if( !line.fromByteArray(respbuf) ) return null;
    return line;  // we're bad
  }

  /**
   * Read an entire light script from a BlinkM at address 'addr' 
   * FIXME: this only really works for script_id==0
   * @param readAll read all script lines, or just the good ones
   */
  public BlinkMScript readScript( int addr, int script_id, boolean readAll ) 
    throws IOException { 
    BlinkMScript script = new BlinkMScript();
    BlinkMScriptLine line;
    for( int i = 0; i< maxScriptLength; i++ ) {
      line = readScriptLine( addr, script_id, i );
      if( line==null 
          || (line.cmd == 0xff && line.dur == 0xff) //(null or -1,-1 == bad loc 
          || (line.cmd == 0x00 && !readAll)
          ) { 
        return script;
        // ooo bad bad scriptline 
      } else { 
        script.add(line);
      }
    }
    return script;
  }

  /**
   * Read an entire light script, return as a string
   */
  public String readScriptToString( int addr, int script_id, boolean readAll )
    throws IOException {
    BlinkMScript script = readScript( addr, script_id, readAll );
    String str = script.toString();
    return str;
  }

  /**
   * Set a BlinkM back to factory settings
   * Writes a new light script and sets the startup paramters
   */
  public void setFactorySettings( int addr ) throws IOException {
    BlinkMScript script = new BlinkMScript();
    script.add( new BlinkMScriptLine(  1, 'f', 10,0,0 ) );
    script.add( new BlinkMScriptLine(100, 'c', 0xff,0xff,0xff) );
    script.add( new BlinkMScriptLine( 50, 'c', 0xff,0x00,0x00) );
    script.add( new BlinkMScriptLine( 50, 'c', 0x00,0xff,0x00) );
    script.add( new BlinkMScriptLine( 50, 'c', 0x00,0x00,0xff) );

    writeScript( addr, script);
    setStartupParamsDefault(addr);
  }


  static public void debug( String s ) {
    if(debug>0) println(s);
  }


  //---------------------------------------------------------------------------
  // Class methods
  //---------------------------------------------------------------------------

  /**
   * Essentially a sparse-array lookup-table for those commands that may 
   * return a value.
   */
  static final public int respSizeForCommand( int c ) {
    int s = 0;
    switch( c ) {
    case 'a': s = 1; break;
    case 'g': s = 3; break;
    case 'i': s = 1; break;
    case 'R': s = 5; break;
    case 'Z': s = 1; break;
    }
    return s;
  }

  /**
   * Load a text file and turn it into an array of Strings.
   */
  static final public String[] loadFile( String filename ) {
    return loadFile( new File(filename) );
  }

  /**
   * Load a text file and turn it into an array of Strings.
   */
  static final public String[] loadFile( File filename ) {
    ArrayList<String> linesl = new ArrayList<String>();
    String line;
    BufferedReader in = null;
    try { 
      in = new BufferedReader(new FileReader(filename));
      while( (line = in.readLine()) != null ) {
        linesl.add( line );
      }
    }
    catch( Exception ex ) { 
      System.err.println("error: "+ex);
      linesl = null;
    }
    finally { 
      try { if( in!=null) in.close(); } catch(Exception ex) {}
    }
    
    if( linesl != null ) { 
      String[] lines = new String[ linesl.size() ];
      for( int i=0; i<linesl.size(); i++) {
        lines[i] = linesl.get(i);
      }
      return lines;
    }
    return null;
  }

  /**
   *
   */
  static final public boolean saveFile( String filename, String scriptstr ) { 
    return saveFile( new File(filename), scriptstr );
  }

  /**
   * Take a script in String format and save it to as a text file.
   */
  static final public boolean saveFile( File file, String scriptstr ) { 
    //File f = new File( filename );
    BufferedWriter out = null;
    try { 
      out = new BufferedWriter(new FileWriter( file ));
      out.write(scriptstr);
    } catch( Exception ex ) { 
      System.err.println("error: "+ex);
      return false;
    } finally { 
      try { out.close(); } catch(Exception ex) {}
    }
    return true;
  }

  /**
   * Take a String containing an entire script and turn it into a BlinkMScript
   */
  static final public BlinkMScript parseScript( String scriptstr ) {
    return parseScript( scriptstr.split("\n") );
  }

  /**
   * Take an array of Strings and turn them into a BlinkMScript object
   */
  static final public BlinkMScript parseScript( String[] lines ) {
    BlinkMScriptLine bsl; 
    BlinkMScript script = new BlinkMScript();

    // matches a single line in form: {  100, {'c', 0xff,0x66,0x33}}
    String linepat = "\\{(.+?),\\{'(.+?)',(.+?),(.+?),(.+?)\\}\\}";
    Pattern p = Pattern.compile(linepat);
    if( lines==null ) return null;
    for( int i=0; i< lines.length; i++) { 
      bsl = null;
      String l = lines[i];

      String[] lineparts = l.split("//");  // in case there's a comment
      String ls = l.replaceAll("\\s+","");  // squash all spaces to zero

      Matcher m = p.matcher( ls );
      if(  m.find() && m.groupCount() == 5 ) { // matched everything
          int dur = parseHexDecInt( m.group(1) );
          char cmd = m.group(2).charAt(0);
          int a1 = parseHexDecInt( m.group(3) );
          int a2 = parseHexDecInt( m.group(4) );
          int a3 = parseHexDecInt( m.group(5) );
          //println("d:"+dur+",c:"+cmd+",a123:"+a1+","+a2+","+a3);
          bsl = new BlinkMScriptLine( dur, cmd, a1,a2,a3);
          if( lineparts.length > 1 ) 
            bsl.addComment( lineparts[1] );
      }
      else {  // didn't match everything => bad line
        if( lineparts.length > 1 ) {
          bsl = new BlinkMScriptLine();
          bsl.addComment( lineparts[1] );  // so add the bad line as a comment
        }
      }
      if( bsl != null ) script.add( bsl );
    }
    return script;
  }

  /**
   * Take an array of Strings and turn them into an array BlinkMScripts
   * (assumes the strings actually comprised more than one script)
   * FIXME: this is a really dumb way of doing this, gotta think more Perly
   */
  static final public BlinkMScript[] parseScripts( String[] lines ) {
    String scriptbeginpat = "^\\s*\\{\\s*$";
    String scriptendpat   = "^\\s*\\}\\s*$";  // FIXME:don't forget comma
    Pattern pb = Pattern.compile(scriptbeginpat);
    Pattern pe = Pattern.compile(scriptendpat);
    int i=0;
    int ib,ie;  // begining and end pos of a single script
    ArrayList<BlinkMScript> scriptlist = new ArrayList<BlinkMScript>();
    while( i < lines.length ) { 
      String l = lines[i];
      Matcher mb = pb.matcher( l );
      if( mb.find() ) {               // found open paren 
        //debug("parseScripts: open paren at line "+i);
        i++;  // skip to next line
        ib = i;  // save begining pos of script
        while( i < lines.length ) {
          l = lines[i];
          //debug("line "+i+":'"+l+"'");
          Matcher me = pe.matcher( l ); // look for close paren
          if( me.find() ) { 
            //debug("parseScripts: close paren at line "+i);
            ie = i;  // save end
            String[] scriptlines = new String[ie-ib];
            System.arraycopy( lines, ib, scriptlines, 0, (ie-ib) );
            //for( int k=0; k<scriptlines.length; k++)
            //  debug("scriptlines["+k+"]: "+scriptlines[k]);
            BlinkMScript script = parseScript( scriptlines );
            scriptlist.add( script );
            //debug("parseScripts: script added.");
            break;
          } 
          i++;
        } // while still in file
      } // if begining found
      i++;  // otherwise go to next line
    }

    if( scriptlist.size() > 0 ) {
      BlinkMScript[] scripts = new BlinkMScript[ scriptlist.size() ];
      for( i=0; i<scriptlist.size(); i++) {
        scripts[i] = scriptlist.get(i);
      }
      return scripts;
    }
    return null;
  }

  //-------------------------------------------------------------------------
  // Utilty Class methods
  //-------------------------------------------------------------------------

  /**
   * Utility: A simple delay
   */
  static final public void pause( int millis ) {
      try { Thread.sleep(millis); } catch(Exception e) { }
  }

  static final public void println(String s) { 
    System.out.println(s);
  }
  static final public void print(String s) { 
    System.out.print(s);
  }

  static final public void printHexString(String intro, byte[] buf) {
    System.out.print(intro);
    if( buf==null ) {
      System.out.println("null");
      return;
    }
    for( int i=0;i<buf.length; i++ ) 
      System.out.print( "0x"+ hex(buf[i],2) +" ");
    println("");
  }

  /**
   * Utility: int to string
   * Stolen from Processing's PApplet.java
   */
  static final public String hex(int what, int digits) {
    String stuff = Integer.toHexString(what).toUpperCase();
    int length = stuff.length();
    if (length > digits)
      return stuff.substring(length - digits);
    else if (length < digits)
      return "00000000".substring(8 - (digits-length)) + stuff;
    return stuff;
  }

  /**
   * Utility: Return either the element in args at pos i or the default
   */
  static final String getArg( String args[], int i, String def ) {
    if( i<args.length )
      return args[i];
    return def;
  }
  
  /**
   * Utility: Split up a string into parts, each parsed as a num,hex,char
   */
  static final public byte[] parseArgBuf(String s) {
    String[] a = s.split("[, ]");
    byte[] b = new byte[ a.length ];
    for( int i=0; i<a.length; i++ ) {
      b[i] = (byte) parseHexDecInt(a[i]);
    }
    return b;
  }

  /**
   * Utility: parse a hex or decimal integer
   */
  static final public int parseHexDecInt(String s) {
    int n=0;
    s = s.replaceAll("[\'\"]", "");  // remove any quotes
    try { 
      if( s.indexOf("0x") != -1 ) // it's hex
        n = Integer.parseInt( s.replaceAll("0x",""), 16 ); // yuck
      else if( Character.isLetter(s.charAt(0)) )  // ascii
        n = (int) s.charAt(0);
      else 
        n = Integer.parseInt( s, 10 );
    } catch( Exception e ) {}
    return n;
  }
  
}





  /*
   * Test use
   *
  public static void main0(String args[]) {
    byte buf[];

    if( args.length == 0 ) {
      println("usage: LinkM <string>");
      System.exit(0);
    }

    byte strbuf[] = new byte[args.length];
    for( int i=0; i< args.length; i++ ) {
      strbuf[i] = (byte)Integer.parseInt(args[i],16);
    }
    //String str = args[0];
    //byte strbuf[] = str.getBytes();
    
    LinkM linkm = new LinkM();

    buf = linkm.test( strbuf );
    for(int i=0;i<buf.length;i++) {
      byte b = buf[i];
      System.out.print("("+hex(b,2)+")"+(char)buf[i]);
    }
    println();

  }
  */

