// Copyright (c) 2007-2008, ThingM Corporation

/**
 *
 */
public class PlayButton {
  private ImageIcon iconPlay;
  private ImageIcon iconPlayHov;
  private ImageIcon iconStop;
  private ImageIcon iconStopHov;
  private boolean isPlaying;
  private JButton b;

  /**
   *
   */
  public PlayButton() {
    iconPlay    = new Util().createImageIcon("blinkm_butn_play_on.gif", 
                                             "Play"); 
    iconPlayHov = new Util().createImageIcon("blinkm_butn_play_hov.gif", 
                                             "Play"); 
    iconStop    = new Util().createImageIcon("blinkm_butn_stop_on.gif", 
                                             "Stop"); 
    iconStopHov = new Util().createImageIcon("blinkm_butn_stop_hov.gif", 
                                             "Stop"); 
    b = new JButton();  // this is me
    b.setOpaque(true);
    b.setBorderPainted( false );
    b.setBackground(bgDarkGray);
    b.setRolloverEnabled(true);
    setIcon();

    b.addActionListener(new ActionListener() {
        public void actionPerformed(ActionEvent ae) {
          // if we are going from not playing to playing, start timeline
          if (!isPlaying) {
            // stop playing uploaded script, prep for preview playing
            prepareForPreview(durationCurrent);
            multitrack.play();
            //channels.play();
            //timeline.play(); 
          }
          else {
            multitrack.reset();
            //channels.reset();
            //timeline.reset();
          }

          isPlaying = !isPlaying;
          l.debug("Playing: " + isPlaying);
          setIcon();

          multitrack.allOff();

        }
      });
  }

  /**
   *
   */
  public void setIcon() {
    if (isPlaying) {
      b.setIcon(iconStop);
      b.setRolloverIcon(iconStopHov); 
    } 
    else {
      b.setIcon(iconPlay);
      b.setRolloverIcon(iconPlayHov); 
    } 
  }

  /**
   *
   */
  public void setToPlay() {
    b.setIcon(iconPlay);
    b.setRolloverIcon(iconPlayHov); 
    isPlaying = false;
  }
}
