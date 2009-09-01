// Copyright (c) 2007-2008, ThingM Corporation

/**
 * ButtonPanel contains all the main control buttons: play, burn (upload), etc.
 */
public class ButtonPanel extends JPanel {

  JButton uploadBtn, downloadBtn;

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
    this.setBackground(bgDarkGray);

    // add play button
    pb = new PlayButton();
    //pb.b.setAlignmentX(Component.CENTER_ALIGNMENT);

    // add upload button
    uploadBtn = new Util().makeButton("blinkm_butn_upload_on_2.png",
                                      "blinkm_butn_upload_hov_2.png",
                                      "Upload to BlinkM", bgDarkGray);
    //burnBtn.setAlignmentX(Component.CENTER_ALIGNMENT);
    // action listener for burn button
    uploadBtn.addActionListener(new ActionListener() {
        public void actionPerformed(ActionEvent ae) {
          new BurnDialog(mf, downloadBtn);
        }
      });
    downloadBtn = new Util().makeButton("blinkm_butn_download_on_2.png",
                                        "blinkm_butn_download_hov_2.png",
                                        "Download from BlinkM", bgDarkGray);
    //burnBtn.setAlignmentX(Component.CENTER_ALIGNMENT);
    // action listener for burn button
    downloadBtn.addActionListener(new ActionListener() {
        public void actionPerformed(ActionEvent ae) {
          //new BurnDialog(mf,burnBtn);
        }
      });

    ImageIcon connImg = new Util().createImageIcon("blinkm_separator_horiz_larg.gif", "separator horizontal");
    //connImg.setAlignmentX(Component.CENTER_ALIGNMENT);

    // add Help button
    JButton helpBtn = new Util().makeButton("blinkm_butn_help_on.gif", 
                                            "blinkm_butn_help_hov.gif", 
                                            "Help", bgDarkGray);
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
                                             "About", bgDarkGray);
    aboutBtn.addActionListener(new ActionListener() {
        public void actionPerformed(ActionEvent ae) {
          l.debug("help...");
          p.link("http://thingm.com/products/blinkm", "_blank"); 
        }    
      }
      );

    JPanel updnPanel = new JPanel();
    updnPanel.setBackground(bgDarkGray);
    updnPanel.add(downloadBtn);
    updnPanel.add(uploadBtn);

    JPanel minibuttonPanel = new JPanel();
    BoxLayout minibuttonLayout= new BoxLayout(minibuttonPanel,BoxLayout.X_AXIS);
    minibuttonPanel.setLayout(minibuttonLayout);
    minibuttonPanel.setBackground(bgDarkGray);
    minibuttonPanel.setPreferredSize(new Dimension(aWidth, 50)); //FIXME

    minibuttonPanel.add( Box.createHorizontalGlue() );
    minibuttonPanel.add(helpBtn);
    minibuttonPanel.add(aboutBtn);
    minibuttonPanel.add(Box.createRigidArea(new Dimension(10,0)));


    this.add(pb.b);  // why did i do this?
    this.add(updnPanel);
    this.add(Box.createRigidArea(new Dimension(0,5)));
    this.add(new JLabel(connImg));      // add separator
    this.add(Box.createRigidArea(new Dimension(0,5)));
    this.add(minibuttonPanel);
  }

}
