/**
 * TrackView
 * 
 *  Gives a zoomed-in view of a particular track.
 *  Needs a MultiTrackView
 *  
 */


public class TrackView 
  extends JPanel implements MouseListener, MouseMotionListener {


  private MultiTrackView multitrack;
  //private Track currTrack;

  private Color playHeadC = new Color(255, 0, 0);
  private float playHeadCurr;
  private boolean playheadClicked = false;

  private int w,h;

  private Point mouseClickedPt;

  public TrackView(MultiTrackView multitrack, int w, int h) {
    this.multitrack = multitrack;

    this.w = w;           // overall width 
    this.h = h;
    this.setPreferredSize(new Dimension(this.w, this.h));
    this.setBackground(bgDarkGray);

    addMouseListener(this);
    addMouseMotionListener(this);

  }


  /**
   * @Override
   */
  public void paintComponent(Graphics gOG) {
    Graphics2D g = (Graphics2D) gOG;
    super.paintComponent(g); 

    //Track track = multitrack.getCurrTrack();

    //track.drawTall(g, h);

  }

  public void tick(float millisSinceLastTick) { 
    if( multitrack.playing ) {
    }
    repaint();
  }


  // --------------------------------------------------------------------------

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

  public void mousePressed(MouseEvent e) {
    l.debug("TrackView.mousePressed: "+e.getPoint());
    /*
    if( (e.getModifiers() & InputEvent.META_MASK) == 0 )  // alt/cmd pressed
      multitrack.allOff();

    Point mp = e.getPoint();

    mouseClickedPt = mp;

    // handle playhead hits in mouseDragged
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
      if( intrack && (mp.x >= 3 && mp.x <= 3+15 ) )   // enable button
        toggleTrackEnable(j);
      else if( intrack && (mp.x >= 26 && mp.x <= 26+20 ) ) // addr button
        doTrackDialog(j);
      else {
        TimeSlice[] timeSlices = tracks[0].timeSlices;  // any track will do
        for( int i=0;i<numSlices;i++) {
          TimeSlice ts = timeSlices[i];
          if( ts.isCollision(mp.x) )
            selectSlice(i,true);  
          //toggleSlice(i);
          else if ((e.getModifiers() & InputEvent.META_MASK) == 0) 
            selectSlice(i,false); // fixme: this doesn't work
        }
      }

    }

    repaint();
    */
  }

  public void mouseReleased(MouseEvent e) {
    Point mouseReleasedPt = e.getPoint();
    int clickCnt = e.getClickCount();
    
    //playheadClicked = false;
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
    //repaint();
  }

  public void mouseMoved(MouseEvent e) {
  }

  public void mouseDragged(MouseEvent e) {
    //l.debug("dragged:"+e);
    /*
    if (playheadClicked) {             // if playhead is selected move it
      playHeadCurr = e.getPoint().x;
          
      // bounds check for playhead
      if (playHeadCurr < sx)
        playHeadCurr = sx;
      else if (playHeadCurr > trackWidth)
        playHeadCurr = trackWidth;
    } 
    else {
      // make multiple selection of timeslices on mousedrag
      int x = e.getPoint().x;
      TimeSlice[] timeSlices = tracks[0].timeSlices;  // any track will do
      for( int i=0;i<numSlices;i++) {
        TimeSlice ts = timeSlices[i];
        if( ts.isCollision(x,mouseClickedPt.x) )
          selectSlice(i,true);
      }
    }

    repaint();
    */
  }

}
