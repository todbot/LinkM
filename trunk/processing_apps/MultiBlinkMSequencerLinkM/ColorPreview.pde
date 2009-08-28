// Copyright (c) 2007-2008, ThingM Corporation

/**
 * A pseudo-LED 
 *
 */
public class ColorPreview extends JPanel {
  private Color colorCurrent = new Color(100, 100, 100);
  private Color colorTarget = new Color(100, 100, 100);
  private javax.swing.Timer fadetimer;
  private Color[] colors = new Color[numTracks];

  // turning this off makes it more time-accurate on slower computers? wtf
  private static final boolean dofade = true;

  public int fadeMillis = 25;
  public int fadespeed  = 25;
  
  /**
   *
   */
  public ColorPreview() {
    super();
    this.setPreferredSize(new Dimension(105, 260));
    this.setBackground(bgLightGray);
    ImageIcon tlText = new Util().createImageIcon("blinkm_text_preview.gif", "Preview");
    JLabel tlLabel = new JLabel(tlText);
    this.add(tlLabel);
    if( dofade ) {
      fadetimer = new javax.swing.Timer(fadeMillis, new ColorFader());
      fadetimer.start();
    }
    for( int i=0; i<numTracks; i++ ) {
      colors[i] = new Color( 30+i*10, i*10, i*10 );
    }
  }

  /**
   * @Override
   */
  public void paintComponent(Graphics g) {
    Graphics2D g2 = (Graphics2D) g;
    super.paintComponent(g2); 
    g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, 
                        RenderingHints.VALUE_ANTIALIAS_ON);
    //g2.setColor(Color.black);
    //g2.drawRect(0,0, getWidth()-1, getHeight()-1);
    //g2.fillRect( 10,70, getWidth()-25, getHeight()-90);
    for( int i=0; i<numTracks; i++ ) {
      Color c = colors[i];
      g2.setColor(c);
      g2.fillRect( 30, 30+(i*29), 40, 27);
    }
  }

  public void setColors(Color[] cs) {
    System.arraycopy( cs, 0, colors, 0, colors.length );
  }

  /**
   *
   */
  public void setColor(Color c) {
    if( dofade ) {
      fadespeed = getFadeSpeed(durationCurrent,numSlices,fadeMillis);
      colorTarget = c;
    } else {
      colorCurrent = c;
    }
    
    // wow. is this a hack?
    //setColors( timeline.getColorsAtColumn( timeline.getPreviewColumn() ) );
    
    // make BlinkM color match preview color
    int addr = 0;
    /*
    try { 
      linkm.fadeToRGB( addr, c);  // FIXME:  which track 
    } catch( IOException ioe) {
      // hmm, what to do here
    }
    */
    repaint();
  }
    
  /**
   *
   */
  public Color getColor() {
    return this.colorCurrent; 
  }


  public int getFadeSpeed(int loopduration,int numsteps,int fadeMillis) {
    float time_per_step = ((float)loopduration / numsteps);
    float time_half_millis = (time_per_step / 2) * 1000;
    int f =  fadeMillis / (int)time_half_millis;
    //l.debug("ColorPreview: fadeMillis:"+fadeMillis+" time_half:"+time_half_millis+", fadespeed:"+f);
    return 25; // (int)time_half_millis;
  }

  /**
   * Somewhat replicates how BlinkM does color fades
   * called by the fadetimer every tick
   *
   * NOTE: this is constant rate, not constant time
   */
  class ColorFader implements ActionListener {
    public void actionPerformed(ActionEvent e) {
      int r = colorCurrent.getRed();
      int g = colorCurrent.getGreen();
      int b = colorCurrent.getBlue();
          
      int rt = colorTarget.getRed();
      int gt = colorTarget.getGreen();
      int bt = colorTarget.getBlue();
          
      r = color_slide(r,rt, fadespeed);
      g = color_slide(g,gt, fadespeed);
      b = color_slide(b,bt, fadespeed);
      colorCurrent = new Color( r,g,b );

      repaint();
    }

    int color_slide(int curr, int dest, int step) {
      int diff = curr - dest;
      if(diff < 0)  diff = -diff;
          
      if( diff <= step ) return dest;
      if( curr == dest ) return dest;
      else if( curr < dest ) return curr + step;
      else                   return curr - step;
    }
  }

}
