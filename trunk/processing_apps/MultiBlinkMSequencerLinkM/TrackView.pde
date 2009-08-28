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

  private int w,h;
  private int scrubHeight;

  private Point mouseClickedPt;

  public TrackView(MultiTrackView multitrack, int w, int h) {
    this.mtv = multitrack;

    this.w = w;           // overall width 
    this.h = h;
    this.setPreferredSize(new Dimension(this.w, this.h));
    this.setBackground(bgDarkGray);
    scrubHeight = mtv.scrubHeight;

    addMouseListener(this);
    addMouseMotionListener(this);

  }


  /**
   * @Override
   */
  public void paintComponent(Graphics gOG) {
    Graphics2D g = (Graphics2D) gOG;
    super.paintComponent(g); 

    mtv.drawTrack( g, mtv.currTrack,  
                   mtv.sx, scrubHeight, w, h-scrubHeight  );

    mtv.drawPlayHead(g);  // draws on me, not on mtv

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

  public void tick(float millisSinceLastTick) { 
    if( mtv.playing ) {
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
    if( (e.getModifiers() & InputEvent.META_MASK) == 0 )  // alt/cmd pressed
      mtv.allOff();

    Point mp = e.getPoint();
    mouseClickedPt = mp;

    for( int i=0;i<mtv.numSlices;i++) {
      if( mtv.isSliceHit( mp.x, i ) ) {
        mtv.getCurrTrack().selects[i] = true; 
        println("tv.slice:"+i);
      }
      else if ((e.getModifiers() & InputEvent.META_MASK) == 0) 
        mtv.getCurrTrack().selects[i] = false; // FIXME: this doesn't work
    }
  }
  
  
  public void mouseReleased(MouseEvent e) {
    Point mouseReleasedPt = e.getPoint();
    int clickCnt = e.getClickCount();
  }    
  
  public void mouseMoved(MouseEvent e) {
  }
  
  public void mouseDragged(MouseEvent e) {
    //if( !playheadDragged(e) ) { 
    //else {
    // make multiple selection of timeslices on mousedrag

    int x = e.getPoint().x;
    for( int i=0; i<numSlices; i++) {
      if( mtv.isSliceHitRanged( x, mouseClickedPt.x, i) ) {
        mtv.getCurrTrack().selects[i] = true;
      }
    }

    repaint();
    mtv.repaint();
  }

}
