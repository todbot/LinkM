// Copyright (c) 2007-2008, ThingM Corporation

/**
 *
 */
public class SetChannelDialog extends JDialog { //implements ActionListener {

  JButton[] colorSpots;
  JTextField[] channels;
  JTextField[] labels;

  public SetChannelDialog() {
    super();

    JPanel p;
    JPanel trackpanel = new JPanel();
    trackpanel.setBackground(cBgDarkGray); //sigh, gotta do this on every panel
    trackpanel.setLayout( new BoxLayout( trackpanel, BoxLayout.Y_AXIS) );

    colorSpots = new JButton[numTracks];
    channels = new JTextField[numTracks];
    labels = new JTextField[numTracks];
    
    for( int i=0; i< numTracks; i++) { 
      colorSpots[i] = new JButton();
      channels[i]   = new JTextField(3);
      labels[i]     = new JTextField(20);

      channels[i].setHorizontalAlignment(JTextField.RIGHT);

      p = new JPanel();
      p.setBackground(cBgDarkGray); //sigh, gotta do this on every panel
      p.add( colorSpots[i] );
      p.add( channels[i] );
      p.add( labels[i] );
      trackpanel.add( p );

      colorSpots[i].setBackground( setChannelColors[i] );
      colorSpots[i].setPreferredSize( new Dimension(20,20) );
      channels[i].setText( String.valueOf(multitrack.tracks[i].blinkmaddr) );
      labels[i].setText( String.valueOf(multitrack.tracks[i].label) );
    }

    JButton okbut = new JButton("OK");
    JButton cancelbut = new JButton("CANCEL");

    cancelbut.addActionListener(new ActionListener() {
        public void actionPerformed(ActionEvent ae) {
          setVisible(false);  // do nothing but go away
          updateInfo();
        }
      });
    okbut.addActionListener(new ActionListener() {
        public void actionPerformed(ActionEvent ae) {
          for( int i=0; i< numTracks; i++ ) {
            try {
              int a = Integer.parseInt( channels[i].getText() );
              if( a >=0 && a < 127 ) { // i2c limits
                multitrack.tracks[i].blinkmaddr = a;
              } else {
                println("bad value");
              }
            } catch(Exception e) {}
            multitrack.tracks[i].label = labels[i].getText();
          }
          setVisible(false);
          updateInfo();
        }
      });

    JPanel butpanel = new JPanel();
    butpanel.setBackground(cBgDarkGray); //sigh, gotta do this on every panel
    butpanel.add( okbut );
    butpanel.add( cancelbut );

    JPanel panel = new JPanel(new BorderLayout());
    panel.setBackground(cBgDarkGray); //sigh, gotta do this on every panel
    panel.setBorder( BorderFactory.createEmptyBorder(20,20,20,20) );

    JLabel header=new JLabel("Attached BlinkMs lit according to channel color");
    header.setForeground( cBgLightGray );
    panel.add( header, BorderLayout.NORTH );
    panel.add( trackpanel, BorderLayout.CENTER );
    panel.add( butpanel, BorderLayout.SOUTH );
 
    getContentPane().add(panel);

    pack();
    setResizable(false);
    setLocationRelativeTo(null); // center it on the BlinkMSequencer
    super.setVisible(false);

    setTitle("Set Channel");

  }

  /**
   *
   */
  public void setVisible(boolean v ) {
    super.setVisible(v);
    int addrs[] = new int[numTracks];
    Color black[] = new Color[numTracks];
    for( int i=0; i< numTracks; i++) { // ugh, wtf 
      addrs[i] = multitrack.tracks[i].blinkmaddr;
      black[i] = Color.BLACK;  // what we have here is a failure of the API :)
    }
    if( v == true ) {
      l.debug("sending blinkm colors!");
      sendBlinkMColors( addrs, setChannelColors, numTracks) ;
    } else { 
      sendBlinkMColors( addrs, black, numTracks );
      l.debug("sending blinkm all off!");
    }
  }

}


    /*
    // a dumb attempt at making table headers
    p = new JPanel();
    p.setBackground(cBgDarkGray);
    JButton fakebut = new JButton();
    fakebut.setBackground(cBgDarkGray);
    fakebut.setPreferredSize( new Dimension(20,20) );
    JTextField faketf1 = new JTextField(3);
    faketf1.setText("chan");
    faketf1.setBackground(cBgDarkGray);
    faketf1.setEditable(false);
    JTextField faketf2 = new JTextField(20);
    faketf2.setText("label");
    faketf2.setBackground(cBgDarkGray);
    faketf2.setEditable(false);
    
    p.add( fakebut );
    p.add( faketf1 );
    p.add( faketf2 );
    trackpanel.add(p);
    */

