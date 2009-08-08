// Copyright (c) 2007-2008, ThingM Corporation

/**
 *
 */
public class MainFrame extends JDialog {

  public Frame f = new Frame();

  private int width, height;
  private PApplet appletRef;

  /**
   *
   */
  public MainFrame(int w, int h, PApplet appRef) {
    super(new Frame(), "BlinkM Sequencer", false);
    this.setBackground(bgDarkGray);
    this.setFocusable(true);
    this.width = w;
    this.height = h;
    this.appletRef = appRef;

    // handle window close events
    this.addWindowListener(new WindowAdapter() {
        public void windowClosing(WindowEvent e) {
          // close mainframe
          dispose();
          // close processing window as well
          appletRef.destroy();
          appletRef.frame.setVisible(false);
          System.exit(0);
        }
      }); 

    // center MainFrame on the screen and show it
    this.setSize(this.width, this.height);
    Dimension scrnSize = Toolkit.getDefaultToolkit().getScreenSize();
    this.setLocation(scrnSize.width/2 - this.width/2, 
                     scrnSize.height/2 - this.height/2);
    this.setVisible(true);
   
  }
}
