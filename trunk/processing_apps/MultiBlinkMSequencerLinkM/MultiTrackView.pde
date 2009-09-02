/**
 * MultiTrackView
 *
 * Owns one or more Tracks
 * Draws scrubber area and playhead
 * Handles movement playhead (by mouse or by timing)
 * Handles selection of slices in tracks
 * Interrogates Tracks for their state .. DUH
 * Handles enable & address buttons on side of each track
 *
 */

public class MultiTrackView
  extends JPanel implements MouseListener, MouseMotionListener {

  Track[] tracks;
  Color[] previewColors;
  int previewFadespeed = 25;

  int numTracks;
  int numSlices;

  int currTrack;
  int currSlice;  // only valid on playback

  boolean playing = false;                  //    
  boolean looping = true;                   // loop or single-shot

  private int scrubHeight = 12;             // height of scrubber area
  private int spacerWidth = 2;              // width between cells
  private int spacerHalf = spacerWidth/2;
  private int w,h;                           // dimensions of me
  private int sx = 52;                      // aka "trackX", offs from left edge
  private int previewWidth = 30;           
  private int sliceWidth = 15;
  private int trackHeight = 15;                // height of each track 
  private int trackWidth;
  private int previewX;
  private Color playHeadC = new Color(255, 0, 0);
  private float playHeadCurr;
  private boolean playheadClicked = false;

  private Font font;

  private Point mouseClickedPt;

  private long startTime = 0;             // debug, start time of play

  TrackView tv;

  /**
   * @param numTracks  number of tracks in this multitrack
   * @param aWidth width of multitrack
   * @param aHeight height of multitrack
   */
  public MultiTrackView(int numTracks, int numSlices,  int w,int h) {
    this.numTracks = numTracks;
    this.numSlices = numSlices;
    this.w = w;           // overall width 
    this.h = h;
    this.setPreferredSize(new Dimension(this.w, this.h));
    this.setBackground(tlDarkGray);

    addMouseListener(this);
    addMouseMotionListener(this);

    //trackWidth = w - sx - previewWidth ;
    //previewX =  w - previewWidth - 10;
    trackWidth = numSlices * sliceWidth;
    previewX =  sx + trackWidth + 10;

    this.font = silkfont;  // global in main class

    // initialize the tracks
    tracks = new Track[numTracks];
    previewColors = new Color[numTracks];
    for( int j=0; j<numTracks; j++ ) {
      tracks[j] = new Track( numSlices, nullColor );
      tracks[j].blinkmaddr = 10+j;  // set default addrs
      previewColors[j] = nullColor;
    }

    currTrack = 0;
    // give people a nudge on what to do
    tracks[ currTrack ].active = true;
    tracks[ currTrack ].selects[0] =  true;

    reset();
  }

  public void addTrackView( TrackView tview ) {
    tv = tview;
  }

  /**
   * @Override
   */
  public void paintComponent(Graphics gOG) {
    Graphics2D g = (Graphics2D) gOG;
    //g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, 
    //                   RenderingHints.VALUE_ANTIALIAS_ON);
    super.paintComponent(g); 

    g.setColor( bgDarkGray );
    g.fillRect( 0,0, getWidth(), getHeight() );


    g.setFont(font);

    drawTracks(g);
    
    drawTrackButtons(g);

    drawPreview(g);

    drawTrackMarker(g);

    drawPlayHead(g, playHeadCurr);   // it goes on top, so it gets painted last
   
  }


  void drawTracks(Graphics2D g) {
    drawTracks(g, sx, 0, trackWidth, trackHeight);
  }

  void drawTracks(Graphics2D g, int x, int y, int w, int h) { 
    //l.debug("drawTracks: x:"+x+",y:"+y+",w:"+w+",h:"+h);
    int ty = 1 + scrubHeight;
    for( int i=0; i<numTracks; i++ ) {
      drawTrack( g, i,  x, ty+i*trackHeight, w, h  );
    }
  }

  void drawTrack(Graphics2D g, int tracknum, int x,int y, int w, int h ) {
    //l.debug("drawTrack: i:"+tracknum+",x:"+x+",y:"+y+",w:"+w+",h:"+h);
    g.setColor( bgDarkGray );
    g.fillRect( x, y, w, h);
    Track track = tracks[tracknum];

    // draw slices in track
    for( int i=0; i<numSlices; i++) {
      Color c = track.slices[i];
      g.setColor( c );
      g.fillRect( x+1, y+1, sliceWidth-2, h-2 );
      boolean sel = track.selects[i];
      if( track.selects[i] ) { // if selected 
        g.setStroke( new BasicStroke(1.1f) );
        g.setColor(cHighLight);
        g.drawRect(x, y, sliceWidth-1, h-1 );
      }
      x += sliceWidth; // go to next slice
    }
  }

  /**
   * Hilight the currently selected track
   */
  void drawTrackMarker(Graphics2D g) { 
    // hilite currTrack with marker
    int tx = 0; // was sx
    int ty = scrubHeight + (currTrack*trackHeight) ;
    //g.setColor( new Color( 200,140,140));
    g.setStroke( new BasicStroke(1.0f));
    g.setColor( muteOrange );
    //g.drawRect( tx,ty, trackWidth, trackHeight+1 );
    g.drawRect( tx,ty, w-1, trackHeight+1 );
  }

  /**
   * Draw enable & addr buttons on left side of timeline
   * @param g Graphics to draw on
   * @param tnum track number (0..maxtracks)
   */
  void drawTrackButtons(Graphics2D g ) {
    g.setStroke( new BasicStroke(1.0f) );
    int ty = 2 + scrubHeight ;
    int th = trackHeight - 3;
    for( int tnum=0; tnum<numTracks; tnum++ ) {
      g.setColor( briOrange);
      g.drawRect(  3,ty+tnum*trackHeight, 15,th );  // enable button outline 
      g.drawRect( 25,ty+tnum*trackHeight, 20,th );  // addr button outline 
      
      if( tracks[tnum].active == true ) { 
        g.setColor( muteOrange );
        g.fillRect(  4, ty+1+tnum*trackHeight, 14,th-1 ); // enable butt insides
        
        int blinkmAddr = tracks[tnum].blinkmaddr; // this track's i2c address
        if( blinkmAddr != -1 ) { // if it's been set to something meaningful
          g.fillRect( 26, ty+1+tnum*trackHeight, 19,th-1 ); // addr butt insides
          g.setColor( cBlk );
          int offs = 26;
          offs = ( blinkmAddr < 100 ) ? offs += 6 : offs;
          offs = ( blinkmAddr < 10 )  ? offs += 5 : offs;
          g.drawString( ""+blinkmAddr, offs, ty+9+tnum*trackHeight);// addr text
        }
      }
    }
  }

  /**
   *
   */
  void drawPlayHead(Graphics2D g, float playHeadCurr) {
    // paint scrub area
    g.setColor(fgLightGray);
    g.fillRect(0, 0, getWidth(), scrubHeight-spacerWidth);

    g.setStroke( new BasicStroke(0.5f) );
    
    g.setColor( playHeadC );
    g.fillRect((int)playHeadCurr, 0, spacerWidth, getHeight());

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

  /**
   *
   */
  void drawPreview(Graphics2D g ) {
    for( int i=0; i<numTracks; i++) { 
      Color ct = tracks[i].slices[currSlice];
      Color c = previewColors[i];
      int rt = ct.getRed();
      int gt = ct.getGreen();
      int bt = ct.getBlue();
      int ro  = c.getRed();
      int go  = c.getGreen();
      int bo  = c.getBlue();
      ro = color_slide( ro,rt, previewFadespeed);
      go = color_slide( go,gt, previewFadespeed);
      bo = color_slide( bo,bt, previewFadespeed);
      previewColors[i] = new Color( ro,go,bo );
      
      int ty =  spacerWidth + scrubHeight + (i*trackHeight);
      g.setColor( previewColors[i] );
      g.fillRect( previewX , ty, previewWidth-1 , trackHeight-spacerWidth);
    }
  }
  

  int color_slide(int curr, int dest, int step) {
    int diff = curr - dest;
    if(diff < 0)  diff = -diff;
    
    if( diff <= step ) return dest;
    if( curr == dest ) return dest;
    else if( curr < dest ) return curr + step;
    else                   return curr - step;
  }

  // --------------------------------------------------------------------------


  /**
   *  Called once every "tick" of the application clock, usualy frameRate
   *
   */
  public void tick(float millisSinceLastTick) { 
    if( playing ) {

      // not quite sure why need to add one to durationCurrent here
      int durtmp = (durationCurrent>5) ? durationCurrent+1 : durationCurrent;
      float step = trackWidth / (durtmp*1000.0/millisSinceLastTick);
      
      previewFadespeed = getFadeSpeed(durationCurrent);
      int newSlice = getCurrSliceNum();
      if( newSlice != currSlice ) {
        currSlice = newSlice;
        for( int i=0; i<numTracks; i++ ) {
          Color c = tracks[i].slices[currSlice];
          if( c!=null && c != nullColor ) { // the default "off", a hack FIXME
            sendBlinkMColor( tracks[i].blinkmaddr, c );
          }
        }
      }
      
      playHeadCurr += step;
      repaint();

      // FIXME: +2
      if( playHeadCurr >= sx + trackWidth +1) {   // check for end of timeline
        reset();       // rest to beginning (and stop)
        if( looping ) {  // if we loop
          play();      // start again
        } 
        else {        // or no loop, so stop after one play
          buttonPanel.setToPlay();  // set play/stop button back to play
        }
      } //if loopend
    } // if playing
    else {
      previewFadespeed = 1000;
    }

    if( tv!=null) tv.tick(millisSinceLastTick);
  }

  /**
   *
   */
  public void play() {
    l.debug("starting to play for dur: " + durationCurrent);
    playing = true;
    startTime = System.currentTimeMillis();
    if( tv!=null) tv.play();
  }

  /**
   *
   */
  public void stop() {
    l.debug("stop"); 
    playing = false;
    l.debug("elapsedTime:"+(System.currentTimeMillis() - startTime));
    if( tv!=null) tv.stop();
  }

  /**
   *
   */
  public void reset() {
    stop();
    playHeadCurr = sx;
    repaint();
    if( tv!=null) tv.reset();
  }

  /**
   * Set all timeslices to be inactive
   * FIXME: hack
   */
  public void allOff() {
    // reset timeslice selections
    for( int i=0; i<numTracks; i++) { 
      allOffTrack( i );
    }
  }
  /**
   * Sets all timeslices for a particular track to be not selected
   */
  public void allOffTrack( int trackindex ) {
    for( int i=0; i<numSlices; i++) {
      tracks[ trackindex ].selects[i] = false;
    }
  }

  /** 
   * select all the slices in a given column
   * @param slicenum time slice index
   * @param state select or deselect
   */
  public void selectSlice( int slicenum, boolean state ) { 
    for( int i=0; i< numTracks; i++ ) 
      tracks[i].selects[slicenum] = state;
    repaint();
  }

  public void toggleSlice( int slicenum ) { 
    for( int i=0; i< numTracks; i++ ) 
      tracks[i].selects[slicenum] = ! tracks[i].selects[slicenum];
    repaint();
  }

  public void setSelectedColor( Color c ) {
    //l.debug("setSelectedColor: "+c);
    for( int i=0; i<numTracks; i++) {
      for( int j=0; j<numSlices; j++) { 
        if( tracks[i].selects[j] ) {
          tracks[i].slices[j] = c;
        }
      }
    }
    repaint();
  }
 
  /**
   * For a given slice on the Tracks, return an array of all the colors
   */
  public Color[] getColorsAtSlice(int slicenum) {
    Color[] colors = new Color[numTracks];
    for( int j=0; j<numTracks; j++)  // gather up all the colors 
      colors[j] = tracks[j].slices[slicenum];
    return colors;
  }
 
  /**
   * Get the time slice index of the current playing slice
   */
  public int getCurrSliceNum() {
    int cs=0;
    for(int i=0; i<numSlices; i++) {
      if( isSliceHit( (int)playHeadCurr, i ) ) {
        cs = i;
      }
    }
    return cs;
  }
    
  /**
   *
   */
  public Track getCurrTrack() {
    return tracks[currTrack];
  }
 

  // --------------------------------------------------------------------------
  
  /**
   * Returns true if mouse is within a time slice.
   * @param mx mouse x-coord
   * @param slicenum index of time slice
   */
  public boolean isSliceHit( int mx, int slicenum ) {
    return isSliceHit( mx, sx + (slicenum*sliceWidth), sliceWidth );
  }
  /**
   * Returns true if mouse is within a time slice.
   * @param mx1 mouse x-coord start pos
   * @param mx2 mouse x-coord end pos
   * @param slicenum index of time slice
   */
  public boolean isSliceHitRanged( int mx1, int mx2, int slicenum ) {
    return isSliceHitRanged( mx1, mx2, sx + (slicenum*sliceWidth), sliceWidth );
  }
  // generalized version of above
  public boolean isSliceHit(int mx, int slicex, int slicew ) {
    return (mx < (slicex + slicew ) && mx >= slicex); 
  }
  // generalized version of above
  public boolean isSliceHitRanged( int mx1,int mx2, int slicex, int slicew ) {
    if( mx2 > mx1 ) 
      return (mx1 < (slicex + slicew ) && mx2 >= slicex);
    else 
      return (mx2 < (slicex + slicew ) && mx1 >= slicex);
  }


  public void mouseClicked(MouseEvent e) {
    //l.debug("MultiTrack.mouseClicked");
  }

  public void mouseEntered(MouseEvent e) {
    //l.debug("entered");
  }

  public void mouseExited(MouseEvent e) {
    //l.debug("exited");
  }

  /**
   * @param mp mouse point of click
   */
  public boolean isPlayheadClicked(Point mp) {
    Polygon p = new Polygon();  // creating bounding box for playhead
    p.addPoint((int)playHeadCurr - 3, 0);
    p.addPoint((int)playHeadCurr + 3, 0);
    p.addPoint((int)playHeadCurr + 3, getHeight());
    p.addPoint((int)playHeadCurr - 3, getHeight());

    return p.contains(mp);  // check if mouseclick on playhead
  }
  
  /**
   * Copy any selection from old track to new track
   */
  public void copySelects( int newtrackindex, int oldtrackindex ) {
    for( int i=0; i<numSlices; i++) 
      tracks[newtrackindex].selects[i] = tracks[oldtrackindex].selects[i];
  }

  public void mousePressed(MouseEvent e) {
    l.debug("MultiTrack.mousePressed: "+e.getPoint());
    Point mp = e.getPoint();
    mouseClickedPt = mp;

    // playhead hits handled fully in mouseDragged
    // record location of hit in mouseClickedPt and go on
    playheadClicked = isPlayheadClicked(mp);
    if( playheadClicked ) {
      repaint();
      return;
    }
    
    // check for enable or address button hits
    for( int j=0; j<numTracks; j++) {
      boolean intrack = 
        (mp.y > j*trackHeight + scrubHeight) && 
        (mp.y < (j+1)*trackHeight + scrubHeight) ;

      if( intrack && (mp.x >= 3 && mp.x <= 3+15 ) ) // enable button
        toggleTrackEnable(j);
      else if( intrack && (mp.x >= 26 && mp.x <= 26+20 ) ) // addr button
        doTrackDialog(j);
      else if( intrack ) {                         // just track selection
        copySelects(j, currTrack);
        allOffTrack( currTrack );
        currTrack = j;  
      }
    }
    
    repaint();
  }

  public void mouseReleased(MouseEvent e) {
    Point mouseReleasedPt = e.getPoint();
    int clickCnt = e.getClickCount();

    playheadClicked = false;
    /*
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
    */
    repaint();
  }

  public void mouseMoved(MouseEvent e) {
  }

  public void mouseDragged(MouseEvent e) {
    //l.debug("dragged:"+e);
    if (playheadClicked) {             // if playhead is selected move it
      playHeadCurr = e.getPoint().x;
          
      // bounds check for playhead
      if (playHeadCurr < sx)
        playHeadCurr = sx;
      else if (playHeadCurr > trackWidth)
        playHeadCurr = trackWidth;
      if( tv!=null ) tv.playHeadCurr = playHeadCurr;
    } 
    else {
      /*
      // make multiple selection of timeslices on mousedrag
      int x = e.getPoint().x;
      for( int i=0; i<numSlices; i++) {
        if( isSliceHitRanged( x, mouseClickedPt.x, i) ) {
          selectSlice(i,true);
        }
      }
      */
    }

    repaint();
  }


  // ------------------------------------------------------------------------

  public void toggleTrackEnable(int track) {
    tracks[track].active = !tracks[track].active;
  }

  //
  public void doTrackDialog(int track) {
    int blinkmAddr = tracks[track].blinkmaddr;
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
          tracks[track].blinkmaddr = blinkmAddr;
        }
      } catch(Exception e) {}
      
    }    
  }

}
