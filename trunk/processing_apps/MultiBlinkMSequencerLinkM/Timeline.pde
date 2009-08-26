// Copyright (c) 2007-2008, ThingM Corporation

/**
 *
 */
public class Timeline extends JPanel implements MouseListener, MouseMotionListener {
  
  private boolean multimode = false;

  private int scrubHeight = 10;             // height of scrubber area
  public int spacerWidth = 2;               // width between cells
  private int w;                            // width of timeline
  private int h;                            // height of timeline
  private int sx = 50;                      // offset from left edge of screen
  private int trackHeight;                  // height of each track 

  private Point mouseClickedPt;
  
  private Color playHeadC = new Color(255, 0, 0);
  private float playHeadCurr = sx;
  private int loopEnd;  //FIXME: need a better name

  //private javax.swing.Timer timer;
  //private int timerMillis = 25;        // time between timer firings
  //private int timerMillis;        // time between ticks  (1/frameRate)
  
  private boolean isPlayHeadClicked = false;
  private boolean isLoop = true;           // timer, loop or no loop
  private long startTime = 0;             // debug, start time of play
  private boolean playing = false;

  private Font font;

  private int numSlices;
  private int numTracks;
  public TimeTrack[] timeTracks;
  
  /**
   * @param multi if true, timeline is multi-track, otherwise single track
   * @param numTracks number of tracks this timeline represents
   * @param numSlices number of slices in a track
   * @param aHeight height of timeline in pixels
   * @param aWidth width of timeline in pixels
   */
  public Timeline(boolean multi, int numSlices, int numTracks, int aWidth, int aHeight ) {
    this.multimode = multi;
    this.numSlices = numSlices;
    this.numTracks = numTracks;
    this.w = aWidth;           // overall width of timeline object
    this.h = aHeight;
    this.timeTracks = new TimeTrack[numTracks];
    this.trackHeight = (h - scrubHeight) / numTracks;
    println("trackHeight: "+trackHeight);
    this.loopEnd = w-20;
    this.setPreferredSize(new Dimension(this.w, this.h));
    this.setBackground(bgDarkGray);
    addMouseListener(this);
    addMouseMotionListener(this);
    //mf.addKeyListener(this);

    //this.font = new Font("Monospaced", Font.PLAIN, 9);
    this.font = silkfont;  // global in main class

    for( int j=0; j<numTracks; j++ ) {
      int sy = scrubHeight + j*trackHeight;
      TimeTrack tc = new TimeTrack(sx,sy,w,trackHeight-spacerWidth,spacerWidth);
      timeTracks[j] = tc;
    }

    // give people a nudge on what to do
    selectSlice( 0, true);
  }

  /**
   * @Override
   */
  public void paintComponent(Graphics gOG) {
    Graphics2D g = (Graphics2D) gOG;
    super.paintComponent(g); 
    // draw light gray background for playhead area
    //g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, 
    //                   RenderingHints.VALUE_ANTIALIAS_ON);
    g.setColor(fgLightGray);
    g.fillRect(0, 0, getWidth(), scrubHeight);

    // draw each time track
    for( int j=0; j<numTracks; j++ ) {
      TimeSlice[] timeSlices = timeTracks[j].timeSlices;      
      // draw track
      for( int i=0; i<numSlices; i++) {
        timeSlices[i].draw(g);
      }
      if( multimode ) {
        paintTrackButtons(g, j);
      }
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
   * Draw enable & addr buttons on left side of timeline
   * @param g Graphics to draw on
   * @param tnum track number (0..maxtracks)
   */
  void paintTrackButtons(Graphics2D g, int tnum ) {
    int blinkmAddr = blinkmAddrs[tnum]; // get this track i2c address
    g.setFont(font);
    BasicStroke stroke = new BasicStroke(0.5f);
    g.setStroke(stroke);
    g.setColor( briOrange);
    g.drawRect(  3,15+tnum*trackHeight, 15,10 );  // enable button outline 
    g.drawRect( 25,15+tnum*trackHeight, 20,10 );  // addr button outline 
    
    if( timeTracks[tnum].active == true ) { 
      g.setColor( muteOrange );
      g.fillRect(  4, 16+tnum*trackHeight, 14,9 );  // enable button insides
      g.fillRect( 26, 16+tnum*trackHeight, 19,9 );  // addr button insides
      
      g.setColor( cBlk );
      int offs = 26;
      offs = ( blinkmAddr < 100 ) ? offs += 6 : offs;
      offs = ( blinkmAddr < 10 )  ? offs += 5 : offs;
      g.drawString( ""+blinkmAddr, offs, 23+tnum*trackHeight);  // addr text
    }
  }
  /**
   *
   */
  void paintPlayHead(Graphics2D g) {
    g.setColor(playHeadC);
    g.fillRect((int)playHeadCurr, 0, spacerWidth, getHeight());
    //if( !multimode ) {
    Polygon p = new Polygon();
    p.addPoint((int)playHeadCurr - 5, 0);
    p.addPoint((int)playHeadCurr + 5, 0);
    p.addPoint((int)playHeadCurr + 5, 5);
    p.addPoint((int)playHeadCurr + 1, 10);
    p.addPoint((int)playHeadCurr - 1, 10);
    p.addPoint((int)playHeadCurr - 5, 5);
    p.addPoint((int)playHeadCurr - 5, 0);    
    g.fillPolygon(p);
    //}
  }
  
  void paintLoopEnd(Graphics2D g) {
    g.setColor(playHeadC);
    g.fillRect( loopEnd,0, spacerWidth, h );
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

  public boolean isPlaying() { 
    return playing;
  }

  /**
   *
   */
  public void play() {
    l.debug("starting to play for dur: " + durationCurrent);
    playing = true;
    startTime = System.currentTimeMillis();
  }

  /**
   *
   */
  public void stop() {
    l.debug("stop"); 
    playing = false;
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
  
  public void selectSlice( int slicenum, boolean state ) { 
    for( int i=0; i< numTracks; i++ ) 
      timeTracks[i].timeSlices[slicenum].selected = state;

  }

  /**
   * FIXME:
   */
  public void setActiveColor(Color c) { 
    // update selected TimeSlice in TimeLine
    for( int j=0; j<numTracks; j++) { 
      TimeSlice[] timeSlices = timeTracks[j].timeSlices;
      for( int i=0; i<numSlices; i++) {
        TimeSlice ts = timeSlices[i];
        if (ts.selected)
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
        timeSlices[i].selected = false;
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
   * does brute force search looking for selected
   */
  public int getPreviewColumn() {
    int col = -1;
    for( int j=0; j<numTracks; j++) {
      for( int i=0; i<numSlices; i++) {
        if( timeTracks[j].timeSlices[i].selected )
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
   *  Called once every "tick" of the application clock, usualy frameRate
   *
   */
  public void tick(float millisSinceLastTick) { 
    if( playing ) {
      int width = getWidth() - sx;
      // not quite sure why need to add one to durationCurrent here
      int durtmp = (durationCurrent>5) ?durationCurrent+1 : durationCurrent;
      float step = width / (durtmp*1000.0/millisSinceLastTick);
      
      playHeadCurr += step;
      repaint();
      
      if (playHeadCurr > loopEnd) {        // check for end of timeline
        reset();       // rest to beginning (and stop)
        if (isLoop) {  // if we loop
          play();      // start again
        } 
        else {        // or we stay stopped
          pb.setToPlay();  // FIXME:
        }
      } //if loopend
    } // if playing
  }

  // ---------------------------------------------------------------------

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
      // check for enable or address button hits
      for( int j=0; j<numTracks; j++) {
        boolean intrack = 
          (mp.y > j*trackHeight + scrubHeight) && 
          (mp.y < (j+1)*trackHeight + scrubHeight) ;
        if( intrack && (mp.x >= 3 && mp.x <= 3+15 ) )   // enable button
          toggleTrackEnable(j);
        else if( intrack && (mp.x >= 26 && mp.x <= 26+20 ) ) // addr button
            doTrackDialog(j);
        else {                                 // check for timeslice hit
          TimeSlice[] timeSlices = timeTracks[j].timeSlices;
          for( int i=0; i<numSlices; i++) {
            TimeSlice ts = timeSlices[i];
            if (ts.isCollision(mp.x)) 
              ts.selected = true;
            else if ((e.getModifiers() & InputEvent.META_MASK) == 0) 
              ts.selected = false; 
          }
        }
      } // for
    } // !playheadclicked

    //isMousePressed = true;
    mouseClickedPt = mp;

    repaint();
  }

  public void mouseReleased(MouseEvent e) {
    Point mouseReleasedPt = e.getPoint();
    int clickCnt = e.getClickCount();

    isPlayHeadClicked = false;
    // snap playhead to closest time slice
    for( int j=0; j<numTracks; j++ ) {
      TimeSlice[] timeSlices = timeTracks[j].timeSlices;
      for( int i=0; i<numSlices; i++) {
        TimeSlice ts = timeSlices[i];
        if( ts.selected && clickCnt >= 2 )   // double-click to set color
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
      TimeSlice[] timeSlices = timeTracks[0].timeSlices;
      for( int i=0;i<numSlices;i++) {
        TimeSlice ts = timeSlices[i];
        if( ts.isCollision(x,mouseClickedPt.x) )
          selectSlice(i,true);
      }
    }
      
    repaint();
  }
  

  // ------------------------------------------------------------------------

  public void toggleSoloO(int track) {
    int soloTrack = -1;
    timeTracks[track].active = !timeTracks[track].active;
  }

  public void toggleTrackEnable(int track) {
    timeTracks[track].active = !timeTracks[track].active;
  }

  //
  // if all tracks active, deactivate all other tracks, active this track
  // if some non-this tracks deactive, toggle track active
  // if only this track active, re-active all tracks
  // (this seems needlessly complex,btw)
  //
  public void toggleSolo1(int track) {
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


