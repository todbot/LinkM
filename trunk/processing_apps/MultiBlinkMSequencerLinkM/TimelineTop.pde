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
    durChoice.addItem( durations[0]+ " seconds");  
    durChoice.addItem( durations[1]+ " seconds");
    durChoice.addItem( durations[2]+ " seconds");

        
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
          durationCurrent = durations[indx];
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
          boolean selected = abButton.getModel().isSelected();
          timeline.setLoop(selected);
                
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

    saveOneBtn.addMouseListener( new MouseAdapter() { 
        public void mouseEntered(MouseEvent e) { 
          buttonLegend.setVisible(true);
          buttonLegend.setText("SAVE ONE SCRIPT");
        }
        public void mouseExited(MouseEvent e) { 
          buttonLegend.setVisible(false);
        }
      } );

  }
    /*
    // add Help button
    JButton helpBtn = new Util().makeButton("blinkm_butn_help_on.gif", 
                                            "blinkm_butn_help_hov.gif", 
                                            "Help", bgLightGray);
    this.add(helpBtn);
        
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
                                             "About", bgLightGray);
    this.add(aboutBtn);
        
    aboutBtn.addActionListener(new ActionListener() {
        public void actionPerformed(ActionEvent ae) {
          l.debug("help...");
          p.link("http://thingm.com/products/blinkm", "_blank"); 
        }    
      }
      );
    */
    
}
