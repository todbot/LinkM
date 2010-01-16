// Copyright (c) 2007-2008, ThingM Corporation

/**
 * ButtonPanel contains all the main control buttons: play, burn (upload), etc.
 */
public class ButtonPanel extends JPanel {

  JButton uploadBtn, downloadBtn;
  JButton playBtn;
  JButton chgAddrBtn;
  private ImageIcon iconPlay;
  private ImageIcon iconPlayHov;
  private ImageIcon iconStop;
  private ImageIcon iconStopHov;
  
  /**
   *
   */
  public ButtonPanel(int aWidth, int aHeight) {
    //BoxLayout layout =  new BoxLayout( this, BoxLayout.Y_AXIS);
    //layout.
    //this.setLayout( layout );
    
    //this.setBorder(BorderFactory.createCompoundBorder(  // debug
    // BorderFactory.createLineBorder(Color.red),this.getBorder()));
    
    this.setPreferredSize(new Dimension(aWidth,aHeight));
    this.setBackground(cBgDarkGray);
    
    // add play button
    makePlayButton();
    //pb.b.setAlignmentX(Component.CENTER_ALIGNMENT);
    
    // add upload button
    uploadBtn = new Util().makeButton("blinkm_butn_upload_on_2.png",
                                      "blinkm_butn_upload_hov_2.png",
                                      "Upload to BlinkM", cBgDarkGray);
    //burnBtn.setAlignmentX(Component.CENTER_ALIGNMENT);
    // action listener for burn button
    uploadBtn.addActionListener(new ActionListener() {
        public void actionPerformed(ActionEvent ae) {
          new BurnDialog(mf, uploadBtn);
        }
      });
    downloadBtn = new Util().makeButton("blinkm_butn_download_on_2.png",
                                        "blinkm_butn_download_hov_2.png",
                                        "Download from BlinkM", cBgDarkGray);
    //burnBtn.setAlignmentX(Component.CENTER_ALIGNMENT);
    // action listener for burn button
    downloadBtn.addActionListener(new ActionListener() {
        public void actionPerformed(ActionEvent ae) {
          doDownload();
          //new BurnDialog(mf,burnBtn);
        }
      });
    
    ImageIcon connImg = new Util().createImageIcon("blinkm_separator_horiz_larg.gif", 
                                                   "separator horizontal");
    //connImg.setAlignmentX(Component.CENTER_ALIGNMENT);
    
    // add Help button
    JButton helpBtn = new Util().makeButton("blinkm_butn_help_on.gif", 
                                            "blinkm_butn_help_hov.gif", 
                                            "Help", cBgDarkGray);
    //helpBtn.setAlignmentX(Component.CENTER_ALIGNMENT);
    helpBtn.addActionListener(new ActionListener() {
        public void actionPerformed(ActionEvent ae) {
          l.debug("help...");
          p.link("http://thingm.com/products/blinkm/help", "_blank"); 
        }    
      }
      );
    // add About button
    JButton aboutBtn = new Util().makeButton("blinkm_butn_about_on.gif", 
                                             "blinkm_butn_about_hov.gif", 
                                             "About", cBgDarkGray);
    aboutBtn.addActionListener(new ActionListener() {
        public void actionPerformed(ActionEvent ae) {
          l.debug("help...");
          p.link("http://thingm.com/products/blinkm", "_blank"); 
        }    
      }
      );

    JButton chgAddrBtn = new JButton("Change BlinkM Address");
    chgAddrBtn.addActionListener(new ActionListener() {
        public void actionPerformed(ActionEvent ae) {
          l.debug("change addr");
          doAddressChange();
        }    
      }
      );


    JPanel updnPanel = new JPanel();
    updnPanel.setBackground(cBgDarkGray);
    updnPanel.add(downloadBtn);
    updnPanel.add(uploadBtn);

    JPanel minibuttonPanel = new JPanel();
    BoxLayout minibuttonLayout= new BoxLayout(minibuttonPanel,BoxLayout.X_AXIS);
    minibuttonPanel.setLayout(minibuttonLayout);
    minibuttonPanel.setBackground(cBgDarkGray);
    minibuttonPanel.setPreferredSize(new Dimension(aWidth, 50)); //FIXME

    minibuttonPanel.add( chgAddrBtn);
    minibuttonPanel.add( Box.createHorizontalGlue() );
    minibuttonPanel.add(helpBtn);
    minibuttonPanel.add(aboutBtn);
    minibuttonPanel.add(Box.createRigidArea(new Dimension(10,0)));


    this.add(playBtn);  // why did i do this?
    this.add(updnPanel);
    this.add(Box.createRigidArea(new Dimension(0,5)));
    this.add(new JLabel(connImg));      // add separator
    this.add(Box.createRigidArea(new Dimension(0,5)));
    this.add(minibuttonPanel);
  }
  

  /**
   *
   */
  public void makePlayButton() { 
    
    iconPlay    = new Util().createImageIcon("blinkm_butn_play_on_2.png", 
                                             "Play"); 
    iconPlayHov = new Util().createImageIcon("blinkm_butn_play_hov_2.png", 
                                             "Play"); 
    iconStop    = new Util().createImageIcon("blinkm_butn_stop_on_2.png", 
                                             "Stop"); 
    iconStopHov = new Util().createImageIcon("blinkm_butn_stop_hov_2.png", 
                                             "Stop"); 
    playBtn = new JButton();
    playBtn.setOpaque(true);
    playBtn.setBorderPainted( false );
    playBtn.setBackground(cBgDarkGray);
    playBtn.setRolloverEnabled(true);
    setPlayIcon();

    playBtn.addActionListener(new ActionListener() {
        public void actionPerformed(ActionEvent ae) {
          // if we are going from not playing to playing, start timeline
          if( !multitrack.playing ) {
            // stop playing uploaded script, prep for preview playing
            prepareForPreview(durationCurrent);  // global func
            multitrack.play();
          }
          else {
            multitrack.reset();
          }
          
          //isPlaying = !isPlaying;
          l.debug("Playing: " + multitrack.playing);
          setPlayIcon();

          multitrack.allOff();  // hmmm.

        }
      });
  }

  /**
   *
   */
  public void setPlayIcon() {
    if( multitrack.playing ) {
      playBtn.setIcon(iconStop);
      playBtn.setRolloverIcon(iconStopHov); 
    } 
    else {
      playBtn.setIcon(iconPlay);
      playBtn.setRolloverIcon(iconPlayHov); 
    } 
  }

  /**
   *
   */
  public void setToPlay() {
    playBtn.setIcon(iconPlay);
    playBtn.setRolloverIcon(iconPlayHov); 
    //isPlaying = false;
  }

}

