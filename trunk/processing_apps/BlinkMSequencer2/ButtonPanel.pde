// Copyright (c) 2007-2008, ThingM Corporation

/**
 * ButtonPanel contains all the main control buttons: play, burn (upload), etc.
 */
public class ButtonPanel extends JPanel {

  JButton playBtn;
  JButton downloadBtn, uploadBtn;
  JButton openBtn, saveBtn;
  JComboBox durChoice;

  private ImageIcon iconPlay;
  private ImageIcon iconPlayHov;
  private ImageIcon iconStop;
  private ImageIcon iconStopHov;
  
  /**
   *
   */
  public ButtonPanel() { //int aWidth, int aHeight) {
    //setPreferredSize(new Dimension(aWidth,aHeight));
    //setMaximumSize(new Dimension(aWidth,aHeight));

    //setBorder(BorderFactory.createCompoundBorder(  // debug
    //BorderFactory.createLineBorder(Color.red),this.getBorder()));

    // add play button
    makePlayButton();

    // add download button
    downloadBtn = new Util().makeButton("blinkm_butn_download_normal.gif",
                                        "blinkm_butn_download_hover.gif",
                                        "Download from BlinkMs", cBgDarkGray);
    downloadBtn.addActionListener(new ActionListener() {
        public void actionPerformed(ActionEvent ae) {
          doDownload();
        }
      });

    // add upload button
    uploadBtn = new Util().makeButton("blinkm_butn_upload_normal.gif",
                                      "blinkm_butn_upload_hover.gif",
                                      "Upload to BlinkMs", cBgDarkGray);
    uploadBtn.addActionListener(new ActionListener() {
        public void actionPerformed(ActionEvent ae) {
          if( !connected ) return;
          new BurnDialog(uploadBtn);
        }
      });
    
    // add open button
    openBtn = new Util().makeButton("blinkm_butn_open_normal.gif",
                                    "blinkm_butn_open_hover.gif",
                                    "Open Sequences File", cBgDarkGray);
    openBtn.addActionListener(new ActionListener() {
        public void actionPerformed(ActionEvent ae) {
            loadAllTracks();
        }
      });
    
    // add save button
    saveBtn = new Util().makeButton("blinkm_butn_save_normal.gif",
                                    "blinkm_butn_save_hover.gif",
                                    "Save Sequences File", cBgDarkGray);
    saveBtn.addActionListener(new ActionListener() {
        public void actionPerformed(ActionEvent ae) {
            saveAllTracks();
        }
      });
    

    JPanel loopPanel = makeLoopControlsPanel();

    JPanel playBtnPanel = new JPanel();
    playBtnPanel.setBackground(cBgDarkGray);
    playBtnPanel.add( playBtn);

    JPanel updnPanel = new JPanel(); // new FlowLayout(FlowLayout.LEFT,0,0) );
    updnPanel.setBackground(cBgDarkGray);
    updnPanel.add(downloadBtn);
    updnPanel.add(uploadBtn);
    //updnPanel.setBorder(BorderFactory.createCompoundBorder(  // debug
    //BorderFactory.createLineBorder(Color.red),updnPanel.getBorder()));

    JPanel opensavePanel = new JPanel();
    opensavePanel.setBackground(cBgDarkGray);
    opensavePanel.add(openBtn);
    opensavePanel.add(saveBtn);

    JPanel grayspacePanel = new JPanel();
    grayspacePanel.setBackground(cBgMidGray);
    //grayspacePanel.add(Box.createVerticalStrut(5)) );

    this.setBackground(cBgDarkGray);
    this.setLayout( new BoxLayout(this, BoxLayout.Y_AXIS));
    this.add(loopPanel);
    this.add(Box.createVerticalStrut(4));
    this.add(playBtnPanel); 
    this.add(grayspacePanel); //Box.createVerticalStrut(5));
    this.add(updnPanel);
    //this.add(Box.createVerticalStrut(1));
    this.add(opensavePanel);

  }

  /**
   *
   */
  public JPanel makeLoopControlsPanel() {
    // add Loop Check Box
    //ImageIcon loopCheckIcn= new Util().createImageIcon("blinkm_text_loop.gif",
    //                                                    "Loop");
    //JLabel loopCheckLabel = new JLabel(loopCheckIcn);
    JLabel loopCheckLabel = new JLabel("LOOP");
    loopCheckLabel.setFont(textBigfont);
    loopCheckLabel.setForeground(cBgMidGray);

    JCheckBox loopCheckbox = new JCheckBox("", true);
    loopCheckbox.setBackground(cBgMidGray);
    ActionListener actionListener = new ActionListener() {
        public void actionPerformed(ActionEvent actionEvent) {
          AbstractButton abButton = (AbstractButton) actionEvent.getSource();
          boolean looping = abButton.getModel().isSelected();
          multitrack.looping = looping;
        }
      };
    loopCheckbox.addActionListener(actionListener);
    
    // add Loop speed label
    //ImageIcon loopIcn=new Util().createImageIcon("blinkm_text_loop_speed.gif",
    //                                               "Loop Speed");
    JLabel loopLabel = new JLabel("LOOP SPEED");
    loopLabel.setFont(textBigfont);
    loopLabel.setForeground(cBgMidGray);

    durChoice = new JComboBox();
    for( int i=0; i< timings.length; i++ ) {
        durChoice.addItem( timings[i].duration+ " seconds");  
    }

    // action listener for duration choice pull down
    durChoice.setBackground(cBgMidGray);
    //durChoice.setForeground(cBgMidGray);
    durChoice.setMaximumSize( durChoice.getPreferredSize() ); 
    durChoice.addItemListener(new ItemListener() {
        public void itemStateChanged(ItemEvent ie) {
          if( ie.getStateChange() == ItemEvent.SELECTED ) {
            int idx = durChoice.getSelectedIndex();  // FIXME
            setDurationByIndex(idx); //durationCurrent = timings[indx].duration;
            prepareForPreview();//durationCurrent);
          }
        }        
      }
      );
    
    JPanel loopPanel = new JPanel();
    loopPanel.setLayout(new BoxLayout( loopPanel, BoxLayout.X_AXIS) );
    loopPanel.setBackground(cBgDarkGray);
    //loopPanel.add(Box.createHorizontalGlue());
    loopPanel.add(Box.createHorizontalStrut(108));
    loopPanel.add(loopCheckLabel);
    loopPanel.add(Box.createHorizontalStrut(5));
    loopPanel.add(loopCheckbox);
    loopPanel.add(Box.createHorizontalStrut(10));
    loopPanel.add(loopLabel);
    loopPanel.add(Box.createHorizontalStrut(5));
    loopPanel.add(durChoice);
    //loopPanel.add(Box.createHorizontalStrut(38));

    return loopPanel;
  }


  /**
   *
   */
  public void makePlayButton() { 
    
    iconPlay    = new Util().createImageIcon("blinkm_butn_play_normal.gif", 
                                             "Play"); 
    iconPlayHov = new Util().createImageIcon("blinkm_butn_play_hover.gif", 
                                             "Play"); 
    // FIXME FIXME FIXME: need blinkm_butn_stop_{normal,hover}.gif
    iconStop    = new Util().createImageIcon("blinkm_butn_stop_normal.gif",  
                                             "Stop"); 
    iconStopHov = new Util().createImageIcon("blinkm_butn_stop_hover.gif", 
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
            prepareForPreview();
            multitrack.play();
          }
          else {
            multitrack.reset();
          }
          
          //isPlaying = !isPlaying;
          l.debug("Playing: " + multitrack.playing);
          setPlayIcon();

          multitrack.deselectAllTracks();  // hmmm.

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

  public void enableButtons(boolean b) {
    if( b ) {
      uploadBtn.setEnabled(true);
      downloadBtn.setEnabled(true);
    }
    else {
      uploadBtn.setEnabled(false);
      downloadBtn.setEnabled(false);
    }
  }

}

