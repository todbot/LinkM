// Copyright (c) 2007-2008, ThingM Corporation

/**
 *
 */
public class ChannelsTop extends JPanel {

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
    JLabel currChanIdText = new JLabel("CURRENT CHANNEL ID:");
    currChanIdLabel = new JLabel("-");
    JLabel currChanLabelText = new JLabel("LABEL:");
    currChanLabel = new JLabel("-nuh-");

    add(chLabel);
    add(Box.createHorizontalStrut(10));
    add(currChanIdText);
    add(Box.createHorizontalStrut(5));
    add(currChanIdLabel);
    add(Box.createHorizontalStrut(10));
    add(currChanLabelText);
    add(Box.createHorizontalStrut(5));
    add(currChanLabel);

    add(Box.createHorizontalGlue());  // boing


  }
    
}
