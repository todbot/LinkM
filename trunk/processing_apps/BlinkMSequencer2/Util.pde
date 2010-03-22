// Copyright (c) 2007-2008, ThingM Corporation

/**
 *
 */
public class Util {
  /** 
   * Returns an ImageIcon, or null if the path was invalid. 
   */
  public ImageIcon createImageIcon(String path, String description) {
    java.net.URL imgURL = getClass().getResource(path);
    if (imgURL != null) {
      return new ImageIcon(imgURL, description);
    } 
    else {
      System.err.println("Couldn't find file: " + path);
      return null;
    }
  }

  /**
   *
   */
  public void centerComp(Component c) {
    Dimension scrnSize = Toolkit.getDefaultToolkit().getScreenSize();
    c.setBounds(scrnSize.width/2 - c.getWidth()/2, scrnSize.height/2 - c.getHeight()/2, c.getWidth(), c.getHeight());
  }

  /**
   *
   */
  public JButton makeButton(String onImg, String rollImg, String txt, Color bgColor) {
    ImageIcon btnImg = createImageIcon(onImg, txt);
    JButton b = new JButton(btnImg);
    //b.setContentAreaFilled( false );
    b.setOpaque(true);
    b.setBorderPainted( false );  // set to true for debugging button sizes
    b.setBackground(bgColor);
    b.setMargin( new Insets(0,0,0,0) );

    if (rollImg != null && !rollImg.equals("")) {
      b.setRolloverEnabled(true);
      ImageIcon img = createImageIcon(rollImg, txt);
      b.setRolloverIcon(img); 
    }

    return b;
  }

}
