// Copyright (c) 2007-2008, ThingM Corporation

/**
 *
 */
public class TimelineTop extends JPanel {

  JComboBox durChoice;
  JLabel buttonLegend;

  /**
   *
   */
  public TimelineTop() {
    // set color of this panel
    setBackground(bgLightGray);
    setLayout( new BoxLayout(this, BoxLayout.X_AXIS) );
    setBorder(BorderFactory.createEmptyBorder(2, 2, 2, 2));

    durChoice = new JComboBox();
    durChoice.addItem( timings[0].duration+ " seconds");  
    durChoice.addItem( timings[1].duration+ " seconds");
    durChoice.addItem( timings[2].duration+ " seconds");

        
    add( Box.createRigidArea(new Dimension(25,0) ) );

    ImageIcon tlText = new Util().createImageIcon("blinkm_text_timeline.gif",
                                                  "TIMELINE");
    JLabel tlLabel = new JLabel(tlText);
    this.add(tlLabel); //, BorderLayout.WEST);
        
    add( Box.createRigidArea(new Dimension(50,0) ) );

    // add loop label
    ImageIcon loopTxt = new Util().createImageIcon("blinkm_text_loop_speed.gif", "Loop Speed");
    JLabel loopLbl = new JLabel(loopTxt);
    this.add(loopLbl);

    add( Box.createRigidArea(new Dimension(15,0) ) );

    // action listener for duration choice pull down
    durChoice.setBackground(bgLightGray);
    durChoice.setMaximumSize( durChoice.getPreferredSize() ); 
    durChoice.addItemListener(new ItemListener() {
        public void itemStateChanged(ItemEvent ie) {
          int indx = durChoice.getSelectedIndex();
          durationCurrent = timings[indx].duration;
          prepareForPreview(durationCurrent);
        }        
      }
      );
    this.add(durChoice);
        
    add( Box.createRigidArea(new Dimension(25,0) ) );

    // add Loop Check Box
    ImageIcon loopCheckIcn = new Util().createImageIcon("blinkm_text_loop.gif",
                                                        "Loop");
    JLabel loopCheckLbl = new JLabel(loopCheckIcn);
    add(loopCheckLbl);

    JCheckBox loopCheck = new JCheckBox("", true);
    loopCheck.setBackground(bgLightGray);
    add(loopCheck);

    ActionListener actionListener = new ActionListener() {
        public void actionPerformed(ActionEvent actionEvent) {
          AbstractButton abButton = (AbstractButton) actionEvent.getSource();
          boolean looping = abButton.getModel().isSelected();
          multitrack.looping = looping;
        }
      };
    loopCheck.addActionListener(actionListener);
        
    add(Box.createHorizontalGlue());
       

    buttonLegend = new JLabel();
    add(buttonLegend);

    add( Box.createRigidArea(new Dimension(5,0) ) );

    JButton loadOneBtn = new Util().makeButton("blinkm_butn_loadall_on.gif", 
                                               "blinkm_butn_loadall_hov.gif", 
                                               "LoadOne", bgLightGray);    
    add(loadOneBtn);

    JButton saveOneBtn = new Util().makeButton("blinkm_butn_saveall_on.gif", 
                                               "blinkm_butn_saveall_hov.gif", 
                                               "SaveOne", bgLightGray);
    add(saveOneBtn);

    add( Box.createRigidArea(new Dimension(15,0) ) );

    loadOneBtn.addMouseListener( new MouseAdapter() { 
        public void mouseEntered(MouseEvent e) { 
          buttonLegend.setVisible(true);
          buttonLegend.setText("LOAD ONE SCRIPT");
        }
        public void mouseExited(MouseEvent e) { 
          buttonLegend.setVisible(false);
        }
      } );
    loadOneBtn.addActionListener(new ActionListener() {
        public void actionPerformed(ActionEvent ae) {
          l.debug("loadOne");
          loadTrack();
        }    
      }
      );

    saveOneBtn.addMouseListener( new MouseAdapter() { 
        public void mouseEntered(MouseEvent e) { 
          buttonLegend.setVisible(true);
          buttonLegend.setText("SAVE ONE SCRIPT");
        }
        public void mouseExited(MouseEvent e) { 
          buttonLegend.setVisible(false);
        }
      } );
    saveOneBtn.addActionListener(new ActionListener() {
        public void actionPerformed(ActionEvent ae) {
          l.debug("saveOne");
          saveTrack();
        }
      }
      );

  }
    
}
