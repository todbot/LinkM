/*
 * BlinkMComm2.pde -- Talk to BlinkMs via Arduino+BlinkMCommunicator sketch
 *                    Very similar api to LinkM.java
 *
 * Note: uses global 'linkm' object for script parsing (bad tod)
 *
 * 2010 Tod E. Kurt, ThingM, http://thingm.com/
 *
 */

import processing.serial.*;


public class BlinkMComm2 {
  //public final boolean fakeIt = false;

  public String portName = null;
  public final int portSpeed = 19200;

  Serial port;

  //static public final int writePauseMillis = 15;
  static public final int writePauseMillis = 30;

  // Return a list of potential ports
  // they should be ordered by best to worst (but are not right now)
  // this can't be static as a .pde, sigh.
  public String[] listPorts() {
    String[] a = Serial.list();
    String osname = System.getProperty("os.name");
    if( osname.toLowerCase().startsWith("windows") ) {
      // reverse list because Arduino is almost always highest COM port
      for(int i=0;i<a.length/2;i++){
        String t = a[i]; a[i] = a[a.length-(1+i)]; a[a.length-(1+i)] = t;
      }
      //for(int left=0, int right=list.length-1; left<right; left++, right--) {
      //  // exchange the first and last
      //  String tmp = list[left]; list[left] = list[right]; list[right] = tmp;
      //}
    }
    if( debugLevel>0 ) { 
      for( int i=0;i<a.length;i++){
        println(i+":"+a[i]);
      }
    }
    return a;
  }

  public BlinkMComm2() {

  }

  
  /**
   * Connect to the given port
   * Can optionally take a PApplet (the sketch) to get serialEvents()
   * but this is not recommended
   *
   */
  public void connect( PApplet p, String portname ) throws Exception {
    l.debug("BlinkMComm.connect: portname:"+portname);
    try {
      if(port != null)
        port.stop(); 
      port = new Serial(p, portname, portSpeed);
      delay(100);
      
      // FIXME: check address, set it if needed

      arduinoMode = true;
      connected = true;
      //isConnected = true;
      portName = portname;
    }
    catch (Exception e) {
      arduinoMode = false;
      connected = false;
      //isConnected = false;
      portName = null;
      port = null;
      throw e;
    }
  }

  // disconnect but remember the name
  public void disconnect() {
    if( port!=null )
      port.stop();
    arduinoMode = false;
    connected = false;
  }

  /**
   * Send an I2C command to addr, via the BlinkMCommander Arduino sketch
   * Byte array must be correct length
   */
  public synchronized void sendCommand( byte addr, byte[] cmd ) {
    sendCommand( addr, cmd, 0 );
  }

  /**
   * Send a command and expect a response
   */
  public synchronized byte[] sendCommand( byte addr, byte[] cmd, int resplen ) {
    l.debug("BlinkMComm.sendCommand("+resplen+"):"+ (char)cmd[0]+ 
            ((cmd.length>1)?(","+(int)cmd[1]):"") + 
            ((cmd.length>3)?(","+(int)cmd[2]+","+(int)cmd[3]):""));

    port.clear();

    byte cmdfull[] = new byte[4+cmd.length];
    cmdfull[0] = 0x01;
    cmdfull[1] = addr;
    cmdfull[2] = (byte)cmd.length;
    cmdfull[3] = (byte)resplen;
    for( int i=0; i<cmd.length; i++) {
      cmdfull[4+i] = cmd[i];
    }
    port.write(cmdfull);

    if( resplen == 0 ) return null;  // no response so get out

    long start_time = millis();
    while( port.available() < resplen ) { // wait
      if( (millis() - start_time) > 1000 ) { 
        return null; // FIXME: better error handling
      }
    }
    
    byte[] respbuf = new byte[resplen];
    port.readBytes(respbuf);
    
    return respbuf;
  }

  /**
   *
   */
  public byte[] i2cScan( int startAddr, int endAddr ) {
    byte[] cmd = {(byte)startAddr, (byte)endAddr}; 

    sendCommand( (byte)128, cmd); // 128 == i2cscan cmd
    delay(100);

    byte[] buh = new byte[endAddr-startAddr];
    int i=0;

    long start_time = millis();
    while( port.available() > 0 ) { // wait
      if( (millis() - start_time) > 1000 ) { 
        return buh; // FIXME: better error handling
      }
      byte addr   = (byte)port.read();
      byte result = (byte)port.read();
      if( result==0 ) {
        buh[i++] = addr;
      }
    }
    byte[] duh = new byte[i];
    System.arraycopy( buh, 0, duh, 0, i);
     
    return duh;
  }

  /**
   *
   */
  public void stopScript( int addr ) {
    byte[] cmd = {'o'};
    sendCommand( (byte)addr, cmd );
  }

  public void setFadeSpeed( int addr, int fadespeed ) {
    byte[] cmd = {'f', (byte)fadespeed};
    sendCommand( (byte)addr, cmd );
  }

  /**
   * Set the blinkm at 'addr' to the specified RGB color 
   *
   * @param addr the i2c address of blinkm
   * @param r red component, 8-bit
   * @param g green component, 8-bit
   * @param b blue component, 8-bit
   */
  public void setRGB(int addr, int r, int g, int b) {
    byte[] cmd = { 'n', (byte)r, (byte)g, (byte)b };
    sendCommand( (byte)addr, cmd );
  }

  public void setRGB( int addr, Color c ) {
    byte[] cmd = {'n', (byte)c.getRed(),(byte)c.getGreen(),(byte)c.getBlue() };
    sendCommand( (byte)addr, cmd );
  }

  public void fadeToRGB( int addr, Color c ) {
    byte[] cmd = {'c', (byte)c.getRed(),(byte)c.getGreen(),(byte)c.getBlue() };
    sendCommand( (byte)addr, cmd );
  }

  /**
   * Turn BlinkM at address addr off.
   * @param addr the i2c address of blinkm
   */
  public void off(int addr) {
    stopScript(addr);
    setRGB(addr, 0,0,0 );
  }

  /**
   * Get the version of a BlinkM at a specific address
   * @param addr the i2c address
   * @returns 2 bytes of version info
   */
  public byte[] getVersion(int addr) {
    byte[] cmd = { 'Z' };
    byte[] respbuf = sendCommand( (byte)addr, cmd, 2);
    return respbuf;
  }

  /**
   * Sets the I2C address of a BlinkM
   * @param addr old address, can be 0 to change all connected BlinkMs
   * @param newaddr new address
   //* @throws IOException on transmit or receive error
   */
  public void setAddress(int addr, int newaddr) {
    byte[] cmd = { (byte)'A', (byte)newaddr, 
                   (byte)0xD0, (byte)0x0D, (byte)newaddr };
    sendCommand( (byte)addr, cmd );
  }

  /**
   * Play a light script
   * @param addr the i2c address
   * @param script_id id of light script (#0 is reprogrammable one)
   * @param reps  number of repeats
   * @param pos   position in script to play
   //* @throws IOException on transmit or receive error
   */
  public void playScript(int addr, int script_id, int reps, int pos) {
    byte[] cmd = { 'p', (byte)script_id, (byte)reps, (byte)pos};
    sendCommand( (byte)addr, cmd );
  }
  /**
   * Plays the eeprom script (script id 0) from start, forever
   * @param addr the i2c address of blinkm
   //* @throws IOException on transmit or receive error
   */
  public void playScript(int addr) {
    playScript(addr, 0,0,0);
  }

  /**
   *
   */
  public void writeScriptLine( int addr, int pos, BlinkMScriptLine line ) {
    l.debug("writeScriptLine: addr:"+addr+" pos:"+pos+" scriptline: "+line);
    // build up the byte array to send
    byte[] cmd = new byte[8];    // 
    cmd[0] = (byte)'W';          // "Write Script Line" command
    cmd[1] = (byte) 0;           // script id (0==eeprom)
    cmd[2] = (byte)pos;          // script line number
    cmd[3] = (byte)line.dur;     // duration in ticks
    cmd[4] = (byte)line.cmd;     // command
    cmd[5] = (byte)line.arg1;    // cmd arg1
    cmd[6] = (byte)line.arg2;    // cmd arg2
    cmd[7] = (byte)line.arg3;    // cmd arg3
    
    sendCommand( (byte)addr, cmd );
    delay( writePauseMillis );// enforce at >4.5msec delay between EEPROM writes
  }

  /**
   * Write an entire light script contained in a string
   * @param addr the i2c address of blinkm
   */
  public void writeScript( int addr, String scriptstr ) {
    BlinkMScript script = linkm.parseScript( scriptstr );
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
   */
  public void writeScript( int addr,  BlinkMScript script) {
    int len = script.length();
    
    for( int i=0; i< len; i++ ) {
      writeScriptLine( addr, i, script.get(i) );
    }
    
    setScriptLengthRepeats( addr, len, 0);    
  }


  /**
   * Set boot params   cmd,mode,id,reps,fadespeed,timeadj
   * @param addr the i2c address of blinkm
   //* @throws IOException on transmit or receive error
   */
  public void setStartupParams( int addr, int mode, int script_id, int reps, 
                                int fadespeed, int timeadj ) {
    byte[] cmd = { 'B', (byte)mode, (byte)script_id, 
                   (byte)reps, (byte)fadespeed, (byte)timeadj };
    sendCommand( (byte)addr, cmd );
    delay( writePauseMillis );  // enforce wait for EEPROM write
  }

  /**
   * Default values for startup params
   * @param addr the i2c address of blinkm
   //* @throws IOException on transmit or receive error
   */
  public void setStartupParamsDefault(int addr) {
    setStartupParams( addr, 1, 0, 0, 8, 0 );
  }

  /**
   * Set light script default length and repeats.
   * reps == 0 means infinite repeats
   * @param addr the i2c address of blinkm
   */
  public void setScriptLengthRepeats( int addr, int len, int reps) {
    byte[] cmd = { 'L', 0, (byte)len, (byte)reps };
    sendCommand( (byte)addr, cmd );
    delay( writePauseMillis );  // enforce wait for EEPROM write
  }


  /**
   * Read a BlinkMScriptLine from 'script_id' and pos 'pos', 
   * from BlinkM at 'addr'.
   * @param addr the i2c address of blinkm
   */
  public BlinkMScriptLine readScriptLine( int addr, int script_id, int pos ) {
    l.debug("readScriptLine: addr: "+addr+" pos:"+pos);
    byte[] cmd = new byte[3];     // 
    cmd[0] = (byte)'R';           // "Write Script Line" command
    cmd[1] = (byte)script_id;     // script id (0==eeprom)
    cmd[2] = (byte)pos;           // script line number

    byte[] respbuf = sendCommand( (byte)addr, cmd, 5);
    
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
    script.add( new BlinkMScriptLine( 50, 'c', 0x00,0x00,0x00) );
    for( int i=0; i< 49-6; i++ ) {  // FIXME:  make this length correct
      script.add( new BlinkMScriptLine( 0, 'c', 0,0,0 ) );
    }

    writeScript( addr, script);

  }

  // ------------------------------------------------------------------------

  /**
   * What happens when "upload" button is pressed
   */
  public boolean doUpload(JProgressBar progressbar) {
    return false;
  }



  JDialog connectDialog;
  JComboBox portChoices;

  public void connectDialog() {

    String[] portNames = listPorts();
    String lastPortName = portName;
    
    if( lastPortName == null ) 
      lastPortName = (portNames.length!=0) ? portNames[0] : null;

    // FIXME: need to catch case of *no* serial ports (setSelectedIndex fails)
    int idx = 0;
    for( int i=0; i<portNames.length; i++) 
      if( portNames[i].equals(lastPortName) ) idx = i;

    portChoices = new JComboBox(portNames);
    portChoices.setSelectedIndex( idx );

    connectDialog = new JDialog();
    connectDialog.setTitle("Connect to Arduino");
    JPanel panel = new JPanel(new BorderLayout());
    panel.setBorder( BorderFactory.createEmptyBorder(20,20,20,20) );

    JButton connectButton = new JButton("Connect");
    connectButton.addActionListener( new ActionListener() { 
        public void actionPerformed(ActionEvent e) {
          String portname = (String) portChoices.getSelectedItem();
          try { 
            connect(p, portname );

            delay(1500); // FIXME: wait for diecimila

            stopScript( 0 );
            setRGB( 0, Color.BLACK );

          } 
          catch( Exception ex ) {
            ex.printStackTrace(); //l.debug(ex);
            JOptionPane.showMessageDialog(mf, 
                                          "Couldn't open port "+portname+".",
                                          "Connect to Arduino Failed",
                                          JOptionPane.INFORMATION_MESSAGE);
          }
          connectDialog.setVisible(false);
        }
      });

    JPanel chooserPanel = new JPanel();
    chooserPanel.add(portChoices);
    chooserPanel.add(connectButton);

    JLabel msgtop = new JLabel("Please select serial port of Arduino with BlinkMCommunicator");
    panel.add( msgtop, BorderLayout.NORTH );
    panel.add( chooserPanel, BorderLayout.CENTER );

    connectDialog.getContentPane().add(panel); // jdialog has limited container 
    connectDialog.pack();
    connectDialog.setResizable(false);
    connectDialog.setLocationRelativeTo(null); // center it on BlinkMSequencer
    connectDialog.setVisible(true);

    connectDialog.addWindowListener( new WindowAdapter() {
        public void windowDeactivated(WindowEvent event) {
            // need to do anything here?
        }
      });
  }

  public void disconnectDialog() { 
    disconnect();
    JOptionPane.showMessageDialog(mf, 
                                  "Disconnected from "+portName+".",
                                  "Disconnect from Arduino",
                                  JOptionPane.INFORMATION_MESSAGE);
  }

}
