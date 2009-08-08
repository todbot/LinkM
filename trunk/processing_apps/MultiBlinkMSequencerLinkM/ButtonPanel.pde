// Copyright (c) 2007-2008, ThingM Corporation

/**
 * ButtonPanel contains all the main control buttons: play, burn (upload), etc.
 */
public class ButtonPanel extends JPanel {

  JButton burnBtn;

  /**
   *
   */
  public ButtonPanel(int aWidth, int aHeight) {
    //setLayout( new BoxLayout( this, BoxLayout.Y_AXIS) );
    this.setPreferredSize(new Dimension(aWidth,aHeight));
    this.setBackground(bgDarkGray);

    // add play button
    pb = new PlayButton();
    this.add(pb.b);

    // add upload button
    burnBtn = new Util().makeButton("blinkm_butn_upload_on.gif",
                                    "blinkm_butn_upload_hov.gif",
                                    "Upload to BlinkM", bgDarkGray);
    // action listener for burn button
    burnBtn.addActionListener(new ActionListener() {
        public void actionPerformed(ActionEvent ae) {
          new BurnDialog(mf,burnBtn);
        }
      });
    this.add(burnBtn);

    // add separator
    ImageIcon connImg = new Util().createImageIcon("blinkm_separator_horiz_larg.gif", "separator horizontal");
    this.add(new JLabel(connImg));

  }

}
