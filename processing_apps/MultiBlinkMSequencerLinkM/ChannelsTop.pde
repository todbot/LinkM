// Copyright (c) 2007-2008, ThingM Corporation

/**
 *
 */
public class ChannelsTop extends JPanel {

  JLabel buttonLegend;

  /**
   *
   */
  public ChannelsTop() {
    // set color of this panel
    setBackground(cBgLightGray);
    setLayout( new BoxLayout(this, BoxLayout.X_AXIS) );
    setBorder(BorderFactory.createEmptyBorder(2, 2, 2, 2));
        
    add( Box.createRigidArea(new Dimension(25,0) ) );

    ImageIcon chText = util.createImageIcon("blinkm_text_channels.gif",
                                            "CHANNELS");
    JLabel chLabel = new JLabel(chText);
    add(chLabel);
        
    add(Box.createHorizontalGlue());  // boing

        
    buttonLegend = new JLabel();
    add(buttonLegend);

    JButton loadAllBtn = util.makeButton("blinkm_butn_loadall_on.gif", 
                                         "blinkm_butn_loadall_hov.gif", 
                                         "LoadAll", cBgLightGray);
    add(loadAllBtn);

    JButton saveAllBtn = util.makeButton("blinkm_butn_saveall_on.gif", 
                                         "blinkm_butn_saveall_hov.gif", 
                                         "SaveAll", cBgLightGray);
    add(saveAllBtn);
        
    add( Box.createRigidArea(new Dimension(15,0) ) );


    loadAllBtn.addMouseListener( new MouseAdapter() { 
        public void mouseEntered(MouseEvent e) { 
          buttonLegend.setVisible(true);
          buttonLegend.setText("LOAD ALL CHANNELS");
        }
        public void mouseExited(MouseEvent e) { 
          buttonLegend.setVisible(false);
        }
      } );

    saveAllBtn.addMouseListener( new MouseAdapter() { 
        public void mouseEntered(MouseEvent e) { 
          buttonLegend.setVisible(true);
          buttonLegend.setText("SAVE ALL CHANNELS");
        }
        public void mouseExited(MouseEvent e) { 
          buttonLegend.setVisible(false);
        }
      } );
    loadAllBtn.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent ae) {
          l.debug("loadAll");
          loadAllTracks();
        }    
      }
      );
    saveAllBtn.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent ae) {
          l.debug("saveAll");
          saveAllTracks();
        }    
      }
      );

  }
    
}
