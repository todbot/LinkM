
/**
 * Represents a single slice of time on the timeline. 
 * There are 'numSlices' time slices, regardless of duration.
 */
public class TimeSlice {
  private int x, y, w, h;
  private boolean isActive;
  private boolean isTicked;
  private Color c = tlDarkGray;

  /**
   *
   */
  public TimeSlice(int x, int y, int w, int h) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
  }

  /**
   *
   */
  public void draw(Graphics2D g) {
    g.setColor(c);
    g.fillRect(x+1, y, w, h);
    if (this.isTicked) {  // make tick mark
      g.setColor(bgDarkGray);
      g.fillRect(x+w, 5, 2, 4);  
    }

    if (isActive) {
      BasicStroke wideStroke = new BasicStroke(2.0f);
      g.setStroke(wideStroke);
      g.setColor(highLightC);
      g.drawRect(x, y, w, h-1);
    }
  }

  // point 1D
  public boolean isCollision(int x) {
    return (x <= (this.x + this.w) && x >= this.x); 
  }

  // ranged 1D
  public boolean isCollision(int x, int y) {
    return (x <= (this.x + this.w) && x >= this.x) && 
      (y <= (this.y + this.h) && y >= this.y);
  }

  // ranged 2D
  public boolean isCollision(int x1, int x2, int y1, int y2) {
    boolean inTrack = false;
    if( y2 > y1 ) 
      inTrack = (y1 <= (this.y + this.h) && y2 >= this.y);
    else 
      inTrack = (y2 <= (this.y + this.h) && y1 >= this.y);

    if( inTrack ) {
      if( x2 > x1 ) 
        return (x1 <= (this.x + this.w) && x2 >= this.x);
      else 
        return (x2 <= (this.x + this.w) && x1 >= this.x);
    }
    return false;
  }

  /**
   *
   */
  public void setColor(Color c) {
    this.c = c;
  }

  /**
   *
   */
  public Color getColor() {
    return this.c; 
  }

}
