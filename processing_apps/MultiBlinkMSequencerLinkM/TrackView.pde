/**
 * TrackView
 * 
 *  Gives a zoomed-in view of a particular track.
 *  Needs a MultiTrackView
 *  
 */


public class TrackView 
  extends JPanel implements MouseListener, MouseMotionListener {


  private MultiTrackView mtv;
  //private Track currTrack;

  private Color playHeadC = new Color(255, 0, 0);
  private float playHeadCurr;
  private boolean playheadClicked = false;
  private Point mouseClickedPt;

  private int w,h;
  private int scrubHeight;

  public TrackView(MultiTrackView multitrack, int w, int h) {
    this.mtv = multitrack;
    mtv.addTrackView(this);

    this.w = w;           // overall width 
    this.h = h;
    this.setPreferredSize(new Dimension(this.w, this.h));
    this.setBackground(cBgDarkGray);
    scrubHeight = mtv.scrubHeight;

    addMouseListener(this);
    addMouseMotionListener(this);

    playHeadCurr = mtv.playHeadCurr;  // kept in sync by tick()
  }


  /**
   * @Override
   */
  public void paintComponent(Graphics gOG) {
    Graphics2D g = (Graphics2D) gOG;
    super.paintComponent(g); 

    mtv.drawTrack( g, mtv.currTrack,  
                   mtv.sx, scrubHeight-1, w, h-scrubHeight-2  ); // Hmmmm

    mtv.drawPlayHead(g, playHeadCurr);  // draws on me, not on mtv

    drawPreview(g);
    
  }

  /**
   *
   */
  void drawPreview(Graphics2D g ) {
    
    int currSlice = mtv.getCurrSliceNum();
    Color c = mtv.getCurrTrack().slices[currSlice];

    g.setColor( c );
    g.fillRect( mtv.previewX , scrubHeight, 40 , h-scrubHeight );

  }

  // called by mtv
  public void tick(float millisSinceLastTick) { 
    if( mtv.playing ) {
      playHeadCurr = mtv.playHeadCurr;
    }
    repaint();
  }
  // called by mtv
  public void play() {
  }
  // called by mtv
  public void stop() { 
  }
  // called by mtv
  public void reset() {
    playHeadCurr = mtv.playHeadCurr;
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
    int phc = (int)playHeadCurr;
    p.addPoint( phc - 4, 0);
    p.addPoint( phc + 4, 0);
    p.addPoint( phc + 4, getHeight());
    p.addPoint( phc - 4, getHeight());
    return p.contains(mp);  // check if mouseclick on playhead
  }
  
  public void mousePressed(MouseEvent e) {

    Point mp = e.getPoint();
    mouseClickedPt = mp;
    
    playheadClicked = isPlayheadClicked(mp);
    if( playheadClicked ) {
    // handle playhead hits in mouseDragged
    // record location of hit in mouseClickedPt and go on
    }
    else { 
      for( int i=0;i<mtv.numSlices;i++) {
        if( mtv.isSliceHit( mp.x, i ) ) 
          mtv.getCurrTrack().selects[i] = true; 
        else if ((e.getModifiers() & InputEvent.META_MASK) == 0) 
          mtv.getCurrTrack().selects[i] = false; // FIXME: this doesn't work
      }
    }
      mtv.repaint();
  }
  
  
  public void mouseReleased(MouseEvent e) {
    Point mouseReleasedPt = e.getPoint();
    Point mp = e.getPoint();
    int clickCnt = e.getClickCount();

    if( clickCnt > 1 ) { 
      for( int i=0;i<mtv.numSlices;i++) {
        if( mtv.isSliceHit( mp.x, i ) ) {
          Color c = mtv.getCurrTrack().slices[i];
          colorChooser.setColor(c);
        }
      }
    }
        
    playheadClicked = false;
  }    
  
  public void mouseMoved(MouseEvent e) {
  }
  
  public void mouseDragged(MouseEvent e) {
    // uck, copy-n-paste antipattern
    if (playheadClicked) {             // if playhead is selected move it
      playHeadCurr = e.getPoint().x;
      // bounds check for playhead
      if (playHeadCurr < mtv.sx)   // such a bad hack copy-paste
        playHeadCurr = mtv.sx;
      else if (playHeadCurr > mtv.trackWidth)
        playHeadCurr = mtv.trackWidth;
      mtv.playHeadCurr = playHeadCurr;
    } 
    else {
      // make multiple selection of timeslices on mousedrag
      int x = e.getPoint().x;
      for( int i=0; i<numSlices; i++) {
        if( mtv.isSliceHitRanged( x, mouseClickedPt.x, i) ) {
          mtv.getCurrTrack().selects[i] = true;
        }
      }
    }
    repaint();
    mtv.repaint();
  }

}
