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
      else if( a.equals("--debug") || a.equals("-d") ) { 
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
        //file = args[++j];
        cmd = "download";
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
        ArrayList lines = linkm.loadFile( file );
        ArrayList scriptLines  = linkm.parseScript( lines );
        if( scriptLines == null ) {
          System.err.println("bad format in file");
          return;
        }

        if( debug>0 ) {
          for( int i=0; i < scriptLines.size(); i++ ) 
            println(i+":"+scriptLines.get(i) );
        }

        println("Uploading "+scriptLines.size()+
                           " line script to BlinkM address "+addr);
        linkm.writeScript( addr, scriptLines );
      }
      else if( cmd.equals("download") ) {
        if( addr == 0 ) { 
          println("Address 0 is not allowed. Set address with --addr=<addr>");
          return;
        }
        println("Downloading script from ...");
        BlinkMScriptLine line = null;
        ArrayList scriptLines = linkm.readScript( addr, 0 );
        for(int i=0; i< scriptLines.size(); i++ ) {
          line = (BlinkMScriptLine) scriptLines.get(i);
          println(line.toString());  
        }
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
      System.err.println("error: "+e);
    }
    
    linkm.close();
    
  }
  
  
  // --------------------------------------------------------------------------
  // Native method declarations
  //

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


  // --------------------------------------------------------------------------
  // Instance methods
  //

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
    /*
    byte[] cmdbuf1 = { (byte)addr, 'o' };          // stop script playing
    byte[] cmdbuf2 = { (byte)addr, 'n', 0,0,0};    // go to black now
    commandi2c( cmdbuf1, null );
    commandi2c( cmdbuf2, null );
    */
  }

  /**
   *
   */
  public byte[] getVersion(int addr)
    throws IOException { 
    byte[] cmdbuf = { (byte)addr, 'z' };
    byte[] recvbuf = new byte[ 2 ]; 
    command( LINKM_CMD_I2CSCAN, cmdbuf, recvbuf);
    return recvbuf;
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
  
  public void setRGB(int addr, int r, int g, int b) 
    throws IOException { 
    byte[] cmdbuf = { (byte)addr, 'n', (byte)r, (byte)g, (byte)b };
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
    pause(20);  // enforce wait for EEPROM write
  }

  /**
   * Write an entire BlinkM light script as an ArrayList of BlinkMScriptLines
   * to blinkm at address 'addr'.
   */
  public void writeScript( int addr,  ArrayList scriptLines ) 
    throws IOException {
    int olen = scriptLines.size();
    // copy only the good ones  FIXME: this is kind of a hack
    ArrayList<BlinkMScriptLine> sl = new ArrayList<BlinkMScriptLine>();
    BlinkMScriptLine line;
    for( int i=0; i< olen; i++ ) {
      line = (BlinkMScriptLine)scriptLines.get(i);
      if( (line.dur == 0xff && line.cmd == 0xff ) || 
          (line.dur == 0 && line.cmd == 0) ) {
        // then, bad line
      } 
      else { 
        sl.add( line );  // copy only the good ones, not the comment-only ones
      }
    }
    int len = sl.size();
    
    for( int i=0; i< len; i++ ) {
      writeScriptLine( addr, i, sl.get(i) );
    }

    setScriptLengthRepeats( addr, len, 0);
    
  }

  /**
   * Write a single BlinkM light script line at position 'pos'.
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
   */
  public ArrayList readScript( int addr, int script_id ) 
    throws IOException { 
    ArrayList<BlinkMScriptLine> lines = new ArrayList<BlinkMScriptLine>();
    BlinkMScriptLine line;
    for( int i = 0; i< maxScriptLength; i++ ) {
      line = readScriptLine( addr, script_id, i );
      if( line==null || (line.dur == 0xff && line.cmd == 0xff ) || 
          (line.dur == 0 && line.cmd == 0) ) {
        // ooo bad bad scriptline, naughty thing
      } else { 
        lines.add(line);
      }
    }
    return lines;
  }

  /**
   * Set a BlinkM back to factory settings
   * Writes a new light script and sets the startup paramters
   */
  public void setFactorySettings( int addr ) throws IOException {
    ArrayList<BlinkMScriptLine> scriptLines = new ArrayList<BlinkMScriptLine>();
    scriptLines.add( new BlinkMScriptLine(  1, 'f', 10,0,0 ) );
    scriptLines.add( new BlinkMScriptLine(100, 'c', 0xff,0xff,0xff) );
    scriptLines.add( new BlinkMScriptLine( 50, 'c', 0xff,0x00,0x00) );
    scriptLines.add( new BlinkMScriptLine( 50, 'c', 0x00,0xff,0x00) );
    scriptLines.add( new BlinkMScriptLine( 50, 'c', 0x00,0x00,0xff) );

    writeScript( addr, scriptLines);
    setStartupParamsDefault(addr);
  }

  public void debug( String s ) {
    if(debug>0) println(s);
  }

  // --------------------------------------------------------------------------
  // Class methods
  //

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
   * Load a text file and turn it into an ArrayList of Strings.
   */
  static final public ArrayList loadFile( String filename ) {
    ArrayList<String> lines = new ArrayList<String>();
    String line;
    BufferedReader in = null;
    try { 
      in = new BufferedReader(new FileReader(filename));
      while( (line = in.readLine()) != null ) {
        lines.add( line );
      }
    }
    catch( Exception ex ) { 
      System.err.println("error: "+ex);
      lines = null;
    }
    finally { 
      try { if( in!=null) in.close(); } catch(Exception ex) {}
    }
    return lines;
  }

  /**
   * Take an ArrayList of Strings and save it to as a text file.
   */
  static final public boolean saveFile( String filename, ArrayList lines ) {
    //File f = new File( filename );
    BufferedWriter out = null;
    try { 
      out = new BufferedWriter(new FileWriter( filename ));
      for( int i=0; i<lines.size(); i++ ) { 
        out.write( (String)lines.get(i) );
      }
    } catch( Exception ex ) { 
      System.err.println("error: "+ex);
      return false;
    } finally { 
      try { out.close(); } catch(Exception ex) {}
    }
    return true;
  }

  /**
   * Take a String and turn it into an ArrayList of BlinkMScriptLine objects
   */
  //@SuppressWarnings("unchecked")
  static final public ArrayList parseScript( ArrayList lines ) {
    BlinkMScriptLine bsl; 
    ArrayList<BlinkMScriptLine> sl = new ArrayList<BlinkMScriptLine>();  
    //ArrayList sl = new ArrayList();  
    String linepat = "\\{(.+?),\\{'(.+?)',(.+?),(.+?),(.+?)\\}\\}";
    Pattern p = Pattern.compile(linepat);
    if( lines==null ) return null;
    for (int i = 0; i < lines.size(); i++) {
      String l = (String) lines.get(i);

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
        bsl = new BlinkMScriptLine();
        bsl.addComment( l );  // so add the bad line as a comment
      }
      sl.add( bsl );
    }
    return sl;
  }

  /**
   * Utility: 'serialize' to String
   * not strictly needed since we can just read/write the editArea
   */
  static final public String scriptLinesToString(ArrayList scriptlines) {
    String str = "{\n";
    BlinkMScriptLine line;
    for( int i=0; i< scriptlines.size(); i++ ) {
      line = (BlinkMScriptLine)scriptlines.get(i);
      str += "\t"+ line.toFormattedString() +"\n";
    }
    str += "}\n";
    return str;
  }

  // -----------------------------------------------------------------------

  /**
   * Utility:
   */

  /**
   * A simple delay
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

