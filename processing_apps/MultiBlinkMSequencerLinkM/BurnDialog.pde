// Copyright (c) 2007-2008, ThingM Corporation

/**
 *
 */
public class BurnDialog extends JDialog implements ActionListener {

  private String msg_uploading = "Uploading...";
  private String msg_done = "Done";
  private String msg_nowplaying = "Now playing sequence stand-alone";
  private String msg_error = "ERROR: not connected to a BlinkM.";
  private String msg_empty = "     ";

  private JLabel msgtop;
  private JLabel msgbot;
  private JProgressBar progressbar;
  private JButton okbut;

  private JButton burnBtn;

  public BurnDialog(Dialog owner, JButton aBurnBtn) {
    //super(owner, "BlinkM Connect",true);  // modal
    super();
    burnBtn = aBurnBtn;
    burnBtn.setEnabled(false);

    setTitle("BlinkM Upload");

    JPanel panel = new JPanel(new GridLayout(0,1));
    panel.setBorder( BorderFactory.createEmptyBorder(20,20,20,20) );

    msgtop = new JLabel(msg_uploading);
    progressbar = new JProgressBar(0, numSlices-1);
    msgbot = new JLabel(msg_nowplaying);
    msgbot.setVisible(false);
    okbut = new JButton("Ok");
    okbut.setVisible(false);
    okbut.addActionListener(this);

    panel.add( msgtop );
    panel.add( progressbar );
    panel.add( msgbot );
    panel.add( okbut );
    getContentPane().add(panel);

    pack();
    setResizable(false);
    setLocationRelativeTo(null); // center it on the BlinkMSequencer
    setVisible(true);
    
    multitrack.reset(); // stop preview script
    pb.setToPlay();  // rest play button

    // so dumb we have to spawn a thread for this
    new Thread( new Burner() ).start();

  }
  // when the burn button is pressed
  public void actionPerformed(ActionEvent e) {
    burnBtn.setEnabled(true);  // seems like such a hack  (why did i do this?)
    prepareForPreview(durationCurrent);
    setVisible(false);
  }
      
  public void isDone() {
    msgbot.setVisible(true);
    okbut.setVisible(true);
  }

  class Burner implements Runnable {
    public void run() {
        
      multitrack.stop();

      for( int j=0; j<numTracks; j++ ) {
        ArrayList colorlist = new ArrayList();
        for( int i=0; i<numSlices; i++)    // FIXME
          colorlist.add( multitrack.tracks[j].slices[i] );
        msgtop.setText( msg_uploading );
        
        int blinkmAddr = blinkmAddrs[j];  // get this track i2c address

        // burn the list, and saying which colors are 'unused'
        burn( blinkmAddr, colorlist, tlDarkGray, durationCurrent,
              multitrack.looping, progressbar);
        
        msgtop.setText( msg_uploading + msg_done );
      }

      msgbot.setText( msg_nowplaying );
      
      isDone();
    } // run
  }
}


