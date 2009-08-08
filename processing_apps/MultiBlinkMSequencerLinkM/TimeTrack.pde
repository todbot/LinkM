/**
 *
 */
public class TimeTrack { 
  private int x, y, w, h;
  private int secSpacerWidth;
  private int scrubHeight;
  public TimeSlice[] timeSlices = new TimeSlice[numSlices];
  boolean active;

  public TimeTrack(int x, int y, int w, int h, int sw) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.secSpacerWidth = sw;
    this.active = true;
    
    // initialize and add numSlices TimeSlice objects
    // draw guide rects
    int xStep = (this.w / numSlices) - secSpacerWidth;
    int xRemaining = this.w % numSlices - secSpacerWidth;
    int xCurr = x;
    for (int i=1; i<numSlices+1; i++) {
      TimeSlice ts = new TimeSlice(xCurr, y+1, xStep, h);
      if (i%8 == 0) 
        ts.isTicked = true; 
      xCurr += xStep + secSpacerWidth;
      timeSlices[i-1] = ts;
    }
  }

}
