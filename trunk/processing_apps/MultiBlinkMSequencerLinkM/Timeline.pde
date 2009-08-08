// Copyright (c) 2007-2008, ThingM Corporation

/**
 *
 */
public class Timeline extends JPanel implements MouseListener, MouseMotionListener {
  
  private int scrubHeight = 10;
  public int secSpacerWidth = 2;
  private int w;  
  private int h;               // = 170;    // height of timeline, was 90
  private int sx = 18;                 // offset from left edge of screen
  private int trackHeight; // = 20;  //FIXME: derive   // height of track in pixels
  private boolean isMousePressed;
  private Point mouseClickedPt;
  private Point mouseReleasedPt;
  
  private Color playHeadC = new Color(255, 0, 0);
  private float playHeadCurr = sx;
  private int loopEnd;

  private javax.swing.Timer timer;
  private int timerMillis = 25;        // time between timer firings
  
  private boolean isPlayHeadClicked = false;
  private boolean isLoop = true;           // timer, loop or no loop
  private long startTime = 0;             // start time 
  
  private Font font;

  private int numSlices;
  private int numTracks;
  public TimeTrack[] timeTracks;
  
  /**
   * @param numTracks number of tracks this timeline represents
   * @param numSlices number of slices in a track
   * @param aHeight height of timeline in pixels
   * @param aWidth width of timeline in pixels
   */
  public Timeline(int numSlices, int numTracks, int aWidth, int aHeight ) {
    this.numSlices = numSlices;
    this.numTracks = numTracks;
    this.w = aWidth;           // overall width of timeline object
    this.h = aHeight;
    this.timeTracks = new TimeTrack[numTracks];
    this.trackHeight = (h - scrubHeight) / numTracks;
    this.loopEnd = w-20;
    this.setPreferredSize(new Dimension(this.w, this.h));
    this.setBackground(bgDarkGray);
    addMouseListener(this);
    addMouseMotionListener(this);
    //mf.addKeyListener(this);

    this.font = new Font("Monospaced", Font.PLAIN, 9);
    for( int j=0; j<numTracks; j++ ) {
      int sy = 10 + j*trackHeight;
      TimeTrack tc = new TimeTrack(sx,sy, w,trackHeight-2, secSpacerWidth);
      timeTracks[j] = tc;
    }

    // give people a nudge on what to do
    timeTracks[0].timeSlices[0].isActive = true;
  }

  /**
   * @Override
   */
  public void paintComponent(Graphics gOG) {
    Graphics2D g = (Graphics2D) gOG;
    super.paintComponent(g); 

    // draw light gray background for playhead area
    g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, 
                       RenderingHints.VALUE_ANTIALIAS_ON);
    g.setColor(fgLightGray);
    g.fillRect(0, 0, getWidth(), scrubHeight);

    // draw "addr" above each adr column
    g.setFont(font);
    g.setColor(Color.black);
    g.drawString( "solo", 2,    8); // left hand side
    g.drawString( "addr", w-16, 8); // right hand  
    // draw each time track
    for( int j=0; j<numTracks; j++ ) {
      TimeSlice[] timeSlices = timeTracks[j].timeSlices;      
      // draw track
      for( int i=0; i<numSlices; i++) {
        timeSlices[i].draw(g);
      }
      // draw solo & addr on left & right sides of timeline
      int blinkmAddr = blinkmAddrs[j];  // get this track i2c address
      //g.setFont(font);
      BasicStroke stroke = new BasicStroke(1.5f);
      g.setStroke(stroke);
      g.setColor( new Color(0,0,0x80) );
      g.drawArc( 3, 15+j*trackHeight, 10,10, 0,360);
      if( timeTracks[j].active == true )  // solo button
        g.fillOval( 5,17+j*trackHeight, 6,6 );
      g.drawString( nf(blinkmAddr,2), w-15, 23+j*trackHeight); // right hand  
    }

    paintPlayHead(g);
    //paintLoopEnd(g);

    // set the preview stack, can use any timetrack for the collision test
    for( int i=0; i<numSlices; i++ ) {
      if( timeTracks[0].timeSlices[i].isCollision( (int)playHeadCurr)) {
        // update ColorPreview panel based on current pos of slider
        //colorPreview.setColors( getColorsAtColumn(i) );
      }
    }
  }

  /**
   *
   */
  void paintPlayHead(Graphics2D g) {
    g.setColor(playHeadC);
    g.fillRect((int)playHeadCurr, 0, secSpacerWidth, getHeight());
    Polygon p = new Polygon();
    p.addPoint((int)playHeadCurr - 5, 0);
    p.addPoint((int)playHeadCurr + 5, 0);
    p.addPoint((int)playHeadCurr + 5, 5);
    p.addPoint((int)playHeadCurr + 1, 10);
    p.addPoint((int)playHeadCurr - 1, 10);
    p.addPoint((int)playHeadCurr - 5, 5);
    p.addPoint((int)playHeadCurr - 5, 0);    
    g.fillPolygon(p);
  }
  
  void paintLoopEnd(Graphics2D g) {
    g.setColor(playHeadC);
    g.fillRect( loopEnd,0, secSpacerWidth, h );
  }

  /**
   *
   */
  public void setLoop(boolean b) {
    isLoop = b; 
  }
  public boolean getLoop() {
    return isLoop;
  }

  /**
   *
   */
  public void play() {
    l.debug("starting to play for dur: " + durationCurrent);

    timer = new javax.swing.Timer( timerMillis, new TimerListener());
    //timer.setInitialDelay(0);
    //timer.setCoalesce(true);
    timer.start();
    startTime = System.currentTimeMillis();
  }

  /**
   *
   */
  public void setActiveColor(Color c) { 
    // update selected TimeSlice in TimeLine
    for( int j=0; j<numTracks; j++) { 
      TimeSlice[] timeSlices = timeTracks[j].timeSlices;
      for( int i=0; i<numSlices; i++) {
        TimeSlice ts = timeSlices[i];
        if (ts.isActive)
          ts.setColor(c);
        //ts.isActive = false;
      }
    }
    repaint();
  }

  /**
   * Set all timeslices to be inactive
   */
  public void allOff() {
    // reset timeslice selections
    for( int j=0; j<numTracks; j++) { 
      TimeSlice[] timeSlices = timeTracks[j].timeSlices;
      for( int i=0; i<numSlices; i++) 
        timeSlices[i].isActive = false;
    }
    repaint(); 
  }
  
  /**
   * For a given column in the TimeLine, return an array of all the colors
   */
  public Color[] getColorsAtColumn(int col) {
    Color[] colors = new Color[numTracks];
    for( int j=0; j<numTracks; j++)  // gather up all the colors for this col
      colors[j] = timeTracks[j].timeSlices[col].getColor();
    return colors;
  }

  /** 
   * return num from 0 to numTracks on an active or playhead column
   */
  public int getPreviewColumn() {
    int col = -1;
    for( int j=0; j<numTracks; j++) {
      for( int i=0; i<numSlices; i++) {
        if( timeTracks[j].timeSlices[i].isActive )
          col = i;
      }
    }
    if( col == -1 ) { // no active col, so use playhead
      for( int i=0; i<numSlices; i++) {
        if( timeTracks[0].timeSlices[i].isCollision( (int)playHeadCurr ) ) 
          col = i;
      }
    }
    l.debug("previewCol: "+col+", playHeadCurr:"+playHeadCurr);
    return col;
  }

  /**
   *
   */
  class TimerListener implements ActionListener {
    /** Handle ActionEvent */
    public void actionPerformed(ActionEvent e) {
      int width = getWidth() - sx;
      // not quite sure why need to add one to durationCurrent here
      int durtmp = (durationCurrent>5) ?durationCurrent+1 : durationCurrent;
      float step = width / (durtmp*1000.0/timerMillis);
      playHeadCurr += step;
      repaint();

      if (playHeadCurr > loopEnd) {        // check for end of timeline
        if (isLoop) {
          reset();
          play(); 
        } 
        else {
          reset();
          pb.setToPlay();
        }
      } //if
    } 
  }

  /**
   *
   */
  public void stop() {
    l.debug("stop"); 
    if (timer != null) 
      timer.stop();
    l.debug("elapsedTime:"+(System.currentTimeMillis() - startTime));
  }

  /**
   *
   */
  public void reset() {
    stop();
    playHeadCurr = sx;
    repaint();
  }

  public void mouseClicked(MouseEvent e) {
    //l.debug("clicked");
  }

  public void mouseEntered(MouseEvent e) {
    //l.debug("entered");
  }

  public void mouseExited(MouseEvent e) {
    //l.debug("exited");
  }

  public void mousePressed(MouseEvent e) {
    l.debug("pressed: "+e);
    Point mp = e.getPoint();

    Polygon p = new Polygon();  // creating bounding box for playhead
    p.addPoint((int)playHeadCurr - 3, 0);
    p.addPoint((int)playHeadCurr + 3, 0);
    p.addPoint((int)playHeadCurr + 3, getHeight());
    p.addPoint((int)playHeadCurr - 3, getHeight());

    isPlayHeadClicked = p.contains(mp);  // check if mouseclick on playhead

    if (!isPlayHeadClicked) {         // test for collision w/timeslice or track
      for( int j=0; j<numTracks; j++) {
        // check for solo/address number hits
        if( (mp.x > 0 && mp.x < 20) ) {         // solo strip, left hand side
          if( (mp.y > j*trackHeight + scrubHeight) && 
              (mp.y < (j+1)*trackHeight + scrubHeight) )      // lame
            toggleSolo(j);
        } 
        else if( (mp.x > w-15 && mp.x < w) ) { // i2caddr strip, right hand side
          if( (mp.y > j*trackHeight + scrubHeight) &&       // lame
              (mp.y < (j+1)*trackHeight + scrubHeight) )
            doTrackDialog(j);
        }
        else {                                 // check for timeslice hit
          TimeSlice[] timeSlices = timeTracks[j].timeSlices;
          for( int i=0; i<numSlices; i++) {
            TimeSlice ts = timeSlices[i];
            if (ts.isCollision(mp.x,mp.y)) 
              ts.isActive = true;
            else if ((e.getModifiers() & InputEvent.META_MASK) == 0) 
              ts.isActive = false; 
          }
        }
      } // for
    } // !playheadclicked

    isMousePressed = true;
    mouseClickedPt = mp;

    repaint();
  }

  public void mouseReleased(MouseEvent e) {
    mouseReleasedPt = e.getPoint();
    int clickCnt = e.getClickCount();

    isPlayHeadClicked = false;
    // snap playhead to closest time slice
    for( int j=0; j<numTracks; j++ ) {
      TimeSlice[] timeSlices = timeTracks[j].timeSlices;
      for( int i=0; i<numSlices; i++) {
        TimeSlice ts = timeSlices[i];
        if( ts.isActive && clickCnt >= 2 )   // double-click to set color
          //colorPreview.setColors(  getColorsAtColumn(i) );
          //colorChooser.setColor( ts.getColor());
        if( ts.isCollision((int)playHeadCurr)) {
          // update ColorPreview panel based on current pos. of slider
          //playHeadCurr = ts.x - 1;        //break;
          playHeadCurr = ts.x;        // FIXME: why was this "- 1"?
        } 
      }
    }
    repaint();
  }

  public void mouseMoved(MouseEvent e) {
  }

  public void mouseDragged(MouseEvent e) {
    //l.debug("dragged:"+e);
    // if playhead is selected movie it
    if (isPlayHeadClicked) {
      playHeadCurr = e.getPoint().x;
          
      // bounds check for playhead
      if (playHeadCurr < sx)
        playHeadCurr = sx;
      else if (playHeadCurr > loopEnd)
        playHeadCurr = loopEnd;
    } 
    else {
      // make multiple selection of timeslices on mousedrag
      int x = e.getPoint().x;
      int y = e.getPoint().y;
      for( int j=0; j<numTracks; j++ ) {
        TimeSlice[] timeSlices = timeTracks[j].timeSlices;
        for( int i=0;i<numSlices;i++) {
          TimeSlice ts = timeSlices[i];
          ts.isActive = ts.isActive || ts.isCollision(mouseClickedPt.x,x, mouseClickedPt.y,y);
        }
      }
    }
      
    repaint();
  }
  
  public void toggleSoloO(int track) {
    int soloTrack = -1;
    timeTracks[track].active = !timeTracks[track].active;
  }

  //
  // if all tracks active, deactivate all other tracks, active this track
  // if some non-this tracks deactive, toggle track active
  // if only this track active, re-active all tracks
  // (this seems needlessly complex,btw)
  //
  public void toggleSolo(int track) {
    boolean someactive = false;
    boolean thisactive = false;
    int activecount = 0;
    for( int i=0; i<numTracks; i++ ) { // find which tracks are active
      if( timeTracks[i].active ) {
        someactive = true;
        if( i==track ) thisactive = true;
        activecount++;
      }
    }
    println("cnt:"+activecount+", some:"+someactive+", this:"+thisactive);
    if( activecount == numTracks ) {  // traditional solo case
      for( int i=0; i<numTracks; i++ )
        timeTracks[i].active = false; 
      timeTracks[track].active = true; // solo only this track
    }
    else if( someactive ) {              // if we're already soloing, reactive
      if( activecount==1 && timeTracks[track].active ) {
        for( int i=0; i<numTracks; i++ )
          timeTracks[i].active = true; 
      }
      else 
        timeTracks[track].active = !timeTracks[track].active;
    }
  }

  //
  public void doTrackDialog(int track) {
    int blinkmAddr = blinkmAddrs[track];
    String s = (String)
      JOptionPane.showInputDialog(
                                  this,
                                  "Enter a new BlinkM address for this track",
                                  "Set track address",
                                  JOptionPane.PLAIN_MESSAGE,
                                  null,
                                  null,
                                  ""+blinkmAddr);
    
    //If a string was returned, say so.
    if ((s != null) && (s.length() > 0)) {
      l.debug("s="+s);
      try { 
        blinkmAddr = Integer.parseInt(s);
        if( blinkmAddr >=0 && blinkmAddr < 127 ) { // i2c limits
          blinkmAddrs[track] = blinkmAddr;
        }
      } catch(Exception e) {}
      
    }    
  }

} // TimeLine


