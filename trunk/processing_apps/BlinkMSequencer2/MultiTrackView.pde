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

  PImage previewAlpha;  // oi
  PImage checkboxImg;

  Track[] tracks;
  Color[] previewColors;
  int previewFadespeed = 25;
  Track bufferTrack;  // for copy-paste ops

  int currTrack;                            // currently selected track
  int currSlice;                            // only valid on playback

  boolean playing = false;                  //    
  boolean looping = true;                   // loop or single-shot

  private int scrubHeight = 12;             // height of scrubber area
  private int spacerWidth = 2;              // width between cells
  private int spacerHalf = spacerWidth/2;
  private int w,h;                          // dimensions of me
  private int sx = 57;                    // aka "trackX", offset from left edge
  private int previewWidth = 19;            // width of preview cells
  private int sliceWidth   = 17;            // width of editable cells
  private int trackHeight  = 18;            // height of each track 
  private int trackWidth;                   // == numSlices * sliceWidth
  private int previewX;
  private Color playHeadC = new Color(255, 0, 0);
  private float playHeadCurr;
  private boolean playheadClicked = false;

  private Font trackfont;

  private Point mouseClickedPt;
  private Point mousePt = new Point();;

  private long startTime = 0;             // debug, start time of play

  //TrackView tv;

  /**
   * @param aWidth width of multitrack
   * @param aHeight height of multitrack
   */
  public MultiTrackView(int w,int h) {
    this.w = w;           // overall width 
    this.h = h;
    this.setPreferredSize(new Dimension(this.w, this.h));
    this.setBackground(tlDarkGray);


    addMouseListener(this);
    addMouseMotionListener(this);

    trackWidth = numSlices * sliceWidth;
    previewX =  sx + trackWidth + 5;

    trackfont = textSmallfont;  //silkfont;  // global in main class
    previewAlpha = loadImage("radial-gradient.png");//"alpha_channel.png");
    previewAlpha = previewAlpha.get(0,2,previewAlpha.width,previewAlpha.height-1);
    checkboxImg = loadImage("checkbox.gif");

    bufferTrack = new Track(numSlices, cEmpty);
    bufferTrack.active = false; // say not full of copy

    // initialize the tracks
    tracks = new Track[numTracks];
    previewColors = new Color[numTracks];
    for( int j=0; j<numTracks; j++ ) {
      tracks[j] = new Track( numSlices, cEmpty );
      tracks[j].blinkmaddr = blinkmStartAddr +j;  // set default addrs
      previewColors[j] = cEmpty;
      tracks[j].label = "Channel "+(j+1)+" Label";
    }

    changeTrack(0);

    // give people a nudge on what to do
    tracks[ currTrack ].active = true;
    tracks[ currTrack ].selects[0] =  true;

    setToolTipText(""); // register for tooltips, so getToolTipText(e) works

    reset();
  }

  /*
  public void addTrackView( TrackView tview ) {
    tv = tview;
  }
  */

  /**
   * @Override
   */
  public void paintComponent(Graphics gOG) {
    Graphics2D g = (Graphics2D) gOG;
    g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, 
                       RenderingHints.VALUE_ANTIALIAS_ON);
    super.paintComponent(g); 

    g.setColor( cBgDarkGray );
    g.fillRect( 0,0, getWidth(), getHeight() );

    g.setFont(trackfont);

    drawTracks(g);
    
    drawTrackButtons(g);

    drawPreview(g);

    //drawTrackMarker(g);

    drawPlayHead(g, playHeadCurr);   // it goes on top, so it gets painted last
   
  }


  void drawTracks(Graphics2D g) {
    drawTracks(g, sx, 0, trackWidth, trackHeight);
  }

  void drawTracks(Graphics2D g, int x, int y, int w, int h) { 
    int ty = 1 + scrubHeight;
    for( int i=0; i<numTracks; i++ ) {
      drawTrack( g, i,  x, ty+i*trackHeight, w, h  );
    }
  }

  void drawTrack(Graphics2D g, int tracknum, int x,int y, int w, int h ) {
    g.setColor( cBgDarkGray );
    if( tracknum == currTrack ) {
      g.setColor( Color.black );
    }
    g.fillRect( x, y, w, h);
    Track track = tracks[tracknum];

    // draw slices in track
    for( int i=0; i<numSlices; i++) {
      Color c = track.slices[i];
      g.setColor( c );
      g.fillRect( x+2, y+2, sliceWidth-4, h-4 );

      boolean sel = track.selects[i];
      if( track.selects[i] ) { // if selected 
        g.setStroke( new BasicStroke(2f) );
        g.setColor(cHighLight);
        g.drawRect(x, y, sliceWidth-1, h-1 );
      }

      x += sliceWidth; // go to next slice
    }
  }

  /**
   * Hilight the currently selected track
   * hilite currTrack with marker
   */
  void drawTrackMarker(Graphics2D g) { 
    int tx = 0; // was sx
    int ty = scrubHeight + (currTrack*trackHeight) ;
    g.setStroke( new BasicStroke(1.0f));
    g.setColor( cBgLightGray );
    //g.drawRect( tx,ty, trackWidth, trackHeight+1 );
    g.drawRect( tx,ty, w-1, trackHeight+1 );
  }

  /**
   * Draw enable & addr buttons on left side of timeline
   * @param g Graphics to draw on
   */
  void drawTrackButtons(Graphics2D g ) {
    g.setStroke( new BasicStroke(1.0f) );
    int ty = 2 + scrubHeight ;
    int th = trackHeight - 3;
    Point mp = mousePt;
    //l.debug("drawTrackButtons: "+mp);
    for( int tnum=0; tnum<numTracks; tnum++ ) {
      Color outlinecolor = cBriOrange;

      //boolean intrack = (mp.y > tnum*trackHeight + scrubHeight) && 
      //  (mp.y < (tnum+1)*trackHeight + scrubHeight) ;
      //if( intrack ) 
      //outlinecolor = cHighLight;

      g.setColor( outlinecolor );
      g.drawRect(  8,ty+tnum*trackHeight, 15,th );  // enable button outline 
      g.drawRect( 30,ty+tnum*trackHeight, 20,th );  // addr button outline 
      
      if( tracks[tnum].active == true ) {
        g.setColor( cMuteOrange2 );
        g.fillRect(  9, ty+1+tnum*trackHeight, 14,th-1 ); // enable butt insides
        g.drawImage( checkboxImg.getImage(), 10,ty+3+tnum*trackHeight  ,null);

        int blinkmAddr = tracks[tnum].blinkmaddr; // this track's i2c address
        if( blinkmAddr != -1 ) { // if it's been set to something meaningful
          g.setStroke( new BasicStroke(1.0f) );
          g.setColor( cMuteOrange2 );
          g.fillRect( 31, ty+1+tnum*trackHeight, 19,th-1 ); // addr butt insides
          g.setColor( cDarkGray );
          int offs = 31;
          offs = ( blinkmAddr < 100 ) ? offs += 3 : offs;
          offs = ( blinkmAddr < 10 )  ? offs += 4 : offs;
          g.drawString( ""+blinkmAddr, offs, ty+13+tnum*trackHeight);//addr text
        }
      }
    }
  }

  /**
   *
   */
  void drawPlayHead(Graphics2D g, float playHeadCurr) {
    // paint scrub area
    g.setColor(cFgLightGray);
    g.fillRect(0, 0, getWidth(), scrubHeight-spacerWidth);

    g.setStroke( new BasicStroke(0.5f) );
    // create vertical playbar
    g.setColor( playHeadC );                      //FIXME:why 10?
    g.fillRect((int)playHeadCurr, 0, spacerWidth, getHeight()-10);

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
   * FIXME: color sliding doesn't work
   */
  void drawPreview(Graphics2D g ) {
    int csn = getCurrSliceNum();
    for( int i=0; i<numTracks; i++) { 
      Color ct = tracks[i].slices[csn];
      Color c = previewColors[i];
      int rt = ct.getRed();
      int gt = ct.getGreen();
      int bt = ct.getBlue();
      int rn = c.getRed();     // 'rn' for 'red now'
      int gn = c.getGreen();
      int bn = c.getBlue();
      rn = color_slide( rn,rt, previewFadespeed);
      gn = color_slide( gn,gt, previewFadespeed);
      bn = color_slide( bn,bt, previewFadespeed);
      previewColors[i] = new Color( rn,gn,bn );
      
      int ty =  spacerWidth + scrubHeight + (i*trackHeight);
      g.setColor( previewColors[i] );
      g.fillRect( previewX , ty, previewWidth-1 , trackHeight-spacerWidth);
      g.drawImage(previewAlpha.getImage(), previewX,ty,null);
    }
  }
  
  /**
   * emulate blinkm firmware color fading
   */
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
      
      int send_addrs[] = new int[numTracks];
      Color send_colors[] = new Color[numTracks];
      int send_count=0;

      previewFadespeed = getFadeSpeed(durationCurrent);
      int newSlice = getCurrSliceNum();
      if( newSlice != currSlice ) {
        currSlice = newSlice;
        for( int i=0; i<numTracks; i++ ) {
          Color c = tracks[i].slices[currSlice];
          if( tracks[i].active ) {
            send_addrs[send_count] = tracks[i].blinkmaddr;
            if( c!=null && c != cEmpty ) { 
              send_colors[send_count] = c;
              //sendBlinkMColor( tracks[i].blinkmaddr, c );
            } else if( c == cEmpty ) {
              //sendBlinkMColor( tracks[i].blinkmaddr, cBlack );
              send_colors[send_count] = cBlack;
            }
            send_count++;
          }
        }
      }
      if( send_count > 0 ) {
        sendBlinkMColors( send_addrs, send_colors, send_count );
      }

      playHeadCurr += step;

      // FIXME: +2
      if( playHeadCurr >= sx + trackWidth +1) {   // check for end of timeline
        reset();         // rest to beginning (and stop)
        if( looping ) {  // if we loop
          play();        // start again
        } 
        else {           // or no loop, so stop after one play
          buttonPanel.setToPlay();  // set play/stop button back to play
        }
      } //if loopend
      repaint();
    } // if playing
    else {
      previewFadespeed = 1000;
    }
    //if( tv!=null) tv.tick(millisSinceLastTick);
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

  /**
   * Set all timeslices to be inactive
   * FIXME: hack
   */
  public void deselectAllTracks() {
    // reset timeslice selections
    for( int i=0; i<numTracks; i++) { 
      deselectTrack( i );
    }
  }
  public void selectAllinTrack() {
      selectAll( currTrack );
  }
  /**
   *
   */
  public void selectAll( int trackindex ) {
    for( int i=0; i<numSlices; i++) {
      tracks[ trackindex ].selects[i] = true;
    }
  }
  /**
   * Sets all timeslices for a particular track to be not selected
   */
  public void deselectTrack( int trackindex ) {
    for( int i=0; i<numSlices; i++) {
      tracks[ trackindex ].selects[i] = false;
    }
  }

  public void disableAllTracks() {
    for( int i=0; i< tracks.length; i++) {
      tracks[i].active = false;
    }
    deselectAllTracks();
  }

  public void toggleTrackEnable(int track) {
    tracks[track].active = !tracks[track].active;
  }

  public void changeTrack(int newtracknum) {
    l.debug("changeTrack "+newtracknum);
    if( newtracknum < 0 ) newtracknum = 0;
    if( newtracknum == numTracks ) newtracknum = numTracks - 1;
    if( newtracknum != currTrack ) {
      copySelects(newtracknum, currTrack);
      deselectTrack(currTrack);
      currTrack = newtracknum;
      updateInfo();
      repaint();
    }
  }

  public void nextTrack() {
    changeTrack( currTrack + 1 );
  }

  public void prevTrack() {
    changeTrack( currTrack - 1 );
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
  
  public void selectSlice( int tracknum, int slicenum, boolean state ) {
    tracks[tracknum].selects[slicenum] = state;
    repaint();
  }

  public void nextSlice(int modifiers) {
    int slicenum=-1;
    Track t = getCurrTrack();
    for( int i=0; i<numSlices; i++) {
      if( t.selects[i] == true ) { 
        if( modifiers==0 ) t.selects[i] = false;
        slicenum = i;
      }
    }
    if( slicenum>=0 ) {
      if( modifiers == 0 ) selectSlice(currTrack, slicenum,false);
      int nextslice = (slicenum==numSlices-1)?numSlices-1:slicenum+1;
      selectSlice(currTrack, nextslice,true);
    }
  }

  // 
  // FIXME: This is a hack, wrt modifiers and in general
  //
  public void prevSlice(int modifiers) {
    int slicenum=-1;
    Track t = getCurrTrack();
    for( int i=0; i<numSlices; i++) {
      int j = numSlices-i-1;
      if( t.selects[j] == true ) { 
        if( modifiers == 0 ) t.selects[j] = false;
        slicenum = j;
      }
    }
    if( slicenum>0 ) {
      if( modifiers == 0 ) selectSlice(currTrack, slicenum,false);
      int nextslice = (slicenum==0) ? 0 : slicenum-1;
      selectSlice(currTrack, nextslice,true);
    }              
  }

  public void toggleSlice( int slicenum ) { 
    for( int i=0; i< numTracks; i++ ) 
      tracks[i].selects[slicenum] = ! tracks[i].selects[slicenum];
    repaint();
  }

  /**
   * used by the ColorChooserPanel
   */
  public void setSelectedColor( Color c ) {
    boolean sentColor = false;
    l.debug("setSelectedColor: "+c);
    for( int i=0; i<numTracks; i++) {
      for( int j=0; j<numSlices; j++) { 
        if( tracks[i].selects[j] ) {
          tracks[i].slices[j] = c;
          if( !sentColor ) {
            sendBlinkMColor( tracks[i].blinkmaddr, c);
            sentColor=true;  // FIXME: hmmm
          }
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
 
  /**
   * Copy any selection from old track to new track
   */
  public void copySelects( int newtrackindex, int oldtrackindex ) {
    for( int i=0; i<numSlices; i++) 
      tracks[newtrackindex].selects[i] = tracks[oldtrackindex].selects[i];
  }
  
  /** 
   * Copy current selects to buffer
   */
  public void copy() {
    //bufferTrack.copy( tracks[currTrack] );
    bufferTrack.copy( tracks[currTrack] );
  }
  public void paste() {
    tracks[currTrack].copySlices( bufferTrack );
  }
  public void cut() { 
    copy();
    delete();
  }
  public void delete() {       
    //tracks[currTrack].erase();    // this deletes whole track
    Track t = getCurrTrack();
    for( int i=0; i<numSlices; i++ ) {
      if( t.selects[i] )
        t.slices[i] = cEmpty;
    }
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

  /**
   * give color vals on tooltip
   */
  public String getToolTipText(MouseEvent e) {
    Point mp = e.getPoint();
    for( int j=0; j<numTracks; j++) {
      boolean intrack = 
        (mp.y > j*trackHeight + scrubHeight) && 
        (mp.y < (j+1)*trackHeight + scrubHeight) ;
      if( intrack ) {
        for( int i=0; i<numSlices; i++) {
          if( isSliceHit( mp.x, i) ) {
            Color c = tracks[j].slices[i];
            if( c == cEmpty ) return "";
            return ""+c.getRed()+","+c.getGreen()+","+c.getBlue();
          }
        }
      }
    }
    return "";
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
    p.addPoint((int)playHeadCurr - 5, 0);
    p.addPoint((int)playHeadCurr + 5, 0);
    p.addPoint((int)playHeadCurr + 5, getHeight());
    p.addPoint((int)playHeadCurr - 5, getHeight());

    return p.contains(mp);  // check if mouseclick on playhead
  }
    
  
  //
  public void mousePressed(MouseEvent e) {
    //l.debug("MultiTrackView.mousePressed: "+e);
    Point mp = e.getPoint();
    mouseClickedPt = mp;
    requestFocus();

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

      if( intrack && (mp.x >= 9+0 && mp.x <=  9+20 ) ) // enable button
        toggleTrackEnable(j);
      else if( intrack && (mp.x >= 26 && mp.x <= 26+20 ) ) // addr button
        doTrackDialog(j);
      else if( intrack ) {                         // just track selection
        //copySelects(j, currTrack);
        if( currTrack != j ) {  // only deselect & change track if different
          deselectTrack( currTrack );
          changeTrack( j );
        }

        // make a gradient, from first selected color to ctrl-clicked color
        // FIXME this is somewhat unreadable
        if( (e.getModifiers() & InputEvent.CTRL_MASK) !=0) {
          int sliceClicked = sliceClicked(mouseClickedPt.x);
          int firstSlice = -1;
          for( int i=0; i<numSlices; i++ ) { 
            if( tracks[currTrack].selects[i] ) {
              firstSlice = i;
              break;
            }
          }
          if( firstSlice != -1 && sliceClicked != -1 ) {
            makeGradient( currTrack, firstSlice, sliceClicked );
          }
          return;
        }

        // change selection
        for( int i=0; i<numSlices; i++) {
          if( isSliceHit( mouseClickedPt.x, i) ) 
            selectSlice(currTrack, i,true);
          else if((e.getModifiers() & InputEvent.META_MASK) ==0) //meta not
            selectSlice(currTrack, i,false);
        }


      } // if(intrack)

    } // for all tracks
    
    //repaint();
  }

  /**
   * make a gradient on the current track, 
   * based on the colors of the start & end of the selection
   */
  public void makeGradient() {
    int start = -1;
    int end = -1;
    for( int i=0; i<numSlices; i++ ) {
      if( tracks[currTrack].selects[i] ) { 
        if( start == -1 ) {
          start = i;
        } else {
          end = i;
        }
      }
    }
    makeGradient( currTrack, start, end );
  }

  /*
   *
   */
  public void makeGradient( int tracknum, int sliceStart, int sliceEnd ) {
    int d = sliceEnd - sliceStart;
    if( d==0 ) return;
    Color sc = tracks[tracknum].slices[sliceStart];
    Color ec  = tracks[tracknum].slices[sliceEnd];
    int dr = ec.getRed()   - sc.getRed();
    int dg = ec.getGreen() - sc.getGreen();
    int db = ec.getBlue()  - sc.getBlue();
    for( int i=sliceStart; i<=sliceEnd; i++ ) {
      int r = sc.getRed()   + (dr*(i-sliceStart)/d);
      int g = sc.getGreen() + (dg*(i-sliceStart)/d);
      int b = sc.getBlue()  + (db*(i-sliceStart)/d);
      tracks[tracknum].slices[i] = new Color(r,g,b);
    }
  }

  // returns non-zero index of slice clicked
  public int sliceClicked( int x ) {
    for( int i=0; i<numSlices; i++ ) {
      if( isSliceHit( x,i) ) {
        return i;
      }
    }
    return -1;
  }
    

  public void mouseReleased(MouseEvent e) {
    Point mouseReleasedPt = e.getPoint();
    int clickCnt = e.getClickCount();

    playheadClicked = false;

    boolean intrack = 
      (mouseClickedPt.y > currTrack*trackHeight + scrubHeight) && 
      (mouseClickedPt.y < (currTrack+1)*trackHeight + scrubHeight) ;

    if( clickCnt >= 2 && intrack ) {   // double-click to set color
      l.debug("mouseReleased:doublclick!");
      //colorPreview.setColors(  getColorsAtColumn(i) );
      for( int i=0; i<numSlices; i++ ) {
        if( isSliceHit( mouseReleasedPt.x,i) ) {
          colorChooser.setColor( tracks[currTrack].slices[i] );
        }
      }
    }

  /*
    if( intrack ) {
      for( int i=0; i<numSlices; i++) {
        if( isSliceHit( mouseReleasedPt.x, i) ) {
          if((e.getModifiers() & InputEvent.META_MASK) == 0) // meta key notheld
            deselectTrack( currTrack );
          selectSlice(currTrack, i,true);
        }
      }
    }
  */

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
    mousePt = e.getPoint();
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
      //if( tv!=null ) tv.playHeadCurr = playHeadCurr;
    } 
    else {
      boolean intrack = 
        (mouseClickedPt.y > currTrack*trackHeight + scrubHeight) && 
        (mouseClickedPt.y < (currTrack+1)*trackHeight + scrubHeight) ;
      if( intrack ) {
        // make multiple selection of timeslices on mousedrag
        int x = e.getPoint().x;
        for( int i=0; i<numSlices; i++) {
          if( isSliceHitRanged( x, mouseClickedPt.x, i) ) {
            selectSlice(currTrack, i,true);
          }
        }
      } // intrack
    }

    repaint();
  }


  // ------------------------------------------------------------------------


 
}
