import javax.swing.border.*;
import java.awt.event.*;

/*
 *
 */
public class GridTestDialog extends JDialog implements MouseListener {

  JLabel[][] trackCells = new JLabel[numTracks][numSlices];
  HashMap cellsToIJ = new HashMap();

  Border bblk = BorderFactory.createLineBorder(Color.black);
  Border bred = BorderFactory.createLineBorder(Color.red);

  boolean mousedown = false;
  int currTrack = 0;

  public GridTestDialog() {
    super();

    JPanel trackpanel = new JPanel();
    trackpanel.setBackground(cBgDarkGray); //sigh, gotta do this on every panel
    trackpanel.setLayout( new GridLayout( numTracks,numSlices ) );

    for( int i=0; i<numTracks; i++ ) {
      Track track = multitrack.tracks[i];
      for( int j=0; j<numSlices; j++) {
        Color c = track.slices[j];
        JLabel l = new JLabel(i+","+j);
        l.setBorder(bblk);
        l.setBackground( cBgDarkGray );
        l.setPreferredSize( new Dimension(18,18) );
        l.addMouseListener(this);
        trackCells[i][j] = l;
        trackpanel.add( l );
        cellsToIJ.put( l, new Point( j,i) );  // FIXME: really? this is what we do?
      }
    }

    getContentPane().add(trackpanel);
    pack();
    setResizable(false);
    setLocationRelativeTo(null); // center it on the BlinkMSequencer
    super.setVisible(false);

    setTitle("Grid Test");

  }

  // Invoked when the mouse button has been clicked (pressed & released)
  void mouseClicked(java.awt.event.MouseEvent e) {
    //println("mouseClicked");
    
  }
  // Invoked when the mouse enters a component.
  void mouseEntered(java.awt.event.MouseEvent e) {
    //println("mouseEntered");
    // if we're mousedown and in same row, select
    if( mousedown ) {
      JLabel l = (JLabel)e.getComponent() ;
      Point p = (Point)cellsToIJ.get( l );
      println("mouseEnered: "+p);
      if( p.y == currTrack ) {
        selectOn( l );
      }
    }
  }
  // Invoked when the mouse exits a component.
  void mouseExited(java.awt.event.MouseEvent e) {
    //println("mouseExited");
  }
  // Invoked when a mouse button has been pressed on a component.
  void	mousePressed(java.awt.event.MouseEvent e) {
    JLabel l = (JLabel)e.getComponent();
    selectOn(l);
    mousedown = true;
    Point p = (Point)cellsToIJ.get( l );
    currTrack = p.y;
    println("mousePressed: "+currTrack);
    // begin select, say "mousedown!" and set what row we're in
  }
  void 	mouseReleased(java.awt.event.MouseEvent e)  {
    println("mouseReleased");
    // if in mousedown, end select
    mousedown = false;
  }

  void selectOn(JLabel l ) {
    l.setBorder(bred);
  }

}

