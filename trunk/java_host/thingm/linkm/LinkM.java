/**
 * LinkM -- interface to LinkM USB dongle
 *
 * This is both a library for use by other programs,
 * as well as a command-line demonstration/utilty app
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

/**
 * The entry point into the LinkM Java API.
 * It depends on a native C library, named (depending on your OS)
 * "libLinkM.dylib", "libLinkM.so", "LinkM.dll". 
 * 
 * This class also provides a main() function that acts as a command-line
 * exerciser of the API.
 *
 */
public class LinkM 
{
  static {
    System.loadLibrary("LinkM");     // Load the library
  }  
  
  static public final int maxScriptLength = 49;

  static public final int writePauseMillis = 15;

  static public int pausemillis = 100;

  static public int debug = 0;

  // Command byte values for linkm_command()
  //
  // !!! NOTE: THIS MUST MATCH enum in linkm-lib.h !!!
  //
  static final int LINKM_CMD_NONE    = 0; // no command, do not use
  // I2C commands
  static final int LINKM_CMD_I2CTRANS= 1; // i2c read/wri (N args: addr+other)
  static final int LINKM_CMD_I2CWRITE= 2; // i2c write    (N args: addr+other)
  static final int LINKM_CMD_I2CREAD = 3; // i2c read     (1 args: addr)
  static final int LINKM_CMD_I2CSCAN = 4; // i2c bus scan (2 args: start,end)
  static final int LINKM_CMD_I2CCONN = 5; // i2c connect/disc (1 args: 1/0)
  static final int LINKM_CMD_I2CINIT = 6; // i2c init         (0 args: )
  // linkm commands
  static final int LINKM_CMD_VERSIONGET= 100;  // version get    (0 args)
  static final int LINKM_CMD_STATLEDSET= 101;  // status LED set (1 args: 1/0)
  static final int LINKM_CMD_STATLEDGET= 102;  // status LED get    (0 args)
  static final int LINKM_CMD_PLAYERSET = 103;  // set params        (7 args)
  static final int LINKM_CMD_PLAYERGET = 104;  // get params        (0 args)
  static final int LINKM_CMD_EESAVE    = 105;  // save params to EE (0 args)
  static final int LINKM_CMD_EELOAD    = 106;  // load params fr EE (0 args)
  static final int LINKM_CMD_GOBOOTLOAD= 107;  // trigger USB bootload

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
"  --on              Play startup script at address (or all) \n" +
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
"  --linkmversion    Get LinkM version \n"+
"  --statled <0|1>   Turn on or off status LED  \n"+
"  --gobootload      Tell LinkM to go into its bootloaer\n"+
"  --factoryreset    Restore a BlinkM to factory conditions \n"+

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
    String cmd = null;
    long arg = -1;
    String file = null;
    byte[] argbuf = null;
    
    // argument processing
    int ac=0;
    while( ac< args.length ) {
      //for( int i=0; i< args.length; i++ ) {
      String rawa = args[ac];
      String a = rawa.replaceAll("-","");
      if( a.equals("addr") || a.equals("a") ) {
        addr = parseHexDecInt( getArg(args,++ac,"") );
      }
      //else if( a.equals("--color") || a.equals("-c") ) {
      //  color = parseHexDecInt( getArg(args,++ac,"") );
      //  cmd = "color";
      //}
      else if( a.equals("debug") || a.equals("d") || a.equals("v") ) { 
        debug++;
      }
      else if( a.equals("millis") || a.equals("m") ) {
        pausemillis = parseHexDecInt( getArg(args,++ac,"") );
      }
      else if( a.equals("statled") ) {
        arg = parseHexDecInt( getArg(args,++ac,"") );
        cmd = "statled";
      }
      else if( a.equals("i2cscan") ) {
        cmd = "i2cscan";
      }
      else if( a.equals("i2cenable") ) {
        arg = parseHexDecInt( getArg(args,++ac,"") );
        cmd = "i2cenable";
      }
      else if( a.equals("cmd")) {
        argbuf = parseArgBuf( args[++ac] );  // blinkm cmd, c,0xff,0x33,0xdd
        cmd = "cmd";
      }
      else if( a.equals("off") ) { 
        addr = parseHexDecInt( getArg(args,++ac,"") );
        cmd = "off";
      }
      else if( a.equals("on") ) { 
        cmd = "on";
      }
      else if( a.equals("play")) { 
        arg = parseHexDecInt( getArg(args,++ac,"") );  // script num to play
        cmd = "play";
      }
      else if( a.equals("stop")) {
        cmd = "stop";
      }
      else if( a.equals("random")) {
        arg = parseHexDecInt( getArg(args,++ac,"") );  // number of rand colors
        cmd = "random";
      }
      else if( a.equals("upload")) {
        file = args[++ac];
        cmd = "upload";
      }
      else if( a.equals("download")) {
        cmd = "download";
      }
      else if( a.equals("getversion")) {
        cmd = "getversion";
      }
      else if( a.equals("setaddr")) { 
        arg = parseHexDecInt( getArg(args,++ac,"") );  // new addr
        cmd = "setaddr";
      }
      else if( a.equals("readinputs")) { 
        cmd = "readinputs";
      }
      else if( a.equals("help")) { 
        cmd = "help";
      }
      else if( a.equals("linkmversion") ) {
        cmd = "linkmversion";
      }
      else if( a.equals("factoryreset") ) {
        cmd = "factoryreset";
      }
      else if( a.equals("gobootload") ) {
        cmd = "gobootload";
      }
      else if( a.equals("bootload") ) {
        cmd = "bootload";
      }
      else if( a.equals("bootloadreset") ) {
        cmd = "bootloadreset";
      }
      else { 
        file = args[ac];
      }
      ac++;
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

      // linkmboot commands
      if( cmd.equals("bootload") ) {
        println("LinkMBoot flashing...");
        linkm.bootload( file, false);
        println("flashing done.");
        return;
      }
      else if( cmd.equals("bootloadreset") ) {
        println("LinkMBoot reset, switching to LinkM mode");
        linkm.bootloadReset();
        return;
      }
      
      // otherwise, begin normal linkm tasks
      linkm.open();
      
      // normal linkm command handling
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
        //if( addr == 0 ) addr = 1; // don't scan general call/ broadcast addr
        println("I2C scan from addresses "+1+" - "+113);
        byte[] addrs = linkm.i2cScan(1,113);
        if( addrs.length == 0 ) {
          println("no devices found");
        } else { 
          for( int i=0; i< addrs.length; i++) {
            println("device found at addr: "+ addrs[i] );
          }
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
      else if( cmd.equals("on") ) {
        println("Turning BlinkMs on at addr "+addr);
        linkm.playScript( addr, 0, 0,0 );
      }
      else if( cmd.equals("statled") ) {
        println("Setting LinkM status LED to "+arg);
        linkm.statusLED( (int)arg );
      }
      else if( cmd.equals("linkmversion") ) {
        print("LinkM Version: ");
        byte[] ver = linkm.getLinkMVersion();
        if( ver != null ) { 
          printHexString("",ver);
        } else {
          println("error, getlinkmversion returned null");
        }
      }
      else if( cmd.equals("gobootload") ) {
        println("LinkM switching to bootloader:");
        linkm.goBootload();
        println("LinkM now in bootloader mode.");
      }
      else if( cmd.equals("cmd") ) {
        printHexString("Sending BlinkM command: ", argbuf );
        if( argbuf.length == 4 ) {   // deal with common case
          linkm.cmd( addr, argbuf[0],argbuf[1],argbuf[2],argbuf[3] );
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
      else if( cmd.equals("getversion") ) { 
        if( addr == 0 ) { 
          println("Address 0 is not allowed. Set address with --addr=<addr>");
        }
        println("Getting version at addr "+addr);
        byte[] ver = linkm.getVersion( addr );
        if( ver != null ) { 
          println("version: "+(char)ver[0]+","+(char)ver[1]);
        } else {
          println("error, getversion returned null");
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
      else if( cmd.equals("factoryreset") ) {        
        println("Setting BlinkM to factory settings for addr "+addr);
        linkm.doFactoryReset(addr);
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
        long st = System.currentTimeMillis();
        for( int i=0; i< arg; i++ ) { 
          int r = rand.nextInt() & 0xFF;
          int g = rand.nextInt() & 0xFF;
          int b = rand.nextInt() & 0xFF;
          linkm.setRGB( addr, r,g,b );
          linkm.pause(pausemillis);
        }
        long et = System.currentTimeMillis();
        println("elapsed time: "+(et-st)+" millisecs");
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
  public native void open(int vid, int pid, String vstr, String pstr)
    throws IOException;
  
  /**
   * Do a transaction with the LinkM dongle
   * length of both byte arrays determines amount of data sent or received
   * @param cmd the linkm command code
   * @param buf_send is byte array of command to send, may be null
   * @param buf_recv is byte array of any receive data, may be null
   * @throws linkm_command response code, 0 == success, non-zero == fail
   */
  public native synchronized void command(int cmd, byte[] buf_send, byte[] buf_recv)
    throws IOException;

  /**
   * Send many I2C commands as fast as possible, with no readback
   *
   * @param cmd the linkm command code
   * @param cmd_count number of commands in buf_send
   * @param cmd_len length of each command
   * @param buf_send is byte array of command to send, may be null
   *
   * @warning this may bork things
   */
  native void commandmany( int cmd, int cmd_count, int cmd_len, byte[] buf_send)
    throws IOException;

  /**
   * Close LinkM dongle
   */
  public native void close();  
 
  /**
   * Set debug level
   * @param debug level. 0 == no debug. Higher values mean more.
   */
  native void linkmdebug(int d);

  /**
   * Testing byte array passing 
   */
  native byte[] test(byte[] buff);


  public native void bootload(String filename, boolean reset) throws IOException;
  public native void bootloadReset() throws IOException;

  //---------------------------------------------------------------------------
  // Instance methods
  //---------------------------------------------------------------------------

  /**
   * Open the first LinkM found
   * @throws IOException if no LinkM found
   */
  public void open() throws IOException {
    open( 0,0, null,null );
  }

  /**
   * Do an I2C transaction via the dongle
   * length of both byte arrays determines amount of data sent or received
   * @param buf_send is byte array of command to send
   * @param buf_recv is byte array of any receive data, may be null
   * @throws IOException on transmit or receive error
   */
  public void commandi2c( byte[] buf_send, byte[] buf_recv ) 
    throws IOException { 
    command( LINKM_CMD_I2CTRANS, buf_send, buf_recv);
  }

  /**
   * Set the playticker / playset parameters 
   *
   * @param playing     on/off state of playTicker
   * @param script_id   the script id to play (usually 0)
   * @param script_tick the number of ticks between lines in the script
   * @param script_len  the length of the script in script lines
   * @param start_pos   starting position of script (usually 0)
   * @throws IOException on transmit or receive error
   */
  public void setPlayset( boolean playing, int script_id, int script_tick, 
                          int script_len, int start_pos, int fadespeed,
                          int dir ) 
    throws IOException {
    byte[] cmdbuf = { (byte)(playing?1:0), (byte)script_id, (byte)script_tick,
                      (byte)script_len, (byte)start_pos, (byte)script_len,
                      (byte)dir };
    command( LINKM_CMD_PLAYERSET, cmdbuf, null );
  }
  
  /**
   * Get playticker parameters
   * @throws IOException on transmit or receive error
   */
  public byte[] getPlayset() throws IOException {
    byte[] recvbuf = new byte[ 7 ];
    command( LINKM_CMD_PLAYERGET, null, recvbuf );
    return recvbuf;
  }

  /**
   * Save the playticker parameters from RAM to EEPROM
   * @throws IOException on transmit or receive error
   */
  public void eeParamSave() throws IOException {
    command( LINKM_CMD_EESAVE, null, null );
  }
  /**
   * Load the playticker parameters from EEPROM to RAM
   * @throws IOException on transmit or receive error
   */
  public void eeParamLoad() throws IOException {    
    command( LINKM_CMD_EELOAD, null, null );
  }


  /**
   * Get LinkM firmware version
   * @throws IOException on transmit or receive error
   */
  public byte[] getLinkMVersion() throws IOException {
    byte[] recvbuf = new byte[ 2 ];
    command( LINKM_CMD_VERSIONGET, null, recvbuf );
    return recvbuf;
  }

  /**
   * Tell LinkM to switch to its USB bootloader mode
   * @throws IOException on transmit or receive error
   */
  public void goBootload() throws IOException {
    command( LINKM_CMD_GOBOOTLOAD, null, null );
  }
  
  /**
   * Set the state of LinkM's status LED 
   * @note future versions of LinkM might support brightness levels
   * @param val 1 = turn LED on, 0 = turn LED off
   * @throws IOException on transmit or receive error
   */
  public void statusLED(int val) 
    throws IOException {
    byte[] cmdbuf = { (byte)val };
    command( LINKM_CMD_STATLEDSET, cmdbuf, null);
  }

  
  /**
   * FIXME: currently ignores start_addr and end_addr
   * @param start_addr start address of scan
   * @param end_addr end address of scan
   * @throws IOException on transmit or receive error
   */
  public byte[] i2cScan(int start_addr, int end_addr)
    throws IOException {
    ArrayList<Integer> addrlist = new ArrayList<Integer>();
    for( int i=0; i<7; i++ ) {
      int addr = i*16 + 1;
      byte[] addrs = i2cScan16(addr,addr+16);
      if( addrs != null ) {
        for( int j=0; j<addrs.length; j++ ) {
          addrlist.add( new Integer(addrs[j]) );
        }
      }
    }
    byte addrs[] = new byte[addrlist.size()];
    for( int i=0; i<addrs.length; i++) {
      addrs[i] = addrlist.get(i).byteValue();
    }    
    return addrs;
  }

  /**
   * Scan the I2C bus
   * FIXME: only works for spans up to 16 addrs
   * @param start_addr start address of scan
   * @param end_addr end address of scan
   * @throws IOException on transmit or receive error
   */
  public byte[] i2cScan16(int start_addr, int end_addr)
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
   * By selectively disabling and enabling the bus buffer you can do hotswap
   * @param state set to true to enable I2C bus, false to disable
   * @throws IOException on transmit or receive error
   */
  public void i2cEnable(boolean state) 
    throws IOException { 
    byte[] cmdbuf = { (byte)((state)?1:0) };
    command( LINKM_CMD_I2CCONN, cmdbuf, null);
  }

  /**
   * (Re)Initialize the I2C subsystem on LinkM
   * @throws IOException on transmit or receive error
   */
  public void i2cInit()
    throws IOException { 
    command( LINKM_CMD_I2CINIT, null, null);
  }

  /**
   * Send a common 1-cmd + 3-arg style of command, with no response.
   * @param addr i2c address
   * @param cmd first byte of command
   * @param arg1 first argument (if any)
   * @param arg2 first argument (if any)
   * @param arg3 first argument (if any)
   * @throws IOException on transmit or receive error
   */
  public void cmd(int addr, int cmd, int arg1, int arg2, int arg3 )
    throws IOException {
    byte[] cmdbuf = { (byte)addr, (byte)cmd, (byte)arg1,(byte)arg2,(byte)arg3};
    commandi2c( cmdbuf, null );     // do i2c transaction with no recv
  }

  /**
   * Turn BlinkM at address addr off.
   * @param addr the i2c address of blinkm
   * @throws IOException on transmit or receive error
   */
  public void off(int addr) 
    throws IOException { 
    stopScript(addr);
    setRGB(addr, 0,0,0 );
  }

  /**
   * Get the version of a BlinkM at a specific address
   * @param addr the i2c address
   * @returns 2 bytes of version info
   * @throws IOException on transmit or receive error
   */
  public byte[] getVersion(int addr)
    throws IOException { 
    byte[] cmdbuf = { (byte)addr, 'Z' };
    byte[] recvbuf = new byte[ 2 ]; 
    commandi2c( cmdbuf, recvbuf );
    return recvbuf;
  }
  
  /**
   * Sets the I2C address of a BlinkM
   * @param addr old address, can be 0 to change all connected BlinkMs
   * @param newaddr new address
   * @throws IOException on transmit or receive error
   */
  public void setAddress(int addr, int newaddr)
    throws IOException { 
    byte[] cmdbuf = { (byte)addr, (byte)'A', (byte)newaddr, 
                      (byte)0xD0, (byte)0x0D, (byte)newaddr };
    commandi2c( cmdbuf, null );
  }

  /**
   * Play a light script
   * @param addr the i2c address
   * @param script_id id of light script (#0 is reprogrammable one)
   * @param reps  number of repeats
   * @param pos   position in script to play
   * @throws IOException on transmit or receive error
   */
  public void playScript(int addr, int script_id, int reps, int pos) 
    throws IOException {
    byte[] cmdbuf = { (byte)addr, 'p', (byte)script_id, (byte)reps, (byte)pos};
    commandi2c( cmdbuf, null );
  }
  /**
   * Plays the eeprom script (script id 0) from start, forever
   * @param addr the i2c address of blinkm
   * @throws IOException on transmit or receive error
   */
  public void playScript(int addr) 
    throws IOException {
    playScript(addr, 0,0,0);
  }
  
  /**
   * Stop any playing script at address 'addr'
   * @param addr the i2c address of blinkm
   * @throws IOException on transmit or receive error
   */
  public void stopScript(int addr) 
    throws IOException {
    debug("stopScript");
    byte[] cmdbuf = { (byte)addr, (byte)'o' };
    commandi2c( cmdbuf, null );
  }
  
  /**
   * Set the blinkm at 'addr' to the specified RGB color 
   *
   * @param addr the i2c address of blinkm
   * @param r red component, 8-bit
   * @param g green component, 8-bit
   * @param b blue component, 8-bit
   * @throws IOException on transmit or receive error
   */
  public void setRGB(int addr, int r, int g, int b) 
    throws IOException { 
    byte[] cmdbuf = { (byte)addr, 'n', (byte)r, (byte)g, (byte)b };
    commandi2c( cmdbuf, null );
  }

  /**
   * Set the blinkm at 'addr' to the specified RGB color 
   *
   * @param addr the i2c address of blinkm
   * @param color the color to set
   * @throws IOException on transmit or receive error
   */
  public void setRGB(int addr, Color color) 
    throws IOException { 
    setRGB( addr, color.getRed(), color.getGreen(), color.getBlue());
  }

  /**
   * Fade the blinkm at 'addr' to the specified color
   * @param addr the i2c address of blinkm
   * @param r red component, 8-bit
   * @param g green component, 8-bit
   * @param b blue component, 8-bit
   * @throws IOException on transmit or receive error
   */
  public void fadeToRGB(int addr, int r, int g, int b) 
    throws IOException { 
    byte[] cmdbuf = { (byte)addr, 'c', (byte)r, (byte)g, (byte)b };
    commandi2c( cmdbuf, null );
  }

  /**
   * Fade the blinkm at 'addr' to the specified color
   *
   * @param addr the i2c address of blinkm
   * @param color the color to set
   * @throws IOException on transmit or receive error
   */
  public void fadeToRGB(int addr, Color color) 
    throws IOException { 
    fadeToRGB( addr, color.getRed(), color.getGreen(), color.getBlue());
  }

  /**
   * Fade a list of devices to a list of RGB colors
   * FIXME: this doesn't work
   * @param addrs list of i2c addresses
   * @param colors list of colors
   * @param count number of items in list
   * @throws IOException on transmit or receive error
   */
  public void fadeToRGB( int addrs[], Color colors[], int count ) 
    throws IOException { 
    int cmdlen = 5;  // {addr,'c',r,g,b}
    byte[] cmdbuf = new byte[ cmdlen * count ];
    for( int i=0; i< count; i++ ) {
      cmdbuf[ (i*cmdlen)+0 ] = (byte)addrs[i];
      cmdbuf[ (i*cmdlen)+1 ] = (byte)'c';
      cmdbuf[ (i*cmdlen)+2 ] = (byte)colors[i].getRed();
      cmdbuf[ (i*cmdlen)+3 ] = (byte)colors[i].getGreen();
      cmdbuf[ (i*cmdlen)+4 ] = (byte)colors[i].getBlue();
    }
    commandmany( LINKM_CMD_I2CTRANS, count, cmdlen, cmdbuf);
  }

  /**
   * Fade to a random color.  
   * Here the r,g,b components are the amount of random for each color channel
   * @param addr the i2c address of blinkm
   * @param r red component, 8-bit
   * @param g green component, 8-bit
   * @param b blue component, 8-bit
   * @throws IOException on transmit or receive error
   */
  public void fadeToRandomRGB(int addr, int r, int g, int b) 
    throws IOException { 
    byte[] cmdbuf = { (byte)addr, 'C', (byte)r, (byte)g, (byte)b };
    commandi2c( cmdbuf, null );
  }

  /**
   * Fade to a color by HSB.
   * @param addr the i2c address of blinkm
   * @param h hue component, 8-bit
   * @param s saturation component, 8-bit
   * @param b brightness component, 8-bit
   * @throws IOException on transmit or receive error
   */
  public void fadeToHSB(int addr, int h, int s, int b)
    throws IOException {
    byte[] cmdbuf = { (byte)addr, 'h', (byte)h, (byte)s, (byte)b };
    commandi2c( cmdbuf, null );
  }

  /**
   * Fade to a random HSB color.  
   * Here the r,g,b components are the amount of random for each color channel
   * @param addr the i2c address of blinkm
   * @param h hue component, 8-bit
   * @param s saturation component, 8-bit
   * @param b brightness component, 8-bit
   * @throws IOException on transmit or receive error
   */
  public void fadeToRandomHSB(int addr, int h, int s, int b)
    throws IOException {
    byte[] cmdbuf = { (byte)addr, 'H', (byte)h, (byte)s, (byte)b };
    commandi2c( cmdbuf, null );
  }

  /**
   * Return the RGB color the BlinkM is currently at.
   * @param addr the i2c address of blinkm
   * @throws IOException on transmit or receive error
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
   * Set fade speed of a BlinkM
   * @param addr the i2c address of blinkm
   * @param fadespeed fadespeed value (1 = very slow, 255 = instantaneous)
   * @throws IOException on transmit or receive error
   */
  public void setFadeSpeed(int addr, int fadespeed)
    throws IOException { 
    byte[] cmdbuf = { (byte)addr, 'f', (byte)fadespeed };
    commandi2c( cmdbuf, null );
  }

  /**
   * Set time adjust of a BlinkM light script playing
   * @param addr the i2c address of blinkm
   * @param timeadj time adjust amount (0 = no adjust, negative = faster, positve = slower)
   * @throws IOException on transmit or receive error
   */
  public void setTimeAdj(int addr, int timeadj)
    throws IOException { 
    byte[] cmdbuf = { (byte)addr, 't', (byte)timeadj };
    commandi2c( cmdbuf, null );
  }

  /**
   * Set boot params   cmd,mode,id,reps,fadespeed,timeadj
   * @param addr the i2c address of blinkm
   * @throws IOException on transmit or receive error
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
   * @param addr the i2c address of blinkm
   * @throws IOException on transmit or receive error
   */
  public void setStartupParamsDefault(int addr) throws IOException {
    setStartupParams( addr, 1, 0, 0, 8, 0 );
  }

  /**
   * Set light script default length and repeats.
   * reps == 0 means infinite repeats
   * @param addr the i2c address of blinkm
   * @throws IOException on transmit or receive error
   */
  public void setScriptLengthRepeats( int addr, int len, int reps)
    throws IOException {
    byte[] cmdbuf = { (byte)addr, 'L', 0, (byte)len, (byte)reps };
    commandi2c( cmdbuf, null );
    pause(10);  // enforce wait for EEPROM write
  }

  /**
   * Read inputs on BlinkMs that have inputs
   * @note only works on MaxM or MinM
   * @param addr the i2c address of blinkm
   * @throws IOException on transmit or receive error
   */
  public byte[] readInputs( int addr ) throws IOException { 
    debug("BlinkMComm.readInputs");
    byte[] cmdbuf = { (byte)addr, 'i'};
    byte[] respbuf = new byte[4]; // 4 bytes of response
    commandi2c( cmdbuf, respbuf);
    return respbuf;
  }

  /**
   * Write an entire light script contained in a string
   * @param addr the i2c address of blinkm
   * @throws IOException on transmit or receive error
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
   * @param addr the i2c address of blinkm
   * @param script BlinkMScript object of script lines
   * @throws IOException on transmit or receive error
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
   * @param addr the i2c address of blinkm
   * @throws IOException on transmit or receive error
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
    pause( writePauseMillis ); // enforce at >4.5msec delay between EEPROM writes
  }

  /**
   * Read a BlinkMScriptLine from 'script_id' and pos 'pos', 
   * from BlinkM at 'addr'.
   * @param addr the i2c address of blinkm
   * @throws IOException on transmit or receive error
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
   * @param addr the i2c address of blinkm
   * @param script_id id of script to read from (usually 0)
   * @param readAll read all script lines, or just the good ones
   * @throws IOException on transmit or receive error
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
   * @param addr the i2c address of blinkm
   * @throws IOException on transmit or receive error
   */
  public String readScriptToString( int addr, int script_id, boolean readAll )
    throws IOException {
    BlinkMScript script = readScript( addr, script_id, readAll );
    String str = script.toString();
    return str;
  }

  /**
   * Set a BlinkM back to factory settings
   * Sets the i2c address to 0x09
   * Writes a new light script and sets the startup paramters
   * @param addr the i2c address of blinkm
   * @throws IOException on transmit or receive error
   */
  public void doFactoryReset( int addr ) throws IOException {
    setAddress( addr, 0x09 );
    addr = 0x09;
    setStartupParamsDefault(addr);

    BlinkMScript script = new BlinkMScript();
    script.add( new BlinkMScriptLine(  1, 'f',   10,   0,   0) );
    script.add( new BlinkMScriptLine(100, 'c', 0xff,0xff,0xff) );
    script.add( new BlinkMScriptLine( 50, 'c', 0xff,0x00,0x00) );
    script.add( new BlinkMScriptLine( 50, 'c', 0x00,0xff,0x00) );
    script.add( new BlinkMScriptLine( 50, 'c', 0x00,0x00,0xff) );
    for( int i=0; i< 48-4; i++ ) {  // FIXME:  make this length correct
      script.add( new BlinkMScriptLine( 0, 'c', 0,0,0 ) );
    }

    writeScript( addr, script);
  }

  /**
   * simple debug facilty
   * @param s string to print out for debug purposes
   */
  static public void debug( String s ) {
    if(debug>0) println(s);
  }


  //---------------------------------------------------------------------------
  // Class methods
  //---------------------------------------------------------------------------

  /**
   * Essentially a sparse-array lookup-table for those commands that may 
   * return a value.
   * @param c command code character
   * @returns num of args for given command
   */
  static final public int respSizeForCommand( int c ) {
    int s = 0;
    switch( c ) {
    case 'a': s = 1; break;
    case 'g': s = 3; break;
    case 'i': s = 1; break;
    case 'R': s = 5; break;
    case 'Z': s = 2; break;
    }
    return s;
  }

  /**
   * Load a text file and turn it into an array of Strings.
   * @param filename name of file to load
   * @returns array of Strings, one per line, of file
   */
  static final public String[] loadFile( String filename ) {
    return loadFile( new File(filename) );
  }

  /**
   * Load a text file and turn it into an array of Strings.
   * @param filename name of file to load
   * @returns array of Strings, one per line, of file
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
   * Save a script in string format to a file
   * @param filename name of file to write
   * @param scripstr script in String format
   */
  static final public boolean saveFile( String filename, String scriptstr ) { 
    return saveFile( new File(filename), scriptstr );
  }

  /**
   * Take a script in String format and save it to as a text file.
   * @param file file to write
   * @param scripstr script in String format
   * @returns true on success, false on failure
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
   * @param scripstr script in String format
   * @returns a BlinkMScript or null
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
        debug("parseScripts: open paren at line "+i);
        i++;  // skip to next line
        ib = i;  // save begining pos of script
        while( i < lines.length ) {
          l = lines[i];
          debug("parseScripts: line "+i+":'"+l+"'");
          Matcher me = pe.matcher( l ); // look for close paren
          if( me.find() ) { 
            debug("parseScripts: close paren at line "+i);
            ie = i;  // save end
            String[] scriptlines = new String[ie-ib];
            System.arraycopy( lines, ib, scriptlines, 0, (ie-ib) );
            //for( int k=0; k<scriptlines.length; k++)
            //  debug("scriptlines["+k+"]: "+scriptlines[k]);
            BlinkMScript script = parseScript( scriptlines );
            scriptlist.add( script );
            debug("parseScripts: script added.");
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

